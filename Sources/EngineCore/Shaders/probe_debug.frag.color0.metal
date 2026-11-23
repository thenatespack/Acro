// Generated from probe_debug.frag by Scripts/compile-shaders.sh — do not edit.
// Edit the GLSL and rerun the script (needs glslc and spirv-cross).
// spirv-fnv1a64: 81cf661810e87f61
// glsl-fnv1a64: 03a6f22025cdef19

#include <metal_stdlib>
#include <simd/simd.h>

using namespace metal;

struct _281
{
    float4x4 _m0;
    float4x4 _m1;
    float4x4 _m2;
    float4x4 _m3;
    float4 _m4;
    float4 _m5;
    float4 _m6;
    float4 _m7;
    float4 _m8;
    float4 _m9;
    float4 _m10;
    float4 _m11;
    float4 _m12;
    float4 _m13;
    float4x4 _m14[4];
    float4x4 _m15[8];
    float4 _m16;
    float4 _m17;
    float4 _m18;
    float4 _m19;
    float4 _m20;
    float4 _m21;
    float4 _m22;
    float4 _m23;
    float4 _m24;
    float4 _m25;
    float4 _m26[8];
    float4 _m27[4];
    float4 _m28[4];
    float4 _m29;
    float4x4 _m30;
    float4 _m31;
    float4 _m32;
    float4 _m33;
    float4 _m34;
};

struct _1279
{
    uint4 _m0[1];
};

struct fragment_main_out
{
    float4 m_3470 [[color(0)]];
};

struct fragment_main_in
{
    float3 m_3037 [[user(locn0)]];
    float3 m_2946 [[user(locn1)]];
    float4 m_3410 [[user(locn3)]];
    float4 m_3478 [[user(locn6)]];
    float4 m_3479 [[user(locn7)]];
};

