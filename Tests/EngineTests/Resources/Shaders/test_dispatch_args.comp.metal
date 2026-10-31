// Generated from test_dispatch_args.comp by Scripts/compile-shaders.sh — do not edit.
// Edit the GLSL and rerun the script (needs glslc and spirv-cross).
// spirv-fnv1a64: 751970fb6307d525
// glsl-fnv1a64: aa81c7b4a657b21c

#include <metal_stdlib>
#include <simd/simd.h>

using namespace metal;

struct _8
{
    uint _m0[1];
};

struct _13
{
    uint _m0;
};

constant uint3 gl_WorkGroupSize [[maybe_unused]] = uint3(1u);

kernel void compute_main(constant _13& _15 [[buffer(16)]], device _8& _10 [[buffer(21)]])
{
    _10._m0[0] = (_15._m0 + 63u) / 64u;
    _10._m0[1] = 1u;
    _10._m0[2] = 1u;
}

