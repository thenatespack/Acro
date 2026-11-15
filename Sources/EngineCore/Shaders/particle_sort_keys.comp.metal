// Generated from particle_sort_keys.comp by Scripts/compile-shaders.sh — do not edit.
// Edit the GLSL and rerun the script (needs glslc and spirv-cross).
// spirv-fnv1a64: 8aab4b4bdcb8c07d
// glsl-fnv1a64: 9c17953233f2e4d7

#include <metal_stdlib>
#include <simd/simd.h>

using namespace metal;

struct _18
{
    uint _m0[1];
};

struct _45
{
    uint _m0[1];
};

struct _55
{
    float4 _m0;
    float4 _m1;
    float4 _m2;
};

struct _57
{
    _55 _m0[1];
};

struct _66
{
    float4 _m0;
};

struct _83
{
    uint2 _m0[1];
};

constant uint3 gl_WorkGroupSize [[maybe_unused]] = uint3(256u, 1u, 1u);

kernel void compute_main(constant _66& _68 [[buffer(2)]], device _57& _59 [[buffer(20)]], device _45& _47 [[buffer(22)]], device _18& _20 [[buffer(26)]], device _83& _85 [[buffer(27)]], uint3 gl_GlobalInvocationID [[thread_position_in_grid]])
{
    do
    {
        if (gl_GlobalInvocationID.x >= _20._m0[0])
        {
            break;
        }
        uint2 _101;
        if (gl_GlobalInvocationID.x < _20._m0[1])
        {
            _101 = uint2(~as_type<uint>(fast::max(length(_59._m0[_47._m0[gl_GlobalInvocationID.x]]._m0.xyz - _68._m0.xyz), 9.9999999747524270787835121154785e-07)), _47._m0[gl_GlobalInvocationID.x]);
        }
        else
        {
            _101 = uint2(4294967295u);
        }
        _85._m0[gl_GlobalInvocationID.x] = _101;
        break;
    } while(false);
}

