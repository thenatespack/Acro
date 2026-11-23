// Generated from mesh_terrain.frag by Scripts/compile-shaders.sh — do not edit.
// Edit the GLSL and rerun the script (needs glslc and spirv-cross).
// spirv-fnv1a64: 040faac4f58327b6
// glsl-fnv1a64: 08f2d8721d375c02

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

// Implementation of the GLSL mod() function, which is slightly different than Metal fmod()
template<typename Tx, typename Ty>
inline Tx mod(Tx x, Ty y)
{
    return x - y * floor(x / y);
}

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

struct _275
{
    float4 _m0[1];
};

struct _592
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

struct _1577
{
    uint4 _m0[1];
};

struct _3046
{
    float4 _m0[1024];
};

struct _3081
{
    float4 _m0[1024];
};

struct _3089
{
    float4 _m0[1024];
};

struct _3184
{
    uint4 _m0[1024];
};

struct _3206
{
    uint4 _m0[1024];
};

struct _3441
{
    float4 _m0;
};

struct _3533
{
    float4 _m0;
    float4 _m1;
    float4 _m2;
    float4 _m3;
    float4 _m4;
    float4 _m5;
    float4 _m6;
};

constant spvUnsafeArray<float3, 4> _959 = spvUnsafeArray<float3, 4>({ float3(1.0, 0.449999988079071044921875, 0.449999988079071044921875), float3(0.449999988079071044921875, 1.0, 0.449999988079071044921875), float3(0.5, 0.60000002384185791015625, 1.0), float3(1.0, 1.0, 0.4000000059604644775390625) });
constant spvUnsafeArray<float3, 6> _1261 = spvUnsafeArray<float3, 6>({ float3(0.0, 0.0, 1.0), float3(0.0, 0.0, -1.0), float3(-1.0, 0.0, 0.0), float3(-1.0, 0.0, 0.0), float3(-1.0, 0.0, 0.0), float3(1.0, 0.0, 0.0) });
constant spvUnsafeArray<float3, 6> _1270 = spvUnsafeArray<float3, 6>({ float3(0.0, 1.0, 0.0), float3(0.0, 1.0, 0.0), float3(0.0, 0.0, -1.0), float3(0.0, 0.0, 1.0), float3(0.0, 1.0, 0.0), float3(0.0, 1.0, 0.0) });
constant spvUnsafeArray<int3, 6> _1651 = spvUnsafeArray<int3, 6>({ int3(0, 256, 128), int3(32768, 128, 64), int3(40960, 64, 32), int3(43008, 32, 16), int3(43520, 16, 8), int3(43648, 8, 4) });
constant spvUnsafeArray<int4, 6> _2883 = spvUnsafeArray<int4, 6>({ int4(0, 0, 512, 256), int4(0, 256, 256, 128), int4(256, 256, 128, 64), int4(384, 256, 64, 32), int4(448, 256, 32, 16), int4(480, 256, 16, 8) });

struct fragment_main_out
{
    float4 m_4290 [[color(0)]];
};

struct fragment_main_in
{
    float3 m_3056 [[user(locn0)]];
    float3 m_3426 [[user(locn1)]];
    float2 m_3421 [[user(locn2)]];
    float4 m_3438 [[user(locn3)]];
    float4 m_3588 [[user(locn5)]];
    float4 m_4299 [[user(locn6)]];
    float4 m_4300 [[user(locn7)]];
    float4 m_3479 [[user(locn8)]];
};

