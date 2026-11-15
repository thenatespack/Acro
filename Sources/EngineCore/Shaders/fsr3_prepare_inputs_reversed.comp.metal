// Generated from fsr3_prepare_inputs_reversed.comp by Scripts/compile-shaders.sh — do not edit.
// Edit the GLSL and rerun the script (needs glslc and spirv-cross).
// spirv-fnv1a64: 0b9dde7c21e5404c
// glsl-fnv1a64: dd4436b606bf0b28

#pragma clang diagnostic ignored "-Wunused-variable"
#pragma clang diagnostic ignored "-Wmissing-prototypes"
#pragma clang diagnostic ignored "-Wmissing-braces"

#include <metal_stdlib>
#include <simd/simd.h>
#include <metal_atomic>

using namespace metal;

template<typename T, size_t Num>
struct spvUnsafeArray
{
    T elements[Num ? Num : 1];
    
    thread T& operator [] (size_t pos) thread
    {
        return elements[pos];
    }
    constexpr const thread T& operator [] (size_t pos) const thread
    {
        return elements[pos];
    }
    
    device T& operator [] (size_t pos) device
    {
        return elements[pos];
    }
    constexpr const device T& operator [] (size_t pos) const device
    {
        return elements[pos];
    }
    
    constexpr const constant T& operator [] (size_t pos) const constant
    {
        return elements[pos];
    }
    
    threadgroup T& operator [] (size_t pos) threadgroup
    {
        return elements[pos];
    }
    constexpr const threadgroup T& operator [] (size_t pos) const threadgroup
    {
        return elements[pos];
    }
};

struct _177
{
    int2 _m0;
    int2 _m1;
    int2 _m2;
    int2 _m3;
    float4 _m4;
    float2 _m5;
    float2 _m6;
    float2 _m7;
    float _m8;
    float _m9;
    float _m10;
    float _m11;
    float _m12;
    float _m13;
    float _m14;
    float _m15;
    float _m16;
    float _m17;
    float _m18;
    uint2 _m19;
};

struct _333
{
    uint _m0[1];
};

constant uint3 gl_WorkGroupSize [[maybe_unused]] = uint3(8u, 8u, 1u);

constant spvUnsafeArray<int2, 9> _589 = spvUnsafeArray<int2, 9>({ int2(0), int2(1, 0), int2(0, 1), int2(0, -1), int2(-1, 0), int2(-1, 1), int2(1), int2(-1), int2(1, -1) });
constant spvUnsafeArray<int2, 4> _1442 = spvUnsafeArray<int2, 4>({ int2(0), int2(1, 0), int2(0, 1), int2(1) });

