// Generated from mesh.frag by Scripts/compile-shaders.sh — do not edit.
// Edit the GLSL and rerun the script (needs glslc and spirv-cross).
// spirv-fnv1a64: 46ccf3b4eb1a0986
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
    float4 m_1260 [[color(0)]];
};

struct fragment_main_in
{
    float3 m_484 [[user(locn0)]];
    float3 m_737 [[user(locn1)]];
    float2 m_665 [[user(locn2)]];
    float4 m_694 [[user(locn3)]];
    float4 m_92 [[user(locn4)]];
    float4 m_852 [[user(locn5)]];
    float4 m_1275 [[user(locn6)]];
    float4 m_1276 [[user(locn7)]];
    float4 m_747 [[user(locn8)]];
};

fragment fragment_main_out fragment_main(fragment_main_in in [[stage_in]], constant _658& _660 [[buffer(2)]], constant _474& _476 [[buffer(3)]], constant _510& _512 [[buffer(4)]], constant _518& _520 [[buffer(5)]], constant _614& _616 [[buffer(6)]], constant _637& _639 [[buffer(7)]], constant _147& _149 [[buffer(15)]], texture2d<float> _172 [[texture(0)]], texture2d<float> _683 [[texture(1)]], texture2d<float> _999 [[texture(2)]], texture2d<float> _776 [[texture(3)]], texture2d<float> _873 [[texture(4)]], texture2d<float> _1233 [[texture(5)]], sampler _172Smplr [[sampler(0)]], sampler _687 [[sampler(1)]], float4 gl_FragCoord [[position]], bool gl_FrontFacing [[front_facing]])
{
    float2 _1274;
    fragment_main_out out = {};
    float2 _679 = float2(dot(_660._m2.xy, in.m_665) + _660._m2.z, dot(_660._m3.xy, in.m_665) + _660._m3.z);
    float4 _692 = _683.sample(_687, _679);
    float3 _703 = (in.m_694.xyz * _660._m0.xyz) * _692.xyz;
    float3 _2124;
    if (_660._m1.x > 0.5)
    {
        float2 _723 = floor(in.m_484.xz * float2(0.5));
        _2124 = _703 * ((mod(abs(_723.x + _723.y), 2.0) < 0.5) ? 1.0 : 0.75);
    }
    else
    {
        _2124 = _703;
    }
    float3 _739 = fast::normalize(in.m_737);
    float3 _2101;
    if (_660._m6.y > 0.5)
    {
        float3 _756 = in.m_747.xyz - (_739 * dot(_739, in.m_747.xyz));
        float3 _2102;
        if (dot(_756, _756) > 9.9999999600419720025001879548654e-13)
        {
            float3 _765 = fast::normalize(_756);
            float3 _785 = (_776.sample(_687, _679).xyz * 2.0) - float3(1.0);
            float2 _791 = _785.xy * _660._m4.z;
            _2102 = fast::normalize(((_765 * _791.x) + ((cross(_739, _765) * ((in.m_747.w < 0.0) ? (-1.0) : 1.0)) * _791.y)) + (_739 * _785.z));
        }
        else
        {
            _2102 = _739;
        }
        _2101 = _2102;
    }
    else
    {
        _2101 = _739;
    }
    bool _816 = _660._m5.w > 0.5;
    bool _824;
    if (_816)
    {
        _824 = !gl_FrontFacing;
    }
    else
    {
        _824 = _816;
    }
    float3 _2135;
    if (_824)
    {
        _2135 = -_2101;
    }
    else
    {
        _2135 = _2101;
    }
    float3 _833 = fast::normalize(_149._m4.xyz);
    float3 _839 = _149._m6.xyz - in.m_484;
    float3 _840 = fast::normalize(_839);
    float3 _845 = fast::normalize(_833 + _840);
    bool _849 = _149._m5.w > 0.5;
    bool _856;
    if (_849)
    {
        _856 = in.m_852.x > 0.5;
    }
    else
    {
        _856 = _849;
    }
    float _2114;
    if (_856)
    {
        float _2113;
        do
        {
            float3 _1319 = in.m_92.xyz / float3(in.m_92.w);
            float _1323 = (_1319.x * 0.5) + 0.5;
            float _1327 = 0.5 - (_1319.y * 0.5);
            bool _1331 = _1323 < 0.0;
            bool _1338;
            if (!_1331)
            {
                _1338 = _1323 > 1.0;
            }
            else
            {
                _1338 = _1331;
            }
            bool _1345;
            if (!_1338)
            {
                _1345 = _1327 < 0.0;
            }
            else
            {
                _1345 = _1338;
            }
            bool _1352;
            if (!_1345)
            {
                _1352 = _1327 > 1.0;
            }
            else
            {
                _1352 = _1345;
            }
            if (_1352)
            {
                _2113 = 1.0;
                break;
            }
            float _1360 = fast::min(_1319.z, 1.0) - _149._m10.y;
            int _1365 = int(_149._m10.z);
            if (_1365 <= 0)
            {
                _2113 = spvDepthCast(_172).sample_compare(_172Smplr, float3(_1323, _1327, _1360).xy, _1360);
                break;
            }
            float2 _1384 = (float2(_1323, _1327) / float2(_149._m10.x)) + float2(0.5);
            float2 _1385 = floor(_1384);
            float2 _1390 = _1384 - _1385;
            float2 _1395 = (_1385 - float2(0.5)) * _149._m10.x;
            bool _1397 = _1365 == 1;
            spvUnsafeArray<float2, 3> _1304;
            spvUnsafeArray<float2, 3> _1305;
            if (_1397)
            {
                float2 _1400 = _1390 * 2.0;
                _1304[0] = float2(3.0) - _1400;
                _1304[1] = float2(1.0) + _1400;
                _1305[0] = ((float2(2.0) - _1390) / _1304[0]) - float2(1.0);
                _1305[1] = (_1390 / _1304[1]) + float2(1.0);
            }
            else
            {
                float2 _1427 = _1390 * 3.0;
                _1304[0] = float2(4.0) - _1427;
                _1304[1] = float2(7.0);
                _1304[2] = float2(1.0) + _1427;
                _1305[0] = ((float2(3.0) - (_1390 * 2.0)) / _1304[0]) - float2(2.0);
                _1305[1] = (float2(3.0) + _1390) / _1304[1];
                _1305[2] = (_1390 / _1304[2]) + float2(2.0);
            }
            int _2161 = _1397 ? 2 : 3;
            int _2103;
            float _2106;
            _2106 = 0.0;
            _2103 = 0;
            float _2112;
            for (; _2103 < _2161; _2106 = _2112, _2103++)
            {
                _2112 = _2106;
                for (int _2109 = 0; _2109 < _2161; )
                {
                    _2112 += ((_1304[_2109].x * _1304[_2103].y) * spvDepthCast(_172).sample_compare(_172Smplr, float3(_1395 + (float2(_1305[_2109].x, _1305[_2103].y) * _149._m10.x), _1360).xy, _1360));
                    _2109++;
                    continue;
                }
            }
            _2113 = _2106 * (_1397 ? 0.0625 : 0.0069444444961845874786376953125);
            break;
        } while(false);
        _2114 = _2113;
    }
    else
    {
        _2114 = 1.0;
    }
    float3 _869 = _149._m5.xyz * _149._m4.w;
    float4 _878 = _873.sample(_687, _679);
    float _882 = 1.0 + (_660._m4.w * (_878.x - 1.0));
    float3 _2143;
    if (!_816)
    {
        float _890 = dot(_2135, _833);
        float3 _929 = (_2124 * (((mix(_149._m9.xyz, _149._m8.xyz, float3((_2135.y * 0.5) + 0.5)) * _149._m8.w) * _882) + ((_869 * fast::max(_890, 0.0)) * _2114))) + ((_869 * ((powr(fast::max(dot(_2135, _845), 0.0), _660._m1.w) * _660._m1.z) * step(0.0, _890))) * _2114);
        float3 _2144;
        if (_149._m13.w > 0.5)
        {
            float2 _1559 = fast::clamp(floor(gl_FragCoord.xy * _149._m12.xy), float2(0.0), _149._m13.xy - float2(1.0));
            uint _1587 = uint((((fast::clamp(floor((log2(fast::max(dot(_149._m11.xyz, in.m_484) + _149._m11.w, 9.9999999747524270787835121154785e-07)) * _149._m12.z) + _149._m12.w), 0.0, _149._m13.z - 1.0) * _149._m13.y) + _1559.y) * _149._m13.x) + _1559.x);
            uint _1589 = _1587 >> uint(2);
            uint _1591 = _1587 & 3u;
            uint _1595 = _616._m0[_1589][_1591] & 65535u;
            uint _1597 = _616._m0[_1589][_1591] >> uint(16);
            float3 _2145;
            _2145 = _929;
            for (uint _2142 = _1595; _2142 < (_1595 + _1597); )
            {
                uint _1603 = _2142 / 3u;
                uint _1616 = (_639._m0[_1603 >> uint(2)][_1603 & 3u] >> ((_2142 - (_1603 * 3u)) * 10u)) & 1023u;
                float3 _1633 = _476._m0[_1616].xyz - in.m_484;
                float _1636 = dot(_1633, _1633);
                float _1640 = _1636 * _476._m0[_1616].w;
                float _1645 = fast::clamp(1.0 - (_1640 * _1640), 0.0, 1.0);
                float3 _1650 = _1633 * rsqrt(fast::max(_1636, 9.9999999392252902907785028219223e-09));
                float _1668 = fast::clamp((dot(-_1650, _520._m0[_1616].xyz) * _512._m0[_1616].w) + _520._m0[_1616].w, 0.0, 1.0);
                float3 _1681 = _512._m0[_1616].xyz * ((((_1645 * _1645) * _1668) * _1668) / fast::max(_1636, 9.9999997473787516355514526367188e-05));
                float _965 = dot(_2135, _1650);
                _2145 += (((_2124 * fast::max(_965, 0.0)) * _1681) + (_1681 * ((powr(fast::max(dot(_2135, fast::normalize(_1650 + _840)), 0.0), _660._m1.w) * _660._m1.z) * step(0.0, _965))));
                _2142++;
                continue;
            }
            _2144 = _2145;
        }
        else
        {
            _2144 = _929;
        }
        _2143 = _2144;
    }
    else
    {
        float4 _1004 = _999.sample(_687, _679);
        float _1011 = fast::clamp(_660._m4.x * _1004.z, 0.0, 1.0);
        float _1019 = fast::clamp(_660._m4.y * _1004.y, 0.04500000178813934326171875, 1.0);
        float _1023 = _1019 * _1019;
        float3 _1028 = _2124 * (1.0 - _1011);
        float3 _1035 = mix(float3(0.039999999105930328369140625), _2124, float3(_1011));
        float _1040 = fast::max(dot(_2135, _840), 9.9999997473787516355514526367188e-05);
        float _1045 = fast::clamp(dot(_2135, _833), 0.0, 1.0);
        float _1050 = fast::clamp(dot(_2135, _845), 0.0, 1.0);
        float3 _1690 = float3(1.0) - _1035;
        float3 _1693 = _1035 + (_1690 * powr(1.0 - fast::clamp(dot(_840, _845), 0.0, 1.0), 5.0));
        float _1700 = _1023 * _1023;
        float _1705 = _1700 - 1.0;
        float _1707 = ((_1050 * _1050) * _1705) + 1.0;
        float _1727 = 1.0 - _1700;
        float _1731 = sqrt(((_1040 * _1040) * _1727) + _1700);
        float4 _1755 = (float4(-1.0, -0.0274999998509883880615234375, -0.572000026702880859375, 0.02199999988079071044921875) * _1019) + float4(1.0, 0.0425000004470348358154296875, 1.03999996185302734375, -0.039999999105930328369140625);
        float _1757 = _1755.x;
        float2 _1775 = (float2(-1.03999996185302734375, 1.03999996185302734375) * ((fast::min(_1757 * _1757, exp2((-9.27999973297119140625) * _1040)) * _1757) + _1755.y)) + _1755.zw;
        float3 _1106 = (_1035 * _1775.x) + float3(_1775.y);
        float3 _1792 = mix(_149._m9.xyz, _149._m8.xyz, float3((_2135.y * 0.5) + 0.5)) * _149._m8.w;
        float3 _1137 = ((((((float3(1.0) - _1693) * _1028) + ((_1693 * ((_1700 / ((3.1415927410125732421875 * _1707) * _1707)) * (0.5 / fast::max((_1045 * _1731) + (_1040 * sqrt(((_1045 * _1045) * _1727) + _1700)), 9.9999997473787516355514526367188e-06)))) * 3.1415927410125732421875)) * _1045) * _869) * _2114) + (((((float3(1.0) - _1106) * _1028) * _1792) + (_1106 * mix(mix(_149._m9.xyz, _149._m8.xyz, float3((reflect(-_840, _2135).y * 0.5) + 0.5)) * _149._m8.w, _1792, float3(_1019)))) * _882);
        float3 _2146;
        if (_149._m13.w > 0.5)
        {
            float2 _1837 = fast::clamp(floor(gl_FragCoord.xy * _149._m12.xy), float2(0.0), _149._m13.xy - float2(1.0));
            uint _1865 = uint((((fast::clamp(floor((log2(fast::max(dot(_149._m11.xyz, in.m_484) + _149._m11.w, 9.9999999747524270787835121154785e-07)) * _149._m12.z) + _149._m12.w), 0.0, _149._m13.z - 1.0) * _149._m13.y) + _1837.y) * _149._m13.x) + _1837.x);
            uint _1867 = _1865 >> uint(2);
            uint _1869 = _1865 & 3u;
            uint _1873 = _616._m0[_1867][_1869] & 65535u;
            uint _1875 = _616._m0[_1867][_1869] >> uint(16);
            float3 _2141;
            _2141 = _1137;
            for (uint _2139 = _1873; _2139 < (_1873 + _1875); )
            {
                uint _1881 = _2139 / 3u;
                uint _1894 = (_639._m0[_1881 >> uint(2)][_1881 & 3u] >> ((_2139 - (_1881 * 3u)) * 10u)) & 1023u;
                float3 _1911 = _476._m0[_1894].xyz - in.m_484;
                float _1914 = dot(_1911, _1911);
                float _1918 = _1914 * _476._m0[_1894].w;
                float _1923 = fast::clamp(1.0 - (_1918 * _1918), 0.0, 1.0);
                float3 _1928 = _1911 * rsqrt(fast::max(_1914, 9.9999999392252902907785028219223e-09));
                float _1946 = fast::clamp((dot(-_1928, _520._m0[_1894].xyz) * _512._m0[_1894].w) + _520._m0[_1894].w, 0.0, 1.0);
                float3 _1173 = fast::normalize(_1928 + _840);
                float _1178 = fast::clamp(dot(_2135, _1928), 0.0, 1.0);
                float _1183 = fast::clamp(dot(_2135, _1173), 0.0, 1.0);
                float3 _1971 = _1035 + (_1690 * powr(1.0 - fast::clamp(dot(_840, _1173), 0.0, 1.0), 5.0));
                float _1985 = ((_1183 * _1183) * _1705) + 1.0;
                _2141 += (((((float3(1.0) - _1971) * _1028) + ((_1971 * ((_1700 / ((3.1415927410125732421875 * _1985) * _1985)) * (0.5 / fast::max((_1178 * _1731) + (_1040 * sqrt(((_1178 * _1178) * _1727) + _1700)), 9.9999997473787516355514526367188e-06)))) * 3.1415927410125732421875)) * _1178) * (_512._m0[_1894].xyz * ((((_1923 * _1923) * _1946) * _1946) / fast::max(_1914, 9.9999997473787516355514526367188e-05))));
                _2139++;
                continue;
            }
            _2146 = _2141;
        }
        else
        {
            _2146 = _1137;
        }
        _2143 = _2146;
    }
    out.m_1260 = float4(mix(mix(_2143, _2124, float3(_660._m1.y)) + (_660._m5.xyz * _1233.sample(_687, _679).xyz), _149._m7.xyz, float3(1.0 - exp((-length(_839)) * _149._m7.w))), (in.m_694.w * _660._m0.w) * _692.w);
    float2 _2152;
    do
    {
        if (in.m_1276.w <= 0.0)
        {
            _2152 = float2(0.0);
            break;
        }
        _2152 = ((in.m_1276.xy / float2(in.m_1276.w)) - (in.m_1275.xy / float2(in.m_1275.w))) * float2(0.5, -0.5);
        break;
    } while(false);
    _1274 = _2152;
    return out;
}

