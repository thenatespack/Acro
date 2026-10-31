// Generated from blit.frag by Scripts/compile-shaders.sh — do not edit.
// Edit the GLSL and rerun the script (needs glslc and spirv-cross).
// spirv-fnv1a64: 7954f8fb45ade5b1
// glsl-fnv1a64: ae509c44d944b3bd

#include <metal_stdlib>
#include <simd/simd.h>

using namespace metal;

struct _169
{
    float2 _m0;
    int2 _m1;
    int2 _m2;
    int2 _m3;
};

struct fragment_main_out
{
    float4 m_186 [[color(0)]];
};

struct fragment_main_in
{
    float2 m_223 [[user(locn0)]];
};

fragment fragment_main_out fragment_main(fragment_main_in in [[stage_in]], constant _169& _171 [[buffer(16)]], texture2d<float> _190 [[texture(0)]], sampler _190Smplr [[sampler(0)]], float4 gl_FragCoord [[position]])
{
    fragment_main_out out = {};
    do
    {
        int2 _175 = int2(gl_FragCoord.xy) - _171._m1;
        if (all(_171._m3 == _171._m2))
        {
            out.m_186 = float4(_190.read(uint2(_175), 0).xyz, 1.0);
            break;
        }
        bool _209 = _171._m3.x <= _171._m2.x;
        bool _218;
        if (_209)
        {
            _218 = _171._m3.y <= _171._m2.y;
        }
        else
        {
            _218 = _209;
        }
        if (_218)
        {
            out.m_186 = float4(_190.sample(_190Smplr, in.m_223).xyz, 1.0);
            break;
        }
        int _352 = _175.x * _171._m3.x;
        int _357 = _352 + _171._m3.x;
        int _362 = _352 / _171._m2.x;
        int _373 = (((_357 - 1) / _171._m2.x) - _362) + 1;
        bool _374 = _373 > 8;
        int _691 = _374 ? 4 : _373;
        int _400 = _175.y * _171._m3.y;
        int _405 = _400 + _171._m3.y;
        int _410 = _400 / _171._m2.y;
        int _421 = (((_405 - 1) / _171._m2.y) - _410) + 1;
        bool _422 = _421 > 8;
        int _692 = _422 ? 4 : _421;
        float3 _668;
        _668 = float3(0.0);
        float3 _314;
        for (int _667 = 0; _667 < _692; _668 = _314, _667++)
        {
            int _671;
            if (_422)
            {
                _671 = (_400 + ((((2 * _667) + 1) * _171._m3.y) / 8)) / _171._m2.y;
            }
            else
            {
                _671 = _410 + _667;
            }
            float3 _673;
            _673 = float3(0.0);
            float3 _303;
            for (int _672 = 0; _672 < _691; _673 = _303, _672++)
            {
                int _681;
                if (_374)
                {
                    _681 = (_352 + ((((2 * _672) + 1) * _171._m3.x) / 8)) / _171._m2.x;
                }
                else
                {
                    _681 = _362 + _672;
                }
                float _683;
                do
                {
                    if (_374)
                    {
                        _683 = 1.0;
                        break;
                    }
                    int _502 = _362 + _672;
                    _683 = float(min(_357, ((_502 + 1) * _171._m2.x)) - max(_352, (_502 * _171._m2.x)));
                    break;
                } while(false);
                _303 = fma(_190.read(uint2(int2(_681, _671)), 0).xyz, float3(_683), _673);
            }
            float _676;
            do
            {
                if (_422)
                {
                    _676 = 1.0;
                    break;
                }
                int _535 = _410 + _667;
                _676 = float(min(_405, ((_535 + 1) * _171._m2.y)) - max(_400, (_535 * _171._m2.y)));
                break;
            } while(false);
            _314 = fma(_673, float3(_676), _668);
        }
        float _669;
        if (_374)
        {
            _669 = 4.0;
        }
        else
        {
            _669 = float(_171._m3.x);
        }
        float _670;
        if (_422)
        {
            _670 = 4.0;
        }
        else
        {
            _670 = float(_171._m3.y);
        }
        out.m_186 = float4(_668 / float3(_669 * _670), 1.0);
        break;
    } while(false);
    return out;
}

