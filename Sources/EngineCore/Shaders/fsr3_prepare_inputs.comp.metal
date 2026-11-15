// Generated from fsr3_prepare_inputs.comp by Scripts/compile-shaders.sh — do not edit.
// Edit the GLSL and rerun the script (needs glslc and spirv-cross).
// spirv-fnv1a64: d9cba5001d0f0750
// glsl-fnv1a64: 75192b0e0f7f2cc6

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

struct _186
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

struct _342
{
    uint _m0[1];
};

constant uint3 gl_WorkGroupSize [[maybe_unused]] = uint3(8u, 8u, 1u);

constant spvUnsafeArray<int2, 9> _598 = spvUnsafeArray<int2, 9>({ int2(0), int2(1, 0), int2(0, 1), int2(0, -1), int2(-1, 0), int2(-1, 1), int2(1), int2(-1), int2(1, -1) });
constant spvUnsafeArray<int2, 4> _1451 = spvUnsafeArray<int2, 4>({ int2(0), int2(1, 0), int2(0, 1), int2(1) });

kernel void compute_main(constant _186& _188 [[buffer(16)]], device _342& _344 [[buffer(20)]], texture2d<float> _257 [[texture(1)]], texture2d<float> _214 [[texture(2)]], texture2d<float> _237 [[texture(3)]], texture2d<float, access::write> _372 [[texture(8)]], texture2d<float, access::write> _356 [[texture(9)]], texture2d<float, access::write> _283 [[texture(10)]], texture2d<float, access::write> _297 [[texture(11)]], uint3 gl_GlobalInvocationID [[thread_position_in_grid]])
{
    int2 _753 = int2(gl_GlobalInvocationID.xy);
    spvUnsafeArray<float, 9> _827;
    for (int _1428 = 0; _1428 < 9; _1428++)
    {
        int2 _848 = _753 + _598[_1428];
        float4 _1441;
        if (all(uint2(_848) < uint2(int2(_214.get_width(), _214.get_height()))))
        {
            _1441 = _214.read(uint2(_848), 0);
        }
        else
        {
            _1441 = float4(0.0);
        }
        _827[_1428] = _1441.x;
    }
    float _1430;
    int2 _1431;
    float _1432;
    _1432 = _827[0];
    _1431 = _753;
    _1430 = _827[0];
    float _1443;
    int2 _1445;
    float _1447;
    for (int _1429 = 1; _1429 < 9; _1432 = _1447, _1431 = _1445, _1430 = _1443, _1429++)
    {
        int2 _874 = _753 + _598[_1429];
        if (all(uint2(_874) < uint2(_188._m0)))
        {
            bool _885 = _827[_1429] < _1432;
            float _1444;
            if (_885)
            {
                _1444 = fast::max(_1430, _827[_1429]);
            }
            else
            {
                _1444 = _1430;
            }
            _1447 = _885 ? _827[_1429] : _1432;
            _1445 = select(_1431, _874, bool2(_885));
            _1443 = _1444;
        }
        else
        {
            _1447 = _1432;
            _1445 = _1431;
            _1443 = _1430;
        }
    }
    float4 _1433;
    if (all(uint2(_1431) < uint2(int2(_257.get_width(), _257.get_height()))))
    {
        _1433 = _257.read(uint2(_1431), 0);
    }
    else
    {
        _1433 = float4(0.0);
    }
    float2 _1013 = float2(_188._m0);
    float2 _1126 = ((((float2(_753) + float2(0.5)) / _1013) + (_1433.xy * float(length(_1433.xy * float2(3840.0, 2160.0)) > mix(0.25, 0.75, fast::clamp(fast::min((_188._m4.y / (_1432 - _188._m4.x)) * _188._m11, 65504.0) * 0.00999999977648258209228515625, 0.0, 1.0))))) * _1013) - float2(0.5);
    int2 _1129 = int2(floor(_1126));
    float2 _1169 = fract(_1126);
    float _1138 = _1169.x;
    float _1139 = 1.0 - _1138;
    float _1141 = _1169.y;
    float _1142 = 1.0 - _1141;
    spvUnsafeArray<float, 4> _1412 = spvUnsafeArray<float, 4>({ _1139 * _1142, _1138 * _1142, _1139 * _1141, _1138 * _1141 });
    spvUnsafeArray<float, 4> _1376 = _1412;
    for (int _1434 = 0; _1434 < 4; _1434++)
    {
        if (_1376[_1434] > 0.0006099999882280826568603515625)
        {
            int2 _1038 = _1129 + _1451[_1434];
            bool _1181 = all(uint2(_1038) < uint2(_188._m0));
            if (_1181)
            {
                do
                {
                    if (!_1181)
                    {
                        break;
                    }
                    uint _1199 = atomic_fetch_min_explicit((device atomic_uint*)&_344._m0[uint((_1038.y * _188._m0.x) + _1038.x)], as_type<uint>(_1432), memory_order_relaxed);
                    break;
                } while(false);
            }
        }
    }
    if (all(gl_GlobalInvocationID.xy < uint2(int2(_372.get_width(), _372.get_height()))))
    {
        _372.write(float4(_1433.xy, 0.0, 0.0), uint2(_753));
    }
    if (all(gl_GlobalInvocationID.xy < uint2(int2(_356.get_width(), _356.get_height()))))
    {
        _356.write(float4(_1432, 0.0, 0.0, 0.0), uint2(_753));
    }
    if (all(gl_GlobalInvocationID.xy < uint2(int2(_283.get_width(), _283.get_height()))))
    {
        _283.write(float4(fast::min((_188._m4.y / (_1430 - _188._m4.x)) * _188._m11, 65504.0), 0.0, 0.0, 0.0), uint2(_753));
    }
    float4 _1435;
    if (all(gl_GlobalInvocationID.xy < uint2(int2(_237.get_width(), _237.get_height()))))
    {
        _1435 = _237.read(uint2(_753), 0);
    }
    else
    {
        _1435 = float4(0.0);
    }
    if (all(gl_GlobalInvocationID.xy < uint2(int2(_297.get_width(), _297.get_height()))))
    {
        _297.write(float4(dot(fast::max(float3(0.0), _1435.xyz), float3(0.2125999927520751953125, 0.715200006961822509765625, 0.072200000286102294921875)), 0.0, 0.0, 0.0), uint2(_753));
    }
}

