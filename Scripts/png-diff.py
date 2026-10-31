#!/usr/bin/env python3
"""Compares two PNGs with a tolerance (standard library only, so CI needs no packages).

    png-diff.py [--mean N] [--fraction F] [--channel N] expected.png actual.png

Prints the mean absolute difference per channel (0-255) and the fraction of pixels where any
channel differs by more than --channel (default 16). Exits 0 when the mean is at most --mean
(default 2.0) and the fraction at most --fraction (default 0.02), 1 when the images are too
different or differ in size, 2 on a decoding problem. Handles the 8-bit non-interlaced RGB(A) and
grayscale PNGs the engine writes.
"""
import struct
import sys
import zlib


def decode(path):
    data = open(path, "rb").read()
    if data[:8] != b"\x89PNG\r\n\x1a\n":
        raise ValueError(f"{path}: not a PNG")
    pos, idat, header = 8, [], None
    while pos < len(data):
        length, kind = struct.unpack(">I4s", data[pos:pos + 8])
        body = data[pos + 8:pos + 8 + length]
        pos += 12 + length
        if kind == b"IHDR":
            header = struct.unpack(">IIBBBBB", body)
        elif kind == b"IDAT":
            idat.append(body)
    width, height, depth, color, _, _, interlace = header
    channels = {0: 1, 2: 3, 4: 2, 6: 4}.get(color)
    if depth != 8 or channels is None or interlace:
        raise ValueError(f"{path}: unsupported PNG (depth {depth}, color type {color}, interlace {interlace})")
    raw = zlib.decompress(b"".join(idat))
    stride = width * channels
    rows, prev = [], bytearray(stride)
    for y in range(height):
        base = y * (stride + 1)
        filt, line = raw[base], bytearray(raw[base + 1:base + 1 + stride])
        if filt == 1:
            for i in range(channels, stride):
                line[i] = (line[i] + line[i - channels]) & 255
        elif filt == 2:
            for i in range(stride):
                line[i] = (line[i] + prev[i]) & 255
        elif filt == 3:
            for i in range(stride):
                left = line[i - channels] if i >= channels else 0
                line[i] = (line[i] + ((left + prev[i]) >> 1)) & 255
        elif filt == 4:
            for i in range(stride):
                a = line[i - channels] if i >= channels else 0
                b = prev[i]
                c = prev[i - channels] if i >= channels else 0
                p = a + b - c
                pa, pb, pc = abs(p - a), abs(p - b), abs(p - c)
                pred = a if pa <= pb and pa <= pc else b if pb <= pc else c
                line[i] = (line[i] + pred) & 255
        elif filt != 0:
            raise ValueError(f"{path}: bad filter {filt}")
        rows.append(line)
        prev = line
    return width, height, channels, rows


def main(argv):
    mean_limit, fraction_limit, channel_limit = 2.0, 0.02, 16
    args = []
    it = iter(argv)
    for arg in it:
        if arg == "--mean":
            mean_limit = float(next(it))
        elif arg == "--fraction":
            fraction_limit = float(next(it))
        elif arg == "--channel":
            channel_limit = int(next(it))
        else:
            args.append(arg)
    if len(args) != 2:
        print(__doc__)
        return 2
    try:
        a, b = decode(args[0]), decode(args[1])
    except Exception as error:  # noqa: BLE001
        print(f"error: {error}")
        return 2
    if a[:3] != b[:3]:
        print(f"size or format differs: {a[:3]} vs {b[:3]}")
        return 1
    width, height, channels = a[:3]
    total, bad = 0, 0
    for ra, rb in zip(a[3], b[3]):
        if ra == rb:
            continue
        for x in range(width):
            i = x * channels
            worst = 0
            for c in range(channels):
                d = abs(ra[i + c] - rb[i + c])
                total += d
                worst = max(worst, d)
            if worst > channel_limit:
                bad += 1
    mean = total / (width * height * channels)
    fraction = bad / (width * height)
    print(f"mean diff {mean:.3f}, {fraction * 100:.2f}% of pixels differ by more than {channel_limit}")
    return 0 if mean <= mean_limit and fraction <= fraction_limit else 1


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
