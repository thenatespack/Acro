// Generated from mesh_mask.frag by Scripts/compile-shaders.sh — do not edit.
// Edit the GLSL and rerun the script (needs glslc and spirv-cross).
// spirv-fnv1a64: 21ef43b5efbe0b85
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

struct _147
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
};

struct _474
{
    float4 _m0[1024];
};

struct _510
{
    float4 _m0[1024];
};

struct _518
{
    float4 _m0[1024];
};

struct _614
{
    uint4 _m0[1024];
};

struct _637
{
    uint4 _m0[1024];
};

struct _658
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
    float4 m_1273 [[color(0)]];
    float2 m_1287 [[color(1)]];
};

struct fragment_main_in
{
    float3 m_484 [[user(locn0)]];
    float3 m_751 [[user(locn1)]];
    float2 m_665 [[user(locn2)]];
    float4 m_694 [[user(locn3)]];
    float4 m_92 [[user(locn4)]];
    float4 m_865 [[user(locn5)]];
    float4 m_1288 [[user(locn6)]];
    float4 m_1289 [[user(locn7)]];
    float4 m_760 [[user(locn8)]];
};

fragment fragment_main_out fragment_main(fragment_main_in in [[stage_in]], constant _658& _660 [[buffer(2)]], constant _474& _476 [[buffer(3)]], constant _510& _512 [[buffer(4)]], constant _518& _520 [[buffer(5)]], constant _614& _616 [[buffer(6)]], constant _637& _639 [[buffer(7)]], constant _147& _149 [[buffer(15)]], texture2d<float> _172 [[texture(0)]], texture2d<float> _683 [[texture(1)]], texture2d<float> _1012 [[texture(2)]], texture2d<float> _789 [[texture(3)]], texture2d<float> _886 [[texture(4)]], texture2d<float> _1246 [[texture(5)]], sampler _172Smplr [[sampler(0)]], sampler _687 [[sampler(1)]], float4 gl_FragCoord [[position]], bool gl_FrontFacing [[front_facing]])
{
    fragment_main_out out = {};
    float2 _679 = float2(dot(_660._m2.xy, in.m_665) + _660._m2.z, dot(_660._m3.xy, in.m_665) + _660._m3.z);
    float4 _692 = _683.sample(_687, _679);
    float3 _703 = (in.m_694.xyz * _660._m0.xyz) * _692.xyz;
    if ((_660._m0.w * _692.w) < _660._m6.x)
    {
        discard_fragment();
    }
    float3 _2138;
    if (_660._m1.x > 0.5)
    {
        float2 _737 = floor(in.m_484.xz * float2(0.5));
        _2138 = _703 * ((mod(abs(_737.x + _737.y), 2.0) < 0.5) ? 1.0 : 0.75);
    }
    else
    {
        _2138 = _703;
    }
    float3 _753 = fast::normalize(in.m_751);
    float3 _2115;
    if (_660._m6.y > 0.5)
    {
        float3 _769 = in.m_760.xyz - (_753 * dot(_753, in.m_760.xyz));
        float3 _2116;
        if (dot(_769, _769) > 9.9999999600419720025001879548654e-13)
        {
            float3 _778 = fast::normalize(_769);
            float3 _798 = (_789.sample(_687, _679).xyz * 2.0) - float3(1.0);
            float2 _804 = _798.xy * _660._m4.z;
            _2116 = fast::normalize(((_778 * _804.x) + ((cross(_753, _778) * ((in.m_760.w < 0.0) ? (-1.0) : 1.0)) * _804.y)) + (_753 * _798.z));
        }
        else
        {
            _2116 = _753;
        }
        _2115 = _2116;
    }
    else
    {
        _2115 = _753;
    }
    bool _829 = _660._m5.w > 0.5;
    bool _837;
    if (_829)
    {
        _837 = !gl_FrontFacing;
    }
    else
    {
        _837 = _829;
    }
    float3 _2149;
    if (_837)
    {
        _2149 = -_2115;
    }
    else
    {
        _2149 = _2115;
    }
    float3 _846 = fast::normalize(_149._m4.xyz);
    float3 _852 = _149._m6.xyz - in.m_484;
    float3 _853 = fast::normalize(_852);
    float3 _858 = fast::normalize(_846 + _853);
    bool _862 = _149._m5.w > 0.5;
    bool _869;
    if (_862)
    {
        _869 = in.m_865.x > 0.5;
    }
    else
    {
        _869 = _862;
    }
    float _2128;
    if (_869)
    {
        float _2127;
        do
        {
            float3 _1332 = in.m_92.xyz / float3(in.m_92.w);
            float _1336 = (_1332.x * 0.5) + 0.5;
            float _1340 = 0.5 - (_1332.y * 0.5);
            bool _1344 = _1336 < 0.0;
            bool _1351;
            if (!_1344)
            {
                _1351 = _1336 > 1.0;
            }
            else
            {
                _1351 = _1344;
            }
            bool _1358;
            if (!_1351)
            {
                _1358 = _1340 < 0.0;
            }
            else
            {
                _1358 = _1351;
            }
            bool _1365;
            if (!_1358)
            {
                _1365 = _1340 > 1.0;
            }
            else
            {
                _1365 = _1358;
            }
            if (_1365)
            {
                _2127 = 1.0;
                break;
            }
            float _1373 = fast::min(_1332.z, 1.0) - _149._m10.y;
            int _1378 = int(_149._m10.z);
            if (_1378 <= 0)
            {
                _2127 = spvDepthCast(_172).sample_compare(_172Smplr, float3(_1336, _1340, _1373).xy, _1373);
                break;
            }
            float2 _1397 = (float2(_1336, _1340) / float2(_149._m10.x)) + float2(0.5);
            float2 _1398 = floor(_1397);
            float2 _1403 = _1397 - _1398;
            float2 _1408 = (_1398 - float2(0.5)) * _149._m10.x;
            bool _1410 = _1378 == 1;
            spvUnsafeArray<float2, 3> _1317;
            spvUnsafeArray<float2, 3> _1318;
            if (_1410)
            {
                float2 _1413 = _1403 * 2.0;
                _1317[0] = float2(3.0) - _1413;
                _1317[1] = float2(1.0) + _1413;
                _1318[0] = ((float2(2.0) - _1403) / _1317[0]) - float2(1.0);
                _1318[1] = (_1403 / _1317[1]) + float2(1.0);
            }
            else
            {
                float2 _1440 = _1403 * 3.0;
                _1317[0] = float2(4.0) - _1440;
                _1317[1] = float2(7.0);
                _1317[2] = float2(1.0) + _1440;
                _1318[0] = ((float2(3.0) - (_1403 * 2.0)) / _1317[0]) - float2(2.0);
                _1318[1] = (float2(3.0) + _1403) / _1317[1];
                _1318[2] = (_1403 / _1317[2]) + float2(2.0);
            }
            int _2194 = _1410 ? 2 : 3;
            int _2117;
            float _2120;
            _2120 = 0.0;
            _2117 = 0;
            float _2126;
            for (; _2117 < _2194; _2120 = _2126, _2117++)
            {
                _2126 = _2120;
                for (int _2123 = 0; _2123 < _2194; )
                {
                    _2126 += ((_1317[_2123].x * _1317[_2117].y) * spvDepthCast(_172).sample_compare(_172Smplr, float3(_1408 + (float2(_1318[_2123].x, _1318[_2117].y) * _149._m10.x), _1373).xy, _1373));
                    _2123++;
                    continue;
                }
            }
            _2127 = _2120 * (_1410 ? 0.0625 : 0.0069444444961845874786376953125);
            break;
        } while(false);
        _2128 = _2127;
    }
    else
    {
        _2128 = 1.0;
    }
    float3 _882 = _149._m5.xyz * _149._m4.w;
    float4 _891 = _886.sample(_687, _679);
    float _895 = 1.0 + (_660._m4.w * (_891.x - 1.0));
    float3 _2157;
    if (!_829)
    {
        float _903 = dot(_2149, _846);
        float3 _942 = (_2138 * (((mix(_149._m9.xyz, _149._m8.xyz, float3((_2149.y * 0.5) + 0.5)) * _149._m8.w) * _895) + ((_882 * fast::max(_903, 0.0)) * _2128))) + ((_882 * ((powr(fast::max(dot(_2149, _858), 0.0), _660._m1.w) * _660._m1.z) * step(0.0, _903))) * _2128);
        float3 _2158;
        if (_149._m13.w > 0.5)
        {
            float2 _1572 = fast::clamp(floor(gl_FragCoord.xy * _149._m12.xy), float2(0.0), _149._m13.xy - float2(1.0));
            uint _1600 = uint((((fast::clamp(floor((log2(fast::max(dot(_149._m11.xyz, in.m_484) + _149._m11.w, 9.9999999747524270787835121154785e-07)) * _149._m12.z) + _149._m12.w), 0.0, _149._m13.z - 1.0) * _149._m13.y) + _1572.y) * _149._m13.x) + _1572.x);
            uint _1602 = _1600 >> uint(2);
            uint _1604 = _1600 & 3u;
            uint _1608 = _616._m0[_1602][_1604] & 65535u;
            uint _1610 = _616._m0[_1602][_1604] >> uint(16);
            float3 _2159;
            _2159 = _942;
            for (uint _2156 = _1608; _2156 < (_1608 + _1610); )
            {
                uint _1616 = _2156 / 3u;
                uint _1629 = (_639._m0[_1616 >> uint(2)][_1616 & 3u] >> ((_2156 - (_1616 * 3u)) * 10u)) & 1023u;
                float3 _1646 = _476._m0[_1629].xyz - in.m_484;
                float _1649 = dot(_1646, _1646);
                float _1653 = _1649 * _476._m0[_1629].w;
                float _1658 = fast::clamp(1.0 - (_1653 * _1653), 0.0, 1.0);
                float3 _1663 = _1646 * rsqrt(fast::max(_1649, 9.9999999392252902907785028219223e-09));
                float _1681 = fast::clamp((dot(-_1663, _520._m0[_1629].xyz) * _512._m0[_1629].w) + _520._m0[_1629].w, 0.0, 1.0);
                float3 _1694 = _512._m0[_1629].xyz * ((((_1658 * _1658) * _1681) * _1681) / fast::max(_1649, 9.9999997473787516355514526367188e-05));
                float _978 = dot(_2149, _1663);
                _2159 += (((_2138 * fast::max(_978, 0.0)) * _1694) + (_1694 * ((powr(fast::max(dot(_2149, fast::normalize(_1663 + _853)), 0.0), _660._m1.w) * _660._m1.z) * step(0.0, _978))));
                _2156++;
                continue;
            }
            _2158 = _2159;
        }
        else
        {
            _2158 = _942;
        }
        _2157 = _2158;
    }
    else
    {
        float4 _1017 = _1012.sample(_687, _679);
        float _1024 = fast::clamp(_660._m4.x * _1017.z, 0.0, 1.0);
        float _1032 = fast::clamp(_660._m4.y * _1017.y, 0.04500000178813934326171875, 1.0);
        float _1036 = _1032 * _1032;
        float3 _1041 = _2138 * (1.0 - _1024);
        float3 _1048 = mix(float3(0.039999999105930328369140625), _2138, float3(_1024));
        float _1053 = fast::max(dot(_2149, _853), 9.9999997473787516355514526367188e-05);
        float _1058 = fast::clamp(dot(_2149, _846), 0.0, 1.0);
        float _1063 = fast::clamp(dot(_2149, _858), 0.0, 1.0);
        float3 _1703 = float3(1.0) - _1048;
        float3 _1706 = _1048 + (_1703 * powr(1.0 - fast::clamp(dot(_853, _858), 0.0, 1.0), 5.0));
        float _1713 = _1036 * _1036;
        float _1718 = _1713 - 1.0;
        float _1720 = ((_1063 * _1063) * _1718) + 1.0;
        float _1740 = 1.0 - _1713;
        float _1744 = sqrt(((_1053 * _1053) * _1740) + _1713);
        float4 _1768 = (float4(-1.0, -0.0274999998509883880615234375, -0.572000026702880859375, 0.02199999988079071044921875) * _1032) + float4(1.0, 0.0425000004470348358154296875, 1.03999996185302734375, -0.039999999105930328369140625);
        float _1770 = _1768.x;
        float2 _1788 = (float2(-1.03999996185302734375, 1.03999996185302734375) * ((fast::min(_1770 * _1770, exp2((-9.27999973297119140625) * _1053)) * _1770) + _1768.y)) + _1768.zw;
        float3 _1119 = (_1048 * _1788.x) + float3(_1788.y);
        float3 _1805 = mix(_149._m9.xyz, _149._m8.xyz, float3((_2149.y * 0.5) + 0.5)) * _149._m8.w;
        float3 _1150 = ((((((float3(1.0) - _1706) * _1041) + ((_1706 * ((_1713 / ((3.1415927410125732421875 * _1720) * _1720)) * (0.5 / fast::max((_1058 * _1744) + (_1053 * sqrt(((_1058 * _1058) * _1740) + _1713)), 9.9999997473787516355514526367188e-06)))) * 3.1415927410125732421875)) * _1058) * _882) * _2128) + (((((float3(1.0) - _1119) * _1041) * _1805) + (_1119 * mix(mix(_149._m9.xyz, _149._m8.xyz, float3((reflect(-_853, _2149).y * 0.5) + 0.5)) * _149._m8.w, _1805, float3(_1032)))) * _895);
        float3 _2160;
        if (_149._m13.w > 0.5)
        {
            float2 _1850 = fast::clamp(floor(gl_FragCoord.xy * _149._m12.xy), float2(0.0), _149._m13.xy - float2(1.0));
            uint _1878 = uint((((fast::clamp(floor((log2(fast::max(dot(_149._m11.xyz, in.m_484) + _149._m11.w, 9.9999999747524270787835121154785e-07)) * _149._m12.z) + _149._m12.w), 0.0, _149._m13.z - 1.0) * _149._m13.y) + _1850.y) * _149._m13.x) + _1850.x);
            uint _1880 = _1878 >> uint(2);
            uint _1882 = _1878 & 3u;
            uint _1886 = _616._m0[_1880][_1882] & 65535u;
            uint _1888 = _616._m0[_1880][_1882] >> uint(16);
            float3 _2155;
            _2155 = _1150;
            for (uint _2153 = _1886; _2153 < (_1886 + _1888); )
            {
                uint _1894 = _2153 / 3u;
                uint _1907 = (_639._m0[_1894 >> uint(2)][_1894 & 3u] >> ((_2153 - (_1894 * 3u)) * 10u)) & 1023u;
                float3 _1924 = _476._m0[_1907].xyz - in.m_484;
                float _1927 = dot(_1924, _1924);
                float _1931 = _1927 * _476._m0[_1907].w;
                float _1936 = fast::clamp(1.0 - (_1931 * _1931), 0.0, 1.0);
                float3 _1941 = _1924 * rsqrt(fast::max(_1927, 9.9999999392252902907785028219223e-09));
                float _1959 = fast::clamp((dot(-_1941, _520._m0[_1907].xyz) * _512._m0[_1907].w) + _520._m0[_1907].w, 0.0, 1.0);
                float3 _1186 = fast::normalize(_1941 + _853);
                float _1191 = fast::clamp(dot(_2149, _1941), 0.0, 1.0);
                float _1196 = fast::clamp(dot(_2149, _1186), 0.0, 1.0);
                float3 _1984 = _1048 + (_1703 * powr(1.0 - fast::clamp(dot(_853, _1186), 0.0, 1.0), 5.0));
                float _1998 = ((_1196 * _1196) * _1718) + 1.0;
                _2155 += (((((float3(1.0) - _1984) * _1041) + ((_1984 * ((_1713 / ((3.1415927410125732421875 * _1998) * _1998)) * (0.5 / fast::max((_1191 * _1744) + (_1053 * sqrt(((_1191 * _1191) * _1740) + _1713)), 9.9999997473787516355514526367188e-06)))) * 3.1415927410125732421875)) * _1191) * (_512._m0[_1907].xyz * ((((_1936 * _1936) * _1959) * _1959) / fast::max(_1927, 9.9999997473787516355514526367188e-05))));
                _2153++;
                continue;
            }
            _2160 = _2155;
        }
        else
        {
            _2160 = _1150;
        }
        _2157 = _2160;
    }
    out.m_1273 = float4(mix(mix(_2157, _2138, float3(_660._m1.y)) + (_660._m5.xyz * _1246.sample(_687, _679).xyz), _149._m7.xyz, float3(1.0 - exp((-length(_852)) * _149._m7.w))), in.m_694.w);
    float2 _2185;
    do
    {
        if (in.m_1289.w <= 0.0)
        {
            _2185 = float2(0.0);
            break;
        }
        _2185 = ((in.m_1289.xy / float2(in.m_1289.w)) - (in.m_1288.xy / float2(in.m_1288.w))) * float2(0.5, -0.5);
        break;
    } while(false);
    out.m_1287 = _2185;
    return out;
}

