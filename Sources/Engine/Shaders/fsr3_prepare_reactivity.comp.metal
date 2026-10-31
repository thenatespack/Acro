// Generated from fsr3_prepare_reactivity.comp by Scripts/compile-shaders.sh — do not edit.
// Edit the GLSL and rerun the script (needs glslc and spirv-cross).
// spirv-fnv1a64: ce06e82bb01a330f
// glsl-fnv1a64: 39e6ca7415491ad3

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

struct _274
{
    int2 _m0;
    int2 _m1;
    int2 _m2;
    int2 _m3;
    float4 _m4;
    float2 _m5;
    float2 _m6;
    float2 _m7;
    float _m8;
    float _m9;
    float _m10;
    float _m11;
    float _m12;
    float _m13;
    float _m14;
    float _m15;
    float _m16;
    float _m17;
    float _m18;
    uint2 _m19;
};

struct _470
{
    uint _m0[1];
};

constant uint3 gl_WorkGroupSize [[maybe_unused]] = uint3(8u, 8u, 1u);
constant float _3146 = {};

constant spvUnsafeArray<int2, 9> _1049 = spvUnsafeArray<int2, 9>({ int2(0), int2(-1), int2(0, -1), int2(1, -1), int2(-1, 0), int2(1, 0), int2(-1, 1), int2(0, 1), int2(1) });
constant spvUnsafeArray<uint, 4> _1174 = spvUnsafeArray<uint, 4>({ 23u, 45u, 209u, 417u });
constant spvUnsafeArray<int2, 4> _3200 = spvUnsafeArray<int2, 4>({ int2(0), int2(1, 0), int2(0, 1), int2(1) });

