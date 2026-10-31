// Generated from fsr3_shading_change_pyramid.comp by Scripts/compile-shaders.sh — do not edit.
// Edit the GLSL and rerun the script (needs glslc and spirv-cross).
// spirv-fnv1a64: 28841895df1f75d4
// glsl-fnv1a64: 13f1c8af5b6ad0df

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

struct _396
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

constant uint3 gl_WorkGroupSize [[maybe_unused]] = uint3(256u, 1u, 1u);

constant spvUnsafeArray<int2, 5> _955 = spvUnsafeArray<int2, 5>({ int2(0), int2(-1, 0), int2(1, 0), int2(0, -1), int2(0, 1) });

kernel void compute_main(constant _396& _398 [[buffer(16)]], texture2d<float> _456 [[texture(1)]], texture2d<float> _477 [[texture(2)]], texture2d<float> _496 [[texture(3)]], texture2d<float, access::write> _524 [[texture(8)]], texture2d<float, access::write> _544 [[texture(9)]], texture2d<float, access::write> _564 [[texture(10)]], uint3 gl_WorkGroupID [[threadgroup_position_in_grid]], uint gl_LocalInvocationIndex [[thread_index_in_threadgroup]])
{
    threadgroup uint _651;
    threadgroup spvUnsafeArray<spvUnsafeArray<float, 16>, 16> _1182;
    threadgroup spvUnsafeArray<spvUnsafeArray<float, 16>, 16> _1188;
    threadgroup spvUnsafeArray<spvUnsafeArray<float, 16>, 16> _1193;
    threadgroup spvUnsafeArray<spvUnsafeArray<float, 16>, 16> _1198;
    do
    {
        uint _2632;
        uint _2635;
        int2 _2647;
        uint _2441 = gl_LocalInvocationIndex % 64u;
        uint _2449 = insert_bits(extract_bits(_2441, uint(2), uint(3)), _2441, uint(0), uint(1)) + (8u * ((gl_LocalInvocationIndex >> uint(6)) % 2u));
        uint _2455 = insert_bits(extract_bits(_2441, uint(3), uint(3)), extract_bits(_2441, uint(1), uint(2)), uint(0), uint(2)) + (8u * (gl_LocalInvocationIndex >> uint(7)));
        do
        {
            int2 _2630 = int2(gl_WorkGroupID.xy * uint2(64u));
            _2632 = _2449 * 2u;
            int _2633 = int(_2632);
            _2635 = _2455 * 2u;
            int _2636 = int(_2635);
            int2 _2638 = _2630 + int2(_2633, _2636);
            int2 _2642 = int2(gl_WorkGroupID.xy * uint2(32u));
            int _2644 = int(_2449);
            int _2646 = int(_2455);
            _2647 = int2(_2644, _2646);
            int2 _2648 = _2642 + _2647;
            uint2 _2650 = uint2(_2638);
            int2 _2951 = int2(float2(_2638));
            int _3000 = _398._m0.x - 1;
            int _3008 = _398._m0.y - 1;
            int2 _30517 = int2(max(0, min(_2951.x, _3000)), max(0, min(_2951.y, _3008)));
            float4 _29743;
            if (all(uint2(_30517) < uint2(int2(_496.get_width(), _496.get_height()))))
            {
                _29743 = _496.read(uint2(_30517), 0);
            }
            else
            {
                _29743 = float4(0.0);
            }
            float2 _2961 = float2(_398._m0);
            float2 _2962 = (float2(_30517) + float2(0.5)) / _2961;
            float2 _3103 = _398._m5 / _2961;
            int2 _3110 = int2(floor((_2962 + _3103) * _2961));
            spvUnsafeArray<float, 5> _28059;
            for (int _29744 = 0; _29744 < 5; _29744++)
            {
                int2 _3174 = _3110 + _955[_29744];
                int2 _30564 = int2(max(0, min(_3174.x, _3000)), max(0, min(_3174.y, _3008)));
                float4 _30358;
                if (all(uint2(_30564) < uint2(int2(_456.get_width(), _456.get_height()))))
                {
                    _30358 = _456.read(uint2(_30564), 0);
                }
                else
                {
                    _30358 = float4(0.0);
                }
                _28059[_29744] = _30358.x * ((_398._m18 == 0.0) ? 1.0 : _398._m18);
                _28059[_29744] = powr(_28059[_29744], 1.0);
                _28059[_29744] = fast::max(_28059[_29744], 6.099999882280826568603515625e-05);
            }
            float2 _3270 = float2(_398._m1);
            float2 _3271 = _398._m6 / _3270;
            float2 _3275 = (_2962 + _3271) + _29743.xy;
            float _3336 = _3275.x;
            bool _3337 = _3336 >= 0.0;
            bool _3343;
            if (_3337)
            {
                _3343 = _3336 <= 1.0;
            }
            else
            {
                _3343 = _3337;
            }
            bool _3355;
            if (_3343)
            {
                float _3346 = _3275.y;
                bool _3347 = _3346 >= 0.0;
                bool _3353;
                if (_3347)
                {
                    _3353 = _3346 <= 1.0;
                }
                else
                {
                    _3353 = _3347;
                }
                _3355 = _3353;
            }
            else
            {
                _3355 = _3343;
            }
            spvUnsafeArray<float, 5> _28777;
            if (_3355)
            {
                int2 _3287 = int2(floor(_3275 * _3270));
                for (int _29745 = 0; _29745 < 5; _29745++)
                {
                    int2 _3377 = _3287 + _955[_29745];
                    int2 _30563 = int2(max(0, min(_3377.x, (_398._m1.x - 1))), max(0, min(_3377.y, (_398._m1.y - 1))));
                    float4 _30356;
                    if (all(uint2(_30563) < uint2(int2(_477.get_width(), _477.get_height()))))
                    {
                        _30356 = _477.read(uint2(_30563), 0);
                    }
                    else
                    {
                        _30356 = float4(0.0);
                    }
                    _28777[_29745] = (_30356.x * _398._m10) * ((_398._m18 == 0.0) ? 1.0 : _398._m18);
                    _28777[_29745] = powr(_28777[_29745], 1.0);
                    _28777[_29745] = fast::max(_28777[_29745], 6.099999882280826568603515625e-05);
                }
            }
            float _29749;
            if (_3355)
            {
                float _3719 = fast::min(_28059[0], _28059[3]);
                float _3724 = fast::max(_28059[0], _28059[3]);
                float _3729 = fast::min(_28059[1], _28059[4]);
                float _3734 = fast::max(_28059[1], _28059[4]);
                float _3739 = fast::min(_3719, _28059[2]);
                float _3744 = fast::max(_3719, _28059[2]);
                float _3749 = fast::min(_3729, _3724);
                float _3754 = fast::max(_3729, _3724);
                float _3764 = fast::max(_3739, _3749);
                float _3769 = fast::min(_3744, _3734);
                float _3774 = fast::max(_3744, _3734);
                float _3784 = fast::max(_3764, _3769);
                float _3789 = fast::min(_3754, _3774);
                spvUnsafeArray<float, 5> _28760 = spvUnsafeArray<float, 5>({ fast::min(_3739, _3749), fast::min(_3764, _3769), fast::min(_3784, _3789), fast::max(_3784, _3789), fast::max(_3754, _3774) });
                spvUnsafeArray<float, 5> _28071 = _28760;
                float _3972 = fast::min(_28777[0], _28777[3]);
                float _3977 = fast::max(_28777[0], _28777[3]);
                float _3982 = fast::min(_28777[1], _28777[4]);
                float _3987 = fast::max(_28777[1], _28777[4]);
                float _3992 = fast::min(_3972, _28777[2]);
                float _3997 = fast::max(_3972, _28777[2]);
                float _4002 = fast::min(_3982, _3977);
                float _4007 = fast::max(_3982, _3977);
                float _4017 = fast::max(_3992, _4002);
                float _4022 = fast::min(_3997, _3987);
                float _4027 = fast::max(_3997, _3987);
                float _4037 = fast::max(_4017, _4022);
                float _4042 = fast::min(_4007, _4027);
                spvUnsafeArray<float, 5> _28776 = spvUnsafeArray<float, 5>({ fast::min(_3992, _4002), fast::min(_4017, _4022), fast::min(_4037, _4042), fast::max(_4037, _4042), fast::max(_4007, _4027) });
                spvUnsafeArray<float, 5> _28078 = _28776;
                float _29748;
                if (fast::min(_28071[4], _28078[4]) > 1.1754943508222875079687365372222e-38)
                {
                    float _29747;
                    _29747 = 65503.0;
                    float _30360;
                    int _30502;
                    int _30503;
                    for (int _29746 = 0, _30348 = 0, _30349 = 0; (_29746 < 5) && (_29747 < 65504.0); _30349 = _30503, _30348 = _30502, _29747 = _30360, _29746++)
                    {
                        float _3496 = _28071[_30348] - _28078[_30349];
                        if (abs(_3496) > 6.099999882280826568603515625e-05)
                        {
                            float _4085 = fast::max(_28071[_30348], _28078[_30349]);
                            float _30350;
                            if (_4085 != 0.0)
                            {
                                _30350 = fast::min(_28071[_30348], _28078[_30349]) / _4085;
                            }
                            else
                            {
                                _30350 = 0.0;
                            }
                            float _3511 = sign(_3496) * (1.0 - _30350);
                            int _3529 = _30348 + int(_28071[_30348] < _28078[_30349]);
                            _30503 = _30349 + int(_28071[_3529] >= _28078[_30349]);
                            _30502 = _3529;
                            _30360 = (abs(_3511) < abs(_29747)) ? _3511 : _29747;
                        }
                        else
                        {
                            _30503 = _30349;
                            _30502 = _30348;
                            _30360 = 65504.0;
                        }
                    }
                    _29748 = _29747;
                }
                else
                {
                    _29748 = 65503.0;
                }
                _29749 = _29748 * float(_29748 < 65503.0);
            }
            else
            {
                _29749 = 0.0;
            }
            float4 _29078 = float4(0.0);
            _29078.x = _29749;
            float _29756;
            if (_29749 != 0.0)
            {
                _29756 = sign(_29749);
            }
            else
            {
                _29756 = 0.0;
            }
            _29078.y = _29756;
            _29078.z = 1.0;
            int2 _4107 = int2(float2(int2(_2650 + uint2(0u, 1u))));
            int2 _30518 = int2(max(0, min(_4107.x, _3000)), max(0, min(_4107.y, _3008)));
            float4 _29758;
            if (all(uint2(_30518) < uint2(int2(_496.get_width(), _496.get_height()))))
            {
                _29758 = _496.read(uint2(_30518), 0);
            }
            else
            {
                _29758 = float4(0.0);
            }
            float2 _4118 = (float2(_30518) + float2(0.5)) / _2961;
            int2 _4266 = int2(floor((_4118 + _3103) * _2961));
            spvUnsafeArray<float, 5> _27907;
            for (int _29759 = 0; _29759 < 5; _29759++)
            {
                int2 _4330 = _4266 + _955[_29759];
                int2 _30562 = int2(max(0, min(_4330.x, _3000)), max(0, min(_4330.y, _3008)));
                float4 _30346;
                if (all(uint2(_30562) < uint2(int2(_456.get_width(), _456.get_height()))))
                {
                    _30346 = _456.read(uint2(_30562), 0);
                }
                else
                {
                    _30346 = float4(0.0);
                }
                _27907[_29759] = _30346.x * ((_398._m18 == 0.0) ? 1.0 : _398._m18);
                _27907[_29759] = powr(_27907[_29759], 1.0);
                _27907[_29759] = fast::max(_27907[_29759], 6.099999882280826568603515625e-05);
            }
            float2 _4431 = (_4118 + _3271) + _29758.xy;
            float _4492 = _4431.x;
            bool _4493 = _4492 >= 0.0;
            bool _4499;
            if (_4493)
            {
                _4499 = _4492 <= 1.0;
            }
            else
            {
                _4499 = _4493;
            }
            bool _4511;
            if (_4499)
            {
                float _4502 = _4431.y;
                bool _4503 = _4502 >= 0.0;
                bool _4509;
                if (_4503)
                {
                    _4509 = _4502 <= 1.0;
                }
                else
                {
                    _4509 = _4503;
                }
                _4511 = _4509;
            }
            else
            {
                _4511 = _4499;
            }
            spvUnsafeArray<float, 5> _28733;
            if (_4511)
            {
                int2 _4443 = int2(floor(_4431 * _3270));
                for (int _29760 = 0; _29760 < 5; _29760++)
                {
                    int2 _4533 = _4443 + _955[_29760];
                    int2 _30561 = int2(max(0, min(_4533.x, (_398._m1.x - 1))), max(0, min(_4533.y, (_398._m1.y - 1))));
                    float4 _30344;
                    if (all(uint2(_30561) < uint2(int2(_477.get_width(), _477.get_height()))))
                    {
                        _30344 = _477.read(uint2(_30561), 0);
                    }
                    else
                    {
                        _30344 = float4(0.0);
                    }
                    _28733[_29760] = (_30344.x * _398._m10) * ((_398._m18 == 0.0) ? 1.0 : _398._m18);
                    _28733[_29760] = powr(_28733[_29760], 1.0);
                    _28733[_29760] = fast::max(_28733[_29760], 6.099999882280826568603515625e-05);
                }
            }
            float _29764;
            if (_4511)
            {
                float _4875 = fast::min(_27907[0], _27907[3]);
                float _4880 = fast::max(_27907[0], _27907[3]);
                float _4885 = fast::min(_27907[1], _27907[4]);
                float _4890 = fast::max(_27907[1], _27907[4]);
                float _4895 = fast::min(_4875, _27907[2]);
                float _4900 = fast::max(_4875, _27907[2]);
                float _4905 = fast::min(_4885, _4880);
                float _4910 = fast::max(_4885, _4880);
                float _4920 = fast::max(_4895, _4905);
                float _4925 = fast::min(_4900, _4890);
                float _4930 = fast::max(_4900, _4890);
                float _4940 = fast::max(_4920, _4925);
                float _4945 = fast::min(_4910, _4930);
                spvUnsafeArray<float, 5> _28716 = spvUnsafeArray<float, 5>({ fast::min(_4895, _4905), fast::min(_4920, _4925), fast::min(_4940, _4945), fast::max(_4940, _4945), fast::max(_4910, _4930) });
                spvUnsafeArray<float, 5> _27919 = _28716;
                float _5128 = fast::min(_28733[0], _28733[3]);
                float _5133 = fast::max(_28733[0], _28733[3]);
                float _5138 = fast::min(_28733[1], _28733[4]);
                float _5143 = fast::max(_28733[1], _28733[4]);
                float _5148 = fast::min(_5128, _28733[2]);
                float _5153 = fast::max(_5128, _28733[2]);
                float _5158 = fast::min(_5138, _5133);
                float _5163 = fast::max(_5138, _5133);
                float _5173 = fast::max(_5148, _5158);
                float _5178 = fast::min(_5153, _5143);
                float _5183 = fast::max(_5153, _5143);
                float _5193 = fast::max(_5173, _5178);
                float _5198 = fast::min(_5163, _5183);
                spvUnsafeArray<float, 5> _28732 = spvUnsafeArray<float, 5>({ fast::min(_5148, _5158), fast::min(_5173, _5178), fast::min(_5193, _5198), fast::max(_5193, _5198), fast::max(_5163, _5183) });
                spvUnsafeArray<float, 5> _27926 = _28732;
                float _29763;
                if (fast::min(_27919[4], _27926[4]) > 1.1754943508222875079687365372222e-38)
                {
                    float _29762;
                    _29762 = 65503.0;
                    float _30363;
                    int _30500;
                    int _30501;
                    for (int _29761 = 0, _30336 = 0, _30337 = 0; (_29761 < 5) && (_29762 < 65504.0); _30337 = _30501, _30336 = _30500, _29762 = _30363, _29761++)
                    {
                        float _4652 = _27919[_30336] - _27926[_30337];
                        if (abs(_4652) > 6.099999882280826568603515625e-05)
                        {
                            float _5241 = fast::max(_27919[_30336], _27926[_30337]);
                            float _30338;
                            if (_5241 != 0.0)
                            {
                                _30338 = fast::min(_27919[_30336], _27926[_30337]) / _5241;
                            }
                            else
                            {
                                _30338 = 0.0;
                            }
                            float _4667 = sign(_4652) * (1.0 - _30338);
                            int _4685 = _30336 + int(_27919[_30336] < _27926[_30337]);
                            _30501 = _30337 + int(_27919[_4685] >= _27926[_30337]);
                            _30500 = _4685;
                            _30363 = (abs(_4667) < abs(_29762)) ? _4667 : _29762;
                        }
                        else
                        {
                            _30501 = _30337;
                            _30500 = _30336;
                            _30363 = 65504.0;
                        }
                    }
                    _29763 = _29762;
                }
                else
                {
                    _29763 = 65503.0;
                }
                _29764 = _29763 * float(_29763 < 65503.0);
            }
            else
            {
                _29764 = 0.0;
            }
            float4 _29114 = float4(0.0);
            _29114.x = _29764;
            float _29771;
            if (_29764 != 0.0)
            {
                _29771 = sign(_29764);
            }
            else
            {
                _29771 = 0.0;
            }
            _29114.y = _29771;
            _29114.z = 1.0;
            int2 _5263 = int2(float2(int2(_2650 + uint2(1u, 0u))));
            int2 _30519 = int2(max(0, min(_5263.x, _3000)), max(0, min(_5263.y, _3008)));
            float4 _29773;
            if (all(uint2(_30519) < uint2(int2(_496.get_width(), _496.get_height()))))
            {
                _29773 = _496.read(uint2(_30519), 0);
            }
            else
            {
                _29773 = float4(0.0);
            }
            float2 _5274 = (float2(_30519) + float2(0.5)) / _2961;
            int2 _5422 = int2(floor((_5274 + _3103) * _2961));
            spvUnsafeArray<float, 5> _27755;
            for (int _29774 = 0; _29774 < 5; _29774++)
            {
                int2 _5486 = _5422 + _955[_29774];
                int2 _30560 = int2(max(0, min(_5486.x, _3000)), max(0, min(_5486.y, _3008)));
                float4 _30334;
                if (all(uint2(_30560) < uint2(int2(_456.get_width(), _456.get_height()))))
                {
                    _30334 = _456.read(uint2(_30560), 0);
                }
                else
                {
                    _30334 = float4(0.0);
                }
                _27755[_29774] = _30334.x * ((_398._m18 == 0.0) ? 1.0 : _398._m18);
                _27755[_29774] = powr(_27755[_29774], 1.0);
                _27755[_29774] = fast::max(_27755[_29774], 6.099999882280826568603515625e-05);
            }
            float2 _5587 = (_5274 + _3271) + _29773.xy;
            float _5648 = _5587.x;
            bool _5649 = _5648 >= 0.0;
            bool _5655;
            if (_5649)
            {
                _5655 = _5648 <= 1.0;
            }
            else
            {
                _5655 = _5649;
            }
            bool _5667;
            if (_5655)
            {
                float _5658 = _5587.y;
                bool _5659 = _5658 >= 0.0;
                bool _5665;
                if (_5659)
                {
                    _5665 = _5658 <= 1.0;
                }
                else
                {
                    _5665 = _5659;
                }
                _5667 = _5665;
            }
            else
            {
                _5667 = _5655;
            }
            spvUnsafeArray<float, 5> _28689;
            if (_5667)
            {
                int2 _5599 = int2(floor(_5587 * _3270));
                for (int _29775 = 0; _29775 < 5; _29775++)
                {
                    int2 _5689 = _5599 + _955[_29775];
                    int2 _30559 = int2(max(0, min(_5689.x, (_398._m1.x - 1))), max(0, min(_5689.y, (_398._m1.y - 1))));
                    float4 _30332;
                    if (all(uint2(_30559) < uint2(int2(_477.get_width(), _477.get_height()))))
                    {
                        _30332 = _477.read(uint2(_30559), 0);
                    }
                    else
                    {
                        _30332 = float4(0.0);
                    }
                    _28689[_29775] = (_30332.x * _398._m10) * ((_398._m18 == 0.0) ? 1.0 : _398._m18);
                    _28689[_29775] = powr(_28689[_29775], 1.0);
                    _28689[_29775] = fast::max(_28689[_29775], 6.099999882280826568603515625e-05);
                }
            }
            float _29779;
            if (_5667)
            {
                float _6031 = fast::min(_27755[0], _27755[3]);
                float _6036 = fast::max(_27755[0], _27755[3]);
                float _6041 = fast::min(_27755[1], _27755[4]);
                float _6046 = fast::max(_27755[1], _27755[4]);
                float _6051 = fast::min(_6031, _27755[2]);
                float _6056 = fast::max(_6031, _27755[2]);
                float _6061 = fast::min(_6041, _6036);
                float _6066 = fast::max(_6041, _6036);
                float _6076 = fast::max(_6051, _6061);
                float _6081 = fast::min(_6056, _6046);
                float _6086 = fast::max(_6056, _6046);
                float _6096 = fast::max(_6076, _6081);
                float _6101 = fast::min(_6066, _6086);
                spvUnsafeArray<float, 5> _28672 = spvUnsafeArray<float, 5>({ fast::min(_6051, _6061), fast::min(_6076, _6081), fast::min(_6096, _6101), fast::max(_6096, _6101), fast::max(_6066, _6086) });
                spvUnsafeArray<float, 5> _27767 = _28672;
                float _6284 = fast::min(_28689[0], _28689[3]);
                float _6289 = fast::max(_28689[0], _28689[3]);
                float _6294 = fast::min(_28689[1], _28689[4]);
                float _6299 = fast::max(_28689[1], _28689[4]);
                float _6304 = fast::min(_6284, _28689[2]);
                float _6309 = fast::max(_6284, _28689[2]);
                float _6314 = fast::min(_6294, _6289);
                float _6319 = fast::max(_6294, _6289);
                float _6329 = fast::max(_6304, _6314);
                float _6334 = fast::min(_6309, _6299);
                float _6339 = fast::max(_6309, _6299);
                float _6349 = fast::max(_6329, _6334);
                float _6354 = fast::min(_6319, _6339);
                spvUnsafeArray<float, 5> _28688 = spvUnsafeArray<float, 5>({ fast::min(_6304, _6314), fast::min(_6329, _6334), fast::min(_6349, _6354), fast::max(_6349, _6354), fast::max(_6319, _6339) });
                spvUnsafeArray<float, 5> _27774 = _28688;
                float _29778;
                if (fast::min(_27767[4], _27774[4]) > 1.1754943508222875079687365372222e-38)
                {
                    float _29777;
                    _29777 = 65503.0;
                    float _30366;
                    int _30498;
                    int _30499;
                    for (int _29776 = 0, _30324 = 0, _30325 = 0; (_29776 < 5) && (_29777 < 65504.0); _30325 = _30499, _30324 = _30498, _29777 = _30366, _29776++)
                    {
                        float _5808 = _27767[_30324] - _27774[_30325];
                        if (abs(_5808) > 6.099999882280826568603515625e-05)
                        {
                            float _6397 = fast::max(_27767[_30324], _27774[_30325]);
                            float _30326;
                            if (_6397 != 0.0)
                            {
                                _30326 = fast::min(_27767[_30324], _27774[_30325]) / _6397;
                            }
                            else
                            {
                                _30326 = 0.0;
                            }
                            float _5823 = sign(_5808) * (1.0 - _30326);
                            int _5841 = _30324 + int(_27767[_30324] < _27774[_30325]);
                            _30499 = _30325 + int(_27767[_5841] >= _27774[_30325]);
                            _30498 = _5841;
                            _30366 = (abs(_5823) < abs(_29777)) ? _5823 : _29777;
                        }
                        else
                        {
                            _30499 = _30325;
                            _30498 = _30324;
                            _30366 = 65504.0;
                        }
                    }
                    _29778 = _29777;
                }
                else
                {
                    _29778 = 65503.0;
                }
                _29779 = _29778 * float(_29778 < 65503.0);
            }
            else
            {
                _29779 = 0.0;
            }
            float4 _29150 = float4(0.0);
            _29150.x = _29779;
            float _29786;
            if (_29779 != 0.0)
            {
                _29786 = sign(_29779);
            }
            else
            {
                _29786 = 0.0;
            }
            _29150.y = _29786;
            _29150.z = 1.0;
            int2 _6419 = int2(float2(int2(_2650 + uint2(1u))));
            int2 _30520 = int2(max(0, min(_6419.x, _3000)), max(0, min(_6419.y, _3008)));
            float4 _29788;
            if (all(uint2(_30520) < uint2(int2(_496.get_width(), _496.get_height()))))
            {
                _29788 = _496.read(uint2(_30520), 0);
            }
            else
            {
                _29788 = float4(0.0);
            }
            float2 _6430 = (float2(_30520) + float2(0.5)) / _2961;
            int2 _6578 = int2(floor((_6430 + _3103) * _2961));
            spvUnsafeArray<float, 5> _27603;
            for (int _29789 = 0; _29789 < 5; _29789++)
            {
                int2 _6642 = _6578 + _955[_29789];
                int2 _30558 = int2(max(0, min(_6642.x, _3000)), max(0, min(_6642.y, _3008)));
                float4 _30322;
                if (all(uint2(_30558) < uint2(int2(_456.get_width(), _456.get_height()))))
                {
                    _30322 = _456.read(uint2(_30558), 0);
                }
                else
                {
                    _30322 = float4(0.0);
                }
                _27603[_29789] = _30322.x * ((_398._m18 == 0.0) ? 1.0 : _398._m18);
                _27603[_29789] = powr(_27603[_29789], 1.0);
                _27603[_29789] = fast::max(_27603[_29789], 6.099999882280826568603515625e-05);
            }
            float2 _6743 = (_6430 + _3271) + _29788.xy;
            float _6804 = _6743.x;
            bool _6805 = _6804 >= 0.0;
            bool _6811;
            if (_6805)
            {
                _6811 = _6804 <= 1.0;
            }
            else
            {
                _6811 = _6805;
            }
            bool _6823;
            if (_6811)
            {
                float _6814 = _6743.y;
                bool _6815 = _6814 >= 0.0;
                bool _6821;
                if (_6815)
                {
                    _6821 = _6814 <= 1.0;
                }
                else
                {
                    _6821 = _6815;
                }
                _6823 = _6821;
            }
            else
            {
                _6823 = _6811;
            }
            spvUnsafeArray<float, 5> _28645;
            if (_6823)
            {
                int2 _6755 = int2(floor(_6743 * _3270));
                for (int _29790 = 0; _29790 < 5; _29790++)
                {
                    int2 _6845 = _6755 + _955[_29790];
                    int2 _30557 = int2(max(0, min(_6845.x, (_398._m1.x - 1))), max(0, min(_6845.y, (_398._m1.y - 1))));
                    float4 _30320;
                    if (all(uint2(_30557) < uint2(int2(_477.get_width(), _477.get_height()))))
                    {
                        _30320 = _477.read(uint2(_30557), 0);
                    }
                    else
                    {
                        _30320 = float4(0.0);
                    }
                    _28645[_29790] = (_30320.x * _398._m10) * ((_398._m18 == 0.0) ? 1.0 : _398._m18);
                    _28645[_29790] = powr(_28645[_29790], 1.0);
                    _28645[_29790] = fast::max(_28645[_29790], 6.099999882280826568603515625e-05);
                }
            }
            float _29794;
            if (_6823)
            {
                float _7187 = fast::min(_27603[0], _27603[3]);
                float _7192 = fast::max(_27603[0], _27603[3]);
                float _7197 = fast::min(_27603[1], _27603[4]);
                float _7202 = fast::max(_27603[1], _27603[4]);
                float _7207 = fast::min(_7187, _27603[2]);
                float _7212 = fast::max(_7187, _27603[2]);
                float _7217 = fast::min(_7197, _7192);
                float _7222 = fast::max(_7197, _7192);
                float _7232 = fast::max(_7207, _7217);
                float _7237 = fast::min(_7212, _7202);
                float _7242 = fast::max(_7212, _7202);
                float _7252 = fast::max(_7232, _7237);
                float _7257 = fast::min(_7222, _7242);
                spvUnsafeArray<float, 5> _28628 = spvUnsafeArray<float, 5>({ fast::min(_7207, _7217), fast::min(_7232, _7237), fast::min(_7252, _7257), fast::max(_7252, _7257), fast::max(_7222, _7242) });
                spvUnsafeArray<float, 5> _27615 = _28628;
                float _7440 = fast::min(_28645[0], _28645[3]);
                float _7445 = fast::max(_28645[0], _28645[3]);
                float _7450 = fast::min(_28645[1], _28645[4]);
                float _7455 = fast::max(_28645[1], _28645[4]);
                float _7460 = fast::min(_7440, _28645[2]);
                float _7465 = fast::max(_7440, _28645[2]);
                float _7470 = fast::min(_7450, _7445);
                float _7475 = fast::max(_7450, _7445);
                float _7485 = fast::max(_7460, _7470);
                float _7490 = fast::min(_7465, _7455);
                float _7495 = fast::max(_7465, _7455);
                float _7505 = fast::max(_7485, _7490);
                float _7510 = fast::min(_7475, _7495);
                spvUnsafeArray<float, 5> _28644 = spvUnsafeArray<float, 5>({ fast::min(_7460, _7470), fast::min(_7485, _7490), fast::min(_7505, _7510), fast::max(_7505, _7510), fast::max(_7475, _7495) });
                spvUnsafeArray<float, 5> _27622 = _28644;
                float _29793;
                if (fast::min(_27615[4], _27622[4]) > 1.1754943508222875079687365372222e-38)
                {
                    float _29792;
                    _29792 = 65503.0;
                    float _30369;
                    int _30496;
                    int _30497;
                    for (int _29791 = 0, _30312 = 0, _30313 = 0; (_29791 < 5) && (_29792 < 65504.0); _30313 = _30497, _30312 = _30496, _29792 = _30369, _29791++)
                    {
                        float _6964 = _27615[_30312] - _27622[_30313];
                        if (abs(_6964) > 6.099999882280826568603515625e-05)
                        {
                            float _7553 = fast::max(_27615[_30312], _27622[_30313]);
                            float _30314;
                            if (_7553 != 0.0)
                            {
                                _30314 = fast::min(_27615[_30312], _27622[_30313]) / _7553;
                            }
                            else
                            {
                                _30314 = 0.0;
                            }
                            float _6979 = sign(_6964) * (1.0 - _30314);
                            int _6997 = _30312 + int(_27615[_30312] < _27622[_30313]);
                            _30497 = _30313 + int(_27615[_6997] >= _27622[_30313]);
                            _30496 = _6997;
                            _30369 = (abs(_6979) < abs(_29792)) ? _6979 : _29792;
                        }
                        else
                        {
                            _30497 = _30313;
                            _30496 = _30312;
                            _30369 = 65504.0;
                        }
                    }
                    _29793 = _29792;
                }
                else
                {
                    _29793 = 65503.0;
                }
                _29794 = _29793 * float(_29793 < 65503.0);
            }
            else
            {
                _29794 = 0.0;
            }
            float4 _29186 = float4(0.0);
            _29186.x = _29794;
            float _29801;
            if (_29794 != 0.0)
            {
                _29801 = sign(_29794);
            }
            else
            {
                _29801 = 0.0;
            }
            _29186.y = _29801;
            _29186.z = 1.0;
            spvUnsafeArray<float4, 4> _2576;
            _2576[0] = (((_29078 + _29114) + _29150) + _29186) * 0.25;
            if (all(uint2(_2648) < uint2(int2(_524.get_width(), _524.get_height()))))
            {
                _524.write(float4(_2576[0].xy, 0.0, 0.0), uint2(_2648));
            }
            int _2666 = int(_2632 + 32u);
            int2 _2671 = _2630 + int2(_2666, _2636);
            int _2678 = int(_2449 + 16u);
            int2 _2682 = _2642 + int2(_2678, _2646);
            uint2 _2684 = uint2(_2671);
            int2 _7716 = int2(float2(_2671));
            int2 _30521 = int2(max(0, min(_7716.x, _3000)), max(0, min(_7716.y, _3008)));
            float4 _29847;
            if (all(uint2(_30521) < uint2(int2(_496.get_width(), _496.get_height()))))
            {
                _29847 = _496.read(uint2(_30521), 0);
            }
            else
            {
                _29847 = float4(0.0);
            }
            float2 _7727 = (float2(_30521) + float2(0.5)) / _2961;
            int2 _7875 = int2(floor((_7727 + _3103) * _2961));
            spvUnsafeArray<float, 5> _27451;
            for (int _29848 = 0; _29848 < 5; _29848++)
            {
                int2 _7939 = _7875 + _955[_29848];
                int2 _30556 = int2(max(0, min(_7939.x, _3000)), max(0, min(_7939.y, _3008)));
                float4 _30310;
                if (all(uint2(_30556) < uint2(int2(_456.get_width(), _456.get_height()))))
                {
                    _30310 = _456.read(uint2(_30556), 0);
                }
                else
                {
                    _30310 = float4(0.0);
                }
                _27451[_29848] = _30310.x * ((_398._m18 == 0.0) ? 1.0 : _398._m18);
                _27451[_29848] = powr(_27451[_29848], 1.0);
                _27451[_29848] = fast::max(_27451[_29848], 6.099999882280826568603515625e-05);
            }
            float2 _8040 = (_7727 + _3271) + _29847.xy;
            float _8101 = _8040.x;
            bool _8102 = _8101 >= 0.0;
            bool _8108;
            if (_8102)
            {
                _8108 = _8101 <= 1.0;
            }
            else
            {
                _8108 = _8102;
            }
            bool _8120;
            if (_8108)
            {
                float _8111 = _8040.y;
                bool _8112 = _8111 >= 0.0;
                bool _8118;
                if (_8112)
                {
                    _8118 = _8111 <= 1.0;
                }
                else
                {
                    _8118 = _8112;
                }
                _8120 = _8118;
            }
            else
            {
                _8120 = _8108;
            }
            spvUnsafeArray<float, 5> _28601;
            if (_8120)
            {
                int2 _8052 = int2(floor(_8040 * _3270));
                for (int _29849 = 0; _29849 < 5; _29849++)
                {
                    int2 _8142 = _8052 + _955[_29849];
                    int2 _30555 = int2(max(0, min(_8142.x, (_398._m1.x - 1))), max(0, min(_8142.y, (_398._m1.y - 1))));
                    float4 _30308;
                    if (all(uint2(_30555) < uint2(int2(_477.get_width(), _477.get_height()))))
                    {
                        _30308 = _477.read(uint2(_30555), 0);
                    }
                    else
                    {
                        _30308 = float4(0.0);
                    }
                    _28601[_29849] = (_30308.x * _398._m10) * ((_398._m18 == 0.0) ? 1.0 : _398._m18);
                    _28601[_29849] = powr(_28601[_29849], 1.0);
                    _28601[_29849] = fast::max(_28601[_29849], 6.099999882280826568603515625e-05);
                }
            }
            float _29853;
            if (_8120)
            {
                float _8484 = fast::min(_27451[0], _27451[3]);
                float _8489 = fast::max(_27451[0], _27451[3]);
                float _8494 = fast::min(_27451[1], _27451[4]);
                float _8499 = fast::max(_27451[1], _27451[4]);
                float _8504 = fast::min(_8484, _27451[2]);
                float _8509 = fast::max(_8484, _27451[2]);
                float _8514 = fast::min(_8494, _8489);
                float _8519 = fast::max(_8494, _8489);
                float _8529 = fast::max(_8504, _8514);
                float _8534 = fast::min(_8509, _8499);
                float _8539 = fast::max(_8509, _8499);
                float _8549 = fast::max(_8529, _8534);
                float _8554 = fast::min(_8519, _8539);
                spvUnsafeArray<float, 5> _28584 = spvUnsafeArray<float, 5>({ fast::min(_8504, _8514), fast::min(_8529, _8534), fast::min(_8549, _8554), fast::max(_8549, _8554), fast::max(_8519, _8539) });
                spvUnsafeArray<float, 5> _27463 = _28584;
                float _8737 = fast::min(_28601[0], _28601[3]);
                float _8742 = fast::max(_28601[0], _28601[3]);
                float _8747 = fast::min(_28601[1], _28601[4]);
                float _8752 = fast::max(_28601[1], _28601[4]);
                float _8757 = fast::min(_8737, _28601[2]);
                float _8762 = fast::max(_8737, _28601[2]);
                float _8767 = fast::min(_8747, _8742);
                float _8772 = fast::max(_8747, _8742);
                float _8782 = fast::max(_8757, _8767);
                float _8787 = fast::min(_8762, _8752);
                float _8792 = fast::max(_8762, _8752);
                float _8802 = fast::max(_8782, _8787);
                float _8807 = fast::min(_8772, _8792);
                spvUnsafeArray<float, 5> _28600 = spvUnsafeArray<float, 5>({ fast::min(_8757, _8767), fast::min(_8782, _8787), fast::min(_8802, _8807), fast::max(_8802, _8807), fast::max(_8772, _8792) });
                spvUnsafeArray<float, 5> _27470 = _28600;
                float _29852;
                if (fast::min(_27463[4], _27470[4]) > 1.1754943508222875079687365372222e-38)
                {
                    float _29851;
                    _29851 = 65503.0;
                    float _30388;
                    int _30494;
                    int _30495;
                    for (int _29850 = 0, _30300 = 0, _30301 = 0; (_29850 < 5) && (_29851 < 65504.0); _30301 = _30495, _30300 = _30494, _29851 = _30388, _29850++)
                    {
                        float _8261 = _27463[_30300] - _27470[_30301];
                        if (abs(_8261) > 6.099999882280826568603515625e-05)
                        {
                            float _8850 = fast::max(_27463[_30300], _27470[_30301]);
                            float _30302;
                            if (_8850 != 0.0)
                            {
                                _30302 = fast::min(_27463[_30300], _27470[_30301]) / _8850;
                            }
                            else
                            {
                                _30302 = 0.0;
                            }
                            float _8276 = sign(_8261) * (1.0 - _30302);
                            int _8294 = _30300 + int(_27463[_30300] < _27470[_30301]);
                            _30495 = _30301 + int(_27463[_8294] >= _27470[_30301]);
                            _30494 = _8294;
                            _30388 = (abs(_8276) < abs(_29851)) ? _8276 : _29851;
                        }
                        else
                        {
                            _30495 = _30301;
                            _30494 = _30300;
                            _30388 = 65504.0;
                        }
                    }
                    _29852 = _29851;
                }
                else
                {
                    _29852 = 65503.0;
                }
                _29853 = _29852 * float(_29852 < 65503.0);
            }
            else
            {
                _29853 = 0.0;
            }
            float4 _29222 = float4(0.0);
            _29222.x = _29853;
            float _29860;
            if (_29853 != 0.0)
            {
                _29860 = sign(_29853);
            }
            else
            {
                _29860 = 0.0;
            }
            _29222.y = _29860;
            _29222.z = 1.0;
            int2 _8872 = int2(float2(int2(_2684 + uint2(0u, 1u))));
            int2 _30522 = int2(max(0, min(_8872.x, _3000)), max(0, min(_8872.y, _3008)));
            float4 _29862;
            if (all(uint2(_30522) < uint2(int2(_496.get_width(), _496.get_height()))))
            {
                _29862 = _496.read(uint2(_30522), 0);
            }
            else
            {
                _29862 = float4(0.0);
            }
            float2 _8883 = (float2(_30522) + float2(0.5)) / _2961;
            int2 _9031 = int2(floor((_8883 + _3103) * _2961));
            spvUnsafeArray<float, 5> _27299;
            for (int _29863 = 0; _29863 < 5; _29863++)
            {
                int2 _9095 = _9031 + _955[_29863];
                int2 _30554 = int2(max(0, min(_9095.x, _3000)), max(0, min(_9095.y, _3008)));
                float4 _30298;
                if (all(uint2(_30554) < uint2(int2(_456.get_width(), _456.get_height()))))
                {
                    _30298 = _456.read(uint2(_30554), 0);
                }
                else
                {
                    _30298 = float4(0.0);
                }
                _27299[_29863] = _30298.x * ((_398._m18 == 0.0) ? 1.0 : _398._m18);
                _27299[_29863] = powr(_27299[_29863], 1.0);
                _27299[_29863] = fast::max(_27299[_29863], 6.099999882280826568603515625e-05);
            }
            float2 _9196 = (_8883 + _3271) + _29862.xy;
            float _9257 = _9196.x;
            bool _9258 = _9257 >= 0.0;
            bool _9264;
            if (_9258)
            {
                _9264 = _9257 <= 1.0;
            }
            else
            {
                _9264 = _9258;
            }
            bool _9276;
            if (_9264)
            {
                float _9267 = _9196.y;
                bool _9268 = _9267 >= 0.0;
                bool _9274;
                if (_9268)
                {
                    _9274 = _9267 <= 1.0;
                }
                else
                {
                    _9274 = _9268;
                }
                _9276 = _9274;
            }
            else
            {
                _9276 = _9264;
            }
            spvUnsafeArray<float, 5> _28557;
            if (_9276)
            {
                int2 _9208 = int2(floor(_9196 * _3270));
                for (int _29864 = 0; _29864 < 5; _29864++)
                {
                    int2 _9298 = _9208 + _955[_29864];
                    int2 _30553 = int2(max(0, min(_9298.x, (_398._m1.x - 1))), max(0, min(_9298.y, (_398._m1.y - 1))));
                    float4 _30296;
                    if (all(uint2(_30553) < uint2(int2(_477.get_width(), _477.get_height()))))
                    {
                        _30296 = _477.read(uint2(_30553), 0);
                    }
                    else
                    {
                        _30296 = float4(0.0);
                    }
                    _28557[_29864] = (_30296.x * _398._m10) * ((_398._m18 == 0.0) ? 1.0 : _398._m18);
                    _28557[_29864] = powr(_28557[_29864], 1.0);
                    _28557[_29864] = fast::max(_28557[_29864], 6.099999882280826568603515625e-05);
                }
            }
            float _29868;
            if (_9276)
            {
                float _9640 = fast::min(_27299[0], _27299[3]);
                float _9645 = fast::max(_27299[0], _27299[3]);
                float _9650 = fast::min(_27299[1], _27299[4]);
                float _9655 = fast::max(_27299[1], _27299[4]);
                float _9660 = fast::min(_9640, _27299[2]);
                float _9665 = fast::max(_9640, _27299[2]);
                float _9670 = fast::min(_9650, _9645);
                float _9675 = fast::max(_9650, _9645);
                float _9685 = fast::max(_9660, _9670);
                float _9690 = fast::min(_9665, _9655);
                float _9695 = fast::max(_9665, _9655);
                float _9705 = fast::max(_9685, _9690);
                float _9710 = fast::min(_9675, _9695);
                spvUnsafeArray<float, 5> _28540 = spvUnsafeArray<float, 5>({ fast::min(_9660, _9670), fast::min(_9685, _9690), fast::min(_9705, _9710), fast::max(_9705, _9710), fast::max(_9675, _9695) });
                spvUnsafeArray<float, 5> _27311 = _28540;
                float _9893 = fast::min(_28557[0], _28557[3]);
                float _9898 = fast::max(_28557[0], _28557[3]);
                float _9903 = fast::min(_28557[1], _28557[4]);
                float _9908 = fast::max(_28557[1], _28557[4]);
                float _9913 = fast::min(_9893, _28557[2]);
                float _9918 = fast::max(_9893, _28557[2]);
                float _9923 = fast::min(_9903, _9898);
                float _9928 = fast::max(_9903, _9898);
                float _9938 = fast::max(_9913, _9923);
                float _9943 = fast::min(_9918, _9908);
                float _9948 = fast::max(_9918, _9908);
                float _9958 = fast::max(_9938, _9943);
                float _9963 = fast::min(_9928, _9948);
                spvUnsafeArray<float, 5> _28556 = spvUnsafeArray<float, 5>({ fast::min(_9913, _9923), fast::min(_9938, _9943), fast::min(_9958, _9963), fast::max(_9958, _9963), fast::max(_9928, _9948) });
                spvUnsafeArray<float, 5> _27318 = _28556;
                float _29867;
                if (fast::min(_27311[4], _27318[4]) > 1.1754943508222875079687365372222e-38)
                {
                    float _29866;
                    _29866 = 65503.0;
                    float _30391;
                    int _30492;
                    int _30493;
                    for (int _29865 = 0, _30288 = 0, _30289 = 0; (_29865 < 5) && (_29866 < 65504.0); _30289 = _30493, _30288 = _30492, _29866 = _30391, _29865++)
                    {
                        float _9417 = _27311[_30288] - _27318[_30289];
                        if (abs(_9417) > 6.099999882280826568603515625e-05)
                        {
                            float _10006 = fast::max(_27311[_30288], _27318[_30289]);
                            float _30290;
                            if (_10006 != 0.0)
                            {
                                _30290 = fast::min(_27311[_30288], _27318[_30289]) / _10006;
                            }
                            else
                            {
                                _30290 = 0.0;
                            }
                            float _9432 = sign(_9417) * (1.0 - _30290);
                            int _9450 = _30288 + int(_27311[_30288] < _27318[_30289]);
                            _30493 = _30289 + int(_27311[_9450] >= _27318[_30289]);
                            _30492 = _9450;
                            _30391 = (abs(_9432) < abs(_29866)) ? _9432 : _29866;
                        }
                        else
                        {
                            _30493 = _30289;
                            _30492 = _30288;
                            _30391 = 65504.0;
                        }
                    }
                    _29867 = _29866;
                }
                else
                {
                    _29867 = 65503.0;
                }
                _29868 = _29867 * float(_29867 < 65503.0);
            }
            else
            {
                _29868 = 0.0;
            }
            float4 _29258 = float4(0.0);
            _29258.x = _29868;
            float _29875;
            if (_29868 != 0.0)
            {
                _29875 = sign(_29868);
            }
            else
            {
                _29875 = 0.0;
            }
            _29258.y = _29875;
            _29258.z = 1.0;
            int2 _10028 = int2(float2(int2(_2684 + uint2(1u, 0u))));
            int2 _30523 = int2(max(0, min(_10028.x, _3000)), max(0, min(_10028.y, _3008)));
            float4 _29877;
            if (all(uint2(_30523) < uint2(int2(_496.get_width(), _496.get_height()))))
            {
                _29877 = _496.read(uint2(_30523), 0);
            }
            else
            {
                _29877 = float4(0.0);
            }
            float2 _10039 = (float2(_30523) + float2(0.5)) / _2961;
            int2 _10187 = int2(floor((_10039 + _3103) * _2961));
            spvUnsafeArray<float, 5> _27147;
            for (int _29878 = 0; _29878 < 5; _29878++)
            {
                int2 _10251 = _10187 + _955[_29878];
                int2 _30552 = int2(max(0, min(_10251.x, _3000)), max(0, min(_10251.y, _3008)));
                float4 _30286;
                if (all(uint2(_30552) < uint2(int2(_456.get_width(), _456.get_height()))))
                {
                    _30286 = _456.read(uint2(_30552), 0);
                }
                else
                {
                    _30286 = float4(0.0);
                }
                _27147[_29878] = _30286.x * ((_398._m18 == 0.0) ? 1.0 : _398._m18);
                _27147[_29878] = powr(_27147[_29878], 1.0);
                _27147[_29878] = fast::max(_27147[_29878], 6.099999882280826568603515625e-05);
            }
            float2 _10352 = (_10039 + _3271) + _29877.xy;
            float _10413 = _10352.x;
            bool _10414 = _10413 >= 0.0;
            bool _10420;
            if (_10414)
            {
                _10420 = _10413 <= 1.0;
            }
            else
            {
                _10420 = _10414;
            }
            bool _10432;
            if (_10420)
            {
                float _10423 = _10352.y;
                bool _10424 = _10423 >= 0.0;
                bool _10430;
                if (_10424)
                {
                    _10430 = _10423 <= 1.0;
                }
                else
                {
                    _10430 = _10424;
                }
                _10432 = _10430;
            }
            else
            {
                _10432 = _10420;
            }
            spvUnsafeArray<float, 5> _28513;
            if (_10432)
            {
                int2 _10364 = int2(floor(_10352 * _3270));
                for (int _29879 = 0; _29879 < 5; _29879++)
                {
                    int2 _10454 = _10364 + _955[_29879];
                    int2 _30551 = int2(max(0, min(_10454.x, (_398._m1.x - 1))), max(0, min(_10454.y, (_398._m1.y - 1))));
                    float4 _30284;
                    if (all(uint2(_30551) < uint2(int2(_477.get_width(), _477.get_height()))))
                    {
                        _30284 = _477.read(uint2(_30551), 0);
                    }
                    else
                    {
                        _30284 = float4(0.0);
                    }
                    _28513[_29879] = (_30284.x * _398._m10) * ((_398._m18 == 0.0) ? 1.0 : _398._m18);
                    _28513[_29879] = powr(_28513[_29879], 1.0);
                    _28513[_29879] = fast::max(_28513[_29879], 6.099999882280826568603515625e-05);
                }
            }
            float _29883;
            if (_10432)
            {
                float _10796 = fast::min(_27147[0], _27147[3]);
                float _10801 = fast::max(_27147[0], _27147[3]);
                float _10806 = fast::min(_27147[1], _27147[4]);
                float _10811 = fast::max(_27147[1], _27147[4]);
                float _10816 = fast::min(_10796, _27147[2]);
                float _10821 = fast::max(_10796, _27147[2]);
                float _10826 = fast::min(_10806, _10801);
                float _10831 = fast::max(_10806, _10801);
                float _10841 = fast::max(_10816, _10826);
                float _10846 = fast::min(_10821, _10811);
                float _10851 = fast::max(_10821, _10811);
                float _10861 = fast::max(_10841, _10846);
                float _10866 = fast::min(_10831, _10851);
                spvUnsafeArray<float, 5> _28496 = spvUnsafeArray<float, 5>({ fast::min(_10816, _10826), fast::min(_10841, _10846), fast::min(_10861, _10866), fast::max(_10861, _10866), fast::max(_10831, _10851) });
                spvUnsafeArray<float, 5> _27159 = _28496;
                float _11049 = fast::min(_28513[0], _28513[3]);
                float _11054 = fast::max(_28513[0], _28513[3]);
                float _11059 = fast::min(_28513[1], _28513[4]);
                float _11064 = fast::max(_28513[1], _28513[4]);
                float _11069 = fast::min(_11049, _28513[2]);
                float _11074 = fast::max(_11049, _28513[2]);
                float _11079 = fast::min(_11059, _11054);
                float _11084 = fast::max(_11059, _11054);
                float _11094 = fast::max(_11069, _11079);
                float _11099 = fast::min(_11074, _11064);
                float _11104 = fast::max(_11074, _11064);
                float _11114 = fast::max(_11094, _11099);
                float _11119 = fast::min(_11084, _11104);
                spvUnsafeArray<float, 5> _28512 = spvUnsafeArray<float, 5>({ fast::min(_11069, _11079), fast::min(_11094, _11099), fast::min(_11114, _11119), fast::max(_11114, _11119), fast::max(_11084, _11104) });
                spvUnsafeArray<float, 5> _27166 = _28512;
                float _29882;
                if (fast::min(_27159[4], _27166[4]) > 1.1754943508222875079687365372222e-38)
                {
                    float _29881;
                    _29881 = 65503.0;
                    float _30394;
                    int _30490;
                    int _30491;
                    for (int _29880 = 0, _30276 = 0, _30277 = 0; (_29880 < 5) && (_29881 < 65504.0); _30277 = _30491, _30276 = _30490, _29881 = _30394, _29880++)
                    {
                        float _10573 = _27159[_30276] - _27166[_30277];
                        if (abs(_10573) > 6.099999882280826568603515625e-05)
                        {
                            float _11162 = fast::max(_27159[_30276], _27166[_30277]);
                            float _30278;
                            if (_11162 != 0.0)
                            {
                                _30278 = fast::min(_27159[_30276], _27166[_30277]) / _11162;
                            }
                            else
                            {
                                _30278 = 0.0;
                            }
                            float _10588 = sign(_10573) * (1.0 - _30278);
                            int _10606 = _30276 + int(_27159[_30276] < _27166[_30277]);
                            _30491 = _30277 + int(_27159[_10606] >= _27166[_30277]);
                            _30490 = _10606;
                            _30394 = (abs(_10588) < abs(_29881)) ? _10588 : _29881;
                        }
                        else
                        {
                            _30491 = _30277;
                            _30490 = _30276;
                            _30394 = 65504.0;
                        }
                    }
                    _29882 = _29881;
                }
                else
                {
                    _29882 = 65503.0;
                }
                _29883 = _29882 * float(_29882 < 65503.0);
            }
            else
            {
                _29883 = 0.0;
            }
            float4 _29294 = float4(0.0);
            _29294.x = _29883;
            float _29890;
            if (_29883 != 0.0)
            {
                _29890 = sign(_29883);
            }
            else
            {
                _29890 = 0.0;
            }
            _29294.y = _29890;
            _29294.z = 1.0;
            int2 _11184 = int2(float2(int2(_2684 + uint2(1u))));
            int2 _30524 = int2(max(0, min(_11184.x, _3000)), max(0, min(_11184.y, _3008)));
            float4 _29892;
            if (all(uint2(_30524) < uint2(int2(_496.get_width(), _496.get_height()))))
            {
                _29892 = _496.read(uint2(_30524), 0);
            }
            else
            {
                _29892 = float4(0.0);
            }
            float2 _11195 = (float2(_30524) + float2(0.5)) / _2961;
            int2 _11343 = int2(floor((_11195 + _3103) * _2961));
            spvUnsafeArray<float, 5> _26995;
            for (int _29893 = 0; _29893 < 5; _29893++)
            {
                int2 _11407 = _11343 + _955[_29893];
                int2 _30550 = int2(max(0, min(_11407.x, _3000)), max(0, min(_11407.y, _3008)));
                float4 _30274;
                if (all(uint2(_30550) < uint2(int2(_456.get_width(), _456.get_height()))))
                {
                    _30274 = _456.read(uint2(_30550), 0);
                }
                else
                {
                    _30274 = float4(0.0);
                }
                _26995[_29893] = _30274.x * ((_398._m18 == 0.0) ? 1.0 : _398._m18);
                _26995[_29893] = powr(_26995[_29893], 1.0);
                _26995[_29893] = fast::max(_26995[_29893], 6.099999882280826568603515625e-05);
            }
            float2 _11508 = (_11195 + _3271) + _29892.xy;
            float _11569 = _11508.x;
            bool _11570 = _11569 >= 0.0;
            bool _11576;
            if (_11570)
            {
                _11576 = _11569 <= 1.0;
            }
            else
            {
                _11576 = _11570;
            }
            bool _11588;
            if (_11576)
            {
                float _11579 = _11508.y;
                bool _11580 = _11579 >= 0.0;
                bool _11586;
                if (_11580)
                {
                    _11586 = _11579 <= 1.0;
                }
                else
                {
                    _11586 = _11580;
                }
                _11588 = _11586;
            }
            else
            {
                _11588 = _11576;
            }
            spvUnsafeArray<float, 5> _28469;
            if (_11588)
            {
                int2 _11520 = int2(floor(_11508 * _3270));
                for (int _29894 = 0; _29894 < 5; _29894++)
                {
                    int2 _11610 = _11520 + _955[_29894];
                    int2 _30549 = int2(max(0, min(_11610.x, (_398._m1.x - 1))), max(0, min(_11610.y, (_398._m1.y - 1))));
                    float4 _30272;
                    if (all(uint2(_30549) < uint2(int2(_477.get_width(), _477.get_height()))))
                    {
                        _30272 = _477.read(uint2(_30549), 0);
                    }
                    else
                    {
                        _30272 = float4(0.0);
                    }
                    _28469[_29894] = (_30272.x * _398._m10) * ((_398._m18 == 0.0) ? 1.0 : _398._m18);
                    _28469[_29894] = powr(_28469[_29894], 1.0);
                    _28469[_29894] = fast::max(_28469[_29894], 6.099999882280826568603515625e-05);
                }
            }
            float _29898;
            if (_11588)
            {
                float _11952 = fast::min(_26995[0], _26995[3]);
                float _11957 = fast::max(_26995[0], _26995[3]);
                float _11962 = fast::min(_26995[1], _26995[4]);
                float _11967 = fast::max(_26995[1], _26995[4]);
                float _11972 = fast::min(_11952, _26995[2]);
                float _11977 = fast::max(_11952, _26995[2]);
                float _11982 = fast::min(_11962, _11957);
                float _11987 = fast::max(_11962, _11957);
                float _11997 = fast::max(_11972, _11982);
                float _12002 = fast::min(_11977, _11967);
                float _12007 = fast::max(_11977, _11967);
                float _12017 = fast::max(_11997, _12002);
                float _12022 = fast::min(_11987, _12007);
                spvUnsafeArray<float, 5> _28452 = spvUnsafeArray<float, 5>({ fast::min(_11972, _11982), fast::min(_11997, _12002), fast::min(_12017, _12022), fast::max(_12017, _12022), fast::max(_11987, _12007) });
                spvUnsafeArray<float, 5> _27007 = _28452;
                float _12205 = fast::min(_28469[0], _28469[3]);
                float _12210 = fast::max(_28469[0], _28469[3]);
                float _12215 = fast::min(_28469[1], _28469[4]);
                float _12220 = fast::max(_28469[1], _28469[4]);
                float _12225 = fast::min(_12205, _28469[2]);
                float _12230 = fast::max(_12205, _28469[2]);
                float _12235 = fast::min(_12215, _12210);
                float _12240 = fast::max(_12215, _12210);
                float _12250 = fast::max(_12225, _12235);
                float _12255 = fast::min(_12230, _12220);
                float _12260 = fast::max(_12230, _12220);
                float _12270 = fast::max(_12250, _12255);
                float _12275 = fast::min(_12240, _12260);
                spvUnsafeArray<float, 5> _28468 = spvUnsafeArray<float, 5>({ fast::min(_12225, _12235), fast::min(_12250, _12255), fast::min(_12270, _12275), fast::max(_12270, _12275), fast::max(_12240, _12260) });
                spvUnsafeArray<float, 5> _27014 = _28468;
                float _29897;
                if (fast::min(_27007[4], _27014[4]) > 1.1754943508222875079687365372222e-38)
                {
                    float _29896;
                    _29896 = 65503.0;
                    float _30397;
                    int _30488;
                    int _30489;
                    for (int _29895 = 0, _30264 = 0, _30265 = 0; (_29895 < 5) && (_29896 < 65504.0); _30265 = _30489, _30264 = _30488, _29896 = _30397, _29895++)
                    {
                        float _11729 = _27007[_30264] - _27014[_30265];
                        if (abs(_11729) > 6.099999882280826568603515625e-05)
                        {
                            float _12318 = fast::max(_27007[_30264], _27014[_30265]);
                            float _30266;
                            if (_12318 != 0.0)
                            {
                                _30266 = fast::min(_27007[_30264], _27014[_30265]) / _12318;
                            }
                            else
                            {
                                _30266 = 0.0;
                            }
                            float _11744 = sign(_11729) * (1.0 - _30266);
                            int _11762 = _30264 + int(_27007[_30264] < _27014[_30265]);
                            _30489 = _30265 + int(_27007[_11762] >= _27014[_30265]);
                            _30488 = _11762;
                            _30397 = (abs(_11744) < abs(_29896)) ? _11744 : _29896;
                        }
                        else
                        {
                            _30489 = _30265;
                            _30488 = _30264;
                            _30397 = 65504.0;
                        }
                    }
                    _29897 = _29896;
                }
                else
                {
                    _29897 = 65503.0;
                }
                _29898 = _29897 * float(_29897 < 65503.0);
            }
            else
            {
                _29898 = 0.0;
            }
            float4 _29330 = float4(0.0);
            _29330.x = _29898;
            float _29905;
            if (_29898 != 0.0)
            {
                _29905 = sign(_29898);
            }
            else
            {
                _29905 = 0.0;
            }
            _29330.y = _29905;
            _29330.z = 1.0;
            _2576[1] = (((_29222 + _29258) + _29294) + _29330) * 0.25;
            if (all(uint2(_2682) < uint2(int2(_524.get_width(), _524.get_height()))))
            {
                _524.write(float4(_2576[1].xy, 0.0, 0.0), uint2(_2682));
            }
            int _2703 = int(_2635 + 32u);
            int2 _2705 = _2630 + int2(_2633, _2703);
            int _2714 = int(_2455 + 16u);
            int2 _2716 = _2642 + int2(_2644, _2714);
            uint2 _2718 = uint2(_2705);
            int2 _12481 = int2(float2(_2705));
            int2 _30525 = int2(max(0, min(_12481.x, _3000)), max(0, min(_12481.y, _3008)));
            float4 _29951;
            if (all(uint2(_30525) < uint2(int2(_496.get_width(), _496.get_height()))))
            {
                _29951 = _496.read(uint2(_30525), 0);
            }
            else
            {
                _29951 = float4(0.0);
            }
            float2 _12492 = (float2(_30525) + float2(0.5)) / _2961;
            int2 _12640 = int2(floor((_12492 + _3103) * _2961));
            spvUnsafeArray<float, 5> _26843;
            for (int _29952 = 0; _29952 < 5; _29952++)
            {
                int2 _12704 = _12640 + _955[_29952];
                int2 _30548 = int2(max(0, min(_12704.x, _3000)), max(0, min(_12704.y, _3008)));
                float4 _30262;
                if (all(uint2(_30548) < uint2(int2(_456.get_width(), _456.get_height()))))
                {
                    _30262 = _456.read(uint2(_30548), 0);
                }
                else
                {
                    _30262 = float4(0.0);
                }
                _26843[_29952] = _30262.x * ((_398._m18 == 0.0) ? 1.0 : _398._m18);
                _26843[_29952] = powr(_26843[_29952], 1.0);
                _26843[_29952] = fast::max(_26843[_29952], 6.099999882280826568603515625e-05);
            }
            float2 _12805 = (_12492 + _3271) + _29951.xy;
            float _12866 = _12805.x;
            bool _12867 = _12866 >= 0.0;
            bool _12873;
            if (_12867)
            {
                _12873 = _12866 <= 1.0;
            }
            else
            {
                _12873 = _12867;
            }
            bool _12885;
            if (_12873)
            {
                float _12876 = _12805.y;
                bool _12877 = _12876 >= 0.0;
                bool _12883;
                if (_12877)
                {
                    _12883 = _12876 <= 1.0;
                }
                else
                {
                    _12883 = _12877;
                }
                _12885 = _12883;
            }
            else
            {
                _12885 = _12873;
            }
            spvUnsafeArray<float, 5> _28425;
            if (_12885)
            {
                int2 _12817 = int2(floor(_12805 * _3270));
                for (int _29953 = 0; _29953 < 5; _29953++)
                {
                    int2 _12907 = _12817 + _955[_29953];
                    int2 _30547 = int2(max(0, min(_12907.x, (_398._m1.x - 1))), max(0, min(_12907.y, (_398._m1.y - 1))));
                    float4 _30260;
                    if (all(uint2(_30547) < uint2(int2(_477.get_width(), _477.get_height()))))
                    {
                        _30260 = _477.read(uint2(_30547), 0);
                    }
                    else
                    {
                        _30260 = float4(0.0);
                    }
                    _28425[_29953] = (_30260.x * _398._m10) * ((_398._m18 == 0.0) ? 1.0 : _398._m18);
                    _28425[_29953] = powr(_28425[_29953], 1.0);
                    _28425[_29953] = fast::max(_28425[_29953], 6.099999882280826568603515625e-05);
                }
            }
            float _29957;
            if (_12885)
            {
                float _13249 = fast::min(_26843[0], _26843[3]);
                float _13254 = fast::max(_26843[0], _26843[3]);
                float _13259 = fast::min(_26843[1], _26843[4]);
                float _13264 = fast::max(_26843[1], _26843[4]);
                float _13269 = fast::min(_13249, _26843[2]);
                float _13274 = fast::max(_13249, _26843[2]);
                float _13279 = fast::min(_13259, _13254);
                float _13284 = fast::max(_13259, _13254);
                float _13294 = fast::max(_13269, _13279);
                float _13299 = fast::min(_13274, _13264);
                float _13304 = fast::max(_13274, _13264);
                float _13314 = fast::max(_13294, _13299);
                float _13319 = fast::min(_13284, _13304);
                spvUnsafeArray<float, 5> _28408 = spvUnsafeArray<float, 5>({ fast::min(_13269, _13279), fast::min(_13294, _13299), fast::min(_13314, _13319), fast::max(_13314, _13319), fast::max(_13284, _13304) });
                spvUnsafeArray<float, 5> _26855 = _28408;
                float _13502 = fast::min(_28425[0], _28425[3]);
                float _13507 = fast::max(_28425[0], _28425[3]);
                float _13512 = fast::min(_28425[1], _28425[4]);
                float _13517 = fast::max(_28425[1], _28425[4]);
                float _13522 = fast::min(_13502, _28425[2]);
                float _13527 = fast::max(_13502, _28425[2]);
                float _13532 = fast::min(_13512, _13507);
                float _13537 = fast::max(_13512, _13507);
                float _13547 = fast::max(_13522, _13532);
                float _13552 = fast::min(_13527, _13517);
                float _13557 = fast::max(_13527, _13517);
                float _13567 = fast::max(_13547, _13552);
                float _13572 = fast::min(_13537, _13557);
                spvUnsafeArray<float, 5> _28424 = spvUnsafeArray<float, 5>({ fast::min(_13522, _13532), fast::min(_13547, _13552), fast::min(_13567, _13572), fast::max(_13567, _13572), fast::max(_13537, _13557) });
                spvUnsafeArray<float, 5> _26862 = _28424;
                float _29956;
                if (fast::min(_26855[4], _26862[4]) > 1.1754943508222875079687365372222e-38)
                {
                    float _29955;
                    _29955 = 65503.0;
                    float _30416;
                    int _30486;
                    int _30487;
                    for (int _29954 = 0, _30252 = 0, _30253 = 0; (_29954 < 5) && (_29955 < 65504.0); _30253 = _30487, _30252 = _30486, _29955 = _30416, _29954++)
                    {
                        float _13026 = _26855[_30252] - _26862[_30253];
                        if (abs(_13026) > 6.099999882280826568603515625e-05)
                        {
                            float _13615 = fast::max(_26855[_30252], _26862[_30253]);
                            float _30254;
                            if (_13615 != 0.0)
                            {
                                _30254 = fast::min(_26855[_30252], _26862[_30253]) / _13615;
                            }
                            else
                            {
                                _30254 = 0.0;
                            }
                            float _13041 = sign(_13026) * (1.0 - _30254);
                            int _13059 = _30252 + int(_26855[_30252] < _26862[_30253]);
                            _30487 = _30253 + int(_26855[_13059] >= _26862[_30253]);
                            _30486 = _13059;
                            _30416 = (abs(_13041) < abs(_29955)) ? _13041 : _29955;
                        }
                        else
                        {
                            _30487 = _30253;
                            _30486 = _30252;
                            _30416 = 65504.0;
                        }
                    }
                    _29956 = _29955;
                }
                else
                {
                    _29956 = 65503.0;
                }
                _29957 = _29956 * float(_29956 < 65503.0);
            }
            else
            {
                _29957 = 0.0;
            }
            float4 _29366 = float4(0.0);
            _29366.x = _29957;
            float _29964;
            if (_29957 != 0.0)
            {
                _29964 = sign(_29957);
            }
            else
            {
                _29964 = 0.0;
            }
            _29366.y = _29964;
            _29366.z = 1.0;
            int2 _13637 = int2(float2(int2(_2718 + uint2(0u, 1u))));
            int2 _30526 = int2(max(0, min(_13637.x, _3000)), max(0, min(_13637.y, _3008)));
            float4 _29966;
            if (all(uint2(_30526) < uint2(int2(_496.get_width(), _496.get_height()))))
            {
                _29966 = _496.read(uint2(_30526), 0);
            }
            else
            {
                _29966 = float4(0.0);
            }
            float2 _13648 = (float2(_30526) + float2(0.5)) / _2961;
            int2 _13796 = int2(floor((_13648 + _3103) * _2961));
            spvUnsafeArray<float, 5> _26691;
            for (int _29967 = 0; _29967 < 5; _29967++)
            {
                int2 _13860 = _13796 + _955[_29967];
                int2 _30546 = int2(max(0, min(_13860.x, _3000)), max(0, min(_13860.y, _3008)));
                float4 _30250;
                if (all(uint2(_30546) < uint2(int2(_456.get_width(), _456.get_height()))))
                {
                    _30250 = _456.read(uint2(_30546), 0);
                }
                else
                {
                    _30250 = float4(0.0);
                }
                _26691[_29967] = _30250.x * ((_398._m18 == 0.0) ? 1.0 : _398._m18);
                _26691[_29967] = powr(_26691[_29967], 1.0);
                _26691[_29967] = fast::max(_26691[_29967], 6.099999882280826568603515625e-05);
            }
            float2 _13961 = (_13648 + _3271) + _29966.xy;
            float _14022 = _13961.x;
            bool _14023 = _14022 >= 0.0;
            bool _14029;
            if (_14023)
            {
                _14029 = _14022 <= 1.0;
            }
            else
            {
                _14029 = _14023;
            }
            bool _14041;
            if (_14029)
            {
                float _14032 = _13961.y;
                bool _14033 = _14032 >= 0.0;
                bool _14039;
                if (_14033)
                {
                    _14039 = _14032 <= 1.0;
                }
                else
                {
                    _14039 = _14033;
                }
                _14041 = _14039;
            }
            else
            {
                _14041 = _14029;
            }
            spvUnsafeArray<float, 5> _28381;
            if (_14041)
            {
                int2 _13973 = int2(floor(_13961 * _3270));
                for (int _29968 = 0; _29968 < 5; _29968++)
                {
                    int2 _14063 = _13973 + _955[_29968];
                    int2 _30545 = int2(max(0, min(_14063.x, (_398._m1.x - 1))), max(0, min(_14063.y, (_398._m1.y - 1))));
                    float4 _30248;
                    if (all(uint2(_30545) < uint2(int2(_477.get_width(), _477.get_height()))))
                    {
                        _30248 = _477.read(uint2(_30545), 0);
                    }
                    else
                    {
                        _30248 = float4(0.0);
                    }
                    _28381[_29968] = (_30248.x * _398._m10) * ((_398._m18 == 0.0) ? 1.0 : _398._m18);
                    _28381[_29968] = powr(_28381[_29968], 1.0);
                    _28381[_29968] = fast::max(_28381[_29968], 6.099999882280826568603515625e-05);
                }
            }
            float _29972;
            if (_14041)
            {
                float _14405 = fast::min(_26691[0], _26691[3]);
                float _14410 = fast::max(_26691[0], _26691[3]);
                float _14415 = fast::min(_26691[1], _26691[4]);
                float _14420 = fast::max(_26691[1], _26691[4]);
                float _14425 = fast::min(_14405, _26691[2]);
                float _14430 = fast::max(_14405, _26691[2]);
                float _14435 = fast::min(_14415, _14410);
                float _14440 = fast::max(_14415, _14410);
                float _14450 = fast::max(_14425, _14435);
                float _14455 = fast::min(_14430, _14420);
                float _14460 = fast::max(_14430, _14420);
                float _14470 = fast::max(_14450, _14455);
                float _14475 = fast::min(_14440, _14460);
                spvUnsafeArray<float, 5> _28364 = spvUnsafeArray<float, 5>({ fast::min(_14425, _14435), fast::min(_14450, _14455), fast::min(_14470, _14475), fast::max(_14470, _14475), fast::max(_14440, _14460) });
                spvUnsafeArray<float, 5> _26703 = _28364;
                float _14658 = fast::min(_28381[0], _28381[3]);
                float _14663 = fast::max(_28381[0], _28381[3]);
                float _14668 = fast::min(_28381[1], _28381[4]);
                float _14673 = fast::max(_28381[1], _28381[4]);
                float _14678 = fast::min(_14658, _28381[2]);
                float _14683 = fast::max(_14658, _28381[2]);
                float _14688 = fast::min(_14668, _14663);
                float _14693 = fast::max(_14668, _14663);
                float _14703 = fast::max(_14678, _14688);
                float _14708 = fast::min(_14683, _14673);
                float _14713 = fast::max(_14683, _14673);
                float _14723 = fast::max(_14703, _14708);
                float _14728 = fast::min(_14693, _14713);
                spvUnsafeArray<float, 5> _28380 = spvUnsafeArray<float, 5>({ fast::min(_14678, _14688), fast::min(_14703, _14708), fast::min(_14723, _14728), fast::max(_14723, _14728), fast::max(_14693, _14713) });
                spvUnsafeArray<float, 5> _26710 = _28380;
                float _29971;
                if (fast::min(_26703[4], _26710[4]) > 1.1754943508222875079687365372222e-38)
                {
                    float _29970;
                    _29970 = 65503.0;
                    float _30419;
                    int _30484;
                    int _30485;
                    for (int _29969 = 0, _30240 = 0, _30241 = 0; (_29969 < 5) && (_29970 < 65504.0); _30241 = _30485, _30240 = _30484, _29970 = _30419, _29969++)
                    {
                        float _14182 = _26703[_30240] - _26710[_30241];
                        if (abs(_14182) > 6.099999882280826568603515625e-05)
                        {
                            float _14771 = fast::max(_26703[_30240], _26710[_30241]);
                            float _30242;
                            if (_14771 != 0.0)
                            {
                                _30242 = fast::min(_26703[_30240], _26710[_30241]) / _14771;
                            }
                            else
                            {
                                _30242 = 0.0;
                            }
                            float _14197 = sign(_14182) * (1.0 - _30242);
                            int _14215 = _30240 + int(_26703[_30240] < _26710[_30241]);
                            _30485 = _30241 + int(_26703[_14215] >= _26710[_30241]);
                            _30484 = _14215;
                            _30419 = (abs(_14197) < abs(_29970)) ? _14197 : _29970;
                        }
                        else
                        {
                            _30485 = _30241;
                            _30484 = _30240;
                            _30419 = 65504.0;
                        }
                    }
                    _29971 = _29970;
                }
                else
                {
                    _29971 = 65503.0;
                }
                _29972 = _29971 * float(_29971 < 65503.0);
            }
            else
            {
                _29972 = 0.0;
            }
            float4 _29402 = float4(0.0);
            _29402.x = _29972;
            float _29979;
            if (_29972 != 0.0)
            {
                _29979 = sign(_29972);
            }
            else
            {
                _29979 = 0.0;
            }
            _29402.y = _29979;
            _29402.z = 1.0;
            int2 _14793 = int2(float2(int2(_2718 + uint2(1u, 0u))));
            int2 _30527 = int2(max(0, min(_14793.x, _3000)), max(0, min(_14793.y, _3008)));
            float4 _29981;
            if (all(uint2(_30527) < uint2(int2(_496.get_width(), _496.get_height()))))
            {
                _29981 = _496.read(uint2(_30527), 0);
            }
            else
            {
                _29981 = float4(0.0);
            }
            float2 _14804 = (float2(_30527) + float2(0.5)) / _2961;
            int2 _14952 = int2(floor((_14804 + _3103) * _2961));
            spvUnsafeArray<float, 5> _26539;
            for (int _29982 = 0; _29982 < 5; _29982++)
            {
                int2 _15016 = _14952 + _955[_29982];
                int2 _30544 = int2(max(0, min(_15016.x, _3000)), max(0, min(_15016.y, _3008)));
                float4 _30238;
                if (all(uint2(_30544) < uint2(int2(_456.get_width(), _456.get_height()))))
                {
                    _30238 = _456.read(uint2(_30544), 0);
                }
                else
                {
                    _30238 = float4(0.0);
                }
                _26539[_29982] = _30238.x * ((_398._m18 == 0.0) ? 1.0 : _398._m18);
                _26539[_29982] = powr(_26539[_29982], 1.0);
                _26539[_29982] = fast::max(_26539[_29982], 6.099999882280826568603515625e-05);
            }
            float2 _15117 = (_14804 + _3271) + _29981.xy;
            float _15178 = _15117.x;
            bool _15179 = _15178 >= 0.0;
            bool _15185;
            if (_15179)
            {
                _15185 = _15178 <= 1.0;
            }
            else
            {
                _15185 = _15179;
            }
            bool _15197;
            if (_15185)
            {
                float _15188 = _15117.y;
                bool _15189 = _15188 >= 0.0;
                bool _15195;
                if (_15189)
                {
                    _15195 = _15188 <= 1.0;
                }
                else
                {
                    _15195 = _15189;
                }
                _15197 = _15195;
            }
            else
            {
                _15197 = _15185;
            }
            spvUnsafeArray<float, 5> _28337;
            if (_15197)
            {
                int2 _15129 = int2(floor(_15117 * _3270));
                for (int _29983 = 0; _29983 < 5; _29983++)
                {
                    int2 _15219 = _15129 + _955[_29983];
                    int2 _30543 = int2(max(0, min(_15219.x, (_398._m1.x - 1))), max(0, min(_15219.y, (_398._m1.y - 1))));
                    float4 _30236;
                    if (all(uint2(_30543) < uint2(int2(_477.get_width(), _477.get_height()))))
                    {
                        _30236 = _477.read(uint2(_30543), 0);
                    }
                    else
                    {
                        _30236 = float4(0.0);
                    }
                    _28337[_29983] = (_30236.x * _398._m10) * ((_398._m18 == 0.0) ? 1.0 : _398._m18);
                    _28337[_29983] = powr(_28337[_29983], 1.0);
                    _28337[_29983] = fast::max(_28337[_29983], 6.099999882280826568603515625e-05);
                }
            }
            float _29987;
            if (_15197)
            {
                float _15561 = fast::min(_26539[0], _26539[3]);
                float _15566 = fast::max(_26539[0], _26539[3]);
                float _15571 = fast::min(_26539[1], _26539[4]);
                float _15576 = fast::max(_26539[1], _26539[4]);
                float _15581 = fast::min(_15561, _26539[2]);
                float _15586 = fast::max(_15561, _26539[2]);
                float _15591 = fast::min(_15571, _15566);
                float _15596 = fast::max(_15571, _15566);
                float _15606 = fast::max(_15581, _15591);
                float _15611 = fast::min(_15586, _15576);
                float _15616 = fast::max(_15586, _15576);
                float _15626 = fast::max(_15606, _15611);
                float _15631 = fast::min(_15596, _15616);
                spvUnsafeArray<float, 5> _28320 = spvUnsafeArray<float, 5>({ fast::min(_15581, _15591), fast::min(_15606, _15611), fast::min(_15626, _15631), fast::max(_15626, _15631), fast::max(_15596, _15616) });
                spvUnsafeArray<float, 5> _26551 = _28320;
                float _15814 = fast::min(_28337[0], _28337[3]);
                float _15819 = fast::max(_28337[0], _28337[3]);
                float _15824 = fast::min(_28337[1], _28337[4]);
                float _15829 = fast::max(_28337[1], _28337[4]);
                float _15834 = fast::min(_15814, _28337[2]);
                float _15839 = fast::max(_15814, _28337[2]);
                float _15844 = fast::min(_15824, _15819);
                float _15849 = fast::max(_15824, _15819);
                float _15859 = fast::max(_15834, _15844);
                float _15864 = fast::min(_15839, _15829);
                float _15869 = fast::max(_15839, _15829);
                float _15879 = fast::max(_15859, _15864);
                float _15884 = fast::min(_15849, _15869);
                spvUnsafeArray<float, 5> _28336 = spvUnsafeArray<float, 5>({ fast::min(_15834, _15844), fast::min(_15859, _15864), fast::min(_15879, _15884), fast::max(_15879, _15884), fast::max(_15849, _15869) });
                spvUnsafeArray<float, 5> _26558 = _28336;
                float _29986;
                if (fast::min(_26551[4], _26558[4]) > 1.1754943508222875079687365372222e-38)
                {
                    float _29985;
                    _29985 = 65503.0;
                    float _30422;
                    int _30482;
                    int _30483;
                    for (int _29984 = 0, _30228 = 0, _30229 = 0; (_29984 < 5) && (_29985 < 65504.0); _30229 = _30483, _30228 = _30482, _29985 = _30422, _29984++)
                    {
                        float _15338 = _26551[_30228] - _26558[_30229];
                        if (abs(_15338) > 6.099999882280826568603515625e-05)
                        {
                            float _15927 = fast::max(_26551[_30228], _26558[_30229]);
                            float _30230;
                            if (_15927 != 0.0)
                            {
                                _30230 = fast::min(_26551[_30228], _26558[_30229]) / _15927;
                            }
                            else
                            {
                                _30230 = 0.0;
                            }
                            float _15353 = sign(_15338) * (1.0 - _30230);
                            int _15371 = _30228 + int(_26551[_30228] < _26558[_30229]);
                            _30483 = _30229 + int(_26551[_15371] >= _26558[_30229]);
                            _30482 = _15371;
                            _30422 = (abs(_15353) < abs(_29985)) ? _15353 : _29985;
                        }
                        else
                        {
                            _30483 = _30229;
                            _30482 = _30228;
                            _30422 = 65504.0;
                        }
                    }
                    _29986 = _29985;
                }
                else
                {
                    _29986 = 65503.0;
                }
                _29987 = _29986 * float(_29986 < 65503.0);
            }
            else
            {
                _29987 = 0.0;
            }
            float4 _29438 = float4(0.0);
            _29438.x = _29987;
            float _29994;
            if (_29987 != 0.0)
            {
                _29994 = sign(_29987);
            }
            else
            {
                _29994 = 0.0;
            }
            _29438.y = _29994;
            _29438.z = 1.0;
            int2 _15949 = int2(float2(int2(_2718 + uint2(1u))));
            int2 _30528 = int2(max(0, min(_15949.x, _3000)), max(0, min(_15949.y, _3008)));
            float4 _29996;
            if (all(uint2(_30528) < uint2(int2(_496.get_width(), _496.get_height()))))
            {
                _29996 = _496.read(uint2(_30528), 0);
            }
            else
            {
                _29996 = float4(0.0);
            }
            float2 _15960 = (float2(_30528) + float2(0.5)) / _2961;
            int2 _16108 = int2(floor((_15960 + _3103) * _2961));
            spvUnsafeArray<float, 5> _26387;
            for (int _29997 = 0; _29997 < 5; _29997++)
            {
                int2 _16172 = _16108 + _955[_29997];
                int2 _30542 = int2(max(0, min(_16172.x, _3000)), max(0, min(_16172.y, _3008)));
                float4 _30226;
                if (all(uint2(_30542) < uint2(int2(_456.get_width(), _456.get_height()))))
                {
                    _30226 = _456.read(uint2(_30542), 0);
                }
                else
                {
                    _30226 = float4(0.0);
                }
                _26387[_29997] = _30226.x * ((_398._m18 == 0.0) ? 1.0 : _398._m18);
                _26387[_29997] = powr(_26387[_29997], 1.0);
                _26387[_29997] = fast::max(_26387[_29997], 6.099999882280826568603515625e-05);
            }
            float2 _16273 = (_15960 + _3271) + _29996.xy;
            float _16334 = _16273.x;
            bool _16335 = _16334 >= 0.0;
            bool _16341;
            if (_16335)
            {
                _16341 = _16334 <= 1.0;
            }
            else
            {
                _16341 = _16335;
            }
            bool _16353;
            if (_16341)
            {
                float _16344 = _16273.y;
                bool _16345 = _16344 >= 0.0;
                bool _16351;
                if (_16345)
                {
                    _16351 = _16344 <= 1.0;
                }
                else
                {
                    _16351 = _16345;
                }
                _16353 = _16351;
            }
            else
            {
                _16353 = _16341;
            }
            spvUnsafeArray<float, 5> _28293;
            if (_16353)
            {
                int2 _16285 = int2(floor(_16273 * _3270));
                for (int _29998 = 0; _29998 < 5; _29998++)
                {
                    int2 _16375 = _16285 + _955[_29998];
                    int2 _30541 = int2(max(0, min(_16375.x, (_398._m1.x - 1))), max(0, min(_16375.y, (_398._m1.y - 1))));
                    float4 _30224;
                    if (all(uint2(_30541) < uint2(int2(_477.get_width(), _477.get_height()))))
                    {
                        _30224 = _477.read(uint2(_30541), 0);
                    }
                    else
                    {
                        _30224 = float4(0.0);
                    }
                    _28293[_29998] = (_30224.x * _398._m10) * ((_398._m18 == 0.0) ? 1.0 : _398._m18);
                    _28293[_29998] = powr(_28293[_29998], 1.0);
                    _28293[_29998] = fast::max(_28293[_29998], 6.099999882280826568603515625e-05);
                }
            }
            float _30002;
            if (_16353)
            {
                float _16717 = fast::min(_26387[0], _26387[3]);
                float _16722 = fast::max(_26387[0], _26387[3]);
                float _16727 = fast::min(_26387[1], _26387[4]);
                float _16732 = fast::max(_26387[1], _26387[4]);
                float _16737 = fast::min(_16717, _26387[2]);
                float _16742 = fast::max(_16717, _26387[2]);
                float _16747 = fast::min(_16727, _16722);
                float _16752 = fast::max(_16727, _16722);
                float _16762 = fast::max(_16737, _16747);
                float _16767 = fast::min(_16742, _16732);
                float _16772 = fast::max(_16742, _16732);
                float _16782 = fast::max(_16762, _16767);
                float _16787 = fast::min(_16752, _16772);
                spvUnsafeArray<float, 5> _28276 = spvUnsafeArray<float, 5>({ fast::min(_16737, _16747), fast::min(_16762, _16767), fast::min(_16782, _16787), fast::max(_16782, _16787), fast::max(_16752, _16772) });
                spvUnsafeArray<float, 5> _26399 = _28276;
                float _16970 = fast::min(_28293[0], _28293[3]);
                float _16975 = fast::max(_28293[0], _28293[3]);
                float _16980 = fast::min(_28293[1], _28293[4]);
                float _16985 = fast::max(_28293[1], _28293[4]);
                float _16990 = fast::min(_16970, _28293[2]);
                float _16995 = fast::max(_16970, _28293[2]);
                float _17000 = fast::min(_16980, _16975);
                float _17005 = fast::max(_16980, _16975);
                float _17015 = fast::max(_16990, _17000);
                float _17020 = fast::min(_16995, _16985);
                float _17025 = fast::max(_16995, _16985);
                float _17035 = fast::max(_17015, _17020);
                float _17040 = fast::min(_17005, _17025);
                spvUnsafeArray<float, 5> _28292 = spvUnsafeArray<float, 5>({ fast::min(_16990, _17000), fast::min(_17015, _17020), fast::min(_17035, _17040), fast::max(_17035, _17040), fast::max(_17005, _17025) });
                spvUnsafeArray<float, 5> _26406 = _28292;
                float _30001;
                if (fast::min(_26399[4], _26406[4]) > 1.1754943508222875079687365372222e-38)
                {
                    float _30000;
                    _30000 = 65503.0;
                    float _30425;
                    int _30480;
                    int _30481;
                    for (int _29999 = 0, _30216 = 0, _30217 = 0; (_29999 < 5) && (_30000 < 65504.0); _30217 = _30481, _30216 = _30480, _30000 = _30425, _29999++)
                    {
                        float _16494 = _26399[_30216] - _26406[_30217];
                        if (abs(_16494) > 6.099999882280826568603515625e-05)
                        {
                            float _17083 = fast::max(_26399[_30216], _26406[_30217]);
                            float _30218;
                            if (_17083 != 0.0)
                            {
                                _30218 = fast::min(_26399[_30216], _26406[_30217]) / _17083;
                            }
                            else
                            {
                                _30218 = 0.0;
                            }
                            float _16509 = sign(_16494) * (1.0 - _30218);
                            int _16527 = _30216 + int(_26399[_30216] < _26406[_30217]);
                            _30481 = _30217 + int(_26399[_16527] >= _26406[_30217]);
                            _30480 = _16527;
                            _30425 = (abs(_16509) < abs(_30000)) ? _16509 : _30000;
                        }
                        else
                        {
                            _30481 = _30217;
                            _30480 = _30216;
                            _30425 = 65504.0;
                        }
                    }
                    _30001 = _30000;
                }
                else
                {
                    _30001 = 65503.0;
                }
                _30002 = _30001 * float(_30001 < 65503.0);
            }
            else
            {
                _30002 = 0.0;
            }
            float4 _29474 = float4(0.0);
            _29474.x = _30002;
            float _30009;
            if (_30002 != 0.0)
            {
                _30009 = sign(_30002);
            }
            else
            {
                _30009 = 0.0;
            }
            _29474.y = _30009;
            _29474.z = 1.0;
            _2576[2] = (((_29366 + _29402) + _29438) + _29474) * 0.25;
            if (all(uint2(_2716) < uint2(int2(_524.get_width(), _524.get_height()))))
            {
                _524.write(float4(_2576[2].xy, 0.0, 0.0), uint2(_2716));
            }
            int2 _2740 = _2630 + int2(_2666, _2703);
            int2 _2752 = _2642 + int2(_2678, _2714);
            uint2 _2754 = uint2(_2740);
            int2 _17246 = int2(float2(_2740));
            int2 _30529 = int2(max(0, min(_17246.x, _3000)), max(0, min(_17246.y, _3008)));
            float4 _30055;
            if (all(uint2(_30529) < uint2(int2(_496.get_width(), _496.get_height()))))
            {
                _30055 = _496.read(uint2(_30529), 0);
            }
            else
            {
                _30055 = float4(0.0);
            }
            float2 _17257 = (float2(_30529) + float2(0.5)) / _2961;
            int2 _17405 = int2(floor((_17257 + _3103) * _2961));
            spvUnsafeArray<float, 5> _26235;
            for (int _30056 = 0; _30056 < 5; _30056++)
            {
                int2 _17469 = _17405 + _955[_30056];
                int2 _30540 = int2(max(0, min(_17469.x, _3000)), max(0, min(_17469.y, _3008)));
                float4 _30214;
                if (all(uint2(_30540) < uint2(int2(_456.get_width(), _456.get_height()))))
                {
                    _30214 = _456.read(uint2(_30540), 0);
                }
                else
                {
                    _30214 = float4(0.0);
                }
                _26235[_30056] = _30214.x * ((_398._m18 == 0.0) ? 1.0 : _398._m18);
                _26235[_30056] = powr(_26235[_30056], 1.0);
                _26235[_30056] = fast::max(_26235[_30056], 6.099999882280826568603515625e-05);
            }
            float2 _17570 = (_17257 + _3271) + _30055.xy;
            float _17631 = _17570.x;
            bool _17632 = _17631 >= 0.0;
            bool _17638;
            if (_17632)
            {
                _17638 = _17631 <= 1.0;
            }
            else
            {
                _17638 = _17632;
            }
            bool _17650;
            if (_17638)
            {
                float _17641 = _17570.y;
                bool _17642 = _17641 >= 0.0;
                bool _17648;
                if (_17642)
                {
                    _17648 = _17641 <= 1.0;
                }
                else
                {
                    _17648 = _17642;
                }
                _17650 = _17648;
            }
            else
            {
                _17650 = _17638;
            }
            spvUnsafeArray<float, 5> _28249;
            if (_17650)
            {
                int2 _17582 = int2(floor(_17570 * _3270));
                for (int _30057 = 0; _30057 < 5; _30057++)
                {
                    int2 _17672 = _17582 + _955[_30057];
                    int2 _30539 = int2(max(0, min(_17672.x, (_398._m1.x - 1))), max(0, min(_17672.y, (_398._m1.y - 1))));
                    float4 _30212;
                    if (all(uint2(_30539) < uint2(int2(_477.get_width(), _477.get_height()))))
                    {
                        _30212 = _477.read(uint2(_30539), 0);
                    }
                    else
                    {
                        _30212 = float4(0.0);
                    }
                    _28249[_30057] = (_30212.x * _398._m10) * ((_398._m18 == 0.0) ? 1.0 : _398._m18);
                    _28249[_30057] = powr(_28249[_30057], 1.0);
                    _28249[_30057] = fast::max(_28249[_30057], 6.099999882280826568603515625e-05);
                }
            }
            float _30061;
            if (_17650)
            {
                float _18014 = fast::min(_26235[0], _26235[3]);
                float _18019 = fast::max(_26235[0], _26235[3]);
                float _18024 = fast::min(_26235[1], _26235[4]);
                float _18029 = fast::max(_26235[1], _26235[4]);
                float _18034 = fast::min(_18014, _26235[2]);
                float _18039 = fast::max(_18014, _26235[2]);
                float _18044 = fast::min(_18024, _18019);
                float _18049 = fast::max(_18024, _18019);
                float _18059 = fast::max(_18034, _18044);
                float _18064 = fast::min(_18039, _18029);
                float _18069 = fast::max(_18039, _18029);
                float _18079 = fast::max(_18059, _18064);
                float _18084 = fast::min(_18049, _18069);
                spvUnsafeArray<float, 5> _28232 = spvUnsafeArray<float, 5>({ fast::min(_18034, _18044), fast::min(_18059, _18064), fast::min(_18079, _18084), fast::max(_18079, _18084), fast::max(_18049, _18069) });
                spvUnsafeArray<float, 5> _26247 = _28232;
                float _18267 = fast::min(_28249[0], _28249[3]);
                float _18272 = fast::max(_28249[0], _28249[3]);
                float _18277 = fast::min(_28249[1], _28249[4]);
                float _18282 = fast::max(_28249[1], _28249[4]);
                float _18287 = fast::min(_18267, _28249[2]);
                float _18292 = fast::max(_18267, _28249[2]);
                float _18297 = fast::min(_18277, _18272);
                float _18302 = fast::max(_18277, _18272);
                float _18312 = fast::max(_18287, _18297);
                float _18317 = fast::min(_18292, _18282);
                float _18322 = fast::max(_18292, _18282);
                float _18332 = fast::max(_18312, _18317);
                float _18337 = fast::min(_18302, _18322);
                spvUnsafeArray<float, 5> _28248 = spvUnsafeArray<float, 5>({ fast::min(_18287, _18297), fast::min(_18312, _18317), fast::min(_18332, _18337), fast::max(_18332, _18337), fast::max(_18302, _18322) });
                spvUnsafeArray<float, 5> _26254 = _28248;
                float _30060;
                if (fast::min(_26247[4], _26254[4]) > 1.1754943508222875079687365372222e-38)
                {
                    float _30059;
                    _30059 = 65503.0;
                    float _30444;
                    int _30478;
                    int _30479;
                    for (int _30058 = 0, _30204 = 0, _30205 = 0; (_30058 < 5) && (_30059 < 65504.0); _30205 = _30479, _30204 = _30478, _30059 = _30444, _30058++)
                    {
                        float _17791 = _26247[_30204] - _26254[_30205];
                        if (abs(_17791) > 6.099999882280826568603515625e-05)
                        {
                            float _18380 = fast::max(_26247[_30204], _26254[_30205]);
                            float _30206;
                            if (_18380 != 0.0)
                            {
                                _30206 = fast::min(_26247[_30204], _26254[_30205]) / _18380;
                            }
                            else
                            {
                                _30206 = 0.0;
                            }
                            float _17806 = sign(_17791) * (1.0 - _30206);
                            int _17824 = _30204 + int(_26247[_30204] < _26254[_30205]);
                            _30479 = _30205 + int(_26247[_17824] >= _26254[_30205]);
                            _30478 = _17824;
                            _30444 = (abs(_17806) < abs(_30059)) ? _17806 : _30059;
                        }
                        else
                        {
                            _30479 = _30205;
                            _30478 = _30204;
                            _30444 = 65504.0;
                        }
                    }
                    _30060 = _30059;
                }
                else
                {
                    _30060 = 65503.0;
                }
                _30061 = _30060 * float(_30060 < 65503.0);
            }
            else
            {
                _30061 = 0.0;
            }
            float4 _29510 = float4(0.0);
            _29510.x = _30061;
            float _30068;
            if (_30061 != 0.0)
            {
                _30068 = sign(_30061);
            }
            else
            {
                _30068 = 0.0;
            }
            _29510.y = _30068;
            _29510.z = 1.0;
            int2 _18402 = int2(float2(int2(_2754 + uint2(0u, 1u))));
            int2 _30530 = int2(max(0, min(_18402.x, _3000)), max(0, min(_18402.y, _3008)));
            float4 _30070;
            if (all(uint2(_30530) < uint2(int2(_496.get_width(), _496.get_height()))))
            {
                _30070 = _496.read(uint2(_30530), 0);
            }
            else
            {
                _30070 = float4(0.0);
            }
            float2 _18413 = (float2(_30530) + float2(0.5)) / _2961;
            int2 _18561 = int2(floor((_18413 + _3103) * _2961));
            spvUnsafeArray<float, 5> _26083;
            for (int _30071 = 0; _30071 < 5; _30071++)
            {
                int2 _18625 = _18561 + _955[_30071];
                int2 _30538 = int2(max(0, min(_18625.x, _3000)), max(0, min(_18625.y, _3008)));
                float4 _30202;
                if (all(uint2(_30538) < uint2(int2(_456.get_width(), _456.get_height()))))
                {
                    _30202 = _456.read(uint2(_30538), 0);
                }
                else
                {
                    _30202 = float4(0.0);
                }
                _26083[_30071] = _30202.x * ((_398._m18 == 0.0) ? 1.0 : _398._m18);
                _26083[_30071] = powr(_26083[_30071], 1.0);
                _26083[_30071] = fast::max(_26083[_30071], 6.099999882280826568603515625e-05);
            }
            float2 _18726 = (_18413 + _3271) + _30070.xy;
            float _18787 = _18726.x;
            bool _18788 = _18787 >= 0.0;
            bool _18794;
            if (_18788)
            {
                _18794 = _18787 <= 1.0;
            }
            else
            {
                _18794 = _18788;
            }
            bool _18806;
            if (_18794)
            {
                float _18797 = _18726.y;
                bool _18798 = _18797 >= 0.0;
                bool _18804;
                if (_18798)
                {
                    _18804 = _18797 <= 1.0;
                }
                else
                {
                    _18804 = _18798;
                }
                _18806 = _18804;
            }
            else
            {
                _18806 = _18794;
            }
            spvUnsafeArray<float, 5> _28205;
            if (_18806)
            {
                int2 _18738 = int2(floor(_18726 * _3270));
                for (int _30072 = 0; _30072 < 5; _30072++)
                {
                    int2 _18828 = _18738 + _955[_30072];
                    int2 _30537 = int2(max(0, min(_18828.x, (_398._m1.x - 1))), max(0, min(_18828.y, (_398._m1.y - 1))));
                    float4 _30200;
                    if (all(uint2(_30537) < uint2(int2(_477.get_width(), _477.get_height()))))
                    {
                        _30200 = _477.read(uint2(_30537), 0);
                    }
                    else
                    {
                        _30200 = float4(0.0);
                    }
                    _28205[_30072] = (_30200.x * _398._m10) * ((_398._m18 == 0.0) ? 1.0 : _398._m18);
                    _28205[_30072] = powr(_28205[_30072], 1.0);
                    _28205[_30072] = fast::max(_28205[_30072], 6.099999882280826568603515625e-05);
                }
            }
            float _30076;
            if (_18806)
            {
                float _19170 = fast::min(_26083[0], _26083[3]);
                float _19175 = fast::max(_26083[0], _26083[3]);
                float _19180 = fast::min(_26083[1], _26083[4]);
                float _19185 = fast::max(_26083[1], _26083[4]);
                float _19190 = fast::min(_19170, _26083[2]);
                float _19195 = fast::max(_19170, _26083[2]);
                float _19200 = fast::min(_19180, _19175);
                float _19205 = fast::max(_19180, _19175);
                float _19215 = fast::max(_19190, _19200);
                float _19220 = fast::min(_19195, _19185);
                float _19225 = fast::max(_19195, _19185);
                float _19235 = fast::max(_19215, _19220);
                float _19240 = fast::min(_19205, _19225);
                spvUnsafeArray<float, 5> _28188 = spvUnsafeArray<float, 5>({ fast::min(_19190, _19200), fast::min(_19215, _19220), fast::min(_19235, _19240), fast::max(_19235, _19240), fast::max(_19205, _19225) });
                spvUnsafeArray<float, 5> _26095 = _28188;
                float _19423 = fast::min(_28205[0], _28205[3]);
                float _19428 = fast::max(_28205[0], _28205[3]);
                float _19433 = fast::min(_28205[1], _28205[4]);
                float _19438 = fast::max(_28205[1], _28205[4]);
                float _19443 = fast::min(_19423, _28205[2]);
                float _19448 = fast::max(_19423, _28205[2]);
                float _19453 = fast::min(_19433, _19428);
                float _19458 = fast::max(_19433, _19428);
                float _19468 = fast::max(_19443, _19453);
                float _19473 = fast::min(_19448, _19438);
                float _19478 = fast::max(_19448, _19438);
                float _19488 = fast::max(_19468, _19473);
                float _19493 = fast::min(_19458, _19478);
                spvUnsafeArray<float, 5> _28204 = spvUnsafeArray<float, 5>({ fast::min(_19443, _19453), fast::min(_19468, _19473), fast::min(_19488, _19493), fast::max(_19488, _19493), fast::max(_19458, _19478) });
                spvUnsafeArray<float, 5> _26102 = _28204;
                float _30075;
                if (fast::min(_26095[4], _26102[4]) > 1.1754943508222875079687365372222e-38)
                {
                    float _30074;
                    _30074 = 65503.0;
                    float _30447;
                    int _30476;
                    int _30477;
                    for (int _30073 = 0, _30192 = 0, _30193 = 0; (_30073 < 5) && (_30074 < 65504.0); _30193 = _30477, _30192 = _30476, _30074 = _30447, _30073++)
                    {
                        float _18947 = _26095[_30192] - _26102[_30193];
                        if (abs(_18947) > 6.099999882280826568603515625e-05)
                        {
                            float _19536 = fast::max(_26095[_30192], _26102[_30193]);
                            float _30194;
                            if (_19536 != 0.0)
                            {
                                _30194 = fast::min(_26095[_30192], _26102[_30193]) / _19536;
                            }
                            else
                            {
                                _30194 = 0.0;
                            }
                            float _18962 = sign(_18947) * (1.0 - _30194);
                            int _18980 = _30192 + int(_26095[_30192] < _26102[_30193]);
                            _30477 = _30193 + int(_26095[_18980] >= _26102[_30193]);
                            _30476 = _18980;
                            _30447 = (abs(_18962) < abs(_30074)) ? _18962 : _30074;
                        }
                        else
                        {
                            _30477 = _30193;
                            _30476 = _30192;
                            _30447 = 65504.0;
                        }
                    }
                    _30075 = _30074;
                }
                else
                {
                    _30075 = 65503.0;
                }
                _30076 = _30075 * float(_30075 < 65503.0);
            }
            else
            {
                _30076 = 0.0;
            }
            float4 _29546 = float4(0.0);
            _29546.x = _30076;
            float _30083;
            if (_30076 != 0.0)
            {
                _30083 = sign(_30076);
            }
            else
            {
                _30083 = 0.0;
            }
            _29546.y = _30083;
            _29546.z = 1.0;
            int2 _19558 = int2(float2(int2(_2754 + uint2(1u, 0u))));
            int2 _30531 = int2(max(0, min(_19558.x, _3000)), max(0, min(_19558.y, _3008)));
            float4 _30085;
            if (all(uint2(_30531) < uint2(int2(_496.get_width(), _496.get_height()))))
            {
                _30085 = _496.read(uint2(_30531), 0);
            }
            else
            {
                _30085 = float4(0.0);
            }
            float2 _19569 = (float2(_30531) + float2(0.5)) / _2961;
            int2 _19717 = int2(floor((_19569 + _3103) * _2961));
            spvUnsafeArray<float, 5> _25931;
            for (int _30086 = 0; _30086 < 5; _30086++)
            {
                int2 _19781 = _19717 + _955[_30086];
                int2 _30536 = int2(max(0, min(_19781.x, _3000)), max(0, min(_19781.y, _3008)));
                float4 _30190;
                if (all(uint2(_30536) < uint2(int2(_456.get_width(), _456.get_height()))))
                {
                    _30190 = _456.read(uint2(_30536), 0);
                }
                else
                {
                    _30190 = float4(0.0);
                }
                _25931[_30086] = _30190.x * ((_398._m18 == 0.0) ? 1.0 : _398._m18);
                _25931[_30086] = powr(_25931[_30086], 1.0);
                _25931[_30086] = fast::max(_25931[_30086], 6.099999882280826568603515625e-05);
            }
            float2 _19882 = (_19569 + _3271) + _30085.xy;
            float _19943 = _19882.x;
            bool _19944 = _19943 >= 0.0;
            bool _19950;
            if (_19944)
            {
                _19950 = _19943 <= 1.0;
            }
            else
            {
                _19950 = _19944;
            }
            bool _19962;
            if (_19950)
            {
                float _19953 = _19882.y;
                bool _19954 = _19953 >= 0.0;
                bool _19960;
                if (_19954)
                {
                    _19960 = _19953 <= 1.0;
                }
                else
                {
                    _19960 = _19954;
                }
                _19962 = _19960;
            }
            else
            {
                _19962 = _19950;
            }
            spvUnsafeArray<float, 5> _28161;
            if (_19962)
            {
                int2 _19894 = int2(floor(_19882 * _3270));
                for (int _30087 = 0; _30087 < 5; _30087++)
                {
                    int2 _19984 = _19894 + _955[_30087];
                    int2 _30535 = int2(max(0, min(_19984.x, (_398._m1.x - 1))), max(0, min(_19984.y, (_398._m1.y - 1))));
                    float4 _30188;
                    if (all(uint2(_30535) < uint2(int2(_477.get_width(), _477.get_height()))))
                    {
                        _30188 = _477.read(uint2(_30535), 0);
                    }
                    else
                    {
                        _30188 = float4(0.0);
                    }
                    _28161[_30087] = (_30188.x * _398._m10) * ((_398._m18 == 0.0) ? 1.0 : _398._m18);
                    _28161[_30087] = powr(_28161[_30087], 1.0);
                    _28161[_30087] = fast::max(_28161[_30087], 6.099999882280826568603515625e-05);
                }
            }
            float _30091;
            if (_19962)
            {
                float _20326 = fast::min(_25931[0], _25931[3]);
                float _20331 = fast::max(_25931[0], _25931[3]);
                float _20336 = fast::min(_25931[1], _25931[4]);
                float _20341 = fast::max(_25931[1], _25931[4]);
                float _20346 = fast::min(_20326, _25931[2]);
                float _20351 = fast::max(_20326, _25931[2]);
                float _20356 = fast::min(_20336, _20331);
                float _20361 = fast::max(_20336, _20331);
                float _20371 = fast::max(_20346, _20356);
                float _20376 = fast::min(_20351, _20341);
                float _20381 = fast::max(_20351, _20341);
                float _20391 = fast::max(_20371, _20376);
                float _20396 = fast::min(_20361, _20381);
                spvUnsafeArray<float, 5> _28144 = spvUnsafeArray<float, 5>({ fast::min(_20346, _20356), fast::min(_20371, _20376), fast::min(_20391, _20396), fast::max(_20391, _20396), fast::max(_20361, _20381) });
                spvUnsafeArray<float, 5> _25943 = _28144;
                float _20579 = fast::min(_28161[0], _28161[3]);
                float _20584 = fast::max(_28161[0], _28161[3]);
                float _20589 = fast::min(_28161[1], _28161[4]);
                float _20594 = fast::max(_28161[1], _28161[4]);
                float _20599 = fast::min(_20579, _28161[2]);
                float _20604 = fast::max(_20579, _28161[2]);
                float _20609 = fast::min(_20589, _20584);
                float _20614 = fast::max(_20589, _20584);
                float _20624 = fast::max(_20599, _20609);
                float _20629 = fast::min(_20604, _20594);
                float _20634 = fast::max(_20604, _20594);
                float _20644 = fast::max(_20624, _20629);
                float _20649 = fast::min(_20614, _20634);
                spvUnsafeArray<float, 5> _28160 = spvUnsafeArray<float, 5>({ fast::min(_20599, _20609), fast::min(_20624, _20629), fast::min(_20644, _20649), fast::max(_20644, _20649), fast::max(_20614, _20634) });
                spvUnsafeArray<float, 5> _25950 = _28160;
                float _30090;
                if (fast::min(_25943[4], _25950[4]) > 1.1754943508222875079687365372222e-38)
                {
                    float _30089;
                    _30089 = 65503.0;
                    float _30450;
                    int _30474;
                    int _30475;
                    for (int _30088 = 0, _30180 = 0, _30181 = 0; (_30088 < 5) && (_30089 < 65504.0); _30181 = _30475, _30180 = _30474, _30089 = _30450, _30088++)
                    {
                        float _20103 = _25943[_30180] - _25950[_30181];
                        if (abs(_20103) > 6.099999882280826568603515625e-05)
                        {
                            float _20692 = fast::max(_25943[_30180], _25950[_30181]);
                            float _30182;
                            if (_20692 != 0.0)
                            {
                                _30182 = fast::min(_25943[_30180], _25950[_30181]) / _20692;
                            }
                            else
                            {
                                _30182 = 0.0;
                            }
                            float _20118 = sign(_20103) * (1.0 - _30182);
                            int _20136 = _30180 + int(_25943[_30180] < _25950[_30181]);
                            _30475 = _30181 + int(_25943[_20136] >= _25950[_30181]);
                            _30474 = _20136;
                            _30450 = (abs(_20118) < abs(_30089)) ? _20118 : _30089;
                        }
                        else
                        {
                            _30475 = _30181;
                            _30474 = _30180;
                            _30450 = 65504.0;
                        }
                    }
                    _30090 = _30089;
                }
                else
                {
                    _30090 = 65503.0;
                }
                _30091 = _30090 * float(_30090 < 65503.0);
            }
            else
            {
                _30091 = 0.0;
            }
            float4 _29582 = float4(0.0);
            _29582.x = _30091;
            float _30098;
            if (_30091 != 0.0)
            {
                _30098 = sign(_30091);
            }
            else
            {
                _30098 = 0.0;
            }
            _29582.y = _30098;
            _29582.z = 1.0;
            int2 _20714 = int2(float2(int2(_2754 + uint2(1u))));
            int2 _30532 = int2(max(0, min(_20714.x, _3000)), max(0, min(_20714.y, _3008)));
            float4 _30100;
            if (all(uint2(_30532) < uint2(int2(_496.get_width(), _496.get_height()))))
            {
                _30100 = _496.read(uint2(_30532), 0);
            }
            else
            {
                _30100 = float4(0.0);
            }
            float2 _20725 = (float2(_30532) + float2(0.5)) / _2961;
            int2 _20873 = int2(floor((_20725 + _3103) * _2961));
            spvUnsafeArray<float, 5> _25779;
            for (int _30101 = 0; _30101 < 5; _30101++)
            {
                int2 _20937 = _20873 + _955[_30101];
                int2 _30534 = int2(max(0, min(_20937.x, _3000)), max(0, min(_20937.y, _3008)));
                float4 _30178;
                if (all(uint2(_30534) < uint2(int2(_456.get_width(), _456.get_height()))))
                {
                    _30178 = _456.read(uint2(_30534), 0);
                }
                else
                {
                    _30178 = float4(0.0);
                }
                _25779[_30101] = _30178.x * ((_398._m18 == 0.0) ? 1.0 : _398._m18);
                _25779[_30101] = powr(_25779[_30101], 1.0);
                _25779[_30101] = fast::max(_25779[_30101], 6.099999882280826568603515625e-05);
            }
            float2 _21038 = (_20725 + _3271) + _30100.xy;
            float _21099 = _21038.x;
            bool _21100 = _21099 >= 0.0;
            bool _21106;
            if (_21100)
            {
                _21106 = _21099 <= 1.0;
            }
            else
            {
                _21106 = _21100;
            }
            bool _21118;
            if (_21106)
            {
                float _21109 = _21038.y;
                bool _21110 = _21109 >= 0.0;
                bool _21116;
                if (_21110)
                {
                    _21116 = _21109 <= 1.0;
                }
                else
                {
                    _21116 = _21110;
                }
                _21118 = _21116;
            }
            else
            {
                _21118 = _21106;
            }
            spvUnsafeArray<float, 5> _28117;
            if (_21118)
            {
                int2 _21050 = int2(floor(_21038 * _3270));
                for (int _30102 = 0; _30102 < 5; _30102++)
                {
                    int2 _21140 = _21050 + _955[_30102];
                    int2 _30533 = int2(max(0, min(_21140.x, (_398._m1.x - 1))), max(0, min(_21140.y, (_398._m1.y - 1))));
                    float4 _30176;
                    if (all(uint2(_30533) < uint2(int2(_477.get_width(), _477.get_height()))))
                    {
                        _30176 = _477.read(uint2(_30533), 0);
                    }
                    else
                    {
                        _30176 = float4(0.0);
                    }
                    _28117[_30102] = (_30176.x * _398._m10) * ((_398._m18 == 0.0) ? 1.0 : _398._m18);
                    _28117[_30102] = powr(_28117[_30102], 1.0);
                    _28117[_30102] = fast::max(_28117[_30102], 6.099999882280826568603515625e-05);
                }
            }
            float _30106;
            if (_21118)
            {
                float _21482 = fast::min(_25779[0], _25779[3]);
                float _21487 = fast::max(_25779[0], _25779[3]);
                float _21492 = fast::min(_25779[1], _25779[4]);
                float _21497 = fast::max(_25779[1], _25779[4]);
                float _21502 = fast::min(_21482, _25779[2]);
                float _21507 = fast::max(_21482, _25779[2]);
                float _21512 = fast::min(_21492, _21487);
                float _21517 = fast::max(_21492, _21487);
                float _21527 = fast::max(_21502, _21512);
                float _21532 = fast::min(_21507, _21497);
                float _21537 = fast::max(_21507, _21497);
                float _21547 = fast::max(_21527, _21532);
                float _21552 = fast::min(_21517, _21537);
                spvUnsafeArray<float, 5> _28100 = spvUnsafeArray<float, 5>({ fast::min(_21502, _21512), fast::min(_21527, _21532), fast::min(_21547, _21552), fast::max(_21547, _21552), fast::max(_21517, _21537) });
                spvUnsafeArray<float, 5> _25791 = _28100;
                float _21735 = fast::min(_28117[0], _28117[3]);
                float _21740 = fast::max(_28117[0], _28117[3]);
                float _21745 = fast::min(_28117[1], _28117[4]);
                float _21750 = fast::max(_28117[1], _28117[4]);
                float _21755 = fast::min(_21735, _28117[2]);
                float _21760 = fast::max(_21735, _28117[2]);
                float _21765 = fast::min(_21745, _21740);
                float _21770 = fast::max(_21745, _21740);
                float _21780 = fast::max(_21755, _21765);
                float _21785 = fast::min(_21760, _21750);
                float _21790 = fast::max(_21760, _21750);
                float _21800 = fast::max(_21780, _21785);
                float _21805 = fast::min(_21770, _21790);
                spvUnsafeArray<float, 5> _28116 = spvUnsafeArray<float, 5>({ fast::min(_21755, _21765), fast::min(_21780, _21785), fast::min(_21800, _21805), fast::max(_21800, _21805), fast::max(_21770, _21790) });
                spvUnsafeArray<float, 5> _25798 = _28116;
                float _30105;
                if (fast::min(_25791[4], _25798[4]) > 1.1754943508222875079687365372222e-38)
                {
                    float _30104;
                    _30104 = 65503.0;
                    float _30453;
                    int _30472;
                    int _30473;
                    for (int _30103 = 0, _30168 = 0, _30169 = 0; (_30103 < 5) && (_30104 < 65504.0); _30169 = _30473, _30168 = _30472, _30104 = _30453, _30103++)
                    {
                        float _21259 = _25791[_30168] - _25798[_30169];
                        if (abs(_21259) > 6.099999882280826568603515625e-05)
                        {
                            float _21848 = fast::max(_25791[_30168], _25798[_30169]);
                            float _30170;
                            if (_21848 != 0.0)
                            {
                                _30170 = fast::min(_25791[_30168], _25798[_30169]) / _21848;
                            }
                            else
                            {
                                _30170 = 0.0;
                            }
                            float _21274 = sign(_21259) * (1.0 - _30170);
                            int _21292 = _30168 + int(_25791[_30168] < _25798[_30169]);
                            _30473 = _30169 + int(_25791[_21292] >= _25798[_30169]);
                            _30472 = _21292;
                            _30453 = (abs(_21274) < abs(_30104)) ? _21274 : _30104;
                        }
                        else
                        {
                            _30473 = _30169;
                            _30472 = _30168;
                            _30453 = 65504.0;
                        }
                    }
                    _30105 = _30104;
                }
                else
                {
                    _30105 = 65503.0;
                }
                _30106 = _30105 * float(_30105 < 65503.0);
            }
            else
            {
                _30106 = 0.0;
            }
            float4 _29618 = float4(0.0);
            _29618.x = _30106;
            float _30113;
            if (_30106 != 0.0)
            {
                _30113 = sign(_30106);
            }
            else
            {
                _30113 = 0.0;
            }
            _29618.y = _30113;
            _29618.z = 1.0;
            _2576[3] = (((_29510 + _29546) + _29582) + _29618) * 0.25;
            if (all(uint2(_2752) < uint2(int2(_524.get_width(), _524.get_height()))))
            {
                _524.write(float4(_2576[3].xy, 0.0, 0.0), uint2(_2752));
            }
            if (_398._m19.x <= 1u)
            {
                break;
            }
            for (uint _30159 = 0u; _30159 < 4u; _30159++)
            {
                _1182[_2449][_2455] = _2576[_30159].x;
                _1188[_2449][_2455] = _2576[_30159].y;
                _1193[_2449][_2455] = _2576[_30159].z;
                _1198[_2449][_2455] = _2576[_30159].w;
                threadgroup_barrier(mem_flags::mem_device | mem_flags::mem_threadgroup | mem_flags::mem_texture);
                if (gl_LocalInvocationIndex < 64u)
                {
                    uint _2792 = _2632 + 1u;
                    uint _2802 = _2635 + 1u;
                    _2576[_30159] = (((float4(_1182[_2632][_2635], _1188[_2632][_2635], _1193[_2632][_2635], _1198[_2632][_2635]) + float4(_1182[_2792][_2635], _1188[_2792][_2635], _1193[_2792][_2635], _1198[_2792][_2635])) + float4(_1182[_2632][_2802], _1188[_2632][_2802], _1193[_2632][_2802], _1198[_2632][_2802])) + float4(_1182[_2792][_2802], _1188[_2792][_2802], _1193[_2792][_2802], _1198[_2792][_2802])) * 0.25;
                    int2 _2830 = int2(gl_WorkGroupID.xy * uint2(16u)) + int2(int(_2449 + ((_30159 % 2u) * 8u)), int(_2455 + ((_30159 / 2u) * 8u)));
                    if (all(uint2(_2830) < uint2(int2(_544.get_width(), _544.get_height()))))
                    {
                        _544.write(float4(_2576[_30159].xy, 0.0, 0.0), uint2(_2830));
                    }
                }
                threadgroup_barrier(mem_flags::mem_device | mem_flags::mem_threadgroup | mem_flags::mem_texture);
            }
            if (gl_LocalInvocationIndex < 64u)
            {
                _1182[_2449][_2455] = _2576[0].x;
                _1188[_2449][_2455] = _2576[0].y;
                _1193[_2449][_2455] = _2576[0].z;
                _1198[_2449][_2455] = _2576[0].w;
                uint _2853 = _2449 + 8u;
                _1182[_2853][_2455] = _2576[1].x;
                _1188[_2853][_2455] = _2576[1].y;
                _1193[_2853][_2455] = _2576[1].z;
                _1198[_2853][_2455] = _2576[1].w;
                uint _2862 = _2455 + 8u;
                _1182[_2449][_2862] = _2576[2].x;
                _1188[_2449][_2862] = _2576[2].y;
                _1193[_2449][_2862] = _2576[2].z;
                _1198[_2449][_2862] = _2576[2].w;
                _1182[_2853][_2862] = _2576[3].x;
                _1188[_2853][_2862] = _2576[3].y;
                _1193[_2853][_2862] = _2576[3].z;
                _1198[_2853][_2862] = _2576[3].w;
            }
            break;
        } while(false);
        do
        {
            if (_398._m19.x <= 2u)
            {
                break;
            }
            threadgroup_barrier(mem_flags::mem_device | mem_flags::mem_threadgroup | mem_flags::mem_texture);
            if (gl_LocalInvocationIndex < 64u)
            {
                uint _22350 = _2632 + 1u;
                uint _22360 = _2635 + 1u;
                float _22442 = _1182[_2632][_2635];
                float _22446 = _1188[_2632][_2635];
                float _22450 = _1193[_2632][_2635];
                float _22461 = _1182[_22350][_2635];
                float _22465 = _1188[_22350][_2635];
                float _22469 = _1193[_22350][_2635];
                float _22480 = _1182[_2632][_22360];
                float _22484 = _1188[_2632][_22360];
                float _22488 = _1193[_2632][_22360];
                float _22499 = _1182[_22350][_22360];
                float _22503 = _1188[_22350][_22360];
                float _22507 = _1193[_22350][_22360];
                float4 _22522 = (((float4(_22442, _22446, _22450, _1198[_2632][_2635]) + float4(_22461, _22465, _22469, _1198[_22350][_2635])) + float4(_22480, _22484, _22488, _1198[_2632][_22360])) + float4(_22499, _22503, _22507, _1198[_22350][_22360])) * 0.25;
                int2 _22379 = int2(gl_WorkGroupID.xy * uint2(8u)) + _2647;
                if (all(uint2(_22379) < uint2(int2(_564.get_width(), _564.get_height()))))
                {
                    _564.write(float4(_22522.xy, 0.0, 0.0), uint2(_22379));
                }
                uint _22388 = _2632 + (_2455 % 2u);
                _1182[_22388][_2635] = _22522.x;
                _1188[_22388][_2635] = _22522.y;
                _1193[_22388][_2635] = _22522.z;
                _1198[_22388][_2635] = _22522.w;
            }
            if (_398._m19.x <= 3u)
            {
                break;
            }
            threadgroup_barrier(mem_flags::mem_device | mem_flags::mem_threadgroup | mem_flags::mem_texture);
            if (gl_LocalInvocationIndex < 16u)
            {
                uint _22633 = _2449 * 4u;
                uint _22637 = _2455 * 4u;
                uint _22642 = _22633 + 2u;
                uint _22651 = _22633 + 1u;
                uint _22654 = _22637 + 2u;
                uint _22659 = _22633 + 3u;
                float _22736 = _1182[_22633][_22637];
                float _22740 = _1188[_22633][_22637];
                float _22744 = _1193[_22633][_22637];
                float _22755 = _1182[_22642][_22637];
                float _22759 = _1188[_22642][_22637];
                float _22763 = _1193[_22642][_22637];
                float _22774 = _1182[_22651][_22654];
                float _22778 = _1188[_22651][_22654];
                float _22782 = _1193[_22651][_22654];
                float _22793 = _1182[_22659][_22654];
                float _22797 = _1188[_22659][_22654];
                float _22801 = _1193[_22659][_22654];
                float4 _22816 = (((float4(_22736, _22740, _22744, _1198[_22633][_22637]) + float4(_22755, _22759, _22763, _1198[_22642][_22637])) + float4(_22774, _22778, _22782, _1198[_22651][_22654])) + float4(_22793, _22797, _22801, _1198[_22659][_22654])) * 0.25;
                uint _22682 = _22633 + _2455;
                _1182[_22682][_22637] = _22816.x;
                _1188[_22682][_22637] = _22816.y;
                _1193[_22682][_22637] = _22816.z;
                _1198[_22682][_22637] = _22816.w;
            }
            if (_398._m19.x <= 4u)
            {
                break;
            }
            threadgroup_barrier(mem_flags::mem_device | mem_flags::mem_threadgroup | mem_flags::mem_texture);
            if (gl_LocalInvocationIndex < 4u)
            {
                uint _22927 = _2449 * 8u;
                uint _22932 = _22927 + _2635;
                uint _22934 = _2455 * 8u;
                uint _22943 = (_22927 + 4u) + _2635;
                uint _22954 = (_22927 + 1u) + _2635;
                uint _22957 = _22934 + 4u;
                uint _22965 = (_22927 + 5u) + _2635;
                float _23040 = _1182[_22932][_22934];
                float _23044 = _1188[_22932][_22934];
                float _23048 = _1193[_22932][_22934];
                float _23059 = _1182[_22943][_22934];
                float _23063 = _1188[_22943][_22934];
                float _23067 = _1193[_22943][_22934];
                float _23078 = _1182[_22954][_22957];
                float _23082 = _1188[_22954][_22957];
                float _23086 = _1193[_22954][_22957];
                float _23097 = _1182[_22965][_22957];
                float _23101 = _1188[_22965][_22957];
                float _23105 = _1193[_22965][_22957];
                float4 _23120 = (((float4(_23040, _23044, _23048, _1198[_22932][_22934]) + float4(_23059, _23063, _23067, _1198[_22943][_22934])) + float4(_23078, _23082, _23086, _1198[_22954][_22957])) + float4(_23097, _23101, _23105, _1198[_22965][_22957])) * 0.25;
                uint _22988 = _2449 + _2635;
                _1182[_22988][0u] = _23120.x;
                _1188[_22988][0u] = _23120.y;
                _1193[_22988][0u] = _23120.z;
                _1198[_22988][0u] = _23120.w;
            }
            if (_398._m19.x <= 5u)
            {
                break;
            }
            threadgroup_barrier(mem_flags::mem_device | mem_flags::mem_threadgroup | mem_flags::mem_texture);
            break;
        } while(false);
        if (_398._m19.x <= 6u)
        {
            break;
        }
        if (gl_LocalInvocationIndex == 0u)
        {
            _651 = 0u;
        }
        threadgroup_barrier(mem_flags::mem_device | mem_flags::mem_threadgroup | mem_flags::mem_texture);
        if (_651 != (_398._m19.y - 1u))
        {
            break;
        }
        uint _23544;
        uint _23574;
        do
        {
            _23544 = _2632 + 1u;
            _23574 = _2635 + 1u;
            if (_398._m19.x <= 7u)
            {
                break;
            }
            _1182[_2449][_2455] = 0.0;
            _1188[_2449][_2455] = 0.0;
            _1193[_2449][_2455] = 0.0;
            _1198[_2449][_2455] = 0.0;
            break;
        } while(false);
        do
        {
            if (_398._m19.x <= 8u)
            {
                break;
            }
            threadgroup_barrier(mem_flags::mem_device | mem_flags::mem_threadgroup | mem_flags::mem_texture);
            if (gl_LocalInvocationIndex < 64u)
            {
                float _24659 = _1182[_2632][_2635];
                float _24663 = _1188[_2632][_2635];
                float _24667 = _1193[_2632][_2635];
                float _24678 = _1182[_23544][_2635];
                float _24682 = _1188[_23544][_2635];
                float _24686 = _1193[_23544][_2635];
                float _24697 = _1182[_2632][_23574];
                float _24701 = _1188[_2632][_23574];
                float _24705 = _1193[_2632][_23574];
                float _24716 = _1182[_23544][_23574];
                float _24720 = _1188[_23544][_23574];
                float _24724 = _1193[_23544][_23574];
                float4 _24739 = (((float4(_24659, _24663, _24667, _1198[_2632][_2635]) + float4(_24678, _24682, _24686, _1198[_23544][_2635])) + float4(_24697, _24701, _24705, _1198[_2632][_23574])) + float4(_24716, _24720, _24724, _1198[_23544][_23574])) * 0.25;
                uint _24605 = _2632 + (_2455 % 2u);
                _1182[_24605][_2635] = _24739.x;
                _1188[_24605][_2635] = _24739.y;
                _1193[_24605][_2635] = _24739.z;
                _1198[_24605][_2635] = _24739.w;
            }
            if (_398._m19.x <= 9u)
            {
                break;
            }
            threadgroup_barrier(mem_flags::mem_device | mem_flags::mem_threadgroup | mem_flags::mem_texture);
            if (gl_LocalInvocationIndex < 16u)
            {
                uint _24850 = _2449 * 4u;
                uint _24854 = _2455 * 4u;
                uint _24859 = _24850 + 2u;
                uint _24868 = _24850 + 1u;
                uint _24871 = _24854 + 2u;
                uint _24876 = _24850 + 3u;
                float _24953 = _1182[_24850][_24854];
                float _24957 = _1188[_24850][_24854];
                float _24961 = _1193[_24850][_24854];
                float _24972 = _1182[_24859][_24854];
                float _24976 = _1188[_24859][_24854];
                float _24980 = _1193[_24859][_24854];
                float _24991 = _1182[_24868][_24871];
                float _24995 = _1188[_24868][_24871];
                float _24999 = _1193[_24868][_24871];
                float _25010 = _1182[_24876][_24871];
                float _25014 = _1188[_24876][_24871];
                float _25018 = _1193[_24876][_24871];
                float4 _25033 = (((float4(_24953, _24957, _24961, _1198[_24850][_24854]) + float4(_24972, _24976, _24980, _1198[_24859][_24854])) + float4(_24991, _24995, _24999, _1198[_24868][_24871])) + float4(_25010, _25014, _25018, _1198[_24876][_24871])) * 0.25;
                uint _24899 = _24850 + _2455;
                _1182[_24899][_24854] = _25033.x;
                _1188[_24899][_24854] = _25033.y;
                _1193[_24899][_24854] = _25033.z;
                _1198[_24899][_24854] = _25033.w;
            }
            if (_398._m19.x <= 10u)
            {
                break;
            }
            threadgroup_barrier(mem_flags::mem_device | mem_flags::mem_threadgroup | mem_flags::mem_texture);
            if (gl_LocalInvocationIndex < 4u)
            {
                uint _25144 = _2449 * 8u;
                uint _25149 = _25144 + _2635;
                uint _25151 = _2455 * 8u;
                uint _25160 = (_25144 + 4u) + _2635;
                uint _25171 = (_25144 + 1u) + _2635;
                uint _25174 = _25151 + 4u;
                uint _25182 = (_25144 + 5u) + _2635;
                float _25257 = _1182[_25149][_25151];
                float _25261 = _1188[_25149][_25151];
                float _25265 = _1193[_25149][_25151];
                float _25276 = _1182[_25160][_25151];
                float _25280 = _1188[_25160][_25151];
                float _25284 = _1193[_25160][_25151];
                float _25295 = _1182[_25171][_25174];
                float _25299 = _1188[_25171][_25174];
                float _25303 = _1193[_25171][_25174];
                float _25314 = _1182[_25182][_25174];
                float _25318 = _1188[_25182][_25174];
                float _25322 = _1193[_25182][_25174];
                float4 _25337 = (((float4(_25257, _25261, _25265, _1198[_25149][_25151]) + float4(_25276, _25280, _25284, _1198[_25160][_25151])) + float4(_25295, _25299, _25303, _1198[_25171][_25174])) + float4(_25314, _25318, _25322, _1198[_25182][_25174])) * 0.25;
                uint _25205 = _2449 + _2635;
                _1182[_25205][0u] = _25337.x;
                _1188[_25205][0u] = _25337.y;
                _1193[_25205][0u] = _25337.z;
                _1198[_25205][0u] = _25337.w;
            }
            if (_398._m19.x <= 11u)
            {
                break;
            }
            threadgroup_barrier(mem_flags::mem_device | mem_flags::mem_threadgroup | mem_flags::mem_texture);
            break;
        } while(false);
        break;
    } while(false);
}

