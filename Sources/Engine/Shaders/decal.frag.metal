// Generated from decal.frag by Scripts/compile-shaders.sh — do not edit.
// Edit the GLSL and rerun the script (needs glslc and spirv-cross).
// spirv-fnv1a64: 29b58d0b22e29645
// glsl-fnv1a64: d9e1c2e0d3077935

#pragma clang diagnostic ignored "-Wmissing-prototypes"
#pragma clang diagnostic ignored "-Wmissing-braces"

#include <metal_stdlib>
#include <simd/simd.h>

using namespace metal;

template<typename T, size_t Num>
struct spvUnsafeArray
{
    T elements[Num ? Num : 1];
    
    thread T& operator [] (size_t pos) thread
    {
        return elements[pos];
    }
    constexpr const thread T& operator [] (size_t pos) const thread
    {
        return elements[pos];
    }
    
    device T& operator [] (size_t pos) device
    {
        return elements[pos];
    }
    constexpr const device T& operator [] (size_t pos) const device
    {
        return elements[pos];
    }
    
    constexpr const constant T& operator [] (size_t pos) const constant
    {
        return elements[pos];
    }
    
    threadgroup T& operator [] (size_t pos) threadgroup
    {
        return elements[pos];
    }
    constexpr const threadgroup T& operator [] (size_t pos) const threadgroup
    {
        return elements[pos];
    }
};

// Implementation of signed integer mod accurate to SPIR-V specification
template<typename Tx, typename Ty>
inline Tx spvSMod(Tx x, Ty y)
{
    Tx remainder = x - y * (x / y);
    return select(Tx(remainder + y), remainder, remainder == 0 || (x >= 0) == (y >= 0));
}

template <typename T>
static inline depth2d<T> spvDepthCast(texture2d<T> t)
{
    return reinterpret_cast<thread const depth2d<T> &>(t);
}

template <typename T>
static inline depth2d_array<T> spvDepthCast(texture2d_array<T> t)
{
    return reinterpret_cast<thread const depth2d_array<T> &>(t);
}

template <typename T>
static inline depthcube<T> spvDepthCast(texturecube<T> t)
{
    return reinterpret_cast<thread const depthcube<T> &>(t);
}

template <typename T>
static inline depthcube_array<T> spvDepthCast(texturecube_array<T> t)
{
    return reinterpret_cast<thread const depthcube_array<T> &>(t);
}

struct _134
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
};

struct _1435
{
    float4x4 _m0;
    float4x4 _m1;
    float4x4 _m2;
    float4 _m3;
    float4 _m4;
    float4 _m5;
};

struct _1913
{
    uint4 _m0[1024];
};

struct _1947
{
    uint4 _m0[1024];
};

struct _1967
{
    float4 _m0[1024];
};

struct _2002
{
    float4 _m0[1024];
};

struct _2010
{
    float4 _m0[1024];
};

constant spvUnsafeArray<float3, 6> _818 = spvUnsafeArray<float3, 6>({ float3(0.0, 0.0, 1.0), float3(0.0, 0.0, -1.0), float3(-1.0, 0.0, 0.0), float3(-1.0, 0.0, 0.0), float3(-1.0, 0.0, 0.0), float3(1.0, 0.0, 0.0) });
constant spvUnsafeArray<float3, 6> _827 = spvUnsafeArray<float3, 6>({ float3(0.0, 1.0, 0.0), float3(0.0, 1.0, 0.0), float3(0.0, 0.0, -1.0), float3(0.0, 0.0, 1.0), float3(0.0, 1.0, 0.0), float3(0.0, 1.0, 0.0) });
constant spvUnsafeArray<int4, 6> _1236 = spvUnsafeArray<int4, 6>({ int4(0, 0, 512, 256), int4(0, 256, 256, 128), int4(256, 256, 128, 64), int4(384, 256, 64, 32), int4(448, 256, 32, 16), int4(480, 256, 16, 8) });

struct fragment_main_out
{
    float4 m_2131 [[color(0)]];
};

