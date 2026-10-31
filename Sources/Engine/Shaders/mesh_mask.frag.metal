// Generated from mesh_mask.frag by Scripts/compile-shaders.sh — do not edit.
// Edit the GLSL and rerun the script (needs glslc and spirv-cross).
// spirv-fnv1a64: 332eac5880cda37a
// glsl-fnv1a64: 4f56061c7a0a3fa1

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
    float4 m_923 [[color(0)]];
    float2 m_937 [[color(1)]];
};

struct fragment_main_in
{
    float3 m_534 [[user(locn0)]];
    float3 m_553 [[user(locn1)]];
    float2 m_465 [[user(locn2)]];
    float4 m_494 [[user(locn3)]];
    float4 m_78 [[user(locn4)]];
    float4 m_667 [[user(locn5)]];
    float4 m_938 [[user(locn6)]];
    float4 m_939 [[user(locn7)]];
    float4 m_562 [[user(locn8)]];
};

fragment fragment_main_out fragment_main(fragment_main_in in [[stage_in]], constant _458& _460 [[buffer(2)]], constant _133& _135 [[buffer(15)]], texture2d<float> _158 [[texture(0)]], texture2d<float> _483 [[texture(1)]], texture2d<float> _747 [[texture(2)]], texture2d<float> _591 [[texture(3)]], texture2d<float> _688 [[texture(4)]], texture2d<float> _896 [[texture(5)]], sampler _158Smplr [[sampler(0)]], sampler _487 [[sampler(1)]], bool gl_FrontFacing [[front_facing]])
{
    fragment_main_out out = {};
    float2 _479 = float2(dot(_460._m2.xy, in.m_465) + _460._m2.z, dot(_460._m3.xy, in.m_465) + _460._m3.z);
    float4 _492 = _483.sample(_487, _479);
    float3 _503 = (in.m_494.xyz * _460._m0.xyz) * _492.xyz;
    if ((_460._m0.w * _492.w) < _460._m6.x)
    {
        discard_fragment();
    }
    float3 _1405;
    if (_460._m1.x > 0.5)
    {
        float2 _539 = floor(in.m_534.xz * float2(0.5));
        _1405 = _503 * ((mod(abs(_539.x + _539.y), 2.0) < 0.5) ? 1.0 : 0.75);
    }
    else
    {
        _1405 = _503;
    }
    float3 _555 = fast::normalize(in.m_553);
    float3 _1382;
    if (_460._m6.y > 0.5)
    {
        float3 _571 = in.m_562.xyz - (_555 * dot(_555, in.m_562.xyz));
        float3 _1383;
        if (dot(_571, _571) > 9.9999999600419720025001879548654e-13)
        {
            float3 _580 = fast::normalize(_571);
            float3 _600 = (_591.sample(_487, _479).xyz * 2.0) - float3(1.0);
            float2 _606 = _600.xy * _460._m4.z;
            _1383 = fast::normalize(((_580 * _606.x) + ((cross(_555, _580) * ((in.m_562.w < 0.0) ? (-1.0) : 1.0)) * _606.y)) + (_555 * _600.z));
        }
        else
        {
            _1383 = _555;
        }
        _1382 = _1383;
    }
    else
    {
        _1382 = _555;
    }
    bool _631 = _460._m5.w > 0.5;
    bool _639;
    if (_631)
    {
        _639 = !gl_FrontFacing;
    }
    else
    {
        _639 = _631;
    }
    float3 _1416;
    if (_639)
    {
        _1416 = -_1382;
    }
    else
    {
        _1416 = _1382;
    }
    float3 _648 = fast::normalize(_135._m4.xyz);
    float3 _654 = _135._m6.xyz - in.m_534;
    float3 _655 = fast::normalize(_654);
    float3 _660 = fast::normalize(_648 + _655);
    bool _664 = _135._m5.w > 0.5;
    bool _671;
    if (_664)
    {
        _671 = in.m_667.x > 0.5;
    }
    else
    {
        _671 = _664;
    }
    float _1395;
    if (_671)
    {
        float _1394;
        do
        {
            float3 _982 = in.m_78.xyz / float3(in.m_78.w);
            float _986 = (_982.x * 0.5) + 0.5;
            float _990 = 0.5 - (_982.y * 0.5);
            bool _994 = _986 < 0.0;
            bool _1001;
            if (!_994)
            {
                _1001 = _986 > 1.0;
            }
            else
            {
                _1001 = _994;
            }
            bool _1008;
            if (!_1001)
            {
                _1008 = _990 < 0.0;
            }
            else
            {
                _1008 = _1001;
            }
            bool _1015;
            if (!_1008)
            {
                _1015 = _990 > 1.0;
            }
            else
            {
                _1015 = _1008;
            }
            if (_1015)
            {
                _1394 = 1.0;
                break;
            }
            float _1023 = fast::min(_982.z, 1.0) - _135._m10.y;
            int _1028 = int(_135._m10.z);
            if (_1028 <= 0)
            {
                _1394 = spvDepthCast(_158).sample_compare(_158Smplr, float3(_986, _990, _1023).xy, _1023);
                break;
            }
            float2 _1047 = (float2(_986, _990) / float2(_135._m10.x)) + float2(0.5);
            float2 _1048 = floor(_1047);
            float2 _1053 = _1047 - _1048;
            float2 _1058 = (_1048 - float2(0.5)) * _135._m10.x;
            bool _1060 = _1028 == 1;
            spvUnsafeArray<float2, 3> _967;
            spvUnsafeArray<float2, 3> _968;
            if (_1060)
            {
                float2 _1063 = _1053 * 2.0;
                _967[0] = float2(3.0) - _1063;
                _967[1] = float2(1.0) + _1063;
                _968[0] = ((float2(2.0) - _1053) / _967[0]) - float2(1.0);
                _968[1] = (_1053 / _967[1]) + float2(1.0);
            }
            else
            {
                float2 _1090 = _1053 * 3.0;
                _967[0] = float2(4.0) - _1090;
                _967[1] = float2(7.0);
                _967[2] = float2(1.0) + _1090;
                _968[0] = ((float2(3.0) - (_1053 * 2.0)) / _967[0]) - float2(2.0);
                _968[1] = (float2(3.0) + _1053) / _967[1];
                _968[2] = (_1053 / _967[2]) + float2(2.0);
            }
            int _1445 = _1060 ? 2 : 3;
            int _1384;
            float _1387;
            _1387 = 0.0;
            _1384 = 0;
            float _1393;
            for (; _1384 < _1445; _1387 = _1393, _1384++)
            {
                _1393 = _1387;
                for (int _1390 = 0; _1390 < _1445; )
                {
                    _1393 += ((_967[_1390].x * _967[_1384].y) * spvDepthCast(_158).sample_compare(_158Smplr, float3(_1058 + (float2(_968[_1390].x, _968[_1384].y) * _135._m10.x), _1023).xy, _1023));
                    _1390++;
                    continue;
                }
            }
            _1394 = _1387 * (_1060 ? 0.0625 : 0.0069444444961845874786376953125);
            break;
        } while(false);
        _1395 = _1394;
    }
    else
    {
        _1395 = 1.0;
    }
    float3 _684 = _135._m5.xyz * _135._m4.w;
    float4 _693 = _688.sample(_487, _479);
    float _697 = 1.0 + (_460._m4.w * (_693.x - 1.0));
    float3 _1420;
    if (!_631)
    {
        float _705 = dot(_1416, _648);
        _1420 = (_1405 * (((mix(_135._m9.xyz, _135._m8.xyz, float3((_1416.y * 0.5) + 0.5)) * _135._m8.w) * _697) + ((_684 * fast::max(_705, 0.0)) * _1395))) + ((_684 * ((powr(fast::max(dot(_1416, _660), 0.0), _460._m1.w) * _460._m1.z) * step(0.0, _705))) * _1395);
    }
    else
    {
        float4 _752 = _747.sample(_487, _479);
        float _759 = fast::clamp(_460._m4.x * _752.z, 0.0, 1.0);
        float _767 = fast::clamp(_460._m4.y * _752.y, 0.04500000178813934326171875, 1.0);
        float _771 = _767 * _767;
        float3 _776 = _1405 * (1.0 - _759);
        float3 _783 = mix(float3(0.039999999105930328369140625), _1405, float3(_759));
        float _789 = fast::max(dot(_1416, _655), 9.9999997473787516355514526367188e-05);
        float _794 = fast::clamp(dot(_1416, _648), 0.0, 1.0);
        float _799 = fast::clamp(dot(_1416, _660), 0.0, 1.0);
        float3 _1206 = _783 + ((float3(1.0) - _783) * powr(1.0 - fast::clamp(dot(_655, _660), 0.0, 1.0), 5.0));
        float _1213 = _771 * _771;
        float _1220 = ((_799 * _799) * (_1213 - 1.0)) + 1.0;
        float _1240 = 1.0 - _1213;
        float4 _1268 = (float4(-1.0, -0.0274999998509883880615234375, -0.572000026702880859375, 0.02199999988079071044921875) * _767) + float4(1.0, 0.0425000004470348358154296875, 1.03999996185302734375, -0.039999999105930328369140625);
        float _1270 = _1268.x;
        float2 _1288 = (float2(-1.03999996185302734375, 1.03999996185302734375) * ((fast::min(_1270 * _1270, exp2((-9.27999973297119140625) * _789)) * _1270) + _1268.y)) + _1268.zw;
        float3 _855 = (_783 * _1288.x) + float3(_1288.y);
        float3 _1305 = mix(_135._m9.xyz, _135._m8.xyz, float3((_1416.y * 0.5) + 0.5)) * _135._m8.w;
        _1420 = ((((((float3(1.0) - _1206) * _776) + ((_1206 * ((_1213 / ((3.1415927410125732421875 * _1220) * _1220)) * (0.5 / fast::max((_794 * sqrt(((_789 * _789) * _1240) + _1213)) + (_789 * sqrt(((_794 * _794) * _1240) + _1213)), 9.9999997473787516355514526367188e-06)))) * 3.1415927410125732421875)) * _794) * _684) * _1395) + (((((float3(1.0) - _855) * _776) * _1305) + (_855 * mix(mix(_135._m9.xyz, _135._m8.xyz, float3((reflect(-_655, _1416).y * 0.5) + 0.5)) * _135._m8.w, _1305, float3(_767)))) * _697);
    }
    out.m_923 = float4(mix(mix(_1420, _1405, float3(_460._m1.y)) + (_460._m5.xyz * _896.sample(_487, _479).xyz), _135._m7.xyz, float3(1.0 - exp((-length(_654)) * _135._m7.w))), in.m_494.w);
    float2 _1437;
    do
    {
        if (in.m_939.w <= 0.0)
        {
            _1437 = float2(0.0);
            break;
        }
        _1437 = ((in.m_939.xy / float2(in.m_939.w)) - (in.m_938.xy / float2(in.m_938.w))) * float2(0.5, -0.5);
        break;
    } while(false);
    out.m_937 = _1437;
    return out;
}

