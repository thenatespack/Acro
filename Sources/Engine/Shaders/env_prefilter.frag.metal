// Generated from env_prefilter.frag by Scripts/compile-shaders.sh — do not edit.
// Edit the GLSL and rerun the script (needs glslc and spirv-cross).
// spirv-fnv1a64: 16e3facbf0fb45b3
// glsl-fnv1a64: 0e339047ceace433

#include <metal_stdlib>
#include <simd/simd.h>

using namespace metal;

struct _252
{
    int2 _m0;
    float2 _m1;
    float _m2;
    int _m3;
};

struct fragment_main_out
{
    float4 m_397 [[color(0)]];
};

fragment fragment_main_out fragment_main(constant _252& _254 [[buffer(16)]], texture2d<float> _378 [[texture(1)]], sampler _379 [[sampler(1)]], float4 gl_FragCoord [[position]])
{
    fragment_main_out out = {};
    float2 _258 = gl_FragCoord.xy / _254._m1;
    float _438 = (_258.x - 0.5) * 6.283185482025146484375;
    float _441 = _258.y * 3.1415927410125732421875;
    float _443 = sin(_441);
    float _449 = cos(_441);
    float3 _455 = float3(_443 * sin(_438), _449, (-_443) * cos(_438));
    float3 _277 = fast::normalize(cross(select(float3(1.0, 0.0, 0.0), float3(0.0, 1.0, 0.0), bool3(abs(_449) < 0.999000012874603271484375)), _455));
    float3 _281 = cross(_455, _277);
    int4 _288 = int4(0, 0, _254._m0);
    float _296 = _254._m2 * _254._m2;
    float3 _638;
    float _639;
    _639 = 0.0;
    _638 = float3(0.0);
    float3 _657;
    float _658;
    for (int _637 = 0; _637 < _254._m3; _639 = _658, _638 = _657, _637++)
    {
        float _467 = float(reverse_bits(uint(_637))) * 2.3283064365386962890625e-10;
        float _322 = 6.283185482025146484375 * (float(_637) / float(_254._m3));
        float _334 = sqrt((1.0 - _467) / (1.0 + ((_296 - 1.0) * _467)));
        float _341 = sqrt(fast::max(1.0 - (_334 * _334), 0.0));
        float3 _359 = ((_277 * (_341 * cos(_322))) + (_281 * (_341 * sin(_322)))) + (_455 * _334);
        float3 _369 = (_359 * (2.0 * dot(_455, _359))) - _455;
        float _373 = dot(_455, _369);
        if (_373 > 0.0)
        {
            float2 _505 = (float2((precise::atan2(_369.x, -_369.z) * 0.15915493667125701904296875) + 0.5, acos(fast::clamp(_369.y, -1.0, 1.0)) * 0.3183098733425140380859375) * float2(_288.zw)) - float2(0.5);
            float2 _507 = floor(_505);
            float2 _510 = _505 - _507;
            int _513 = int(_507.x);
            int _516 = int(_507.y);
            int _640;
            if (_513 < 0)
            {
                _640 = _513 + _254._m0.x;
            }
            else
            {
                _640 = _513;
            }
            int _641;
            if (_640 >= _254._m0.x)
            {
                _641 = _640 - _254._m0.x;
            }
            else
            {
                _641 = _640;
            }
            int _536 = _641 + 1;
            int _662 = (_536 == _254._m0.x) ? 0 : _536;
            int _551 = min((_516 + 1), (_254._m0.y - 1));
            int _553 = max(_516, 0);
            int2 _558 = _288.xy;
            float3 _606 = float3(_510.x);
            _658 = _639 + _373;
            _657 = _638 + (mix(mix(_378.read(uint2((_558 + int2(_641, _553))), 0).xyz, _378.read(uint2((_558 + int2(_662, _553))), 0).xyz, _606), mix(_378.read(uint2((_558 + int2(_641, _551))), 0).xyz, _378.read(uint2((_558 + int2(_662, _551))), 0).xyz, _606), float3(_510.y)) * _373);
        }
        else
        {
            _658 = _639;
            _657 = _638;
        }
    }
    out.m_397 = float4(_638 / float3(fast::max(_639, 9.9999999747524270787835121154785e-07)), 1.0);
    return out;
}

