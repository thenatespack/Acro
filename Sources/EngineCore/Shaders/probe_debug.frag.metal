// Generated from probe_debug.frag by Scripts/compile-shaders.sh — do not edit.
// Edit the GLSL and rerun the script (needs glslc and spirv-cross).
// spirv-fnv1a64: 224e407e02a0917a
// glsl-fnv1a64: e93fe8d06869caa2

#include <metal_stdlib>
#include <simd/simd.h>

using namespace metal;

struct _237
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

struct _1235
{
    uint4 _m0[1];
};

struct fragment_main_out
{
    float4 m_2718 [[color(0)]];
    float2 m_2725 [[color(1)]];
};

struct fragment_main_in
{
    float3 m_2285 [[user(locn0)]];
    float3 m_2193 [[user(locn1)]];
    float4 m_2658 [[user(locn3)]];
    float4 m_2726 [[user(locn6)]];
    float4 m_2727 [[user(locn7)]];
};

fragment fragment_main_out fragment_main(fragment_main_in in [[stage_in]], constant _237& _239 [[buffer(15)]], const device _1235& _1237 [[buffer(21)]])
{
    fragment_main_out out = {};
    float3 _2650 = fast::normalize(in.m_2193);
    float3 _4824;
    if (in.m_2658.x < 0.5)
    {
        int _2669 = int(in.m_2658.y + 0.5);
        int _3712 = int(((device uint*)&_1237._m0[_2669 + 6])[0u]);
        float3 _2678 = reflect(-fast::normalize(_239._m6.xyz - in.m_2285), _2650);
        float2 _3850 = (float2((precise::atan2(dot(as_type<float4>(_1237._m0[_2669]).xyz, _2678), -dot(as_type<float4>(_1237._m0[_2669 + 2]).xyz, _2678)) * 0.15915493667125701904296875) + 0.5, acos(fast::clamp(dot(as_type<float4>(_1237._m0[_2669 + 1]).xyz, _2678), -1.0, 1.0)) * 0.3183098733425140380859375) * float2(256.0, 128.0)) - float2(0.5);
        float2 _3852 = floor(_3850);
        float2 _3855 = _3850 - _3852;
        int _3858 = int(_3852.x);
        int _3861 = int(_3852.y);
        int _4796;
        if (_3858 < 0)
        {
            _4796 = _3858 + 256;
        }
        else
        {
            _4796 = _3858;
        }
        int _4797;
        if (_4796 >= 256)
        {
            _4797 = _4796 - 256;
        }
        else
        {
            _4797 = _4796;
        }
        int _3881 = _4797 + 1;
        int _4837 = (_3881 == 256) ? 0 : _3881;
        int _3949 = _3712 + (max(_3861, 0) * 256);
        int _3951 = _3949 + _4797;
        int _3953 = _3951 >> 1;
        uint2 _4803;
        if ((_3951 & 1) == 0)
        {
            _4803 = _1237._m0[_3953].xy;
        }
        else
        {
            _4803 = _1237._m0[_3953].zw;
        }
        int _3989 = _3949 + _4837;
        int _3991 = _3989 >> 1;
        uint2 _4805;
        if ((_3989 & 1) == 0)
        {
            _4805 = _1237._m0[_3991].xy;
        }
        else
        {
            _4805 = _1237._m0[_3991].zw;
        }
        int _4025 = _3712 + (min((_3861 + 1), 127) * 256);
        int _4027 = _4025 + _4797;
        int _4029 = _4027 >> 1;
        uint2 _4808;
        if ((_4027 & 1) == 0)
        {
            _4808 = _1237._m0[_4029].xy;
        }
        else
        {
            _4808 = _1237._m0[_4029].zw;
        }
        int _4065 = _4025 + _4837;
        int _4067 = _4065 >> 1;
        uint2 _4809;
        if ((_4065 & 1) == 0)
        {
            _4809 = _1237._m0[_4067].xy;
        }
        else
        {
            _4809 = _1237._m0[_4067].zw;
        }
        float3 _3927 = float3(_3855.x);
        _4824 = mix(mix(float3(float2(as_type<half2>(_4803.x)), float2(as_type<half2>(_4803.y)).x), float3(float2(as_type<half2>(_4805.x)), float2(as_type<half2>(_4805.y)).x), _3927), mix(float3(float2(as_type<half2>(_4808.x)), float2(as_type<half2>(_4808.y)).x), float3(float2(as_type<half2>(_4809.x)), float2(as_type<half2>(_4809.y)).x), _3927), float3(_3855.y));
    }
    else
    {
        int _2692 = int(in.m_2658.y + 0.5);
        int _4381 = _2692 + 3;
        float3 _4795;
        if (float2(as_type<half2>(((device uint*)&_1237._m0[_4381])[1u])).y > 0.5)
        {
            int _2702 = int(in.m_2658.z + 0.5);
            float _4396 = dot(as_type<float4>(_1237._m0[_2702]).xyz, _2650);
            float _4402 = dot(as_type<float4>(_1237._m0[_2702 + 1]).xyz, _2650);
            float _4408 = dot(as_type<float4>(_1237._m0[_2702 + 2]).xyz, _2650);
            float _4444 = 1.09254801273345947265625 * _4396;
            int _4508 = _2692 + 1;
            int _4512 = _2692 + 2;
            float2 _4524 = float2(as_type<half2>(_1237._m0[_2692].y));
            float2 _4533 = float2(as_type<half2>(_1237._m0[_4508].x));
            float2 _4542 = float2(as_type<half2>(_1237._m0[_4508].w));
            float2 _4551 = float2(as_type<half2>(_1237._m0[_4512].z));
            float3 _4629 = ((((((float3(float2(as_type<half2>(_1237._m0[_2692].x)), _4524.x) * 0.2820949852466583251953125) + (float3(_4524.y, float2(as_type<half2>(_1237._m0[_2692].z))) * (0.48860299587249755859375 * _4402))) + (float3(float2(as_type<half2>(_1237._m0[_2692].w)), _4533.x) * (0.48860299587249755859375 * _4408))) + (float3(_4533.y, float2(as_type<half2>(_1237._m0[_4508].y))) * (0.48860299587249755859375 * _4396))) + (float3(float2(as_type<half2>(_1237._m0[_4508].z)), _4542.x) * (_4444 * _4402))) + (float3(_4542.y, float2(as_type<half2>(_1237._m0[_4512].x))) * ((1.09254801273345947265625 * _4402) * _4408))) + (float3(float2(as_type<half2>(_1237._m0[_4512].y)), _4551.x) * (0.3153919875621795654296875 * (((3.0 * _4408) * _4408) - 1.0)));
            _4795 = fast::max((_4629 + (float3(_4551.y, float2(as_type<half2>(_1237._m0[_4512].w))) * (_4444 * _4408))) + (float3(float2(as_type<half2>(_1237._m0[_4381].x)), float2(as_type<half2>(_1237._m0[_4381].y)).x) * (0.546274006366729736328125 * ((_4396 * _4396) - (_4402 * _4402)))), float3(0.0));
        }
        else
        {
            _4795 = float3(0.60000002384185791015625, 0.0, 0.0);
        }
        _4824 = _4795;
    }
    out.m_2718 = float4(_4824, 1.0);
    float2 _4825;
    do
    {
        if (in.m_2727.w <= 0.0)
        {
            _4825 = float2(0.0);
            break;
        }
        _4825 = ((in.m_2727.xy / float2(in.m_2727.w)) - (in.m_2726.xy / float2(in.m_2726.w))) * float2(0.5, -0.5);
        break;
    } while(false);
    out.m_2725 = _4825;
    return out;
}

