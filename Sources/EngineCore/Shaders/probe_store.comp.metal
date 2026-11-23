// Generated from probe_store.comp by Scripts/compile-shaders.sh — do not edit.
// Edit the GLSL and rerun the script (needs glslc and spirv-cross).
// spirv-fnv1a64: 9074fe49add72079
// glsl-fnv1a64: 05345543a44a840e

#pragma clang diagnostic ignored "-Wmissing-prototypes"
#pragma clang diagnostic ignored "-Wmissing-braces"

#include <metal_stdlib>
#include <simd/simd.h>

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

struct _26
{
    int4 _m0;
    float4 _m1;
};

struct _86
{
    uint _m0[1];
};

constant uint3 gl_WorkGroupSize [[maybe_unused]] = uint3(8u, 8u, 1u);

kernel void compute_main(constant _26& _28 [[buffer(16)]], device _86& _88 [[buffer(20)]], texture2d<float> _51 [[texture(1)]], sampler _55 [[sampler(1)]], uint3 gl_GlobalInvocationID [[thread_position_in_grid]])
{
    do
    {
        int2 _17 = int2(gl_GlobalInvocationID.xy);
        int _22 = _17.x;
        bool _33 = _22 >= _28._m0.x;
        bool _43;
        if (!_33)
        {
            _43 = _17.y >= _28._m0.y;
        }
        else
        {
            _43 = _33;
        }
        if (_43)
        {
            break;
        }
        float4 _61 = _51.read(uint2(_17), 0);
        int _70 = (_17.y * _28._m0.x) + _22;
        if (_28._m0.w == 0)
        {
            int _84 = _28._m0.z + (_70 * 2);
            _88._m0[_84] = as_type<uint>(half2(_61.xy));
            _88._m0[_84 + 1] = as_type<uint>(half2(_61.zw));
        }
        else
        {
            if (_70 == 0)
            {
                spvUnsafeArray<float, 32> _131;
                for (int _215 = 0; _215 < 9; )
                {
                    float4 _126 = _51.read(uint2(int2(_215, 0)), 0);
                    int _134 = _215 * 3;
                    _131[_134] = _126.x;
                    _131[_134 + 1] = _126.y;
                    _131[_134 + 2] = _126.z;
                    _215++;
                    continue;
                }
                _131[27] = _28._m1.x;
                for (int _216 = 28; _216 < 32; )
                {
                    _131[_216] = 0.0;
                    _216++;
                    continue;
                }
                for (int _217 = 0; _217 < 16; )
                {
                    int _187 = _217 * 2;
                    _88._m0[_28._m0.z + _217] = as_type<uint>(half2(float2(_131[_187], _131[_187 + 1])));
                    _217++;
                    continue;
                }
            }
        }
        break;
    } while(false);
}