kernel void compute_main(constant _274& _276 [[buffer(16)]], const device _470& _472 [[buffer(20)]], texture2d<float> _486 [[texture(1)]], texture2d<float> _505 [[texture(2)]], texture2d<float> _339 [[texture(3)]], texture2d<float> _368 [[texture(4)]], texture2d<float> _397 [[texture(5)]], texture2d<float> _412 [[texture(6)]], texture2d<float, access::write> _526 [[texture(8)]], texture2d<float, access::write> _431 [[texture(9)]], texture2d<float, access::write> _385 [[texture(10)]], sampler _372 [[sampler(1)]], uint3 gl_GlobalInvocationID [[thread_position_in_grid]])
{
    int2 _1403 = int2(gl_GlobalInvocationID.xy);
    float2 _1471 = float2(_1403) + float2(0.5);
    float2 _1473 = float2(_276._m0);
    float2 _1474 = _1471 / _1473;
    float4 _3073;
    if (all(gl_GlobalInvocationID.xy < uint2(int2(_486.get_width(), _486.get_height()))))
    {
        _3073 = _486.read(uint2(_1403), 0);
    }
    else
    {
        _3073 = float4(0.0);
    }
    float4 _3074;
    if (all(gl_GlobalInvocationID.xy < uint2(int2(_505.get_width(), _505.get_height()))))
    {
        _3074 = _505.read(uint2(_1403), 0);
    }
    else
    {
        _3074 = float4(0.0);
    }
    float _1615 = _276._m4.y / (_3074.x - _276._m4.x);
    float _1658 = _1615 * _276._m11;
    float _1788 = length(_3073.xy * float2(3840.0, 2160.0));
    float2 _1803 = ((_1474 + (_3073.xy * float(_1788 > mix(0.25, 0.75, fast::clamp(fast::min(_1658, 65504.0) * 0.00999999977648258209228515625, 0.0, 1.0))))) * _1473) - float2(0.5);
    int2 _1806 = int2(floor(_1803));
    float2 _1846 = fract(_1803);
    float _1815 = _1846.x;
    float _1816 = 1.0 - _1815;
    float _1818 = _1846.y;
    float _1819 = 1.0 - _1818;
    spvUnsafeArray<float, 4> _3014 = spvUnsafeArray<float, 4>({ _1816 * _1819, _1815 * _1819, _1816 * _1818, _1815 * _1818 });
    spvUnsafeArray<float, 4> _2990 = _3014;
    bool _3076;
    float _3077;
    float _3078;
    _3078 = 0.0;
    _3077 = 0.0;
    _3076 = true;
    bool _3169;
    float _3172;
    float _3175;
    for (int _3075 = 0; (_3075 < 4) && _3076; _3078 = _3175, _3077 = _3172, _3076 = _3169, _3075++)
    {
        int2 _1864 = _1806 + _3200[_3075];
        int _1891 = max(0, min(_1864.x, (_276._m0.x - 1)));
        int _1901 = max(0, min(_1864.y, (_276._m0.y - 1)));
        bool _1913 = all(uint2(int2(_1891, _1901)) < uint2(_276._m0));
        if (_1913)
        {
            bool _3170;
            float _3173;
            float _3176;
            if (_2990[_3075] > 0.0006099999882280826568603515625)
            {
                float _3161;
                if (_1913)
                {
                    _3161 = as_type<float>(_472._m0[uint((_1901 * _276._m0.x) + _1891)]);
                }
                else
                {
                    _3161 = 0.0;
                }
                float _1967 = _276._m4.y / (_3161 - _276._m4.x);
                float _1705 = _1615 - _1967;
                bool _1709 = _3076 && (_1705 > 1.1754943508222875079687365372222e-38);
                float _3174;
                float _3177;
                if (_1709)
                {
                    _3177 = _3078 + (fast::clamp(((1.3699999726668465882539749145508e-05 * length(_1473 * 0.5)) * fast::max(_1615, _1967)) / _1705, 0.0, 1.0) * _2990[_3075]);
                    _3174 = _3077 + _2990[_3075];
                }
                else
                {
                    _3177 = _3078;
                    _3174 = _3077;
                }
                _3176 = _3177;
                _3173 = _3174;
                _3170 = _1709;
            }
            else
            {
                _3176 = _3078;
                _3173 = _3077;
                _3170 = _3076;
            }
            _3175 = _3176;
            _3172 = _3173;
            _3169 = _3170;
        }
        else
        {
            _3175 = _3078;
            _3172 = _3077;
            _3169 = _3076;
        }
    }
    float _3079;
    if (_3076 && (_3077 > 0.0))
    {
        _3079 = fast::clamp(1.0 - (_3078 / _3077), 0.0, 1.0);
    }
    else
    {
        _3079 = 0.0;
    }
    float _3081;
    _3081 = 0.0;
    float _3159;
    for (int _3080 = -1; _3080 <= 1; _3081 = _3159, _3080++)
    {
        _3159 = _3081;
        float _2110;
        for (int _3155 = -1; _3155 <= 1; _3159 = _2110, _3155++)
        {
            int2 _2047 = _1403 + int2(_3155, _3080);
            int2 _3206 = int2(max(0, min(_2047.x, (_276._m0.x - 1))), max(0, min(_2047.y, (_276._m0.y - 1))));
            float4 _3157;
            if (all(uint2(_3206) < uint2(int2(_339.get_width(), _339.get_height()))))
            {
                _3157 = _339.read(uint2(_3206), 0);
            }
            else
            {
                _3157 = float4(0.0);
            }
            _2110 = fast::max(_3159, _3157.x * _276._m14);
        }
    }
    float2 _2172 = float2(int2(_1473 * 0.5));
    float _2214 = fast::max(_3081, fast::clamp(_397.sample(_372, (fast::max(float2(0.5), fast::min((_1474 - (_276._m5 / _1473)) * _2172, _2172 - float2(0.5))) / _2172), level(0.0)).x * _276._m15, 0.0, 1.0));
    float2 _2238 = _1474 + _3073.xy;
    int2 _2242 = int2(_2238 * _1473);
    uint2 _2284 = uint2(_2242);
    float4 _3082;
    if (all(_2284 < uint2(int2(_505.get_width(), _505.get_height()))))
    {
        _3082 = _505.read(uint2(_2242), 0);
    }
    else
    {
        _3082 = float4(0.0);
    }
    float4 _3083;
    if (all(_2284 < uint2(int2(_486.get_width(), _486.get_height()))))
    {
        _3083 = _486.read(uint2(_2242), 0);
    }
    else
    {
        _3083 = float4(0.0);
    }
    float _2332 = (_276._m4.y / (_3082.x - _276._m4.x)) * _276._m11;
    float _2400 = fast::max(_2332, _1658);
    float _3084;
    if (_2400 != 0.0)
    {
        _3084 = fast::min(_2332, _1658) / _2400;
    }
    else
    {
        _3084 = 0.0;
    }
    float _2542 = _2238.x;
    bool _2543 = _2542 >= 0.0;
    bool _2549;
    if (_2543)
    {
        _2549 = _2542 <= 1.0;
    }
    else
    {
        _2549 = _2543;
    }
    bool _2561;
    if (_2549)
    {
        float _2552 = _2238.y;
        bool _2553 = _2552 >= 0.0;
        bool _2559;
        if (_2553)
        {
            _2559 = _2552 <= 1.0;
        }
        else
        {
            _2559 = _2553;
        }
        _2561 = _2559;
    }
    else
    {
        _2561 = _2549;
    }
    float _3085;
    if (_2561)
    {
        float2 _2581 = float2(_276._m1);
        _3085 = fast::clamp(_368.sample(_372, (fast::max(float2(0.5), fast::min(_2238 * _2581, _2581 - float2(0.5))) / _1473), level(0.0)).x, 0.0, 1.0);
    }
    else
    {
        _3085 = 0.0;
    }
    float _2625 = mix(_3085, 0.0, _2214);
    float _2640 = mix(_2625, fast::min(_276._m17, _2625), _3079);
    float _2530 = _2640 * float(round(_2640 * 100.0) > 1.0);
    if (all(gl_GlobalInvocationID.xy < uint2(int2(_385.get_width(), _385.get_height()))))
    {
        _385.write(float4(fast::clamp(_2530 + _276._m16, 0.0, 1.0), 0.0, 0.0, 0.0), uint2(_1403));
    }
    if (all(gl_GlobalInvocationID.xy < uint2(int2(_526.get_width(), _526.get_height()))))
    {
        _526.write(float4(fast::max(((1.0 - fast::clamp(length(_3083.xy * float2(3840.0, 2160.0)) / _1788, 0.0, 1.0)) * _3084) * fast::clamp(_1788 * 0.100000001490116119384765625, 0.0, 1.0), 0.0), _3079, _2214, _2530), uint2(_1403));
    }
    float _3127;
    do
    {
        float _3121;
        float _3126;
        _3126 = 1.1754943508222875079687365372222e-38;
        _3121 = 3.4028234663852885981170418348452e+38;
        float _2908;
        float _2913;
        spvUnsafeArray<float, 9> _2682;
        for (int _3104 = 0; _3104 < 9; _3126 = _2913, _3121 = _2908, _3104++)
        {
            int2 _2839 = _1403 + _1049[_3104];
            int2 _3205 = int2(max(0, min(_2839.x, (_276._m0.x - 1))), max(0, min(_2839.y, (_276._m0.y - 1))));
            float4 _3151;
            if (all(uint2(_3205) < uint2(int2(_412.get_width(), _412.get_height()))))
            {
                _3151 = _412.read(uint2(_3205), 0);
            }
            else
            {
                _3151 = float4(0.0);
            }
            _2682[_3104] = _3151.x * ((_276._m18 == 0.0) ? 1.0 : _276._m18);
            _2908 = fast::min(_3121, _2682[_3104]);
            _2913 = fast::max(_3126, _2682[_3104]);
        }
        float _3106;
        float _3107;
        uint _3111;
        _3111 = 1u;
        _3107 = 3.4028234663852885981170418348452e+38;
        _3106 = 0.0;
        float _3184;
        float _3185;
        uint _3186;
        for (int _3105 = 1, _3148 = 1; _3105 < 9; _3148++, _3111 = _3186, _3107 = _3185, _3106 = _3184, _3105++)
        {
            if ((abs(_2682[_3105] - _2682[0]) / (_3126 - _3121)) < 0.89999997615814208984375)
            {
                _3186 = _3111 | (1u << uint(_3148));
                _3185 = _3107;
                _3184 = _3106;
            }
            else
            {
                _3186 = _3111;
                _3185 = fast::min(_3107, _2682[_3105]);
                _3184 = fast::max(_3106, _2682[_3105]);
            }
        }
        bool _2780 = _2682[0] > _3106;
        bool _2788;
        if (!_2780)
        {
            _2788 = _2682[0] < _3107;
        }
        else
        {
            _2788 = _2780;
        }
        if (!_2788)
        {
            _3127 = 0.0;
            break;
        }
        bool _3112;
        float _3128;
        int _3108 = 0;
        for (;;)
        {
            if (uint(_3108) < 4u)
            {
                if ((_3111 & _1174[_3108]) == _1174[_3108])
                {
                    _3128 = 0.0;
                    _3112 = true;
                    break;
                }
                _3108++;
                continue;
            }
            else
            {
                _3128 = _3146;
                _3112 = false;
                break;
            }
        }
        if (_3112)
        {
            _3127 = _3128;
            break;
        }
        _3127 = 1.0 - (_3121 / _3126);
        break;
    } while(false);
    if (_3127 > 0.00999999977648258209228515625)
    {
        int2 _2944 = int2(floor(((_1471 - _276._m5) / _1473) * float2(_276._m2)));
        if (all(uint2(_2944) < uint2(int2(_431.get_width(), _431.get_height()))))
        {
            _431.write(float4(_3127, 0.0, 0.0, 0.0), uint2(_2944));
        }
    }
}

