// Generated from mesh.frag by Scripts/compile-shaders.sh — do not edit.
// Edit the GLSL and rerun the script (needs glslc and spirv-cross).
// spirv-fnv1a64: 6166d260c8983685
// glsl-fnv1a64: 8ca1a5e24f97303a

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

struct _191
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
};

struct _1529
{
    float4 _m0;
    float4 _m1;
    float4 _m2;
    float4 _m3;
    float4 _m4;
    float4 _m5;
    float4 _m6;
};

struct _1682
{
    float4 _m0[1024];
};

struct _1717
{
    float4 _m0[1024];
};

struct _1725
{
    float4 _m0[1024];
};

struct _1820
{
    uint4 _m0[1024];
};

struct _1841
{
    uint4 _m0[1024];
};

constant spvUnsafeArray<float3, 4> _567 = spvUnsafeArray<float3, 4>({ float3(1.0, 0.449999988079071044921875, 0.449999988079071044921875), float3(0.449999988079071044921875, 1.0, 0.449999988079071044921875), float3(0.5, 0.60000002384185791015625, 1.0), float3(1.0, 1.0, 0.4000000059604644775390625) });
constant spvUnsafeArray<float3, 6> _871 = spvUnsafeArray<float3, 6>({ float3(0.0, 0.0, 1.0), float3(0.0, 0.0, -1.0), float3(-1.0, 0.0, 0.0), float3(-1.0, 0.0, 0.0), float3(-1.0, 0.0, 0.0), float3(1.0, 0.0, 0.0) });
constant spvUnsafeArray<float3, 6> _880 = spvUnsafeArray<float3, 6>({ float3(0.0, 1.0, 0.0), float3(0.0, 1.0, 0.0), float3(0.0, 0.0, -1.0), float3(0.0, 0.0, 1.0), float3(0.0, 1.0, 0.0), float3(0.0, 1.0, 0.0) });
constant spvUnsafeArray<int4, 6> _1290 = spvUnsafeArray<int4, 6>({ int4(0, 0, 512, 256), int4(0, 256, 256, 128), int4(256, 256, 128, 64), int4(384, 256, 64, 32), int4(448, 256, 32, 16), int4(480, 256, 16, 8) });

struct fragment_main_out
{
    float4 m_2922 [[color(0)]];
    float2 m_2930 [[color(1)]];
};

struct fragment_main_in
{
    float3 m_1691 [[user(locn0)]];
    float3 m_1601 [[user(locn1)]];
    float2 m_2060 [[user(locn2)]];
    float4 m_2083 [[user(locn3)]];
    float4 m_2302 [[user(locn5)]];
    float4 m_2931 [[user(locn6)]];
    float4 m_2932 [[user(locn7)]];
    float4 m_1607 [[user(locn8)]];
};

