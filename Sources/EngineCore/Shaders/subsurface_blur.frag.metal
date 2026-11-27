// Generated from subsurface_blur.frag by Scripts/compile-shaders.sh — do not edit.
// Edit the GLSL and rerun the script (needs glslc and spirv-cross).
// spirv-fnv1a64: cbbb534940e8d3ea
// glsl-fnv1a64: bc9898baf9cea962

#include <metal_stdlib>
#include <simd/simd.h>

using namespace metal;

struct _36
{
    float4 _m0;
    float4 _m1;
    float4 _m2;
    int4 _m3;
};

struct _166
{
    float4 _m0[25];
};

struct fragment_main_out
{
    float4 m_107 [[color(0)]];
};

fragment fragment_main_out fragment_main(constant _166& _168 [[buffer(2)]], constant _36& _38 [[buffer(16)]], texture2d<float> _86 [[texture(1)]], texture2d<float> _18 [[texture(2)]], sampler _22 [[sampler(1)]], float4 gl_FragCoord [[position]])
{
    fragment_main_out out = {};
    do
    {
        int2 _83 = int2(gl_FragCoord.xy);
        float4 _92 = _86.read(uint2(_83), 0);
        bool _99 = _38._m1.w > 0.5;
        float _101 = _92.w;
        if (_101 > (-0.5))
        {
            out.m_107 = float4(_92.xyz, _99 ? 1.0 : _101);
            break;
        }
        float _131 = fast::max((-1.0) - _101, 0.0);
        float3 _401;
        if (_99)
        {
            _401 = _92.xyz;
        }
        else
        {
            _401 = fast::max(_92.xyz - float3(_131), float3(0.0));
        }
        float4 _327 = _18.read(uint2(_83), 0);
        float _328 = _327.x;
        float _335 = (_38._m0.z * _328) + _38._m0.w;
        float _402;
        if (abs(_335) < 9.9999999600419720025001879548654e-13)
        {
            _402 = 1000000.0;
        }
        else
        {
            _402 = abs(((_38._m0.x * _328) + _38._m0.y) / _335);
        }
        float _354 = fast::clamp(_402, 9.9999997473787516355514526367188e-05, 1000000.0);
        float _160 = (_38._m1.x * _38._m1.y) / _354;
        float _172 = _160 * _168._m0[1].w;
        bool _174 = _172 > 0.25;
        bool _184;
        if (!_174)
        {
            _184 = _172 < (-0.25);
        }
        else
        {
            _184 = _174;
        }
        float3 _404;
        if (_184)
        {
            int _197 = int(_38._m1.z);
            float3 _406;
            _406 = _401 * _168._m0[0].xyz;
            float3 _287;
            for (int _403 = 1; _403 < _197; _406 = _287, _403++)
            {
                int2 _232 = clamp(_83 + int2(round(_38._m2.xy * (_168._m0[_403].w * _160))), int2(0), _38._m3.xy);
                float4 _239 = _86.read(uint2(_232), 0);
                float _243 = _239.w;
                float3 _410;
                if (_243 < (-0.5))
                {
                    float3 _408;
                    if (_99)
                    {
                        _408 = _239.xyz;
                    }
                    else
                    {
                        _408 = fast::max(_239.xyz - float3(fast::max((-1.0) - _243, 0.0)), float3(0.0));
                    }
                    float4 _366 = _18.read(uint2(_232), 0);
                    float _367 = _366.x;
                    float _374 = (_38._m0.z * _367) + _38._m0.w;
                    float _409;
                    if (abs(_374) < 9.9999999600419720025001879548654e-13)
                    {
                        _409 = 1000000.0;
                    }
                    else
                    {
                        _409 = abs(((_38._m0.x * _367) + _38._m0.y) / _374);
                    }
                    _410 = mix(_408, _401, float3(fast::clamp(abs(fast::clamp(_409, 9.9999997473787516355514526367188e-05, 1000000.0) - _354) * _38._m2.z, 0.0, 1.0)));
                }
                else
                {
                    _410 = _401;
                }
                _287 = _406 + (_168._m0[_403].xyz * _410);
            }
            _404 = _406;
        }
        else
        {
            _404 = _401;
        }
        float4 _407;
        if (_99)
        {
            _407 = float4(_404 + float3(_131), 1.0);
        }
        else
        {
            _407 = float4(_404, _101);
        }
        out.m_107 = _407;
        break;
    } while(false);
    return out;
}

