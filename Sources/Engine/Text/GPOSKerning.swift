/// Pair kerning from an OpenType `GPOS` table (the `kern` feature: pair adjustment lookups,
/// formats 1 and 2, including ones behind Extension lookups). stb_truetype's own GPOS support
/// scans every lookup and skips Extension lookups, which is where modern fonts such as Inter
/// keep their kerning, so it finds none there. Only the horizontal advance of the first glyph is
/// applied; scripts and languages are not distinguished (all `kern` lookups are consulted, in order).
struct GPOSKerning {
    private let bytes: [UInt8]
    /// Offset of the GPOS table.
    private let gpos: Int
    private var subtables: [(format: Int, offset: Int)] = []

    /// nil when the font has no GPOS `kern` feature.
    init?(font bytes: [UInt8]) {
        self.bytes = bytes
        guard let table = Self.findTable("GPOS", in: bytes) else { return nil }
        gpos = table
        guard u16(gpos) == 1 else { return nil }
        let featureList = gpos + u16(gpos + 6)
        let lookupList = gpos + u16(gpos + 8)
        var lookups = Set<Int>()
        for i in 0..<u16(featureList) {
            let record = featureList + 2 + i * 6
            guard tag(record) == "kern" else { continue }
            let feature = featureList + u16(record + 4)
            for j in 0..<u16(feature + 2) { lookups.insert(u16(feature + 4 + j * 2)) }
        }
        for lookup in lookups.sorted() where lookup < u16(lookupList) {
            let table = lookupList + u16(lookupList + 2 + lookup * 2)
            for s in 0..<u16(table + 4) {
                var type = u16(table)
                var subtable = table + u16(table + 6 + s * 2)
                if type == 9 {  // Extension: format, real lookup type, 32-bit offset
                    type = u16(subtable + 2)
                    subtable += u32(subtable + 4)
                }
                if type == 2 { subtables.append((u16(subtable), subtable)) }
            }
        }
        if subtables.isEmpty { return nil }
    }

    /// Adjustment in font units to add to the advance of `left` when `right` follows.
    func adjustment(_ left: Int, _ right: Int) -> Int {
        for (format, table) in subtables {
            guard let coverage = coverageIndex(table + u16(table + 2), left) else { continue }
            let format1 = u16(table + 4), format2 = u16(table + 6)
            let size1 = Self.valueSize(format1), size2 = Self.valueSize(format2)
            // The x advance follows the x/y placement values when present.
            let advanceOffset = (format1 & 1 != 0 ? 2 : 0) + (format1 & 2 != 0 ? 2 : 0)
            guard format1 & 4 != 0 else { continue }
            if format == 1 {
                let set = table + u16(table + 10 + coverage * 2)
                let record = 2 + size1 + size2
                for i in 0..<u16(set) where u16(set + 2 + i * record) == right {
                    return i16(set + 2 + i * record + 2 + advanceOffset)
                }
            } else if format == 2 {
                let class1 = classOf(table + u16(table + 8), left)
                let class2 = classOf(table + u16(table + 10), right)
                guard class1 < u16(table + 12), class2 < u16(table + 14) else { return 0 }
                return i16(table + 16 + (class1 * u16(table + 14) + class2) * (size1 + size2) + advanceOffset)
            }
        }
        return 0
    }

    private static func valueSize(_ format: Int) -> Int { format.nonzeroBitCount * 2 }

    private func coverageIndex(_ table: Int, _ glyph: Int) -> Int? {
        switch u16(table) {
        case 1:
            var low = 0, high = u16(table + 2) - 1
            while low <= high {
                let mid = (low + high) / 2
                let value = u16(table + 4 + mid * 2)
                if value == glyph { return mid }
                if glyph < value { high = mid - 1 } else { low = mid + 1 }
            }
        case 2:
            for i in 0..<u16(table + 2) {
                let range = table + 4 + i * 6
                if glyph >= u16(range), glyph <= u16(range + 2) { return u16(range + 4) + glyph - u16(range) }
            }
        default: break
        }
        return nil
    }

    private func classOf(_ table: Int, _ glyph: Int) -> Int {
        switch u16(table) {
        case 1:
            let index = glyph - u16(table + 2)
            if index >= 0, index < u16(table + 4) { return u16(table + 6 + index * 2) }
        case 2:
            for i in 0..<u16(table + 2) {
                let range = table + 4 + i * 6
                if glyph >= u16(range), glyph <= u16(range + 2) { return u16(range + 4) }
            }
        default: break
        }
        return 0
    }

    // Big-endian readers; anything past the end of the data reads as 0, so a corrupt font
    // yields no kerning instead of a crash.
    private func u16(_ offset: Int) -> Int {
        offset >= 0 && offset + 2 <= bytes.count ? Int(bytes[offset]) << 8 | Int(bytes[offset + 1]) : 0
    }

    private func i16(_ offset: Int) -> Int { Int(Int16(truncatingIfNeeded: u16(offset))) }

    private func u32(_ offset: Int) -> Int { u16(offset) << 16 | u16(offset + 2) }

    private func tag(_ offset: Int) -> String {
        String(decoding: (0..<4).map { offset + $0 < bytes.count ? bytes[offset + $0] : 0 }, as: UTF8.self)
    }

    private static func findTable(_ name: String, in bytes: [UInt8]) -> Int? {
        func u16(_ o: Int) -> Int { o + 2 <= bytes.count ? Int(bytes[o]) << 8 | Int(bytes[o + 1]) : 0 }
        guard bytes.count >= 12 else { return nil }
        for i in 0..<u16(4) {
            let record = 12 + i * 16
            guard record + 16 <= bytes.count else { return nil }
            if String(decoding: bytes[record..<record + 4], as: UTF8.self) == name {
                return u16(record + 8) << 16 | u16(record + 10)
            }
        }
        return nil
    }
}