fragment fragment_main_out fragment_main(fragment_main_in in [[stage_in]], constant _3533& _3535 [[buffer(2)]], constant _3046& _3048 [[buffer(3)]], constant _3081& _3083 [[buffer(4)]], constant _3089& _3091 [[buffer(5)]], constant _3184& _3186 [[buffer(6)]], constant _3206& _3208 [[buffer(7)]], constant _592& _594 [[buffer(15)]], constant _3441& _3443 [[buffer(16)]], const device _275& _277 [[buffer(20)]], const device _1577& _1579 [[buffer(21)]], texture2d<float> _612 [[texture(0)]], texture2d<float> _471 [[texture(1)]], texture2d<float> _359 [[texture(2)]], texture2d<float> _492 [[texture(3)]], texture2d<float> _3372 [[texture(4)]], texture2d<float> _374 [[texture(5)]], texture2d<float> _2827 [[texture(6)]], texture2d<float> _2927 [[texture(7)]], sampler _612Smplr [[sampler(0)]], sampler _361 [[sampler(1)]], sampler _2929 [[sampler(7)]], float4 gl_FragCoord [[position]], bool gl_FrontFacing [[front_facing]])
{
    float2 _4298;
    fragment_main_out out = {};
    int _4385 = int(_277._m0[0].x + 0.5);
    int _4389 = int(_277._m0[0].y + 0.5);
    float2 _4397 = (in.m_3421 * _277._m0[0].z) + float2(_277._m0[0].w);
    float4 _4349 = _359.sample(_361, _4397, level(0.0));
    float4 _15805;
    if (_4385 > 4)
    {
        _15805 = _374.sample(_361, _4397, level(0.0));
    }
    else
    {
        _15805 = float4(0.0);
    }
    float4 _4350 = _15805;
    float2 _4419 = (in.m_3421 - float2(0.5)) * _277._m0[1].xy;
    float2 _4421 = dfdx(_4419);
    float2 _4423 = dfdy(_4419);
    float3 _15810;
    float3 _15814;
    float _15817;
    _15817 = 0.0;
    _15814 = float3(0.0);
    _15810 = float3(0.0);
    float3 _16815;
    float3 _16817;
    float _16818;
    for (int _15806 = 0; _15806 < 8; _15817 = _16818, _15814 = _16817, _15810 = _16815, _15806++)
    {
        if (_15806 >= _4385)
        {
            break;
        }
        float _15807;
        if (_15806 < 4)
        {
            _15807 = _4349[_15806];
        }
        else
        {
            _15807 = _4350[_15806 - 4];
        }
        if (_15807 < 0.001953125)
        {
            _16818 = _15817;
            _16817 = _15814;
            _16815 = _15810;
            continue;
        }
        int _4453 = 3 + (_15806 / 4);
        int _4455 = spvSMod(_15806, 4);
        float2 _4463 = _4421 * ((device float*)&_277._m0[_4453])[_4455];
        float2 _4466 = _4423 * ((device float*)&_277._m0[_4453])[_4455];
        float _4569 = fast::clamp(0.5 * log2(fast::max((fast::max(dot(_4463, _4463), dot(_4466, _4466)) * _277._m0[2].w) * _277._m0[2].w, 9.9999999392252902907785028219223e-09)), 0.0, fast::max(log2(_277._m0[2].w) - 2.0, 0.0));
        float _4582 = float(_15806);
        float _4597 = (0.5 * exp2(ceil(_4569))) / _277._m0[2].w;
        float2 _4611 = (float2(mod(_4582, _277._m0[2].y), floor(_4582 / _277._m0[2].y)) + fast::clamp(fract(_4419 * ((device float*)&_277._m0[_4453])[_4455]), float2(_4597), float2(1.0 - _4597))) / _277._m0[2].yz;
        float3 _15811;
        if (((_4389 >> _15806) & 1) != 0)
        {
            float3 _4500 = (_492.sample(_361, _4611, level(_4569)).xyz * 2.0) - float3(1.0);
            float2 _4505 = _4500.xy * _277._m0[1].z;
            float3 _14875 = _4500;
            _14875.x = _4505.x;
            _14875.y = _4505.y;
            _15811 = _14875;
        }
        else
        {
            _15811 = float3(0.0, 0.0, 1.0);
        }
        _16818 = _15817 + _15807;
        _16817 = _15814 + (_15811 * _15807);
        _16815 = _15810 + (_471.sample(_361, _4611, level(_4569)).xyz * _15807);
    }
    bool _4524 = _15817 > 0.0;
    float _15821;
    if (_4524)
    {
        _15821 = 1.0 / _15817;
    }
    else
    {
        _15821 = 0.0;
    }
    float3 _15827;
    if (_4524)
    {
        _15827 = _15814 * _15821;
    }
    else
    {
        _15827 = float3(0.0, 0.0, 1.0);
    }
    float3 _3453 = in.m_3438.xyz * fast::max(_15810 * _15821, float3(0.0));
    if (_3443._m0.y > 0.5)
    {
        if (1.0 < _3443._m0.z)
        {
            discard_fragment();
        }
    }
    float3 _3477 = fast::normalize(in.m_3426);
    float3 _3488 = in.m_3479.xyz - (_3477 * dot(_3477, in.m_3479.xyz));
    bool _3492 = dot(_3488, _3488) > 9.9999999600419720025001879548654e-13;
    bool _3499;
    if (_3492)
    {
        _3499 = dot(_15827, _15827) > 9.9999999600419720025001879548654e-13;
    }
    else
    {
        _3499 = _3492;
    }
    float3 _15833;
    if (_3499)
    {
        float3 _3503 = fast::normalize(_3488);
        float3 _3515 = fast::normalize(_15827);
        _15833 = fast::normalize(((_3503 * _3515.x) + ((cross(_3477, _3503) * ((in.m_3479.w < 0.0) ? (-1.0) : 1.0)) * _3515.y)) + (_3477 * _3515.z));
    }
    else
    {
        _15833 = _3477;
    }
    bool _3538 = _3535._m5.w > 0.5;
    float _15830;
    if (_3538)
    {
        _15830 = fast::clamp(_3535._m1.z, 0.0, 1.0);
    }
    else
    {
        _15830 = 0.0;
    }
    bool _3556;
    if (_3538)
    {
        _3556 = !gl_FrontFacing;
    }
    else
    {
        _3556 = _3538;
    }
    float3 _15944;
    if (_3556 && (_15830 <= 0.0))
    {
        _15944 = -_15833;
    }
    else
    {
        _15944 = _15833;
    }
    float3 _3568 = fast::normalize(_594._m4.xyz);
    float3 _3574 = _594._m6.xyz - in.m_3056;
    float3 _3575 = fast::normalize(_3574);
    float3 _3580 = fast::normalize(_3568 + _3575);
    float3 _3586 = _3477 * (gl_FrontFacing ? 1.0 : (-1.0));
    bool _3591 = in.m_3588.x > 0.5;
    float3 _15941;
    float _15976;
    if ((_594._m5.w > 0.5) && _3591)
    {
        float _15889;
        float3 _15890;
        do
        {
            int _4632 = int(_594._m21.x);
            float _4640 = dot(_594._m20.xyz, in.m_3056) + _594._m20.w;
            int _15834;
            _15834 = 0;
            for (;;)
            {
                bool _4646 = _15834 < (_4632 - 1);
                bool _4654;
                if (_4646)
                {
                    _4654 = _4640 > _594._m16[_15834];
                }
                else
                {
                    _4654 = _4646;
                }
                if (_4654)
                {
                    _15834++;
                    continue;
                }
                else
                {
                    break;
                }
            }
            if (_4640 > _594._m16[_15834])
            {
                _15890 = float3(1.0);
                _15889 = 1.0;
                break;
            }
            float _15847;
            do
            {
                float4 _4756 = _594._m14[_15834] * float4(in.m_3056 + (_3586 * _594._m18[_15834]), 1.0);
                float _4759 = _4756.x;
                bool _4760 = _4759 < 0.0;
                bool _4767;
                if (!_4760)
                {
                    _4767 = _4759 > 1.0;
                }
                else
                {
                    _4767 = _4760;
                }
                bool _4774;
                if (!_4767)
                {
                    _4774 = _4756.y < 0.0;
                }
                else
                {
                    _4774 = _4767;
                }
                bool _4781;
                if (!_4774)
                {
                    _4781 = _4756.y > 1.0;
                }
                else
                {
                    _4781 = _4774;
                }
                if (_4781)
                {
                    _15847 = 1.0;
                    break;
                }
                float2 _4794 = float2(float(_15834 & 1), float(_15834 >> 1)) * _594._m23.xy;
                float _4801 = fast::min(_4756.z, 1.0) - _594._m19[_15834];
                float2 _4820 = _594._m22.xy * 0.5;
                float2 _4825 = _4794 + (_4756.xy * _594._m23.xy);
                float4 _4838 = float4(_4794 + _4820, (_4794 + _594._m23.xy) - _4820);
                float _15846;
                do
                {
                    int _4864 = int(_594._m22.z);
                    if (_4864 <= 0)
                    {
                        _15846 = spvDepthCast(_612).sample_compare(_612Smplr, float3(fast::clamp(_4825, _4838.xy, _4838.zw), _4801).xy, _4801);
                        break;
                    }
                    float2 _4887 = (_4825 / _594._m22.xy) + float2(0.5);
                    float2 _4888 = floor(_4887);
                    float2 _4893 = _4887 - _4888;
                    float2 _4896 = _4888 - float2(0.5);
                    bool _4900 = _4864 == 1;
                    spvUnsafeArray<float2, 3> _4848;
                    spvUnsafeArray<float2, 3> _4849;
                    if (_4900)
                    {
                        float2 _4903 = _4893 * 2.0;
                        _4848[0] = float2(3.0) - _4903;
                        _4848[1] = float2(1.0) + _4903;
                        _4849[0] = ((float2(2.0) - _4893) / _4848[0]) - float2(1.0);
                        _4849[1] = (_4893 / _4848[1]) + float2(1.0);
                    }
                    else
                    {
                        float2 _4930 = _4893 * 3.0;
                        _4848[0] = float2(4.0) - _4930;
                        _4848[1] = float2(7.0);
                        _4848[2] = float2(1.0) + _4930;
                        _4849[0] = ((float2(3.0) - (_4893 * 2.0)) / _4848[0]) - float2(2.0);
                        _4849[1] = (float2(3.0) + _4893) / _4848[1];
                        _4849[2] = (_4893 / _4848[2]) + float2(2.0);
                    }
                    int _16967 = _4900 ? 2 : 3;
                    int _15836;
                    float _15839;
                    _15839 = 0.0;
                    _15836 = 0;
                    float _15845;
                    for (; _15836 < _16967; _15839 = _15845, _15836++)
                    {
                        _15845 = _15839;
                        for (int _15842 = 0; _15842 < _16967; )
                        {
                            _15845 += ((_4848[_15842].x * _4848[_15836].y) * spvDepthCast(_612).sample_compare(_612Smplr, float3(fast::clamp(_594._m22.xy * (_4896 + float2(_4849[_15842].x, _4849[_15836].y)), _4838.xy, _4838.zw), _4801).xy, _4801));
                            _15842++;
                            continue;
                        }
                    }
                    _15846 = _15839 * (_4900 ? 0.0625 : 0.0069444444961845874786376953125);
                    break;
                } while(false);
                _15847 = _15846;
                break;
            } while(false);
            float3 _15884;
            float _15887;
            if (_4640 > _594._m17[_15834])
            {
                float _4694 = (_4640 - _594._m17[_15834]) / (_594._m16[_15834] - _594._m17[_15834]);
                int _4696 = _15834 + 1;
                float3 _15885;
                float _15888;
                if (_4696 < _4632)
                {
                    float _15867;
                    do
                    {
                        float4 _5043 = _594._m14[_4696] * float4(in.m_3056 + (_3586 * _594._m18[_4696]), 1.0);
                        float _5046 = _5043.x;
                        bool _5047 = _5046 < 0.0;
                        bool _5054;
                        if (!_5047)
                        {
                            _5054 = _5046 > 1.0;
                        }
                        else
                        {
                            _5054 = _5047;
                        }
                        bool _5061;
                        if (!_5054)
                        {
                            _5061 = _5043.y < 0.0;
                        }
                        else
                        {
                            _5061 = _5054;
                        }
                        bool _5068;
                        if (!_5061)
                        {
                            _5068 = _5043.y > 1.0;
                        }
                        else
                        {
                            _5068 = _5061;
                        }
                        if (_5068)
                        {
                            _15867 = 1.0;
                            break;
                        }
                        float2 _5081 = float2(float(_4696 & 1), float(_4696 >> 1)) * _594._m23.xy;
                        float _5088 = fast::min(_5043.z, 1.0) - _594._m19[_4696];
                        float2 _5107 = _594._m22.xy * 0.5;
                        float2 _5112 = _5081 + (_5043.xy * _594._m23.xy);
                        float4 _5125 = float4(_5081 + _5107, (_5081 + _594._m23.xy) - _5107);
                        float _15866;
                        do
                        {
                            int _5151 = int(_594._m22.z);
                            if (_5151 <= 0)
                            {
                                _15866 = spvDepthCast(_612).sample_compare(_612Smplr, float3(fast::clamp(_5112, _5125.xy, _5125.zw), _5088).xy, _5088);
                                break;
                            }
                            float2 _5174 = (_5112 / _594._m22.xy) + float2(0.5);
                            float2 _5175 = floor(_5174);
                            float2 _5180 = _5174 - _5175;
                            float2 _5183 = _5175 - float2(0.5);
                            bool _5187 = _5151 == 1;
                            spvUnsafeArray<float2, 3> _5135;
                            spvUnsafeArray<float2, 3> _5136;
                            if (_5187)
                            {
                                float2 _5190 = _5180 * 2.0;
                                _5135[0] = float2(3.0) - _5190;
                                _5135[1] = float2(1.0) + _5190;
                                _5136[0] = ((float2(2.0) - _5180) / _5135[0]) - float2(1.0);
                                _5136[1] = (_5180 / _5135[1]) + float2(1.0);
                            }
                            else
                            {
                                float2 _5217 = _5180 * 3.0;
                                _5135[0] = float2(4.0) - _5217;
                                _5135[1] = float2(7.0);
                                _5135[2] = float2(1.0) + _5217;
                                _5136[0] = ((float2(3.0) - (_5180 * 2.0)) / _5135[0]) - float2(2.0);
                                _5136[1] = (float2(3.0) + _5180) / _5135[1];
                                _5136[2] = (_5180 / _5135[2]) + float2(2.0);
                            }
                            int _16969 = _5187 ? 2 : 3;
                            int _15856;
                            float _15859;
                            _15859 = 0.0;
                            _15856 = 0;
                            float _15865;
                            for (; _15856 < _16969; _15859 = _15865, _15856++)
                            {
                                _15865 = _15859;
                                for (int _15862 = 0; _15862 < _16969; )
                                {
                                    _15865 += ((_5135[_15862].x * _5135[_15856].y) * spvDepthCast(_612).sample_compare(_612Smplr, float3(fast::clamp(_594._m22.xy * (_5183 + float2(_5136[_15862].x, _5136[_15856].y)), _5125.xy, _5125.zw), _5088).xy, _5088));
                                    _15862++;
                                    continue;
                                }
                            }
                            _15866 = _15859 * (_5187 ? 0.0625 : 0.0069444444961845874786376953125);
                            break;
                        } while(false);
                        _15867 = _15866;
                        break;
                    } while(false);
                    _15888 = mix(_15847, _15867, _4694);
                    _15885 = mix(_959[_15834], _959[_4696], float3(_4694));
                }
                else
                {
                    _15888 = mix(_15847, 1.0, _4694);
                    _15885 = _959[_15834];
                }
                _15887 = _15888;
                _15884 = _15885;
            }
            else
            {
                _15887 = _15847;
                _15884 = _959[_15834];
            }
            _15890 = select(float3(1.0), _15884, bool3(_594._m22.w > 0.5));
            _15889 = _15887;
            break;
        } while(false);
        _15976 = _15889;
        _15941 = _3453 * _15890;
    }
    else
    {
        _15976 = 1.0;
        _15941 = _3453;
    }
    float3 _3617 = _594._m5.xyz * _594._m4.w;
    float _3624 = abs(in.m_3479.w);
    float _16224;
    if (_3624 > 0.0)
    {
        _16224 = fast::min(_3624, 1.0);
    }
    else
    {
        _16224 = 1.0;
    }
    float3 _16465;
    float3 _16535;
    if (!_3538)
    {
        float _3640 = dot(_15944, _3568);
        float3 _16446;
        if (_594._m29.x > 0.5)
        {
            float _5368 = (_594._m29.z * _15944.x) - (_594._m29.w * _15944.z);
            float _5381 = (_594._m29.w * _15944.x) + (_594._m29.z * _15944.z);
            float _5399 = 1.09254801273345947265625 * _5368;
            spvUnsafeArray<float, 9> _14865 = spvUnsafeArray<float, 9>({ 0.2820949852466583251953125, 0.48860299587249755859375 * _15944.y, 0.48860299587249755859375 * _5381, 0.48860299587249755859375 * _5368, _5399 * _15944.y, (1.09254801273345947265625 * _15944.y) * _5381, 0.3153919875621795654296875 * (((3.0 * _5381) * _5381) - 1.0), _5399 * _5381, 0.546274006366729736328125 * ((_5368 * _5368) - (_15944.y * _15944.y)) });
            spvUnsafeArray<float, 9> _5313 = _14865;
            float3 _16445;
            _16445 = float3(0.0);
            for (int _16444 = 0; _16444 < 9; )
            {
                _16445 += (_2827.read(uint2((int2(496, 256) + int2(_16444, 0))), 0).xyz * _5313[_16444]);
                _16444++;
                continue;
            }
            _16446 = fast::max(_16445, float3(0.0)) * _594._m29.y;
        }
        else
        {
            _16446 = mix(_594._m9.xyz, _594._m8.xyz, float3((_15944.y * 0.5) + 0.5)) * _594._m8.w;
        }
        float3 _16451;
        if (_594._m34.y > 0.5)
        {
            int _5576 = int(_594._m34.y);
            int _5579 = int(_594._m34.x);
            float3 _16450;
            _16450 = _16446;
            float3 _16848;
            for (int _16449 = 0; _16449 < _5576; _16450 = _16848, _16449++)
            {
                int _5591 = 8 * (_5579 + _16449);
                float4 _5800 = as_type<float4>(_1579._m0[_5591 + 3]);
                float4 _5844 = as_type<float4>(_1579._m0[_5591]);
                float4 _5850 = as_type<float4>(_1579._m0[_5591 + 1]);
                float4 _5856 = as_type<float4>(_1579._m0[_5591 + 2]);
                float3 _5818 = _5844.xyz;
                float _5822 = _5844.w;
                float3 _5825 = _5850.xyz;
                float _5829 = _5850.w;
                float3 _5832 = _5856.xyz;
                float _5836 = _5856.w;
                float3 _5838 = float3(dot(_5818, in.m_3056) + _5822, dot(_5825, in.m_3056) + _5829, dot(_5832, in.m_3056) + _5836);
                float3 _5600 = _5800.xyz;
                float _5602 = _5800.w;
                float _16810;
                do
                {
                    float3 _5868 = _5600 - abs(_5838);
                    float _5876 = fast::min(_5868.x, fast::min(_5868.y, _5868.z));
                    if (_5876 <= 0.0)
                    {
                        _16810 = 0.0;
                        break;
                    }
                    if (_5602 <= 0.0)
                    {
                        _16810 = 1.0;
                        break;
                    }
                    float _5888 = fast::min(_5876 / _5602, 1.0);
                    _16810 = (_5888 * _5888) * (3.0 - (2.0 * _5888));
                    break;
                } while(false);
                if (_16810 <= 0.0)
                {
                    _16848 = _16450;
                    continue;
                }
                float3 _5611 = as_type<float4>(_1579._m0[_5591 + 4]).xyz;
                float4 _5909 = as_type<float4>(_1579._m0[_5591 + 5]);
                int _5915 = int(((device uint*)&_1579._m0[_5591 + 6])[0u]);
                float _5925 = dot(_5818, _15944);
                float _5931 = dot(_5825, _15944);
                float _5937 = dot(_5832, _15944);
                float3 _5938 = float3(_5925, _5931, _5937);
                float3 _5631 = (in.m_3056 + (_15944 * _5909.x)) + (_3575 * _5909.y);
                float3 _5650 = fast::clamp((((float3(dot(_5818, _5631) + _5822, dot(_5825, _5631) + _5829, dot(_5832, _5631) + _5836) + _5600) / fast::max(_5600 * 2.0, float3(9.9999999747524270787835121154785e-07))) * _5611) - float3(0.5), float3(0.0), _5611 - float3(1.0));
                int3 _5652 = int3(_5611);
                int3 _5659 = min(int3(_5650), max((_5652 - int3(2)), int3(0)));
                float3 _5663 = _5650 - float3(_5659);
                float _6018 = 0.48860299587249755859375 * _5931;
                float _6021 = 0.48860299587249755859375 * _5937;
                float _6024 = 0.48860299587249755859375 * _5925;
                float _6029 = 1.09254801273345947265625 * _5925;
                float _6032 = _6029 * _5931;
                float _6038 = (1.09254801273345947265625 * _5931) * _5937;
                float _6046 = 0.3153919875621795654296875 * (((3.0 * _5937) * _5937) - 1.0);
                float _6052 = _6029 * _5937;
                float _6066 = 0.546274006366729736328125 * ((_5925 * _5925) - (_5931 * _5931));
                int3 _6085 = _5652 - int3(1);
                int3 _6086 = min(_5659, _6085);
                int _6091 = _5652.x;
                int _6095 = _5652.y;
                int _6103 = _5915 + ((_6086.x + (_6091 * (_6086.y + (_6095 * _6086.z)))) * 4);
                float3 _6106 = float3(1.0) - _5663;
                float3 _6124 = (((((float3(_6086) + float3(0.5)) / _5611) * _5600) * 2.0) - _5600) - _5838;
                float _6134 = dot(_6124 * rsqrt(fast::max(dot(_6124, _6124), 1.0000000133514319600180897396058e-10)), _5938) + 1.0;
                float _6137 = _6106.x;
                float _6139 = _6106.y;
                float _6140 = _6137 * _6139;
                float _6142 = _6106.z;
                int _6166 = _6103 + 3;
                float _6152 = ((_6140 * _6142) * ((0.25 * (_6134 * _6134)) + 0.20000000298023223876953125)) * float(float2(as_type<half2>(((device uint*)&_1579._m0[_6166])[1u])).y > 0.5);
                int _6196 = _6103 + 1;
                int _6200 = _6103 + 2;
                float2 _6212 = float2(as_type<half2>(_1579._m0[_6103].y));
                float2 _6221 = float2(as_type<half2>(_1579._m0[_6196].x));
                float2 _6230 = float2(as_type<half2>(_1579._m0[_6196].w));
                float2 _6239 = float2(as_type<half2>(_1579._m0[_6200].z));
                float3 _6327 = (((((((float3(float2(as_type<half2>(_1579._m0[_6103].x)), _6212.x) * 0.2820949852466583251953125) + (float3(_6212.y, float2(as_type<half2>(_1579._m0[_6103].z))) * _6018)) + (float3(float2(as_type<half2>(_1579._m0[_6103].w)), _6221.x) * _6021)) + (float3(_6221.y, float2(as_type<half2>(_1579._m0[_6196].y))) * _6024)) + (float3(float2(as_type<half2>(_1579._m0[_6196].z)), _6230.x) * _6032)) + (float3(_6230.y, float2(as_type<half2>(_1579._m0[_6200].x))) * _6038)) + (float3(float2(as_type<half2>(_1579._m0[_6200].y)), _6239.x) * _6046)) + (float3(_6239.y, float2(as_type<half2>(_1579._m0[_6200].w))) * _6052);
                int3 _6355 = min((_5659 + int3(1, 0, 0)), _6085);
                int _6372 = _5915 + ((_6355.x + (_6091 * (_6355.y + (_6095 * _6355.z)))) * 4);
                float3 _6393 = (((((float3(_6355) + float3(0.5)) / _5611) * _5600) * 2.0) - _5600) - _5838;
                float _6403 = dot(_6393 * rsqrt(fast::max(dot(_6393, _6393), 1.0000000133514319600180897396058e-10)), _5938) + 1.0;
                float _6409 = _5663.x * _6139;
                int _6435 = _6372 + 3;
                float _6421 = ((_6409 * _6142) * ((0.25 * (_6403 * _6403)) + 0.20000000298023223876953125)) * float(float2(as_type<half2>(((device uint*)&_1579._m0[_6435])[1u])).y > 0.5);
                int _6465 = _6372 + 1;
                int _6469 = _6372 + 2;
                float2 _6481 = float2(as_type<half2>(_1579._m0[_6372].y));
                float2 _6490 = float2(as_type<half2>(_1579._m0[_6465].x));
                float2 _6499 = float2(as_type<half2>(_1579._m0[_6465].w));
                float2 _6508 = float2(as_type<half2>(_1579._m0[_6469].z));
                float3 _6596 = (((((((float3(float2(as_type<half2>(_1579._m0[_6372].x)), _6481.x) * 0.2820949852466583251953125) + (float3(_6481.y, float2(as_type<half2>(_1579._m0[_6372].z))) * _6018)) + (float3(float2(as_type<half2>(_1579._m0[_6372].w)), _6490.x) * _6021)) + (float3(_6490.y, float2(as_type<half2>(_1579._m0[_6465].y))) * _6024)) + (float3(float2(as_type<half2>(_1579._m0[_6465].z)), _6499.x) * _6032)) + (float3(_6499.y, float2(as_type<half2>(_1579._m0[_6469].x))) * _6038)) + (float3(float2(as_type<half2>(_1579._m0[_6469].y)), _6508.x) * _6046)) + (float3(_6508.y, float2(as_type<half2>(_1579._m0[_6469].w))) * _6052);
                int3 _6624 = min((_5659 + int3(0, 1, 0)), _6085);
                int _6641 = _5915 + ((_6624.x + (_6091 * (_6624.y + (_6095 * _6624.z)))) * 4);
                float3 _6662 = (((((float3(_6624) + float3(0.5)) / _5611) * _5600) * 2.0) - _5600) - _5838;
                float _6672 = dot(_6662 * rsqrt(fast::max(dot(_6662, _6662), 1.0000000133514319600180897396058e-10)), _5938) + 1.0;
                float _6678 = _6137 * _5663.y;
                int _6704 = _6641 + 3;
                float _6690 = ((_6678 * _6142) * ((0.25 * (_6672 * _6672)) + 0.20000000298023223876953125)) * float(float2(as_type<half2>(((device uint*)&_1579._m0[_6704])[1u])).y > 0.5);
                int _6734 = _6641 + 1;
                int _6738 = _6641 + 2;
                float2 _6750 = float2(as_type<half2>(_1579._m0[_6641].y));
                float2 _6759 = float2(as_type<half2>(_1579._m0[_6734].x));
                float2 _6768 = float2(as_type<half2>(_1579._m0[_6734].w));
                float2 _6777 = float2(as_type<half2>(_1579._m0[_6738].z));
                float3 _6865 = (((((((float3(float2(as_type<half2>(_1579._m0[_6641].x)), _6750.x) * 0.2820949852466583251953125) + (float3(_6750.y, float2(as_type<half2>(_1579._m0[_6641].z))) * _6018)) + (float3(float2(as_type<half2>(_1579._m0[_6641].w)), _6759.x) * _6021)) + (float3(_6759.y, float2(as_type<half2>(_1579._m0[_6734].y))) * _6024)) + (float3(float2(as_type<half2>(_1579._m0[_6734].z)), _6768.x) * _6032)) + (float3(_6768.y, float2(as_type<half2>(_1579._m0[_6738].x))) * _6038)) + (float3(float2(as_type<half2>(_1579._m0[_6738].y)), _6777.x) * _6046)) + (float3(_6777.y, float2(as_type<half2>(_1579._m0[_6738].w))) * _6052);
                int3 _6893 = min((_5659 + int3(1, 1, 0)), _6085);
                int _6910 = _5915 + ((_6893.x + (_6091 * (_6893.y + (_6095 * _6893.z)))) * 4);
                float3 _6931 = (((((float3(_6893) + float3(0.5)) / _5611) * _5600) * 2.0) - _5600) - _5838;
                float _6941 = dot(_6931 * rsqrt(fast::max(dot(_6931, _6931), 1.0000000133514319600180897396058e-10)), _5938) + 1.0;
                float _6947 = _5663.x * _5663.y;
                int _6973 = _6910 + 3;
                float _6959 = ((_6947 * _6142) * ((0.25 * (_6941 * _6941)) + 0.20000000298023223876953125)) * float(float2(as_type<half2>(((device uint*)&_1579._m0[_6973])[1u])).y > 0.5);
                int _7003 = _6910 + 1;
                int _7007 = _6910 + 2;
                float2 _7019 = float2(as_type<half2>(_1579._m0[_6910].y));
                float2 _7028 = float2(as_type<half2>(_1579._m0[_7003].x));
                float2 _7037 = float2(as_type<half2>(_1579._m0[_7003].w));
                float2 _7046 = float2(as_type<half2>(_1579._m0[_7007].z));
                float3 _7134 = (((((((float3(float2(as_type<half2>(_1579._m0[_6910].x)), _7019.x) * 0.2820949852466583251953125) + (float3(_7019.y, float2(as_type<half2>(_1579._m0[_6910].z))) * _6018)) + (float3(float2(as_type<half2>(_1579._m0[_6910].w)), _7028.x) * _6021)) + (float3(_7028.y, float2(as_type<half2>(_1579._m0[_7003].y))) * _6024)) + (float3(float2(as_type<half2>(_1579._m0[_7003].z)), _7037.x) * _6032)) + (float3(_7037.y, float2(as_type<half2>(_1579._m0[_7007].x))) * _6038)) + (float3(float2(as_type<half2>(_1579._m0[_7007].y)), _7046.x) * _6046)) + (float3(_7046.y, float2(as_type<half2>(_1579._m0[_7007].w))) * _6052);
                int3 _7162 = min((_5659 + int3(0, 0, 1)), _6085);
                int _7179 = _5915 + ((_7162.x + (_6091 * (_7162.y + (_6095 * _7162.z)))) * 4);
                float3 _7200 = (((((float3(_7162) + float3(0.5)) / _5611) * _5600) * 2.0) - _5600) - _5838;
                float _7210 = dot(_7200 * rsqrt(fast::max(dot(_7200, _7200), 1.0000000133514319600180897396058e-10)), _5938) + 1.0;
                int _7242 = _7179 + 3;
                float _7228 = ((_6140 * _5663.z) * ((0.25 * (_7210 * _7210)) + 0.20000000298023223876953125)) * float(float2(as_type<half2>(((device uint*)&_1579._m0[_7242])[1u])).y > 0.5);
                int _7272 = _7179 + 1;
                int _7276 = _7179 + 2;
                float2 _7288 = float2(as_type<half2>(_1579._m0[_7179].y));
                float2 _7297 = float2(as_type<half2>(_1579._m0[_7272].x));
                float2 _7306 = float2(as_type<half2>(_1579._m0[_7272].w));
                float2 _7315 = float2(as_type<half2>(_1579._m0[_7276].z));
                float3 _7403 = (((((((float3(float2(as_type<half2>(_1579._m0[_7179].x)), _7288.x) * 0.2820949852466583251953125) + (float3(_7288.y, float2(as_type<half2>(_1579._m0[_7179].z))) * _6018)) + (float3(float2(as_type<half2>(_1579._m0[_7179].w)), _7297.x) * _6021)) + (float3(_7297.y, float2(as_type<half2>(_1579._m0[_7272].y))) * _6024)) + (float3(float2(as_type<half2>(_1579._m0[_7272].z)), _7306.x) * _6032)) + (float3(_7306.y, float2(as_type<half2>(_1579._m0[_7276].x))) * _6038)) + (float3(float2(as_type<half2>(_1579._m0[_7276].y)), _7315.x) * _6046)) + (float3(_7315.y, float2(as_type<half2>(_1579._m0[_7276].w))) * _6052);
                float4 _5730 = (((float4((_6327 + (float3(float2(as_type<half2>(_1579._m0[_6166].x)), float2(as_type<half2>(_1579._m0[_6166].y)).x) * _6066)) * _6152, _6152) + float4((_6596 + (float3(float2(as_type<half2>(_1579._m0[_6435].x)), float2(as_type<half2>(_1579._m0[_6435].y)).x) * _6066)) * _6421, _6421)) + float4((_6865 + (float3(float2(as_type<half2>(_1579._m0[_6704].x)), float2(as_type<half2>(_1579._m0[_6704].y)).x) * _6066)) * _6690, _6690)) + float4((_7134 + (float3(float2(as_type<half2>(_1579._m0[_6973].x)), float2(as_type<half2>(_1579._m0[_6973].y)).x) * _6066)) * _6959, _6959)) + float4((_7403 + (float3(float2(as_type<half2>(_1579._m0[_7242].x)), float2(as_type<half2>(_1579._m0[_7242].y)).x) * _6066)) * _7228, _7228);
                int3 _7431 = min((_5659 + int3(1, 0, 1)), _6085);
                int _7448 = _5915 + ((_7431.x + (_6091 * (_7431.y + (_6095 * _7431.z)))) * 4);
                float3 _7469 = (((((float3(_7431) + float3(0.5)) / _5611) * _5600) * 2.0) - _5600) - _5838;
                float _7479 = dot(_7469 * rsqrt(fast::max(dot(_7469, _7469), 1.0000000133514319600180897396058e-10)), _5938) + 1.0;
                int _7511 = _7448 + 3;
                float _7497 = ((_6409 * _5663.z) * ((0.25 * (_7479 * _7479)) + 0.20000000298023223876953125)) * float(float2(as_type<half2>(((device uint*)&_1579._m0[_7511])[1u])).y > 0.5);
                int _7541 = _7448 + 1;
                int _7545 = _7448 + 2;
                float2 _7557 = float2(as_type<half2>(_1579._m0[_7448].y));
                float2 _7566 = float2(as_type<half2>(_1579._m0[_7541].x));
                float2 _7575 = float2(as_type<half2>(_1579._m0[_7541].w));
                float2 _7584 = float2(as_type<half2>(_1579._m0[_7545].z));
                float3 _7672 = (((((((float3(float2(as_type<half2>(_1579._m0[_7448].x)), _7557.x) * 0.2820949852466583251953125) + (float3(_7557.y, float2(as_type<half2>(_1579._m0[_7448].z))) * _6018)) + (float3(float2(as_type<half2>(_1579._m0[_7448].w)), _7566.x) * _6021)) + (float3(_7566.y, float2(as_type<half2>(_1579._m0[_7541].y))) * _6024)) + (float3(float2(as_type<half2>(_1579._m0[_7541].z)), _7575.x) * _6032)) + (float3(_7575.y, float2(as_type<half2>(_1579._m0[_7545].x))) * _6038)) + (float3(float2(as_type<half2>(_1579._m0[_7545].y)), _7584.x) * _6046)) + (float3(_7584.y, float2(as_type<half2>(_1579._m0[_7545].w))) * _6052);
                int3 _7700 = min((_5659 + int3(0, 1, 1)), _6085);
                int _7717 = _5915 + ((_7700.x + (_6091 * (_7700.y + (_6095 * _7700.z)))) * 4);
                float3 _7738 = (((((float3(_7700) + float3(0.5)) / _5611) * _5600) * 2.0) - _5600) - _5838;
                float _7748 = dot(_7738 * rsqrt(fast::max(dot(_7738, _7738), 1.0000000133514319600180897396058e-10)), _5938) + 1.0;
                int _7780 = _7717 + 3;
                float _7766 = ((_6678 * _5663.z) * ((0.25 * (_7748 * _7748)) + 0.20000000298023223876953125)) * float(float2(as_type<half2>(((device uint*)&_1579._m0[_7780])[1u])).y > 0.5);
                int _7810 = _7717 + 1;
                int _7814 = _7717 + 2;
                float2 _7826 = float2(as_type<half2>(_1579._m0[_7717].y));
                float2 _7835 = float2(as_type<half2>(_1579._m0[_7810].x));
                float2 _7844 = float2(as_type<half2>(_1579._m0[_7810].w));
                float2 _7853 = float2(as_type<half2>(_1579._m0[_7814].z));
                float3 _7941 = (((((((float3(float2(as_type<half2>(_1579._m0[_7717].x)), _7826.x) * 0.2820949852466583251953125) + (float3(_7826.y, float2(as_type<half2>(_1579._m0[_7717].z))) * _6018)) + (float3(float2(as_type<half2>(_1579._m0[_7717].w)), _7835.x) * _6021)) + (float3(_7835.y, float2(as_type<half2>(_1579._m0[_7810].y))) * _6024)) + (float3(float2(as_type<half2>(_1579._m0[_7810].z)), _7844.x) * _6032)) + (float3(_7844.y, float2(as_type<half2>(_1579._m0[_7814].x))) * _6038)) + (float3(float2(as_type<half2>(_1579._m0[_7814].y)), _7853.x) * _6046)) + (float3(_7853.y, float2(as_type<half2>(_1579._m0[_7814].w))) * _6052);
                int3 _7969 = min((_5659 + int3(1)), _6085);
                int _7986 = _5915 + ((_7969.x + (_6091 * (_7969.y + (_6095 * _7969.z)))) * 4);
                float3 _8007 = (((((float3(_7969) + float3(0.5)) / _5611) * _5600) * 2.0) - _5600) - _5838;
                float _8017 = dot(_8007 * rsqrt(fast::max(dot(_8007, _8007), 1.0000000133514319600180897396058e-10)), _5938) + 1.0;
                int _8049 = _7986 + 3;
                float _8035 = ((_6947 * _5663.z) * ((0.25 * (_8017 * _8017)) + 0.20000000298023223876953125)) * float(float2(as_type<half2>(((device uint*)&_1579._m0[_8049])[1u])).y > 0.5);
                int _8079 = _7986 + 1;
                int _8083 = _7986 + 2;
                float2 _8095 = float2(as_type<half2>(_1579._m0[_7986].y));
                float2 _8104 = float2(as_type<half2>(_1579._m0[_8079].x));
                float2 _8113 = float2(as_type<half2>(_1579._m0[_8079].w));
                float2 _8122 = float2(as_type<half2>(_1579._m0[_8083].z));
                float3 _8210 = (((((((float3(float2(as_type<half2>(_1579._m0[_7986].x)), _8095.x) * 0.2820949852466583251953125) + (float3(_8095.y, float2(as_type<half2>(_1579._m0[_7986].z))) * _6018)) + (float3(float2(as_type<half2>(_1579._m0[_7986].w)), _8104.x) * _6021)) + (float3(_8104.y, float2(as_type<half2>(_1579._m0[_8079].y))) * _6024)) + (float3(float2(as_type<half2>(_1579._m0[_8079].z)), _8113.x) * _6032)) + (float3(_8113.y, float2(as_type<half2>(_1579._m0[_8083].x))) * _6038)) + (float3(float2(as_type<half2>(_1579._m0[_8083].y)), _8122.x) * _6046)) + (float3(_8122.y, float2(as_type<half2>(_1579._m0[_8083].w))) * _6052);
                float4 _5769 = ((_5730 + float4((_7672 + (float3(float2(as_type<half2>(_1579._m0[_7511].x)), float2(as_type<half2>(_1579._m0[_7511].y)).x) * _6066)) * _7497, _7497)) + float4((_7941 + (float3(float2(as_type<half2>(_1579._m0[_7780].x)), float2(as_type<half2>(_1579._m0[_7780].y)).x) * _6066)) * _7766, _7766)) + float4((_8210 + (float3(float2(as_type<half2>(_1579._m0[_8049].x)), float2(as_type<half2>(_1579._m0[_8049].y)).x) * _6066)) * _8035, _8035);
                float _5773 = _5769.w;
                float3 _16849;
                if (_5773 > 9.9999997473787516355514526367188e-06)
                {
                    _16849 = mix(_16450, (fast::max(_5769.xyz, float3(0.0)) / float3(_5773)) * _5909.z, float3(_16810));
                }
                else
                {
                    _16849 = _16450;
                }
                _16848 = _16849;
            }
            _16451 = _16450;
        }
        else
        {
            _16451 = _16446;
        }
        float3 _3706 = (_15941 * ((_16451 * _16224) + ((_3617 * fast::max(_3640, 0.0)) * _15976))) + ((_3617 * ((powr(fast::max(dot(_15944, _3580), 0.0), _3535._m1.w) * _3535._m1.z) * step(0.0, _3640))) * _15976);
        float3 _16466;
        if (_594._m13.w > 0.5)
        {
            float2 _8248 = fast::clamp(floor(gl_FragCoord.xy * _594._m12.xy), float2(0.0), _594._m13.xy - float2(1.0));
            uint _8276 = uint((((fast::clamp(floor((log2(fast::max(dot(_594._m11.xyz, in.m_3056) + _594._m11.w, 9.9999999747524270787835121154785e-07)) * _594._m12.z) + _594._m12.w), 0.0, _594._m13.z - 1.0) * _594._m13.y) + _8248.y) * _594._m13.x) + _8248.x);
            uint _8278 = _8276 >> uint(2);
            uint _8280 = _8276 & 3u;
            uint _8284 = _3186._m0[_8278][_8280] & 65535u;
            uint _8286 = _3186._m0[_8278][_8280] >> uint(16);
            float3 _16467;
            _16467 = _3706;
            float3 _3786;
            spvUnsafeArray<float2, 3> _8694;
            spvUnsafeArray<float2, 3> _8695;
            spvUnsafeArray<float2, 3> _8907;
            spvUnsafeArray<float2, 3> _8908;
            for (uint _16464 = _8284; _16464 < (_8284 + _8286); _16467 = _3786, _16464++)
            {
                uint _8292 = _16464 / 3u;
                uint _8305 = (_3208._m0[_8292 >> uint(2)][_8292 & 3u] >> ((_16464 - (_8292 * 3u)) * 10u)) & 1023u;
                float3 _8322 = _3048._m0[_8305].xyz - in.m_3056;
                float _8325 = dot(_8322, _8322);
                float _8329 = _8325 * _3048._m0[_8305].w;
                float _8334 = fast::clamp(1.0 - (_8329 * _8329), 0.0, 1.0);
                float3 _8339 = _8322 * rsqrt(fast::max(_8325, 9.9999999392252902907785028219223e-09));
                float _8357 = fast::clamp((dot(-_8339, _3091._m0[_8305].xyz) * _3083._m0[_8305].w) + _3091._m0[_8305].w, 0.0, 1.0);
                float3 _8370 = _3083._m0[_8305].xyz * ((((_8334 * _8334) * _8357) * _8357) / fast::max(_8325, 9.9999997473787516355514526367188e-05));
                float3 _16775;
                if (_3591)
                {
                    float _16721;
                    do
                    {
                        uint _8406 = uint(_594._m21.z);
                        if (_8305 < _8406)
                        {
                            float _8428 = _594._m26[_8305].z * fast::max((_594._m15[_8305] * float4(in.m_3056, 1.0)).w, 0.0);
                            float4 _8452 = _594._m15[_8305] * float4((in.m_3056 + (_3586 * (_8428 * _594._m25.x))) + (_8339 * (_8428 * _594._m25.y)), 1.0);
                            float _8454 = _8452.w;
                            if (_8454 <= 0.0)
                            {
                                _16721 = 1.0;
                                break;
                            }
                            float3 _8463 = _8452.xyz / float3(_8454);
                            float _8465 = _8463.x;
                            bool _8466 = _8465 < 0.0;
                            bool _8473;
                            if (!_8466)
                            {
                                _8473 = _8465 > 1.0;
                            }
                            else
                            {
                                _8473 = _8466;
                            }
                            bool _8480;
                            if (!_8473)
                            {
                                _8480 = _8463.y < 0.0;
                            }
                            else
                            {
                                _8480 = _8473;
                            }
                            bool _8487;
                            if (!_8480)
                            {
                                _8487 = _8463.y > 1.0;
                            }
                            else
                            {
                                _8487 = _8480;
                            }
                            bool _8494;
                            if (!_8487)
                            {
                                _8494 = _8463.z > 1.0;
                            }
                            else
                            {
                                _8494 = _8487;
                            }
                            if (_8494)
                            {
                                _16721 = 1.0;
                                break;
                            }
                            float _8500 = _8463.z;
                            float2 _8666 = _594._m22.xy * 0.5;
                            float2 _8671 = _594._m26[_8305].xy + (_8463.xy * _594._m23.zw);
                            float4 _8684 = float4(_594._m26[_8305].xy + _8666, (_594._m26[_8305].xy + _594._m23.zw) - _8666);
                            float _16720;
                            do
                            {
                                int _8710 = int(_594._m22.z);
                                if (_8710 <= 0)
                                {
                                    float2 _8720 = fast::clamp(_8671, _8684.xy, _8684.zw);
                                    _16720 = spvDepthCast(_612).sample_compare(_612Smplr, float3(_8720, _8500).xy, _8500);
                                    break;
                                }
                                float2 _8733 = (_8671 / _594._m22.xy) + float2(0.5);
                                float2 _8734 = floor(_8733);
                                float2 _8739 = _8733 - _8734;
                                float2 _8742 = _8734 - float2(0.5);
                                bool _8746 = _8710 == 1;
                                if (_8746)
                                {
                                    float2 _8749 = _8739 * 2.0;
                                    _8694[0] = float2(3.0) - _8749;
                                    _8694[1] = float2(1.0) + _8749;
                                    _8695[0] = ((float2(2.0) - _8739) / _8694[0]) - float2(1.0);
                                    _8695[1] = (_8739 / _8694[1]) + float2(1.0);
                                }
                                else
                                {
                                    float2 _8776 = _8739 * 3.0;
                                    _8694[0] = float2(4.0) - _8776;
                                    _8694[1] = float2(7.0);
                                    _8694[2] = float2(1.0) + _8776;
                                    _8695[0] = ((float2(3.0) - (_8739 * 2.0)) / _8694[0]) - float2(2.0);
                                    _8695[1] = (float2(3.0) + _8739) / _8694[1];
                                    _8695[2] = (_8739 / _8694[2]) + float2(2.0);
                                }
                                int _16974 = _8746 ? 2 : 3;
                                int _16710;
                                float _16713;
                                _16713 = 0.0;
                                _16710 = 0;
                                float _16719;
                                for (; _16710 < _16974; _16713 = _16719, _16710++)
                                {
                                    _16719 = _16713;
                                    for (int _16716 = 0; _16716 < _16974; )
                                    {
                                        _16719 += ((_8694[_16716].x * _8694[_16710].y) * spvDepthCast(_612).sample_compare(_612Smplr, float3(fast::clamp(_594._m22.xy * (_8742 + float2(_8695[_16716].x, _8695[_16710].y)), _8684.xy, _8684.zw), _8500).xy, _8500));
                                        _16716++;
                                        continue;
                                    }
                                }
                                _16720 = _16713 * (_8746 ? 0.0625 : 0.0069444444961845874786376953125);
                                break;
                            } while(false);
                            _16721 = _16720;
                            break;
                        }
                        uint _8510 = _8305 - _8406;
                        if (_8510 >= uint(_594._m21.w))
                        {
                            _16721 = 1.0;
                            break;
                        }
                        float _8531 = _594._m27[_8510].w * length(in.m_3056 - _594._m27[_8510].xyz);
                        float3 _8549 = ((in.m_3056 + (_3586 * (_8531 * _594._m25.x))) + (_8339 * (_8531 * _594._m25.y))) - _594._m27[_8510].xyz;
                        float3 _8551 = abs(_8549);
                        float _8553 = _8551.x;
                        float _8555 = _8551.y;
                        bool _8556 = _8553 >= _8555;
                        bool _8564;
                        if (_8556)
                        {
                            _8564 = _8553 >= _8551.z;
                        }
                        else
                        {
                            _8564 = _8556;
                        }
                        float _16695;
                        int _16697;
                        if (_8564)
                        {
                            _16697 = (_8549.x > 0.0) ? 0 : 1;
                            _16695 = _8553;
                        }
                        else
                        {
                            float _8576 = _8551.z;
                            bool _8577 = _8555 >= _8576;
                            int _16698;
                            if (_8577)
                            {
                                _16698 = (_8549.y > 0.0) ? 2 : 3;
                            }
                            else
                            {
                                _16698 = (_8549.z > 0.0) ? 4 : 5;
                            }
                            _16697 = _16698;
                            _16695 = _8577 ? _8555 : _8576;
                        }
                        if (_16695 <= 0.0)
                        {
                            _16721 = 1.0;
                            break;
                        }
                        float2 _8614 = float2(dot(_8549, _1261[_16697]), dot(_8549, _1270[_16697])) / float2(_16695 * _594._m24.z);
                        float _8621 = _594._m28[_8510].z + (_594._m28[_8510].w / _16695);
                        if (_8621 > 1.0)
                        {
                            _16721 = 1.0;
                            break;
                        }
                        float2 _8639 = _594._m28[_8510].xy + (float2(float(spvSMod(_16697, 3)), float(_16697 / 3)) * _594._m24.xy);
                        float2 _8879 = _594._m22.xy * 0.5;
                        float2 _8884 = _8639 + (float2(0.5 + (0.5 * _8614.x), 0.5 - (0.5 * _8614.y)) * _594._m24.xy);
                        float4 _8897 = float4(_8639 + _8879, (_8639 + _594._m24.xy) - _8879);
                        float _16709;
                        do
                        {
                            int _8923 = int(_594._m22.z);
                            if (_8923 <= 0)
                            {
                                _16709 = spvDepthCast(_612).sample_compare(_612Smplr, float3(fast::clamp(_8884, _8897.xy, _8897.zw), _8621).xy, _8621);
                                break;
                            }
                            float2 _8946 = (_8884 / _594._m22.xy) + float2(0.5);
                            float2 _8947 = floor(_8946);
                            float2 _8952 = _8946 - _8947;
                            float2 _8955 = _8947 - float2(0.5);
                            bool _8959 = _8923 == 1;
                            if (_8959)
                            {
                                float2 _8962 = _8952 * 2.0;
                                _8907[0] = float2(3.0) - _8962;
                                _8907[1] = float2(1.0) + _8962;
                                _8908[0] = ((float2(2.0) - _8952) / _8907[0]) - float2(1.0);
                                _8908[1] = (_8952 / _8907[1]) + float2(1.0);
                            }
                            else
                            {
                                float2 _8989 = _8952 * 3.0;
                                _8907[0] = float2(4.0) - _8989;
                                _8907[1] = float2(7.0);
                                _8907[2] = float2(1.0) + _8989;
                                _8908[0] = ((float2(3.0) - (_8952 * 2.0)) / _8907[0]) - float2(2.0);
                                _8908[1] = (float2(3.0) + _8952) / _8907[1];
                                _8908[2] = (_8952 / _8907[2]) + float2(2.0);
                            }
                            int _16977 = _8959 ? 2 : 3;
                            int _16699;
                            float _16702;
                            _16702 = 0.0;
                            _16699 = 0;
                            float _16708;
                            for (; _16699 < _16977; _16702 = _16708, _16699++)
                            {
                                _16708 = _16702;
                                for (int _16705 = 0; _16705 < _16977; )
                                {
                                    _16708 += ((_8907[_16705].x * _8907[_16699].y) * spvDepthCast(_612).sample_compare(_612Smplr, float3(fast::clamp(_594._m22.xy * (_8955 + float2(_8908[_16705].x, _8908[_16699].y)), _8897.xy, _8897.zw), _8621).xy, _8621));
                                    _16705++;
                                    continue;
                                }
                            }
                            _16709 = _16702 * (_8959 ? 0.0625 : 0.0069444444961845874786376953125);
                            break;
                        } while(false);
                        _16721 = _16709;
                        break;
                    } while(false);
                    _16775 = _8370 * _16721;
                }
                else
                {
                    _16775 = _8370;
                }
                float _3757 = dot(_15944, _8339);
                _3786 = _16467 + (((_15941 * fast::max(_3757, 0.0)) * _16775) + (_16775 * ((powr(fast::max(dot(_15944, fast::normalize(_8339 + _3575)), 0.0), _3535._m1.w) * _3535._m1.z) * step(0.0, _3757))));
            }
            _16466 = _16467;
        }
        else
        {
            _16466 = _3706;
        }
        _16535 = _16451;
        _16465 = _16466;
    }
    else
    {
        float _3792 = fast::clamp(_277._m0[2].x, 0.0, 1.0);
        float _3796 = fast::clamp(_277._m0[1].w, 0.04500000178813934326171875, 1.0);
        float _3800 = _3796 * _3796;
        float3 _3805 = _15941 * (1.0 - _3792);
        float3 _3811 = mix(float3(0.039999999105930328369140625), _15941, float3(_3792));
        bool _3815 = _15830 > 0.0;
        float3 _15967;
        if (_3815)
        {
            float3 _3820 = dfdx(in.m_3056);
            float3 _3822 = dfdy(in.m_3056);
            float3 _3823 = cross(_3820, _3822);
            float3 _15968;
            if (dot(_3823, _3823) > 9.9999996826552253889678874634872e-21)
            {
                _15968 = fast::normalize((fast::normalize(_3823) * ((dot(_3823, _3575) < 0.0) ? (-1.0) : 1.0)) + (_15944 - _3477));
            }
            else
            {
                _15968 = _15944;
            }
            _15967 = _15968;
        }
        else
        {
            _15967 = _15944;
        }
        float _3849 = fast::max(dot(_15967, _3575), 9.9999997473787516355514526367188e-05);
        float _3858 = dot(_15967, _3568);
        float _3859 = fast::clamp(_3858, 0.0, 1.0);
        float _3864 = fast::clamp(dot(_15967, _3580), 0.0, 1.0);
        float _3869 = fast::clamp(dot(_3575, _3580), 0.0, 1.0);
        float _15971;
        float _15972;
        if (_3815)
        {
            _15972 = fast::max(_3849, 0.5);
            _15971 = fast::max(_3869, 0.5);
        }
        else
        {
            _15972 = _3849;
            _15971 = _3869;
        }
        float3 _9091 = float3(1.0) - _3811;
        float3 _9094 = _3811 + (_9091 * powr(1.0 - _15971, 5.0));
        float _9101 = _3800 * _3800;
        float _9106 = _9101 - 1.0;
        float _9108 = ((_3864 * _3864) * _9106) + 1.0;
        float _9128 = 1.0 - _9101;
        float _9132 = sqrt(((_15972 * _15972) * _9128) + _9101);
        float3 _3915 = (((((float3(1.0) - _9094) * _3805) * fast::clamp(dot(_15944, _3568), 0.0, 1.0)) + (((_9094 * ((_9101 / ((3.1415927410125732421875 * _9108) * _9108)) * (0.5 / fast::max((_3859 * _9132) + (_15972 * sqrt(((_3859 * _3859) * _9128) + _9101)), 9.9999997473787516355514526367188e-06)))) * 3.1415927410125732421875) * _3859)) * _3617) * _15976;
        float3 _16261;
        if (_3815)
        {
            _16261 = _3915 + (((((_3805 * _3617) * _15976) * _15830) * fast::clamp(-_3858, 0.0, 1.0)) * (0.3499999940395355224609375 + (0.64999997615814208984375 * powr(fast::clamp(dot(-_3575, _3568), 0.0, 1.0), 3.0))));
        }
        else
        {
            _16261 = _3915;
        }
        float3 _16000;
        float3 _16027;
        float2 _16173;
        if (_594._m29.x > 0.5)
        {
            float4 _9165 = _2927.sample(_2929, (((float2(_15972, _3796) * 31.0) + float2(0.5)) * float2(0.03125)));
            float _9224 = (_594._m29.z * _15944.x) - (_594._m29.w * _15944.z);
            float _9237 = (_594._m29.w * _15944.x) + (_594._m29.z * _15944.z);
            float _9255 = 1.09254801273345947265625 * _9224;
            spvUnsafeArray<float, 9> _14727 = spvUnsafeArray<float, 9>({ 0.2820949852466583251953125, 0.48860299587249755859375 * _15944.y, 0.48860299587249755859375 * _9237, 0.48860299587249755859375 * _9224, _9255 * _15944.y, (1.09254801273345947265625 * _15944.y) * _9237, 0.3153919875621795654296875 * (((3.0 * _9237) * _9237) - 1.0), _9255 * _9237, 0.546274006366729736328125 * ((_9224 * _9224) - (_15944.y * _15944.y)) });
            spvUnsafeArray<float, 9> _9169 = _14727;
            float3 _15984;
            _15984 = float3(0.0);
            for (int _15983 = 0; _15983 < 9; )
            {
                _15984 += (_2827.read(uint2((int2(496, 256) + int2(_15983, 0))), 0).xyz * _9169[_15983]);
                _15983++;
                continue;
            }
            float3 _3969 = reflect(-_3575, _15967);
            float _9350 = _3969.x;
            float _9355 = _3969.z;
            float2 _9387 = float2((precise::atan2((_594._m29.z * _9350) - (_594._m29.w * _9355), -((_594._m29.w * _9350) + (_594._m29.z * _9355))) * 0.15915493667125701904296875) + 0.5, acos(fast::clamp(_3969.y, -1.0, 1.0)) * 0.3183098733425140380859375);
            float _9319 = _3796 * 5.0;
            int _9322 = min(int(_9319), 4);
            float2 _9408 = (_9387 * float2(_2883[_9322].zw)) - float2(0.5);
            float2 _9410 = floor(_9408);
            float2 _9413 = _9408 - _9410;
            int _9416 = int(_9410.x);
            int _9419 = int(_9410.y);
            int _15986;
            if (_9416 < 0)
            {
                _15986 = _9416 + _2883[_9322].z;
            }
            else
            {
                _15986 = _9416;
            }
            int _15987;
            if (_15986 >= _2883[_9322].z)
            {
                _15987 = _15986 - _2883[_9322].z;
            }
            else
            {
                _15987 = _15986;
            }
            int _9439 = _15987 + 1;
            int _16978 = (_9439 == _2883[_9322].z) ? 0 : _9439;
            int _9454 = min((_9419 + 1), (_2883[_9322].w - 1));
            int _9456 = max(_9419, 0);
            float3 _9509 = float3(_9413.x);
            int _9329 = _9322 + 1;
            float2 _9541 = (_9387 * float2(_2883[_9329].zw)) - float2(0.5);
            float2 _9543 = floor(_9541);
            float2 _9546 = _9541 - _9543;
            int _9549 = int(_9543.x);
            int _9552 = int(_9543.y);
            int _15993;
            if (_9549 < 0)
            {
                _15993 = _9549 + _2883[_9329].z;
            }
            else
            {
                _15993 = _9549;
            }
            int _15994;
            if (_15993 >= _2883[_9329].z)
            {
                _15994 = _15993 - _2883[_9329].z;
            }
            else
            {
                _15994 = _15993;
            }
            int _9572 = _15994 + 1;
            int _16979 = (_9572 == _2883[_9329].z) ? 0 : _9572;
            int _9587 = min((_9552 + 1), (_2883[_9329].w - 1));
            int _9589 = max(_9552, 0);
            float3 _9642 = float3(_9546.x);
            float3 _9344 = mix(mix(mix(_2827.read(uint2((_2883[_9322].xy + int2(_15987, _9456))), 0).xyz, _2827.read(uint2((_2883[_9322].xy + int2(_16978, _9456))), 0).xyz, _9509), mix(_2827.read(uint2((_2883[_9322].xy + int2(_15987, _9454))), 0).xyz, _2827.read(uint2((_2883[_9322].xy + int2(_16978, _9454))), 0).xyz, _9509), float3(_9413.y)), mix(mix(_2827.read(uint2((_2883[_9329].xy + int2(_15994, _9589))), 0).xyz, _2827.read(uint2((_2883[_9329].xy + int2(_16979, _9589))), 0).xyz, _9642), mix(_2827.read(uint2((_2883[_9329].xy + int2(_15994, _9587))), 0).xyz, _2827.read(uint2((_2883[_9329].xy + int2(_16979, _9587))), 0).xyz, _9642), float3(_9546.y)), float3(_9319 - float(_9322))) * _594._m29.y;
            _16173 = _9165.xy;
            _16027 = _9344;
            _16000 = fast::max(_15984, float3(0.0)) * _594._m29.y;
        }
        else
        {
            float4 _9660 = (float4(-1.0, -0.0274999998509883880615234375, -0.572000026702880859375, 0.02199999988079071044921875) * _3796) + float4(1.0, 0.0425000004470348358154296875, 1.03999996185302734375, -0.039999999105930328369140625);
            float _9662 = _9660.x;
            float3 _9697 = mix(_594._m9.xyz, _594._m8.xyz, float3((_15944.y * 0.5) + 0.5)) * _594._m8.w;
            _16173 = (float2(-1.03999996185302734375, 1.03999996185302734375) * ((fast::min(_9662 * _9662, exp2((-9.27999973297119140625) * _15972)) * _9662) + _9660.y)) + _9660.zw;
            _16027 = mix(mix(_594._m9.xyz, _594._m8.xyz, float3((reflect(-_3575, _15967).y * 0.5) + 0.5)) * _594._m8.w, _9697, float3(_3796));
            _16000 = _9697;
        }
        float3 _16118;
        if (_594._m34.y > 0.5)
        {
            int _9834 = int(_594._m34.y);
            int _9837 = int(_594._m34.x);
            float3 _16016;
            _16016 = _16000;
            float3 _16821;
            for (int _16015 = 0; _16015 < _9834; _16016 = _16821, _16015++)
            {
                int _9849 = 8 * (_9837 + _16015);
                float4 _10058 = as_type<float4>(_1579._m0[_9849 + 3]);
                float4 _10102 = as_type<float4>(_1579._m0[_9849]);
                float4 _10108 = as_type<float4>(_1579._m0[_9849 + 1]);
                float4 _10114 = as_type<float4>(_1579._m0[_9849 + 2]);
                float3 _10076 = _10102.xyz;
                float _10080 = _10102.w;
                float3 _10083 = _10108.xyz;
                float _10087 = _10108.w;
                float3 _10090 = _10114.xyz;
                float _10094 = _10114.w;
                float3 _10096 = float3(dot(_10076, in.m_3056) + _10080, dot(_10083, in.m_3056) + _10087, dot(_10090, in.m_3056) + _10094);
                float3 _9858 = _10058.xyz;
                float _9860 = _10058.w;
                float _16439;
                do
                {
                    float3 _10126 = _9858 - abs(_10096);
                    float _10134 = fast::min(_10126.x, fast::min(_10126.y, _10126.z));
                    if (_10134 <= 0.0)
                    {
                        _16439 = 0.0;
                        break;
                    }
                    if (_9860 <= 0.0)
                    {
                        _16439 = 1.0;
                        break;
                    }
                    float _10146 = fast::min(_10134 / _9860, 1.0);
                    _16439 = (_10146 * _10146) * (3.0 - (2.0 * _10146));
                    break;
                } while(false);
                if (_16439 <= 0.0)
                {
                    _16821 = _16016;
                    continue;
                }
                float3 _9869 = as_type<float4>(_1579._m0[_9849 + 4]).xyz;
                float4 _10167 = as_type<float4>(_1579._m0[_9849 + 5]);
                int _10173 = int(((device uint*)&_1579._m0[_9849 + 6])[0u]);
                float _10183 = dot(_10076, _15944);
                float _10189 = dot(_10083, _15944);
                float _10195 = dot(_10090, _15944);
                float3 _10196 = float3(_10183, _10189, _10195);
                float3 _9889 = (in.m_3056 + (_15944 * _10167.x)) + (_3575 * _10167.y);
                float3 _9908 = fast::clamp((((float3(dot(_10076, _9889) + _10080, dot(_10083, _9889) + _10087, dot(_10090, _9889) + _10094) + _9858) / fast::max(_9858 * 2.0, float3(9.9999999747524270787835121154785e-07))) * _9869) - float3(0.5), float3(0.0), _9869 - float3(1.0));
                int3 _9910 = int3(_9869);
                int3 _9917 = min(int3(_9908), max((_9910 - int3(2)), int3(0)));
                float3 _9921 = _9908 - float3(_9917);
                float _10276 = 0.48860299587249755859375 * _10189;
                float _10279 = 0.48860299587249755859375 * _10195;
                float _10282 = 0.48860299587249755859375 * _10183;
                float _10287 = 1.09254801273345947265625 * _10183;
                float _10290 = _10287 * _10189;
                float _10296 = (1.09254801273345947265625 * _10189) * _10195;
                float _10304 = 0.3153919875621795654296875 * (((3.0 * _10195) * _10195) - 1.0);
                float _10310 = _10287 * _10195;
                float _10324 = 0.546274006366729736328125 * ((_10183 * _10183) - (_10189 * _10189));
                int3 _10343 = _9910 - int3(1);
                int3 _10344 = min(_9917, _10343);
                int _10349 = _9910.x;
                int _10353 = _9910.y;
                int _10361 = _10173 + ((_10344.x + (_10349 * (_10344.y + (_10353 * _10344.z)))) * 4);
                float3 _10364 = float3(1.0) - _9921;
                float3 _10382 = (((((float3(_10344) + float3(0.5)) / _9869) * _9858) * 2.0) - _9858) - _10096;
                float _10392 = dot(_10382 * rsqrt(fast::max(dot(_10382, _10382), 1.0000000133514319600180897396058e-10)), _10196) + 1.0;
                float _10395 = _10364.x;
                float _10397 = _10364.y;
                float _10398 = _10395 * _10397;
                float _10400 = _10364.z;
                int _10424 = _10361 + 3;
                float _10410 = ((_10398 * _10400) * ((0.25 * (_10392 * _10392)) + 0.20000000298023223876953125)) * float(float2(as_type<half2>(((device uint*)&_1579._m0[_10424])[1u])).y > 0.5);
                int _10454 = _10361 + 1;
                int _10458 = _10361 + 2;
                float2 _10470 = float2(as_type<half2>(_1579._m0[_10361].y));
                float2 _10479 = float2(as_type<half2>(_1579._m0[_10454].x));
                float2 _10488 = float2(as_type<half2>(_1579._m0[_10454].w));
                float2 _10497 = float2(as_type<half2>(_1579._m0[_10458].z));
                float3 _10585 = (((((((float3(float2(as_type<half2>(_1579._m0[_10361].x)), _10470.x) * 0.2820949852466583251953125) + (float3(_10470.y, float2(as_type<half2>(_1579._m0[_10361].z))) * _10276)) + (float3(float2(as_type<half2>(_1579._m0[_10361].w)), _10479.x) * _10279)) + (float3(_10479.y, float2(as_type<half2>(_1579._m0[_10454].y))) * _10282)) + (float3(float2(as_type<half2>(_1579._m0[_10454].z)), _10488.x) * _10290)) + (float3(_10488.y, float2(as_type<half2>(_1579._m0[_10458].x))) * _10296)) + (float3(float2(as_type<half2>(_1579._m0[_10458].y)), _10497.x) * _10304)) + (float3(_10497.y, float2(as_type<half2>(_1579._m0[_10458].w))) * _10310);
                int3 _10613 = min((_9917 + int3(1, 0, 0)), _10343);
                int _10630 = _10173 + ((_10613.x + (_10349 * (_10613.y + (_10353 * _10613.z)))) * 4);
                float3 _10651 = (((((float3(_10613) + float3(0.5)) / _9869) * _9858) * 2.0) - _9858) - _10096;
                float _10661 = dot(_10651 * rsqrt(fast::max(dot(_10651, _10651), 1.0000000133514319600180897396058e-10)), _10196) + 1.0;
                float _10667 = _9921.x * _10397;
                int _10693 = _10630 + 3;
                float _10679 = ((_10667 * _10400) * ((0.25 * (_10661 * _10661)) + 0.20000000298023223876953125)) * float(float2(as_type<half2>(((device uint*)&_1579._m0[_10693])[1u])).y > 0.5);
                int _10723 = _10630 + 1;
                int _10727 = _10630 + 2;
                float2 _10739 = float2(as_type<half2>(_1579._m0[_10630].y));
                float2 _10748 = float2(as_type<half2>(_1579._m0[_10723].x));
                float2 _10757 = float2(as_type<half2>(_1579._m0[_10723].w));
                float2 _10766 = float2(as_type<half2>(_1579._m0[_10727].z));
                float3 _10854 = (((((((float3(float2(as_type<half2>(_1579._m0[_10630].x)), _10739.x) * 0.2820949852466583251953125) + (float3(_10739.y, float2(as_type<half2>(_1579._m0[_10630].z))) * _10276)) + (float3(float2(as_type<half2>(_1579._m0[_10630].w)), _10748.x) * _10279)) + (float3(_10748.y, float2(as_type<half2>(_1579._m0[_10723].y))) * _10282)) + (float3(float2(as_type<half2>(_1579._m0[_10723].z)), _10757.x) * _10290)) + (float3(_10757.y, float2(as_type<half2>(_1579._m0[_10727].x))) * _10296)) + (float3(float2(as_type<half2>(_1579._m0[_10727].y)), _10766.x) * _10304)) + (float3(_10766.y, float2(as_type<half2>(_1579._m0[_10727].w))) * _10310);
                int3 _10882 = min((_9917 + int3(0, 1, 0)), _10343);
                int _10899 = _10173 + ((_10882.x + (_10349 * (_10882.y + (_10353 * _10882.z)))) * 4);
                float3 _10920 = (((((float3(_10882) + float3(0.5)) / _9869) * _9858) * 2.0) - _9858) - _10096;
                float _10930 = dot(_10920 * rsqrt(fast::max(dot(_10920, _10920), 1.0000000133514319600180897396058e-10)), _10196) + 1.0;
                float _10936 = _10395 * _9921.y;
                int _10962 = _10899 + 3;
                float _10948 = ((_10936 * _10400) * ((0.25 * (_10930 * _10930)) + 0.20000000298023223876953125)) * float(float2(as_type<half2>(((device uint*)&_1579._m0[_10962])[1u])).y > 0.5);
                int _10992 = _10899 + 1;
                int _10996 = _10899 + 2;
                float2 _11008 = float2(as_type<half2>(_1579._m0[_10899].y));
                float2 _11017 = float2(as_type<half2>(_1579._m0[_10992].x));
                float2 _11026 = float2(as_type<half2>(_1579._m0[_10992].w));
                float2 _11035 = float2(as_type<half2>(_1579._m0[_10996].z));
                float3 _11123 = (((((((float3(float2(as_type<half2>(_1579._m0[_10899].x)), _11008.x) * 0.2820949852466583251953125) + (float3(_11008.y, float2(as_type<half2>(_1579._m0[_10899].z))) * _10276)) + (float3(float2(as_type<half2>(_1579._m0[_10899].w)), _11017.x) * _10279)) + (float3(_11017.y, float2(as_type<half2>(_1579._m0[_10992].y))) * _10282)) + (float3(float2(as_type<half2>(_1579._m0[_10992].z)), _11026.x) * _10290)) + (float3(_11026.y, float2(as_type<half2>(_1579._m0[_10996].x))) * _10296)) + (float3(float2(as_type<half2>(_1579._m0[_10996].y)), _11035.x) * _10304)) + (float3(_11035.y, float2(as_type<half2>(_1579._m0[_10996].w))) * _10310);
                int3 _11151 = min((_9917 + int3(1, 1, 0)), _10343);
                int _11168 = _10173 + ((_11151.x + (_10349 * (_11151.y + (_10353 * _11151.z)))) * 4);
                float3 _11189 = (((((float3(_11151) + float3(0.5)) / _9869) * _9858) * 2.0) - _9858) - _10096;
                float _11199 = dot(_11189 * rsqrt(fast::max(dot(_11189, _11189), 1.0000000133514319600180897396058e-10)), _10196) + 1.0;
                float _11205 = _9921.x * _9921.y;
                int _11231 = _11168 + 3;
                float _11217 = ((_11205 * _10400) * ((0.25 * (_11199 * _11199)) + 0.20000000298023223876953125)) * float(float2(as_type<half2>(((device uint*)&_1579._m0[_11231])[1u])).y > 0.5);
                int _11261 = _11168 + 1;
                int _11265 = _11168 + 2;
                float2 _11277 = float2(as_type<half2>(_1579._m0[_11168].y));
                float2 _11286 = float2(as_type<half2>(_1579._m0[_11261].x));
                float2 _11295 = float2(as_type<half2>(_1579._m0[_11261].w));
                float2 _11304 = float2(as_type<half2>(_1579._m0[_11265].z));
                float3 _11392 = (((((((float3(float2(as_type<half2>(_1579._m0[_11168].x)), _11277.x) * 0.2820949852466583251953125) + (float3(_11277.y, float2(as_type<half2>(_1579._m0[_11168].z))) * _10276)) + (float3(float2(as_type<half2>(_1579._m0[_11168].w)), _11286.x) * _10279)) + (float3(_11286.y, float2(as_type<half2>(_1579._m0[_11261].y))) * _10282)) + (float3(float2(as_type<half2>(_1579._m0[_11261].z)), _11295.x) * _10290)) + (float3(_11295.y, float2(as_type<half2>(_1579._m0[_11265].x))) * _10296)) + (float3(float2(as_type<half2>(_1579._m0[_11265].y)), _11304.x) * _10304)) + (float3(_11304.y, float2(as_type<half2>(_1579._m0[_11265].w))) * _10310);
                int3 _11420 = min((_9917 + int3(0, 0, 1)), _10343);
                int _11437 = _10173 + ((_11420.x + (_10349 * (_11420.y + (_10353 * _11420.z)))) * 4);
                float3 _11458 = (((((float3(_11420) + float3(0.5)) / _9869) * _9858) * 2.0) - _9858) - _10096;
                float _11468 = dot(_11458 * rsqrt(fast::max(dot(_11458, _11458), 1.0000000133514319600180897396058e-10)), _10196) + 1.0;
                int _11500 = _11437 + 3;
                float _11486 = ((_10398 * _9921.z) * ((0.25 * (_11468 * _11468)) + 0.20000000298023223876953125)) * float(float2(as_type<half2>(((device uint*)&_1579._m0[_11500])[1u])).y > 0.5);
                int _11530 = _11437 + 1;
                int _11534 = _11437 + 2;
                float2 _11546 = float2(as_type<half2>(_1579._m0[_11437].y));
                float2 _11555 = float2(as_type<half2>(_1579._m0[_11530].x));
                float2 _11564 = float2(as_type<half2>(_1579._m0[_11530].w));
                float2 _11573 = float2(as_type<half2>(_1579._m0[_11534].z));
                float3 _11661 = (((((((float3(float2(as_type<half2>(_1579._m0[_11437].x)), _11546.x) * 0.2820949852466583251953125) + (float3(_11546.y, float2(as_type<half2>(_1579._m0[_11437].z))) * _10276)) + (float3(float2(as_type<half2>(_1579._m0[_11437].w)), _11555.x) * _10279)) + (float3(_11555.y, float2(as_type<half2>(_1579._m0[_11530].y))) * _10282)) + (float3(float2(as_type<half2>(_1579._m0[_11530].z)), _11564.x) * _10290)) + (float3(_11564.y, float2(as_type<half2>(_1579._m0[_11534].x))) * _10296)) + (float3(float2(as_type<half2>(_1579._m0[_11534].y)), _11573.x) * _10304)) + (float3(_11573.y, float2(as_type<half2>(_1579._m0[_11534].w))) * _10310);
                float4 _9988 = (((float4((_10585 + (float3(float2(as_type<half2>(_1579._m0[_10424].x)), float2(as_type<half2>(_1579._m0[_10424].y)).x) * _10324)) * _10410, _10410) + float4((_10854 + (float3(float2(as_type<half2>(_1579._m0[_10693].x)), float2(as_type<half2>(_1579._m0[_10693].y)).x) * _10324)) * _10679, _10679)) + float4((_11123 + (float3(float2(as_type<half2>(_1579._m0[_10962].x)), float2(as_type<half2>(_1579._m0[_10962].y)).x) * _10324)) * _10948, _10948)) + float4((_11392 + (float3(float2(as_type<half2>(_1579._m0[_11231].x)), float2(as_type<half2>(_1579._m0[_11231].y)).x) * _10324)) * _11217, _11217)) + float4((_11661 + (float3(float2(as_type<half2>(_1579._m0[_11500].x)), float2(as_type<half2>(_1579._m0[_11500].y)).x) * _10324)) * _11486, _11486);
                int3 _11689 = min((_9917 + int3(1, 0, 1)), _10343);
                int _11706 = _10173 + ((_11689.x + (_10349 * (_11689.y + (_10353 * _11689.z)))) * 4);
                float3 _11727 = (((((float3(_11689) + float3(0.5)) / _9869) * _9858) * 2.0) - _9858) - _10096;
                float _11737 = dot(_11727 * rsqrt(fast::max(dot(_11727, _11727), 1.0000000133514319600180897396058e-10)), _10196) + 1.0;
                int _11769 = _11706 + 3;
                float _11755 = ((_10667 * _9921.z) * ((0.25 * (_11737 * _11737)) + 0.20000000298023223876953125)) * float(float2(as_type<half2>(((device uint*)&_1579._m0[_11769])[1u])).y > 0.5);
                int _11799 = _11706 + 1;
                int _11803 = _11706 + 2;
                float2 _11815 = float2(as_type<half2>(_1579._m0[_11706].y));
                float2 _11824 = float2(as_type<half2>(_1579._m0[_11799].x));
                float2 _11833 = float2(as_type<half2>(_1579._m0[_11799].w));
                float2 _11842 = float2(as_type<half2>(_1579._m0[_11803].z));
                float3 _11930 = (((((((float3(float2(as_type<half2>(_1579._m0[_11706].x)), _11815.x) * 0.2820949852466583251953125) + (float3(_11815.y, float2(as_type<half2>(_1579._m0[_11706].z))) * _10276)) + (float3(float2(as_type<half2>(_1579._m0[_11706].w)), _11824.x) * _10279)) + (float3(_11824.y, float2(as_type<half2>(_1579._m0[_11799].y))) * _10282)) + (float3(float2(as_type<half2>(_1579._m0[_11799].z)), _11833.x) * _10290)) + (float3(_11833.y, float2(as_type<half2>(_1579._m0[_11803].x))) * _10296)) + (float3(float2(as_type<half2>(_1579._m0[_11803].y)), _11842.x) * _10304)) + (float3(_11842.y, float2(as_type<half2>(_1579._m0[_11803].w))) * _10310);
                int3 _11958 = min((_9917 + int3(0, 1, 1)), _10343);
                int _11975 = _10173 + ((_11958.x + (_10349 * (_11958.y + (_10353 * _11958.z)))) * 4);
                float3 _11996 = (((((float3(_11958) + float3(0.5)) / _9869) * _9858) * 2.0) - _9858) - _10096;
                float _12006 = dot(_11996 * rsqrt(fast::max(dot(_11996, _11996), 1.0000000133514319600180897396058e-10)), _10196) + 1.0;
                int _12038 = _11975 + 3;
                float _12024 = ((_10936 * _9921.z) * ((0.25 * (_12006 * _12006)) + 0.20000000298023223876953125)) * float(float2(as_type<half2>(((device uint*)&_1579._m0[_12038])[1u])).y > 0.5);
                int _12068 = _11975 + 1;
                int _12072 = _11975 + 2;
                float2 _12084 = float2(as_type<half2>(_1579._m0[_11975].y));
                float2 _12093 = float2(as_type<half2>(_1579._m0[_12068].x));
                float2 _12102 = float2(as_type<half2>(_1579._m0[_12068].w));
                float2 _12111 = float2(as_type<half2>(_1579._m0[_12072].z));
                float3 _12199 = (((((((float3(float2(as_type<half2>(_1579._m0[_11975].x)), _12084.x) * 0.2820949852466583251953125) + (float3(_12084.y, float2(as_type<half2>(_1579._m0[_11975].z))) * _10276)) + (float3(float2(as_type<half2>(_1579._m0[_11975].w)), _12093.x) * _10279)) + (float3(_12093.y, float2(as_type<half2>(_1579._m0[_12068].y))) * _10282)) + (float3(float2(as_type<half2>(_1579._m0[_12068].z)), _12102.x) * _10290)) + (float3(_12102.y, float2(as_type<half2>(_1579._m0[_12072].x))) * _10296)) + (float3(float2(as_type<half2>(_1579._m0[_12072].y)), _12111.x) * _10304)) + (float3(_12111.y, float2(as_type<half2>(_1579._m0[_12072].w))) * _10310);
                int3 _12227 = min((_9917 + int3(1)), _10343);
                int _12244 = _10173 + ((_12227.x + (_10349 * (_12227.y + (_10353 * _12227.z)))) * 4);
                float3 _12265 = (((((float3(_12227) + float3(0.5)) / _9869) * _9858) * 2.0) - _9858) - _10096;
                float _12275 = dot(_12265 * rsqrt(fast::max(dot(_12265, _12265), 1.0000000133514319600180897396058e-10)), _10196) + 1.0;
                int _12307 = _12244 + 3;
                float _12293 = ((_11205 * _9921.z) * ((0.25 * (_12275 * _12275)) + 0.20000000298023223876953125)) * float(float2(as_type<half2>(((device uint*)&_1579._m0[_12307])[1u])).y > 0.5);
                int _12337 = _12244 + 1;
                int _12341 = _12244 + 2;
                float2 _12353 = float2(as_type<half2>(_1579._m0[_12244].y));
                float2 _12362 = float2(as_type<half2>(_1579._m0[_12337].x));
                float2 _12371 = float2(as_type<half2>(_1579._m0[_12337].w));
                float2 _12380 = float2(as_type<half2>(_1579._m0[_12341].z));
                float3 _12468 = (((((((float3(float2(as_type<half2>(_1579._m0[_12244].x)), _12353.x) * 0.2820949852466583251953125) + (float3(_12353.y, float2(as_type<half2>(_1579._m0[_12244].z))) * _10276)) + (float3(float2(as_type<half2>(_1579._m0[_12244].w)), _12362.x) * _10279)) + (float3(_12362.y, float2(as_type<half2>(_1579._m0[_12337].y))) * _10282)) + (float3(float2(as_type<half2>(_1579._m0[_12337].z)), _12371.x) * _10290)) + (float3(_12371.y, float2(as_type<half2>(_1579._m0[_12341].x))) * _10296)) + (float3(float2(as_type<half2>(_1579._m0[_12341].y)), _12380.x) * _10304)) + (float3(_12380.y, float2(as_type<half2>(_1579._m0[_12341].w))) * _10310);
                float4 _10027 = ((_9988 + float4((_11930 + (float3(float2(as_type<half2>(_1579._m0[_11769].x)), float2(as_type<half2>(_1579._m0[_11769].y)).x) * _10324)) * _11755, _11755)) + float4((_12199 + (float3(float2(as_type<half2>(_1579._m0[_12038].x)), float2(as_type<half2>(_1579._m0[_12038].y)).x) * _10324)) * _12024, _12024)) + float4((_12468 + (float3(float2(as_type<half2>(_1579._m0[_12307].x)), float2(as_type<half2>(_1579._m0[_12307].y)).x) * _10324)) * _12293, _12293);
                float _10031 = _10027.w;
                float3 _16822;
                if (_10031 > 9.9999997473787516355514526367188e-06)
                {
                    _16822 = mix(_16016, (fast::max(_10027.xyz, float3(0.0)) / float3(_10031)) * _10167.z, float3(_16439));
                }
                else
                {
                    _16822 = _16016;
                }
                _16821 = _16822;
            }
            _16118 = _16016;
        }
        else
        {
            _16118 = _16000;
        }
        float3 _16140;
        if (_594._m34.x > 0.5)
        {
            float3 _4015 = reflect(-_3575, _15967);
            int _12516 = int(_594._m34.x);
            float _16030;
            float3 _16096;
            _16096 = float3(0.0);
            _16030 = 0.0;
            float _16829;
            float3 _16830;
            for (int _16029 = 0; _16029 < _12516; _16096 = _16830, _16030 = _16829, _16029++)
            {
                if (_16030 > 0.999000012874603271484375)
                {
                    break;
                }
                int _12528 = _16029 * 8;
                float4 _12643 = as_type<float4>(_1579._m0[_12528]);
                float4 _12649 = as_type<float4>(_1579._m0[_12528 + 1]);
                float4 _12655 = as_type<float4>(_1579._m0[_12528 + 2]);
                float3 _12617 = _12643.xyz;
                float3 _12624 = _12649.xyz;
                float3 _12631 = _12655.xyz;
                float3 _12637 = float3(dot(_12617, in.m_3056) + _12643.w, dot(_12624, in.m_3056) + _12649.w, dot(_12631, in.m_3056) + _12655.w);
                float4 _12661 = as_type<float4>(_1579._m0[_12528 + 3]);
                float _12539 = _12661.w;
                float _16031;
                do
                {
                    float3 _12673 = _12661.xyz - abs(_12637);
                    float _12681 = fast::min(_12673.x, fast::min(_12673.y, _12673.z));
                    if (_12681 <= 0.0)
                    {
                        _16031 = 0.0;
                        break;
                    }
                    if (_12539 <= 0.0)
                    {
                        _16031 = 1.0;
                        break;
                    }
                    float _12693 = fast::min(_12681 / _12539, 1.0);
                    _16031 = (_12693 * _12693) * (3.0 - (2.0 * _12693));
                    break;
                } while(false);
                if (_16031 <= 0.0)
                {
                    _16830 = _16096;
                    _16829 = _16030;
                    continue;
                }
                float4 _12708 = as_type<float4>(_1579._m0[_12528 + 4]);
                float4 _12714 = as_type<float4>(_1579._m0[_12528 + 5]);
                float3 _12737 = float3(dot(_12617, _4015), dot(_12624, _4015), dot(_12631, _4015));
                float3 _16033;
                if (_12708.w > 0.5)
                {
                    float3 _12561 = _12708.xyz;
                    float3 _12767 = -_12561;
                    float3 _12769 = fast::clamp(_12637, _12767, _12561);
                    float3 _12779 = step(float3(9.9999999747524270787835121154785e-07), abs(_12737));
                    float3 _12789 = mix(float3(1000000015047466219876688855040.0), (mix(_12767, _12561, step(float3(0.0), _12737)) - _12769) / mix(float3(9.9999999747524270787835121154785e-07), _12737, _12779), _12779);
                    float3 _12805 = (_12769 + (_12737 * fast::max(fast::min(_12789.x, fast::min(_12789.y, _12789.z)), 0.0))) - _12714.xyz;
                    float3 _16032;
                    if (dot(_12805, _12805) > 9.9999999600419720025001879548654e-13)
                    {
                        _16032 = fast::normalize(_12805);
                    }
                    else
                    {
                        _16032 = _12737;
                    }
                    _16033 = _16032;
                }
                else
                {
                    _16033 = _12737;
                }
                int _12822 = int(((device uint*)&_1579._m0[_12528 + 6])[0u]);
                float2 _12872 = float2((precise::atan2(_16033.x, -_16033.z) * 0.15915493667125701904296875) + 0.5, acos(fast::clamp(_16033.y, -1.0, 1.0)) * 0.3183098733425140380859375);
                float _12838 = _3796 * 5.0;
                int _12841 = min(int(_12838), 4);
                int _12912 = _12822 + _1651[_12841].x;
                float2 _12919 = (_12872 * float2(_1651[_12841].yz)) - float2(0.5);
                float2 _12921 = floor(_12919);
                float2 _12924 = _12919 - _12921;
                int _12927 = int(_12921.x);
                int _12930 = int(_12921.y);
                int _16034;
                if (_12927 < 0)
                {
                    _16034 = _12927 + _1651[_12841].y;
                }
                else
                {
                    _16034 = _12927;
                }
                int _16035;
                if (_16034 >= _1651[_12841].y)
                {
                    _16035 = _16034 - _1651[_12841].y;
                }
                else
                {
                    _16035 = _16034;
                }
                int _12950 = _16035 + 1;
                int _16980 = (_12950 == _1651[_12841].y) ? 0 : _12950;
                int _13018 = _12912 + (max(_12930, 0) * _1651[_12841].y);
                int _13020 = _13018 + _16035;
                int _13022 = _13020 >> 1;
                uint2 _16041;
                if ((_13020 & 1) == 0)
                {
                    _16041 = _1579._m0[_13022].xy;
                }
                else
                {
                    _16041 = _1579._m0[_13022].zw;
                }
                int _13058 = _13018 + _16980;
                int _13060 = _13058 >> 1;
                uint2 _16043;
                if ((_13058 & 1) == 0)
                {
                    _16043 = _1579._m0[_13060].xy;
                }
                else
                {
                    _16043 = _1579._m0[_13060].zw;
                }
                int _13094 = _12912 + (min((_12930 + 1), (_1651[_12841].z - 1)) * _1651[_12841].y);
                int _13096 = _13094 + _16035;
                int _13098 = _13096 >> 1;
                uint2 _16046;
                if ((_13096 & 1) == 0)
                {
                    _16046 = _1579._m0[_13098].xy;
                }
                else
                {
                    _16046 = _1579._m0[_13098].zw;
                }
                int _13134 = _13094 + _16980;
                int _13136 = _13134 >> 1;
                uint2 _16047;
                if ((_13134 & 1) == 0)
                {
                    _16047 = _1579._m0[_13136].xy;
                }
                else
                {
                    _16047 = _1579._m0[_13136].zw;
                }
                float3 _12996 = float3(_12924.x);
                int _12847 = _12841 + 1;
                int _13199 = _12822 + _1651[_12847].x;
                float2 _13206 = (_12872 * float2(_1651[_12847].yz)) - float2(0.5);
                float2 _13208 = floor(_13206);
                float2 _13211 = _13206 - _13208;
                int _13214 = int(_13208.x);
                int _13217 = int(_13208.y);
                int _16048;
                if (_13214 < 0)
                {
                    _16048 = _13214 + _1651[_12847].y;
                }
                else
                {
                    _16048 = _13214;
                }
                int _16049;
                if (_16048 >= _1651[_12847].y)
                {
                    _16049 = _16048 - _1651[_12847].y;
                }
                else
                {
                    _16049 = _16048;
                }
                int _13237 = _16049 + 1;
                int _16981 = (_13237 == _1651[_12847].y) ? 0 : _13237;
                int _13305 = _13199 + (max(_13217, 0) * _1651[_12847].y);
                int _13307 = _13305 + _16049;
                int _13309 = _13307 >> 1;
                uint2 _16055;
                if ((_13307 & 1) == 0)
                {
                    _16055 = _1579._m0[_13309].xy;
                }
                else
                {
                    _16055 = _1579._m0[_13309].zw;
                }
                int _13345 = _13305 + _16981;
                int _13347 = _13345 >> 1;
                uint2 _16057;
                if ((_13345 & 1) == 0)
                {
                    _16057 = _1579._m0[_13347].xy;
                }
                else
                {
                    _16057 = _1579._m0[_13347].zw;
                }
                int _13381 = _13199 + (min((_13217 + 1), (_1651[_12847].z - 1)) * _1651[_12847].y);
                int _13383 = _13381 + _16049;
                int _13385 = _13383 >> 1;
                uint2 _16060;
                if ((_13383 & 1) == 0)
                {
                    _16060 = _1579._m0[_13385].xy;
                }
                else
                {
                    _16060 = _1579._m0[_13385].zw;
                }
                int _13421 = _13381 + _16981;
                int _13423 = _13421 >> 1;
                uint2 _16061;
                if ((_13421 & 1) == 0)
                {
                    _16061 = _1579._m0[_13423].xy;
                }
                else
                {
                    _16061 = _1579._m0[_13423].zw;
                }
                float3 _13283 = float3(_13211.x);
                float3 _12577 = mix(mix(mix(float3(float2(as_type<half2>(_16041.x)), float2(as_type<half2>(_16041.y)).x), float3(float2(as_type<half2>(_16043.x)), float2(as_type<half2>(_16043.y)).x), _12996), mix(float3(float2(as_type<half2>(_16046.x)), float2(as_type<half2>(_16046.y)).x), float3(float2(as_type<half2>(_16047.x)), float2(as_type<half2>(_16047.y)).x), _12996), float3(_12924.y)), mix(mix(float3(float2(as_type<half2>(_16055.x)), float2(as_type<half2>(_16055.y)).x), float3(float2(as_type<half2>(_16057.x)), float2(as_type<half2>(_16057.y)).x), _13283), mix(float3(float2(as_type<half2>(_16060.x)), float2(as_type<half2>(_16060.y)).x), float3(float2(as_type<half2>(_16061.x)), float2(as_type<half2>(_16061.y)).x), _13283), float3(_13211.y)), float3(_12838 - float(_12841))) * _12714.w;
                float _12581 = _16031 * (1.0 - _16030);
                _16830 = _16096 + (_12577 * _12581);
                _16829 = _16030 + _12581;
            }
            _16140 = _16096 + (_16027 * (1.0 - _16030));
        }
        else
        {
            _16140 = _16027;
        }
        bool _4027 = _3535._m6.w > 0.5;
        bool _4033;
        if (_4027)
        {
            _4033 = _594._m33.z > 0.5;
        }
        else
        {
            _4033 = _4027;
        }
        float3 _16208;
        if (_4033)
        {
            float3 _16168;
            do
            {
                float _13508 = ((_594._m32.x * (1.0 - smoothstep(_594._m33.x * 0.5, _594._m33.x, abs(dot(_594._m31.xyz, in.m_3056) - _594._m31.w)))) * smoothstep(0.5, 0.89999997615814208984375, dot(_3586, _594._m31.xyz))) * (1.0 - smoothstep(_594._m32.y * 0.5, _594._m32.y, _3796));
                if (_13508 <= 0.0)
                {
                    _16168 = _16140;
                    break;
                }
                float4 _13533 = _594._m30 * float4(in.m_3056 + ((_15944 - (_594._m31.xyz * dot(_15944, _594._m31.xyz))) * _594._m32.w), 1.0);
                float2 _13546 = ((float2(_13533.x, -_13533.y) / float2(_13533.w)) * 0.5) + float2(0.5);
                float _13550 = _594._m32.z * _3796;
                float3 _16166;
                float _16167;
                _16167 = 0.0;
                _16166 = float3(0.0);
                for (int _16165 = 0; _16165 < 12; )
                {
                    float _13557 = float(_16165);
                    float _13565 = _13557 * 2.3999631404876708984375;
                    float2 _13577 = _13546 + (float2(cos(_13565) * _594._m33.y, sin(_13565)) * (sqrt((_13557 + 0.5) * 0.083333335816860198974609375) * _13550));
                    float2 _13582 = fast::min(_13577, float2(1.0) - _13577);
                    float _13588 = smoothstep(0.0, 0.039999999105930328369140625, fast::min(_13582.x, _13582.y));
                    float4 _13596 = _3372.sample(_361, fast::clamp(_13577, float2(0.0), float2(1.0)), level(0.0));
                    float3 _13598 = _13596.xyz;
                    _16167 += (_13596.w * _13588);
                    _16166 += ((_13598 / (float3(1.0) - fast::min(_13598, float3(0.99500000476837158203125)))) * _13588);
                    _16165++;
                    continue;
                }
                _16168 = mix(_16140, (_16166 * float3(0.083333335816860198974609375)) + (_16140 * (1.0 - (_16167 * 0.083333335816860198974609375))), float3(_13508));
                break;
            } while(false);
            _16208 = _16168;
        }
        else
        {
            _16208 = _16140;
        }
        float3 _4053 = (_3811 * _16173.x) + float3(_16173.y);
        float3 _4069 = _16261 + (((((float3(1.0) - _4053) * _3805) * _16118) + (_4053 * _16208)) * _16224);
        float3 _16468;
        if (_594._m13.w > 0.5)
        {
            float2 _13662 = fast::clamp(floor(gl_FragCoord.xy * _594._m12.xy), float2(0.0), _594._m13.xy - float2(1.0));
            uint _13690 = uint((((fast::clamp(floor((log2(fast::max(dot(_594._m11.xyz, in.m_3056) + _594._m11.w, 9.9999999747524270787835121154785e-07)) * _594._m12.z) + _594._m12.w), 0.0, _594._m13.z - 1.0) * _594._m13.y) + _13662.y) * _594._m13.x) + _13662.x);
            uint _13692 = _13690 >> uint(2);
            uint _13694 = _13690 & 3u;
            uint _13698 = _3186._m0[_13692][_13694] & 65535u;
            uint _13700 = _3186._m0[_13692][_13694] >> uint(16);
            float3 _16405;
            _16405 = _4069;
            float3 _4169;
            spvUnsafeArray<float2, 3> _14108;
            spvUnsafeArray<float2, 3> _14109;
            spvUnsafeArray<float2, 3> _14321;
            spvUnsafeArray<float2, 3> _14322;
            for (uint _16285 = _13698; _16285 < (_13698 + _13700); _16405 = _4169, _16285++)
            {
                uint _13706 = _16285 / 3u;
                uint _13719 = (_3208._m0[_13706 >> uint(2)][_13706 & 3u] >> ((_16285 - (_13706 * 3u)) * 10u)) & 1023u;
                float3 _13736 = _3048._m0[_13719].xyz - in.m_3056;
                float _13739 = dot(_13736, _13736);
                float _13743 = _13739 * _3048._m0[_13719].w;
                float _13748 = fast::clamp(1.0 - (_13743 * _13743), 0.0, 1.0);
                float3 _13753 = _13736 * rsqrt(fast::max(_13739, 9.9999999392252902907785028219223e-09));
                float _13771 = fast::clamp((dot(-_13753, _3091._m0[_13719].xyz) * _3083._m0[_13719].w) + _3091._m0[_13719].w, 0.0, 1.0);
                float3 _13784 = _3083._m0[_13719].xyz * ((((_13748 * _13748) * _13771) * _13771) / fast::max(_13739, 9.9999997473787516355514526367188e-05));
                float3 _16403;
                if (_3591)
                {
                    float _16312;
                    do
                    {
                        uint _13820 = uint(_594._m21.z);
                        if (_13719 < _13820)
                        {
                            float _13842 = _594._m26[_13719].z * fast::max((_594._m15[_13719] * float4(in.m_3056, 1.0)).w, 0.0);
                            float4 _13866 = _594._m15[_13719] * float4((in.m_3056 + (_3586 * (_13842 * _594._m25.x))) + (_13753 * (_13842 * _594._m25.y)), 1.0);
                            float _13868 = _13866.w;
                            if (_13868 <= 0.0)
                            {
                                _16312 = 1.0;
                                break;
                            }
                            float3 _13877 = _13866.xyz / float3(_13868);
                            float _13879 = _13877.x;
                            bool _13880 = _13879 < 0.0;
                            bool _13887;
                            if (!_13880)
                            {
                                _13887 = _13879 > 1.0;
                            }
                            else
                            {
                                _13887 = _13880;
                            }
                            bool _13894;
                            if (!_13887)
                            {
                                _13894 = _13877.y < 0.0;
                            }
                            else
                            {
                                _13894 = _13887;
                            }
                            bool _13901;
                            if (!_13894)
                            {
                                _13901 = _13877.y > 1.0;
                            }
                            else
                            {
                                _13901 = _13894;
                            }
                            bool _13908;
                            if (!_13901)
                            {
                                _13908 = _13877.z > 1.0;
                            }
                            else
                            {
                                _13908 = _13901;
                            }
                            if (_13908)
                            {
                                _16312 = 1.0;
                                break;
                            }
                            float _13914 = _13877.z;
                            float2 _14080 = _594._m22.xy * 0.5;
                            float2 _14085 = _594._m26[_13719].xy + (_13877.xy * _594._m23.zw);
                            float4 _14098 = float4(_594._m26[_13719].xy + _14080, (_594._m26[_13719].xy + _594._m23.zw) - _14080);
                            float _16311;
                            do
                            {
                                int _14124 = int(_594._m22.z);
                                if (_14124 <= 0)
                                {
                                    float2 _14134 = fast::clamp(_14085, _14098.xy, _14098.zw);
                                    _16311 = spvDepthCast(_612).sample_compare(_612Smplr, float3(_14134, _13914).xy, _13914);
                                    break;
                                }
                                float2 _14147 = (_14085 / _594._m22.xy) + float2(0.5);
                                float2 _14148 = floor(_14147);
                                float2 _14153 = _14147 - _14148;
                                float2 _14156 = _14148 - float2(0.5);
                                bool _14160 = _14124 == 1;
                                if (_14160)
                                {
                                    float2 _14163 = _14153 * 2.0;
                                    _14108[0] = float2(3.0) - _14163;
                                    _14108[1] = float2(1.0) + _14163;
                                    _14109[0] = ((float2(2.0) - _14153) / _14108[0]) - float2(1.0);
                                    _14109[1] = (_14153 / _14108[1]) + float2(1.0);
                                }
                                else
                                {
                                    float2 _14190 = _14153 * 3.0;
                                    _14108[0] = float2(4.0) - _14190;
                                    _14108[1] = float2(7.0);
                                    _14108[2] = float2(1.0) + _14190;
                                    _14109[0] = ((float2(3.0) - (_14153 * 2.0)) / _14108[0]) - float2(2.0);
                                    _14109[1] = (float2(3.0) + _14153) / _14108[1];
                                    _14109[2] = (_14153 / _14108[2]) + float2(2.0);
                                }
                                int _16983 = _14160 ? 2 : 3;
                                int _16301;
                                float _16304;
                                _16304 = 0.0;
                                _16301 = 0;
                                float _16310;
                                for (; _16301 < _16983; _16304 = _16310, _16301++)
                                {
                                    _16310 = _16304;
                                    for (int _16307 = 0; _16307 < _16983; )
                                    {
                                        _16310 += ((_14108[_16307].x * _14108[_16301].y) * spvDepthCast(_612).sample_compare(_612Smplr, float3(fast::clamp(_594._m22.xy * (_14156 + float2(_14109[_16307].x, _14109[_16301].y)), _14098.xy, _14098.zw), _13914).xy, _13914));
                                        _16307++;
                                        continue;
                                    }
                                }
                                _16311 = _16304 * (_14160 ? 0.0625 : 0.0069444444961845874786376953125);
                                break;
                            } while(false);
                            _16312 = _16311;
                            break;
                        }
                        uint _13924 = _13719 - _13820;
                        if (_13924 >= uint(_594._m21.w))
                        {
                            _16312 = 1.0;
                            break;
                        }
                        float _13945 = _594._m27[_13924].w * length(in.m_3056 - _594._m27[_13924].xyz);
                        float3 _13963 = ((in.m_3056 + (_3586 * (_13945 * _594._m25.x))) + (_13753 * (_13945 * _594._m25.y))) - _594._m27[_13924].xyz;
                        float3 _13965 = abs(_13963);
                        float _13967 = _13965.x;
                        float _13969 = _13965.y;
                        bool _13970 = _13967 >= _13969;
                        bool _13978;
                        if (_13970)
                        {
                            _13978 = _13967 >= _13965.z;
                        }
                        else
                        {
                            _13978 = _13970;
                        }
                        float _16286;
                        int _16288;
                        if (_13978)
                        {
                            _16288 = (_13963.x > 0.0) ? 0 : 1;
                            _16286 = _13967;
                        }
                        else
                        {
                            float _13990 = _13965.z;
                            bool _13991 = _13969 >= _13990;
                            int _16289;
                            if (_13991)
                            {
                                _16289 = (_13963.y > 0.0) ? 2 : 3;
                            }
                            else
                            {
                                _16289 = (_13963.z > 0.0) ? 4 : 5;
                            }
                            _16288 = _16289;
                            _16286 = _13991 ? _13969 : _13990;
                        }
                        if (_16286 <= 0.0)
                        {
                            _16312 = 1.0;
                            break;
                        }
                        float2 _14028 = float2(dot(_13963, _1261[_16288]), dot(_13963, _1270[_16288])) / float2(_16286 * _594._m24.z);
                        float _14035 = _594._m28[_13924].z + (_594._m28[_13924].w / _16286);
                        if (_14035 > 1.0)
                        {
                            _16312 = 1.0;
                            break;
                        }
                        float2 _14053 = _594._m28[_13924].xy + (float2(float(spvSMod(_16288, 3)), float(_16288 / 3)) * _594._m24.xy);
                        float2 _14293 = _594._m22.xy * 0.5;
                        float2 _14298 = _14053 + (float2(0.5 + (0.5 * _14028.x), 0.5 - (0.5 * _14028.y)) * _594._m24.xy);
                        float4 _14311 = float4(_14053 + _14293, (_14053 + _594._m24.xy) - _14293);
                        float _16300;
                        do
                        {
                            int _14337 = int(_594._m22.z);
                            if (_14337 <= 0)
                            {
                                _16300 = spvDepthCast(_612).sample_compare(_612Smplr, float3(fast::clamp(_14298, _14311.xy, _14311.zw), _14035).xy, _14035);
                                break;
                            }
                            float2 _14360 = (_14298 / _594._m22.xy) + float2(0.5);
                            float2 _14361 = floor(_14360);
                            float2 _14366 = _14360 - _14361;
                            float2 _14369 = _14361 - float2(0.5);
                            bool _14373 = _14337 == 1;
                            if (_14373)
                            {
                                float2 _14376 = _14366 * 2.0;
                                _14321[0] = float2(3.0) - _14376;
                                _14321[1] = float2(1.0) + _14376;
                                _14322[0] = ((float2(2.0) - _14366) / _14321[0]) - float2(1.0);
                                _14322[1] = (_14366 / _14321[1]) + float2(1.0);
                            }
                            else
                            {
                                float2 _14403 = _14366 * 3.0;
                                _14321[0] = float2(4.0) - _14403;
                                _14321[1] = float2(7.0);
                                _14321[2] = float2(1.0) + _14403;
                                _14322[0] = ((float2(3.0) - (_14366 * 2.0)) / _14321[0]) - float2(2.0);
                                _14322[1] = (float2(3.0) + _14366) / _14321[1];
                                _14322[2] = (_14366 / _14321[2]) + float2(2.0);
                            }
                            int _16986 = _14373 ? 2 : 3;
                            int _16290;
                            float _16293;
                            _16293 = 0.0;
                            _16290 = 0;
                            float _16299;
                            for (; _16290 < _16986; _16293 = _16299, _16290++)
                            {
                                _16299 = _16293;
                                for (int _16296 = 0; _16296 < _16986; )
                                {
                                    _16299 += ((_14321[_16296].x * _14321[_16290].y) * spvDepthCast(_612).sample_compare(_612Smplr, float3(fast::clamp(_594._m22.xy * (_14369 + float2(_14322[_16296].x, _14322[_16290].y)), _14311.xy, _14311.zw), _14035).xy, _14035));
                                    _16296++;
                                    continue;
                                }
                            }
                            _16300 = _16293 * (_14373 ? 0.0625 : 0.0069444444961845874786376953125);
                            break;
                        } while(false);
                        _16312 = _16300;
                        break;
                    } while(false);
                    _16403 = _13784 * _16312;
                }
                else
                {
                    _16403 = _13784;
                }
                float3 _4121 = fast::normalize(_13753 + _3575);
                float _4126 = fast::clamp(dot(_15944, _13753), 0.0, 1.0);
                float _4131 = fast::clamp(dot(_15944, _4121), 0.0, 1.0);
                float3 _14508 = _3811 + (_9091 * powr(1.0 - fast::clamp(dot(_3575, _4121), 0.0, 1.0), 5.0));
                float _14522 = ((_4131 * _4131) * _9106) + 1.0;
                _4169 = _16405 + (((((float3(1.0) - _14508) * _3805) + ((_14508 * ((_9101 / ((3.1415927410125732421875 * _14522) * _14522)) * (0.5 / fast::max((_4126 * _9132) + (_15972 * sqrt(((_4126 * _4126) * _9128) + _9101)), 9.9999997473787516355514526367188e-06)))) * 3.1415927410125732421875)) * _4126) * _16403);
            }
            _16468 = _16405;
        }
        else
        {
            _16468 = _4069;
        }
        _16535 = _16118;
        _16465 = _16468;
    }
    float _4195 = -length(_3574);
    float _16590;
    if (_594._m9.w != 0.0)
    {
        float _4219 = _594._m9.w * (in.m_3056 - _594._m6.xyz).y;
        float _16533;
        if (abs(_4219) < 9.9999997473787516355514526367188e-05)
        {
            _16533 = 1.0 - (0.5 * _4219);
        }
        else
        {
            _16533 = (1.0 - exp(fast::min(-_4219, 60.0))) / _4219;
        }
        _16590 = 1.0 - exp((_4195 * (_594._m7.w * exp(fast::min((-_594._m9.w) * (_594._m6.y - _594._m6.w), 30.0)))) * _16533);
    }
    else
    {
        _16590 = 1.0 - exp(_4195 * _594._m7.w);
    }
    bool _4265 = _594._m34.z > 0.5;
    float3 _16586;
    if (_4265)
    {
        _16586 = _16535 * _16224;
    }
    else
    {
        _16586 = mix(_16465, _15941, float3(_3535._m1.y));
    }
    float3 _4278 = mix(_16586, _594._m7.xyz, float3(_4265 ? 0.0 : _16590));
    float3 _16591;
    if (_594._m33.w > 0.5)
    {
        _16591 = _4278 / (float3(1.0) + _4278);
    }
    else
    {
        _16591 = _4278;
    }
    out.m_4290 = float4(_16591, in.m_3438.w);
    float2 _16694;
    do
    {
        if (in.m_4300.w <= 0.0)
        {
            _16694 = float2(0.0);
            break;
        }
        _16694 = ((in.m_4300.xy / float2(in.m_4300.w)) - (in.m_4299.xy / float2(in.m_4299.w))) * float2(0.5, -0.5);
        break;
    } while(false);
    _4298 = _16694;
    return out;
}

