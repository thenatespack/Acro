// Generated from mesh_skin.frag by Scripts/compile-shaders.sh — do not edit.
// Edit the GLSL and rerun the script (needs glslc and spirv-cross).
// spirv-fnv1a64: d433a392a9e432dd
// glsl-fnv1a64: 5f2e617ff78cfba5

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

struct _289
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

struct _1676
{
    float4 _m0;
    float4 _m1;
    float4 _m2;
    float4 _m3;
    float4 _m4;
    float4 _m5;
    float4 _m6;
};

struct _1831
{
    float4 _m0[1024];
};

struct _1866
{
    float4 _m0[1024];
};

struct _1874
{
    float4 _m0[1024];
};

struct _1969
{
    uint4 _m0[1024];
};

struct _1990
{
    uint4 _m0[1024];
};

struct _2075
{
    float4 _m0;
    float4 _m1;
    float4 _m2;
    float4 _m3;
    float4 _m4;
    float4 _m5;
    float4 _m6;
};

constant float _20055 = {};

constant spvUnsafeArray<float3, 4> _665 = spvUnsafeArray<float3, 4>({ float3(1.0, 0.449999988079071044921875, 0.449999988079071044921875), float3(0.449999988079071044921875, 1.0, 0.449999988079071044921875), float3(0.5, 0.60000002384185791015625, 1.0), float3(1.0, 1.0, 0.4000000059604644775390625) });
constant spvUnsafeArray<float3, 6> _969 = spvUnsafeArray<float3, 6>({ float3(0.0, 0.0, 1.0), float3(0.0, 0.0, -1.0), float3(-1.0, 0.0, 0.0), float3(-1.0, 0.0, 0.0), float3(-1.0, 0.0, 0.0), float3(1.0, 0.0, 0.0) });
constant spvUnsafeArray<float3, 6> _978 = spvUnsafeArray<float3, 6>({ float3(0.0, 1.0, 0.0), float3(0.0, 1.0, 0.0), float3(0.0, 0.0, -1.0), float3(0.0, 0.0, 1.0), float3(0.0, 1.0, 0.0), float3(0.0, 1.0, 0.0) });
constant spvUnsafeArray<int4, 6> _1388 = spvUnsafeArray<int4, 6>({ int4(0, 0, 512, 256), int4(0, 256, 256, 128), int4(256, 256, 128, 64), int4(384, 256, 64, 32), int4(448, 256, 32, 16), int4(480, 256, 16, 8) });
constant spvUnsafeArray<float, 4> _2184 = spvUnsafeArray<float, 4>({ 0.00200000009499490261077880859375, 0.004999999888241291046142578125, 0.00999999977648258209228515625, 0.0199999995529651641845703125 });

struct fragment_main_out
{
    float4 m_5021 [[color(0)]];
    float2 m_5029 [[color(1)]];
};

struct fragment_main_in
{
    float3 m_1840 [[user(locn0)]];
    float3 m_1748 [[user(locn1)]];
    float2 m_3779 [[user(locn2)]];
    float4 m_4365 [[user(locn3)]];
    float3 m_1783 [[user(locn4)]];
    float4 m_4591 [[user(locn5)]];
    float4 m_5030 [[user(locn6)]];
    float4 m_5031 [[user(locn7)]];
    float4 m_1754 [[user(locn8)]];
};

