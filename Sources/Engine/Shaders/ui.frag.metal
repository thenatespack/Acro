// Generated from ui.frag by Scripts/compile-shaders.sh — do not edit.
// Edit the GLSL and rerun the script (needs glslc and spirv-cross).
// spirv-fnv1a64: 14116735d09891bb

#include <metal_stdlib>
#include <simd/simd.h>

using namespace metal;

struct fragment_main_out
{
    float4 m_226 [[color(0)]];
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
    float _330;
    if (in.m_138.x < 0.0)
    {
        float _329;
        if (in.m_138.y < 0.0)
        {
            _329 = in.m_140.x;
        }
        else
        {
            _329 = in.m_140.w;
        }
        _330 = _329;
    }
    else
    {
        float _328;
        if (in.m_138.y < 0.0)
        {
            _328 = in.m_140.y;
        }
        else
        {
            _328 = in.m_140.z;
        }
        _330 = _328;
    }
    float2 _280 = (abs(in.m_138) - in.m_139) + float2(_330);
    float _293 = (fast::min(fast::max(_280.x, _280.y), 0.0) + length(fast::max(_280, float2(0.0)))) - _330;
    float _335;
    if (in.m_127.x > 0.0)
    {
        float _155 = 0.5 * in.m_127.x;
        _335 = fast::clamp(0.5 - (abs(_293 + _155) - _155), 0.0, 1.0);
    }
    else
    {
        _335 = fast::clamp(0.5 - _293, 0.0, 1.0);
    }
    float4 _173 = fast::clamp(in.m_169, float4(0.0), float4(1.0));
    float3 _177 = _173.xyz;
    float _180 = _173.w;
    float4 _184 = float4(mix(_177 * float3(0.077399380505084991455078125), powr((_177 + float3(0.054999999701976776123046875)) * float3(0.947867333889007568359375), float3(2.400000095367431640625)), step(float3(0.040449999272823333740234375), _177)), _180);
    float4 _331;
    if (_133 == 1)
    {
        _331 = _184 * _122;
    }
    else
    {
        float4 _332;
        if (_133 == 2)
        {
            float4 _322 = _184;
            _322.w = _180 * _122.w;
            _332 = _322;
        }
        else
        {
            float4 _333;
            if (_133 == 3)
            {
                float4 _326 = _184;
                _326.w = _180 * fast::clamp(((_122.w - 0.5) / fast::max(in.m_127.z, 9.9999997473787516355514526367188e-05)) + 0.5, 0.0, 1.0);
                _333 = _326;
            }
            else
            {
                _333 = _184;
            }
            _332 = _333;
        }
        _331 = _332;
    }
    out.m_226 = float4(_331.xyz, _331.w * _335);
    return out;
}