kernel void compute_main(constant _177& _179 [[buffer(16)]], device _333& _335 [[buffer(20)]], texture2d<float> _248 [[texture(1)]], texture2d<float> _205 [[texture(2)]], texture2d<float> _228 [[texture(3)]], texture2d<float, access::write> _363 [[texture(8)]], texture2d<float, access::write> _347 [[texture(9)]], texture2d<float, access::write> _274 [[texture(10)]], texture2d<float, access::write> _288 [[texture(11)]], uint3 gl_GlobalInvocationID [[thread_position_in_grid]])
{
    int2 _744 = int2(gl_GlobalInvocationID.xy);
    spvUnsafeArray<float, 9> _818;
    for (int _1419 = 0; _1419 < 9; _1419++)
    {
        int2 _839 = _744 + _589[_1419];
        float4 _1432;
        if (all(uint2(_839) < uint2(int2(_205.get_width(), _205.get_height()))))
        {
            _1432 = _205.read(uint2(_839), 0);
        }
        else
        {
            _1432 = float4(0.0);
        }
        _818[_1419] = _1432.x;
    }
    float _1421;
    int2 _1422;
    float _1423;
    _1423 = _818[0];
    _1422 = _744;
    _1421 = _818[0];
    float _1434;
    int2 _1436;
    float _1438;
    for (int _1420 = 1; _1420 < 9; _1423 = _1438, _1422 = _1436, _1421 = _1434, _1420++)
    {
        int2 _865 = _744 + _589[_1420];
        if (all(uint2(_865) < uint2(_179._m0)))
        {
            bool _876 = _818[_1420] > _1423;
            float _1435;
            if (_876)
            {
                _1435 = fast::min(_1421, _818[_1420]);
            }
            else
            {
                _1435 = _1421;
            }
            _1438 = _876 ? _818[_1420] : _1423;
            _1436 = select(_1422, _865, bool2(_876));
            _1434 = _1435;
        }
        else
        {
            _1438 = _1423;
            _1436 = _1422;
            _1434 = _1421;
        }
    }
    float4 _1424;
    if (all(uint2(_1422) < uint2(int2(_248.get_width(), _248.get_height()))))
    {
        _1424 = _248.read(uint2(_1422), 0);
    }
    else
    {
        _1424 = float4(0.0);
    }
    float2 _1004 = float2(_179._m0);
    float2 _1117 = ((((float2(_744) + float2(0.5)) / _1004) + (_1424.xy * float(length(_1424.xy * float2(3840.0, 2160.0)) > mix(0.25, 0.75, fast::clamp(fast::min((_179._m4.y / (_1423 - _179._m4.x)) * _179._m11, 65504.0) * 0.00999999977648258209228515625, 0.0, 1.0))))) * _1004) - float2(0.5);
    int2 _1120 = int2(floor(_1117));
    float2 _1160 = fract(_1117);
    float _1129 = _1160.x;
    float _1130 = 1.0 - _1129;
    float _1132 = _1160.y;
    float _1133 = 1.0 - _1132;
    spvUnsafeArray<float, 4> _1403 = spvUnsafeArray<float, 4>({ _1130 * _1133, _1129 * _1133, _1130 * _1132, _1129 * _1132 });
    spvUnsafeArray<float, 4> _1367 = _1403;
    for (int _1425 = 0; _1425 < 4; _1425++)
    {
        if (_1367[_1425] > 0.0006099999882280826568603515625)
        {
            int2 _1029 = _1120 + _1442[_1425];
            bool _1172 = all(uint2(_1029) < uint2(_179._m0));
            if (_1172)
            {
                do
                {
                    if (!_1172)
                    {
                        break;
                    }
                    uint _1190 = atomic_fetch_max_explicit((device atomic_uint*)&_335._m0[uint((_1029.y * _179._m0.x) + _1029.x)], as_type<uint>(_1423), memory_order_relaxed);
                    break;
                } while(false);
            }
        }
    }
    if (all(gl_GlobalInvocationID.xy < uint2(int2(_363.get_width(), _363.get_height()))))
    {
        _363.write(float4(_1424.xy, 0.0, 0.0), uint2(_744));
    }
    if (all(gl_GlobalInvocationID.xy < uint2(int2(_347.get_width(), _347.get_height()))))
    {
        _347.write(float4(_1423, 0.0, 0.0, 0.0), uint2(_744));
    }
    if (all(gl_GlobalInvocationID.xy < uint2(int2(_274.get_width(), _274.get_height()))))
    {
        _274.write(float4(fast::min((_179._m4.y / (_1421 - _179._m4.x)) * _179._m11, 65504.0), 0.0, 0.0, 0.0), uint2(_744));
    }
    float4 _1426;
    if (all(gl_GlobalInvocationID.xy < uint2(int2(_228.get_width(), _228.get_height()))))
    {
        _1426 = _228.read(uint2(_744), 0);
    }
    else
    {
        _1426 = float4(0.0);
    }
    if (all(gl_GlobalInvocationID.xy < uint2(int2(_288.get_width(), _288.get_height()))))
    {
        _288.write(float4(dot(fast::max(float3(0.0), _1426.xyz), float3(0.2125999927520751953125, 0.715200006961822509765625, 0.072200000286102294921875)), 0.0, 0.0, 0.0), uint2(_744));
    }
}

