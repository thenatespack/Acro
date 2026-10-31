// Generated from tonemap.frag by Scripts/compile-shaders.sh — do not edit.
// Edit the GLSL and rerun the script (needs glslc and spirv-cross).
// spirv-fnv1a64: 4ee45fb3b90f6f8f
// glsl-fnv1a64: 5223746e687c9812

#include <metal_stdlib>
#include <simd/simd.h>

using namespace metal;

struct _294
{
    float _m0;
    float _m1;
    int _m2;
    float _m3;
    int2 _m4;
};

struct fragment_main_out
{
    float4 m_371 [[color(0)]];
};

fragment fragment_main_out fragment_main(constant _294& _296 [[buffer(16)]], texture2d<float> _286 [[texture(1)]], texture2d<float> _305 [[texture(2)]], texture2d<float> _327 [[texture(3)]], sampler _38 [[sampler(1)]], float4 gl_FragCoord [[position]])
{
    fragment_main_out out = {};
    int2 _284 = int2(gl_FragCoord.xy);
    float3 _293 = _286.read(uint2(_284), 0).xyz;
    float3 _621;
    if (_296._m1 > 0.0)
    {
        int2 _413 = _284 & int2(1);
        int2 _414 = ((_284 >> int2(1)) - int2(1)) + _413;
        float2 _421 = (float2(_413) * 0.5) + float2(0.25);
        float3 _441 = float3(_421.x);
        _621 = mix(_293, mix(mix(_305.read(uint2(clamp(_414 + int2(1, 0), int2(0), _296._m4)), 0).xyz, _305.read(uint2(clamp(_414, int2(0), _296._m4)), 0).xyz, _441), mix(_305.read(uint2(clamp(_414 + int2(1), int2(0), _296._m4)), 0).xyz, _305.read(uint2(clamp(_414 + int2(0, 1), int2(0), _296._m4)), 0).xyz, _441), float3(1.0 - _421.y)), float3(_296._m1));
    }
    else
    {
        _621 = _293;
    }
    float _622;
    if (_296._m3 > 0.5)
    {
        _622 = _296._m0 * exp2(_327.read(uint2(int2(0)), 0).x);
    }
    else
    {
        _622 = _296._m0;
    }
    float3 _341 = fast::max(_621 * _622, float3(0.0));
    float3 _626;
    if (_296._m2 == 1)
    {
        _626 = _341 / (float3(1.0) + _341);
    }
    else
    {
        float3 _627;
        if (_296._m2 == 2)
        {
            float3 _625;
            do
            {
                float _523 = fast::min(_341.x, fast::min(_341.y, _341.z));
                float _623;
                if (_523 < 0.07999999821186065673828125)
                {
                    _623 = _523 - ((6.25 * _523) * _523);
                }
                else
                {
                    _623 = 0.039999999105930328369140625;
                }
                float3 _539 = _341 - float3(_623);
                float _547 = fast::max(_539.x, fast::max(_539.y, _539.z));
                if (_547 < 0.7599999904632568359375)
                {
                    _625 = _539;
                    break;
                }
                float _557 = 1.0 - (0.057599999010562896728515625 / (_547 + (-0.519999980926513671875)));
                _625 = mix(_539 * (_557 / _547), float3(_557), float3(1.0 - (1.0 / ((0.1500000059604644775390625 * (_547 - _557)) + 1.0))));
                break;
            } while(false);
            _627 = _625;
        }
        else
        {
            float3 _628;
            if (_296._m2 == 3)
            {
                float3 _587 = float3(dot(float3(0.59719002246856689453125, 0.354579985141754150390625, 0.048229999840259552001953125), _341), dot(float3(0.075999997556209564208984375, 0.908339977264404296875, 0.0156599991023540496826171875), _341), dot(float3(0.0284000001847743988037109375, 0.13382999598979949951171875, 0.837769985198974609375), _341));
                float3 _603 = ((_587 * (_587 + float3(0.02457859925925731658935546875))) - float3(9.0537003416102379560470581054688e-05)) / ((_587 * ((_587 * 0.98372900485992431640625) + float3(0.4329510033130645751953125))) + float3(0.23808099329471588134765625));
                _628 = float3(dot(float3(1.60475003719329833984375, -0.5310800075531005859375, -0.0736699998378753662109375), _603), dot(float3(-0.10208000242710113525390625, 1.108129978179931640625, -0.00604999996721744537353515625), _603), dot(float3(-0.00326999998651444911956787109375, -0.07276000082492828369140625, 1.0760200023651123046875), _603));
            }
            else
            {
                _628 = _341;
            }
            _627 = _628;
        }
        _626 = _627;
    }
    out.m_371 = float4(fast::clamp(_626, float3(0.0), float3(1.0)), 1.0);
    return out;
}