fragment fragment_main_out fragment_main(fragment_main_in in [[stage_in]], constant _281& _283 [[buffer(15)]], const device _1279& _1281 [[buffer(21)]])
{
    float2 _3477;
    fragment_main_out out = {};
    float3 _3402 = fast::normalize(in.m_2946);
    float3 _5631;
    if (in.m_3410.x < 0.5)
    {
        int _3421 = int(in.m_3410.y + 0.5);
        int _4519 = int(((device uint*)&_1281._m0[_3421 + 6])[0u]);
        float3 _3430 = reflect(-fast::normalize(_283._m6.xyz - in.m_3037), _3402);
        float2 _4657 = (float2((precise::atan2(dot(as_type<float4>(_1281._m0[_3421]).xyz, _3430), -dot(as_type<float4>(_1281._m0[_3421 + 2]).xyz, _3430)) * 0.15915493667125701904296875) + 0.5, acos(fast::clamp(dot(as_type<float4>(_1281._m0[_3421 + 1]).xyz, _3430), -1.0, 1.0)) * 0.3183098733425140380859375) * float2(256.0, 128.0)) - float2(0.5);
        float2 _4659 = floor(_4657);
        float2 _4662 = _4657 - _4659;
        int _4665 = int(_4659.x);
        int _4668 = int(_4659.y);
        int _5603;
        if (_4665 < 0)
        {
            _5603 = _4665 + 256;
        }
        else
        {
            _5603 = _4665;
        }
        int _5604;
        if (_5603 >= 256)
        {
            _5604 = _5603 - 256;
        }
        else
        {
            _5604 = _5603;
        }
        int _4688 = _5604 + 1;
        int _5644 = (_4688 == 256) ? 0 : _4688;
        int _4756 = _4519 + (max(_4668, 0) * 256);
        int _4758 = _4756 + _5604;
        int _4760 = _4758 >> 1;
        uint2 _5610;
        if ((_4758 & 1) == 0)
        {
            _5610 = _1281._m0[_4760].xy;
        }
        else
        {
            _5610 = _1281._m0[_4760].zw;
        }
        int _4796 = _4756 + _5644;
        int _4798 = _4796 >> 1;
        uint2 _5612;
        if ((_4796 & 1) == 0)
        {
            _5612 = _1281._m0[_4798].xy;
        }
        else
        {
            _5612 = _1281._m0[_4798].zw;
        }
        int _4832 = _4519 + (min((_4668 + 1), 127) * 256);
        int _4834 = _4832 + _5604;
        int _4836 = _4834 >> 1;
        uint2 _5615;
        if ((_4834 & 1) == 0)
        {
            _5615 = _1281._m0[_4836].xy;
        }
        else
        {
            _5615 = _1281._m0[_4836].zw;
        }
        int _4872 = _4832 + _5644;
        int _4874 = _4872 >> 1;
        uint2 _5616;
        if ((_4872 & 1) == 0)
        {
            _5616 = _1281._m0[_4874].xy;
        }
        else
        {
            _5616 = _1281._m0[_4874].zw;
        }
        float3 _4734 = float3(_4662.x);
        _5631 = mix(mix(float3(float2(as_type<half2>(_5610.x)), float2(as_type<half2>(_5610.y)).x), float3(float2(as_type<half2>(_5612.x)), float2(as_type<half2>(_5612.y)).x), _4734), mix(float3(float2(as_type<half2>(_5615.x)), float2(as_type<half2>(_5615.y)).x), float3(float2(as_type<half2>(_5616.x)), float2(as_type<half2>(_5616.y)).x), _4734), float3(_4662.y));
    }
    else
    {
        int _3444 = int(in.m_3410.y + 0.5);
        int _5188 = _3444 + 3;
        float3 _5602;
        if (float2(as_type<half2>(((device uint*)&_1281._m0[_5188])[1u])).y > 0.5)
        {
            int _3454 = int(in.m_3410.z + 0.5);
            float _5203 = dot(as_type<float4>(_1281._m0[_3454]).xyz, _3402);
            float _5209 = dot(as_type<float4>(_1281._m0[_3454 + 1]).xyz, _3402);
            float _5215 = dot(as_type<float4>(_1281._m0[_3454 + 2]).xyz, _3402);
            float _5251 = 1.09254801273345947265625 * _5203;
            int _5315 = _3444 + 1;
            int _5319 = _3444 + 2;
            float2 _5331 = float2(as_type<half2>(_1281._m0[_3444].y));
            float2 _5340 = float2(as_type<half2>(_1281._m0[_5315].x));
            float2 _5349 = float2(as_type<half2>(_1281._m0[_5315].w));
            float2 _5358 = float2(as_type<half2>(_1281._m0[_5319].z));
            float3 _5436 = ((((((float3(float2(as_type<half2>(_1281._m0[_3444].x)), _5331.x) * 0.2820949852466583251953125) + (float3(_5331.y, float2(as_type<half2>(_1281._m0[_3444].z))) * (0.48860299587249755859375 * _5209))) + (float3(float2(as_type<half2>(_1281._m0[_3444].w)), _5340.x) * (0.48860299587249755859375 * _5215))) + (float3(_5340.y, float2(as_type<half2>(_1281._m0[_5315].y))) * (0.48860299587249755859375 * _5203))) + (float3(float2(as_type<half2>(_1281._m0[_5315].z)), _5349.x) * (_5251 * _5209))) + (float3(_5349.y, float2(as_type<half2>(_1281._m0[_5319].x))) * ((1.09254801273345947265625 * _5209) * _5215))) + (float3(float2(as_type<half2>(_1281._m0[_5319].y)), _5358.x) * (0.3153919875621795654296875 * (((3.0 * _5215) * _5215) - 1.0)));
            _5602 = fast::max((_5436 + (float3(_5358.y, float2(as_type<half2>(_1281._m0[_5319].w))) * (_5251 * _5215))) + (float3(float2(as_type<half2>(_1281._m0[_5188].x)), float2(as_type<half2>(_1281._m0[_5188].y)).x) * (0.546274006366729736328125 * ((_5203 * _5203) - (_5209 * _5209)))), float3(0.0));
        }
        else
        {
            _5602 = float3(0.60000002384185791015625, 0.0, 0.0);
        }
        _5631 = _5602;
    }
    out.m_3470 = float4(_5631, 1.0);
    float2 _5632;
    do
    {
        if (in.m_3479.w <= 0.0)
        {
            _5632 = float2(0.0);
            break;
        }
        _5632 = ((in.m_3479.xy / float2(in.m_3479.w)) - (in.m_3478.xy / float2(in.m_3478.w))) * float2(0.5, -0.5);
        break;
    } while(false);
    _3477 = _5632;
    return out;
}

