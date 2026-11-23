// Generated from probe_equirect.frag by Scripts/compile-shaders.sh — do not edit.
// Edit the GLSL and rerun the script (needs glslc and spirv-cross).
// spirv-fnv1a64: 5915a9127fd36320
// glsl-fnv1a64: c68d18831a6a5220

#include <metal_stdlib>
#include <simd/simd.h>

using namespace metal;

struct _160
{
    int2 _m0;
    int _m1;
};

struct fragment_main_out
{
    float4 m_329 [[color(0)]];
};

fragment fragment_main_out fragment_main(constant _160& _162 [[buffer(16)]], texture2d<float> _66 [[texture(1)]], texture2d<float> _85 [[texture(2)]], texture2d<float> _99 [[texture(3)]], texture2d<float> _113 [[texture(4)]], texture2d<float> _127 [[texture(5)]], texture2d<float> _136 [[texture(6)]], sampler _70 [[sampler(1)]], float4 gl_FragCoord [[position]])
{
    fragment_main_out out = {};
    float2 _167 = gl_FragCoord.xy / float2(_162._m0);
    float _381 = (_167.x - 0.5) * 6.283185482025146484375;
    float _384 = _167.y * 3.1415927410125732421875;
    float _386 = sin(_384);
    float _390 = _386 * sin(_381);
    float _392 = cos(_384);
    float _397 = (-_386) * cos(_381);
    float3 _398 = float3(_390, _392, _397);
    float3 _172 = abs(_398);
    float _174 = _172.x;
    float _176 = _172.y;
    bool _177 = _174 >= _176;
    bool _186;
    if (_177)
    {
        _186 = _174 >= _172.z;
    }
    else
    {
        _186 = _177;
    }
    float3 _725;
    float3 _727;
    int _729;
    if (_186)
    {
        bool _193 = _390 >= 0.0;
        _729 = _193 ? 0 : 1;
        _727 = float3(0.0, 1.0, 0.0);
        _725 = float3(_193 ? 1.0 : (-1.0), 0.0, 0.0);
    }
    else
    {
        float3 _726;
        float3 _728;
        int _730;
        if (_176 >= _172.z)
        {
            bool _214 = _392 >= 0.0;
            float _219 = _214 ? 1.0 : (-1.0);
            _730 = _214 ? 2 : 3;
            _728 = float3(0.0, 0.0, _219);
            _726 = float3(0.0, _219, 0.0);
        }
        else
        {
            bool _229 = _397 >= 0.0;
            _730 = _229 ? 4 : 5;
            _728 = float3(0.0, 1.0, 0.0);
            _726 = float3(0.0, 0.0, _229 ? 1.0 : (-1.0));
        }
        _729 = _730;
        _727 = _728;
        _725 = _726;
    }
    float _244 = dot(_398, _725);
    float2 _269 = (float2(0.5 + ((0.5 * dot(_398, cross(_725, _727))) / _244), 0.5 - ((0.5 * dot(_398, _727)) / _244)) * float(_162._m1)) - float2(0.5);
    float2 _272 = floor(_269);
    float2 _276 = _269 - _272;
    int2 _283 = int2(_272);
    int2 _286 = int2(_162._m1 - 1);
    int2 _287 = clamp(_283, int2(0), _286);
    int2 _295 = clamp(_283 + int2(1), int2(0), _286);
    bool _403 = _729 == 0;
    float3 _731;
    if (_403)
    {
        _731 = _66.read(uint2(_287), 0).xyz;
    }
    else
    {
        float3 _732;
        if (_729 == 1)
        {
            _732 = _85.read(uint2(_287), 0).xyz;
        }
        else
        {
            float3 _733;
            if (_729 == 2)
            {
                _733 = _99.read(uint2(_287), 0).xyz;
            }
            else
            {
                float3 _734;
                if (_729 == 3)
                {
                    _734 = _113.read(uint2(_287), 0).xyz;
                }
                else
                {
                    float3 _735;
                    if (_729 == 4)
                    {
                        _735 = _127.read(uint2(_287), 0).xyz;
                    }
                    else
                    {
                        _735 = _136.read(uint2(_287), 0).xyz;
                    }
                    _734 = _735;
                }
                _733 = _734;
            }
            _732 = _733;
        }
        _731 = _732;
    }
    int2 _307 = int2(_295.x, _287.y);
    float3 _741;
    if (_403)
    {
        _741 = _66.read(uint2(_307), 0).xyz;
    }
    else
    {
        float3 _742;
        if (_729 == 1)
        {
            _742 = _85.read(uint2(_307), 0).xyz;
        }
        else
        {
            float3 _743;
            if (_729 == 2)
            {
                _743 = _99.read(uint2(_307), 0).xyz;
            }
            else
            {
                float3 _744;
                if (_729 == 3)
                {
                    _744 = _113.read(uint2(_307), 0).xyz;
                }
                else
                {
                    float3 _745;
                    if (_729 == 4)
                    {
                        _745 = _127.read(uint2(_307), 0).xyz;
                    }
                    else
                    {
                        _745 = _136.read(uint2(_307), 0).xyz;
                    }
                    _744 = _745;
                }
                _743 = _744;
            }
            _742 = _743;
        }
        _741 = _742;
    }
    int2 _317 = int2(_287.x, _295.y);
    float3 _751;
    if (_403)
    {
        _751 = _66.read(uint2(_317), 0).xyz;
    }
    else
    {
        float3 _752;
        if (_729 == 1)
        {
            _752 = _85.read(uint2(_317), 0).xyz;
        }
        else
        {
            float3 _753;
            if (_729 == 2)
            {
                _753 = _99.read(uint2(_317), 0).xyz;
            }
            else
            {
                float3 _754;
                if (_729 == 3)
                {
                    _754 = _113.read(uint2(_317), 0).xyz;
                }
                else
                {
                    float3 _755;
                    if (_729 == 4)
                    {
                        _755 = _127.read(uint2(_317), 0).xyz;
                    }
                    else
                    {
                        _755 = _136.read(uint2(_317), 0).xyz;
                    }
                    _754 = _755;
                }
                _753 = _754;
            }
            _752 = _753;
        }
        _751 = _752;
    }
    float3 _761;
    if (_403)
    {
        _761 = _66.read(uint2(_295), 0).xyz;
    }
    else
    {
        float3 _762;
        if (_729 == 1)
        {
            _762 = _85.read(uint2(_295), 0).xyz;
        }
        else
        {
            float3 _763;
            if (_729 == 2)
            {
                _763 = _99.read(uint2(_295), 0).xyz;
            }
            else
            {
                float3 _764;
                if (_729 == 3)
                {
                    _764 = _113.read(uint2(_295), 0).xyz;
                }
                else
                {
                    float3 _765;
                    if (_729 == 4)
                    {
                        _765 = _127.read(uint2(_295), 0).xyz;
                    }
                    else
                    {
                        _765 = _136.read(uint2(_295), 0).xyz;
                    }
                    _764 = _765;
                }
                _763 = _764;
            }
            _762 = _763;
        }
        _761 = _762;
    }
    float3 _334 = float3(_276.x);
    out.m_329 = float4(mix(mix(_731 / (float3(1.0) - fast::min(_731, float3(0.99500000476837158203125))), _741 / (float3(1.0) - fast::min(_741, float3(0.99500000476837158203125))), _334), mix(_751 / (float3(1.0) - fast::min(_751, float3(0.99500000476837158203125))), _761 / (float3(1.0) - fast::min(_761, float3(0.99500000476837158203125))), _334), float3(_276.y)), 1.0);
    return out;
}