fragment fragment_main_out fragment_main(fragment_main_in in [[stage_in]], constant _1676& _1678 [[buffer(2)]], constant _1831& _1833 [[buffer(3)]], constant _1866& _1868 [[buffer(4)]], constant _1874& _1876 [[buffer(5)]], constant _1969& _1971 [[buffer(6)]], constant _1990& _1992 [[buffer(7)]], constant _289& _291 [[buffer(15)]], constant _2075& _2077 [[buffer(16)]], texture2d<float> _311 [[texture(0)]], texture2d<float> _4358 [[texture(1)]], texture2d<float> _4797 [[texture(2)]], texture2d<float> _4471 [[texture(3)]], texture2d<float> _4631 [[texture(4)]], texture2d<float> _4887 [[texture(5)]], texture2d<float> _1326 [[texture(6)]], texture2d<float> _1432 [[texture(7)]], sampler _311Smplr [[sampler(0)]], sampler _1328 [[sampler(1)]], sampler _1434 [[sampler(7)]], float4 gl_FragCoord [[position]], bool gl_FrontFacing [[front_facing]])
{
    fragment_main_out out = {};
    float2 _4356 = float2(dot(_1678._m2.xy, in.m_3779) + _1678._m2.z, dot(_1678._m3.xy, in.m_3779) + _1678._m3.z);
    float4 _4363 = _4358.sample(_1328, _4356);
    float3 _4373 = _4363.xyz;
    float3 _4374 = (in.m_4365.xyz * _1678._m0.xyz) * _4373;
    float3 _18581;
    if (_1678._m1.x > 0.5)
    {
        float2 _4395 = floor(in.m_1840.xz * float2(0.5));
        _18581 = _4374 * ((mod(abs(_4395.x + _4395.y), 2.0) < 0.5) ? 1.0 : 0.75);
    }
    else
    {
        _18581 = _4374;
    }
    float3 _18678;
    float _18709;
    float2 _18742;
    if (_1678._m3.w > 0.5)
    {
        float3 _5169;
        float2 _5176;
        float _18579;
        do
        {
            float3 _5140 = float4(_1678._m2.w, _1678._m3.w, 0.0, 0.0).xyy;
            float3 _5143 = floor(_5140 * float3(1.52587890625e-05));
            float3 _5148 = _5140 - (_5143 * 65536.0);
            float3 _5151 = floor(_5148 * float3(0.00390625));
            float3 _5159 = _5148 - (_5151 * 256.0);
            _5169 = (float3(_5159.x, _5151.x, _5143.x) * float3(0.0039215688593685626983642578125)) * 2.0;
            _5176 = float2(_5159.y, _5151.y) * float2(0.0039215688593685626983642578125);
            float _5179 = _5143.y - 128.0;
            float _5185 = floor(_5179 * 0.03125) * 0.3333333432674407958984375;
            float3 _5191 = fast::normalize(in.m_1748);
            float _5195 = dot(_5191, in.m_1754.xyz);
            float _5207 = (_5195 / fast::max(length(in.m_1754.xyz - (_5191 * _5195)), 9.9999999747524270787835121154785e-07)) * 25.5;
            if (((-24.0) + _5207) < (-2.0))
            {
                _18579 = 0.0;
                break;
            }
            float3 _5215 = in.m_1783 * (4.0 * exp2(mod(_5179, 32.0) * 0.3333333432674407958984375));
            float3 _5259 = floor(_5215);
            float3 _5262 = _5215 - _5259;
            float3 _5270 = (_5262 * _5262) * (float3(3.0) - (_5262 * 2.0));
            uint3 _5337 = uint3(int3(_5259));
            uint _5350 = (((_5337.x * 1597334677u) ^ (_5337.y * 3812015801u)) ^ (_5337.z * 2798796415u)) * 1597334677u;
            uint3 _5365 = uint3(int3(_5259 + float3(1.0, 0.0, 0.0)));
            uint _5378 = (((_5365.x * 1597334677u) ^ (_5365.y * 3812015801u)) ^ (_5365.z * 2798796415u)) * 1597334677u;
            float _5279 = _5270.x;
            uint3 _5393 = uint3(int3(_5259 + float3(0.0, 1.0, 0.0)));
            uint _5406 = (((_5393.x * 1597334677u) ^ (_5393.y * 3812015801u)) ^ (_5393.z * 2798796415u)) * 1597334677u;
            uint3 _5421 = uint3(int3(_5259 + float3(1.0, 1.0, 0.0)));
            uint _5434 = (((_5421.x * 1597334677u) ^ (_5421.y * 3812015801u)) ^ (_5421.z * 2798796415u)) * 1597334677u;
            float _5295 = _5270.y;
            uint3 _5449 = uint3(int3(_5259 + float3(0.0, 0.0, 1.0)));
            uint _5462 = (((_5449.x * 1597334677u) ^ (_5449.y * 3812015801u)) ^ (_5449.z * 2798796415u)) * 1597334677u;
            uint3 _5477 = uint3(int3(_5259 + float3(1.0, 0.0, 1.0)));
            uint _5490 = (((_5477.x * 1597334677u) ^ (_5477.y * 3812015801u)) ^ (_5477.z * 2798796415u)) * 1597334677u;
            uint3 _5505 = uint3(int3(_5259 + float3(0.0, 1.0, 1.0)));
            uint _5518 = (((_5505.x * 1597334677u) ^ (_5505.y * 3812015801u)) ^ (_5505.z * 2798796415u)) * 1597334677u;
            uint3 _5533 = uint3(int3(_5259 + float3(1.0)));
            uint _5546 = (((_5533.x * 1597334677u) ^ (_5533.y * 3812015801u)) ^ (_5533.z * 2798796415u)) * 1597334677u;
            float3 _5221 = (_5215 * 2.7000000476837158203125) + float3(17.299999237060546875, 5.099999904632568359375, 9.69999980926513671875);
            float3 _5572 = floor(_5221);
            float3 _5575 = _5221 - _5572;
            float3 _5583 = (_5575 * _5575) * (float3(3.0) - (_5575 * 2.0));
            uint3 _5650 = uint3(int3(_5572));
            uint _5663 = (((_5650.x * 1597334677u) ^ (_5650.y * 3812015801u)) ^ (_5650.z * 2798796415u)) * 1597334677u;
            uint3 _5678 = uint3(int3(_5572 + float3(1.0, 0.0, 0.0)));
            uint _5691 = (((_5678.x * 1597334677u) ^ (_5678.y * 3812015801u)) ^ (_5678.z * 2798796415u)) * 1597334677u;
            float _5592 = _5583.x;
            uint3 _5706 = uint3(int3(_5572 + float3(0.0, 1.0, 0.0)));
            uint _5719 = (((_5706.x * 1597334677u) ^ (_5706.y * 3812015801u)) ^ (_5706.z * 2798796415u)) * 1597334677u;
            uint3 _5734 = uint3(int3(_5572 + float3(1.0, 1.0, 0.0)));
            uint _5747 = (((_5734.x * 1597334677u) ^ (_5734.y * 3812015801u)) ^ (_5734.z * 2798796415u)) * 1597334677u;
            float _5608 = _5583.y;
            uint3 _5762 = uint3(int3(_5572 + float3(0.0, 0.0, 1.0)));
            uint _5775 = (((_5762.x * 1597334677u) ^ (_5762.y * 3812015801u)) ^ (_5762.z * 2798796415u)) * 1597334677u;
            uint3 _5790 = uint3(int3(_5572 + float3(1.0, 0.0, 1.0)));
            uint _5803 = (((_5790.x * 1597334677u) ^ (_5790.y * 3812015801u)) ^ (_5790.z * 2798796415u)) * 1597334677u;
            uint3 _5818 = uint3(int3(_5572 + float3(0.0, 1.0, 1.0)));
            uint _5831 = (((_5818.x * 1597334677u) ^ (_5818.y * 3812015801u)) ^ (_5818.z * 2798796415u)) * 1597334677u;
            uint3 _5846 = uint3(int3(_5572 + float3(1.0)));
            uint _5859 = (((_5846.x * 1597334677u) ^ (_5846.y * 3812015801u)) ^ (_5846.z * 2798796415u)) * 1597334677u;
            float _5226 = mix(0.449999988079071044921875, 0.0500000007450580596923828125, _5185);
            float _5230 = ((mix(mix(mix(float((_5350 ^ (_5350 >> uint(16))) & 65535u) * 1.525902189314365386962890625e-05, float((_5378 ^ (_5378 >> uint(16))) & 65535u) * 1.525902189314365386962890625e-05, _5279), mix(float((_5406 ^ (_5406 >> uint(16))) & 65535u) * 1.525902189314365386962890625e-05, float((_5434 ^ (_5434 >> uint(16))) & 65535u) * 1.525902189314365386962890625e-05, _5279), _5295), mix(mix(float((_5462 ^ (_5462 >> uint(16))) & 65535u) * 1.525902189314365386962890625e-05, float((_5490 ^ (_5490 >> uint(16))) & 65535u) * 1.525902189314365386962890625e-05, _5279), mix(float((_5518 ^ (_5518 >> uint(16))) & 65535u) * 1.525902189314365386962890625e-05, float((_5546 ^ (_5546 >> uint(16))) & 65535u) * 1.525902189314365386962890625e-05, _5279), _5295), _5270.z) * 0.64999997615814208984375) + (mix(mix(mix(float((_5663 ^ (_5663 >> uint(16))) & 65535u) * 1.525902189314365386962890625e-05, float((_5691 ^ (_5691 >> uint(16))) & 65535u) * 1.525902189314365386962890625e-05, _5592), mix(float((_5719 ^ (_5719 >> uint(16))) & 65535u) * 1.525902189314365386962890625e-05, float((_5747 ^ (_5747 >> uint(16))) & 65535u) * 1.525902189314365386962890625e-05, _5592), _5608), mix(mix(float((_5775 ^ (_5775 >> uint(16))) & 65535u) * 1.525902189314365386962890625e-05, float((_5803 ^ (_5803 >> uint(16))) & 65535u) * 1.525902189314365386962890625e-05, _5592), mix(float((_5831 ^ (_5831 >> uint(16))) & 65535u) * 1.525902189314365386962890625e-05, float((_5859 ^ (_5859 >> uint(16))) & 65535u) * 1.525902189314365386962890625e-05, _5592), _5608), _5583.z) * 0.3499999940395355224609375)) - 0.5;
            _18579 = smoothstep(-_5226, _5226, (_5207 + (-24.450000762939453125)) + (_5230 * mix(0.800000011920928955078125, 2.2000000476837158203125, _5185)));
            break;
        } while(false);
        _18742 = _5176;
        _18709 = _18579;
        _18678 = mix(_18581, (in.m_4365.xyz * _5169) * mix(float3(1.0), _4373 * 2.0, float3(0.5)), float3(_18579));
    }
    else
    {
        _18742 = float2(0.0);
        _18709 = 0.0;
        _18678 = _18581;
    }
    float3 _4437 = fast::normalize(in.m_1748);
    float3 _18591;
    if (_1678._m6.y > 0.5)
    {
        float3 _4452 = in.m_1754.xyz - (_4437 * dot(_4437, in.m_1754.xyz));
        float3 _18592;
        if (dot(_4452, _4452) > 9.9999999600419720025001879548654e-13)
        {
            float3 _4460 = fast::normalize(_4452);
            float4 _4476 = _4471.sample(_1328, _4356);
            float3 _18583;
            if (_1678._m6.z > 0.5)
            {
                float2 _18582;
                if (_1678._m6.z > 1.5)
                {
                    _18582 = _4476.xw;
                }
                else
                {
                    _18582 = _4476.xy;
                }
                float2 _4498 = (_18582 * 2.0) - float2(1.0);
                _18583 = float3(_4498, sqrt(fast::clamp(1.0 - dot(_4498, _4498), 0.0, 1.0)));
            }
            else
            {
                _18583 = (_4476.xyz * 2.0) - float3(1.0);
            }
            float2 _4520 = _18583.xy * _1678._m4.z;
            _18592 = fast::normalize(((_4460 * _4520.x) + ((cross(_4437, _4460) * ((in.m_1754.w < 0.0) ? (-1.0) : 1.0)) * _4520.y)) + (_4437 * _18583.z));
        }
        else
        {
            _18592 = _4437;
        }
        _18591 = _18592;
    }
    else
    {
        _18591 = _4437;
    }
    bool _4543 = _1678._m5.w > 0.5;
    float _18588;
    if (_4543)
    {
        _18588 = fast::clamp(_1678._m1.z, 0.0, 1.0);
    }
    else
    {
        _18588 = 0.0;
    }
    bool _4559;
    if (_4543)
    {
        _4559 = !gl_FrontFacing;
    }
    else
    {
        _4559 = _4543;
    }
    float3 _18776;
    if (_4559 && (_18588 <= 0.0))
    {
        _18776 = -_18591;
    }
    else
    {
        _18776 = _18591;
    }
    float3 _4571 = fast::normalize(_291._m4.xyz);
    float3 _4577 = _291._m6.xyz - in.m_1840;
    float3 _4578 = fast::normalize(_4577);
    float3 _4583 = fast::normalize(_4571 + _4578);
    float3 _4589 = _4437 * (gl_FrontFacing ? 1.0 : (-1.0));
    bool _4594 = in.m_4591.x > 0.5;
    float3 _18771;
    float _18802;
    if ((_291._m5.w > 0.5) && _4594)
    {
        float _18648;
        float3 _18649;
        do
        {
            int _5888 = int(_291._m21.x);
            float _5896 = dot(_291._m20.xyz, in.m_1840) + _291._m20.w;
            int _18593;
            _18593 = 0;
            for (;;)
            {
                bool _5902 = _18593 < (_5888 - 1);
                bool _5910;
                if (_5902)
                {
                    _5910 = _5896 > _291._m16[_18593];
                }
                else
                {
                    _5910 = _5902;
                }
                if (_5910)
                {
                    _18593++;
                    continue;
                }
                else
                {
                    break;
                }
            }
            if (_5896 > _291._m16[_18593])
            {
                _18649 = float3(1.0);
                _18648 = 1.0;
                break;
            }
            float _18606;
            do
            {
                float4 _6012 = _291._m14[_18593] * float4(in.m_1840 + (_4589 * _291._m18[_18593]), 1.0);
                float _6015 = _6012.x;
                bool _6016 = _6015 < 0.0;
                bool _6023;
                if (!_6016)
                {
                    _6023 = _6015 > 1.0;
                }
                else
                {
                    _6023 = _6016;
                }
                bool _6030;
                if (!_6023)
                {
                    _6030 = _6012.y < 0.0;
                }
                else
                {
                    _6030 = _6023;
                }
                bool _6037;
                if (!_6030)
                {
                    _6037 = _6012.y > 1.0;
                }
                else
                {
                    _6037 = _6030;
                }
                if (_6037)
                {
                    _18606 = 1.0;
                    break;
                }
                float2 _6050 = float2(float(_18593 & 1), float(_18593 >> 1)) * _291._m23.xy;
                float _6057 = fast::min(_6012.z, 1.0) - _291._m19[_18593];
                float2 _6076 = _291._m22.xy * 0.5;
                float2 _6081 = _6050 + (_6012.xy * _291._m23.xy);
                float4 _6094 = float4(_6050 + _6076, (_6050 + _291._m23.xy) - _6076);
                float _18605;
                do
                {
                    int _6120 = int(_291._m22.z);
                    if (_6120 <= 0)
                    {
                        _18605 = spvDepthCast(_311).sample_compare(_311Smplr, float3(fast::clamp(_6081, _6094.xy, _6094.zw), _6057).xy, _6057);
                        break;
                    }
                    float2 _6143 = (_6081 / _291._m22.xy) + float2(0.5);
                    float2 _6144 = floor(_6143);
                    float2 _6149 = _6143 - _6144;
                    float2 _6152 = _6144 - float2(0.5);
                    bool _6156 = _6120 == 1;
                    spvUnsafeArray<float2, 3> _6104;
                    spvUnsafeArray<float2, 3> _6105;
                    if (_6156)
                    {
                        float2 _6159 = _6149 * 2.0;
                        _6104[0] = float2(3.0) - _6159;
                        _6104[1] = float2(1.0) + _6159;
                        _6105[0] = ((float2(2.0) - _6149) / _6104[0]) - float2(1.0);
                        _6105[1] = (_6149 / _6104[1]) + float2(1.0);
                    }
                    else
                    {
                        float2 _6186 = _6149 * 3.0;
                        _6104[0] = float2(4.0) - _6186;
                        _6104[1] = float2(7.0);
                        _6104[2] = float2(1.0) + _6186;
                        _6105[0] = ((float2(3.0) - (_6149 * 2.0)) / _6104[0]) - float2(2.0);
                        _6105[1] = (float2(3.0) + _6149) / _6104[1];
                        _6105[2] = (_6149 / _6104[2]) + float2(2.0);
                    }
                    int _20066 = _6156 ? 2 : 3;
                    int _18595;
                    float _18598;
                    _18598 = 0.0;
                    _18595 = 0;
                    float _18604;
                    for (; _18595 < _20066; _18598 = _18604, _18595++)
                    {
                        _18604 = _18598;
                        for (int _18601 = 0; _18601 < _20066; )
                        {
                            _18604 += ((_6104[_18601].x * _6104[_18595].y) * spvDepthCast(_311).sample_compare(_311Smplr, float3(fast::clamp(_291._m22.xy * (_6152 + float2(_6105[_18601].x, _6105[_18595].y)), _6094.xy, _6094.zw), _6057).xy, _6057));
                            _18601++;
                            continue;
                        }
                    }
                    _18605 = _18598 * (_6156 ? 0.0625 : 0.0069444444961845874786376953125);
                    break;
                } while(false);
                _18606 = _18605;
                break;
            } while(false);
            float3 _18643;
            float _18646;
            if (_5896 > _291._m17[_18593])
            {
                float _5950 = (_5896 - _291._m17[_18593]) / (_291._m16[_18593] - _291._m17[_18593]);
                int _5952 = _18593 + 1;
                float3 _18644;
                float _18647;
                if (_5952 < _5888)
                {
                    float _18626;
                    do
                    {
                        float4 _6299 = _291._m14[_5952] * float4(in.m_1840 + (_4589 * _291._m18[_5952]), 1.0);
                        float _6302 = _6299.x;
                        bool _6303 = _6302 < 0.0;
                        bool _6310;
                        if (!_6303)
                        {
                            _6310 = _6302 > 1.0;
                        }
                        else
                        {
                            _6310 = _6303;
                        }
                        bool _6317;
                        if (!_6310)
                        {
                            _6317 = _6299.y < 0.0;
                        }
                        else
                        {
                            _6317 = _6310;
                        }
                        bool _6324;
                        if (!_6317)
                        {
                            _6324 = _6299.y > 1.0;
                        }
                        else
                        {
                            _6324 = _6317;
                        }
                        if (_6324)
                        {
                            _18626 = 1.0;
                            break;
                        }
                        float2 _6337 = float2(float(_5952 & 1), float(_5952 >> 1)) * _291._m23.xy;
                        float _6344 = fast::min(_6299.z, 1.0) - _291._m19[_5952];
                        float2 _6363 = _291._m22.xy * 0.5;
                        float2 _6368 = _6337 + (_6299.xy * _291._m23.xy);
                        float4 _6381 = float4(_6337 + _6363, (_6337 + _291._m23.xy) - _6363);
                        float _18625;
                        do
                        {
                            int _6407 = int(_291._m22.z);
                            if (_6407 <= 0)
                            {
                                _18625 = spvDepthCast(_311).sample_compare(_311Smplr, float3(fast::clamp(_6368, _6381.xy, _6381.zw), _6344).xy, _6344);
                                break;
                            }
                            float2 _6430 = (_6368 / _291._m22.xy) + float2(0.5);
                            float2 _6431 = floor(_6430);
                            float2 _6436 = _6430 - _6431;
                            float2 _6439 = _6431 - float2(0.5);
                            bool _6443 = _6407 == 1;
                            spvUnsafeArray<float2, 3> _6391;
                            spvUnsafeArray<float2, 3> _6392;
                            if (_6443)
                            {
                                float2 _6446 = _6436 * 2.0;
                                _6391[0] = float2(3.0) - _6446;
                                _6391[1] = float2(1.0) + _6446;
                                _6392[0] = ((float2(2.0) - _6436) / _6391[0]) - float2(1.0);
                                _6392[1] = (_6436 / _6391[1]) + float2(1.0);
                            }
                            else
                            {
                                float2 _6473 = _6436 * 3.0;
                                _6391[0] = float2(4.0) - _6473;
                                _6391[1] = float2(7.0);
                                _6391[2] = float2(1.0) + _6473;
                                _6392[0] = ((float2(3.0) - (_6436 * 2.0)) / _6391[0]) - float2(2.0);
                                _6392[1] = (float2(3.0) + _6436) / _6391[1];
                                _6392[2] = (_6436 / _6391[2]) + float2(2.0);
                            }
                            int _20068 = _6443 ? 2 : 3;
                            int _18615;
                            float _18618;
                            _18618 = 0.0;
                            _18615 = 0;
                            float _18624;
                            for (; _18615 < _20068; _18618 = _18624, _18615++)
                            {
                                _18624 = _18618;
                                for (int _18621 = 0; _18621 < _20068; )
                                {
                                    _18624 += ((_6391[_18621].x * _6391[_18615].y) * spvDepthCast(_311).sample_compare(_311Smplr, float3(fast::clamp(_291._m22.xy * (_6439 + float2(_6392[_18621].x, _6392[_18615].y)), _6381.xy, _6381.zw), _6344).xy, _6344));
                                    _18621++;
                                    continue;
                                }
                            }
                            _18625 = _18618 * (_6443 ? 0.0625 : 0.0069444444961845874786376953125);
                            break;
                        } while(false);
                        _18626 = _18625;
                        break;
                    } while(false);
                    _18647 = mix(_18606, _18626, _5950);
                    _18644 = mix(_665[_18593], _665[_5952], float3(_5950));
                }
                else
                {
                    _18647 = mix(_18606, 1.0, _5950);
                    _18644 = _665[_18593];
                }
                _18646 = _18647;
                _18643 = _18644;
            }
            else
            {
                _18646 = _18606;
                _18643 = _665[_18593];
            }
            _18649 = select(float3(1.0), _18643, bool3(_291._m22.w > 0.5));
            _18648 = _18646;
            break;
        } while(false);
        _18802 = _18648;
        _18771 = _18678 * _18649;
    }
    else
    {
        _18802 = 1.0;
        _18771 = _18678;
    }
    float3 _4620 = _291._m5.xyz * _291._m4.w;
    float _18701;
    if (_1678._m6.w > 0.5)
    {
        _18701 = 1.0;
    }
    else
    {
        _18701 = 1.0 + (_1678._m4.w * (_4631.sample(_1328, _4356).x - 1.0));
    }
    float _4645 = abs(in.m_1754.w);
    float _18804;
    if (_4645 > 0.0)
    {
        _18804 = _18701 * fast::min(_4645, 1.0);
    }
    else
    {
        _18804 = _18701;
    }
    float3 _19404;
    float3 _19544;
    if (!_4543)
    {
        float _4662 = dot(_18776, _4571);
        float3 _19396;
        if (_291._m29.x > 0.5)
        {
            float _6624 = (_291._m29.z * _18776.x) - (_291._m29.w * _18776.z);
            float _6637 = (_291._m29.w * _18776.x) + (_291._m29.z * _18776.z);
            float _6655 = 1.09254801273345947265625 * _6624;
            spvUnsafeArray<float, 9> _17851 = spvUnsafeArray<float, 9>({ 0.2820949852466583251953125, 0.48860299587249755859375 * _18776.y, 0.48860299587249755859375 * _6637, 0.48860299587249755859375 * _6624, _6655 * _18776.y, (1.09254801273345947265625 * _18776.y) * _6637, 0.3153919875621795654296875 * (((3.0 * _6637) * _6637) - 1.0), _6655 * _6637, 0.546274006366729736328125 * ((_6624 * _6624) - (_18776.y * _18776.y)) });
            spvUnsafeArray<float, 9> _6569 = _17851;
            float3 _19395;
            _19395 = float3(0.0);
            for (int _19394 = 0; _19394 < 9; )
            {
                _19395 += (_1326.read(uint2((int2(496, 256) + int2(_19394, 0))), 0).xyz * _6569[_19394]);
                _19394++;
                continue;
            }
            _19396 = fast::max(_19395, float3(0.0)) * _291._m29.y;
        }
        else
        {
            _19396 = mix(_291._m9.xyz, _291._m8.xyz, float3((_18776.y * 0.5) + 0.5)) * _291._m8.w;
        }
        float3 _4712 = (_18771 * ((_19396 * _18804) + ((_4620 * fast::max(_4662, 0.0)) * _18802))) + ((_4620 * ((powr(fast::max(dot(_18776, _4583), 0.0), _1678._m1.w) * _1678._m1.z) * step(0.0, _4662))) * _18802);
        float3 _19405;
        if (_291._m13.w > 0.5)
        {
            float2 _6740 = fast::clamp(floor(gl_FragCoord.xy * _291._m12.xy), float2(0.0), _291._m13.xy - float2(1.0));
            uint _6768 = uint((((fast::clamp(floor((log2(fast::max(dot(_291._m11.xyz, in.m_1840) + _291._m11.w, 9.9999999747524270787835121154785e-07)) * _291._m12.z) + _291._m12.w), 0.0, _291._m13.z - 1.0) * _291._m13.y) + _6740.y) * _291._m13.x) + _6740.x);
            uint _6770 = _6768 >> uint(2);
            uint _6772 = _6768 & 3u;
            uint _6776 = _1971._m0[_6770][_6772] & 65535u;
            uint _6778 = _1971._m0[_6770][_6772] >> uint(16);
            float3 _19406;
            _19406 = _4712;
            float3 _4792;
            spvUnsafeArray<float2, 3> _7186;
            spvUnsafeArray<float2, 3> _7187;
            spvUnsafeArray<float2, 3> _7399;
            spvUnsafeArray<float2, 3> _7400;
            for (uint _19403 = _6776; _19403 < (_6776 + _6778); _19406 = _4792, _19403++)
            {
                uint _6784 = _19403 / 3u;
                uint _6797 = (_1992._m0[_6784 >> uint(2)][_6784 & 3u] >> ((_19403 - (_6784 * 3u)) * 10u)) & 1023u;
                float3 _6814 = _1833._m0[_6797].xyz - in.m_1840;
                float _6817 = dot(_6814, _6814);
                float _6821 = _6817 * _1833._m0[_6797].w;
                float _6826 = fast::clamp(1.0 - (_6821 * _6821), 0.0, 1.0);
                float3 _6831 = _6814 * rsqrt(fast::max(_6817, 9.9999999392252902907785028219223e-09));
                float _6849 = fast::clamp((dot(-_6831, _1876._m0[_6797].xyz) * _1868._m0[_6797].w) + _1876._m0[_6797].w, 0.0, 1.0);
                float3 _6862 = _1868._m0[_6797].xyz * ((((_6826 * _6826) * _6849) * _6849) / fast::max(_6817, 9.9999997473787516355514526367188e-05));
                float3 _19809;
                if (_4594)
                {
                    float _19755;
                    do
                    {
                        uint _6898 = uint(_291._m21.z);
                        if (_6797 < _6898)
                        {
                            float _6920 = _291._m26[_6797].z * fast::max((_291._m15[_6797] * float4(in.m_1840, 1.0)).w, 0.0);
                            float4 _6944 = _291._m15[_6797] * float4((in.m_1840 + (_4589 * (_6920 * _291._m25.x))) + (_6831 * (_6920 * _291._m25.y)), 1.0);
                            float _6946 = _6944.w;
                            if (_6946 <= 0.0)
                            {
                                _19755 = 1.0;
                                break;
                            }
                            float3 _6955 = _6944.xyz / float3(_6946);
                            float _6957 = _6955.x;
                            bool _6958 = _6957 < 0.0;
                            bool _6965;
                            if (!_6958)
                            {
                                _6965 = _6957 > 1.0;
                            }
                            else
                            {
                                _6965 = _6958;
                            }
                            bool _6972;
                            if (!_6965)
                            {
                                _6972 = _6955.y < 0.0;
                            }
                            else
                            {
                                _6972 = _6965;
                            }
                            bool _6979;
                            if (!_6972)
                            {
                                _6979 = _6955.y > 1.0;
                            }
                            else
                            {
                                _6979 = _6972;
                            }
                            bool _6986;
                            if (!_6979)
                            {
                                _6986 = _6955.z > 1.0;
                            }
                            else
                            {
                                _6986 = _6979;
                            }
                            if (_6986)
                            {
                                _19755 = 1.0;
                                break;
                            }
                            float _6992 = _6955.z;
                            float2 _7158 = _291._m22.xy * 0.5;
                            float2 _7163 = _291._m26[_6797].xy + (_6955.xy * _291._m23.zw);
                            float4 _7176 = float4(_291._m26[_6797].xy + _7158, (_291._m26[_6797].xy + _291._m23.zw) - _7158);
                            float _19754;
                            do
                            {
                                int _7202 = int(_291._m22.z);
                                if (_7202 <= 0)
                                {
                                    float2 _7212 = fast::clamp(_7163, _7176.xy, _7176.zw);
                                    _19754 = spvDepthCast(_311).sample_compare(_311Smplr, float3(_7212, _6992).xy, _6992);
                                    break;
                                }
                                float2 _7225 = (_7163 / _291._m22.xy) + float2(0.5);
                                float2 _7226 = floor(_7225);
                                float2 _7231 = _7225 - _7226;
                                float2 _7234 = _7226 - float2(0.5);
                                bool _7238 = _7202 == 1;
                                if (_7238)
                                {
                                    float2 _7241 = _7231 * 2.0;
                                    _7186[0] = float2(3.0) - _7241;
                                    _7186[1] = float2(1.0) + _7241;
                                    _7187[0] = ((float2(2.0) - _7231) / _7186[0]) - float2(1.0);
                                    _7187[1] = (_7231 / _7186[1]) + float2(1.0);
                                }
                                else
                                {
                                    float2 _7268 = _7231 * 3.0;
                                    _7186[0] = float2(4.0) - _7268;
                                    _7186[1] = float2(7.0);
                                    _7186[2] = float2(1.0) + _7268;
                                    _7187[0] = ((float2(3.0) - (_7231 * 2.0)) / _7186[0]) - float2(2.0);
                                    _7187[1] = (float2(3.0) + _7231) / _7186[1];
                                    _7187[2] = (_7231 / _7186[2]) + float2(2.0);
                                }
                                int _20073 = _7238 ? 2 : 3;
                                int _19744;
                                float _19747;
                                _19747 = 0.0;
                                _19744 = 0;
                                float _19753;
                                for (; _19744 < _20073; _19747 = _19753, _19744++)
                                {
                                    _19753 = _19747;
                                    for (int _19750 = 0; _19750 < _20073; )
                                    {
                                        _19753 += ((_7186[_19750].x * _7186[_19744].y) * spvDepthCast(_311).sample_compare(_311Smplr, float3(fast::clamp(_291._m22.xy * (_7234 + float2(_7187[_19750].x, _7187[_19744].y)), _7176.xy, _7176.zw), _6992).xy, _6992));
                                        _19750++;
                                        continue;
                                    }
                                }
                                _19754 = _19747 * (_7238 ? 0.0625 : 0.0069444444961845874786376953125);
                                break;
                            } while(false);
                            _19755 = _19754;
                            break;
                        }
                        uint _7002 = _6797 - _6898;
                        if (_7002 >= uint(_291._m21.w))
                        {
                            _19755 = 1.0;
                            break;
                        }
                        float _7023 = _291._m27[_7002].w * length(in.m_1840 - _291._m27[_7002].xyz);
                        float3 _7041 = ((in.m_1840 + (_4589 * (_7023 * _291._m25.x))) + (_6831 * (_7023 * _291._m25.y))) - _291._m27[_7002].xyz;
                        float3 _7043 = abs(_7041);
                        float _7045 = _7043.x;
                        float _7047 = _7043.y;
                        bool _7048 = _7045 >= _7047;
                        bool _7056;
                        if (_7048)
                        {
                            _7056 = _7045 >= _7043.z;
                        }
                        else
                        {
                            _7056 = _7048;
                        }
                        float _19729;
                        int _19731;
                        if (_7056)
                        {
                            _19731 = (_7041.x > 0.0) ? 0 : 1;
                            _19729 = _7045;
                        }
                        else
                        {
                            float _7068 = _7043.z;
                            bool _7069 = _7047 >= _7068;
                            int _19732;
                            if (_7069)
                            {
                                _19732 = (_7041.y > 0.0) ? 2 : 3;
                            }
                            else
                            {
                                _19732 = (_7041.z > 0.0) ? 4 : 5;
                            }
                            _19731 = _19732;
                            _19729 = _7069 ? _7047 : _7068;
                        }
                        if (_19729 <= 0.0)
                        {
                            _19755 = 1.0;
                            break;
                        }
                        float2 _7106 = float2(dot(_7041, _969[_19731]), dot(_7041, _978[_19731])) / float2(_19729 * _291._m24.z);
                        float _7113 = _291._m28[_7002].z + (_291._m28[_7002].w / _19729);
                        if (_7113 > 1.0)
                        {
                            _19755 = 1.0;
                            break;
                        }
                        float2 _7131 = _291._m28[_7002].xy + (float2(float(spvSMod(_19731, 3)), float(_19731 / 3)) * _291._m24.xy);
                        float2 _7371 = _291._m22.xy * 0.5;
                        float2 _7376 = _7131 + (float2(0.5 + (0.5 * _7106.x), 0.5 - (0.5 * _7106.y)) * _291._m24.xy);
                        float4 _7389 = float4(_7131 + _7371, (_7131 + _291._m24.xy) - _7371);
                        float _19743;
                        do
                        {
                            int _7415 = int(_291._m22.z);
                            if (_7415 <= 0)
                            {
                                _19743 = spvDepthCast(_311).sample_compare(_311Smplr, float3(fast::clamp(_7376, _7389.xy, _7389.zw), _7113).xy, _7113);
                                break;
                            }
                            float2 _7438 = (_7376 / _291._m22.xy) + float2(0.5);
                            float2 _7439 = floor(_7438);
                            float2 _7444 = _7438 - _7439;
                            float2 _7447 = _7439 - float2(0.5);
                            bool _7451 = _7415 == 1;
                            if (_7451)
                            {
                                float2 _7454 = _7444 * 2.0;
                                _7399[0] = float2(3.0) - _7454;
                                _7399[1] = float2(1.0) + _7454;
                                _7400[0] = ((float2(2.0) - _7444) / _7399[0]) - float2(1.0);
                                _7400[1] = (_7444 / _7399[1]) + float2(1.0);
                            }
                            else
                            {
                                float2 _7481 = _7444 * 3.0;
                                _7399[0] = float2(4.0) - _7481;
                                _7399[1] = float2(7.0);
                                _7399[2] = float2(1.0) + _7481;
                                _7400[0] = ((float2(3.0) - (_7444 * 2.0)) / _7399[0]) - float2(2.0);
                                _7400[1] = (float2(3.0) + _7444) / _7399[1];
                                _7400[2] = (_7444 / _7399[2]) + float2(2.0);
                            }
                            int _20076 = _7451 ? 2 : 3;
                            int _19733;
                            float _19736;
                            _19736 = 0.0;
                            _19733 = 0;
                            float _19742;
                            for (; _19733 < _20076; _19736 = _19742, _19733++)
                            {
                                _19742 = _19736;
                                for (int _19739 = 0; _19739 < _20076; )
                                {
                                    _19742 += ((_7399[_19739].x * _7399[_19733].y) * spvDepthCast(_311).sample_compare(_311Smplr, float3(fast::clamp(_291._m22.xy * (_7447 + float2(_7400[_19739].x, _7400[_19733].y)), _7389.xy, _7389.zw), _7113).xy, _7113));
                                    _19739++;
                                    continue;
                                }
                            }
                            _19743 = _19736 * (_7451 ? 0.0625 : 0.0069444444961845874786376953125);
                            break;
                        } while(false);
                        _19755 = _19743;
                        break;
                    } while(false);
                    _19809 = _6862 * _19755;
                }
                else
                {
                    _19809 = _6862;
                }
                float _4763 = dot(_18776, _6831);
                _4792 = _19406 + (((_18771 * fast::max(_4763, 0.0)) * _19809) + (_19809 * ((powr(fast::max(dot(_18776, fast::normalize(_6831 + _4578)), 0.0), _1678._m1.w) * _1678._m1.z) * step(0.0, _4763))));
            }
            _19405 = _19406;
        }
        else
        {
            _19405 = _4712;
        }
        _19544 = float3(0.0);
        _19404 = _19405;
    }
    else
    {
        float4 _4802 = _4797.sample(_1328, _4356);
        float _4809 = fast::clamp(_1678._m4.x * _4802.z, 0.0, 1.0);
        float _4816 = fast::clamp(_1678._m4.y * _4802.y, 0.04500000178813934326171875, 1.0);
        float _18805;
        float _18806;
        if (_18709 > 0.0)
        {
            _18806 = mix(_4809, _18742.y, _18709);
            _18805 = mix(_4816, fast::max(_18742.x, 0.04500000178813934326171875), _18709);
        }
        else
        {
            _18806 = _4809;
            _18805 = _4816;
        }
        float3 _19407;
        float3 _19549;
        if (_2077._m1.z > 0.5)
        {
            float2 _7684 = (in.m_3779 - float2(0.5)) * 2.0;
            float _7686 = length(_7684);
            bool _7692 = _7686 > 1.0;
            float2 _19296;
            if (_7692)
            {
                _19296 = _7684 / float2(_7686);
            }
            else
            {
                _19296 = _7684;
            }
            float3 _8191;
            float3 _19297;
            do
            {
                float _8151 = asin(fast::min(length(_19296), 1.0));
                float _8154 = asin(fast::clamp(_2077._m4.w, 0.0500000007450580596923828125, 0.949999988079071044921875));
                float _8158 = fast::min(_8151 / _8154, 1.0);
                float _8162 = 1.0 - (_8158 * _8158);
                float _8174 = precise::atan2(_19296.y, _19296.x + 9.999999717180685365747194737196e-10);
                float _8176 = sin(_8151);
                float _8178 = cos(_8174);
                float _8183 = sin(_8174);
                float _8186 = cos(_8151);
                float3 _8187 = float3(_8176 * _8178, _8176 * _8183, _8186);
                float _8190 = 1.0 + ((0.07999999821186065673828125 * _8162) * _8162);
                _8191 = _8187 * _8190;
                if (_8151 >= _8154)
                {
                    _19297 = _8187;
                    break;
                }
                _19297 = fast::normalize(_8187 + ((float3(_8186 * _8178, _8186 * _8183, -_8176) * (((0.319999992847442626953125 * _8158) * _8162) / _8154)) / float3(_8190)));
                break;
            } while(false);
            float3 _19298;
            if (_7692)
            {
                _19298 = float3(_19297.xy, -_19297.z);
            }
            else
            {
                _19298 = _19297;
            }
            float3 _19301;
            float3 _19302;
            float3 _19303;
            if (dot(in.m_1754.xyz, in.m_1754.xyz) < 9.9999999600419720025001879548654e-13)
            {
                float3 _7728 = fast::normalize(cross(_4589, float3(1.0, 0.0, 0.0)) + float3(0.0, 9.9999997473787516355514526367188e-05, 0.0));
                _19303 = _4589;
                _19302 = _7728;
                _19301 = cross(_7728, _4589);
            }
            else
            {
                float3 _7734 = fast::normalize(in.m_1754.xyz);
                float3 _7740 = _4589 - (_7734 * _19298.x);
                float _7742 = length(_7740);
                float2 _7750 = _19298.yz / float2(fast::max(length(_19298.yz), 9.9999999747524270787835121154785e-07));
                float3 _19299;
                if (_7742 > 9.9999999747524270787835121154785e-07)
                {
                    _19299 = _7740 / float3(_7742);
                }
                else
                {
                    _19299 = _4589;
                }
                float3 _7764 = cross(_7734, _19299);
                float _7766 = _7750.x;
                float _7770 = _7750.y;
                _19303 = (_19299 * _7770) + (_7764 * _7766);
                _19302 = (_19299 * _7766) - (_7764 * _7770);
                _19301 = _7734;
            }
            float _7796 = 1.08000004291534423828125 - _2077._m6.z;
            bool _7798 = _7686 < 1.0;
            bool _7805;
            if (_7798)
            {
                _7805 = _8191.z > _7796;
            }
            else
            {
                _7805 = _7798;
            }
            float3 _19308;
            float _19312;
            float _19314;
            if (_7805)
            {
                float3 _7810 = refract(-float3(dot(_4578, _19301), dot(_4578, _19302), dot(_4578, _19303)), _19298, 0.7485029697418212890625);
                float _7813 = _7810.z;
                float2 _19307;
                if (_7813 < (-0.001000000047497451305389404296875))
                {
                    _19307 = _8191.xy + (_7810.xy * ((_7796 - _8191.z) / _7813));
                }
                else
                {
                    _19307 = _7684;
                }
                float _7835 = length(_19307);
                float _7836 = smoothstep(_2077._m4.w - 0.0350000001490116119384765625, _2077._m4.w + 0.014999999664723873138427734375, _7835);
                float _8248 = _7835 / _2077._m4.w;
                float _8254 = precise::atan2(_19307.y, _19307.x + 9.999999717180685365747194737196e-10);
                float2 _8259 = float2(cos(_8254), sin(_8254));
                float3 _8266 = float3(_8259 * 26.0, _8248 * 2.2000000476837158203125);
                float3 _8351 = floor(_8266);
                float3 _8354 = _8266 - _8351;
                float3 _8362 = (_8354 * _8354) * (float3(3.0) - (_8354 * 2.0));
                uint3 _8429 = uint3(int3(_8351));
                uint _8442 = (((_8429.x * 1597334677u) ^ (_8429.y * 3812015801u)) ^ (_8429.z * 2798796415u)) * 1597334677u;
                uint3 _8457 = uint3(int3(_8351 + float3(1.0, 0.0, 0.0)));
                uint _8470 = (((_8457.x * 1597334677u) ^ (_8457.y * 3812015801u)) ^ (_8457.z * 2798796415u)) * 1597334677u;
                float _8371 = _8362.x;
                uint3 _8485 = uint3(int3(_8351 + float3(0.0, 1.0, 0.0)));
                uint _8498 = (((_8485.x * 1597334677u) ^ (_8485.y * 3812015801u)) ^ (_8485.z * 2798796415u)) * 1597334677u;
                uint3 _8513 = uint3(int3(_8351 + float3(1.0, 1.0, 0.0)));
                uint _8526 = (((_8513.x * 1597334677u) ^ (_8513.y * 3812015801u)) ^ (_8513.z * 2798796415u)) * 1597334677u;
                float _8387 = _8362.y;
                uint3 _8541 = uint3(int3(_8351 + float3(0.0, 0.0, 1.0)));
                uint _8554 = (((_8541.x * 1597334677u) ^ (_8541.y * 3812015801u)) ^ (_8541.z * 2798796415u)) * 1597334677u;
                uint3 _8569 = uint3(int3(_8351 + float3(1.0, 0.0, 1.0)));
                uint _8582 = (((_8569.x * 1597334677u) ^ (_8569.y * 3812015801u)) ^ (_8569.z * 2798796415u)) * 1597334677u;
                uint3 _8597 = uint3(int3(_8351 + float3(0.0, 1.0, 1.0)));
                uint _8610 = (((_8597.x * 1597334677u) ^ (_8597.y * 3812015801u)) ^ (_8597.z * 2798796415u)) * 1597334677u;
                uint3 _8625 = uint3(int3(_8351 + float3(1.0)));
                uint _8638 = (((_8625.x * 1597334677u) ^ (_8625.y * 3812015801u)) ^ (_8625.z * 2798796415u)) * 1597334677u;
                float3 _8276 = float3(_8259 * 61.0, (_8248 * 4.0) + 7.0);
                float3 _8664 = floor(_8276);
                float3 _8667 = _8276 - _8664;
                float3 _8675 = (_8667 * _8667) * (float3(3.0) - (_8667 * 2.0));
                uint3 _8742 = uint3(int3(_8664));
                uint _8755 = (((_8742.x * 1597334677u) ^ (_8742.y * 3812015801u)) ^ (_8742.z * 2798796415u)) * 1597334677u;
                uint3 _8770 = uint3(int3(_8664 + float3(1.0, 0.0, 0.0)));
                uint _8783 = (((_8770.x * 1597334677u) ^ (_8770.y * 3812015801u)) ^ (_8770.z * 2798796415u)) * 1597334677u;
                float _8684 = _8675.x;
                uint3 _8798 = uint3(int3(_8664 + float3(0.0, 1.0, 0.0)));
                uint _8811 = (((_8798.x * 1597334677u) ^ (_8798.y * 3812015801u)) ^ (_8798.z * 2798796415u)) * 1597334677u;
                uint3 _8826 = uint3(int3(_8664 + float3(1.0, 1.0, 0.0)));
                uint _8839 = (((_8826.x * 1597334677u) ^ (_8826.y * 3812015801u)) ^ (_8826.z * 2798796415u)) * 1597334677u;
                float _8700 = _8675.y;
                uint3 _8854 = uint3(int3(_8664 + float3(0.0, 0.0, 1.0)));
                uint _8867 = (((_8854.x * 1597334677u) ^ (_8854.y * 3812015801u)) ^ (_8854.z * 2798796415u)) * 1597334677u;
                uint3 _8882 = uint3(int3(_8664 + float3(1.0, 0.0, 1.0)));
                uint _8895 = (((_8882.x * 1597334677u) ^ (_8882.y * 3812015801u)) ^ (_8882.z * 2798796415u)) * 1597334677u;
                uint3 _8910 = uint3(int3(_8664 + float3(0.0, 1.0, 1.0)));
                uint _8923 = (((_8910.x * 1597334677u) ^ (_8910.y * 3812015801u)) ^ (_8910.z * 2798796415u)) * 1597334677u;
                uint3 _8938 = uint3(int3(_8664 + float3(1.0)));
                uint _8951 = (((_8938.x * 1597334677u) ^ (_8938.y * 3812015801u)) ^ (_8938.z * 2798796415u)) * 1597334677u;
                float3 _8287 = float3(_8259 * 9.0, (_8248 * 7.0) + 3.0);
                float3 _8977 = floor(_8287);
                float3 _8980 = _8287 - _8977;
                float3 _8988 = (_8980 * _8980) * (float3(3.0) - (_8980 * 2.0));
                uint3 _9055 = uint3(int3(_8977));
                uint _9068 = (((_9055.x * 1597334677u) ^ (_9055.y * 3812015801u)) ^ (_9055.z * 2798796415u)) * 1597334677u;
                uint3 _9083 = uint3(int3(_8977 + float3(1.0, 0.0, 0.0)));
                uint _9096 = (((_9083.x * 1597334677u) ^ (_9083.y * 3812015801u)) ^ (_9083.z * 2798796415u)) * 1597334677u;
                float _8997 = _8988.x;
                uint3 _9111 = uint3(int3(_8977 + float3(0.0, 1.0, 0.0)));
                uint _9124 = (((_9111.x * 1597334677u) ^ (_9111.y * 3812015801u)) ^ (_9111.z * 2798796415u)) * 1597334677u;
                uint3 _9139 = uint3(int3(_8977 + float3(1.0, 1.0, 0.0)));
                uint _9152 = (((_9139.x * 1597334677u) ^ (_9139.y * 3812015801u)) ^ (_9139.z * 2798796415u)) * 1597334677u;
                float _9013 = _8988.y;
                uint3 _9167 = uint3(int3(_8977 + float3(0.0, 0.0, 1.0)));
                uint _9180 = (((_9167.x * 1597334677u) ^ (_9167.y * 3812015801u)) ^ (_9167.z * 2798796415u)) * 1597334677u;
                uint3 _9195 = uint3(int3(_8977 + float3(1.0, 0.0, 1.0)));
                uint _9208 = (((_9195.x * 1597334677u) ^ (_9195.y * 3812015801u)) ^ (_9195.z * 2798796415u)) * 1597334677u;
                uint3 _9223 = uint3(int3(_8977 + float3(0.0, 1.0, 1.0)));
                uint _9236 = (((_9223.x * 1597334677u) ^ (_9223.y * 3812015801u)) ^ (_9223.z * 2798796415u)) * 1597334677u;
                uint3 _9251 = uint3(int3(_8977 + float3(1.0)));
                uint _9264 = (((_9251.x * 1597334677u) ^ (_9251.y * 3812015801u)) ^ (_9251.z * 2798796415u)) * 1597334677u;
                float _8291 = 1.10000002384185791015625 * ((mix(mix(mix(float((_8442 ^ (_8442 >> uint(16))) & 65535u) * 1.525902189314365386962890625e-05, float((_8470 ^ (_8470 >> uint(16))) & 65535u) * 1.525902189314365386962890625e-05, _8371), mix(float((_8498 ^ (_8498 >> uint(16))) & 65535u) * 1.525902189314365386962890625e-05, float((_8526 ^ (_8526 >> uint(16))) & 65535u) * 1.525902189314365386962890625e-05, _8371), _8387), mix(mix(float((_8554 ^ (_8554 >> uint(16))) & 65535u) * 1.525902189314365386962890625e-05, float((_8582 ^ (_8582 >> uint(16))) & 65535u) * 1.525902189314365386962890625e-05, _8371), mix(float((_8610 ^ (_8610 >> uint(16))) & 65535u) * 1.525902189314365386962890625e-05, float((_8638 ^ (_8638 >> uint(16))) & 65535u) * 1.525902189314365386962890625e-05, _8371), _8387), _8362.z) * 0.64999997615814208984375) + (mix(mix(mix(float((_8755 ^ (_8755 >> uint(16))) & 65535u) * 1.525902189314365386962890625e-05, float((_8783 ^ (_8783 >> uint(16))) & 65535u) * 1.525902189314365386962890625e-05, _8684), mix(float((_8811 ^ (_8811 >> uint(16))) & 65535u) * 1.525902189314365386962890625e-05, float((_8839 ^ (_8839 >> uint(16))) & 65535u) * 1.525902189314365386962890625e-05, _8684), _8700), mix(mix(float((_8867 ^ (_8867 >> uint(16))) & 65535u) * 1.525902189314365386962890625e-05, float((_8895 ^ (_8895 >> uint(16))) & 65535u) * 1.525902189314365386962890625e-05, _8684), mix(float((_8923 ^ (_8923 >> uint(16))) & 65535u) * 1.525902189314365386962890625e-05, float((_8951 ^ (_8951 >> uint(16))) & 65535u) * 1.525902189314365386962890625e-05, _8684), _8700), _8675.z) * 0.3499999940395355224609375));
                float3 _8314 = mix((_2077._m4.xyz * (0.449999988079071044921875 + _8291)) * mix(0.550000011920928955078125, 1.0, smoothstep(0.25, 0.550000011920928955078125, mix(mix(mix(float((_9068 ^ (_9068 >> uint(16))) & 65535u) * 1.525902189314365386962890625e-05, float((_9096 ^ (_9096 >> uint(16))) & 65535u) * 1.525902189314365386962890625e-05, _8997), mix(float((_9124 ^ (_9124 >> uint(16))) & 65535u) * 1.525902189314365386962890625e-05, float((_9152 ^ (_9152 >> uint(16))) & 65535u) * 1.525902189314365386962890625e-05, _8997), _9013), mix(mix(float((_9180 ^ (_9180 >> uint(16))) & 65535u) * 1.525902189314365386962890625e-05, float((_9208 ^ (_9208 >> uint(16))) & 65535u) * 1.525902189314365386962890625e-05, _8997), mix(float((_9236 ^ (_9236 >> uint(16))) & 65535u) * 1.525902189314365386962890625e-05, float((_9264 ^ (_9264 >> uint(16))) & 65535u) * 1.525902189314365386962890625e-05, _8997), _9013), _8988.z))), (_2077._m4.xyz * 1.7000000476837158203125) + float3(0.0500000007450580596923828125, 0.0350000001490116119384765625, 0.0), float3(exp(-powr((_8248 - (_2077._m5.w + 0.17000000178813934326171875)) * 11.111110687255859375, 2.0)) * 0.550000011920928955078125));
                float2 _9294 = _7684 / float2(fast::max(_7686, 9.9999997473787516355514526367188e-05));
                float3 _9302 = float3(_9294 * 6.0, (_7686 * 2.2000000476837158203125) + 1.7000000476837158203125);
                float3 _9363 = floor(_9302);
                float3 _9366 = _9302 - _9363;
                float3 _9374 = (_9366 * _9366) * (float3(3.0) - (_9366 * 2.0));
                uint3 _9441 = uint3(int3(_9363));
                uint _9454 = (((_9441.x * 1597334677u) ^ (_9441.y * 3812015801u)) ^ (_9441.z * 2798796415u)) * 1597334677u;
                uint3 _9469 = uint3(int3(_9363 + float3(1.0, 0.0, 0.0)));
                uint _9482 = (((_9469.x * 1597334677u) ^ (_9469.y * 3812015801u)) ^ (_9469.z * 2798796415u)) * 1597334677u;
                float _9383 = _9374.x;
                uint3 _9497 = uint3(int3(_9363 + float3(0.0, 1.0, 0.0)));
                uint _9510 = (((_9497.x * 1597334677u) ^ (_9497.y * 3812015801u)) ^ (_9497.z * 2798796415u)) * 1597334677u;
                uint3 _9525 = uint3(int3(_9363 + float3(1.0, 1.0, 0.0)));
                uint _9538 = (((_9525.x * 1597334677u) ^ (_9525.y * 3812015801u)) ^ (_9525.z * 2798796415u)) * 1597334677u;
                float _9399 = _9374.y;
                uint3 _9553 = uint3(int3(_9363 + float3(0.0, 0.0, 1.0)));
                uint _9566 = (((_9553.x * 1597334677u) ^ (_9553.y * 3812015801u)) ^ (_9553.z * 2798796415u)) * 1597334677u;
                uint3 _9581 = uint3(int3(_9363 + float3(1.0, 0.0, 1.0)));
                uint _9594 = (((_9581.x * 1597334677u) ^ (_9581.y * 3812015801u)) ^ (_9581.z * 2798796415u)) * 1597334677u;
                uint3 _9609 = uint3(int3(_9363 + float3(0.0, 1.0, 1.0)));
                uint _9622 = (((_9609.x * 1597334677u) ^ (_9609.y * 3812015801u)) ^ (_9609.z * 2798796415u)) * 1597334677u;
                uint3 _9637 = uint3(int3(_9363 + float3(1.0)));
                uint _9650 = (((_9637.x * 1597334677u) ^ (_9637.y * 3812015801u)) ^ (_9637.z * 2798796415u)) * 1597334677u;
                float3 _9311 = float3(_9294 * 15.0, (_7686 * 5.0) + 9.30000019073486328125);
                float3 _9676 = floor(_9311);
                float3 _9679 = _9311 - _9676;
                float3 _9687 = (_9679 * _9679) * (float3(3.0) - (_9679 * 2.0));
                uint3 _9754 = uint3(int3(_9676));
                uint _9767 = (((_9754.x * 1597334677u) ^ (_9754.y * 3812015801u)) ^ (_9754.z * 2798796415u)) * 1597334677u;
                uint3 _9782 = uint3(int3(_9676 + float3(1.0, 0.0, 0.0)));
                uint _9795 = (((_9782.x * 1597334677u) ^ (_9782.y * 3812015801u)) ^ (_9782.z * 2798796415u)) * 1597334677u;
                float _9696 = _9687.x;
                uint3 _9810 = uint3(int3(_9676 + float3(0.0, 1.0, 0.0)));
                uint _9823 = (((_9810.x * 1597334677u) ^ (_9810.y * 3812015801u)) ^ (_9810.z * 2798796415u)) * 1597334677u;
                uint3 _9838 = uint3(int3(_9676 + float3(1.0, 1.0, 0.0)));
                uint _9851 = (((_9838.x * 1597334677u) ^ (_9838.y * 3812015801u)) ^ (_9838.z * 2798796415u)) * 1597334677u;
                float _9712 = _9687.y;
                uint3 _9866 = uint3(int3(_9676 + float3(0.0, 0.0, 1.0)));
                uint _9879 = (((_9866.x * 1597334677u) ^ (_9866.y * 3812015801u)) ^ (_9866.z * 2798796415u)) * 1597334677u;
                uint3 _9894 = uint3(int3(_9676 + float3(1.0, 0.0, 1.0)));
                uint _9907 = (((_9894.x * 1597334677u) ^ (_9894.y * 3812015801u)) ^ (_9894.z * 2798796415u)) * 1597334677u;
                uint3 _9922 = uint3(int3(_9676 + float3(0.0, 1.0, 1.0)));
                uint _9935 = (((_9922.x * 1597334677u) ^ (_9922.y * 3812015801u)) ^ (_9922.z * 2798796415u)) * 1597334677u;
                uint3 _9950 = uint3(int3(_9676 + float3(1.0)));
                uint _9963 = (((_9950.x * 1597334677u) ^ (_9950.y * 3812015801u)) ^ (_9950.z * 2798796415u)) * 1597334677u;
                float _9328 = (0.5 * powr(1.0 - abs((2.0 * mix(mix(mix(float((_9767 ^ (_9767 >> uint(16))) & 65535u) * 1.525902189314365386962890625e-05, float((_9795 ^ (_9795 >> uint(16))) & 65535u) * 1.525902189314365386962890625e-05, _9696), mix(float((_9823 ^ (_9823 >> uint(16))) & 65535u) * 1.525902189314365386962890625e-05, float((_9851 ^ (_9851 >> uint(16))) & 65535u) * 1.525902189314365386962890625e-05, _9696), _9712), mix(mix(float((_9879 ^ (_9879 >> uint(16))) & 65535u) * 1.525902189314365386962890625e-05, float((_9907 ^ (_9907 >> uint(16))) & 65535u) * 1.525902189314365386962890625e-05, _9696), mix(float((_9935 ^ (_9935 >> uint(16))) & 65535u) * 1.525902189314365386962890625e-05, float((_9963 ^ (_9963 >> uint(16))) & 65535u) * 1.525902189314365386962890625e-05, _9696), _9712), _9687.z)) - 1.0), 30.0)) * smoothstep(0.60000002384185791015625, 0.89999997615814208984375, _7686);
                float _9337 = (powr(1.0 - abs((2.0 * mix(mix(mix(float((_9454 ^ (_9454 >> uint(16))) & 65535u) * 1.525902189314365386962890625e-05, float((_9482 ^ (_9482 >> uint(16))) & 65535u) * 1.525902189314365386962890625e-05, _9383), mix(float((_9510 ^ (_9510 >> uint(16))) & 65535u) * 1.525902189314365386962890625e-05, float((_9538 ^ (_9538 >> uint(16))) & 65535u) * 1.525902189314365386962890625e-05, _9383), _9399), mix(mix(float((_9566 ^ (_9566 >> uint(16))) & 65535u) * 1.525902189314365386962890625e-05, float((_9594 ^ (_9594 >> uint(16))) & 65535u) * 1.525902189314365386962890625e-05, _9383), mix(float((_9622 ^ (_9622 >> uint(16))) & 65535u) * 1.525902189314365386962890625e-05, float((_9650 ^ (_9650 >> uint(16))) & 65535u) * 1.525902189314365386962890625e-05, _9383), _9399), _9374.z)) - 1.0), 24.0) + _9328) * smoothstep(_2077._m4.w + 0.07999999821186065673828125, 0.949999988079071044921875, _7686);
                _19314 = _7836;
                _19312 = 1.0 - _7836;
                _19308 = mix(mix(float3(0.0040000001899898052215576171875), _8314 * (1.0 - ((_2077._m6.x * 0.85000002384185791015625) * smoothstep(0.7200000286102294921875, 1.0, _8248))), float3(smoothstep(_2077._m5.w - 0.02500000037252902984619140625, _2077._m5.w + 0.02500000037252902984619140625, _8248))), mix(_2077._m5.xyz * mix(float3(1.0), float3(1.019999980926513671875, 0.86000001430511474609375, 0.819999992847442626953125), float3(smoothstep(0.449999988079071044921875, 1.0, _7686))), float3(0.5, 0.070000000298023223876953125, 0.0599999986588954925537109375), float3(fast::clamp((_9337 * _2077._m6.y) * 1.39999997615814208984375, 0.0, 0.800000011920928955078125))) * (1.0 - (0.60000002384185791015625 * _2077._m6.x)), float3(_7836));
            }
            else
            {
                float2 _9993 = _7684 / float2(fast::max(_7686, 9.9999997473787516355514526367188e-05));
                float3 _10001 = float3(_9993 * 6.0, (_7686 * 2.2000000476837158203125) + 1.7000000476837158203125);
                float3 _10062 = floor(_10001);
                float3 _10065 = _10001 - _10062;
                float3 _10073 = (_10065 * _10065) * (float3(3.0) - (_10065 * 2.0));
                uint3 _10140 = uint3(int3(_10062));
                uint _10153 = (((_10140.x * 1597334677u) ^ (_10140.y * 3812015801u)) ^ (_10140.z * 2798796415u)) * 1597334677u;
                uint3 _10168 = uint3(int3(_10062 + float3(1.0, 0.0, 0.0)));
                uint _10181 = (((_10168.x * 1597334677u) ^ (_10168.y * 3812015801u)) ^ (_10168.z * 2798796415u)) * 1597334677u;
                float _10082 = _10073.x;
                uint3 _10196 = uint3(int3(_10062 + float3(0.0, 1.0, 0.0)));
                uint _10209 = (((_10196.x * 1597334677u) ^ (_10196.y * 3812015801u)) ^ (_10196.z * 2798796415u)) * 1597334677u;
                uint3 _10224 = uint3(int3(_10062 + float3(1.0, 1.0, 0.0)));
                uint _10237 = (((_10224.x * 1597334677u) ^ (_10224.y * 3812015801u)) ^ (_10224.z * 2798796415u)) * 1597334677u;
                float _10098 = _10073.y;
                uint3 _10252 = uint3(int3(_10062 + float3(0.0, 0.0, 1.0)));
                uint _10265 = (((_10252.x * 1597334677u) ^ (_10252.y * 3812015801u)) ^ (_10252.z * 2798796415u)) * 1597334677u;
                uint3 _10280 = uint3(int3(_10062 + float3(1.0, 0.0, 1.0)));
                uint _10293 = (((_10280.x * 1597334677u) ^ (_10280.y * 3812015801u)) ^ (_10280.z * 2798796415u)) * 1597334677u;
                uint3 _10308 = uint3(int3(_10062 + float3(0.0, 1.0, 1.0)));
                uint _10321 = (((_10308.x * 1597334677u) ^ (_10308.y * 3812015801u)) ^ (_10308.z * 2798796415u)) * 1597334677u;
                uint3 _10336 = uint3(int3(_10062 + float3(1.0)));
                uint _10349 = (((_10336.x * 1597334677u) ^ (_10336.y * 3812015801u)) ^ (_10336.z * 2798796415u)) * 1597334677u;
                float3 _10010 = float3(_9993 * 15.0, (_7686 * 5.0) + 9.30000019073486328125);
                float3 _10375 = floor(_10010);
                float3 _10378 = _10010 - _10375;
                float3 _10386 = (_10378 * _10378) * (float3(3.0) - (_10378 * 2.0));
                uint3 _10453 = uint3(int3(_10375));
                uint _10466 = (((_10453.x * 1597334677u) ^ (_10453.y * 3812015801u)) ^ (_10453.z * 2798796415u)) * 1597334677u;
                uint3 _10481 = uint3(int3(_10375 + float3(1.0, 0.0, 0.0)));
                uint _10494 = (((_10481.x * 1597334677u) ^ (_10481.y * 3812015801u)) ^ (_10481.z * 2798796415u)) * 1597334677u;
                float _10395 = _10386.x;
                uint3 _10509 = uint3(int3(_10375 + float3(0.0, 1.0, 0.0)));
                uint _10522 = (((_10509.x * 1597334677u) ^ (_10509.y * 3812015801u)) ^ (_10509.z * 2798796415u)) * 1597334677u;
                uint3 _10537 = uint3(int3(_10375 + float3(1.0, 1.0, 0.0)));
                uint _10550 = (((_10537.x * 1597334677u) ^ (_10537.y * 3812015801u)) ^ (_10537.z * 2798796415u)) * 1597334677u;
                float _10411 = _10386.y;
                uint3 _10565 = uint3(int3(_10375 + float3(0.0, 0.0, 1.0)));
                uint _10578 = (((_10565.x * 1597334677u) ^ (_10565.y * 3812015801u)) ^ (_10565.z * 2798796415u)) * 1597334677u;
                uint3 _10593 = uint3(int3(_10375 + float3(1.0, 0.0, 1.0)));
                uint _10606 = (((_10593.x * 1597334677u) ^ (_10593.y * 3812015801u)) ^ (_10593.z * 2798796415u)) * 1597334677u;
                uint3 _10621 = uint3(int3(_10375 + float3(0.0, 1.0, 1.0)));
                uint _10634 = (((_10621.x * 1597334677u) ^ (_10621.y * 3812015801u)) ^ (_10621.z * 2798796415u)) * 1597334677u;
                uint3 _10649 = uint3(int3(_10375 + float3(1.0)));
                uint _10662 = (((_10649.x * 1597334677u) ^ (_10649.y * 3812015801u)) ^ (_10649.z * 2798796415u)) * 1597334677u;
                float _10027 = (0.5 * powr(1.0 - abs((2.0 * mix(mix(mix(float((_10466 ^ (_10466 >> uint(16))) & 65535u) * 1.525902189314365386962890625e-05, float((_10494 ^ (_10494 >> uint(16))) & 65535u) * 1.525902189314365386962890625e-05, _10395), mix(float((_10522 ^ (_10522 >> uint(16))) & 65535u) * 1.525902189314365386962890625e-05, float((_10550 ^ (_10550 >> uint(16))) & 65535u) * 1.525902189314365386962890625e-05, _10395), _10411), mix(mix(float((_10578 ^ (_10578 >> uint(16))) & 65535u) * 1.525902189314365386962890625e-05, float((_10606 ^ (_10606 >> uint(16))) & 65535u) * 1.525902189314365386962890625e-05, _10395), mix(float((_10634 ^ (_10634 >> uint(16))) & 65535u) * 1.525902189314365386962890625e-05, float((_10662 ^ (_10662 >> uint(16))) & 65535u) * 1.525902189314365386962890625e-05, _10395), _10411), _10386.z)) - 1.0), 30.0)) * smoothstep(0.60000002384185791015625, 0.89999997615814208984375, _7686);
                float _10036 = (powr(1.0 - abs((2.0 * mix(mix(mix(float((_10153 ^ (_10153 >> uint(16))) & 65535u) * 1.525902189314365386962890625e-05, float((_10181 ^ (_10181 >> uint(16))) & 65535u) * 1.525902189314365386962890625e-05, _10082), mix(float((_10209 ^ (_10209 >> uint(16))) & 65535u) * 1.525902189314365386962890625e-05, float((_10237 ^ (_10237 >> uint(16))) & 65535u) * 1.525902189314365386962890625e-05, _10082), _10098), mix(mix(float((_10265 ^ (_10265 >> uint(16))) & 65535u) * 1.525902189314365386962890625e-05, float((_10293 ^ (_10293 >> uint(16))) & 65535u) * 1.525902189314365386962890625e-05, _10082), mix(float((_10321 ^ (_10321 >> uint(16))) & 65535u) * 1.525902189314365386962890625e-05, float((_10349 ^ (_10349 >> uint(16))) & 65535u) * 1.525902189314365386962890625e-05, _10082), _10098), _10073.z)) - 1.0), 24.0) + _10027) * smoothstep(_2077._m4.w + 0.07999999821186065673828125, 0.949999988079071044921875, _7686);
                _19314 = 1.0;
                _19312 = 0.0;
                _19308 = mix(_2077._m5.xyz * mix(float3(1.0), float3(1.019999980926513671875, 0.86000001430511474609375, 0.819999992847442626953125), float3(smoothstep(0.449999988079071044921875, 1.0, _7686))), float3(0.5, 0.070000000298023223876953125, 0.0599999986588954925537109375), float3(fast::clamp((_10036 * _2077._m6.y) * 1.39999997615814208984375, 0.0, 0.800000011920928955078125))) * (1.0 - ((_2077._m6.x * 0.3499999940395355224609375) * (1.0 - smoothstep(_2077._m4.w, _2077._m4.w + 0.070000000298023223876953125, _7686))));
            }
            float _7896 = _7684.y;
            float _7911 = _7692 ? 0.20000000298023223876953125 : (((1.0 - (0.64999997615814208984375 * smoothstep(0.449999988079071044921875, 0.949999988079071044921875, abs(_7684.x)))) * (1.0 - (0.449999988079071044921875 * smoothstep(0.1500000059604644775390625, 0.60000002384185791015625, _7896)))) * (1.0 - (0.300000011920928955078125 * smoothstep(0.25, 0.699999988079071044921875, -_7896))));
            float _7913 = mix(1.0, _7911, 0.60000002384185791015625);
            float _7916 = dot(_4589, _4571);
            float3 _7950 = mix(_4589, _19303, float3(_19312));
            float3 _7954 = reflect(-_4578, _4589);
            bool _10679 = _291._m29.x > 0.5;
            float3 _19332;
            float3 _19339;
            if (_10679)
            {
                float _10746 = _7950.x;
                float _10751 = _7950.z;
                float _10753 = (_291._m29.z * _10746) - (_291._m29.w * _10751);
                float _10755 = _7950.y;
                float _10766 = (_291._m29.w * _10746) + (_291._m29.z * _10751);
                float _10784 = 1.09254801273345947265625 * _10753;
                spvUnsafeArray<float, 9> _17832 = spvUnsafeArray<float, 9>({ 0.2820949852466583251953125, 0.48860299587249755859375 * _10755, 0.48860299587249755859375 * _10766, 0.48860299587249755859375 * _10753, _10784 * _10755, (1.09254801273345947265625 * _10755) * _10766, 0.3153919875621795654296875 * (((3.0 * _10766) * _10766) - 1.0), _10784 * _10766, 0.546274006366729736328125 * ((_10753 * _10753) - (_10755 * _10755)) });
                spvUnsafeArray<float, 9> _10698 = _17832;
                float3 _19317;
                _19317 = float3(0.0);
                for (int _19316 = 0; _19316 < 9; )
                {
                    _19317 += (_1326.read(uint2((int2(496, 256) + int2(_19316, 0))), 0).xyz * _10698[_19316]);
                    _19316++;
                    continue;
                }
                float _10879 = _7954.x;
                float _10884 = _7954.z;
                float2 _10916 = float2((precise::atan2((_291._m29.z * _10879) - (_291._m29.w * _10884), -((_291._m29.w * _10879) + (_291._m29.z * _10884))) * 0.15915493667125701904296875) + 0.5, acos(fast::clamp(_7954.y, -1.0, 1.0)) * 0.3183098733425140380859375);
                float2 _10937 = (_10916 * float2(512.0, 256.0)) - float2(0.5);
                float2 _10939 = floor(_10937);
                float2 _10942 = _10937 - _10939;
                int _10945 = int(_10939.x);
                int _10948 = int(_10939.y);
                int _19318;
                if (_10945 < 0)
                {
                    _19318 = _10945 + 512;
                }
                else
                {
                    _19318 = _10945;
                }
                int _19319;
                if (_19318 >= 512)
                {
                    _19319 = _19318 - 512;
                }
                else
                {
                    _19319 = _19318;
                }
                int _10968 = _19319 + 1;
                int _20077 = (_10968 == 512) ? 0 : _10968;
                int _10983 = min((_10948 + 1), 255);
                int _10985 = max(_10948, 0);
                float3 _11038 = float3(_10942.x);
                float2 _11070 = (_10916 * float2(256.0, 128.0)) - float2(0.5);
                float2 _11072 = floor(_11070);
                float2 _11075 = _11070 - _11072;
                int _11078 = int(_11072.x);
                int _11081 = int(_11072.y);
                int _19325;
                if (_11078 < 0)
                {
                    _19325 = _11078 + 256;
                }
                else
                {
                    _19325 = _11078;
                }
                int _19326;
                if (_19325 >= 256)
                {
                    _19326 = _19325 - 256;
                }
                else
                {
                    _19326 = _19325;
                }
                int _11101 = _19326 + 1;
                int _20078 = (_11101 == 256) ? 0 : _11101;
                int _11116 = min((_11081 + 1), 127);
                int _11118 = max(_11081, 0);
                float3 _11171 = float3(_11075.x);
                _19339 = mix(mix(mix(_1326.read(uint2(int2(_19319, _10985)), 0).xyz, _1326.read(uint2(int2(_20077, _10985)), 0).xyz, _11038), mix(_1326.read(uint2(int2(_19319, _10983)), 0).xyz, _1326.read(uint2(int2(_20077, _10983)), 0).xyz, _11038), float3(_10942.y)), mix(mix(_1326.read(uint2((int2(0, 256) + int2(_19326, _11118))), 0).xyz, _1326.read(uint2((int2(0, 256) + int2(_20078, _11118))), 0).xyz, _11171), mix(_1326.read(uint2((int2(0, 256) + int2(_19326, _11116))), 0).xyz, _1326.read(uint2((int2(0, 256) + int2(_20078, _11116))), 0).xyz, _11171), float3(_11075.y)), float3(0.3499999940395355224609375)) * _291._m29.y;
                _19332 = fast::max(_19317, float3(0.0)) * _291._m29.y;
            }
            else
            {
                float3 _11199 = mix(_291._m9.xyz, _291._m8.xyz, float3((_7950.y * 0.5) + 0.5)) * _291._m8.w;
                _19339 = mix(mix(_291._m9.xyz, _291._m8.xyz, float3((_7954.y * 0.5) + 0.5)) * _291._m8.w, _11199, float3(0.070000000298023223876953125));
                _19332 = _11199;
            }
            float3 _7966 = (((float3((fast::max((dot(_19303, _4571) * 0.64999997615814208984375) + (_7916 * 0.3499999940395355224609375), 0.0) * _19312) + (fast::max((_7916 + 0.300000011920928955078125) * 0.769230782985687255859375, 0.0) * _19314)) * _4620) * _18802) * _7913) + ((_19332 * _18804) * _7911);
            float _7970 = fast::max(dot(_4589, _4578), 9.9999997473787516355514526367188e-05);
            float _7976 = fast::clamp(_7916, 0.0, 1.0);
            float _7989 = fast::clamp(dot(_4589, _4583), 0.0, 1.0);
            float _11242 = ((_7989 * _7989) * (-0.999975979328155517578125)) + 1.0;
            float _11266 = sqrt(((_7970 * _7970) * 0.999975979328155517578125) + 2.4009999833651818335056304931641e-05);
            float3 _8007 = ((((((float3(0.02500000037252902984619140625) + (float3(0.97500002384185791015625) * powr(1.0 - fast::clamp(dot(_4578, _4583), 0.0, 1.0), 5.0))) * (1.200499991682590916752815246582e-05 / (((3.1415927410125732421875 * _11242) * _11242) * fast::max((_7976 * _11266) + (_7970 * sqrt(((_7976 * _7976) * 0.999975979328155517578125) + 2.4009999833651818335056304931641e-05)), 9.9999997473787516355514526367188e-06)))) * 3.1415927410125732421875) * _7976) * _4620) * _18802) * _7913;
            float3 _19351;
            float3 _19365;
            if (_291._m13.w > 0.5)
            {
                float2 _11311 = fast::clamp(floor(gl_FragCoord.xy * _291._m12.xy), float2(0.0), _291._m13.xy - float2(1.0));
                uint _11339 = uint((((fast::clamp(floor((log2(fast::max(dot(_291._m11.xyz, in.m_1840) + _291._m11.w, 9.9999999747524270787835121154785e-07)) * _291._m12.z) + _291._m12.w), 0.0, _291._m13.z - 1.0) * _291._m13.y) + _11311.y) * _291._m13.x) + _11311.x);
                uint _11341 = _11339 >> uint(2);
                uint _11343 = _11339 & 3u;
                uint _11347 = _1971._m0[_11341][_11343] & 65535u;
                uint _11349 = _1971._m0[_11341][_11343] >> uint(16);
                float3 _19352;
                float3 _19366;
                _19366 = _7966;
                _19352 = _8007;
                for (uint _19348 = _11347; _19348 < (_11347 + _11349); )
                {
                    uint _11355 = _19348 / 3u;
                    uint _11368 = (_1992._m0[_11355 >> uint(2)][_11355 & 3u] >> ((_19348 - (_11355 * 3u)) * 10u)) & 1023u;
                    float3 _11385 = _1833._m0[_11368].xyz - in.m_1840;
                    float _11388 = dot(_11385, _11385);
                    float _11392 = _11388 * _1833._m0[_11368].w;
                    float _11397 = fast::clamp(1.0 - (_11392 * _11392), 0.0, 1.0);
                    float3 _11402 = _11385 * rsqrt(fast::max(_11388, 9.9999999392252902907785028219223e-09));
                    float _11420 = fast::clamp((dot(-_11402, _1876._m0[_11368].xyz) * _1868._m0[_11368].w) + _1876._m0[_11368].w, 0.0, 1.0);
                    float3 _8033 = (_1868._m0[_11368].xyz * ((((_11397 * _11397) * _11420) * _11420) / fast::max(_11388, 9.9999997473787516355514526367188e-05))) * _7913;
                    float _8037 = dot(_4589, _11402);
                    float3 _8068 = fast::normalize(_11402 + _4578);
                    float _8070 = fast::clamp(_8037, 0.0, 1.0);
                    float _8083 = fast::clamp(dot(_4589, _8068), 0.0, 1.0);
                    float _11459 = ((_8083 * _8083) * (-0.999975979328155517578125)) + 1.0;
                    _19366 += (float3((fast::max((dot(_19303, _11402) * 0.64999997615814208984375) + (_8037 * 0.3499999940395355224609375), 0.0) * _19312) + (fast::max((_8037 + 0.300000011920928955078125) * 0.769230782985687255859375, 0.0) * _19314)) * _8033);
                    _19352 += (((((float3(0.02500000037252902984619140625) + (float3(0.97500002384185791015625) * powr(1.0 - fast::clamp(dot(_4578, _8068), 0.0, 1.0), 5.0))) * (1.200499991682590916752815246582e-05 / (((3.1415927410125732421875 * _11459) * _11459) * fast::max((_8070 * _11266) + (_7970 * sqrt(((_8070 * _8070) * 0.999975979328155517578125) + 2.4009999833651818335056304931641e-05)), 9.9999997473787516355514526367188e-06)))) * 3.1415927410125732421875) * _8070) * _8033);
                    _19348++;
                    continue;
                }
                _19365 = _19366;
                _19351 = _19352;
            }
            else
            {
                _19365 = _7966;
                _19351 = _8007;
            }
            float2 _19349;
            if (_10679)
            {
                _19349 = _1432.sample(_1434, (((float2(_7970, 0.070000000298023223876953125) * 31.0) + float2(0.5)) * float2(0.03125))).xy;
            }
            else
            {
                _19349 = (float2(-1.03999996185302734375, 1.03999996185302734375) * ((fast::min(0.86489999294281005859375, exp2((-9.27999973297119140625) * _7970)) * 0.930000007152557373046875) + 0.0405750013887882232666015625)) + float2(0.9999599456787109375, -0.0384599976241588592529296875);
            }
            float3 _8115 = (float3(0.02500000037252902984619140625) * _19349.x) + float3(_19349.y);
            float3 _8123 = _19351 + ((_8115 * _19339) * mix(1.0, _7911, 0.699999988079071044921875));
            _19549 = _8123;
            _19407 = (((_19308 * _18771) * _19365) * (float3(1.0) - _8115)) + _8123;
        }
        else
        {
            float3 _18807;
            do
            {
                if ((_2077._m3.x <= 0.0) || (_2077._m3.y <= 0.0))
                {
                    _18807 = _18776;
                    break;
                }
                float3 _12069 = dfdx(in.m_1783);
                float3 _12071 = dfdy(in.m_1783);
                float _12078 = fast::max(length(_12069), length(_12071)) * _2077._m3.y;
                float _12081 = 1.0 - smoothstep(0.25, 0.699999988079071044921875, _12078);
                if (_12081 <= 0.0)
                {
                    _18807 = _18776;
                    break;
                }
                float3 _12089 = in.m_1783 * _2077._m3.y;
                float3 _12200 = floor(_12089);
                float3 _12203 = _12089 - _12200;
                float3 _12211 = (_12203 * _12203) * (float3(3.0) - (_12203 * 2.0));
                uint3 _12410 = uint3(int3(_12200));
                uint _12423 = (((_12410.x * 1597334677u) ^ (_12410.y * 3812015801u)) ^ (_12410.z * 2798796415u)) * 1597334677u;
                float _12430 = float((_12423 ^ (_12423 >> uint(16))) & 65535u);
                float _12431 = _12430 * 1.525902189314365386962890625e-05;
                uint3 _12438 = uint3(int3(_12200 + float3(1.0, 0.0, 0.0)));
                uint _12451 = (((_12438.x * 1597334677u) ^ (_12438.y * 3812015801u)) ^ (_12438.z * 2798796415u)) * 1597334677u;
                float _12459 = float((_12451 ^ (_12451 >> uint(16))) & 65535u) * 1.525902189314365386962890625e-05;
                uint3 _12466 = uint3(int3(_12200 + float3(0.0, 1.0, 0.0)));
                uint _12479 = (((_12466.x * 1597334677u) ^ (_12466.y * 3812015801u)) ^ (_12466.z * 2798796415u)) * 1597334677u;
                float _12487 = float((_12479 ^ (_12479 >> uint(16))) & 65535u) * 1.525902189314365386962890625e-05;
                uint3 _12494 = uint3(int3(_12200 + float3(1.0, 1.0, 0.0)));
                uint _12507 = (((_12494.x * 1597334677u) ^ (_12494.y * 3812015801u)) ^ (_12494.z * 2798796415u)) * 1597334677u;
                float _12515 = float((_12507 ^ (_12507 >> uint(16))) & 65535u) * 1.525902189314365386962890625e-05;
                uint3 _12522 = uint3(int3(_12200 + float3(0.0, 0.0, 1.0)));
                uint _12535 = (((_12522.x * 1597334677u) ^ (_12522.y * 3812015801u)) ^ (_12522.z * 2798796415u)) * 1597334677u;
                float _12543 = float((_12535 ^ (_12535 >> uint(16))) & 65535u) * 1.525902189314365386962890625e-05;
                uint3 _12550 = uint3(int3(_12200 + float3(1.0, 0.0, 1.0)));
                uint _12563 = (((_12550.x * 1597334677u) ^ (_12550.y * 3812015801u)) ^ (_12550.z * 2798796415u)) * 1597334677u;
                float _12571 = float((_12563 ^ (_12563 >> uint(16))) & 65535u) * 1.525902189314365386962890625e-05;
                uint3 _12578 = uint3(int3(_12200 + float3(0.0, 1.0, 1.0)));
                uint _12591 = (((_12578.x * 1597334677u) ^ (_12578.y * 3812015801u)) ^ (_12578.z * 2798796415u)) * 1597334677u;
                float _12599 = float((_12591 ^ (_12591 >> uint(16))) & 65535u) * 1.525902189314365386962890625e-05;
                uint3 _12606 = uint3(int3(_12200 + float3(1.0)));
                uint _12619 = (((_12606.x * 1597334677u) ^ (_12606.y * 3812015801u)) ^ (_12606.z * 2798796415u)) * 1597334677u;
                float _12243 = _12459 - _12431;
                float _12246 = _12487 - _12431;
                float _12249 = _12543 - _12431;
                float _12252 = _12431 - _12459;
                float _12256 = (_12252 - _12487) + _12515;
                float _12263 = ((_12431 - _12487) - _12543) + _12599;
                float _12270 = (_12252 - _12543) + _12571;
                float _12286 = (((((((_12430 * (-1.525902189314365386962890625e-05)) + _12459) + _12487) - _12515) + _12543) - _12571) - _12599) + (float((_12619 ^ (_12619 >> uint(16))) & 65535u) * 1.525902189314365386962890625e-05);
                float _12290 = _12211.x;
                float _12295 = _12211.y;
                float _12300 = _12211.z;
                float _12306 = _12256 * _12290;
                float _12314 = _12263 * _12295;
                float _12322 = _12270 * _12300;
                float _12333 = (_12286 * _12290) * _12295;
                float _12337 = ((((((_12431 + (_12243 * _12290)) + (_12246 * _12295)) + (_12249 * _12300)) + (_12306 * _12295)) + (_12314 * _12300)) + (_12322 * _12290)) + (_12333 * _12300);
                float _12094 = 1.0 - _12337;
                float3 _12106 = (_12089 * float3(2.900000095367431640625, 2.2999999523162841796875, 2.599999904632568359375)) + float3(13.1000003814697265625, 7.69999980926513671875, 3.2999999523162841796875);
                float3 _12660 = floor(_12106);
                float3 _12663 = _12106 - _12660;
                float3 _12671 = (_12663 * _12663) * (float3(3.0) - (_12663 * 2.0));
                uint3 _12870 = uint3(int3(_12660));
                uint _12883 = (((_12870.x * 1597334677u) ^ (_12870.y * 3812015801u)) ^ (_12870.z * 2798796415u)) * 1597334677u;
                float _12890 = float((_12883 ^ (_12883 >> uint(16))) & 65535u);
                float _12891 = _12890 * 1.525902189314365386962890625e-05;
                uint3 _12898 = uint3(int3(_12660 + float3(1.0, 0.0, 0.0)));
                uint _12911 = (((_12898.x * 1597334677u) ^ (_12898.y * 3812015801u)) ^ (_12898.z * 2798796415u)) * 1597334677u;
                float _12919 = float((_12911 ^ (_12911 >> uint(16))) & 65535u) * 1.525902189314365386962890625e-05;
                uint3 _12926 = uint3(int3(_12660 + float3(0.0, 1.0, 0.0)));
                uint _12939 = (((_12926.x * 1597334677u) ^ (_12926.y * 3812015801u)) ^ (_12926.z * 2798796415u)) * 1597334677u;
                float _12947 = float((_12939 ^ (_12939 >> uint(16))) & 65535u) * 1.525902189314365386962890625e-05;
                uint3 _12954 = uint3(int3(_12660 + float3(1.0, 1.0, 0.0)));
                uint _12967 = (((_12954.x * 1597334677u) ^ (_12954.y * 3812015801u)) ^ (_12954.z * 2798796415u)) * 1597334677u;
                float _12975 = float((_12967 ^ (_12967 >> uint(16))) & 65535u) * 1.525902189314365386962890625e-05;
                uint3 _12982 = uint3(int3(_12660 + float3(0.0, 0.0, 1.0)));
                uint _12995 = (((_12982.x * 1597334677u) ^ (_12982.y * 3812015801u)) ^ (_12982.z * 2798796415u)) * 1597334677u;
                float _13003 = float((_12995 ^ (_12995 >> uint(16))) & 65535u) * 1.525902189314365386962890625e-05;
                uint3 _13010 = uint3(int3(_12660 + float3(1.0, 0.0, 1.0)));
                uint _13023 = (((_13010.x * 1597334677u) ^ (_13010.y * 3812015801u)) ^ (_13010.z * 2798796415u)) * 1597334677u;
                float _13031 = float((_13023 ^ (_13023 >> uint(16))) & 65535u) * 1.525902189314365386962890625e-05;
                uint3 _13038 = uint3(int3(_12660 + float3(0.0, 1.0, 1.0)));
                uint _13051 = (((_13038.x * 1597334677u) ^ (_13038.y * 3812015801u)) ^ (_13038.z * 2798796415u)) * 1597334677u;
                float _13059 = float((_13051 ^ (_13051 >> uint(16))) & 65535u) * 1.525902189314365386962890625e-05;
                uint3 _13066 = uint3(int3(_12660 + float3(1.0)));
                uint _13079 = (((_13066.x * 1597334677u) ^ (_13066.y * 3812015801u)) ^ (_13066.z * 2798796415u)) * 1597334677u;
                float _12712 = _12891 - _12919;
                float _12716 = (_12712 - _12947) + _12975;
                float _12723 = ((_12891 - _12947) - _13003) + _13059;
                float _12730 = (_12712 - _13003) + _13031;
                float _12746 = (((((((_12890 * (-1.525902189314365386962890625e-05)) + _12919) + _12947) - _12975) + _13003) - _13031) - _13059) + (float((_13079 ^ (_13079 >> uint(16))) & 65535u) * 1.525902189314365386962890625e-05);
                float _12750 = _12671.x;
                float _12755 = _12671.y;
                float _12760 = _12671.z;
                float3 _12123 = ((float4(_12337, ((_12203 * 6.0) * (float3(1.0) - _12203)) * float3(((_12243 + (_12256 * _12295)) + _12322) + ((_12286 * _12295) * _12300), ((_12246 + (_12263 * _12300)) + _12306) + ((_12286 * _12300) * _12290), ((_12249 + (_12270 * _12290)) + _12314) + _12333)).yzw * (((4.0 * _12094) * _12094) * _12094)) + ((float3(1.01499998569488525390625, 0.805000007152557373046875, 0.910000026226043701171875) * float4(_20055, ((_12663 * 6.0) * (float3(1.0) - _12663)) * float3((((_12919 - _12891) + (_12716 * _12755)) + (_12730 * _12760)) + ((_12746 * _12755) * _12760), (((_12947 - _12891) + (_12723 * _12760)) + (_12716 * _12750)) + ((_12746 * _12760) * _12750), (((_13003 - _12891) + (_12730 * _12750)) + (_12723 * _12755)) + ((_12746 * _12750) * _12755))).yzw) * (1.0 - smoothstep(0.20000000298023223876953125, 0.5, _12078 * 2.900000095367431640625)))) * ((0.25 * _2077._m3.x) * _12081);
                float3 _12131 = dfdx(in.m_1840);
                float3 _12133 = dfdy(in.m_1840);
                float3 _12136 = cross(_12133, _18776);
                float _12142 = dot(_12131, _12136);
                float _12144 = abs(_12142);
                if (_12144 < 9.9999996826552253889678874634872e-21)
                {
                    _18807 = _18776;
                    break;
                }
                _18807 = fast::normalize((_18776 * _12144) - (((_12136 * dot(_12123, _12069)) + (cross(_18776, _12131) * dot(_12123, _12071))) * sign(_12142)));
                break;
            } while(false);
            float _11667 = fast::max(dot(_18807, _4578), 9.9999997473787516355514526367188e-05);
            float3 _11675 = mix(float3(0.0280000008642673492431640625), _18771, float3(_18806));
            float3 _11681 = fast::clamp(float3(0.4799999892711639404296875, 0.4099999964237213134765625, 0.2800000011920928955078125) * _2077._m0.w, float3(0.0), float3(1.0));
            bool _11684 = _2077._m0.w > 0.0;
            bool _11690;
            if (_11684)
            {
                _11690 = _2077._m1.x > 0.0;
            }
            else
            {
                _11690 = _11684;
            }
            bool _11697 = _11690 && (isunordered(_2077._m1.w, 0.5) || _2077._m1.w <= 0.5);
            float _18808;
            if (_11690)
            {
                _18808 = _2077._m1.y;
            }
            else
            {
                _18808 = 0.0;
            }
            bool _11707 = _18808 > 0.0;
            float _18809;
            if (_11697 || _11707)
            {
                _18809 = fast::clamp(length(fwidth(_4589)) / fast::max(length(fwidth(in.m_1840)), 1.0000000116860974230803549289703e-07), 0.0, 400.0);
            }
            else
            {
                _18809 = 0.0;
            }
            float _11721 = fast::max(_18809, 2.0);
            spvUnsafeArray<float3, 2> _2331;
            spvUnsafeArray<float3, 2> _2339;
            spvUnsafeArray<float3, 2> _2345;
            spvUnsafeArray<float3, 2> _2352;
            if (_11697)
            {
                float3 _13100 = (_2077._m0.xyz * (_2077._m1.x * 0.5)) * _18809;
                for (int _18810 = 0; _18810 < 2; )
                {
                    float3 _13110 = _13100 * ((_18810 == 0) ? 0.519999980926513671875 : 1.7200000286102294921875);
                    float3 _13113 = _13110 * 1.35562622547149658203125;
                    _2331[_18810] = cos(_13113);
                    _2339[_18810] = sin(_13113);
                    float3 _13123 = _13110 * 2.8569700717926025390625;
                    _2345[_18810] = cos(_13123);
                    _2352[_18810] = sin(_13123);
                    _18810++;
                    continue;
                }
            }
            float3 _18816;
            if (_11697)
            {
                _18816 = fast::normalize(mix(_18807, _4589, float3(_11681.x)));
            }
            else
            {
                _18816 = _18807;
            }
            float3 _18818;
            if (_11697)
            {
                _18818 = fast::normalize(mix(_18807, _4589, float3(_11681.y * 0.60000002384185791015625)));
            }
            else
            {
                _18818 = _18807;
            }
            float3 _18820;
            if (_11697)
            {
                _18820 = fast::normalize(mix(_18807, _4589, float3(_11681.z * 0.4000000059604644775390625)));
            }
            else
            {
                _18820 = _18807;
            }
            float _11774 = dot(_18818, _4571);
            float3 _11778 = float3(dot(_18816, _4571), _11774, dot(_18820, _4571));
            float3 _18823;
            if (_11697)
            {
                float3 _13145 = fast::clamp(_11778, float3(-1.0), float3(1.0));
                float3 _13152 = sqrt(fast::max(float3(1.0) - (_13145 * _13145), float3(0.0)));
                float3 _18822;
                _18822 = float3(0.0);
                for (int _18821 = 0; _18821 < 2; )
                {
                    _18822 += ((((fast::max(_13145, float3(0.0)) * 0.533333301544189453125) + ((fast::max((_13145 * _2331[_18821]) - (_13152 * _2339[_18821]), float3(0.0)) + fast::max((_13145 * _2331[_18821]) + (_13152 * _2339[_18821]), float3(0.0))) * 0.22207589447498321533203125)) + ((fast::max((_13145 * _2345[_18821]) - (_13152 * _2352[_18821]), float3(0.0)) + fast::max((_13145 * _2345[_18821]) + (_13152 * _2352[_18821]), float3(0.0))) * 0.011257399804890155792236328125)) * ((_18821 == 0) ? 0.430000007152557373046875 : 0.569999992847442626953125));
                    _18821++;
                    continue;
                }
                _18823 = mix(fast::max(_11778, float3(0.0)), _18822, _11681);
            }
            else
            {
                _18823 = float3(fast::max(_11774, 0.0));
            }
            float3 _11795 = (_18823 * _4620) * _18802;
            float3 _18830;
            do
            {
                float _13266 = fast::clamp(dot(_18807, _4571), 0.0, 1.0);
                if (_13266 <= 0.0)
                {
                    _18830 = float3(0.0);
                    break;
                }
                float _13274 = fast::clamp(dot(_18807, _4583), 0.0, 1.0);
                float _13285 = fast::clamp(_18805 * _2077._m2.x, 0.04500000178813934326171875, 1.0);
                float _13288 = _13285 * _13285;
                float _13348 = _13288 * _13288;
                float _13351 = _13274 * _13274;
                float _13355 = (_13351 * (_13348 - 1.0)) + 1.0;
                float _13373 = _11667 * _11667;
                float _13375 = 1.0 - _13348;
                float _13384 = _13266 * _13266;
                float _13296 = (_13348 / ((3.1415927410125732421875 * _13355) * _13355)) * (0.5 / fast::max((_13266 * sqrt((_13373 * _13375) + _13348)) + (_11667 * sqrt((_13384 * _13375) + _13348)), 9.9999997473787516355514526367188e-06));
                float _18829;
                if (_2077._m2.w > 0.5)
                {
                    float _13305 = fast::clamp(_18805 * _2077._m2.y, 0.04500000178813934326171875, 1.0);
                    float _13308 = _13305 * _13305;
                    float _13403 = _13308 * _13308;
                    float _13410 = (_13351 * (_13403 - 1.0)) + 1.0;
                    float _13430 = 1.0 - _13403;
                    _18829 = mix(_13296, (_13403 / ((3.1415927410125732421875 * _13410) * _13410)) * (0.5 / fast::max((_13266 * sqrt((_13373 * _13430) + _13403)) + (_11667 * sqrt((_13384 * _13430) + _13403)), 9.9999997473787516355514526367188e-06)), _2077._m2.z);
                }
                else
                {
                    _18829 = _13296;
                }
                _18830 = (_11675 + ((float3(1.0) - _11675) * powr(1.0 - fast::clamp(dot(_4578, _4583), 0.0, 1.0), 5.0))) * ((_18829 * 3.1415927410125732421875) * _13266);
                break;
            } while(false);
            float3 _11808 = (_18830 * _4620) * _18802;
            bool _11819;
            if (_11707)
            {
                _11819 = dot(_4589, _4571) < 0.3499999940395355224609375;
            }
            else
            {
                _11819 = _11707;
            }
            bool _11825;
            if (_11819)
            {
                _11825 = _291._m4.w > 0.0;
            }
            else
            {
                _11825 = _11819;
            }
            float3 _18980;
            if (_11825)
            {
                float3 _18890;
                if (_4594)
                {
                    float3 _18889;
                    do
                    {
                        int _13479 = int(_291._m21.x);
                        if ((_291._m5.w < 0.5) || (_13479 == 0))
                        {
                            float _13587 = (1200.0 / _11721) / (0.60000002384185791015625 + (6.0 * _2077._m1.y));
                            float _13594 = (-_13587) * _13587;
                            _18889 = (((((float3(0.23299999535083770751953125, 0.4550000131130218505859375, 0.648999989032745361328125) * exp(_13594 * 156.25)) + (float3(0.100000001490116119384765625, 0.3359999954700469970703125, 0.3440000116825103759765625) * exp(_13594 * 20.6611576080322265625))) + (float3(0.1180000007152557373046875, 0.19799999892711639404296875, 0.0) * exp(_13594 * 5.3475933074951171875))) + (float3(0.112999998033046722412109375, 0.007000000216066837310791015625, 0.007000000216066837310791015625) * exp(_13594 * 1.763668537139892578125))) + (float3(0.3580000102519989013671875, 0.0040000001899898052215576171875, 0.0) * exp(_13594 * 0.50251257419586181640625))) + (float3(0.078000001609325408935546875, 0.0, 0.0) * exp(_13594 * 0.13495276868343353271484375));
                            break;
                        }
                        float _13498 = dot(_291._m20.xyz, in.m_1840) + _291._m20.w;
                        int _18835;
                        _18835 = 0;
                        for (;;)
                        {
                            bool _13504 = _18835 < (_13479 - 1);
                            bool _13512;
                            if (_13504)
                            {
                                _13512 = _13498 > _291._m16[_18835];
                            }
                            else
                            {
                                _13512 = _13504;
                            }
                            if (_13512)
                            {
                                _18835++;
                                continue;
                            }
                            else
                            {
                                break;
                            }
                        }
                        if (_13498 > _291._m16[_18835])
                        {
                            float _13632 = (1200.0 / _11721) / (0.60000002384185791015625 + (6.0 * _2077._m1.y));
                            float _13639 = (-_13632) * _13632;
                            _18889 = (((((float3(0.23299999535083770751953125, 0.4550000131130218505859375, 0.648999989032745361328125) * exp(_13639 * 156.25)) + (float3(0.100000001490116119384765625, 0.3359999954700469970703125, 0.3440000116825103759765625) * exp(_13639 * 20.6611576080322265625))) + (float3(0.1180000007152557373046875, 0.19799999892711639404296875, 0.0) * exp(_13639 * 5.3475933074951171875))) + (float3(0.112999998033046722412109375, 0.007000000216066837310791015625, 0.007000000216066837310791015625) * exp(_13639 * 1.763668537139892578125))) + (float3(0.3580000102519989013671875, 0.0040000001899898052215576171875, 0.0) * exp(_13639 * 0.50251257419586181640625))) + (float3(0.078000001609325408935546875, 0.0, 0.0) * exp(_13639 * 0.13495276868343353271484375));
                            break;
                        }
                        float4x4 _13682;
                        float3 _13536 = in.m_1840 - (_4589 * fast::max(_291._m18[_18835] * 2.0, 0.0040000001899898052215576171875));
                        float _18848;
                        do
                        {
                            _13682 = _291._m14[_18835];
                            float4 _13688 = _13682 * float4(_13536 + (_4571 * 0.0199999995529651641845703125), 1.0);
                            float _13691 = _13688.x;
                            bool _13692 = _13691 < 0.0;
                            bool _13699;
                            if (!_13692)
                            {
                                _13699 = _13691 > 1.0;
                            }
                            else
                            {
                                _13699 = _13692;
                            }
                            bool _13706;
                            if (!_13699)
                            {
                                _13706 = _13688.y < 0.0;
                            }
                            else
                            {
                                _13706 = _13699;
                            }
                            bool _13713;
                            if (!_13706)
                            {
                                _13713 = _13688.y > 1.0;
                            }
                            else
                            {
                                _13713 = _13706;
                            }
                            if (_13713)
                            {
                                _18848 = 1.0;
                                break;
                            }
                            float2 _13726 = float2(float(_18835 & 1), float(_18835 >> 1)) * _291._m23.xy;
                            float _13733 = fast::min(_13688.z, 1.0) - _291._m19[_18835];
                            float2 _13752 = _291._m22.xy * 0.5;
                            float2 _13757 = _13726 + (_13688.xy * _291._m23.xy);
                            float4 _13770 = float4(_13726 + _13752, (_13726 + _291._m23.xy) - _13752);
                            float _18847;
                            do
                            {
                                int _13796 = int(_291._m22.z);
                                if (_13796 <= 0)
                                {
                                    _18847 = spvDepthCast(_311).sample_compare(_311Smplr, float3(fast::clamp(_13757, _13770.xy, _13770.zw), _13733).xy, _13733);
                                    break;
                                }
                                float2 _13819 = (_13757 / _291._m22.xy) + float2(0.5);
                                float2 _13820 = floor(_13819);
                                float2 _13825 = _13819 - _13820;
                                float2 _13828 = _13820 - float2(0.5);
                                bool _13832 = _13796 == 1;
                                spvUnsafeArray<float2, 3> _13780;
                                spvUnsafeArray<float2, 3> _13781;
                                if (_13832)
                                {
                                    float2 _13835 = _13825 * 2.0;
                                    _13780[0] = float2(3.0) - _13835;
                                    _13780[1] = float2(1.0) + _13835;
                                    _13781[0] = ((float2(2.0) - _13825) / _13780[0]) - float2(1.0);
                                    _13781[1] = (_13825 / _13780[1]) + float2(1.0);
                                }
                                else
                                {
                                    float2 _13862 = _13825 * 3.0;
                                    _13780[0] = float2(4.0) - _13862;
                                    _13780[1] = float2(7.0);
                                    _13780[2] = float2(1.0) + _13862;
                                    _13781[0] = ((float2(3.0) - (_13825 * 2.0)) / _13780[0]) - float2(2.0);
                                    _13781[1] = (float2(3.0) + _13825) / _13780[1];
                                    _13781[2] = (_13825 / _13780[2]) + float2(2.0);
                                }
                                int _20080 = _13832 ? 2 : 3;
                                int _18837;
                                float _18840;
                                _18840 = 0.0;
                                _18837 = 0;
                                float _18846;
                                for (; _18837 < _20080; _18840 = _18846, _18837++)
                                {
                                    _18846 = _18840;
                                    for (int _18843 = 0; _18843 < _20080; )
                                    {
                                        _18846 += ((_13780[_18843].x * _13780[_18837].y) * spvDepthCast(_311).sample_compare(_311Smplr, float3(fast::clamp(_291._m22.xy * (_13828 + float2(_13781[_18843].x, _13781[_18837].y)), _13770.xy, _13770.zw), _13733).xy, _13733));
                                        _18843++;
                                        continue;
                                    }
                                }
                                _18847 = _18840 * (_13832 ? 0.0625 : 0.0069444444961845874786376953125);
                                break;
                            } while(false);
                            _18848 = _18847;
                            break;
                        } while(false);
                        if (_18848 <= 0.0)
                        {
                            _18889 = float3(0.0);
                            break;
                        }
                        float3 _18850;
                        float3 _18851;
                        _18851 = float3(1.0);
                        _18850 = float3(0.0);
                        float3 _13570;
                        float3 _14000;
                        spvUnsafeArray<float2, 3> _14112;
                        spvUnsafeArray<float2, 3> _14113;
                        for (int _18849 = 0; _18849 < 4; _18851 = _14000, _18850 = _13570, _18849++)
                        {
                            float _13964 = (_2184[_18849] * 1000.0) / (0.60000002384185791015625 + (6.0 * _2077._m1.y));
                            float _13971 = (-_13964) * _13964;
                            _14000 = (((((float3(0.23299999535083770751953125, 0.4550000131130218505859375, 0.648999989032745361328125) * exp(_13971 * 156.25)) + (float3(0.100000001490116119384765625, 0.3359999954700469970703125, 0.3440000116825103759765625) * exp(_13971 * 20.6611576080322265625))) + (float3(0.1180000007152557373046875, 0.19799999892711639404296875, 0.0) * exp(_13971 * 5.3475933074951171875))) + (float3(0.112999998033046722412109375, 0.007000000216066837310791015625, 0.007000000216066837310791015625) * exp(_13971 * 1.763668537139892578125))) + (float3(0.3580000102519989013671875, 0.0040000001899898052215576171875, 0.0) * exp(_13971 * 0.50251257419586181640625))) + (float3(0.078000001609325408935546875, 0.0, 0.0) * exp(_13971 * 0.13495276868343353271484375));
                            float _18872;
                            do
                            {
                                float4 _14020 = _13682 * float4(_13536 + (_4571 * _2184[_18849]), 1.0);
                                float _14023 = _14020.x;
                                bool _14024 = _14023 < 0.0;
                                bool _14031;
                                if (!_14024)
                                {
                                    _14031 = _14023 > 1.0;
                                }
                                else
                                {
                                    _14031 = _14024;
                                }
                                bool _14038;
                                if (!_14031)
                                {
                                    _14038 = _14020.y < 0.0;
                                }
                                else
                                {
                                    _14038 = _14031;
                                }
                                bool _14045;
                                if (!_14038)
                                {
                                    _14045 = _14020.y > 1.0;
                                }
                                else
                                {
                                    _14045 = _14038;
                                }
                                if (_14045)
                                {
                                    _18872 = 1.0;
                                    break;
                                }
                                float2 _14058 = float2(float(_18835 & 1), float(_18835 >> 1)) * _291._m23.xy;
                                float _14065 = fast::min(_14020.z, 1.0) - _291._m19[_18835];
                                float2 _14084 = _291._m22.xy * 0.5;
                                float2 _14089 = _14058 + (_14020.xy * _291._m23.xy);
                                float4 _14102 = float4(_14058 + _14084, (_14058 + _291._m23.xy) - _14084);
                                float _18871;
                                do
                                {
                                    int _14128 = int(_291._m22.z);
                                    if (_14128 <= 0)
                                    {
                                        _18871 = spvDepthCast(_311).sample_compare(_311Smplr, float3(fast::clamp(_14089, _14102.xy, _14102.zw), _14065).xy, _14065);
                                        break;
                                    }
                                    float2 _14151 = (_14089 / _291._m22.xy) + float2(0.5);
                                    float2 _14152 = floor(_14151);
                                    float2 _14157 = _14151 - _14152;
                                    float2 _14160 = _14152 - float2(0.5);
                                    bool _14164 = _14128 == 1;
                                    if (_14164)
                                    {
                                        float2 _14167 = _14157 * 2.0;
                                        _14112[0] = float2(3.0) - _14167;
                                        _14112[1] = float2(1.0) + _14167;
                                        _14113[0] = ((float2(2.0) - _14157) / _14112[0]) - float2(1.0);
                                        _14113[1] = (_14157 / _14112[1]) + float2(1.0);
                                    }
                                    else
                                    {
                                        float2 _14194 = _14157 * 3.0;
                                        _14112[0] = float2(4.0) - _14194;
                                        _14112[1] = float2(7.0);
                                        _14112[2] = float2(1.0) + _14194;
                                        _14113[0] = ((float2(3.0) - (_14157 * 2.0)) / _14112[0]) - float2(2.0);
                                        _14113[1] = (float2(3.0) + _14157) / _14112[1];
                                        _14113[2] = (_14157 / _14112[2]) + float2(2.0);
                                    }
                                    int _20082 = _14164 ? 2 : 3;
                                    int _18861;
                                    float _18864;
                                    _18864 = 0.0;
                                    _18861 = 0;
                                    float _18870;
                                    for (; _18861 < _20082; _18864 = _18870, _18861++)
                                    {
                                        _18870 = _18864;
                                        for (int _18867 = 0; _18867 < _20082; )
                                        {
                                            _18870 += ((_14112[_18867].x * _14112[_18861].y) * spvDepthCast(_311).sample_compare(_311Smplr, float3(fast::clamp(_291._m22.xy * (_14160 + float2(_14113[_18867].x, _14113[_18861].y)), _14102.xy, _14102.zw), _14065).xy, _14065));
                                            _18867++;
                                            continue;
                                        }
                                    }
                                    _18871 = _18864 * (_14164 ? 0.0625 : 0.0069444444961845874786376953125);
                                    break;
                                } while(false);
                                _18872 = _18871;
                                break;
                            } while(false);
                            _13570 = _18850 + ((_18851 - _14000) * _18872);
                        }
                        _18889 = _18850;
                        break;
                    } while(false);
                    _18890 = _18889;
                }
                else
                {
                    float _14296 = (1200.0 / _11721) / (0.60000002384185791015625 + (6.0 * _2077._m1.y));
                    float _14303 = (-_14296) * _14296;
                    _18890 = (((((float3(0.23299999535083770751953125, 0.4550000131130218505859375, 0.648999989032745361328125) * exp(_14303 * 156.25)) + (float3(0.100000001490116119384765625, 0.3359999954700469970703125, 0.3440000116825103759765625) * exp(_14303 * 20.6611576080322265625))) + (float3(0.1180000007152557373046875, 0.19799999892711639404296875, 0.0) * exp(_14303 * 5.3475933074951171875))) + (float3(0.112999998033046722412109375, 0.007000000216066837310791015625, 0.007000000216066837310791015625) * exp(_14303 * 1.763668537139892578125))) + (float3(0.3580000102519989013671875, 0.0040000001899898052215576171875, 0.0) * exp(_14303 * 0.50251257419586181640625))) + (float3(0.078000001609325408935546875, 0.0, 0.0) * exp(_14303 * 0.13495276868343353271484375));
                }
                _18980 = _11795 + ((_18890 * _4620) * ((fast::clamp(0.300000011920928955078125 - dot(_4589, _4571), 0.0, 1.0) * _18808) * 2.0));
            }
            else
            {
                _18980 = _11795;
            }
            float3 _18979;
            float3 _18991;
            if (_291._m13.w > 0.5)
            {
                float2 _14360 = fast::clamp(floor(gl_FragCoord.xy * _291._m12.xy), float2(0.0), _291._m13.xy - float2(1.0));
                uint _14388 = uint((((fast::clamp(floor((log2(fast::max(dot(_291._m11.xyz, in.m_1840) + _291._m11.w, 9.9999999747524270787835121154785e-07)) * _291._m12.z) + _291._m12.w), 0.0, _291._m13.z - 1.0) * _291._m13.y) + _14360.y) * _291._m13.x) + _14360.x);
                uint _14390 = _14388 >> uint(2);
                uint _14392 = _14388 & 3u;
                uint _14396 = _1971._m0[_14390][_14392] & 65535u;
                uint _14398 = _1971._m0[_14390][_14392] >> uint(16);
                float3 _18981;
                float3 _19016;
                _19016 = _11808;
                _18981 = _18980;
                float3 _11929;
                spvUnsafeArray<float2, 3> _14806;
                spvUnsafeArray<float2, 3> _14807;
                spvUnsafeArray<float2, 3> _15019;
                spvUnsafeArray<float2, 3> _15020;
                spvUnsafeArray<float2, 3> _15967;
                spvUnsafeArray<float2, 3> _15968;
                spvUnsafeArray<float2, 3> _16180;
                spvUnsafeArray<float2, 3> _16181;
                spvUnsafeArray<float2, 3> _16724;
                spvUnsafeArray<float2, 3> _16725;
                spvUnsafeArray<float2, 3> _16937;
                spvUnsafeArray<float2, 3> _16938;
                float3 _19895;
                for (uint _18916 = _14396; _18916 < (_14396 + _14398); _19016 = _11929, _18981 = _19895, _18916++)
                {
                    uint _14404 = _18916 / 3u;
                    uint _14417 = (_1992._m0[_14404 >> uint(2)][_14404 & 3u] >> ((_18916 - (_14404 * 3u)) * 10u)) & 1023u;
                    float3 _14434 = _1833._m0[_14417].xyz - in.m_1840;
                    float _14437 = dot(_14434, _14434);
                    float _14441 = _14437 * _1833._m0[_14417].w;
                    float _14446 = fast::clamp(1.0 - (_14441 * _14441), 0.0, 1.0);
                    float3 _14451 = _14434 * rsqrt(fast::max(_14437, 9.9999999392252902907785028219223e-09));
                    float _14469 = fast::clamp((dot(-_14451, _1876._m0[_14417].xyz) * _1868._m0[_14417].w) + _1876._m0[_14417].w, 0.0, 1.0);
                    float3 _14482 = _1868._m0[_14417].xyz * ((((_14446 * _14446) * _14469) * _14469) / fast::max(_14437, 9.9999997473787516355514526367188e-05));
                    float _19044;
                    if (_4594)
                    {
                        float _19043;
                        do
                        {
                            uint _14518 = uint(_291._m21.z);
                            if (_14417 < _14518)
                            {
                                float _14540 = _291._m26[_14417].z * fast::max((_291._m15[_14417] * float4(in.m_1840, 1.0)).w, 0.0);
                                float4 _14564 = _291._m15[_14417] * float4((in.m_1840 + (_4589 * (_14540 * _291._m25.x))) + (_14451 * (_14540 * _291._m25.y)), 1.0);
                                float _14566 = _14564.w;
                                if (_14566 <= 0.0)
                                {
                                    _19043 = 1.0;
                                    break;
                                }
                                float3 _14575 = _14564.xyz / float3(_14566);
                                float _14577 = _14575.x;
                                bool _14578 = _14577 < 0.0;
                                bool _14585;
                                if (!_14578)
                                {
                                    _14585 = _14577 > 1.0;
                                }
                                else
                                {
                                    _14585 = _14578;
                                }
                                bool _14592;
                                if (!_14585)
                                {
                                    _14592 = _14575.y < 0.0;
                                }
                                else
                                {
                                    _14592 = _14585;
                                }
                                bool _14599;
                                if (!_14592)
                                {
                                    _14599 = _14575.y > 1.0;
                                }
                                else
                                {
                                    _14599 = _14592;
                                }
                                bool _14606;
                                if (!_14599)
                                {
                                    _14606 = _14575.z > 1.0;
                                }
                                else
                                {
                                    _14606 = _14599;
                                }
                                if (_14606)
                                {
                                    _19043 = 1.0;
                                    break;
                                }
                                float _14612 = _14575.z;
                                float2 _14778 = _291._m22.xy * 0.5;
                                float2 _14783 = _291._m26[_14417].xy + (_14575.xy * _291._m23.zw);
                                float4 _14796 = float4(_291._m26[_14417].xy + _14778, (_291._m26[_14417].xy + _291._m23.zw) - _14778);
                                float _19042;
                                do
                                {
                                    int _14822 = int(_291._m22.z);
                                    if (_14822 <= 0)
                                    {
                                        float2 _14832 = fast::clamp(_14783, _14796.xy, _14796.zw);
                                        _19042 = spvDepthCast(_311).sample_compare(_311Smplr, float3(_14832, _14612).xy, _14612);
                                        break;
                                    }
                                    float2 _14845 = (_14783 / _291._m22.xy) + float2(0.5);
                                    float2 _14846 = floor(_14845);
                                    float2 _14851 = _14845 - _14846;
                                    float2 _14854 = _14846 - float2(0.5);
                                    bool _14858 = _14822 == 1;
                                    if (_14858)
                                    {
                                        float2 _14861 = _14851 * 2.0;
                                        _14806[0] = float2(3.0) - _14861;
                                        _14806[1] = float2(1.0) + _14861;
                                        _14807[0] = ((float2(2.0) - _14851) / _14806[0]) - float2(1.0);
                                        _14807[1] = (_14851 / _14806[1]) + float2(1.0);
                                    }
                                    else
                                    {
                                        float2 _14888 = _14851 * 3.0;
                                        _14806[0] = float2(4.0) - _14888;
                                        _14806[1] = float2(7.0);
                                        _14806[2] = float2(1.0) + _14888;
                                        _14807[0] = ((float2(3.0) - (_14851 * 2.0)) / _14806[0]) - float2(2.0);
                                        _14807[1] = (float2(3.0) + _14851) / _14806[1];
                                        _14807[2] = (_14851 / _14806[2]) + float2(2.0);
                                    }
                                    int _20084 = _14858 ? 2 : 3;
                                    int _19032;
                                    float _19035;
                                    _19035 = 0.0;
                                    _19032 = 0;
                                    float _19041;
                                    for (; _19032 < _20084; _19035 = _19041, _19032++)
                                    {
                                        _19041 = _19035;
                                        for (int _19038 = 0; _19038 < _20084; )
                                        {
                                            _19041 += ((_14806[_19038].x * _14806[_19032].y) * spvDepthCast(_311).sample_compare(_311Smplr, float3(fast::clamp(_291._m22.xy * (_14854 + float2(_14807[_19038].x, _14807[_19032].y)), _14796.xy, _14796.zw), _14612).xy, _14612));
                                            _19038++;
                                            continue;
                                        }
                                    }
                                    _19042 = _19035 * (_14858 ? 0.0625 : 0.0069444444961845874786376953125);
                                    break;
                                } while(false);
                                _19043 = _19042;
                                break;
                            }
                            uint _14622 = _14417 - _14518;
                            if (_14622 >= uint(_291._m21.w))
                            {
                                _19043 = 1.0;
                                break;
                            }
                            float _14643 = _291._m27[_14622].w * length(in.m_1840 - _291._m27[_14622].xyz);
                            float3 _14661 = ((in.m_1840 + (_4589 * (_14643 * _291._m25.x))) + (_14451 * (_14643 * _291._m25.y))) - _291._m27[_14622].xyz;
                            float3 _14663 = abs(_14661);
                            float _14665 = _14663.x;
                            float _14667 = _14663.y;
                            bool _14668 = _14665 >= _14667;
                            bool _14676;
                            if (_14668)
                            {
                                _14676 = _14665 >= _14663.z;
                            }
                            else
                            {
                                _14676 = _14668;
                            }
                            float _19017;
                            int _19019;
                            if (_14676)
                            {
                                _19019 = (_14661.x > 0.0) ? 0 : 1;
                                _19017 = _14665;
                            }
                            else
                            {
                                float _14688 = _14663.z;
                                bool _14689 = _14667 >= _14688;
                                int _19020;
                                if (_14689)
                                {
                                    _19020 = (_14661.y > 0.0) ? 2 : 3;
                                }
                                else
                                {
                                    _19020 = (_14661.z > 0.0) ? 4 : 5;
                                }
                                _19019 = _19020;
                                _19017 = _14689 ? _14667 : _14688;
                            }
                            if (_19017 <= 0.0)
                            {
                                _19043 = 1.0;
                                break;
                            }
                            float2 _14726 = float2(dot(_14661, _969[_19019]), dot(_14661, _978[_19019])) / float2(_19017 * _291._m24.z);
                            float _14733 = _291._m28[_14622].z + (_291._m28[_14622].w / _19017);
                            if (_14733 > 1.0)
                            {
                                _19043 = 1.0;
                                break;
                            }
                            float2 _14751 = _291._m28[_14622].xy + (float2(float(spvSMod(_19019, 3)), float(_19019 / 3)) * _291._m24.xy);
                            float2 _14991 = _291._m22.xy * 0.5;
                            float2 _14996 = _14751 + (float2(0.5 + (0.5 * _14726.x), 0.5 - (0.5 * _14726.y)) * _291._m24.xy);
                            float4 _15009 = float4(_14751 + _14991, (_14751 + _291._m24.xy) - _14991);
                            float _19031;
                            do
                            {
                                int _15035 = int(_291._m22.z);
                                if (_15035 <= 0)
                                {
                                    _19031 = spvDepthCast(_311).sample_compare(_311Smplr, float3(fast::clamp(_14996, _15009.xy, _15009.zw), _14733).xy, _14733);
                                    break;
                                }
                                float2 _15058 = (_14996 / _291._m22.xy) + float2(0.5);
                                float2 _15059 = floor(_15058);
                                float2 _15064 = _15058 - _15059;
                                float2 _15067 = _15059 - float2(0.5);
                                bool _15071 = _15035 == 1;
                                if (_15071)
                                {
                                    float2 _15074 = _15064 * 2.0;
                                    _15019[0] = float2(3.0) - _15074;
                                    _15019[1] = float2(1.0) + _15074;
                                    _15020[0] = ((float2(2.0) - _15064) / _15019[0]) - float2(1.0);
                                    _15020[1] = (_15064 / _15019[1]) + float2(1.0);
                                }
                                else
                                {
                                    float2 _15101 = _15064 * 3.0;
                                    _15019[0] = float2(4.0) - _15101;
                                    _15019[1] = float2(7.0);
                                    _15019[2] = float2(1.0) + _15101;
                                    _15020[0] = ((float2(3.0) - (_15064 * 2.0)) / _15019[0]) - float2(2.0);
                                    _15020[1] = (float2(3.0) + _15064) / _15019[1];
                                    _15020[2] = (_15064 / _15019[2]) + float2(2.0);
                                }
                                int _20087 = _15071 ? 2 : 3;
                                int _19021;
                                float _19024;
                                _19024 = 0.0;
                                _19021 = 0;
                                float _19030;
                                for (; _19021 < _20087; _19024 = _19030, _19021++)
                                {
                                    _19030 = _19024;
                                    for (int _19027 = 0; _19027 < _20087; )
                                    {
                                        _19030 += ((_15019[_19027].x * _15019[_19021].y) * spvDepthCast(_311).sample_compare(_311Smplr, float3(fast::clamp(_291._m22.xy * (_15067 + float2(_15020[_19027].x, _15020[_19021].y)), _15009.xy, _15009.zw), _14733).xy, _14733));
                                        _19027++;
                                        continue;
                                    }
                                }
                                _19031 = _19024 * (_15071 ? 0.0625 : 0.0069444444961845874786376953125);
                                break;
                            } while(false);
                            _19043 = _19031;
                            break;
                        } while(false);
                        _19044 = _19043;
                    }
                    else
                    {
                        _19044 = 1.0;
                    }
                    float _11893 = dot(_18818, _14451);
                    float3 _11897 = float3(dot(_18816, _14451), _11893, dot(_18820, _14451));
                    float3 _19047;
                    if (_11697)
                    {
                        float3 _15205 = fast::clamp(_11897, float3(-1.0), float3(1.0));
                        float3 _15212 = sqrt(fast::max(float3(1.0) - (_15205 * _15205), float3(0.0)));
                        float3 _19046;
                        _19046 = float3(0.0);
                        for (int _19045 = 0; _19045 < 2; )
                        {
                            _19046 += ((((fast::max(_15205, float3(0.0)) * 0.533333301544189453125) + ((fast::max((_15205 * _2331[_19045]) - (_15212 * _2339[_19045]), float3(0.0)) + fast::max((_15205 * _2331[_19045]) + (_15212 * _2339[_19045]), float3(0.0))) * 0.22207589447498321533203125)) + ((fast::max((_15205 * _2345[_19045]) - (_15212 * _2352[_19045]), float3(0.0)) + fast::max((_15205 * _2345[_19045]) + (_15212 * _2352[_19045]), float3(0.0))) * 0.011257399804890155792236328125)) * ((_19045 == 0) ? 0.430000007152557373046875 : 0.569999992847442626953125));
                            _19045++;
                            continue;
                        }
                        _19047 = mix(fast::max(_11897, float3(0.0)), _19046, _11681);
                    }
                    else
                    {
                        _19047 = float3(fast::max(_11893, 0.0));
                    }
                    float3 _11916 = _18981 + ((_19047 * _14482) * _19044);
                    float3 _19087;
                    do
                    {
                        float3 _15322 = fast::normalize(_14451 + _4578);
                        float _15326 = fast::clamp(dot(_18807, _14451), 0.0, 1.0);
                        if (_15326 <= 0.0)
                        {
                            _19087 = float3(0.0);
                            break;
                        }
                        float _15334 = fast::clamp(dot(_18807, _15322), 0.0, 1.0);
                        float _15345 = fast::clamp(_18805 * _2077._m2.x, 0.04500000178813934326171875, 1.0);
                        float _15348 = _15345 * _15345;
                        float _15408 = _15348 * _15348;
                        float _15411 = _15334 * _15334;
                        float _15415 = (_15411 * (_15408 - 1.0)) + 1.0;
                        float _15433 = _11667 * _11667;
                        float _15435 = 1.0 - _15408;
                        float _15444 = _15326 * _15326;
                        float _15356 = (_15408 / ((3.1415927410125732421875 * _15415) * _15415)) * (0.5 / fast::max((_15326 * sqrt((_15433 * _15435) + _15408)) + (_11667 * sqrt((_15444 * _15435) + _15408)), 9.9999997473787516355514526367188e-06));
                        float _19086;
                        if (_2077._m2.w > 0.5)
                        {
                            float _15365 = fast::clamp(_18805 * _2077._m2.y, 0.04500000178813934326171875, 1.0);
                            float _15368 = _15365 * _15365;
                            float _15463 = _15368 * _15368;
                            float _15470 = (_15411 * (_15463 - 1.0)) + 1.0;
                            float _15490 = 1.0 - _15463;
                            _19086 = mix(_15356, (_15463 / ((3.1415927410125732421875 * _15470) * _15470)) * (0.5 / fast::max((_15326 * sqrt((_15433 * _15490) + _15463)) + (_11667 * sqrt((_15444 * _15490) + _15463)), 9.9999997473787516355514526367188e-06)), _2077._m2.z);
                        }
                        else
                        {
                            _19086 = _15356;
                        }
                        _19087 = (_11675 + ((float3(1.0) - _11675) * powr(1.0 - fast::clamp(dot(_4578, _15322), 0.0, 1.0), 5.0))) * ((_19086 * 3.1415927410125732421875) * _15326);
                        break;
                    } while(false);
                    _11929 = _19016 + ((_19087 * _14482) * _19044);
                    bool _11938;
                    if (_11707)
                    {
                        _11938 = dot(_4589, _14451) < 0.3499999940395355224609375;
                    }
                    else
                    {
                        _11938 = _11707;
                    }
                    if (_11938)
                    {
                        float3 _19199;
                        if (_4594)
                        {
                            float3 _19198;
                            do
                            {
                                if (_14417 >= uint(_291._m21.z + _291._m21.w))
                                {
                                    float _15607 = (1200.0 / _11721) / (0.60000002384185791015625 + (6.0 * _2077._m1.y));
                                    float _15614 = (-_15607) * _15607;
                                    _19198 = (((((float3(0.23299999535083770751953125, 0.4550000131130218505859375, 0.648999989032745361328125) * exp(_15614 * 156.25)) + (float3(0.100000001490116119384765625, 0.3359999954700469970703125, 0.3440000116825103759765625) * exp(_15614 * 20.6611576080322265625))) + (float3(0.1180000007152557373046875, 0.19799999892711639404296875, 0.0) * exp(_15614 * 5.3475933074951171875))) + (float3(0.112999998033046722412109375, 0.007000000216066837310791015625, 0.007000000216066837310791015625) * exp(_15614 * 1.763668537139892578125))) + (float3(0.3580000102519989013671875, 0.0040000001899898052215576171875, 0.0) * exp(_15614 * 0.50251257419586181640625))) + (float3(0.078000001609325408935546875, 0.0, 0.0) * exp(_15614 * 0.13495276868343353271484375));
                                    break;
                                }
                                uint _15679;
                                bool _15682;
                                float3 _15552 = in.m_1840 - (_4589 * 0.0040000001899898052215576171875);
                                float3 _15556 = _15552 + (_14451 * 0.0199999995529651641845703125);
                                float _19135;
                                do
                                {
                                    _15679 = uint(_291._m21.z);
                                    _15682 = _14417 < _15679;
                                    if (_15682)
                                    {
                                        float _15701 = _291._m26[_14417].z * fast::max((_291._m15[_14417] * float4(_15556, 1.0)).w, 0.0);
                                        float4 _15725 = _291._m15[_14417] * float4((_15556 + (_4589 * (_15701 * _291._m25.x))) + (_14451 * (_15701 * _291._m25.y)), 1.0);
                                        float _15727 = _15725.w;
                                        if (_15727 <= 0.0)
                                        {
                                            _19135 = 1.0;
                                            break;
                                        }
                                        float3 _15736 = _15725.xyz / float3(_15727);
                                        float _15738 = _15736.x;
                                        bool _15739 = _15738 < 0.0;
                                        bool _15746;
                                        if (!_15739)
                                        {
                                            _15746 = _15738 > 1.0;
                                        }
                                        else
                                        {
                                            _15746 = _15739;
                                        }
                                        bool _15753;
                                        if (!_15746)
                                        {
                                            _15753 = _15736.y < 0.0;
                                        }
                                        else
                                        {
                                            _15753 = _15746;
                                        }
                                        bool _15760;
                                        if (!_15753)
                                        {
                                            _15760 = _15736.y > 1.0;
                                        }
                                        else
                                        {
                                            _15760 = _15753;
                                        }
                                        bool _15767;
                                        if (!_15760)
                                        {
                                            _15767 = _15736.z > 1.0;
                                        }
                                        else
                                        {
                                            _15767 = _15760;
                                        }
                                        if (_15767)
                                        {
                                            _19135 = 1.0;
                                            break;
                                        }
                                        float _15773 = _15736.z;
                                        float2 _15939 = _291._m22.xy * 0.5;
                                        float2 _15944 = _291._m26[_14417].xy + (_15736.xy * _291._m23.zw);
                                        float4 _15957 = float4(_291._m26[_14417].xy + _15939, (_291._m26[_14417].xy + _291._m23.zw) - _15939);
                                        float _19134;
                                        do
                                        {
                                            int _15983 = int(_291._m22.z);
                                            if (_15983 <= 0)
                                            {
                                                _19134 = spvDepthCast(_311).sample_compare(_311Smplr, float3(fast::clamp(_15944, _15957.xy, _15957.zw), _15773).xy, _15773);
                                                break;
                                            }
                                            float2 _16006 = (_15944 / _291._m22.xy) + float2(0.5);
                                            float2 _16007 = floor(_16006);
                                            float2 _16012 = _16006 - _16007;
                                            float2 _16015 = _16007 - float2(0.5);
                                            bool _16019 = _15983 == 1;
                                            if (_16019)
                                            {
                                                float2 _16022 = _16012 * 2.0;
                                                _15967[0] = float2(3.0) - _16022;
                                                _15967[1] = float2(1.0) + _16022;
                                                _15968[0] = ((float2(2.0) - _16012) / _15967[0]) - float2(1.0);
                                                _15968[1] = (_16012 / _15967[1]) + float2(1.0);
                                            }
                                            else
                                            {
                                                float2 _16049 = _16012 * 3.0;
                                                _15967[0] = float2(4.0) - _16049;
                                                _15967[1] = float2(7.0);
                                                _15967[2] = float2(1.0) + _16049;
                                                _15968[0] = ((float2(3.0) - (_16012 * 2.0)) / _15967[0]) - float2(2.0);
                                                _15968[1] = (float2(3.0) + _16012) / _15967[1];
                                                _15968[2] = (_16012 / _15967[2]) + float2(2.0);
                                            }
                                            int _20089 = _16019 ? 2 : 3;
                                            int _19124;
                                            float _19127;
                                            _19127 = 0.0;
                                            _19124 = 0;
                                            float _19133;
                                            for (; _19124 < _20089; _19127 = _19133, _19124++)
                                            {
                                                _19133 = _19127;
                                                for (int _19130 = 0; _19130 < _20089; )
                                                {
                                                    _19133 += ((_15967[_19130].x * _15967[_19124].y) * spvDepthCast(_311).sample_compare(_311Smplr, float3(fast::clamp(_291._m22.xy * (_16015 + float2(_15968[_19130].x, _15968[_19124].y)), _15957.xy, _15957.zw), _15773).xy, _15773));
                                                    _19130++;
                                                    continue;
                                                }
                                            }
                                            _19134 = _19127 * (_16019 ? 0.0625 : 0.0069444444961845874786376953125);
                                            break;
                                        } while(false);
                                        _19135 = _19134;
                                        break;
                                    }
                                    uint _15783 = _14417 - _15679;
                                    if (_15783 >= uint(_291._m21.w))
                                    {
                                        _19135 = 1.0;
                                        break;
                                    }
                                    float _15804 = _291._m27[_15783].w * length(_15556 - _291._m27[_15783].xyz);
                                    float3 _15822 = ((_15556 + (_4589 * (_15804 * _291._m25.x))) + (_14451 * (_15804 * _291._m25.y))) - _291._m27[_15783].xyz;
                                    float3 _15824 = abs(_15822);
                                    float _15826 = _15824.x;
                                    float _15828 = _15824.y;
                                    bool _15829 = _15826 >= _15828;
                                    bool _15837;
                                    if (_15829)
                                    {
                                        _15837 = _15826 >= _15824.z;
                                    }
                                    else
                                    {
                                        _15837 = _15829;
                                    }
                                    float _19109;
                                    int _19111;
                                    if (_15837)
                                    {
                                        _19111 = (_15822.x > 0.0) ? 0 : 1;
                                        _19109 = _15826;
                                    }
                                    else
                                    {
                                        float _15849 = _15824.z;
                                        bool _15850 = _15828 >= _15849;
                                        int _19112;
                                        if (_15850)
                                        {
                                            _19112 = (_15822.y > 0.0) ? 2 : 3;
                                        }
                                        else
                                        {
                                            _19112 = (_15822.z > 0.0) ? 4 : 5;
                                        }
                                        _19111 = _19112;
                                        _19109 = _15850 ? _15828 : _15849;
                                    }
                                    if (_19109 <= 0.0)
                                    {
                                        _19135 = 1.0;
                                        break;
                                    }
                                    float2 _15887 = float2(dot(_15822, _969[_19111]), dot(_15822, _978[_19111])) / float2(_19109 * _291._m24.z);
                                    float _15894 = _291._m28[_15783].z + (_291._m28[_15783].w / _19109);
                                    if (_15894 > 1.0)
                                    {
                                        _19135 = 1.0;
                                        break;
                                    }
                                    float2 _15912 = _291._m28[_15783].xy + (float2(float(spvSMod(_19111, 3)), float(_19111 / 3)) * _291._m24.xy);
                                    float2 _16152 = _291._m22.xy * 0.5;
                                    float2 _16157 = _15912 + (float2(0.5 + (0.5 * _15887.x), 0.5 - (0.5 * _15887.y)) * _291._m24.xy);
                                    float4 _16170 = float4(_15912 + _16152, (_15912 + _291._m24.xy) - _16152);
                                    float _19123;
                                    do
                                    {
                                        int _16196 = int(_291._m22.z);
                                        if (_16196 <= 0)
                                        {
                                            _19123 = spvDepthCast(_311).sample_compare(_311Smplr, float3(fast::clamp(_16157, _16170.xy, _16170.zw), _15894).xy, _15894);
                                            break;
                                        }
                                        float2 _16219 = (_16157 / _291._m22.xy) + float2(0.5);
                                        float2 _16220 = floor(_16219);
                                        float2 _16225 = _16219 - _16220;
                                        float2 _16228 = _16220 - float2(0.5);
                                        bool _16232 = _16196 == 1;
                                        if (_16232)
                                        {
                                            float2 _16235 = _16225 * 2.0;
                                            _16180[0] = float2(3.0) - _16235;
                                            _16180[1] = float2(1.0) + _16235;
                                            _16181[0] = ((float2(2.0) - _16225) / _16180[0]) - float2(1.0);
                                            _16181[1] = (_16225 / _16180[1]) + float2(1.0);
                                        }
                                        else
                                        {
                                            float2 _16262 = _16225 * 3.0;
                                            _16180[0] = float2(4.0) - _16262;
                                            _16180[1] = float2(7.0);
                                            _16180[2] = float2(1.0) + _16262;
                                            _16181[0] = ((float2(3.0) - (_16225 * 2.0)) / _16180[0]) - float2(2.0);
                                            _16181[1] = (float2(3.0) + _16225) / _16180[1];
                                            _16181[2] = (_16225 / _16180[2]) + float2(2.0);
                                        }
                                        int _20092 = _16232 ? 2 : 3;
                                        int _19113;
                                        float _19116;
                                        _19116 = 0.0;
                                        _19113 = 0;
                                        float _19122;
                                        for (; _19113 < _20092; _19116 = _19122, _19113++)
                                        {
                                            _19122 = _19116;
                                            for (int _19119 = 0; _19119 < _20092; )
                                            {
                                                _19122 += ((_16180[_19119].x * _16180[_19113].y) * spvDepthCast(_311).sample_compare(_311Smplr, float3(fast::clamp(_291._m22.xy * (_16228 + float2(_16181[_19119].x, _16181[_19113].y)), _16170.xy, _16170.zw), _15894).xy, _15894));
                                                _19119++;
                                                continue;
                                            }
                                        }
                                        _19123 = _19116 * (_16232 ? 0.0625 : 0.0069444444961845874786376953125);
                                        break;
                                    } while(false);
                                    _19135 = _19123;
                                    break;
                                } while(false);
                                if (_19135 <= 0.0)
                                {
                                    _19198 = float3(0.0);
                                    break;
                                }
                                float3 _19137;
                                float3 _19138;
                                _19138 = float3(1.0);
                                _19137 = float3(0.0);
                                float3 _15590;
                                float3 _16400;
                                for (int _19136 = 0; _19136 < 4; _19138 = _16400, _19137 = _15590, _19136++)
                                {
                                    float _16364 = (_2184[_19136] * 1000.0) / (0.60000002384185791015625 + (6.0 * _2077._m1.y));
                                    float _16371 = (-_16364) * _16364;
                                    _16400 = (((((float3(0.23299999535083770751953125, 0.4550000131130218505859375, 0.648999989032745361328125) * exp(_16371 * 156.25)) + (float3(0.100000001490116119384765625, 0.3359999954700469970703125, 0.3440000116825103759765625) * exp(_16371 * 20.6611576080322265625))) + (float3(0.1180000007152557373046875, 0.19799999892711639404296875, 0.0) * exp(_16371 * 5.3475933074951171875))) + (float3(0.112999998033046722412109375, 0.007000000216066837310791015625, 0.007000000216066837310791015625) * exp(_16371 * 1.763668537139892578125))) + (float3(0.3580000102519989013671875, 0.0040000001899898052215576171875, 0.0) * exp(_16371 * 0.50251257419586181640625))) + (float3(0.078000001609325408935546875, 0.0, 0.0) * exp(_16371 * 0.13495276868343353271484375));
                                    float3 _15583 = _15552 + (_14451 * _2184[_19136]);
                                    float _19165;
                                    do
                                    {
                                        if (_15682)
                                        {
                                            float _16458 = _291._m26[_14417].z * fast::max((_291._m15[_14417] * float4(_15583, 1.0)).w, 0.0);
                                            float4 _16482 = _291._m15[_14417] * float4((_15583 + (_4589 * (_16458 * _291._m25.x))) + (_14451 * (_16458 * _291._m25.y)), 1.0);
                                            float _16484 = _16482.w;
                                            if (_16484 <= 0.0)
                                            {
                                                _19165 = 1.0;
                                                break;
                                            }
                                            float3 _16493 = _16482.xyz / float3(_16484);
                                            float _16495 = _16493.x;
                                            bool _16496 = _16495 < 0.0;
                                            bool _16503;
                                            if (!_16496)
                                            {
                                                _16503 = _16495 > 1.0;
                                            }
                                            else
                                            {
                                                _16503 = _16496;
                                            }
                                            bool _16510;
                                            if (!_16503)
                                            {
                                                _16510 = _16493.y < 0.0;
                                            }
                                            else
                                            {
                                                _16510 = _16503;
                                            }
                                            bool _16517;
                                            if (!_16510)
                                            {
                                                _16517 = _16493.y > 1.0;
                                            }
                                            else
                                            {
                                                _16517 = _16510;
                                            }
                                            bool _16524;
                                            if (!_16517)
                                            {
                                                _16524 = _16493.z > 1.0;
                                            }
                                            else
                                            {
                                                _16524 = _16517;
                                            }
                                            if (_16524)
                                            {
                                                _19165 = 1.0;
                                                break;
                                            }
                                            float _16530 = _16493.z;
                                            float2 _16696 = _291._m22.xy * 0.5;
                                            float2 _16701 = _291._m26[_14417].xy + (_16493.xy * _291._m23.zw);
                                            float4 _16714 = float4(_291._m26[_14417].xy + _16696, (_291._m26[_14417].xy + _291._m23.zw) - _16696);
                                            float _19164;
                                            do
                                            {
                                                int _16740 = int(_291._m22.z);
                                                if (_16740 <= 0)
                                                {
                                                    _19164 = spvDepthCast(_311).sample_compare(_311Smplr, float3(fast::clamp(_16701, _16714.xy, _16714.zw), _16530).xy, _16530);
                                                    break;
                                                }
                                                float2 _16763 = (_16701 / _291._m22.xy) + float2(0.5);
                                                float2 _16764 = floor(_16763);
                                                float2 _16769 = _16763 - _16764;
                                                float2 _16772 = _16764 - float2(0.5);
                                                bool _16776 = _16740 == 1;
                                                if (_16776)
                                                {
                                                    float2 _16779 = _16769 * 2.0;
                                                    _16724[0] = float2(3.0) - _16779;
                                                    _16724[1] = float2(1.0) + _16779;
                                                    _16725[0] = ((float2(2.0) - _16769) / _16724[0]) - float2(1.0);
                                                    _16725[1] = (_16769 / _16724[1]) + float2(1.0);
                                                }
                                                else
                                                {
                                                    float2 _16806 = _16769 * 3.0;
                                                    _16724[0] = float2(4.0) - _16806;
                                                    _16724[1] = float2(7.0);
                                                    _16724[2] = float2(1.0) + _16806;
                                                    _16725[0] = ((float2(3.0) - (_16769 * 2.0)) / _16724[0]) - float2(2.0);
                                                    _16725[1] = (float2(3.0) + _16769) / _16724[1];
                                                    _16725[2] = (_16769 / _16724[2]) + float2(2.0);
                                                }
                                                int _20094 = _16776 ? 2 : 3;
                                                int _19154;
                                                float _19157;
                                                _19157 = 0.0;
                                                _19154 = 0;
                                                float _19163;
                                                for (; _19154 < _20094; _19157 = _19163, _19154++)
                                                {
                                                    _19163 = _19157;
                                                    for (int _19160 = 0; _19160 < _20094; )
                                                    {
                                                        _19163 += ((_16724[_19160].x * _16724[_19154].y) * spvDepthCast(_311).sample_compare(_311Smplr, float3(fast::clamp(_291._m22.xy * (_16772 + float2(_16725[_19160].x, _16725[_19154].y)), _16714.xy, _16714.zw), _16530).xy, _16530));
                                                        _19160++;
                                                        continue;
                                                    }
                                                }
                                                _19164 = _19157 * (_16776 ? 0.0625 : 0.0069444444961845874786376953125);
                                                break;
                                            } while(false);
                                            _19165 = _19164;
                                            break;
                                        }
                                        uint _16540 = _14417 - _15679;
                                        if (_16540 >= uint(_291._m21.w))
                                        {
                                            _19165 = 1.0;
                                            break;
                                        }
                                        float _16561 = _291._m27[_16540].w * length(_15583 - _291._m27[_16540].xyz);
                                        float3 _16579 = ((_15583 + (_4589 * (_16561 * _291._m25.x))) + (_14451 * (_16561 * _291._m25.y))) - _291._m27[_16540].xyz;
                                        float3 _16581 = abs(_16579);
                                        float _16583 = _16581.x;
                                        float _16585 = _16581.y;
                                        bool _16586 = _16583 >= _16585;
                                        bool _16594;
                                        if (_16586)
                                        {
                                            _16594 = _16583 >= _16581.z;
                                        }
                                        else
                                        {
                                            _16594 = _16586;
                                        }
                                        float _19139;
                                        int _19141;
                                        if (_16594)
                                        {
                                            _19141 = (_16579.x > 0.0) ? 0 : 1;
                                            _19139 = _16583;
                                        }
                                        else
                                        {
                                            float _16606 = _16581.z;
                                            bool _16607 = _16585 >= _16606;
                                            int _19142;
                                            if (_16607)
                                            {
                                                _19142 = (_16579.y > 0.0) ? 2 : 3;
                                            }
                                            else
                                            {
                                                _19142 = (_16579.z > 0.0) ? 4 : 5;
                                            }
                                            _19141 = _19142;
                                            _19139 = _16607 ? _16585 : _16606;
                                        }
                                        if (_19139 <= 0.0)
                                        {
                                            _19165 = 1.0;
                                            break;
                                        }
                                        float2 _16644 = float2(dot(_16579, _969[_19141]), dot(_16579, _978[_19141])) / float2(_19139 * _291._m24.z);
                                        float _16651 = _291._m28[_16540].z + (_291._m28[_16540].w / _19139);
                                        if (_16651 > 1.0)
                                        {
                                            _19165 = 1.0;
                                            break;
                                        }
                                        float2 _16669 = _291._m28[_16540].xy + (float2(float(spvSMod(_19141, 3)), float(_19141 / 3)) * _291._m24.xy);
                                        float2 _16909 = _291._m22.xy * 0.5;
                                        float2 _16914 = _16669 + (float2(0.5 + (0.5 * _16644.x), 0.5 - (0.5 * _16644.y)) * _291._m24.xy);
                                        float4 _16927 = float4(_16669 + _16909, (_16669 + _291._m24.xy) - _16909);
                                        float _19153;
                                        do
                                        {
                                            int _16953 = int(_291._m22.z);
                                            if (_16953 <= 0)
                                            {
                                                _19153 = spvDepthCast(_311).sample_compare(_311Smplr, float3(fast::clamp(_16914, _16927.xy, _16927.zw), _16651).xy, _16651);
                                                break;
                                            }
                                            float2 _16976 = (_16914 / _291._m22.xy) + float2(0.5);
                                            float2 _16977 = floor(_16976);
                                            float2 _16982 = _16976 - _16977;
                                            float2 _16985 = _16977 - float2(0.5);
                                            bool _16989 = _16953 == 1;
                                            if (_16989)
                                            {
                                                float2 _16992 = _16982 * 2.0;
                                                _16937[0] = float2(3.0) - _16992;
                                                _16937[1] = float2(1.0) + _16992;
                                                _16938[0] = ((float2(2.0) - _16982) / _16937[0]) - float2(1.0);
                                                _16938[1] = (_16982 / _16937[1]) + float2(1.0);
                                            }
                                            else
                                            {
                                                float2 _17019 = _16982 * 3.0;
                                                _16937[0] = float2(4.0) - _17019;
                                                _16937[1] = float2(7.0);
                                                _16937[2] = float2(1.0) + _17019;
                                                _16938[0] = ((float2(3.0) - (_16982 * 2.0)) / _16937[0]) - float2(2.0);
                                                _16938[1] = (float2(3.0) + _16982) / _16937[1];
                                                _16938[2] = (_16982 / _16937[2]) + float2(2.0);
                                            }
                                            int _20097 = _16989 ? 2 : 3;
                                            int _19143;
                                            float _19146;
                                            _19146 = 0.0;
                                            _19143 = 0;
                                            float _19152;
                                            for (; _19143 < _20097; _19146 = _19152, _19143++)
                                            {
                                                _19152 = _19146;
                                                for (int _19149 = 0; _19149 < _20097; )
                                                {
                                                    _19152 += ((_16937[_19149].x * _16937[_19143].y) * spvDepthCast(_311).sample_compare(_311Smplr, float3(fast::clamp(_291._m22.xy * (_16985 + float2(_16938[_19149].x, _16938[_19143].y)), _16927.xy, _16927.zw), _16651).xy, _16651));
                                                    _19149++;
                                                    continue;
                                                }
                                            }
                                            _19153 = _19146 * (_16989 ? 0.0625 : 0.0069444444961845874786376953125);
                                            break;
                                        } while(false);
                                        _19165 = _19153;
                                        break;
                                    } while(false);
                                    _15590 = _19137 + ((_19138 - _16400) * _19165);
                                }
                                _19198 = _19137;
                                break;
                            } while(false);
                            _19199 = _19198;
                        }
                        else
                        {
                            float _17121 = (1200.0 / _11721) / (0.60000002384185791015625 + (6.0 * _2077._m1.y));
                            float _17128 = (-_17121) * _17121;
                            _19199 = (((((float3(0.23299999535083770751953125, 0.4550000131130218505859375, 0.648999989032745361328125) * exp(_17128 * 156.25)) + (float3(0.100000001490116119384765625, 0.3359999954700469970703125, 0.3440000116825103759765625) * exp(_17128 * 20.6611576080322265625))) + (float3(0.1180000007152557373046875, 0.19799999892711639404296875, 0.0) * exp(_17128 * 5.3475933074951171875))) + (float3(0.112999998033046722412109375, 0.007000000216066837310791015625, 0.007000000216066837310791015625) * exp(_17128 * 1.763668537139892578125))) + (float3(0.3580000102519989013671875, 0.0040000001899898052215576171875, 0.0) * exp(_17128 * 0.50251257419586181640625))) + (float3(0.078000001609325408935546875, 0.0, 0.0) * exp(_17128 * 0.13495276868343353271484375));
                        }
                        _19895 = _11916 + ((_19199 * _14482) * ((fast::clamp(0.300000011920928955078125 - dot(_4589, _14451), 0.0, 1.0) * _18808) * 2.0));
                    }
                    else
                    {
                        _19895 = _11916;
                    }
                }
                _18991 = _19016;
                _18979 = _18981;
            }
            else
            {
                _18991 = _11808;
                _18979 = _18980;
            }
            float _11984 = fast::clamp(_18805 * mix(_2077._m2.x, _2077._m2.y, _2077._m2.z), 0.04500000178813934326171875, 1.0);
            float3 _11988 = reflect(-_4578, _18807);
            bool _17166 = _291._m29.x > 0.5;
            float3 _18961;
            float3 _18968;
            if (_17166)
            {
                float _17240 = (_291._m29.z * _18807.x) - (_291._m29.w * _18807.z);
                float _17253 = (_291._m29.w * _18807.x) + (_291._m29.z * _18807.z);
                float _17271 = 1.09254801273345947265625 * _17240;
                spvUnsafeArray<float, 9> _17813 = spvUnsafeArray<float, 9>({ 0.2820949852466583251953125, 0.48860299587249755859375 * _18807.y, 0.48860299587249755859375 * _17253, 0.48860299587249755859375 * _17240, _17271 * _18807.y, (1.09254801273345947265625 * _18807.y) * _17253, 0.3153919875621795654296875 * (((3.0 * _17253) * _17253) - 1.0), _17271 * _17253, 0.546274006366729736328125 * ((_17240 * _17240) - (_18807.y * _18807.y)) });
                spvUnsafeArray<float, 9> _17185 = _17813;
                float3 _18946;
                _18946 = float3(0.0);
                for (int _18945 = 0; _18945 < 9; )
                {
                    _18946 += (_1326.read(uint2((int2(496, 256) + int2(_18945, 0))), 0).xyz * _17185[_18945]);
                    _18945++;
                    continue;
                }
                float _17366 = _11988.x;
                float _17371 = _11988.z;
                float2 _17403 = float2((precise::atan2((_291._m29.z * _17366) - (_291._m29.w * _17371), -((_291._m29.w * _17366) + (_291._m29.z * _17371))) * 0.15915493667125701904296875) + 0.5, acos(fast::clamp(_11988.y, -1.0, 1.0)) * 0.3183098733425140380859375);
                float _17335 = _11984 * 5.0;
                int _17338 = min(int(_17335), 4);
                float2 _17424 = (_17403 * float2(_1388[_17338].zw)) - float2(0.5);
                float2 _17426 = floor(_17424);
                float2 _17429 = _17424 - _17426;
                int _17432 = int(_17426.x);
                int _17435 = int(_17426.y);
                int _18947;
                if (_17432 < 0)
                {
                    _18947 = _17432 + _1388[_17338].z;
                }
                else
                {
                    _18947 = _17432;
                }
                int _18948;
                if (_18947 >= _1388[_17338].z)
                {
                    _18948 = _18947 - _1388[_17338].z;
                }
                else
                {
                    _18948 = _18947;
                }
                int _17455 = _18948 + 1;
                int _20098 = (_17455 == _1388[_17338].z) ? 0 : _17455;
                int _17470 = min((_17435 + 1), (_1388[_17338].w - 1));
                int _17472 = max(_17435, 0);
                float3 _17525 = float3(_17429.x);
                int _17345 = _17338 + 1;
                float2 _17557 = (_17403 * float2(_1388[_17345].zw)) - float2(0.5);
                float2 _17559 = floor(_17557);
                float2 _17562 = _17557 - _17559;
                int _17565 = int(_17559.x);
                int _17568 = int(_17559.y);
                int _18954;
                if (_17565 < 0)
                {
                    _18954 = _17565 + _1388[_17345].z;
                }
                else
                {
                    _18954 = _17565;
                }
                int _18955;
                if (_18954 >= _1388[_17345].z)
                {
                    _18955 = _18954 - _1388[_17345].z;
                }
                else
                {
                    _18955 = _18954;
                }
                int _17588 = _18955 + 1;
                int _20099 = (_17588 == _1388[_17345].z) ? 0 : _17588;
                int _17603 = min((_17568 + 1), (_1388[_17345].w - 1));
                int _17605 = max(_17568, 0);
                float3 _17658 = float3(_17562.x);
                float3 _17360 = mix(mix(mix(_1326.read(uint2((_1388[_17338].xy + int2(_18948, _17472))), 0).xyz, _1326.read(uint2((_1388[_17338].xy + int2(_20098, _17472))), 0).xyz, _17525), mix(_1326.read(uint2((_1388[_17338].xy + int2(_18948, _17470))), 0).xyz, _1326.read(uint2((_1388[_17338].xy + int2(_20098, _17470))), 0).xyz, _17525), float3(_17429.y)), mix(mix(_1326.read(uint2((_1388[_17345].xy + int2(_18955, _17605))), 0).xyz, _1326.read(uint2((_1388[_17345].xy + int2(_20099, _17605))), 0).xyz, _17658), mix(_1326.read(uint2((_1388[_17345].xy + int2(_18955, _17603))), 0).xyz, _1326.read(uint2((_1388[_17345].xy + int2(_20099, _17603))), 0).xyz, _17658), float3(_17562.y)), float3(_17335 - float(_17338))) * _291._m29.y;
                _18968 = _17360;
                _18961 = fast::max(_18946, float3(0.0)) * _291._m29.y;
            }
            else
            {
                float3 _17686 = mix(_291._m9.xyz, _291._m8.xyz, float3((_18807.y * 0.5) + 0.5)) * _291._m8.w;
                _18968 = mix(mix(_291._m9.xyz, _291._m8.xyz, float3((_11988.y * 0.5) + 0.5)) * _291._m8.w, _17686, float3(_11984));
                _18961 = _17686;
            }
            float2 _18969;
            if (_17166)
            {
                _18969 = _1432.sample(_1434, (((float2(_11667, _11984) * 31.0) + float2(0.5)) * float2(0.03125))).xy;
            }
            else
            {
                float4 _17747 = (float4(-1.0, -0.0274999998509883880615234375, -0.572000026702880859375, 0.02199999988079071044921875) * _11984) + float4(1.0, 0.0425000004470348358154296875, 1.03999996185302734375, -0.039999999105930328369140625);
                float _17749 = _17747.x;
                _18969 = (float2(-1.03999996185302734375, 1.03999996185302734375) * ((fast::min(_17749 * _17749, exp2((-9.27999973297119140625) * _11667)) * _17749) + _17747.y)) + _17747.zw;
            }
            float3 _12005 = (_11675 * _18969.x) + float3(_18969.y);
            float3 _12023 = _18991 + ((_12005 * _18968) * _18804);
            _19549 = _12023;
            _19407 = ((_18771 * (1.0 - _18806)) * ((_18979 * (float3(1.0) - _11675)) + (((float3(1.0) - _12005) * _18961) * _18804))) + _12023;
        }
        _19544 = _19549;
        _19404 = _19407;
    }
    float4 _4892 = _4887.sample(_1328, _4356);
    float _4910 = -length(_4577);
    float _19540;
    if (_291._m9.w != 0.0)
    {
        float _4934 = _291._m9.w * (in.m_1840 - _291._m6.xyz).y;
        float _19537;
        if (abs(_4934) < 9.9999997473787516355514526367188e-05)
        {
            _19537 = 1.0 - (0.5 * _4934);
        }
        else
        {
            _19537 = (1.0 - exp(fast::min(-_4934, 60.0))) / _4934;
        }
        _19540 = 1.0 - exp((_4910 * (_291._m7.w * exp(fast::min((-_291._m9.w) * (_291._m6.y - _291._m6.w), 30.0)))) * _19537);
    }
    else
    {
        _19540 = 1.0 - exp(_4910 * _291._m7.w);
    }
    float3 _4984 = mix(mix(_19404, _18771, float3(_1678._m1.y)) + ((_1678._m5.xyz * _4892.xyz) * (float3(1.0) + in.m_4591.yzw)), _291._m7.xyz, float3(_19540));
    float3 _19555;
    if (_291._m33.w > 0.5)
    {
        _19555 = _4984 / (float3(1.0) + _4984);
    }
    else
    {
        _19555 = _4984;
    }
    bool _4998 = _2077._m1.w > 0.5;
    bool _5004;
    if (_4998)
    {
        _5004 = _291._m33.w < 0.5;
    }
    else
    {
        _5004 = _4998;
    }
    float _19556;
    if (_5004)
    {
        _19556 = (-1.0) - fast::max(dot(_19544 * (1.0 - _19540), float3(0.2125999927520751953125, 0.715200006961822509765625, 0.072200000286102294921875)), 0.0);
    }
    else
    {
        _19556 = (in.m_4365.w * _1678._m0.w) * _4363.w;
    }
    out.m_5021 = float4(_19555, _19556);
    float2 _19728;
    do
    {
        if (in.m_5031.w <= 0.0)
        {
            _19728 = float2(0.0);
            break;
        }
        _19728 = ((in.m_5031.xy / float2(in.m_5031.w)) - (in.m_5030.xy / float2(in.m_5030.w))) * float2(0.5, -0.5);
        break;
    } while(false);
    out.m_5029 = _19728;
    return out;
}