fragment fragment_main_out fragment_main(fragment_main_in in [[stage_in]], constant _1529& _1531 [[buffer(2)]], constant _1682& _1684 [[buffer(3)]], constant _1717& _1719 [[buffer(4)]], constant _1725& _1727 [[buffer(5)]], constant _1820& _1822 [[buffer(6)]], constant _1841& _1843 [[buffer(7)]], constant _191& _193 [[buffer(15)]], texture2d<float> _213 [[texture(0)]], texture2d<float> _2076 [[texture(1)]], texture2d<float> _2506 [[texture(2)]], texture2d<float> _2192 [[texture(3)]], texture2d<float> _2007 [[texture(4)]], texture2d<float> _2812 [[texture(5)]], texture2d<float> _1228 [[texture(6)]], texture2d<float> _1334 [[texture(7)]], sampler _213Smplr [[sampler(0)]], sampler _1230 [[sampler(1)]], sampler _1336 [[sampler(7)]], float4 gl_FragCoord [[position]], bool gl_FrontFacing [[front_facing]])
{
    fragment_main_out out = {};
    float2 _2074 = float2(dot(_1531._m2.xy, in.m_2060) + _1531._m2.z, dot(_1531._m3.xy, in.m_2060) + _1531._m3.z);
    float4 _2081 = _2076.sample(_1230, _2074);
    float3 _2091 = _2081.xyz;
    float3 _2092 = (in.m_2083.xyz * _1531._m0.xyz) * _2091;
    float3 _7133;
    if (_1531._m1.x > 0.5)
    {
        float2 _2113 = floor(in.m_1691.xz * float2(0.5));
        _7133 = _2092 * ((mod(abs(_2113.x + _2113.y), 2.0) < 0.5) ? 1.0 : 0.75);
    }
    else
    {
        _7133 = _2092;
    }
    float3 _7227;
    float _7257;
    float2 _7289;
    if (_1531._m3.w > 0.5)
    {
        float3 _3033;
        float2 _3040;
        float _7131;
        do
        {
            float3 _3004 = float4(_1531._m2.w, _1531._m3.w, 0.0, 0.0).xyy;
            float3 _3007 = floor(_3004 * float3(1.52587890625e-05));
            float3 _3012 = _3004 - (_3007 * 65536.0);
            float3 _3015 = floor(_3012 * float3(0.00390625));
            float3 _3023 = _3012 - (_3015 * 256.0);
            _3033 = (float3(_3023.x, _3015.x, _3007.x) * float3(0.0039215688593685626983642578125)) * 2.0;
            _3040 = float2(_3023.y, _3015.y) * float2(0.0039215688593685626983642578125);
            float _3043 = _3007.y - 128.0;
            float _3049 = floor(_3043 * 0.03125) * 0.3333333432674407958984375;
            float3 _3055 = fast::normalize(in.m_1601);
            float _3059 = dot(_3055, in.m_1607.xyz);
            float _3071 = (_3059 / fast::max(length(in.m_1607.xyz - (_3055 * _3059)), 9.9999999747524270787835121154785e-07)) * 25.5;
            if (((-24.0) + _3071) < (-2.0))
            {
                _7131 = 0.0;
                break;
            }
            float2 _3079 = _2074 * (4.0 * exp2(mod(_3043, 32.0) * 0.3333333432674407958984375));
            float2 _3116 = floor(_3079);
            float2 _3119 = _3079 - _3116;
            float2 _3127 = (_3119 * _3119) * (float2(3.0) - (_3119 * 2.0));
            uint2 _3155 = uint2(int2(_3116) + int2(65536));
            uint _3164 = ((_3155.x * 1597334677u) ^ (_3155.y * 3812015801u)) * 1597334677u;
            uint2 _3180 = uint2(int2(_3116 + float2(1.0, 0.0)) + int2(65536));
            uint _3189 = ((_3180.x * 1597334677u) ^ (_3180.y * 3812015801u)) * 1597334677u;
            float _3134 = _3127.x;
            uint2 _3205 = uint2(int2(_3116 + float2(0.0, 1.0)) + int2(65536));
            uint _3214 = ((_3205.x * 1597334677u) ^ (_3205.y * 3812015801u)) * 1597334677u;
            uint2 _3230 = uint2(int2(_3116 + float2(1.0)) + int2(65536));
            uint _3239 = ((_3230.x * 1597334677u) ^ (_3230.y * 3812015801u)) * 1597334677u;
            float2 _3085 = (_3079 * 2.7000000476837158203125) + float2(17.299999237060546875, 5.099999904632568359375);
            float2 _3258 = floor(_3085);
            float2 _3261 = _3085 - _3258;
            float2 _3269 = (_3261 * _3261) * (float2(3.0) - (_3261 * 2.0));
            uint2 _3297 = uint2(int2(_3258) + int2(65536));
            uint _3306 = ((_3297.x * 1597334677u) ^ (_3297.y * 3812015801u)) * 1597334677u;
            uint2 _3322 = uint2(int2(_3258 + float2(1.0, 0.0)) + int2(65536));
            uint _3331 = ((_3322.x * 1597334677u) ^ (_3322.y * 3812015801u)) * 1597334677u;
            float _3276 = _3269.x;
            uint2 _3347 = uint2(int2(_3258 + float2(0.0, 1.0)) + int2(65536));
            uint _3356 = ((_3347.x * 1597334677u) ^ (_3347.y * 3812015801u)) * 1597334677u;
            uint2 _3372 = uint2(int2(_3258 + float2(1.0)) + int2(65536));
            uint _3381 = ((_3372.x * 1597334677u) ^ (_3372.y * 3812015801u)) * 1597334677u;
            float _3090 = mix(0.449999988079071044921875, 0.0500000007450580596923828125, _3049);
            float _3098 = (_3071 + (-24.450000762939453125)) + ((((mix(mix(float((_3164 ^ (_3164 >> uint(16))) & 65535u) * 1.525902189314365386962890625e-05, float((_3189 ^ (_3189 >> uint(16))) & 65535u) * 1.525902189314365386962890625e-05, _3134), mix(float((_3214 ^ (_3214 >> uint(16))) & 65535u) * 1.525902189314365386962890625e-05, float((_3239 ^ (_3239 >> uint(16))) & 65535u) * 1.525902189314365386962890625e-05, _3134), _3127.y) * 0.64999997615814208984375) + (mix(mix(float((_3306 ^ (_3306 >> uint(16))) & 65535u) * 1.525902189314365386962890625e-05, float((_3331 ^ (_3331 >> uint(16))) & 65535u) * 1.525902189314365386962890625e-05, _3276), mix(float((_3356 ^ (_3356 >> uint(16))) & 65535u) * 1.525902189314365386962890625e-05, float((_3381 ^ (_3381 >> uint(16))) & 65535u) * 1.525902189314365386962890625e-05, _3276), _3269.y) * 0.3499999940395355224609375)) - 0.5) * mix(0.800000011920928955078125, 2.2000000476837158203125, _3049));
            _7131 = smoothstep(-_3090, _3090, _3098);
            break;
        } while(false);
        _7289 = _3040;
        _7257 = _7131;
        _7227 = mix(_7133, (in.m_2083.xyz * _3033) * mix(float3(1.0), _2091 * 2.0, float3(0.5)), float3(_7131));
    }
    else
    {
        _7289 = float2(0.0);
        _7257 = 0.0;
        _7227 = _7133;
    }
    float3 _2157 = fast::normalize(in.m_1601);
    float3 _7141;
    if (_1531._m6.y > 0.5)
    {
        float3 _2172 = in.m_1607.xyz - (_2157 * dot(_2157, in.m_1607.xyz));
        float3 _7142;
        if (dot(_2172, _2172) > 9.9999999600419720025001879548654e-13)
        {
            float3 _2181 = fast::normalize(_2172);
            float4 _2197 = _2192.sample(_1230, _2074);
            float3 _7135;
            if (_1531._m6.z > 0.5)
            {
                float2 _7134;
                if (_1531._m6.z > 1.5)
                {
                    _7134 = _2197.xw;
                }
                else
                {
                    _7134 = _2197.xy;
                }
                float2 _2219 = (_7134 * 2.0) - float2(1.0);
                _7135 = float3(_2219, sqrt(fast::clamp(1.0 - dot(_2219, _2219), 0.0, 1.0)));
            }
            else
            {
                _7135 = (_2197.xyz * 2.0) - float3(1.0);
            }
            float2 _2241 = _7135.xy * _1531._m4.z;
            _7142 = fast::normalize(((_2181 * _2241.x) + ((cross(_2157, _2181) * ((in.m_1607.w < 0.0) ? (-1.0) : 1.0)) * _2241.y)) + (_2157 * _7135.z));
        }
        else
        {
            _7142 = _2157;
        }
        _7141 = _7142;
    }
    else
    {
        _7141 = _2157;
    }
    bool _2265 = _1531._m5.w > 0.5;
    bool _2273;
    if (_2265)
    {
        _2273 = !gl_FrontFacing;
    }
    else
    {
        _2273 = _2265;
    }
    float3 _7325;
    if (_2273)
    {
        _7325 = -_7141;
    }
    else
    {
        _7325 = _7141;
    }
    float3 _2282 = fast::normalize(_193._m4.xyz);
    float3 _2288 = _193._m6.xyz - in.m_1691;
    float3 _2289 = fast::normalize(_2288);
    float3 _2294 = fast::normalize(_2282 + _2289);
    float3 _2300 = _2157 * (gl_FrontFacing ? 1.0 : (-1.0));
    bool _2305 = in.m_2302.x > 0.5;
    float3 _7319;
    float _7351;
    if ((_193._m5.w > 0.5) && _2305)
    {
        float _7198;
        float3 _7199;
        do
        {
            int _3410 = int(_193._m21.x);
            float _3418 = dot(_193._m20.xyz, in.m_1691) + _193._m20.w;
            int _7143;
            _7143 = 0;
            for (;;)
            {
                bool _3424 = _7143 < (_3410 - 1);
                bool _3432;
                if (_3424)
                {
                    _3432 = _3418 > _193._m16[_7143];
                }
                else
                {
                    _3432 = _3424;
                }
                if (_3432)
                {
                    _7143++;
                    continue;
                }
                else
                {
                    break;
                }
            }
            if (_3418 > _193._m16[_7143])
            {
                _7199 = float3(1.0);
                _7198 = 1.0;
                break;
            }
            float _7156;
            do
            {
                float4 _3534 = _193._m14[_7143] * float4(in.m_1691 + (_2300 * _193._m18[_7143]), 1.0);
                float _3537 = _3534.x;
                bool _3538 = _3537 < 0.0;
                bool _3545;
                if (!_3538)
                {
                    _3545 = _3537 > 1.0;
                }
                else
                {
                    _3545 = _3538;
                }
                bool _3552;
                if (!_3545)
                {
                    _3552 = _3534.y < 0.0;
                }
                else
                {
                    _3552 = _3545;
                }
                bool _3559;
                if (!_3552)
                {
                    _3559 = _3534.y > 1.0;
                }
                else
                {
                    _3559 = _3552;
                }
                if (_3559)
                {
                    _7156 = 1.0;
                    break;
                }
                float2 _3572 = float2(float(_7143 & 1), float(_7143 >> 1)) * _193._m23.xy;
                float _3579 = fast::min(_3534.z, 1.0) - _193._m19[_7143];
                float2 _3598 = _193._m22.xy * 0.5;
                float2 _3603 = _3572 + (_3534.xy * _193._m23.xy);
                float4 _3616 = float4(_3572 + _3598, (_3572 + _193._m23.xy) - _3598);
                float _7155;
                do
                {
                    int _3642 = int(_193._m22.z);
                    if (_3642 <= 0)
                    {
                        _7155 = spvDepthCast(_213).sample_compare(_213Smplr, float3(fast::clamp(_3603, _3616.xy, _3616.zw), _3579).xy, _3579);
                        break;
                    }
                    float2 _3665 = (_3603 / _193._m22.xy) + float2(0.5);
                    float2 _3666 = floor(_3665);
                    float2 _3671 = _3665 - _3666;
                    float2 _3674 = _3666 - float2(0.5);
                    bool _3678 = _3642 == 1;
                    spvUnsafeArray<float2, 3> _3626;
                    spvUnsafeArray<float2, 3> _3627;
                    if (_3678)
                    {
                        float2 _3681 = _3671 * 2.0;
                        _3626[0] = float2(3.0) - _3681;
                        _3626[1] = float2(1.0) + _3681;
                        _3627[0] = ((float2(2.0) - _3671) / _3626[0]) - float2(1.0);
                        _3627[1] = (_3671 / _3626[1]) + float2(1.0);
                    }
                    else
                    {
                        float2 _3708 = _3671 * 3.0;
                        _3626[0] = float2(4.0) - _3708;
                        _3626[1] = float2(7.0);
                        _3626[2] = float2(1.0) + _3708;
                        _3627[0] = ((float2(3.0) - (_3671 * 2.0)) / _3626[0]) - float2(2.0);
                        _3627[1] = (float2(3.0) + _3671) / _3626[1];
                        _3627[2] = (_3671 / _3626[2]) + float2(2.0);
                    }
                    int _7743 = _3678 ? 2 : 3;
                    int _7145;
                    float _7148;
                    _7148 = 0.0;
                    _7145 = 0;
                    float _7154;
                    for (; _7145 < _7743; _7148 = _7154, _7145++)
                    {
                        _7154 = _7148;
                        for (int _7151 = 0; _7151 < _7743; )
                        {
                            _7154 += ((_3626[_7151].x * _3626[_7145].y) * spvDepthCast(_213).sample_compare(_213Smplr, float3(fast::clamp(_193._m22.xy * (_3674 + float2(_3627[_7151].x, _3627[_7145].y)), _3616.xy, _3616.zw), _3579).xy, _3579));
                            _7151++;
                            continue;
                        }
                    }
                    _7155 = _7148 * (_3678 ? 0.0625 : 0.0069444444961845874786376953125);
                    break;
                } while(false);
                _7156 = _7155;
                break;
            } while(false);
            float3 _7193;
            float _7196;
            if (_3418 > _193._m17[_7143])
            {
                float _3472 = (_3418 - _193._m17[_7143]) / (_193._m16[_7143] - _193._m17[_7143]);
                int _3474 = _7143 + 1;
                float3 _7194;
                float _7197;
                if (_3474 < _3410)
                {
                    float _7176;
                    do
                    {
                        float4 _3821 = _193._m14[_3474] * float4(in.m_1691 + (_2300 * _193._m18[_3474]), 1.0);
                        float _3824 = _3821.x;
                        bool _3825 = _3824 < 0.0;
                        bool _3832;
                        if (!_3825)
                        {
                            _3832 = _3824 > 1.0;
                        }
                        else
                        {
                            _3832 = _3825;
                        }
                        bool _3839;
                        if (!_3832)
                        {
                            _3839 = _3821.y < 0.0;
                        }
                        else
                        {
                            _3839 = _3832;
                        }
                        bool _3846;
                        if (!_3839)
                        {
                            _3846 = _3821.y > 1.0;
                        }
                        else
                        {
                            _3846 = _3839;
                        }
                        if (_3846)
                        {
                            _7176 = 1.0;
                            break;
                        }
                        float2 _3859 = float2(float(_3474 & 1), float(_3474 >> 1)) * _193._m23.xy;
                        float _3866 = fast::min(_3821.z, 1.0) - _193._m19[_3474];
                        float2 _3885 = _193._m22.xy * 0.5;
                        float2 _3890 = _3859 + (_3821.xy * _193._m23.xy);
                        float4 _3903 = float4(_3859 + _3885, (_3859 + _193._m23.xy) - _3885);
                        float _7175;
                        do
                        {
                            int _3929 = int(_193._m22.z);
                            if (_3929 <= 0)
                            {
                                _7175 = spvDepthCast(_213).sample_compare(_213Smplr, float3(fast::clamp(_3890, _3903.xy, _3903.zw), _3866).xy, _3866);
                                break;
                            }
                            float2 _3952 = (_3890 / _193._m22.xy) + float2(0.5);
                            float2 _3953 = floor(_3952);
                            float2 _3958 = _3952 - _3953;
                            float2 _3961 = _3953 - float2(0.5);
                            bool _3965 = _3929 == 1;
                            spvUnsafeArray<float2, 3> _3913;
                            spvUnsafeArray<float2, 3> _3914;
                            if (_3965)
                            {
                                float2 _3968 = _3958 * 2.0;
                                _3913[0] = float2(3.0) - _3968;
                                _3913[1] = float2(1.0) + _3968;
                                _3914[0] = ((float2(2.0) - _3958) / _3913[0]) - float2(1.0);
                                _3914[1] = (_3958 / _3913[1]) + float2(1.0);
                            }
                            else
                            {
                                float2 _3995 = _3958 * 3.0;
                                _3913[0] = float2(4.0) - _3995;
                                _3913[1] = float2(7.0);
                                _3913[2] = float2(1.0) + _3995;
                                _3914[0] = ((float2(3.0) - (_3958 * 2.0)) / _3913[0]) - float2(2.0);
                                _3914[1] = (float2(3.0) + _3958) / _3913[1];
                                _3914[2] = (_3958 / _3913[2]) + float2(2.0);
                            }
                            int _7745 = _3965 ? 2 : 3;
                            int _7165;
                            float _7168;
                            _7168 = 0.0;
                            _7165 = 0;
                            float _7174;
                            for (; _7165 < _7745; _7168 = _7174, _7165++)
                            {
                                _7174 = _7168;
                                for (int _7171 = 0; _7171 < _7745; )
                                {
                                    _7174 += ((_3913[_7171].x * _3913[_7165].y) * spvDepthCast(_213).sample_compare(_213Smplr, float3(fast::clamp(_193._m22.xy * (_3961 + float2(_3914[_7171].x, _3914[_7165].y)), _3903.xy, _3903.zw), _3866).xy, _3866));
                                    _7171++;
                                    continue;
                                }
                            }
                            _7175 = _7168 * (_3965 ? 0.0625 : 0.0069444444961845874786376953125);
                            break;
                        } while(false);
                        _7176 = _7175;
                        break;
                    } while(false);
                    _7197 = mix(_7156, _7176, _3472);
                    _7194 = mix(_567[_7143], _567[_3474], float3(_3472));
                }
                else
                {
                    _7197 = mix(_7156, 1.0, _3472);
                    _7194 = _567[_7143];
                }
                _7196 = _7197;
                _7193 = _7194;
            }
            else
            {
                _7196 = _7156;
                _7193 = _567[_7143];
            }
            _7199 = select(float3(1.0), _7193, bool3(_193._m22.w > 0.5));
            _7198 = _7196;
            break;
        } while(false);
        _7351 = _7198;
        _7319 = _7227 * _7199;
    }
    else
    {
        _7351 = 1.0;
        _7319 = _7227;
    }
    float3 _2331 = _193._m5.xyz * _193._m4.w;
    bool _2335 = _1531._m6.w > 0.5;
    float _7250;
    if (_2335)
    {
        _7250 = 1.0;
    }
    else
    {
        _7250 = 1.0 + (_1531._m4.w * (_2007.sample(_1230, _2074).x - 1.0));
    }
    float _2355 = abs(in.m_1607.w);
    float _7427;
    if (_2355 > 0.0)
    {
        _7427 = _7250 * fast::min(_2355, 1.0);
    }
    else
    {
        _7427 = _7250;
    }
    float3 _7541;
    if (!_2265)
    {
        float _2371 = dot(_7325, _2282);
        float3 _7533;
        if (_193._m29.x > 0.5)
        {
            float _4146 = (_193._m29.z * _7325.x) - (_193._m29.w * _7325.z);
            float _4159 = (_193._m29.w * _7325.x) + (_193._m29.z * _7325.z);
            float _4177 = 1.09254801273345947265625 * _4146;
            spvUnsafeArray<float, 9> _6909 = spvUnsafeArray<float, 9>({ 0.2820949852466583251953125, 0.48860299587249755859375 * _7325.y, 0.48860299587249755859375 * _4159, 0.48860299587249755859375 * _4146, _4177 * _7325.y, (1.09254801273345947265625 * _7325.y) * _4159, 0.3153919875621795654296875 * (((3.0 * _4159) * _4159) - 1.0), _4177 * _4159, 0.546274006366729736328125 * ((_4146 * _4146) - (_7325.y * _7325.y)) });
            spvUnsafeArray<float, 9> _4091 = _6909;
            float3 _7532;
            _7532 = float3(0.0);
            for (int _7531 = 0; _7531 < 9; )
            {
                _7532 += (_1228.read(uint2((int2(496, 256) + int2(_7531, 0))), 0).xyz * _4091[_7531]);
                _7531++;
                continue;
            }
            _7533 = fast::max(_7532, float3(0.0)) * _193._m29.y;
        }
        else
        {
            _7533 = mix(_193._m9.xyz, _193._m8.xyz, float3((_7325.y * 0.5) + 0.5)) * _193._m8.w;
        }
        float3 _2421 = (_7319 * ((_7533 * _7427) + ((_2331 * fast::max(_2371, 0.0)) * _7351))) + ((_2331 * ((powr(fast::max(dot(_7325, _2294), 0.0), _1531._m1.w) * _1531._m1.z) * step(0.0, _2371))) * _7351);
        float3 _7542;
        if (_193._m13.w > 0.5)
        {
            float2 _4262 = fast::clamp(floor(gl_FragCoord.xy * _193._m12.xy), float2(0.0), _193._m13.xy - float2(1.0));
            uint _4290 = uint((((fast::clamp(floor((log2(fast::max(dot(_193._m11.xyz, in.m_1691) + _193._m11.w, 9.9999999747524270787835121154785e-07)) * _193._m12.z) + _193._m12.w), 0.0, _193._m13.z - 1.0) * _193._m13.y) + _4262.y) * _193._m13.x) + _4262.x);
            uint _4292 = _4290 >> uint(2);
            uint _4294 = _4290 & 3u;
            uint _4298 = _1822._m0[_4292][_4294] & 65535u;
            uint _4300 = _1822._m0[_4292][_4294] >> uint(16);
            float3 _7543;
            _7543 = _2421;
            float3 _2501;
            spvUnsafeArray<float2, 3> _4708;
            spvUnsafeArray<float2, 3> _4709;
            spvUnsafeArray<float2, 3> _4921;
            spvUnsafeArray<float2, 3> _4922;
            for (uint _7540 = _4298; _7540 < (_4298 + _4300); _7543 = _2501, _7540++)
            {
                uint _4306 = _7540 / 3u;
                uint _4319 = (_1843._m0[_4306 >> uint(2)][_4306 & 3u] >> ((_7540 - (_4306 * 3u)) * 10u)) & 1023u;
                float3 _4336 = _1684._m0[_4319].xyz - in.m_1691;
                float _4339 = dot(_4336, _4336);
                float _4343 = _4339 * _1684._m0[_4319].w;
                float _4348 = fast::clamp(1.0 - (_4343 * _4343), 0.0, 1.0);
                float3 _4353 = _4336 * rsqrt(fast::max(_4339, 9.9999999392252902907785028219223e-09));
                float _4371 = fast::clamp((dot(-_4353, _1727._m0[_4319].xyz) * _1719._m0[_4319].w) + _1727._m0[_4319].w, 0.0, 1.0);
                float3 _4384 = _1719._m0[_4319].xyz * ((((_4348 * _4348) * _4371) * _4371) / fast::max(_4339, 9.9999997473787516355514526367188e-05));
                float3 _7665;
                if (_2305)
                {
                    float _7611;
                    do
                    {
                        uint _4420 = uint(_193._m21.z);
                        if (_4319 < _4420)
                        {
                            float _4442 = _193._m26[_4319].z * fast::max((_193._m15[_4319] * float4(in.m_1691, 1.0)).w, 0.0);
                            float4 _4466 = _193._m15[_4319] * float4((in.m_1691 + (_2300 * (_4442 * _193._m25.x))) + (_4353 * (_4442 * _193._m25.y)), 1.0);
                            float _4468 = _4466.w;
                            if (_4468 <= 0.0)
                            {
                                _7611 = 1.0;
                                break;
                            }
                            float3 _4477 = _4466.xyz / float3(_4468);
                            float _4479 = _4477.x;
                            bool _4480 = _4479 < 0.0;
                            bool _4487;
                            if (!_4480)
                            {
                                _4487 = _4479 > 1.0;
                            }
                            else
                            {
                                _4487 = _4480;
                            }
                            bool _4494;
                            if (!_4487)
                            {
                                _4494 = _4477.y < 0.0;
                            }
                            else
                            {
                                _4494 = _4487;
                            }
                            bool _4501;
                            if (!_4494)
                            {
                                _4501 = _4477.y > 1.0;
                            }
                            else
                            {
                                _4501 = _4494;
                            }
                            bool _4508;
                            if (!_4501)
                            {
                                _4508 = _4477.z > 1.0;
                            }
                            else
                            {
                                _4508 = _4501;
                            }
                            if (_4508)
                            {
                                _7611 = 1.0;
                                break;
                            }
                            float _4514 = _4477.z;
                            float2 _4680 = _193._m22.xy * 0.5;
                            float2 _4685 = _193._m26[_4319].xy + (_4477.xy * _193._m23.zw);
                            float4 _4698 = float4(_193._m26[_4319].xy + _4680, (_193._m26[_4319].xy + _193._m23.zw) - _4680);
                            float _7610;
                            do
                            {
                                int _4724 = int(_193._m22.z);
                                if (_4724 <= 0)
                                {
                                    float2 _4734 = fast::clamp(_4685, _4698.xy, _4698.zw);
                                    _7610 = spvDepthCast(_213).sample_compare(_213Smplr, float3(_4734, _4514).xy, _4514);
                                    break;
                                }
                                float2 _4747 = (_4685 / _193._m22.xy) + float2(0.5);
                                float2 _4748 = floor(_4747);
                                float2 _4753 = _4747 - _4748;
                                float2 _4756 = _4748 - float2(0.5);
                                bool _4760 = _4724 == 1;
                                if (_4760)
                                {
                                    float2 _4763 = _4753 * 2.0;
                                    _4708[0] = float2(3.0) - _4763;
                                    _4708[1] = float2(1.0) + _4763;
                                    _4709[0] = ((float2(2.0) - _4753) / _4708[0]) - float2(1.0);
                                    _4709[1] = (_4753 / _4708[1]) + float2(1.0);
                                }
                                else
                                {
                                    float2 _4790 = _4753 * 3.0;
                                    _4708[0] = float2(4.0) - _4790;
                                    _4708[1] = float2(7.0);
                                    _4708[2] = float2(1.0) + _4790;
                                    _4709[0] = ((float2(3.0) - (_4753 * 2.0)) / _4708[0]) - float2(2.0);
                                    _4709[1] = (float2(3.0) + _4753) / _4708[1];
                                    _4709[2] = (_4753 / _4708[2]) + float2(2.0);
                                }
                                int _7750 = _4760 ? 2 : 3;
                                int _7600;
                                float _7603;
                                _7603 = 0.0;
                                _7600 = 0;
                                float _7609;
                                for (; _7600 < _7750; _7603 = _7609, _7600++)
                                {
                                    _7609 = _7603;
                                    for (int _7606 = 0; _7606 < _7750; )
                                    {
                                        _7609 += ((_4708[_7606].x * _4708[_7600].y) * spvDepthCast(_213).sample_compare(_213Smplr, float3(fast::clamp(_193._m22.xy * (_4756 + float2(_4709[_7606].x, _4709[_7600].y)), _4698.xy, _4698.zw), _4514).xy, _4514));
                                        _7606++;
                                        continue;
                                    }
                                }
                                _7610 = _7603 * (_4760 ? 0.0625 : 0.0069444444961845874786376953125);
                                break;
                            } while(false);
                            _7611 = _7610;
                            break;
                        }
                        uint _4524 = _4319 - _4420;
                        if (_4524 >= uint(_193._m21.w))
                        {
                            _7611 = 1.0;
                            break;
                        }
                        float _4545 = _193._m27[_4524].w * length(in.m_1691 - _193._m27[_4524].xyz);
                        float3 _4563 = ((in.m_1691 + (_2300 * (_4545 * _193._m25.x))) + (_4353 * (_4545 * _193._m25.y))) - _193._m27[_4524].xyz;
                        float3 _4565 = abs(_4563);
                        float _4567 = _4565.x;
                        float _4569 = _4565.y;
                        bool _4570 = _4567 >= _4569;
                        bool _4578;
                        if (_4570)
                        {
                            _4578 = _4567 >= _4565.z;
                        }
                        else
                        {
                            _4578 = _4570;
                        }
                        float _7585;
                        int _7587;
                        if (_4578)
                        {
                            _7587 = (_4563.x > 0.0) ? 0 : 1;
                            _7585 = _4567;
                        }
                        else
                        {
                            float _4590 = _4565.z;
                            bool _4591 = _4569 >= _4590;
                            int _7588;
                            if (_4591)
                            {
                                _7588 = (_4563.y > 0.0) ? 2 : 3;
                            }
                            else
                            {
                                _7588 = (_4563.z > 0.0) ? 4 : 5;
                            }
                            _7587 = _7588;
                            _7585 = _4591 ? _4569 : _4590;
                        }
                        if (_7585 <= 0.0)
                        {
                            _7611 = 1.0;
                            break;
                        }
                        float2 _4628 = float2(dot(_4563, _871[_7587]), dot(_4563, _880[_7587])) / float2(_7585 * _193._m24.z);
                        float _4635 = _193._m28[_4524].z + (_193._m28[_4524].w / _7585);
                        if (_4635 > 1.0)
                        {
                            _7611 = 1.0;
                            break;
                        }
                        float2 _4653 = _193._m28[_4524].xy + (float2(float(spvSMod(_7587, 3)), float(_7587 / 3)) * _193._m24.xy);
                        float2 _4893 = _193._m22.xy * 0.5;
                        float2 _4898 = _4653 + (float2(0.5 + (0.5 * _4628.x), 0.5 - (0.5 * _4628.y)) * _193._m24.xy);
                        float4 _4911 = float4(_4653 + _4893, (_4653 + _193._m24.xy) - _4893);
                        float _7599;
                        do
                        {
                            int _4937 = int(_193._m22.z);
                            if (_4937 <= 0)
                            {
                                _7599 = spvDepthCast(_213).sample_compare(_213Smplr, float3(fast::clamp(_4898, _4911.xy, _4911.zw), _4635).xy, _4635);
                                break;
                            }
                            float2 _4960 = (_4898 / _193._m22.xy) + float2(0.5);
                            float2 _4961 = floor(_4960);
                            float2 _4966 = _4960 - _4961;
                            float2 _4969 = _4961 - float2(0.5);
                            bool _4973 = _4937 == 1;
                            if (_4973)
                            {
                                float2 _4976 = _4966 * 2.0;
                                _4921[0] = float2(3.0) - _4976;
                                _4921[1] = float2(1.0) + _4976;
                                _4922[0] = ((float2(2.0) - _4966) / _4921[0]) - float2(1.0);
                                _4922[1] = (_4966 / _4921[1]) + float2(1.0);
                            }
                            else
                            {
                                float2 _5003 = _4966 * 3.0;
                                _4921[0] = float2(4.0) - _5003;
                                _4921[1] = float2(7.0);
                                _4921[2] = float2(1.0) + _5003;
                                _4922[0] = ((float2(3.0) - (_4966 * 2.0)) / _4921[0]) - float2(2.0);
                                _4922[1] = (float2(3.0) + _4966) / _4921[1];
                                _4922[2] = (_4966 / _4921[2]) + float2(2.0);
                            }
                            int _7753 = _4973 ? 2 : 3;
                            int _7589;
                            float _7592;
                            _7592 = 0.0;
                            _7589 = 0;
                            float _7598;
                            for (; _7589 < _7753; _7592 = _7598, _7589++)
                            {
                                _7598 = _7592;
                                for (int _7595 = 0; _7595 < _7753; )
                                {
                                    _7598 += ((_4921[_7595].x * _4921[_7589].y) * spvDepthCast(_213).sample_compare(_213Smplr, float3(fast::clamp(_193._m22.xy * (_4969 + float2(_4922[_7595].x, _4922[_7589].y)), _4911.xy, _4911.zw), _4635).xy, _4635));
                                    _7595++;
                                    continue;
                                }
                            }
                            _7599 = _7592 * (_4973 ? 0.0625 : 0.0069444444961845874786376953125);
                            break;
                        } while(false);
                        _7611 = _7599;
                        break;
                    } while(false);
                    _7665 = _4384 * _7611;
                }
                else
                {
                    _7665 = _4384;
                }
                float _2472 = dot(_7325, _4353);
                _2501 = _7543 + (((_7319 * fast::max(_2472, 0.0)) * _7665) + (_7665 * ((powr(fast::max(dot(_7325, fast::normalize(_4353 + _2289)), 0.0), _1531._m1.w) * _1531._m1.z) * step(0.0, _2472))));
            }
            _7542 = _7543;
        }
        else
        {
            _7542 = _2421;
        }
        _7541 = _7542;
    }
    else
    {
        float4 _2511 = _2506.sample(_1230, _2074);
        float _2518 = fast::clamp(_1531._m4.x * _2511.z, 0.0, 1.0);
        float _2526 = fast::clamp(_1531._m4.y * _2511.y, 0.04500000178813934326171875, 1.0);
        float _7315;
        float _7320;
        if (_7257 > 0.0)
        {
            _7320 = mix(_2518, _7289.y, _7257);
            _7315 = mix(_2526, fast::max(_7289.x, 0.04500000178813934326171875), _7257);
        }
        else
        {
            _7320 = _2518;
            _7315 = _2526;
        }
        float _2545 = _7315 * _7315;
        float3 _2550 = _7319 * (1.0 - _7320);
        float3 _2556 = mix(float3(0.039999999105930328369140625), _7319, float3(_7320));
        float _2561 = fast::max(dot(_7325, _2289), 9.9999997473787516355514526367188e-05);
        float _2566 = fast::clamp(dot(_7325, _2282), 0.0, 1.0);
        float _2571 = fast::clamp(dot(_7325, _2294), 0.0, 1.0);
        float3 _5105 = float3(1.0) - _2556;
        float3 _5108 = _2556 + (_5105 * powr(1.0 - fast::clamp(dot(_2289, _2294), 0.0, 1.0), 5.0));
        float _5115 = _2545 * _2545;
        float _5120 = _5115 - 1.0;
        float _5122 = ((_2571 * _2571) * _5120) + 1.0;
        float _5142 = 1.0 - _5115;
        float _5146 = sqrt(((_2561 * _2561) * _5142) + _5115);
        float3 _7371;
        float2 _7394;
        float3 _7406;
        if (_193._m29.x > 0.5)
        {
            float4 _5179 = _1334.sample(_1336, (((float2(_2561, _7315) * 31.0) + float2(0.5)) * float2(0.03125)));
            float _5238 = (_193._m29.z * _7325.x) - (_193._m29.w * _7325.z);
            float _5251 = (_193._m29.w * _7325.x) + (_193._m29.z * _7325.z);
            float _5269 = 1.09254801273345947265625 * _5238;
            spvUnsafeArray<float, 9> _6890 = spvUnsafeArray<float, 9>({ 0.2820949852466583251953125, 0.48860299587249755859375 * _7325.y, 0.48860299587249755859375 * _5251, 0.48860299587249755859375 * _5238, _5269 * _7325.y, (1.09254801273345947265625 * _7325.y) * _5251, 0.3153919875621795654296875 * (((3.0 * _5251) * _5251) - 1.0), _5269 * _5251, 0.546274006366729736328125 * ((_5238 * _5238) - (_7325.y * _7325.y)) });
            spvUnsafeArray<float, 9> _5183 = _6890;
            float3 _7353;
            _7353 = float3(0.0);
            for (int _7352 = 0; _7352 < 9; )
            {
                _7353 += (_1228.read(uint2((int2(496, 256) + int2(_7352, 0))), 0).xyz * _5183[_7352]);
                _7352++;
                continue;
            }
            float3 _2632 = reflect(-_2289, _7325);
            float _5364 = _2632.x;
            float _5369 = _2632.z;
            float2 _5401 = float2((precise::atan2((_193._m29.z * _5364) - (_193._m29.w * _5369), -((_193._m29.w * _5364) + (_193._m29.z * _5369))) * 0.15915493667125701904296875) + 0.5, acos(fast::clamp(_2632.y, -1.0, 1.0)) * 0.3183098733425140380859375);
            float _5333 = _7315 * 5.0;
            int _5336 = min(int(_5333), 4);
            float2 _5422 = (_5401 * float2(_1290[_5336].zw)) - float2(0.5);
            float2 _5424 = floor(_5422);
            float2 _5427 = _5422 - _5424;
            int _5430 = int(_5424.x);
            int _5433 = int(_5424.y);
            int _7356;
            if (_5430 < 0)
            {
                _7356 = _5430 + _1290[_5336].z;
            }
            else
            {
                _7356 = _5430;
            }
            int _7357;
            if (_7356 >= _1290[_5336].z)
            {
                _7357 = _7356 - _1290[_5336].z;
            }
            else
            {
                _7357 = _7356;
            }
            int _5453 = _7357 + 1;
            int _7754 = (_5453 == _1290[_5336].z) ? 0 : _5453;
            int _5468 = min((_5433 + 1), (_1290[_5336].w - 1));
            int _5470 = max(_5433, 0);
            float3 _5523 = float3(_5427.x);
            int _5343 = _5336 + 1;
            float2 _5555 = (_5401 * float2(_1290[_5343].zw)) - float2(0.5);
            float2 _5557 = floor(_5555);
            float2 _5560 = _5555 - _5557;
            int _5563 = int(_5557.x);
            int _5566 = int(_5557.y);
            int _7363;
            if (_5563 < 0)
            {
                _7363 = _5563 + _1290[_5343].z;
            }
            else
            {
                _7363 = _5563;
            }
            int _7364;
            if (_7363 >= _1290[_5343].z)
            {
                _7364 = _7363 - _1290[_5343].z;
            }
            else
            {
                _7364 = _7363;
            }
            int _5586 = _7364 + 1;
            int _7755 = (_5586 == _1290[_5343].z) ? 0 : _5586;
            int _5601 = min((_5566 + 1), (_1290[_5343].w - 1));
            int _5603 = max(_5566, 0);
            float3 _5656 = float3(_5560.x);
            float3 _5358 = mix(mix(mix(_1228.read(uint2((_1290[_5336].xy + int2(_7357, _5470))), 0).xyz, _1228.read(uint2((_1290[_5336].xy + int2(_7754, _5470))), 0).xyz, _5523), mix(_1228.read(uint2((_1290[_5336].xy + int2(_7357, _5468))), 0).xyz, _1228.read(uint2((_1290[_5336].xy + int2(_7754, _5468))), 0).xyz, _5523), float3(_5427.y)), mix(mix(_1228.read(uint2((_1290[_5343].xy + int2(_7364, _5603))), 0).xyz, _1228.read(uint2((_1290[_5343].xy + int2(_7755, _5603))), 0).xyz, _5656), mix(_1228.read(uint2((_1290[_5343].xy + int2(_7364, _5601))), 0).xyz, _1228.read(uint2((_1290[_5343].xy + int2(_7755, _5601))), 0).xyz, _5656), float3(_5560.y)), float3(_5333 - float(_5336))) * _193._m29.y;
            _7406 = fast::max(_7353, float3(0.0)) * _193._m29.y;
            _7394 = _5179.xy;
            _7371 = _5358;
        }
        else
        {
            float4 _5674 = (float4(-1.0, -0.0274999998509883880615234375, -0.572000026702880859375, 0.02199999988079071044921875) * _7315) + float4(1.0, 0.0425000004470348358154296875, 1.03999996185302734375, -0.039999999105930328369140625);
            float _5676 = _5674.x;
            float3 _5711 = mix(_193._m9.xyz, _193._m8.xyz, float3((_7325.y * 0.5) + 0.5)) * _193._m8.w;
            _7406 = _5711;
            _7394 = (float2(-1.03999996185302734375, 1.03999996185302734375) * ((fast::min(_5676 * _5676, exp2((-9.27999973297119140625) * _2561)) * _5676) + _5674.y)) + _5674.zw;
            _7371 = mix(mix(_193._m9.xyz, _193._m8.xyz, float3((reflect(-_2289, _7325).y * 0.5) + 0.5)) * _193._m8.w, _5711, float3(_7315));
        }
        bool _2664;
        if (_2335)
        {
            _2664 = _193._m33.z > 0.5;
        }
        else
        {
            _2664 = _2335;
        }
        float3 _7415;
        if (_2664)
        {
            float3 _7391;
            do
            {
                float _5790 = ((_193._m32.x * (1.0 - smoothstep(_193._m33.x * 0.5, _193._m33.x, abs(dot(_193._m31.xyz, in.m_1691) - _193._m31.w)))) * smoothstep(0.5, 0.89999997615814208984375, dot(_2300, _193._m31.xyz))) * (1.0 - smoothstep(_193._m32.y * 0.5, _193._m32.y, _7315));
                if (_5790 <= 0.0)
                {
                    _7391 = _7371;
                    break;
                }
                float4 _5815 = _193._m30 * float4(in.m_1691 + ((_7325 - (_193._m31.xyz * dot(_7325, _193._m31.xyz))) * _193._m32.w), 1.0);
                float2 _5828 = ((float2(_5815.x, -_5815.y) / float2(_5815.w)) * 0.5) + float2(0.5);
                float _5832 = _193._m32.z * _7315;
                float3 _7389;
                float _7390;
                _7390 = 0.0;
                _7389 = float3(0.0);
                for (int _7388 = 0; _7388 < 12; )
                {
                    float _5839 = float(_7388);
                    float _5847 = _5839 * 2.3999631404876708984375;
                    float2 _5859 = _5828 + (float2(cos(_5847) * _193._m33.y, sin(_5847)) * (sqrt((_5839 + 0.5) * 0.083333335816860198974609375) * _5832));
                    float2 _5864 = fast::min(_5859, float2(1.0) - _5859);
                    float _5870 = smoothstep(0.0, 0.039999999105930328369140625, fast::min(_5864.x, _5864.y));
                    float4 _5878 = _2007.sample(_1230, fast::clamp(_5859, float2(0.0), float2(1.0)), level(0.0));
                    float3 _5880 = _5878.xyz;
                    _7390 += (_5878.w * _5870);
                    _7389 += ((_5880 / (float3(1.0) - fast::min(_5880, float3(0.99500000476837158203125)))) * _5870);
                    _7388++;
                    continue;
                }
                _7391 = mix(_7371, (_7389 * float3(0.083333335816860198974609375)) + (_7371 * (1.0 - (_7390 * 0.083333335816860198974609375))), float3(_5790));
                break;
            } while(false);
            _7415 = _7391;
        }
        else
        {
            _7415 = _7371;
        }
        float3 _2684 = (_2556 * _7394.x) + float3(_7394.y);
        float3 _2700 = ((((((float3(1.0) - _5108) * _2550) + ((_5108 * ((_5115 / ((3.1415927410125732421875 * _5122) * _5122)) * (0.5 / fast::max((_2566 * _5146) + (_2561 * sqrt(((_2566 * _2566) * _5142) + _5115)), 9.9999997473787516355514526367188e-06)))) * 3.1415927410125732421875)) * _2566) * _2331) * _7351) + (((((float3(1.0) - _2684) * _2550) * _7406) + (_2684 * _7415)) * _7427);
        float3 _7544;
        if (_193._m13.w > 0.5)
        {
            float2 _5944 = fast::clamp(floor(gl_FragCoord.xy * _193._m12.xy), float2(0.0), _193._m13.xy - float2(1.0));
            uint _5972 = uint((((fast::clamp(floor((log2(fast::max(dot(_193._m11.xyz, in.m_1691) + _193._m11.w, 9.9999999747524270787835121154785e-07)) * _193._m12.z) + _193._m12.w), 0.0, _193._m13.z - 1.0) * _193._m13.y) + _5944.y) * _193._m13.x) + _5944.x);
            uint _5974 = _5972 >> uint(2);
            uint _5976 = _5972 & 3u;
            uint _5980 = _1822._m0[_5974][_5976] & 65535u;
            uint _5982 = _1822._m0[_5974][_5976] >> uint(16);
            float3 _7497;
            _7497 = _2700;
            float3 _2800;
            spvUnsafeArray<float2, 3> _6390;
            spvUnsafeArray<float2, 3> _6391;
            spvUnsafeArray<float2, 3> _6603;
            spvUnsafeArray<float2, 3> _6604;
            for (uint _7430 = _5980; _7430 < (_5980 + _5982); _7497 = _2800, _7430++)
            {
                uint _5988 = _7430 / 3u;
                uint _6001 = (_1843._m0[_5988 >> uint(2)][_5988 & 3u] >> ((_7430 - (_5988 * 3u)) * 10u)) & 1023u;
                float3 _6018 = _1684._m0[_6001].xyz - in.m_1691;
                float _6021 = dot(_6018, _6018);
                float _6025 = _6021 * _1684._m0[_6001].w;
                float _6030 = fast::clamp(1.0 - (_6025 * _6025), 0.0, 1.0);
                float3 _6035 = _6018 * rsqrt(fast::max(_6021, 9.9999999392252902907785028219223e-09));
                float _6053 = fast::clamp((dot(-_6035, _1727._m0[_6001].xyz) * _1719._m0[_6001].w) + _1727._m0[_6001].w, 0.0, 1.0);
                float3 _6066 = _1719._m0[_6001].xyz * ((((_6030 * _6030) * _6053) * _6053) / fast::max(_6021, 9.9999997473787516355514526367188e-05));
                float3 _7495;
                if (_2305)
                {
                    float _7457;
                    do
                    {
                        uint _6102 = uint(_193._m21.z);
                        if (_6001 < _6102)
                        {
                            float _6124 = _193._m26[_6001].z * fast::max((_193._m15[_6001] * float4(in.m_1691, 1.0)).w, 0.0);
                            float4 _6148 = _193._m15[_6001] * float4((in.m_1691 + (_2300 * (_6124 * _193._m25.x))) + (_6035 * (_6124 * _193._m25.y)), 1.0);
                            float _6150 = _6148.w;
                            if (_6150 <= 0.0)
                            {
                                _7457 = 1.0;
                                break;
                            }
                            float3 _6159 = _6148.xyz / float3(_6150);
                            float _6161 = _6159.x;
                            bool _6162 = _6161 < 0.0;
                            bool _6169;
                            if (!_6162)
                            {
                                _6169 = _6161 > 1.0;
                            }
                            else
                            {
                                _6169 = _6162;
                            }
                            bool _6176;
                            if (!_6169)
                            {
                                _6176 = _6159.y < 0.0;
                            }
                            else
                            {
                                _6176 = _6169;
                            }
                            bool _6183;
                            if (!_6176)
                            {
                                _6183 = _6159.y > 1.0;
                            }
                            else
                            {
                                _6183 = _6176;
                            }
                            bool _6190;
                            if (!_6183)
                            {
                                _6190 = _6159.z > 1.0;
                            }
                            else
                            {
                                _6190 = _6183;
                            }
                            if (_6190)
                            {
                                _7457 = 1.0;
                                break;
                            }
                            float _6196 = _6159.z;
                            float2 _6362 = _193._m22.xy * 0.5;
                            float2 _6367 = _193._m26[_6001].xy + (_6159.xy * _193._m23.zw);
                            float4 _6380 = float4(_193._m26[_6001].xy + _6362, (_193._m26[_6001].xy + _193._m23.zw) - _6362);
                            float _7456;
                            do
                            {
                                int _6406 = int(_193._m22.z);
                                if (_6406 <= 0)
                                {
                                    float2 _6416 = fast::clamp(_6367, _6380.xy, _6380.zw);
                                    _7456 = spvDepthCast(_213).sample_compare(_213Smplr, float3(_6416, _6196).xy, _6196);
                                    break;
                                }
                                float2 _6429 = (_6367 / _193._m22.xy) + float2(0.5);
                                float2 _6430 = floor(_6429);
                                float2 _6435 = _6429 - _6430;
                                float2 _6438 = _6430 - float2(0.5);
                                bool _6442 = _6406 == 1;
                                if (_6442)
                                {
                                    float2 _6445 = _6435 * 2.0;
                                    _6390[0] = float2(3.0) - _6445;
                                    _6390[1] = float2(1.0) + _6445;
                                    _6391[0] = ((float2(2.0) - _6435) / _6390[0]) - float2(1.0);
                                    _6391[1] = (_6435 / _6390[1]) + float2(1.0);
                                }
                                else
                                {
                                    float2 _6472 = _6435 * 3.0;
                                    _6390[0] = float2(4.0) - _6472;
                                    _6390[1] = float2(7.0);
                                    _6390[2] = float2(1.0) + _6472;
                                    _6391[0] = ((float2(3.0) - (_6435 * 2.0)) / _6390[0]) - float2(2.0);
                                    _6391[1] = (float2(3.0) + _6435) / _6390[1];
                                    _6391[2] = (_6435 / _6390[2]) + float2(2.0);
                                }
                                int _7757 = _6442 ? 2 : 3;
                                int _7446;
                                float _7449;
                                _7449 = 0.0;
                                _7446 = 0;
                                float _7455;
                                for (; _7446 < _7757; _7449 = _7455, _7446++)
                                {
                                    _7455 = _7449;
                                    for (int _7452 = 0; _7452 < _7757; )
                                    {
                                        _7455 += ((_6390[_7452].x * _6390[_7446].y) * spvDepthCast(_213).sample_compare(_213Smplr, float3(fast::clamp(_193._m22.xy * (_6438 + float2(_6391[_7452].x, _6391[_7446].y)), _6380.xy, _6380.zw), _6196).xy, _6196));
                                        _7452++;
                                        continue;
                                    }
                                }
                                _7456 = _7449 * (_6442 ? 0.0625 : 0.0069444444961845874786376953125);
                                break;
                            } while(false);
                            _7457 = _7456;
                            break;
                        }
                        uint _6206 = _6001 - _6102;
                        if (_6206 >= uint(_193._m21.w))
                        {
                            _7457 = 1.0;
                            break;
                        }
                        float _6227 = _193._m27[_6206].w * length(in.m_1691 - _193._m27[_6206].xyz);
                        float3 _6245 = ((in.m_1691 + (_2300 * (_6227 * _193._m25.x))) + (_6035 * (_6227 * _193._m25.y))) - _193._m27[_6206].xyz;
                        float3 _6247 = abs(_6245);
                        float _6249 = _6247.x;
                        float _6251 = _6247.y;
                        bool _6252 = _6249 >= _6251;
                        bool _6260;
                        if (_6252)
                        {
                            _6260 = _6249 >= _6247.z;
                        }
                        else
                        {
                            _6260 = _6252;
                        }
                        float _7431;
                        int _7433;
                        if (_6260)
                        {
                            _7433 = (_6245.x > 0.0) ? 0 : 1;
                            _7431 = _6249;
                        }
                        else
                        {
                            float _6272 = _6247.z;
                            bool _6273 = _6251 >= _6272;
                            int _7434;
                            if (_6273)
                            {
                                _7434 = (_6245.y > 0.0) ? 2 : 3;
                            }
                            else
                            {
                                _7434 = (_6245.z > 0.0) ? 4 : 5;
                            }
                            _7433 = _7434;
                            _7431 = _6273 ? _6251 : _6272;
                        }
                        if (_7431 <= 0.0)
                        {
                            _7457 = 1.0;
                            break;
                        }
                        float2 _6310 = float2(dot(_6245, _871[_7433]), dot(_6245, _880[_7433])) / float2(_7431 * _193._m24.z);
                        float _6317 = _193._m28[_6206].z + (_193._m28[_6206].w / _7431);
                        if (_6317 > 1.0)
                        {
                            _7457 = 1.0;
                            break;
                        }
                        float2 _6335 = _193._m28[_6206].xy + (float2(float(spvSMod(_7433, 3)), float(_7433 / 3)) * _193._m24.xy);
                        float2 _6575 = _193._m22.xy * 0.5;
                        float2 _6580 = _6335 + (float2(0.5 + (0.5 * _6310.x), 0.5 - (0.5 * _6310.y)) * _193._m24.xy);
                        float4 _6593 = float4(_6335 + _6575, (_6335 + _193._m24.xy) - _6575);
                        float _7445;
                        do
                        {
                            int _6619 = int(_193._m22.z);
                            if (_6619 <= 0)
                            {
                                _7445 = spvDepthCast(_213).sample_compare(_213Smplr, float3(fast::clamp(_6580, _6593.xy, _6593.zw), _6317).xy, _6317);
                                break;
                            }
                            float2 _6642 = (_6580 / _193._m22.xy) + float2(0.5);
                            float2 _6643 = floor(_6642);
                            float2 _6648 = _6642 - _6643;
                            float2 _6651 = _6643 - float2(0.5);
                            bool _6655 = _6619 == 1;
                            if (_6655)
                            {
                                float2 _6658 = _6648 * 2.0;
                                _6603[0] = float2(3.0) - _6658;
                                _6603[1] = float2(1.0) + _6658;
                                _6604[0] = ((float2(2.0) - _6648) / _6603[0]) - float2(1.0);
                                _6604[1] = (_6648 / _6603[1]) + float2(1.0);
                            }
                            else
                            {
                                float2 _6685 = _6648 * 3.0;
                                _6603[0] = float2(4.0) - _6685;
                                _6603[1] = float2(7.0);
                                _6603[2] = float2(1.0) + _6685;
                                _6604[0] = ((float2(3.0) - (_6648 * 2.0)) / _6603[0]) - float2(2.0);
                                _6604[1] = (float2(3.0) + _6648) / _6603[1];
                                _6604[2] = (_6648 / _6603[2]) + float2(2.0);
                            }
                            int _7760 = _6655 ? 2 : 3;
                            int _7435;
                            float _7438;
                            _7438 = 0.0;
                            _7435 = 0;
                            float _7444;
                            for (; _7435 < _7760; _7438 = _7444, _7435++)
                            {
                                _7444 = _7438;
                                for (int _7441 = 0; _7441 < _7760; )
                                {
                                    _7444 += ((_6603[_7441].x * _6603[_7435].y) * spvDepthCast(_213).sample_compare(_213Smplr, float3(fast::clamp(_193._m22.xy * (_6651 + float2(_6604[_7441].x, _6604[_7435].y)), _6593.xy, _6593.zw), _6317).xy, _6317));
                                    _7441++;
                                    continue;
                                }
                            }
                            _7445 = _7438 * (_6655 ? 0.0625 : 0.0069444444961845874786376953125);
                            break;
                        } while(false);
                        _7457 = _7445;
                        break;
                    } while(false);
                    _7495 = _6066 * _7457;
                }
                else
                {
                    _7495 = _6066;
                }
                float3 _2752 = fast::normalize(_6035 + _2289);
                float _2757 = fast::clamp(dot(_7325, _6035), 0.0, 1.0);
                float _2762 = fast::clamp(dot(_7325, _2752), 0.0, 1.0);
                float3 _6790 = _2556 + (_5105 * powr(1.0 - fast::clamp(dot(_2289, _2752), 0.0, 1.0), 5.0));
                float _6804 = ((_2762 * _2762) * _5120) + 1.0;
                _2800 = _7497 + (((((float3(1.0) - _6790) * _2550) + ((_6790 * ((_5115 / ((3.1415927410125732421875 * _6804) * _6804)) * (0.5 / fast::max((_2757 * _5146) + (_2561 * sqrt(((_2757 * _2757) * _5142) + _5115)), 9.9999997473787516355514526367188e-06)))) * 3.1415927410125732421875)) * _2757) * _7495);
            }
            _7544 = _7497;
        }
        else
        {
            _7544 = _2700;
        }
        _7541 = _7544;
    }
    float4 _2817 = _2812.sample(_1230, _2074);
    float _2835 = -length(_2288);
    float _7582;
    if (_193._m9.w != 0.0)
    {
        float _2859 = _193._m9.w * (in.m_1691 - _193._m6.xyz).y;
        float _7579;
        if (abs(_2859) < 9.9999997473787516355514526367188e-05)
        {
            _7579 = 1.0 - (0.5 * _2859);
        }
        else
        {
            _7579 = (1.0 - exp(fast::min(-_2859, 60.0))) / _2859;
        }
        _7582 = 1.0 - exp((_2835 * (_193._m7.w * exp(fast::min((-_193._m9.w) * (_193._m6.y - _193._m6.w), 30.0)))) * _7579);
    }
    else
    {
        _7582 = 1.0 - exp(_2835 * _193._m7.w);
    }
    float3 _2910 = mix(mix(_7541, _7319, float3(_1531._m1.y)) + ((_1531._m5.xyz * _2817.xyz) * (float3(1.0) + in.m_2302.yzw)), _193._m7.xyz, float3(_7582));
    float3 _7583;
    if (_193._m33.w > 0.5)
    {
        _7583 = _2910 / (float3(1.0) + _2910);
    }
    else
    {
        _7583 = _2910;
    }
    out.m_2922 = float4(_7583, (in.m_2083.w * _1531._m0.w) * _2081.w);
    float2 _7584;
    do
    {
        if (in.m_2932.w <= 0.0)
        {
            _7584 = float2(0.0);
            break;
        }
        _7584 = ((in.m_2932.xy / float2(in.m_2932.w)) - (in.m_2931.xy / float2(in.m_2931.w))) * float2(0.5, -0.5);
        break;
    } while(false);
    out.m_2930 = _7584;
    return out;
}