fragment fragment_main_out fragment_main(constant _1435& _1437 [[buffer(2)]], constant _1967& _1969 [[buffer(3)]], constant _2002& _2004 [[buffer(4)]], constant _2010& _2012 [[buffer(5)]], constant _1913& _1915 [[buffer(6)]], constant _1947& _1949 [[buffer(7)]], constant _134& _136 [[buffer(15)]], texture2d<float> _157 [[texture(0)]], texture2d<float> _1638 [[texture(1)]], texture2d<float> _1404 [[texture(2)]], texture2d<float> _1174 [[texture(6)]], texture2d<float> _1280 [[texture(7)]], sampler _157Smplr [[sampler(0)]], sampler _1176 [[sampler(1)]], sampler _1282 [[sampler(7)]], float4 gl_FragCoord [[position]])
{
    fragment_main_out out = {};
    int2 _1470 = int2(_1404.get_width(), _1404.get_height());
    int2 _1476 = int2(gl_FragCoord.xy);
    int2 _2175 = _1470 - int2(1);
    int2 _2176 = clamp(_1476, int2(0), _2175);
    float _2190 = float(_1470.x);
    float _2200 = float(_1470.y);
    float4 _2212 = _1437._m2 * float4((((float(_2176.x) + 0.5) / _2190) * 2.0) - 1.0, 1.0 - (((float(_2176.y) + 0.5) / _2200) * 2.0), _1404.read(uint2(_2176), 0).x, 1.0);
    float3 _2218 = _2212.xyz / float3(_2212.w);
    float4 _2227 = float4(_2218, 1.0);
    float4 _2228 = _1437._m1 * _2227;
    if (any(abs(_2228.xyz) > float3(0.5)))
    {
        discard_fragment();
    }
    int2 _2239 = clamp(_1476 + int2(1, 0), int2(0), _2175);
    float4 _2275 = _1437._m2 * float4((((float(_2239.x) + 0.5) / _2190) * 2.0) - 1.0, 1.0 - (((float(_2239.y) + 0.5) / _2200) * 2.0), _1404.read(uint2(_2239), 0).x, 1.0);
    int2 _2291 = clamp(_1476 - int2(1, 0), int2(0), _2175);
    float4 _2327 = _1437._m2 * float4((((float(_2291.x) + 0.5) / _2190) * 2.0) - 1.0, 1.0 - (((float(_2291.y) + 0.5) / _2200) * 2.0), _1404.read(uint2(_2291), 0).x, 1.0);
    int2 _2343 = clamp(_1476 + int2(0, 1), int2(0), _2175);
    float4 _2379 = _1437._m2 * float4((((float(_2343.x) + 0.5) / _2190) * 2.0) - 1.0, 1.0 - (((float(_2343.y) + 0.5) / _2200) * 2.0), _1404.read(uint2(_2343), 0).x, 1.0);
    int2 _2395 = clamp(_1476 - int2(0, 1), int2(0), _2175);
    float4 _2431 = _1437._m2 * float4((((float(_2395.x) + 0.5) / _2190) * 2.0) - 1.0, 1.0 - (((float(_2395.y) + 0.5) / _2200) * 2.0), _1404.read(uint2(_2395), 0).x, 1.0);
    float3 _1529 = (_2275.xyz / float3(_2275.w)) - _2218;
    float3 _1533 = _2218 - (_2327.xyz / float3(_2327.w));
    float3 _1537 = (_2379.xyz / float3(_2379.w)) - _2218;
    float3 _1541 = _2218 - (_2431.xyz / float3(_2431.w));
    float3 _1553 = select(_1533, _1529, bool3(dot(_1529, _1529) < dot(_1533, _1533)));
    float3 _1565 = select(_1541, _1537, bool3(dot(_1537, _1537) < dot(_1541, _1541)));
    float3 _1571 = _136._m6.xyz - _2218;
    float3 _1575 = cross(_1553, _1565);
    float3 _4723;
    if (dot(_1575, _1575) > 9.9999996826552253889678874634872e-21)
    {
        _4723 = fast::normalize(_1575);
    }
    else
    {
        _4723 = fast::normalize(_1571);
    }
    float3 _4728;
    if (dot(_4723, _1571) < 0.0)
    {
        _4728 = -_4723;
    }
    else
    {
        _4728 = _4723;
    }
    float3 _1599 = fast::normalize(_1571);
    float2 _1616 = _2228.xy;
    float4 _4726;
    if (_1437._m4.w > 0.5)
    {
        _4726 = _1638.sample(_1176, float2(_2228.x + 0.5, 0.5 - _2228.y), gradient2d(((_1437._m1 * float4(_2218 + _1553, 1.0)).xy - _1616) * float2(1.0, -1.0), ((_1437._m1 * float4(_2218 + _1565, 1.0)).xy - _1616) * float2(1.0, -1.0)));
    }
    else
    {
        _4726 = float4(1.0);
    }
    float3 _1655 = _1437._m3.xyz * _4726.xyz;
    float _1661 = _1437._m3.w * _4726.w;
    float _4729;
    if (_1437._m4.z > 0.0)
    {
        _4729 = _1661 * fast::clamp(dot(_4728, -_1437._m5.xyz) / _1437._m4.z, 0.0, 1.0);
    }
    else
    {
        _4729 = _1661;
    }
    if (_4729 <= 0.0)
    {
        discard_fragment();
    }
    float _1690 = _1437._m4.y * _1437._m4.y;
    float3 _1698 = fast::normalize(_136._m4.xyz);
    float3 _1703 = fast::normalize(_1698 + _1599);
    float _4814;
    if (_136._m5.w > 0.5)
    {
        float _4769;
        do
        {
            int _2480 = int(_136._m21.x);
            float _2488 = dot(_136._m20.xyz, _2218) + _136._m20.w;
            int _4733;
            _4733 = 0;
            for (;;)
            {
                bool _2494 = _4733 < (_2480 - 1);
                bool _2502;
                if (_2494)
                {
                    _2502 = _2488 > _136._m16[_4733];
                }
                else
                {
                    _2502 = _2494;
                }
                if (_2502)
                {
                    _4733++;
                    continue;
                }
                else
                {
                    break;
                }
            }
            if (_2488 > _136._m16[_4733])
            {
                _4769 = 1.0;
                break;
            }
            float _4746;
            do
            {
                float4 _2604 = _136._m14[_4733] * float4(_2218 + (_4728 * _136._m18[_4733]), 1.0);
                float _2607 = _2604.x;
                bool _2608 = _2607 < 0.0;
                bool _2615;
                if (!_2608)
                {
                    _2615 = _2607 > 1.0;
                }
                else
                {
                    _2615 = _2608;
                }
                bool _2622;
                if (!_2615)
                {
                    _2622 = _2604.y < 0.0;
                }
                else
                {
                    _2622 = _2615;
                }
                bool _2629;
                if (!_2622)
                {
                    _2629 = _2604.y > 1.0;
                }
                else
                {
                    _2629 = _2622;
                }
                if (_2629)
                {
                    _4746 = 1.0;
                    break;
                }
                float2 _2642 = float2(float(_4733 & 1), float(_4733 >> 1)) * _136._m23.xy;
                float _2649 = fast::min(_2604.z, 1.0) - _136._m19[_4733];
                float2 _2668 = _136._m22.xy * 0.5;
                float2 _2673 = _2642 + (_2604.xy * _136._m23.xy);
                float4 _2686 = float4(_2642 + _2668, (_2642 + _136._m23.xy) - _2668);
                float _4745;
                do
                {
                    int _2712 = int(_136._m22.z);
                    if (_2712 <= 0)
                    {
                        float2 _2722 = fast::clamp(_2673, _2686.xy, _2686.zw);
                        _4745 = spvDepthCast(_157).sample_compare(_157Smplr, float3(_2722, _2649).xy, _2649);
                        break;
                    }
                    float2 _2735 = (_2673 / _136._m22.xy) + float2(0.5);
                    float2 _2736 = floor(_2735);
                    float2 _2741 = _2735 - _2736;
                    float2 _2744 = _2736 - float2(0.5);
                    bool _2748 = _2712 == 1;
                    spvUnsafeArray<float2, 3> _2696;
                    spvUnsafeArray<float2, 3> _2697;
                    if (_2748)
                    {
                        float2 _2751 = _2741 * 2.0;
                        _2696[0] = float2(3.0) - _2751;
                        _2696[1] = float2(1.0) + _2751;
                        _2697[0] = ((float2(2.0) - _2741) / _2696[0]) - float2(1.0);
                        _2697[1] = (_2741 / _2696[1]) + float2(1.0);
                    }
                    else
                    {
                        float2 _2778 = _2741 * 3.0;
                        _2696[0] = float2(4.0) - _2778;
                        _2696[1] = float2(7.0);
                        _2696[2] = float2(1.0) + _2778;
                        _2697[0] = ((float2(3.0) - (_2741 * 2.0)) / _2696[0]) - float2(2.0);
                        _2697[1] = (float2(3.0) + _2741) / _2696[1];
                        _2697[2] = (_2741 / _2696[2]) + float2(2.0);
                    }
                    int _5053 = _2748 ? 2 : 3;
                    int _4735;
                    float _4738;
                    _4738 = 0.0;
                    _4735 = 0;
                    float _4744;
                    for (; _4735 < _5053; _4738 = _4744, _4735++)
                    {
                        _4744 = _4738;
                        for (int _4741 = 0; _4741 < _5053; )
                        {
                            _4744 += ((_2696[_4741].x * _2696[_4735].y) * spvDepthCast(_157).sample_compare(_157Smplr, float3(fast::clamp(_136._m22.xy * (_2744 + float2(_2697[_4741].x, _2697[_4735].y)), _2686.xy, _2686.zw), _2649).xy, _2649));
                            _4741++;
                            continue;
                        }
                    }
                    _4745 = _4738 * (_2748 ? 0.0625 : 0.0069444444961845874786376953125);
                    break;
                } while(false);
                _4746 = _4745;
                break;
            } while(false);
            float _4767;
            if (_2488 > _136._m17[_4733])
            {
                float _2542 = (_2488 - _136._m17[_4733]) / (_136._m16[_4733] - _136._m17[_4733]);
                int _2544 = _4733 + 1;
                float _4768;
                if (_2544 < _2480)
                {
                    float _4766;
                    do
                    {
                        float4 _2891 = _136._m14[_2544] * float4(_2218 + (_4728 * _136._m18[_2544]), 1.0);
                        float _2894 = _2891.x;
                        bool _2895 = _2894 < 0.0;
                        bool _2902;
                        if (!_2895)
                        {
                            _2902 = _2894 > 1.0;
                        }
                        else
                        {
                            _2902 = _2895;
                        }
                        bool _2909;
                        if (!_2902)
                        {
                            _2909 = _2891.y < 0.0;
                        }
                        else
                        {
                            _2909 = _2902;
                        }
                        bool _2916;
                        if (!_2909)
                        {
                            _2916 = _2891.y > 1.0;
                        }
                        else
                        {
                            _2916 = _2909;
                        }
                        if (_2916)
                        {
                            _4766 = 1.0;
                            break;
                        }
                        float2 _2929 = float2(float(_2544 & 1), float(_2544 >> 1)) * _136._m23.xy;
                        float _2936 = fast::min(_2891.z, 1.0) - _136._m19[_2544];
                        float2 _2955 = _136._m22.xy * 0.5;
                        float2 _2960 = _2929 + (_2891.xy * _136._m23.xy);
                        float4 _2973 = float4(_2929 + _2955, (_2929 + _136._m23.xy) - _2955);
                        float _4765;
                        do
                        {
                            int _2999 = int(_136._m22.z);
                            if (_2999 <= 0)
                            {
                                float2 _3009 = fast::clamp(_2960, _2973.xy, _2973.zw);
                                _4765 = spvDepthCast(_157).sample_compare(_157Smplr, float3(_3009, _2936).xy, _2936);
                                break;
                            }
                            float2 _3022 = (_2960 / _136._m22.xy) + float2(0.5);
                            float2 _3023 = floor(_3022);
                            float2 _3028 = _3022 - _3023;
                            float2 _3031 = _3023 - float2(0.5);
                            bool _3035 = _2999 == 1;
                            spvUnsafeArray<float2, 3> _2983;
                            spvUnsafeArray<float2, 3> _2984;
                            if (_3035)
                            {
                                float2 _3038 = _3028 * 2.0;
                                _2983[0] = float2(3.0) - _3038;
                                _2983[1] = float2(1.0) + _3038;
                                _2984[0] = ((float2(2.0) - _3028) / _2983[0]) - float2(1.0);
                                _2984[1] = (_3028 / _2983[1]) + float2(1.0);
                            }
                            else
                            {
                                float2 _3065 = _3028 * 3.0;
                                _2983[0] = float2(4.0) - _3065;
                                _2983[1] = float2(7.0);
                                _2983[2] = float2(1.0) + _3065;
                                _2984[0] = ((float2(3.0) - (_3028 * 2.0)) / _2983[0]) - float2(2.0);
                                _2984[1] = (float2(3.0) + _3028) / _2983[1];
                                _2984[2] = (_3028 / _2983[2]) + float2(2.0);
                            }
                            int _5055 = _3035 ? 2 : 3;
                            int _4755;
                            float _4758;
                            _4758 = 0.0;
                            _4755 = 0;
                            float _4764;
                            for (; _4755 < _5055; _4758 = _4764, _4755++)
                            {
                                _4764 = _4758;
                                for (int _4761 = 0; _4761 < _5055; )
                                {
                                    _4764 += ((_2983[_4761].x * _2983[_4755].y) * spvDepthCast(_157).sample_compare(_157Smplr, float3(fast::clamp(_136._m22.xy * (_3031 + float2(_2984[_4761].x, _2984[_4755].y)), _2973.xy, _2973.zw), _2936).xy, _2936));
                                    _4761++;
                                    continue;
                                }
                            }
                            _4765 = _4758 * (_3035 ? 0.0625 : 0.0069444444961845874786376953125);
                            break;
                        } while(false);
                        _4766 = _4765;
                        break;
                    } while(false);
                    _4768 = mix(_4746, _4766, _2542);
                }
                else
                {
                    _4768 = mix(_4746, 1.0, _2542);
                }
                _4767 = _4768;
            }
            else
            {
                _4767 = _4746;
            }
            _4769 = _4767;
            break;
        } while(false);
        _4814 = _4769;
    }
    else
    {
        _4814 = 1.0;
    }
    float _1730 = fast::max(dot(_4728, _1599), 9.9999997473787516355514526367188e-05);
    float _1735 = fast::clamp(dot(_4728, _1698), 0.0, 1.0);
    float _1740 = fast::clamp(dot(_4728, _1703), 0.0, 1.0);
    float3 _3169 = float3(0.959999978542327880859375) * powr(1.0 - fast::clamp(dot(_1599, _1703), 0.0, 1.0), 5.0);
    float _3177 = _1690 * _1690;
    float _3182 = _3177 - 1.0;
    float _3184 = ((_1740 * _1740) * _3182) + 1.0;
    float _3204 = 1.0 - _3177;
    float _3208 = sqrt(((_1730 * _1730) * _3204) + _3177);
    float2 _4833;
    float3 _4841;
    float3 _4848;
    if (_136._m29.x > 0.5)
    {
        float4 _3241 = _1280.sample(_1282, (((float2(_1730, _1437._m4.y) * 31.0) + float2(0.5)) * float2(0.03125)));
        float _3300 = (_136._m29.z * _4728.x) - (_136._m29.w * _4728.z);
        float _3313 = (_136._m29.w * _4728.x) + (_136._m29.z * _4728.z);
        float _3331 = 1.09254801273345947265625 * _3300;
        spvUnsafeArray<float, 9> _4588 = spvUnsafeArray<float, 9>({ 0.2820949852466583251953125, 0.48860299587249755859375 * _4728.y, 0.48860299587249755859375 * _3313, 0.48860299587249755859375 * _3300, _3331 * _4728.y, (1.09254801273345947265625 * _4728.y) * _3313, 0.3153919875621795654296875 * (((3.0 * _3313) * _3313) - 1.0), _3331 * _3313, 0.546274006366729736328125 * ((_3300 * _3300) - (_4728.y * _4728.y)) });
        spvUnsafeArray<float, 9> _3245 = _4588;
        float3 _4816;
        _4816 = float3(0.0);
        for (int _4815 = 0; _4815 < 9; )
        {
            _4816 += (_1174.read(uint2((int2(496, 256) + int2(_4815, 0))), 0).xyz * _3245[_4815]);
            _4815++;
            continue;
        }
        float3 _1801 = reflect(-_1599, _4728);
        float _3426 = _1801.x;
        float _3431 = _1801.z;
        float2 _3463 = float2((precise::atan2((_136._m29.z * _3426) - (_136._m29.w * _3431), -((_136._m29.w * _3426) + (_136._m29.z * _3431))) * 0.15915493667125701904296875) + 0.5, acos(fast::clamp(_1801.y, -1.0, 1.0)) * 0.3183098733425140380859375);
        float _3395 = _1437._m4.y * 5.0;
        int _3398 = min(int(_3395), 4);
        float2 _3484 = (_3463 * float2(_1236[_3398].zw)) - float2(0.5);
        float2 _3486 = floor(_3484);
        float2 _3489 = _3484 - _3486;
        int _3492 = int(_3486.x);
        int _3495 = int(_3486.y);
        int _4819;
        if (_3492 < 0)
        {
            _4819 = _3492 + _1236[_3398].z;
        }
        else
        {
            _4819 = _3492;
        }
        int _4820;
        if (_4819 >= _1236[_3398].z)
        {
            _4820 = _4819 - _1236[_3398].z;
        }
        else
        {
            _4820 = _4819;
        }
        int _3515 = _4820 + 1;
        int _5056 = (_3515 == _1236[_3398].z) ? 0 : _3515;
        int _3530 = min((_3495 + 1), (_1236[_3398].w - 1));
        int _3532 = max(_3495, 0);
        float3 _3585 = float3(_3489.x);
        int _3405 = _3398 + 1;
        float2 _3617 = (_3463 * float2(_1236[_3405].zw)) - float2(0.5);
        float2 _3619 = floor(_3617);
        float2 _3622 = _3617 - _3619;
        int _3625 = int(_3619.x);
        int _3628 = int(_3619.y);
        int _4826;
        if (_3625 < 0)
        {
            _4826 = _3625 + _1236[_3405].z;
        }
        else
        {
            _4826 = _3625;
        }
        int _4827;
        if (_4826 >= _1236[_3405].z)
        {
            _4827 = _4826 - _1236[_3405].z;
        }
        else
        {
            _4827 = _4826;
        }
        int _3648 = _4827 + 1;
        int _5057 = (_3648 == _1236[_3405].z) ? 0 : _3648;
        int _3663 = min((_3628 + 1), (_1236[_3405].w - 1));
        int _3665 = max(_3628, 0);
        float3 _3718 = float3(_3622.x);
        float3 _3420 = mix(mix(mix(_1174.read(uint2((_1236[_3398].xy + int2(_4820, _3532))), 0).xyz, _1174.read(uint2((_1236[_3398].xy + int2(_5056, _3532))), 0).xyz, _3585), mix(_1174.read(uint2((_1236[_3398].xy + int2(_4820, _3530))), 0).xyz, _1174.read(uint2((_1236[_3398].xy + int2(_5056, _3530))), 0).xyz, _3585), float3(_3489.y)), mix(mix(_1174.read(uint2((_1236[_3405].xy + int2(_4827, _3665))), 0).xyz, _1174.read(uint2((_1236[_3405].xy + int2(_5057, _3665))), 0).xyz, _3718), mix(_1174.read(uint2((_1236[_3405].xy + int2(_4827, _3663))), 0).xyz, _1174.read(uint2((_1236[_3405].xy + int2(_5057, _3663))), 0).xyz, _3718), float3(_3622.y)), float3(_3395 - float(_3398))) * _136._m29.y;
        _4848 = _3420;
        _4841 = fast::max(_4816, float3(0.0)) * _136._m29.y;
        _4833 = _3241.xy;
    }
    else
    {
        float4 _3736 = (float4(-1.0, -0.0274999998509883880615234375, -0.572000026702880859375, 0.02199999988079071044921875) * _1437._m4.y) + float4(1.0, 0.0425000004470348358154296875, 1.03999996185302734375, -0.039999999105930328369140625);
        float _3738 = _3736.x;
        float3 _3773 = mix(_136._m9.xyz, _136._m8.xyz, float3((_4728.y * 0.5) + 0.5)) * _136._m8.w;
        _4848 = mix(mix(_136._m9.xyz, _136._m8.xyz, float3((reflect(-_1599, _4728).y * 0.5) + 0.5)) * _136._m8.w, _3773, float3(_1437._m4.y));
        _4841 = _3773;
        _4833 = (float2(-1.03999996185302734375, 1.03999996185302734375) * ((fast::min(_3738 * _3738, exp2((-9.27999973297119140625) * _1730)) * _3738) + _3736.y)) + _3736.zw;
    }
    float3 _1833 = (float3(0.039999999105930328369140625) * _4833.x) + float3(_4833.y);
    float3 _1845 = ((((((float3(0.959999978542327880859375) - _3169) * _1655) + (((float3(0.039999999105930328369140625) + _3169) * ((_3177 / ((3.1415927410125732421875 * _3184) * _3184)) * (0.5 / fast::max((_1735 * _3208) + (_1730 * sqrt(((_1735 * _1735) * _3204) + _3177)), 9.9999997473787516355514526367188e-06)))) * 3.1415927410125732421875)) * _1735) * (_136._m5.xyz * _136._m4.w)) * _4814) + ((((float3(1.0) - _1833) * _1655) * _4841) + (_1833 * _4848));
    float3 _4858;
    if (_136._m13.w > 0.5)
    {
        float2 _1877 = fast::clamp(floor(gl_FragCoord.xy * _136._m12.xy), float2(0.0), _136._m13.xy - float2(1.0));
        uint _1908 = uint((((fast::clamp(floor((log2(fast::max(dot(_136._m11.xyz, _2218) + _136._m11.w, 9.9999999747524270787835121154785e-07)) * _136._m12.z) + _136._m12.w), 0.0, _136._m13.z - 1.0) * _136._m13.y) + _1877.y) * _136._m13.x) + _1877.x);
        uint _1917 = _1908 >> uint(2);
        uint _1919 = _1908 & 3u;
        uint _1926 = _1915._m0[_1917][_1919] & 65535u;
        uint _1929 = _1915._m0[_1917][_1919] >> uint(16);
        float3 _4859;
        _4859 = _1845;
        float3 _2106;
        spvUnsafeArray<float2, 3> _4114;
        spvUnsafeArray<float2, 3> _4115;
        spvUnsafeArray<float2, 3> _4327;
        spvUnsafeArray<float2, 3> _4328;
        for (uint _4857 = _1926; _4857 < (_1926 + _1929); _4859 = _2106, _4857++)
        {
            uint _1944 = _4857 / 3u;
            uint _1964 = (_1949._m0[_1944 >> uint(2)][_1944 & 3u] >> ((_4857 - (_1944 * 3u)) * 10u)) & 1023u;
            float3 _1977 = _1969._m0[_1964].xyz - _2218;
            float _1981 = dot(_1977, _1977);
            float _1986 = _1981 * _1969._m0[_1964].w;
            float _1992 = fast::clamp(1.0 - (_1986 * _1986), 0.0, 1.0);
            float3 _1999 = _1977 * rsqrt(fast::max(_1981, 9.9999999392252902907785028219223e-09));
            float _2028 = fast::clamp((dot(-_1999, _2012._m0[_1964].xyz) * _2004._m0[_1964].w) + _2012._m0[_1964].w, 0.0, 1.0);
            float _4926;
            do
            {
                uint _3826 = uint(_136._m21.z);
                if (_1964 < _3826)
                {
                    float _3848 = _136._m26[_1964].z * fast::max((_136._m15[_1964] * _2227).w, 0.0);
                    float4 _3872 = _136._m15[_1964] * float4((_2218 + (_4728 * (_3848 * _136._m25.x))) + (_1999 * (_3848 * _136._m25.y)), 1.0);
                    float _3874 = _3872.w;
                    if (_3874 <= 0.0)
                    {
                        _4926 = 1.0;
                        break;
                    }
                    float3 _3883 = _3872.xyz / float3(_3874);
                    float _3885 = _3883.x;
                    bool _3886 = _3885 < 0.0;
                    bool _3893;
                    if (!_3886)
                    {
                        _3893 = _3885 > 1.0;
                    }
                    else
                    {
                        _3893 = _3886;
                    }
                    bool _3900;
                    if (!_3893)
                    {
                        _3900 = _3883.y < 0.0;
                    }
                    else
                    {
                        _3900 = _3893;
                    }
                    bool _3907;
                    if (!_3900)
                    {
                        _3907 = _3883.y > 1.0;
                    }
                    else
                    {
                        _3907 = _3900;
                    }
                    bool _3914;
                    if (!_3907)
                    {
                        _3914 = _3883.z > 1.0;
                    }
                    else
                    {
                        _3914 = _3907;
                    }
                    if (_3914)
                    {
                        _4926 = 1.0;
                        break;
                    }
                    float _3920 = _3883.z;
                    float2 _4086 = _136._m22.xy * 0.5;
                    float2 _4091 = _136._m26[_1964].xy + (_3883.xy * _136._m23.zw);
                    float4 _4104 = float4(_136._m26[_1964].xy + _4086, (_136._m26[_1964].xy + _136._m23.zw) - _4086);
                    float _4925;
                    do
                    {
                        int _4130 = int(_136._m22.z);
                        if (_4130 <= 0)
                        {
                            _4925 = spvDepthCast(_157).sample_compare(_157Smplr, float3(fast::clamp(_4091, _4104.xy, _4104.zw), _3920).xy, _3920);
                            break;
                        }
                        float2 _4153 = (_4091 / _136._m22.xy) + float2(0.5);
                        float2 _4154 = floor(_4153);
                        float2 _4159 = _4153 - _4154;
                        float2 _4162 = _4154 - float2(0.5);
                        bool _4166 = _4130 == 1;
                        if (_4166)
                        {
                            float2 _4169 = _4159 * 2.0;
                            _4114[0] = float2(3.0) - _4169;
                            _4114[1] = float2(1.0) + _4169;
                            _4115[0] = ((float2(2.0) - _4159) / _4114[0]) - float2(1.0);
                            _4115[1] = (_4159 / _4114[1]) + float2(1.0);
                        }
                        else
                        {
                            float2 _4196 = _4159 * 3.0;
                            _4114[0] = float2(4.0) - _4196;
                            _4114[1] = float2(7.0);
                            _4114[2] = float2(1.0) + _4196;
                            _4115[0] = ((float2(3.0) - (_4159 * 2.0)) / _4114[0]) - float2(2.0);
                            _4115[1] = (float2(3.0) + _4159) / _4114[1];
                            _4115[2] = (_4159 / _4114[2]) + float2(2.0);
                        }
                        int _5059 = _4166 ? 2 : 3;
                        int _4915;
                        float _4918;
                        _4918 = 0.0;
                        _4915 = 0;
                        float _4924;
                        for (; _4915 < _5059; _4918 = _4924, _4915++)
                        {
                            _4924 = _4918;
                            for (int _4921 = 0; _4921 < _5059; )
                            {
                                _4924 += ((_4114[_4921].x * _4114[_4915].y) * spvDepthCast(_157).sample_compare(_157Smplr, float3(fast::clamp(_136._m22.xy * (_4162 + float2(_4115[_4921].x, _4115[_4915].y)), _4104.xy, _4104.zw), _3920).xy, _3920));
                                _4921++;
                                continue;
                            }
                        }
                        _4925 = _4918 * (_4166 ? 0.0625 : 0.0069444444961845874786376953125);
                        break;
                    } while(false);
                    _4926 = _4925;
                    break;
                }
                uint _3930 = _1964 - _3826;
                if (_3930 >= uint(_136._m21.w))
                {
                    _4926 = 1.0;
                    break;
                }
                float _3951 = _136._m27[_3930].w * length(_2218 - _136._m27[_3930].xyz);
                float3 _3969 = ((_2218 + (_4728 * (_3951 * _136._m25.x))) + (_1999 * (_3951 * _136._m25.y))) - _136._m27[_3930].xyz;
                float3 _3971 = abs(_3969);
                float _3973 = _3971.x;
                float _3975 = _3971.y;
                bool _3976 = _3973 >= _3975;
                bool _3984;
                if (_3976)
                {
                    _3984 = _3973 >= _3971.z;
                }
                else
                {
                    _3984 = _3976;
                }
                float _4900;
                int _4902;
                if (_3984)
                {
                    _4902 = (_3969.x > 0.0) ? 0 : 1;
                    _4900 = _3973;
                }
                else
                {
                    float _3996 = _3971.z;
                    bool _3997 = _3975 >= _3996;
                    int _4903;
                    if (_3997)
                    {
                        _4903 = (_3969.y > 0.0) ? 2 : 3;
                    }
                    else
                    {
                        _4903 = (_3969.z > 0.0) ? 4 : 5;
                    }
                    _4902 = _4903;
                    _4900 = _3997 ? _3975 : _3996;
                }
                if (_4900 <= 0.0)
                {
                    _4926 = 1.0;
                    break;
                }
                float2 _4034 = float2(dot(_3969, _818[_4902]), dot(_3969, _827[_4902])) / float2(_4900 * _136._m24.z);
                float _4041 = _136._m28[_3930].z + (_136._m28[_3930].w / _4900);
                if (_4041 > 1.0)
                {
                    _4926 = 1.0;
                    break;
                }
                float2 _4059 = _136._m28[_3930].xy + (float2(float(spvSMod(_4902, 3)), float(_4902 / 3)) * _136._m24.xy);
                float2 _4299 = _136._m22.xy * 0.5;
                float2 _4304 = _4059 + (float2(0.5 + (0.5 * _4034.x), 0.5 - (0.5 * _4034.y)) * _136._m24.xy);
                float4 _4317 = float4(_4059 + _4299, (_4059 + _136._m24.xy) - _4299);
                float _4914;
                do
                {
                    int _4343 = int(_136._m22.z);
                    if (_4343 <= 0)
                    {
                        float2 _4353 = fast::clamp(_4304, _4317.xy, _4317.zw);
                        _4914 = spvDepthCast(_157).sample_compare(_157Smplr, float3(_4353, _4041).xy, _4041);
                        break;
                    }
                    float2 _4366 = (_4304 / _136._m22.xy) + float2(0.5);
                    float2 _4367 = floor(_4366);
                    float2 _4372 = _4366 - _4367;
                    float2 _4375 = _4367 - float2(0.5);
                    bool _4379 = _4343 == 1;
                    if (_4379)
                    {
                        float2 _4382 = _4372 * 2.0;
                        _4327[0] = float2(3.0) - _4382;
                        _4327[1] = float2(1.0) + _4382;
                        _4328[0] = ((float2(2.0) - _4372) / _4327[0]) - float2(1.0);
                        _4328[1] = (_4372 / _4327[1]) + float2(1.0);
                    }
                    else
                    {
                        float2 _4409 = _4372 * 3.0;
                        _4327[0] = float2(4.0) - _4409;
                        _4327[1] = float2(7.0);
                        _4327[2] = float2(1.0) + _4409;
                        _4328[0] = ((float2(3.0) - (_4372 * 2.0)) / _4327[0]) - float2(2.0);
                        _4328[1] = (float2(3.0) + _4372) / _4327[1];
                        _4328[2] = (_4372 / _4327[2]) + float2(2.0);
                    }
                    int _5062 = _4379 ? 2 : 3;
                    int _4904;
                    float _4907;
                    _4907 = 0.0;
                    _4904 = 0;
                    float _4913;
                    for (; _4904 < _5062; _4907 = _4913, _4904++)
                    {
                        _4913 = _4907;
                        for (int _4910 = 0; _4910 < _5062; )
                        {
                            _4913 += ((_4327[_4910].x * _4327[_4904].y) * spvDepthCast(_157).sample_compare(_157Smplr, float3(fast::clamp(_136._m22.xy * (_4375 + float2(_4328[_4910].x, _4328[_4904].y)), _4317.xy, _4317.zw), _4041).xy, _4041));
                            _4910++;
                            continue;
                        }
                    }
                    _4914 = _4907 * (_4379 ? 0.0625 : 0.0069444444961845874786376953125);
                    break;
                } while(false);
                _4926 = _4914;
                break;
            } while(false);
            float3 _2058 = fast::normalize(_1999 + _1599);
            float _2063 = fast::clamp(dot(_4728, _1999), 0.0, 1.0);
            float _2068 = fast::clamp(dot(_4728, _2058), 0.0, 1.0);
            float3 _4513 = float3(0.959999978542327880859375) * powr(1.0 - fast::clamp(dot(_1599, _2058), 0.0, 1.0), 5.0);
            float _4528 = ((_2068 * _2068) * _3182) + 1.0;
            _2106 = _4859 + (((((float3(0.959999978542327880859375) - _4513) * _1655) + (((float3(0.039999999105930328369140625) + _4513) * ((_3177 / ((3.1415927410125732421875 * _4528) * _4528)) * (0.5 / fast::max((_2063 * _3208) + (_1730 * sqrt(((_2063 * _2063) * _3204) + _3177)), 9.9999997473787516355514526367188e-06)))) * 3.1415927410125732421875)) * _2063) * ((_2004._m0[_1964].xyz * ((((_1992 * _1992) * _2028) * _2028) / fast::max(_1981, 9.9999997473787516355514526367188e-05))) * _4926));
        }
        _4858 = _4859;
    }
    else
    {
        _4858 = _1845;
    }
    out.m_2131 = float4(mix(_4858 + (_1655 * _1437._m4.x), _136._m7.xyz, float3(1.0 - exp((-length(_1571)) * _136._m7.w))), _4729);
    return out;
}

