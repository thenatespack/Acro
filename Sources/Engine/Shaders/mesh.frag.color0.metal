// Generated from mesh.frag by Scripts/compile-shaders.sh — do not edit.
// Edit the GLSL and rerun the script (needs glslc and spirv-cross).
// spirv-fnv1a64: 1cf42da02d9e32ff
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

struct _133
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
};

struct _458
{
    float4 _m0;
    float4 _m1;
    float4 _m2;
    float4 _m3;
    float4 _m4;
    float4 _m5;
    float4 _m6;
};

struct fragment_main_out
{
    float4 m_910 [[color(0)]];
};

struct fragment_main_in
{
    float3 m_520 [[user(locn0)]];
    float3 m_539 [[user(locn1)]];
    float2 m_465 [[user(locn2)]];
    float4 m_494 [[user(locn3)]];
    float4 m_78 [[user(locn4)]];
    float4 m_654 [[user(locn5)]];
    float4 m_925 [[user(locn6)]];
    float4 m_926 [[user(locn7)]];
    float4 m_549 [[user(locn8)]];
};

fragment fragment_main_out fragment_main(fragment_main_in in [[stage_in]], constant _458& _460 [[buffer(2)]], constant _133& _135 [[buffer(15)]], texture2d<float> _158 [[texture(0)]], texture2d<float> _483 [[texture(1)]], texture2d<float> _734 [[texture(2)]], texture2d<float> _578 [[texture(3)]], texture2d<float> _675 [[texture(4)]], texture2d<float> _883 [[texture(5)]], sampler _158Smplr [[sampler(0)]], sampler _487 [[sampler(1)]], bool gl_FrontFacing [[front_facing]])
{
    float2 _924;
    fragment_main_out out = {};
    float2 _479 = float2(dot(_460._m2.xy, in.m_465) + _460._m2.z, dot(_460._m3.xy, in.m_465) + _460._m3.z);
    float4 _492 = _483.sample(_487, _479);
    float3 _503 = (in.m_494.xyz * _460._m0.xyz) * _492.xyz;
    float3 _1391;
    if (_460._m1.x > 0.5)
    {
        float2 _525 = floor(in.m_520.xz * float2(0.5));
        _1391 = _503 * ((mod(abs(_525.x + _525.y), 2.0) < 0.5) ? 1.0 : 0.75);
    }
    else
    {
        _1391 = _503;
    }
    float3 _541 = fast::normalize(in.m_539);
    float3 _1368;
    if (_460._m6.y > 0.5)
    {
        float3 _558 = in.m_549.xyz - (_541 * dot(_541, in.m_549.xyz));
        float3 _1369;
        if (dot(_558, _558) > 9.9999999600419720025001879548654e-13)
        {
            float3 _567 = fast::normalize(_558);
            float3 _587 = (_578.sample(_487, _479).xyz * 2.0) - float3(1.0);
            float2 _593 = _587.xy * _460._m4.z;
            _1369 = fast::normalize(((_567 * _593.x) + ((cross(_541, _567) * ((in.m_549.w < 0.0) ? (-1.0) : 1.0)) * _593.y)) + (_541 * _587.z));
        }
        else
        {
            _1369 = _541;
        }
        _1368 = _1369;
    }
    else
    {
        _1368 = _541;
    }
    bool _618 = _460._m5.w > 0.5;
    bool _626;
    if (_618)
    {
        _626 = !gl_FrontFacing;
    }
    else
    {
        _626 = _618;
    }
    float3 _1402;
    if (_626)
    {
        _1402 = -_1368;
    }
    else
    {
        _1402 = _1368;
    }
    float3 _635 = fast::normalize(_135._m4.xyz);
    float3 _641 = _135._m6.xyz - in.m_520;
    float3 _642 = fast::normalize(_641);
    float3 _647 = fast::normalize(_635 + _642);
    bool _651 = _135._m5.w > 0.5;
    bool _658;
    if (_651)
    {
        _658 = in.m_654.x > 0.5;
    }
    else
    {
        _658 = _651;
    }
    float _1381;
    if (_658)
    {
        float _1380;
        do
        {
            float3 _969 = in.m_78.xyz / float3(in.m_78.w);
            float _973 = (_969.x * 0.5) + 0.5;
            float _977 = 0.5 - (_969.y * 0.5);
            bool _981 = _973 < 0.0;
            bool _988;
            if (!_981)
            {
                _988 = _973 > 1.0;
            }
            else
            {
                _988 = _981;
            }
            bool _995;
            if (!_988)
            {
                _995 = _977 < 0.0;
            }
            else
            {
                _995 = _988;
            }
            bool _1002;
            if (!_995)
            {
                _1002 = _977 > 1.0;
            }
            else
            {
                _1002 = _995;
            }
            if (_1002)
            {
                _1380 = 1.0;
                break;
            }
            float _1010 = fast::min(_969.z, 1.0) - _135._m10.y;
            int _1015 = int(_135._m10.z);
            if (_1015 <= 0)
            {
                _1380 = spvDepthCast(_158).sample_compare(_158Smplr, float3(_973, _977, _1010).xy, _1010);
                break;
            }
            float2 _1034 = (float2(_973, _977) / float2(_135._m10.x)) + float2(0.5);
            float2 _1035 = floor(_1034);
            float2 _1040 = _1034 - _1035;
            float2 _1045 = (_1035 - float2(0.5)) * _135._m10.x;
            bool _1047 = _1015 == 1;
            spvUnsafeArray<float2, 3> _954;
            spvUnsafeArray<float2, 3> _955;
            if (_1047)
            {
                float2 _1050 = _1040 * 2.0;
                _954[0] = float2(3.0) - _1050;
                _954[1] = float2(1.0) + _1050;
                _955[0] = ((float2(2.0) - _1040) / _954[0]) - float2(1.0);
                _955[1] = (_1040 / _954[1]) + float2(1.0);
            }
            else
            {
                float2 _1077 = _1040 * 3.0;
                _954[0] = float2(4.0) - _1077;
                _954[1] = float2(7.0);
                _954[2] = float2(1.0) + _1077;
                _955[0] = ((float2(3.0) - (_1040 * 2.0)) / _954[0]) - float2(2.0);
                _955[1] = (float2(3.0) + _1040) / _954[1];
                _955[2] = (_1040 / _954[2]) + float2(2.0);
            }
            int _1416 = _1047 ? 2 : 3;
            int _1370;
            float _1373;
            _1373 = 0.0;
            _1370 = 0;
            float _1379;
            for (; _1370 < _1416; _1373 = _1379, _1370++)
            {
                _1379 = _1373;
                for (int _1376 = 0; _1376 < _1416; )
                {
                    _1379 += ((_954[_1376].x * _954[_1370].y) * spvDepthCast(_158).sample_compare(_158Smplr, float3(_1045 + (float2(_955[_1376].x, _955[_1370].y) * _135._m10.x), _1010).xy, _1010));
                    _1376++;
                    continue;
                }
            }
            _1380 = _1373 * (_1047 ? 0.0625 : 0.0069444444961845874786376953125);
            break;
        } while(false);
        _1381 = _1380;
    }
    else
    {
        _1381 = 1.0;
    }
    float3 _671 = _135._m5.xyz * _135._m4.w;
    float4 _680 = _675.sample(_487, _479);
    float _684 = 1.0 + (_460._m4.w * (_680.x - 1.0));
    float3 _1406;
    if (!_618)
    {
        float _692 = dot(_1402, _635);
        _1406 = (_1391 * (((mix(_135._m9.xyz, _135._m8.xyz, float3((_1402.y * 0.5) + 0.5)) * _135._m8.w) * _684) + ((_671 * fast::max(_692, 0.0)) * _1381))) + ((_671 * ((powr(fast::max(dot(_1402, _647), 0.0), _460._m1.w) * _460._m1.z) * step(0.0, _692))) * _1381);
    }
    else
    {
        float4 _739 = _734.sample(_487, _479);
        float _746 = fast::clamp(_460._m4.x * _739.z, 0.0, 1.0);
        float _754 = fast::clamp(_460._m4.y * _739.y, 0.04500000178813934326171875, 1.0);
        float _758 = _754 * _754;
        float3 _763 = _1391 * (1.0 - _746);
        float3 _770 = mix(float3(0.039999999105930328369140625), _1391, float3(_746));
        float _776 = fast::max(dot(_1402, _642), 9.9999997473787516355514526367188e-05);
        float _781 = fast::clamp(dot(_1402, _635), 0.0, 1.0);
        float _786 = fast::clamp(dot(_1402, _647), 0.0, 1.0);
        float3 _1193 = _770 + ((float3(1.0) - _770) * powr(1.0 - fast::clamp(dot(_642, _647), 0.0, 1.0), 5.0));
        float _1200 = _758 * _758;
        float _1207 = ((_786 * _786) * (_1200 - 1.0)) + 1.0;
        float _1227 = 1.0 - _1200;
        float4 _1255 = (float4(-1.0, -0.0274999998509883880615234375, -0.572000026702880859375, 0.02199999988079071044921875) * _754) + float4(1.0, 0.0425000004470348358154296875, 1.03999996185302734375, -0.039999999105930328369140625);
        float _1257 = _1255.x;
        float2 _1275 = (float2(-1.03999996185302734375, 1.03999996185302734375) * ((fast::min(_1257 * _1257, exp2((-9.27999973297119140625) * _776)) * _1257) + _1255.y)) + _1255.zw;
        float3 _842 = (_770 * _1275.x) + float3(_1275.y);
        float3 _1292 = mix(_135._m9.xyz, _135._m8.xyz, float3((_1402.y * 0.5) + 0.5)) * _135._m8.w;
        _1406 = ((((((float3(1.0) - _1193) * _763) + ((_1193 * ((_1200 / ((3.1415927410125732421875 * _1207) * _1207)) * (0.5 / fast::max((_781 * sqrt(((_776 * _776) * _1227) + _1200)) + (_776 * sqrt(((_781 * _781) * _1227) + _1200)), 9.9999997473787516355514526367188e-06)))) * 3.1415927410125732421875)) * _781) * _671) * _1381) + (((((float3(1.0) - _842) * _763) * _1292) + (_842 * mix(mix(_135._m9.xyz, _135._m8.xyz, float3((reflect(-_642, _1402).y * 0.5) + 0.5)) * _135._m8.w, _1292, float3(_754)))) * _684);
    }
    out.m_910 = float4(mix(mix(_1406, _1391, float3(_460._m1.y)) + (_460._m5.xyz * _883.sample(_487, _479).xyz), _135._m7.xyz, float3(1.0 - exp((-length(_641)) * _135._m7.w))), (in.m_494.w * _460._m0.w) * _492.w);
    float2 _1408;
    do
    {
        if (in.m_926.w <= 0.0)
        {
            _1408 = float2(0.0);
            break;
        }
        _1408 = ((in.m_926.xy / float2(in.m_926.w)) - (in.m_925.xy / float2(in.m_925.w))) * float2(0.5, -0.5);
        break;
    } while(false);
    _924 = _1408;
    return out;
}

