// Generated from ui.frag by Scripts/compile-shaders.sh — do not edit.
// Edit the GLSL and rerun the script (needs glslc and spirv-cross).
// spirv-fnv1a64: 825fb5c7b32eb4c9

#include <metal_stdlib>
#include <simd/simd.h>

using namespace metal;

struct fragment_main_out
{
    float4 m_221 [[color(0)]];
};

struct fragment_main_in
{
    float2 m_120 [[user(locn0)]];
    float4 m_169 [[user(locn1)]];
    float2 m_138 [[user(locn2)]];
    float2 m_139 [[user(locn3), flat]];
    float4 m_140 [[user(locn4), flat]];
    float4 m_127 [[user(locn5), flat]];
};

fragment fragment_main_out fragment_main(fragment_main_in in [[stage_in]], texture2d<float> _111 [[texture(1)]], sampler _115 [[sampler(1)]])
{
    fragment_main_out out = {};
    float4 _122 = _111.sample(_115, in.m_120);
    int _133 = int(in.m_127.y + 0.5);
    float _324;
    if (in.m_138.x < 0.0)
    {
        float _323;
        if (in.m_138.y < 0.0)
        {
            _323 = in.m_140.x;
        }
        else
        {
            _323 = in.m_140.w;
        }
        _324 = _323;
    }
    else
    {
        float _322;
        if (in.m_138.y < 0.0)
        {
            _322 = in.m_140.y;
        }
        else
        {
            _322 = in.m_140.z;
        }
        _324 = _322;
    }
    float2 _275 = (abs(in.m_138) - in.m_139) + float2(_324);
    float _288 = (fast::min(fast::max(_275.x, _275.y), 0.0) + length(fast::max(_275, float2(0.0)))) - _324;
    float _329;
    if (in.m_127.x > 0.0)
    {
        float _155 = 0.5 * in.m_127.x;
        _329 = fast::clamp(0.5 - (abs(_288 + _155) - _155), 0.0, 1.0);
    }
    else
    {
        _329 = fast::clamp(0.5 - _288, 0.0, 1.0);
    }
    float4 _179 = float4(mix(in.m_169.xyz * float3(0.077399380505084991455078125), powr((in.m_169.xyz + float3(0.054999999701976776123046875)) * float3(0.947867333889007568359375), float3(2.400000095367431640625)), step(float3(0.040449999272823333740234375), in.m_169.xyz)), in.m_169.w);
    float4 _325;
    if (_133 == 1)
    {
        _325 = _179 * _122;
    }
    else
    {
        float4 _326;
        if (_133 == 2)
        {
            float4 _316 = _179;
            _316.w = in.m_169.w * _122.w;
            _326 = _316;
        }
        else
        {
            float4 _327;
            if (_133 == 3)
            {
                float4 _320 = _179;
                _320.w = in.m_169.w * fast::clamp(((_122.w - 0.5) / fast::max(in.m_127.z, 9.9999997473787516355514526367188e-05)) + 0.5, 0.0, 1.0);
                _327 = _320;
            }
            else
            {
                _327 = _179;
            }
            _326 = _327;
        }
        _325 = _326;
    }
    out.m_221 = float4(_325.xyz, _325.w * _329);
    return out;
}

