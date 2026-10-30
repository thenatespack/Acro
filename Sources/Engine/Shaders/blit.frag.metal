// Generated from blit.frag by Scripts/compile-shaders.sh — do not edit.
// Edit the GLSL and rerun the script (needs glslc and spirv-cross).
// spirv-fnv1a64: a53fe33251697973
// glsl-fnv1a64: 6c671852c4394412

#include <metal_stdlib>
#include <simd/simd.h>

using namespace metal;

struct _161
{
    float2 _m0;
    int2 _m1;
    int2 _m2;
    int2 _m3;
};

struct fragment_main_out
{
    float4 m_185 [[color(0)]];
};

struct fragment_main_in
{
    float2 m_192 [[user(locn0)]];
};

fragment fragment_main_out fragment_main(fragment_main_in in [[stage_in]], constant _161& _163 [[buffer(16)]], texture2d<float> _189 [[texture(0)]], sampler _189Smplr [[sampler(0)]], float4 gl_FragCoord [[position]])
{
    fragment_main_out out = {};
    do
    {
        bool _171 = _163._m3.x <= _163._m2.x;
        bool _180;
        if (_171)
        {
            _180 = _163._m3.y <= _163._m2.y;
        }
        else
        {
            _180 = _171;
        }
        if (_180)
        {
            out.m_185 = float4(_189.sample(_189Smplr, in.m_192).xyz, 1.0);
            break;
        }
        int2 _212 = int2(gl_FragCoord.xy) - _163._m1;
        int _333 = _212.x * _163._m3.x;
        int _338 = _333 + _163._m3.x;
        int _343 = _333 / _163._m2.x;
        int _354 = (((_338 - 1) / _163._m2.x) - _343) + 1;
        bool _355 = _354 > 8;
        int _672 = _355 ? 4 : _354;
        int _381 = _212.y * _163._m3.y;
        int _386 = _381 + _163._m3.y;
        int _391 = _381 / _163._m2.y;
        int _402 = (((_386 - 1) / _163._m2.y) - _391) + 1;
        bool _403 = _402 > 8;
        int _673 = _403 ? 4 : _402;
        float3 _649;
        _649 = float3(0.0);
        float3 _295;
        for (int _648 = 0; _648 < _673; _649 = _295, _648++)
        {
            int _652;
            if (_403)
            {
                _652 = (_381 + ((((2 * _648) + 1) * _163._m3.y) / 8)) / _163._m2.y;
            }
            else
            {
                _652 = _391 + _648;
            }
            float3 _654;
            _654 = float3(0.0);
            float3 _284;
            for (int _653 = 0; _653 < _672; _654 = _284, _653++)
            {
                int _662;
                if (_355)
                {
                    _662 = (_333 + ((((2 * _653) + 1) * _163._m3.x) / 8)) / _163._m2.x;
                }
                else
                {
                    _662 = _343 + _653;
                }
                float _664;
                do
                {
                    if (_355)
                    {
                        _664 = 1.0;
                        break;
                    }
                    int _483 = _343 + _653;
                    _664 = float(min(_338, ((_483 + 1) * _163._m2.x)) - max(_333, (_483 * _163._m2.x)));
                    break;
                } while(false);
                _284 = fma(_189.read(uint2(int2(_662, _652)), 0).xyz, float3(_664), _654);
            }
            float _657;
            do
            {
                if (_403)
                {
                    _657 = 1.0;
                    break;
                }
                int _516 = _391 + _648;
                _657 = float(min(_386, ((_516 + 1) * _163._m2.y)) - max(_381, (_516 * _163._m2.y)));
                break;
            } while(false);
            _295 = fma(_654, float3(_657), _649);
        }
        float _650;
        if (_355)
        {
            _650 = 4.0;
        }
        else
        {
            _650 = float(_163._m3.x);
        }
        float _651;
        if (_403)
        {
            _651 = 4.0;
        }
        else
        {
            _651 = float(_163._m3.y);
        }
        out.m_185 = float4(_649 / float3(_650 * _651), 1.0);
        break;
    } while(false);
    return out;
}

