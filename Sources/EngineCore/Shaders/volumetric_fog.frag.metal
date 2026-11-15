// Generated from volumetric_fog.frag by Scripts/compile-shaders.sh — do not edit.
// Edit the GLSL and rerun the script (needs glslc and spirv-cross).
// spirv-fnv1a64: 4d9d5b2d6d7a13d9
// glsl-fnv1a64: fa56cfd039d94239

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

struct _45
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

struct _502
{
    uint4 _m0[1024];
};

struct _537
{
    uint4 _m0[1024];
};

struct _557
{
    float4 _m0[1024];
};

struct _592
{
    float4 _m0[1024];
};

struct _600
{
    float4 _m0[1024];
};

struct _690
{
    float4x4 _m0;
    float4 _m1;
    float4 _m2;
};

struct fragment_main_out
{
    float4 m_878 [[color(0)]];
};

fragment fragment_main_out fragment_main(constant _557& _559 [[buffer(3)]], constant _592& _594 [[buffer(4)]], constant _600& _602 [[buffer(5)]], constant _502& _504 [[buffer(6)]], constant _537& _539 [[buffer(7)]], constant _45& _47 [[buffer(15)]], constant _690& _692 [[buffer(16)]], texture2d<float> _647 [[texture(1)]], texture2d<float> _656 [[texture(2)]], texture2d<float> _199 [[texture(3)]], sampler _203 [[sampler(1)]], float4 gl_FragCoord [[position]])
{
    fragment_main_out out = {};
    int2 _645 = int2(gl_FragCoord.xy);
    float4 _662 = _656.read(uint2(_645), 0);
    float _663 = _662.x;
    float2 _673 = float2(_645);
    float2 _680 = (((_673 + float2(0.5)) / float2(int2(_647.get_width(), _647.get_height()))) * 2.0) - float2(1.0);
    float _683 = -_680.y;
    float _697 = _680.x;
    float4 _700 = _692._m0 * float4(_697, _683, 0.5, 1.0);
    float3 _710 = fast::normalize((_700.xyz / float3(_700.w)) - _47._m6.xyz);
    bool _1628;
    if (_692._m2.x > 0.5)
    {
        _1628 = _663 <= 0.0;
    }
    else
    {
        _1628 = _663 >= 1.0;
    }
    float _1629;
    if (!_1628)
    {
        float4 _743 = _692._m0 * float4(_697, _683, _663, 1.0);
        _1629 = fast::min(length((_743.xyz / float3(_743.w)) - _47._m6.xyz), _692._m1.z);
    }
    else
    {
        _1629 = _692._m1.z;
    }
    int _758 = int(_692._m1.w);
    float _763 = _1629 / float(_758);
    float _774 = fract(52.98291778564453125 * fract(dot(_673, float2(0.067110560834407806396484375, 0.005837149918079376220703125))));
    float _910 = _692._m1.y * _692._m1.y;
    float3 _794 = (_47._m5.xyz * _47._m4.w) * ((1.0 - _910) / powr(fast::max((1.0 + _910) - ((2.0 * _692._m1.y) * dot(_710, fast::normalize(_47._m4.xyz))), 9.9999997473787516355514526367188e-05), 1.5));
    bool _798 = _47._m5.w > 0.5;
    bool _802 = _692._m2.y > 0.5;
    bool _808;
    if (_802)
    {
        _808 = _47._m13.w > 0.5;
    }
    else
    {
        _808 = _802;
    }
    float3 _1631;
    _1631 = float3(0.0);
    float _847;
    float3 _874;
    spvUnsafeArray<float, 4> _1054;
    spvUnsafeArray<float, 4> _1216;
    int _1630 = 0;
    float _1634 = 0.0;
    for (; _1630 < _758; _1634 = _847, _1631 = _874, _1630++)
    {
        float3 _830 = _47._m6.xyz + (_710 * ((float(_1630) + _774) * _763));
        float _1632;
        if (_47._m9.w == 0.0)
        {
            _1632 = _47._m7.w;
        }
        else
        {
            _1632 = _47._m7.w * exp(fast::min((-_47._m9.w) * (_830.y - _47._m6.w), 30.0));
        }
        float _837 = _1632 * _763;
        _847 = _1634 + _837;
        float _1649;
        if (_798)
        {
            float _1648;
            do
            {
                int _968 = int(_47._m21.x);
                float _976 = dot(_47._m20.xyz, _830) + _47._m20.w;
                int _1635;
                _1635 = 0;
                for (;;)
                {
                    bool _982 = _1635 < (_968 - 1);
                    bool _990;
                    if (_982)
                    {
                        _990 = _976 > _47._m16[_1635];
                    }
                    else
                    {
                        _990 = _982;
                    }
                    if (_990)
                    {
                        _1635++;
                        continue;
                    }
                    else
                    {
                        break;
                    }
                }
                if (_976 > _47._m16[_1635])
                {
                    _1648 = 1.0;
                    break;
                }
                float4 _1065;
                float _1638;
                do
                {
                    _1065 = float4(_830, 1.0);
                    float4 _1066 = _47._m14[_1635] * _1065;
                    float _1069 = _1066.x;
                    bool _1070 = _1069 < 0.0;
                    bool _1077;
                    if (!_1070)
                    {
                        _1077 = _1069 > 1.0;
                    }
                    else
                    {
                        _1077 = _1070;
                    }
                    bool _1084;
                    if (!_1077)
                    {
                        _1084 = _1066.y < 0.0;
                    }
                    else
                    {
                        _1084 = _1077;
                    }
                    bool _1091;
                    if (!_1084)
                    {
                        _1091 = _1066.y > 1.0;
                    }
                    else
                    {
                        _1091 = _1084;
                    }
                    if (_1091)
                    {
                        _1638 = 1.0;
                        break;
                    }
                    float2 _1098 = float2(1.0) / _47._m22.xy;
                    float2 _1109 = float2(float(_1635 & 1), float(_1635 >> 1)) * _47._m23.xy;
                    int2 _1115 = int2((_1109 * _1098) + float2(0.5));
                    int2 _1127 = int2(((_1109 + _47._m23.xy) * _1098) + float2(0.5)) - int2(1);
                    float _1134 = fast::min(_1066.z, 1.0) - _47._m19[_1635];
                    float2 _1146 = ((_1109 + (_1066.xy * _47._m23.xy)) * _1098) - float2(0.5);
                    float2 _1148 = floor(_1146);
                    float2 _1151 = _1146 - _1148;
                    for (int _1637 = 0; _1637 < 4; )
                    {
                        _1054[_1637] = float(_1134 <= _199.read(uint2(clamp(int2(_1148) + int2(_1637 & 1, _1637 >> 1), _1115, _1127)), 0).x);
                        _1637++;
                        continue;
                    }
                    float _1189 = _1151.x;
                    _1638 = mix(mix(_1054[0], _1054[1], _1189), mix(_1054[2], _1054[3], _1189), _1151.y);
                    break;
                } while(false);
                float _1647;
                if (_976 > _47._m17[_1635])
                {
                    int _1024 = _1635 + 1;
                    float _1646;
                    if (_1024 < _968)
                    {
                        float _1645;
                        do
                        {
                            float4 _1228 = _47._m14[_1024] * _1065;
                            float _1231 = _1228.x;
                            bool _1232 = _1231 < 0.0;
                            bool _1239;
                            if (!_1232)
                            {
                                _1239 = _1231 > 1.0;
                            }
                            else
                            {
                                _1239 = _1232;
                            }
                            bool _1246;
                            if (!_1239)
                            {
                                _1246 = _1228.y < 0.0;
                            }
                            else
                            {
                                _1246 = _1239;
                            }
                            bool _1253;
                            if (!_1246)
                            {
                                _1253 = _1228.y > 1.0;
                            }
                            else
                            {
                                _1253 = _1246;
                            }
                            if (_1253)
                            {
                                _1645 = 1.0;
                                break;
                            }
                            float2 _1260 = float2(1.0) / _47._m22.xy;
                            float2 _1271 = float2(float(_1024 & 1), float(_1024 >> 1)) * _47._m23.xy;
                            int2 _1277 = int2((_1271 * _1260) + float2(0.5));
                            int2 _1289 = int2(((_1271 + _47._m23.xy) * _1260) + float2(0.5)) - int2(1);
                            float _1296 = fast::min(_1228.z, 1.0) - _47._m19[_1024];
                            float2 _1308 = ((_1271 + (_1228.xy * _47._m23.xy)) * _1260) - float2(0.5);
                            float2 _1310 = floor(_1308);
                            float2 _1313 = _1308 - _1310;
                            for (int _1644 = 0; _1644 < 4; )
                            {
                                _1216[_1644] = float(_1296 <= _199.read(uint2(clamp(int2(_1310) + int2(_1644 & 1, _1644 >> 1), _1277, _1289)), 0).x);
                                _1644++;
                                continue;
                            }
                            float _1351 = _1313.x;
                            _1645 = mix(mix(_1216[0], _1216[1], _1351), mix(_1216[2], _1216[3], _1351), _1313.y);
                            break;
                        } while(false);
                        _1646 = _1645;
                    }
                    else
                    {
                        _1646 = 1.0;
                    }
                    _1647 = mix(_1638, _1646, (_976 - _47._m17[_1635]) / (_47._m16[_1635] - _47._m17[_1635]));
                }
                else
                {
                    _1647 = _1638;
                }
                _1648 = _1647;
                break;
            } while(false);
            _1649 = _1648;
        }
        else
        {
            _1649 = 1.0;
        }
        float3 _859 = _794 * _1649;
        float3 _1658;
        if (_808)
        {
            float3 _1652;
            do
            {
                float4 _1399 = _47._m0 * float4(_830, 1.0);
                float _1401 = _1399.w;
                if (_1401 <= 0.0)
                {
                    _1652 = float3(0.0);
                    break;
                }
                float _1419 = ((_1399.x / _1401) * 0.5) + 0.5;
                float _1426 = 0.5 - ((_1399.y / _1401) * 0.5);
                bool _1430 = _1419 < 0.0;
                bool _1437;
                if (!_1430)
                {
                    _1437 = _1419 >= 1.0;
                }
                else
                {
                    _1437 = _1430;
                }
                bool _1444;
                if (!_1437)
                {
                    _1444 = _1426 < 0.0;
                }
                else
                {
                    _1444 = _1437;
                }
                bool _1451;
                if (!_1444)
                {
                    _1451 = _1426 >= 1.0;
                }
                else
                {
                    _1451 = _1444;
                }
                if (_1451)
                {
                    _1652 = float3(0.0);
                    break;
                }
                float2 _1465 = fast::clamp(floor(float2(_1419, _1426) * _47._m13.xy), float2(0.0), _47._m13.xy - float2(1.0));
                uint _1493 = uint((((fast::clamp(floor((log2(fast::max(dot(_47._m11.xyz, _830) + _47._m11.w, 9.9999999747524270787835121154785e-07)) * _47._m12.z) + _47._m12.w), 0.0, _47._m13.z - 1.0) * _47._m13.y) + _1465.y) * _47._m13.x) + _1465.x);
                uint _1495 = _1493 >> uint(2);
                uint _1497 = _1493 & 3u;
                uint _1501 = _504._m0[_1495][_1497] & 65535u;
                uint _1503 = _504._m0[_1495][_1497] >> uint(16);
                float3 _1651;
                _1651 = float3(0.0);
                for (uint _1650 = _1501; _1650 < (_1501 + _1503); )
                {
                    uint _1514 = _1650 / 3u;
                    uint _1527 = (_539._m0[_1514 >> uint(2)][_1514 & 3u] >> ((_1650 - (_1514 * 3u)) * 10u)) & 1023u;
                    float3 _1534 = _559._m0[_1527].xyz - _830;
                    float _1537 = dot(_1534, _1534);
                    float _1541 = _1537 * _559._m0[_1527].w;
                    float _1546 = fast::clamp(1.0 - (_1541 * _1541), 0.0, 1.0);
                    float _1569 = fast::clamp((dot(-(_1534 * rsqrt(fast::max(_1537, 9.9999999392252902907785028219223e-09))), _602._m0[_1527].xyz) * _594._m0[_1527].w) + _602._m0[_1527].w, 0.0, 1.0);
                    _1651 += (_594._m0[_1527].xyz * ((((_1546 * _1546) * _1569) * _1569) / fast::max(_1537, 0.25)));
                    _1650++;
                    continue;
                }
                _1652 = _1651;
                break;
            } while(false);
            _1658 = _859 + _1652;
        }
        else
        {
            _1658 = _859;
        }
        _874 = _1631 + (_1658 * (_837 * exp(-(_1634 + (0.5 * _837)))));
    }
    out.m_878 = float4(_647.read(uint2(_645), 0).xyz + (_1631 * _692._m1.x), 1.0);
    return out;
}

