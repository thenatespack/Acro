// Generated from fsr3_accumulate.comp by Scripts/compile-shaders.sh — do not edit.
// Edit the GLSL and rerun the script (needs glslc and spirv-cross).
// spirv-fnv1a64: d92921cec87a51c5
// glsl-fnv1a64: 87df2372a59d4de8

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

template <typename ImageT>
void spvImageFence(ImageT img) { img.fence(); }

struct _395
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

constant uint3 gl_WorkGroupSize [[maybe_unused]] = uint3(8u, 8u, 1u);
constant float _7463 = {};
constant float3 _7466 = {};

kernel void compute_main(constant _395& _397 [[buffer(16)]], texture2d<float> _596 [[texture(1)]], texture2d<float> _579 [[texture(2)]], texture2d<float> _485 [[texture(3)]], texture2d<float> _516 [[texture(4)]], texture2d<float> _534 [[texture(5)]], texture2d<float> _464 [[texture(6)]], texture2d<float, access::write> _505 [[texture(8)]], texture2d<float, access::read_write> _547 [[texture(9)]], sampler _524 [[sampler(1)]], uint3 gl_GlobalInvocationID [[thread_position_in_grid]])
{
    int2 _2267 = int2(gl_GlobalInvocationID.xy);
    float2 _2390 = float2(_2267) + float2(0.5);
    float2 _2393 = _2390 / float2(_397._m2);
    float2 _2399 = float2(_397._m0);
    float2 _2401 = _2393 + (_397._m5 / _2399);
    float2 _2517 = _2399 - float2(0.5);
    float2 _2543 = _2393 * _2399;
    int2 _2544 = int2(_2543);
    float4 _7467;
    if (all(uint2(_2544) < uint2(int2(_579.get_width(), _579.get_height()))))
    {
        _7467 = _579.read(uint2(_2544), 0);
    }
    else
    {
        _7467 = float4(0.0);
    }
    float _2573 = length(_7467.xy * float2(3840.0, 2160.0));
    float2 _2580 = _2393 + _7467.xy;
    float _2589 = _2580.x;
    bool _2590 = _2589 >= 0.0;
    bool _2596;
    if (_2590)
    {
        _2596 = _2589 <= 1.0;
    }
    else
    {
        _2596 = _2590;
    }
    bool _2608;
    if (_2596)
    {
        float _2599 = _2580.y;
        bool _2600 = _2599 >= 0.0;
        bool _2606;
        if (_2600)
        {
            _2606 = _2599 <= 1.0;
        }
        else
        {
            _2606 = _2600;
        }
        _2608 = _2606;
    }
    else
    {
        _2608 = _2596;
    }
    float2 _2678 = float2(_397._m0 / int2(2));
    bool _2445;
    if (_2608)
    {
        _2445 = 0.0 == _397._m12;
    }
    else
    {
        _2445 = !_2608;
    }
    float4 _2719 = _596.sample(_524, (fast::max(float2(0.5), fast::min(_2401 * _2399, _2517)) / _2399), level(0.0));
    float _2723 = fast::clamp(_2719.x, 0.0, 1.0);
    float _2727 = fast::clamp(_2719.y, 0.0, 1.0);
    float _2731 = fast::clamp(_2719.z, 0.0, 1.0);
    float _2735 = fast::clamp(_2719.w, 0.0, 1.0);
    float _2474 = _2735 * float(round(_2735 * 100.0) > 1.0);
    bool _2311;
    if (_2608)
    {
        _2311 = !_2445;
    }
    else
    {
        _2311 = _2608;
    }
    float _7543;
    float3 _7545;
    if (_2311)
    {
        float2 _2791 = (_2580 * float2(_397._m3)) - float2(0.5);
        float2 _2824 = fract(_2791);
        int2 _2814 = int2(floor(float2(fast::max(0.0, fast::min(float(_397._m3.x - 1), _2791.x)), fast::max(0.0, fast::min(float(_397._m3.y - 1), _2791.y)))));
        int2 _3006 = _2814 + int2(-1);
        int _3009 = _397._m3.x - 2;
        int _3017 = _397._m3.y - 2;
        int2 _7755 = int2(max(1, min(_3006.x, _3009)), max(1, min(_3006.y, _3017)));
        float4 _7502;
        if (all(uint2(_7755) < uint2(int2(_485.get_width(), _485.get_height()))))
        {
            _7502 = _485.read(uint2(_7755), 0);
        }
        else
        {
            _7502 = float4(0.0);
        }
        int2 _3079 = _2814 + int2(0, -1);
        int2 _7756 = int2(max(1, min(_3079.x, _3009)), max(1, min(_3079.y, _3017)));
        float4 _7503;
        if (all(uint2(_7756) < uint2(int2(_485.get_width(), _485.get_height()))))
        {
            _7503 = _485.read(uint2(_7756), 0);
        }
        else
        {
            _7503 = float4(0.0);
        }
        int2 _3152 = _2814 + int2(1, -1);
        int2 _7757 = int2(max(1, min(_3152.x, _3009)), max(1, min(_3152.y, _3017)));
        float4 _7504;
        if (all(uint2(_7757) < uint2(int2(_485.get_width(), _485.get_height()))))
        {
            _7504 = _485.read(uint2(_7757), 0);
        }
        else
        {
            _7504 = float4(0.0);
        }
        int2 _3225 = _2814 + int2(2, -1);
        int2 _7758 = int2(max(1, min(_3225.x, _3009)), max(1, min(_3225.y, _3017)));
        float4 _7505;
        if (all(uint2(_7758) < uint2(int2(_485.get_width(), _485.get_height()))))
        {
            _7505 = _485.read(uint2(_7758), 0);
        }
        else
        {
            _7505 = float4(0.0);
        }
        int2 _3298 = _2814 + int2(-1, 0);
        int2 _7759 = int2(max(1, min(_3298.x, _3009)), max(1, min(_3298.y, _3017)));
        float4 _7506;
        if (all(uint2(_7759) < uint2(int2(_485.get_width(), _485.get_height()))))
        {
            _7506 = _485.read(uint2(_7759), 0);
        }
        else
        {
            _7506 = float4(0.0);
        }
        int2 _7760 = int2(max(1, min(_2814.x, _3009)), max(1, min(_2814.y, _3017)));
        float4 _7507;
        if (all(uint2(_7760) < uint2(int2(_485.get_width(), _485.get_height()))))
        {
            _7507 = _485.read(uint2(_7760), 0);
        }
        else
        {
            _7507 = float4(0.0);
        }
        int2 _3444 = _2814 + int2(1, 0);
        int2 _7761 = int2(max(1, min(_3444.x, _3009)), max(1, min(_3444.y, _3017)));
        float4 _7508;
        if (all(uint2(_7761) < uint2(int2(_485.get_width(), _485.get_height()))))
        {
            _7508 = _485.read(uint2(_7761), 0);
        }
        else
        {
            _7508 = float4(0.0);
        }
        int2 _3517 = _2814 + int2(2, 0);
        int2 _7762 = int2(max(1, min(_3517.x, _3009)), max(1, min(_3517.y, _3017)));
        float4 _7509;
        if (all(uint2(_7762) < uint2(int2(_485.get_width(), _485.get_height()))))
        {
            _7509 = _485.read(uint2(_7762), 0);
        }
        else
        {
            _7509 = float4(0.0);
        }
        int2 _3590 = _2814 + int2(-1, 1);
        int2 _7763 = int2(max(1, min(_3590.x, _3009)), max(1, min(_3590.y, _3017)));
        float4 _7510;
        if (all(uint2(_7763) < uint2(int2(_485.get_width(), _485.get_height()))))
        {
            _7510 = _485.read(uint2(_7763), 0);
        }
        else
        {
            _7510 = float4(0.0);
        }
        int2 _3663 = _2814 + int2(0, 1);
        int2 _7764 = int2(max(1, min(_3663.x, _3009)), max(1, min(_3663.y, _3017)));
        float4 _7511;
        if (all(uint2(_7764) < uint2(int2(_485.get_width(), _485.get_height()))))
        {
            _7511 = _485.read(uint2(_7764), 0);
        }
        else
        {
            _7511 = float4(0.0);
        }
        int2 _3736 = _2814 + int2(1);
        int2 _7765 = int2(max(1, min(_3736.x, _3009)), max(1, min(_3736.y, _3017)));
        float4 _7512;
        if (all(uint2(_7765) < uint2(int2(_485.get_width(), _485.get_height()))))
        {
            _7512 = _485.read(uint2(_7765), 0);
        }
        else
        {
            _7512 = float4(0.0);
        }
        int2 _3809 = _2814 + int2(2, 1);
        int2 _7766 = int2(max(1, min(_3809.x, _3009)), max(1, min(_3809.y, _3017)));
        float4 _7513;
        if (all(uint2(_7766) < uint2(int2(_485.get_width(), _485.get_height()))))
        {
            _7513 = _485.read(uint2(_7766), 0);
        }
        else
        {
            _7513 = float4(0.0);
        }
        int2 _3882 = _2814 + int2(-1, 2);
        int2 _7767 = int2(max(1, min(_3882.x, _3009)), max(1, min(_3882.y, _3017)));
        float4 _7514;
        if (all(uint2(_7767) < uint2(int2(_485.get_width(), _485.get_height()))))
        {
            _7514 = _485.read(uint2(_7767), 0);
        }
        else
        {
            _7514 = float4(0.0);
        }
        int2 _3955 = _2814 + int2(0, 2);
        int2 _7768 = int2(max(1, min(_3955.x, _3009)), max(1, min(_3955.y, _3017)));
        float4 _7515;
        if (all(uint2(_7768) < uint2(int2(_485.get_width(), _485.get_height()))))
        {
            _7515 = _485.read(uint2(_7768), 0);
        }
        else
        {
            _7515 = float4(0.0);
        }
        int2 _4028 = _2814 + int2(1, 2);
        int2 _7769 = int2(max(1, min(_4028.x, _3009)), max(1, min(_4028.y, _3017)));
        float4 _7516;
        if (all(uint2(_7769) < uint2(int2(_485.get_width(), _485.get_height()))))
        {
            _7516 = _485.read(uint2(_7769), 0);
        }
        else
        {
            _7516 = float4(0.0);
        }
        int2 _4101 = _2814 + int2(2);
        int2 _7770 = int2(max(1, min(_4101.x, _3009)), max(1, min(_4101.y, _3017)));
        float4 _7517;
        if (all(uint2(_7770) < uint2(int2(_485.get_width(), _485.get_height()))))
        {
            _7517 = _485.read(uint2(_7770), 0);
        }
        else
        {
            _7517 = float4(0.0);
        }
        float _4210 = _2824.x;
        float _4349 = fast::min(abs((-1.0) - _4210), 2.0);
        bool _4355 = abs(_4349) < 6.099999882280826568603515625e-05;
        float _7518;
        if (_4355)
        {
            _7518 = 1.0;
        }
        else
        {
            float _4359 = 3.1415927410125732421875 * _4349;
            float _4365 = 1.57079637050628662109375 * _4349;
            _7518 = (sin(_4359) / _4359) * (sin(_4365) / _4365);
        }
        float _4387 = fast::min(abs(-_4210), 2.0);
        bool _4393 = abs(_4387) < 6.099999882280826568603515625e-05;
        float _7519;
        if (_4393)
        {
            _7519 = 1.0;
        }
        else
        {
            float _4397 = 3.1415927410125732421875 * _4387;
            float _4403 = 1.57079637050628662109375 * _4387;
            _7519 = (sin(_4397) / _4397) * (sin(_4403) / _4403);
        }
        float _4425 = fast::min(abs(1.0 - _4210), 2.0);
        bool _4431 = abs(_4425) < 6.099999882280826568603515625e-05;
        float _7520;
        if (_4431)
        {
            _7520 = 1.0;
        }
        else
        {
            float _4435 = 3.1415927410125732421875 * _4425;
            float _4441 = 1.57079637050628662109375 * _4425;
            _7520 = (sin(_4435) / _4435) * (sin(_4441) / _4441);
        }
        float _4463 = fast::min(abs(2.0 - _4210), 2.0);
        bool _4469 = abs(_4463) < 6.099999882280826568603515625e-05;
        float _7521;
        if (_4469)
        {
            _7521 = 1.0;
        }
        else
        {
            float _4473 = 3.1415927410125732421875 * _4463;
            float _4479 = 1.57079637050628662109375 * _4463;
            _7521 = (sin(_4473) / _4473) * (sin(_4479) / _4479);
        }
        float _7522;
        if (_4355)
        {
            _7522 = 1.0;
        }
        else
        {
            float _4557 = 3.1415927410125732421875 * _4349;
            float _4563 = 1.57079637050628662109375 * _4349;
            _7522 = (sin(_4557) / _4557) * (sin(_4563) / _4563);
        }
        float _7523;
        if (_4393)
        {
            _7523 = 1.0;
        }
        else
        {
            float _4595 = 3.1415927410125732421875 * _4387;
            float _4601 = 1.57079637050628662109375 * _4387;
            _7523 = (sin(_4595) / _4595) * (sin(_4601) / _4601);
        }
        float _7524;
        if (_4431)
        {
            _7524 = 1.0;
        }
        else
        {
            float _4633 = 3.1415927410125732421875 * _4425;
            float _4639 = 1.57079637050628662109375 * _4425;
            _7524 = (sin(_4633) / _4633) * (sin(_4639) / _4639);
        }
        float _7525;
        if (_4469)
        {
            _7525 = 1.0;
        }
        else
        {
            float _4671 = 3.1415927410125732421875 * _4463;
            float _4677 = 1.57079637050628662109375 * _4463;
            _7525 = (sin(_4671) / _4671) * (sin(_4677) / _4677);
        }
        float _7526;
        if (_4355)
        {
            _7526 = 1.0;
        }
        else
        {
            float _4755 = 3.1415927410125732421875 * _4349;
            float _4761 = 1.57079637050628662109375 * _4349;
            _7526 = (sin(_4755) / _4755) * (sin(_4761) / _4761);
        }
        float _7527;
        if (_4393)
        {
            _7527 = 1.0;
        }
        else
        {
            float _4793 = 3.1415927410125732421875 * _4387;
            float _4799 = 1.57079637050628662109375 * _4387;
            _7527 = (sin(_4793) / _4793) * (sin(_4799) / _4799);
        }
        float _7528;
        if (_4431)
        {
            _7528 = 1.0;
        }
        else
        {
            float _4831 = 3.1415927410125732421875 * _4425;
            float _4837 = 1.57079637050628662109375 * _4425;
            _7528 = (sin(_4831) / _4831) * (sin(_4837) / _4837);
        }
        float _7529;
        if (_4469)
        {
            _7529 = 1.0;
        }
        else
        {
            float _4869 = 3.1415927410125732421875 * _4463;
            float _4875 = 1.57079637050628662109375 * _4463;
            _7529 = (sin(_4869) / _4869) * (sin(_4875) / _4875);
        }
        float _7530;
        if (_4355)
        {
            _7530 = 1.0;
        }
        else
        {
            float _4953 = 3.1415927410125732421875 * _4349;
            float _4959 = 1.57079637050628662109375 * _4349;
            _7530 = (sin(_4953) / _4953) * (sin(_4959) / _4959);
        }
        float _7531;
        if (_4393)
        {
            _7531 = 1.0;
        }
        else
        {
            float _4991 = 3.1415927410125732421875 * _4387;
            float _4997 = 1.57079637050628662109375 * _4387;
            _7531 = (sin(_4991) / _4991) * (sin(_4997) / _4997);
        }
        float _7532;
        if (_4431)
        {
            _7532 = 1.0;
        }
        else
        {
            float _5029 = 3.1415927410125732421875 * _4425;
            float _5035 = 1.57079637050628662109375 * _4425;
            _7532 = (sin(_5029) / _5029) * (sin(_5035) / _5035);
        }
        float _7533;
        if (_4469)
        {
            _7533 = 1.0;
        }
        else
        {
            float _5067 = 3.1415927410125732421875 * _4463;
            float _5073 = 1.57079637050628662109375 * _4463;
            _7533 = (sin(_5067) / _5067) * (sin(_5073) / _5073);
        }
        float _4250 = _2824.y;
        float _5141 = fast::min(abs((-1.0) - _4250), 2.0);
        float _7534;
        if (abs(_5141) < 6.099999882280826568603515625e-05)
        {
            _7534 = 1.0;
        }
        else
        {
            float _5151 = 3.1415927410125732421875 * _5141;
            float _5157 = 1.57079637050628662109375 * _5141;
            _7534 = (sin(_5151) / _5151) * (sin(_5157) / _5157);
        }
        float _5179 = fast::min(abs(-_4250), 2.0);
        float _7535;
        if (abs(_5179) < 6.099999882280826568603515625e-05)
        {
            _7535 = 1.0;
        }
        else
        {
            float _5189 = 3.1415927410125732421875 * _5179;
            float _5195 = 1.57079637050628662109375 * _5179;
            _7535 = (sin(_5189) / _5189) * (sin(_5195) / _5195);
        }
        float _5217 = fast::min(abs(1.0 - _4250), 2.0);
        float _7536;
        if (abs(_5217) < 6.099999882280826568603515625e-05)
        {
            _7536 = 1.0;
        }
        else
        {
            float _5227 = 3.1415927410125732421875 * _5217;
            float _5233 = 1.57079637050628662109375 * _5217;
            _7536 = (sin(_5227) / _5227) * (sin(_5233) / _5233);
        }
        float _5255 = fast::min(abs(2.0 - _4250), 2.0);
        float _7537;
        if (abs(_5255) < 6.099999882280826568603515625e-05)
        {
            _7537 = 1.0;
        }
        else
        {
            float _5265 = 3.1415927410125732421875 * _5255;
            float _5271 = 1.57079637050628662109375 * _5255;
            _7537 = (sin(_5265) / _5265) * (sin(_5271) / _5271);
        }
        spvUnsafeArray<float4, 4> _4260 = spvUnsafeArray<float4, 4>({ _7507, _7508, _7511, _7512 });
        spvUnsafeArray<float4, 4> _4191 = _4260;
        float4 _7540;
        float4 _7541;
        _7541 = _4191[0];
        _7540 = _4191[0];
        for (int _7538 = 1; _7538 < 4; )
        {
            _7541 = fast::max(_7541, _4191[_7538]);
            _7540 = fast::min(_7540, _4191[_7538]);
            _7538++;
            continue;
        }
        float4 _4287 = fast::clamp((((((((((_7502 * _7518) + (_7503 * _7519)) + (_7504 * _7520)) + (_7505 * _7521)) / float4(((_7518 + _7519) + _7520) + _7521)) * _7534) + ((((((_7506 * _7522) + (_7507 * _7523)) + (_7508 * _7524)) + (_7509 * _7525)) / float4(((_7522 + _7523) + _7524) + _7525)) * _7535)) + ((((((_7510 * _7526) + (_7511 * _7527)) + (_7512 * _7528)) + (_7513 * _7529)) / float4(((_7526 + _7527) + _7528) + _7529)) * _7536)) + ((((((_7514 * _7530) + (_7515 * _7531)) + (_7516 * _7532)) + (_7517 * _7533)) / float4(((_7530 + _7531) + _7532) + _7533)) * _7537)) / float4(((_7534 + _7535) + _7536) + _7537), _7540, _7541);
        float3 _2755 = (_4287.xyz * _397._m10) * ((_397._m18 == 0.0) ? 1.0 : _397._m18);
        float _5306 = _2755.x;
        float _5310 = 0.5 * _2755.y;
        float _5313 = _2755.z;
        float _5314 = 0.25 * _5313;
        _7545 = float3(((0.25 * _5306) + _5310) + _5314, 0.5 * (_5306 - _5313), (((-0.25) * _5306) + _5310) - _5314);
        _7543 = _4287.w;
    }
    else
    {
        _7545 = float3(0.0);
        _7543 = 0.0;
    }
    float _5446 = fast::max(fast::clamp(_2731, 0.0, 1.0), fast::max(_2723, _2727));
    float _5451 = fast::max(0.0, (_7543 * float(!_2445)) - (_5446 * 2.0));
    float _7553;
    if (all(gl_GlobalInvocationID.xy < uint2(int2(_547.get_width(), _547.get_height()))))
    {
        spvImageFence(_547);
        _7553 = _547.read(uint2(_2267)).x;
    }
    else
    {
        _7553 = 0.0;
    }
    float2 _5424 = _2393 - _7467.xy;
    float _5505 = _5424.x;
    bool _5506 = _5505 >= 0.0;
    bool _5512;
    if (_5506)
    {
        _5512 = _5505 <= 1.0;
    }
    else
    {
        _5512 = _5506;
    }
    bool _5524;
    if (_5512)
    {
        float _5515 = _5424.y;
        bool _5516 = _5515 >= 0.0;
        bool _5522;
        if (_5516)
        {
            _5522 = _5515 <= 1.0;
        }
        else
        {
            _5522 = _5516;
        }
        _5524 = _5522;
    }
    else
    {
        _5524 = _5512;
    }
    float _5571 = fast::min(_2474, mix(_2474, 0.1500000059604644775390625, fast::clamp(fast::max(0.0, (_2573 * _397._m13) * 2.0), 0.0, 1.0)));
    float2 _5638 = _2390 * _397._m7;
    int2 _5641 = int2(floor(_5638));
    float2 _5646 = (float2(_5641) + float2(0.5)) - _397._m5;
    float2 _5649 = _5646 - _5638;
    bool _5654 = _5646.x > _5638.x;
    bool _5661 = _5646.y > _5638.y;
    int2 _7772 = int2(_5654 ? (-2) : (-1), _5661 ? (-2) : (-1));
    float2 _5675 = float2(_7772);
    bool _5677 = _2474 == 0.0;
    spvUnsafeArray<float3, 9> _5593;
    int _7702;
    for (int _7606 = 0, _7703 = 0; _7606 < 3; _7606++, _7703 = _7702)
    {
        _7702 = _7703;
        int _5718;
        for (int _7695 = 0; _7695 < 3; _7702 = _5718, _7695++)
        {
            int _7697;
            if (_5654)
            {
                _7697 = 3 - _7695;
            }
            else
            {
                _7697 = _7695;
            }
            int _7699;
            if (_5661)
            {
                _7699 = 3 - _7606;
            }
            else
            {
                _7699 = _7606;
            }
            int2 _5709 = (_5641 + _7772) + int2(_7697, _7699);
            int2 _7774 = int2(max(0, min(_5709.x, (_397._m0.x - 1))), max(0, min(_5709.y, (_397._m0.y - 1))));
            float4 _7704;
            if (all(uint2(_7774) < uint2(int2(_464.get_width(), _464.get_height()))))
            {
                _7704 = _464.read(uint2(_7774), 0);
            }
            else
            {
                _7704 = float4(0.0);
            }
            float3 _5967 = fast::max(float3(0.0), _7704.xyz) * ((_397._m18 == 0.0) ? 1.0 : _397._m18);
            float _6007 = _5967.x;
            float _6011 = 0.5 * _5967.y;
            float _6014 = _5967.z;
            float _6015 = 0.25 * _6014;
            _5593[_7702] = float3(((0.25 * _6007) + _6011) + _6015, 0.5 * (_6007 - _6014), (((-0.25) * _6007) + _6011) - _6015);
            _5718 = _7702 + 1;
        }
    }
    float _6059 = fast::min(1.9900000095367431640625, 1.0 + ((float2(1.0) / _397._m7) - float2(1.0)).x);
    float _6084 = mix(fast::max(1.0, (1.0 + _6059) * 0.300000011920928955078125), _6059, fast::min(1.0 - (_2727 * 0.5), fast::min(1.0 - _2731, fast::clamp(_5571 * 5.0, 0.0, 1.0))));
    float _7609;
    float3 _7611;
    float3 _7613;
    float3 _7615;
    float3 _7617;
    float _7623;
    float3 _7626;
    _7626 = float3(0.0);
    _7623 = 0.0;
    _7617 = _7466;
    _7615 = _7466;
    _7613 = _7466;
    _7611 = _7466;
    _7609 = _7463;
    int _7654;
    float3 _7658;
    float _7661;
    float _7671;
    float3 _7675;
    float3 _7679;
    float3 _7683;
    float3 _7687;
    for (int _7608 = 0, _7655 = 0; _7608 < 3; _7626 = _7658, _7623 = _7661, _7617 = _7687, _7615 = _7683, _7613 = _7679, _7611 = _7675, _7609 = _7671, _7608++, _7655 = _7654)
    {
        _7687 = _7617;
        _7683 = _7615;
        _7679 = _7613;
        _7675 = _7611;
        _7671 = _7609;
        _7661 = _7623;
        _7658 = _7626;
        _7654 = _7655;
        int _5839;
        float _7688;
        float3 _7689;
        float3 _7690;
        float3 _7691;
        float3 _7692;
        float3 _7748;
        float _7750;
        for (int _7647 = 0; _7647 < 3; _7687 = _7692, _7683 = _7691, _7679 = _7690, _7675 = _7689, _7671 = _7688, _7661 = _7750, _7658 = _7748, _7654 = _5839, _7647++)
        {
            int _7649;
            if (_5654)
            {
                _7649 = 3 - _7647;
            }
            else
            {
                _7649 = _7647;
            }
            int _7651;
            if (_5661)
            {
                _7651 = 3 - _7608;
            }
            else
            {
                _7651 = _7608;
            }
            int2 _5775 = int2(_7649, _7651);
            float2 _5782 = _5649 + (_5675 + float2(_5775));
            float _5791 = float(all(uint2((_5641 + _7772) + _5775) < uint2(_397._m0)));
            if (!_5677)
            {
                float2 _6105 = _5782 * float2(_6084);
                float _6124 = fast::min(dot(_6105, _6105), 4.0);
                float _6131 = (0.4000000059604644775390625 * _6124) - 1.0;
                float _6134 = (0.25 * _6124) - 1.0;
                float _5799 = _5791 * ((((1.5625 * _6131) * _6131) - 0.5625) * (_6134 * _6134));
                _7750 = _7661 + _5799;
                _7748 = _7658 + (_5593[_7654] * _5799);
            }
            else
            {
                _7750 = _7661;
                _7748 = _7658;
            }
            float _5822 = exp((-2.2999999523162841796875) * dot(_5782, _5782)) * _5791;
            if ((_7608 == 0) && (_7647 == 0))
            {
                float3 _6186 = _5593[_7654] * _5822;
                _7692 = _6186;
                _7691 = _5593[_7654] * _6186;
                _7690 = _5593[_7654];
                _7689 = _5593[_7654];
                _7688 = _5822;
            }
            else
            {
                float3 _6165 = _5593[_7654] * _5822;
                _7692 = _7687 + _6165;
                _7691 = _7683 + (_5593[_7654] * _6165);
                _7690 = fast::min(_7679, _5593[_7654]);
                _7689 = fast::max(_7675, _5593[_7654]);
                _7688 = _7671 + _5822;
            }
            _5839 = _7654 + 1;
        }
    }
    float3 _6221 = float3((abs(_7609) > 1.1754943508222875079687365372222e-38) ? _7609 : 1.0);
    float3 _6222 = _7617 / _6221;
    float _5859 = _7623 * float(_7623 > 6.099999882280826568603515625e-05);
    float _7634;
    float3 _7636;
    if (_5859 > 6.099999882280826568603515625e-05)
    {
        _7636 = fast::clamp(_7626 / float3(_5859), _7613, _7611);
        _7634 = _5859 * 0.04625000059604644775390625;
    }
    else
    {
        _7636 = _7626;
        _7634 = _5859;
    }
    float _7780 = _5677 ? 1.0 : _7634;
    float _7781 = _5677 ? 0.0 : _5571;
    float3 _6314 = (sqrt(abs((_7615 / _6221) - (_6222 * _6222))) * float3(1.7000000476837158203125, 1.0, 1.0)) * mix(3.0, 1.0, fast::max(fast::clamp(_2573 * 0.0500000007450580596923828125, 0.0, 1.0), fast::max(fast::clamp(0.75 - (_516.sample(_524, (fast::max(float2(0.5), fast::min(_2401 * _2678, _2678 - float2(0.5))) / float2(int2(_516.get_width(), _516.get_height()))), level(0.0)).x * 0.0500000007450580596923828125), 0.0, 1.0), fast::max(1.0 - _2474, fast::max(powr(_2723, 0.5), _2731)))));
    float3 _6323 = (_7545 - _6222) / fast::max(_6314, float3(1.19299997436428384389728307724e-07));
    float3 _7646;
    if (length(_6323) > 1.0)
    {
        _7646 = mix((fast::normalize(_6323) * _6314) + _6222, _7545, float3(fast::clamp((fast::max(_534.sample(_524, (fast::max(float2(0.5), fast::min(_2543, _2517)) / _2399), level(0.0)).x, fast::clamp(fast::clamp(_5451 - 1.0, 0.0, 1.0), 0.0, 1.0)) * _2474) * (1.0 - _2727), 0.0, 1.0)));
    }
    else
    {
        _7646 = _7545;
    }
    float3 _6469 = mix(_7646, select(_7636, _6222, bool3(_5677)), float3(fast::clamp(_7780 / fast::max(6.099999882280826568603515625e-05, (_7781 * float(_7781 > 6.099999882280826568603515625e-05)) + _7780), 0.0, 1.0)));
    float _6474 = _6469.x;
    float _6476 = _6469.y;
    float _6479 = _6469.z;
    if (all(gl_GlobalInvocationID.xy < uint2(int2(_505.get_width(), _505.get_height()))))
    {
        _505.write(float4(fast::max(float3((_6474 + _6476) - _6479, _6474 + _6479, (_6474 - _6476) - _6479) / float3((_397._m18 == 0.0) ? 1.0 : _397._m18), float3(0.0)), fast::max(0.0, fast::max(0.0, fast::min(_5451 + (_7553 * (1.0 - fast::max(0.0, _2723))), 2.0)) - ((0.100000001490116119384765625 / _397._m9) * (1.0 - _5446))) * float(_5524)), uint2(_2267));
    }
    if (all(gl_GlobalInvocationID.xy < uint2(int2(_547.get_width(), _547.get_height()))))
    {
        _547.write(float4(0.0), uint2(_2267));
    }
}

