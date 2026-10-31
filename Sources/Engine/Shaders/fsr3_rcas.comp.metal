// Generated from fsr3_rcas.comp by Scripts/compile-shaders.sh — do not edit.
// Edit the GLSL and rerun the script (needs glslc and spirv-cross).
// spirv-fnv1a64: 9bb12bb62f414d8e
// glsl-fnv1a64: 8f43f2f9e47c8b85

#include <metal_stdlib>
#include <simd/simd.h>

using namespace metal;

struct _211
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

constant uint3 gl_WorkGroupSize [[maybe_unused]] = uint3(64u, 1u, 1u);

kernel void compute_main(constant _211& _213 [[buffer(16)]], texture2d<float> _239 [[texture(1)]], texture2d<float, access::write> _262 [[texture(8)]], uint3 gl_LocalInvocationID [[thread_position_in_threadgroup]], uint3 gl_WorkGroupID [[threadgroup_position_in_grid]])
{
    uint2 _864 = uint2(extract_bits(gl_LocalInvocationID.x, uint(1), uint(3)), insert_bits(extract_bits(gl_LocalInvocationID.x, uint(3), uint(3)), gl_LocalInvocationID.x, uint(0), uint(1))) + uint2(gl_WorkGroupID.x << 4u, gl_WorkGroupID.y << 4u);
    int2 _1076 = int2(_864);
    int2 _1078 = _1076 + int2(0, -1);
    float4 _4794;
    if (all(uint2(_1078) < uint2(int2(_239.get_width(), _239.get_height()))))
    {
        _4794 = _239.read(uint2(_1078), 0);
    }
    else
    {
        _4794 = float4(0.0);
    }
    float _1444 = (_213._m18 == 0.0) ? 1.0 : _213._m18;
    float3 _1411 = _4794.xyz * _1444;
    float _1413 = _1411.x;
    float _1415 = _1411.y;
    float _1417 = _1411.z;
    int2 _1082 = _1076 + int2(-1, 0);
    float4 _4795;
    if (all(uint2(_1082) < uint2(int2(_239.get_width(), _239.get_height()))))
    {
        _4795 = _239.read(uint2(_1082), 0);
    }
    else
    {
        _4795 = float4(0.0);
    }
    float3 _1454 = _4795.xyz * _1444;
    float _1456 = _1454.x;
    float _1458 = _1454.y;
    float _1460 = _1454.z;
    float4 _4796;
    if (all(_864 < uint2(int2(_239.get_width(), _239.get_height()))))
    {
        _4796 = _239.read(uint2(_1076), 0);
    }
    else
    {
        _4796 = float4(0.0);
    }
    float3 _1497 = _4796.xyz * _1444;
    float _1499 = _1497.x;
    float _1501 = _1497.y;
    float _1503 = _1497.z;
    int2 _1089 = _1076 + int2(1, 0);
    float4 _4797;
    if (all(uint2(_1089) < uint2(int2(_239.get_width(), _239.get_height()))))
    {
        _4797 = _239.read(uint2(_1089), 0);
    }
    else
    {
        _4797 = float4(0.0);
    }
    float3 _1540 = _4797.xyz * _1444;
    float _1542 = _1540.x;
    float _1544 = _1540.y;
    float _1546 = _1540.z;
    int2 _1093 = _1076 + int2(0, 1);
    float4 _4798;
    if (all(uint2(_1093) < uint2(int2(_239.get_width(), _239.get_height()))))
    {
        _4798 = _239.read(uint2(_1093), 0);
    }
    else
    {
        _4798 = float4(0.0);
    }
    float3 _1583 = _4798.xyz * _1444;
    float _1585 = _1583.x;
    float _1587 = _1583.y;
    float _1589 = _1583.z;
    float _1167 = (_1417 * 0.5) + ((_1413 * 0.5) + _1415);
    float _1174 = (_1460 * 0.5) + ((_1456 * 0.5) + _1458);
    float _1181 = (_1503 * 0.5) + ((_1499 * 0.5) + _1501);
    float _1188 = (_1546 * 0.5) + ((_1542 * 0.5) + _1544);
    float _1195 = (_1589 * 0.5) + ((_1585 * 0.5) + _1587);
    float _1225 = fast::max(fast::max(_1167, fast::max(_1174, _1181)), fast::max(_1188, _1195)) - fast::min(fast::min(_1167, fast::min(_1174, _1181)), fast::min(_1188, _1195));
    float _1673 = as_type<float>(2129764351u - as_type<uint>(_1225));
    float _1689 = fast::min(fast::min(_1413, fast::min(_1456, _1542)), _1585);
    float _1701 = fast::min(fast::min(_1415, fast::min(_1458, _1544)), _1587);
    float _1713 = fast::min(fast::min(_1417, fast::min(_1460, _1546)), _1589);
    float _1255 = fast::max(fast::max(_1413, fast::max(_1456, _1542)), _1585);
    float _1261 = fast::max(fast::max(_1415, fast::max(_1458, _1544)), _1587);
    float _1267 = fast::max(fast::max(_1417, fast::max(_1460, _1546)), _1589);
    float _1774 = as_type<float>(_213._m19.x);
    float _1340 = (fast::max(-0.1875, fast::min(fast::max(fast::max(-(_1689 * (0.25 / _1255)), (1.0 - _1255) * (1.0 / ((4.0 * _1689) + (-4.0)))), fast::max(fast::max(-(_1701 * (0.25 / _1261)), (1.0 - _1261) * (1.0 / ((4.0 * _1701) + (-4.0)))), fast::max(-(_1713 * (0.25 / _1267)), (1.0 - _1267) * (1.0 / ((4.0 * _1713) + (-4.0)))))), 0.0)) * _1774) * (((-0.5) * fast::clamp(abs((0.25 * (((_1167 + _1174) + _1188) + _1195)) - _1181) * (_1673 * (((-_1673) * _1225) + 2.0)), 0.0, 1.0)) + 1.0);
    float _1343 = (4.0 * _1340) + 1.0;
    float _1798 = as_type<float>(2129764351u - as_type<uint>(_1343));
    float _1790 = _1798 * (((-_1798) * _1343) + 2.0);
    float3 _946 = float3(_1444);
    if (all(_864 < uint2(int2(_262.get_width(), _262.get_height()))))
    {
        _262.write(float4(float3(((_1340 * (((_1413 + _1456) + _1585) + _1542)) + _1499) * _1790, ((_1340 * (((_1415 + _1458) + _1587) + _1544)) + _1501) * _1790, ((_1340 * (((_1417 + _1460) + _1589) + _1546)) + _1503) * _1790) / _946, 1.0), uint2(_1076));
    }
    uint _868 = _864.x;
    uint _869 = _868 + 8u;
    uint2 _4613 = _864;
    _4613.x = _869;
    int2 _1982 = int2(_4613);
    int2 _1984 = _1982 + int2(0, -1);
    float4 _4811;
    if (all(uint2(_1984) < uint2(int2(_239.get_width(), _239.get_height()))))
    {
        _4811 = _239.read(uint2(_1984), 0);
    }
    else
    {
        _4811 = float4(0.0);
    }
    float3 _2317 = _4811.xyz * _1444;
    float _2319 = _2317.x;
    float _2321 = _2317.y;
    float _2323 = _2317.z;
    int2 _1988 = _1982 + int2(-1, 0);
    float4 _4812;
    if (all(uint2(_1988) < uint2(int2(_239.get_width(), _239.get_height()))))
    {
        _4812 = _239.read(uint2(_1988), 0);
    }
    else
    {
        _4812 = float4(0.0);
    }
    float3 _2360 = _4812.xyz * _1444;
    float _2362 = _2360.x;
    float _2364 = _2360.y;
    float _2366 = _2360.z;
    float4 _4813;
    if (all(_4613 < uint2(int2(_239.get_width(), _239.get_height()))))
    {
        _4813 = _239.read(uint2(_1982), 0);
    }
    else
    {
        _4813 = float4(0.0);
    }
    float3 _2403 = _4813.xyz * _1444;
    float _2405 = _2403.x;
    float _2407 = _2403.y;
    float _2409 = _2403.z;
    int2 _1995 = _1982 + int2(1, 0);
    float4 _4814;
    if (all(uint2(_1995) < uint2(int2(_239.get_width(), _239.get_height()))))
    {
        _4814 = _239.read(uint2(_1995), 0);
    }
    else
    {
        _4814 = float4(0.0);
    }
    float3 _2446 = _4814.xyz * _1444;
    float _2448 = _2446.x;
    float _2450 = _2446.y;
    float _2452 = _2446.z;
    int2 _1999 = _1982 + int2(0, 1);
    float4 _4815;
    if (all(uint2(_1999) < uint2(int2(_239.get_width(), _239.get_height()))))
    {
        _4815 = _239.read(uint2(_1999), 0);
    }
    else
    {
        _4815 = float4(0.0);
    }
    float3 _2489 = _4815.xyz * _1444;
    float _2491 = _2489.x;
    float _2493 = _2489.y;
    float _2495 = _2489.z;
    float _2073 = (_2323 * 0.5) + ((_2319 * 0.5) + _2321);
    float _2080 = (_2366 * 0.5) + ((_2362 * 0.5) + _2364);
    float _2087 = (_2409 * 0.5) + ((_2405 * 0.5) + _2407);
    float _2094 = (_2452 * 0.5) + ((_2448 * 0.5) + _2450);
    float _2101 = (_2495 * 0.5) + ((_2491 * 0.5) + _2493);
    float _2131 = fast::max(fast::max(_2073, fast::max(_2080, _2087)), fast::max(_2094, _2101)) - fast::min(fast::min(_2073, fast::min(_2080, _2087)), fast::min(_2094, _2101));
    float _2579 = as_type<float>(2129764351u - as_type<uint>(_2131));
    float _2595 = fast::min(fast::min(_2319, fast::min(_2362, _2448)), _2491);
    float _2607 = fast::min(fast::min(_2321, fast::min(_2364, _2450)), _2493);
    float _2619 = fast::min(fast::min(_2323, fast::min(_2366, _2452)), _2495);
    float _2161 = fast::max(fast::max(_2319, fast::max(_2362, _2448)), _2491);
    float _2167 = fast::max(fast::max(_2321, fast::max(_2364, _2450)), _2493);
    float _2173 = fast::max(fast::max(_2323, fast::max(_2366, _2452)), _2495);
    float _2246 = (fast::max(-0.1875, fast::min(fast::max(fast::max(-(_2595 * (0.25 / _2161)), (1.0 - _2161) * (1.0 / ((4.0 * _2595) + (-4.0)))), fast::max(fast::max(-(_2607 * (0.25 / _2167)), (1.0 - _2167) * (1.0 / ((4.0 * _2607) + (-4.0)))), fast::max(-(_2619 * (0.25 / _2173)), (1.0 - _2173) * (1.0 / ((4.0 * _2619) + (-4.0)))))), 0.0)) * _1774) * (((-0.5) * fast::clamp(abs((0.25 * (((_2073 + _2080) + _2094) + _2101)) - _2087) * (_2579 * (((-_2579) * _2131) + 2.0)), 0.0, 1.0)) + 1.0);
    float _2249 = (4.0 * _2246) + 1.0;
    float _2704 = as_type<float>(2129764351u - as_type<uint>(_2249));
    float _2696 = _2704 * (((-_2704) * _2249) + 2.0);
    if (all(_4613 < uint2(int2(_262.get_width(), _262.get_height()))))
    {
        _262.write(float4(float3(((_2246 * (((_2319 + _2362) + _2491) + _2448)) + _2405) * _2696, ((_2246 * (((_2321 + _2364) + _2493) + _2450)) + _2407) * _2696, ((_2246 * (((_2323 + _2366) + _2495) + _2452)) + _2409) * _2696) / _946, 1.0), uint2(_1982));
    }
    uint2 _4916 = uint2(_869, _864.y + 8u);
    int2 _2888 = int2(_4916);
    int2 _2890 = _2888 + int2(0, -1);
    float4 _4833;
    if (all(uint2(_2890) < uint2(int2(_239.get_width(), _239.get_height()))))
    {
        _4833 = _239.read(uint2(_2890), 0);
    }
    else
    {
        _4833 = float4(0.0);
    }
    float3 _3223 = _4833.xyz * _1444;
    float _3225 = _3223.x;
    float _3227 = _3223.y;
    float _3229 = _3223.z;
    int2 _2894 = _2888 + int2(-1, 0);
    float4 _4834;
    if (all(uint2(_2894) < uint2(int2(_239.get_width(), _239.get_height()))))
    {
        _4834 = _239.read(uint2(_2894), 0);
    }
    else
    {
        _4834 = float4(0.0);
    }
    float3 _3266 = _4834.xyz * _1444;
    float _3268 = _3266.x;
    float _3270 = _3266.y;
    float _3272 = _3266.z;
    float4 _4835;
    if (all(_4916 < uint2(int2(_239.get_width(), _239.get_height()))))
    {
        _4835 = _239.read(uint2(_2888), 0);
    }
    else
    {
        _4835 = float4(0.0);
    }
    float3 _3309 = _4835.xyz * _1444;
    float _3311 = _3309.x;
    float _3313 = _3309.y;
    float _3315 = _3309.z;
    int2 _2901 = _2888 + int2(1, 0);
    float4 _4836;
    if (all(uint2(_2901) < uint2(int2(_239.get_width(), _239.get_height()))))
    {
        _4836 = _239.read(uint2(_2901), 0);
    }
    else
    {
        _4836 = float4(0.0);
    }
    float3 _3352 = _4836.xyz * _1444;
    float _3354 = _3352.x;
    float _3356 = _3352.y;
    float _3358 = _3352.z;
    int2 _2905 = _2888 + int2(0, 1);
    float4 _4837;
    if (all(uint2(_2905) < uint2(int2(_239.get_width(), _239.get_height()))))
    {
        _4837 = _239.read(uint2(_2905), 0);
    }
    else
    {
        _4837 = float4(0.0);
    }
    float3 _3395 = _4837.xyz * _1444;
    float _3397 = _3395.x;
    float _3399 = _3395.y;
    float _3401 = _3395.z;
    float _2979 = (_3229 * 0.5) + ((_3225 * 0.5) + _3227);
    float _2986 = (_3272 * 0.5) + ((_3268 * 0.5) + _3270);
    float _2993 = (_3315 * 0.5) + ((_3311 * 0.5) + _3313);
    float _3000 = (_3358 * 0.5) + ((_3354 * 0.5) + _3356);
    float _3007 = (_3401 * 0.5) + ((_3397 * 0.5) + _3399);
    float _3037 = fast::max(fast::max(_2979, fast::max(_2986, _2993)), fast::max(_3000, _3007)) - fast::min(fast::min(_2979, fast::min(_2986, _2993)), fast::min(_3000, _3007));
    float _3485 = as_type<float>(2129764351u - as_type<uint>(_3037));
    float _3501 = fast::min(fast::min(_3225, fast::min(_3268, _3354)), _3397);
    float _3513 = fast::min(fast::min(_3227, fast::min(_3270, _3356)), _3399);
    float _3525 = fast::min(fast::min(_3229, fast::min(_3272, _3358)), _3401);
    float _3067 = fast::max(fast::max(_3225, fast::max(_3268, _3354)), _3397);
    float _3073 = fast::max(fast::max(_3227, fast::max(_3270, _3356)), _3399);
    float _3079 = fast::max(fast::max(_3229, fast::max(_3272, _3358)), _3401);
    float _3152 = (fast::max(-0.1875, fast::min(fast::max(fast::max(-(_3501 * (0.25 / _3067)), (1.0 - _3067) * (1.0 / ((4.0 * _3501) + (-4.0)))), fast::max(fast::max(-(_3513 * (0.25 / _3073)), (1.0 - _3073) * (1.0 / ((4.0 * _3513) + (-4.0)))), fast::max(-(_3525 * (0.25 / _3079)), (1.0 - _3079) * (1.0 / ((4.0 * _3525) + (-4.0)))))), 0.0)) * _1774) * (((-0.5) * fast::clamp(abs((0.25 * (((_2979 + _2986) + _3000) + _3007)) - _2993) * (_3485 * (((-_3485) * _3037) + 2.0)), 0.0, 1.0)) + 1.0);
    float _3155 = (4.0 * _3152) + 1.0;
    float _3610 = as_type<float>(2129764351u - as_type<uint>(_3155));
    float _3602 = _3610 * (((-_3610) * _3155) + 2.0);
    if (all(_4916 < uint2(int2(_262.get_width(), _262.get_height()))))
    {
        _262.write(float4(float3(((_3152 * (((_3225 + _3268) + _3397) + _3354)) + _3311) * _3602, ((_3152 * (((_3227 + _3270) + _3399) + _3356)) + _3313) * _3602, ((_3152 * (((_3229 + _3272) + _3401) + _3358)) + _3315) * _3602) / _946, 1.0), uint2(_2888));
    }
    _4916.x = _868;
    int2 _3794 = int2(_4916);
    int2 _3796 = _3794 + int2(0, -1);
    float4 _4861;
    if (all(uint2(_3796) < uint2(int2(_239.get_width(), _239.get_height()))))
    {
        _4861 = _239.read(uint2(_3796), 0);
    }
    else
    {
        _4861 = float4(0.0);
    }
    float3 _4129 = _4861.xyz * _1444;
    float _4131 = _4129.x;
    float _4133 = _4129.y;
    float _4135 = _4129.z;
    int2 _3800 = _3794 + int2(-1, 0);
    float4 _4862;
    if (all(uint2(_3800) < uint2(int2(_239.get_width(), _239.get_height()))))
    {
        _4862 = _239.read(uint2(_3800), 0);
    }
    else
    {
        _4862 = float4(0.0);
    }
    float3 _4172 = _4862.xyz * _1444;
    float _4174 = _4172.x;
    float _4176 = _4172.y;
    float _4178 = _4172.z;
    float4 _4863;
    if (all(_4916 < uint2(int2(_239.get_width(), _239.get_height()))))
    {
        _4863 = _239.read(uint2(_3794), 0);
    }
    else
    {
        _4863 = float4(0.0);
    }
    float3 _4215 = _4863.xyz * _1444;
    float _4217 = _4215.x;
    float _4219 = _4215.y;
    float _4221 = _4215.z;
    int2 _3807 = _3794 + int2(1, 0);
    float4 _4864;
    if (all(uint2(_3807) < uint2(int2(_239.get_width(), _239.get_height()))))
    {
        _4864 = _239.read(uint2(_3807), 0);
    }
    else
    {
        _4864 = float4(0.0);
    }
    float3 _4258 = _4864.xyz * _1444;
    float _4260 = _4258.x;
    float _4262 = _4258.y;
    float _4264 = _4258.z;
    int2 _3811 = _3794 + int2(0, 1);
    float4 _4865;
    if (all(uint2(_3811) < uint2(int2(_239.get_width(), _239.get_height()))))
    {
        _4865 = _239.read(uint2(_3811), 0);
    }
    else
    {
        _4865 = float4(0.0);
    }
    float3 _4301 = _4865.xyz * _1444;
    float _4303 = _4301.x;
    float _4305 = _4301.y;
    float _4307 = _4301.z;
    float _3885 = (_4135 * 0.5) + ((_4131 * 0.5) + _4133);
    float _3892 = (_4178 * 0.5) + ((_4174 * 0.5) + _4176);
    float _3899 = (_4221 * 0.5) + ((_4217 * 0.5) + _4219);
    float _3906 = (_4264 * 0.5) + ((_4260 * 0.5) + _4262);
    float _3913 = (_4307 * 0.5) + ((_4303 * 0.5) + _4305);
    float _3943 = fast::max(fast::max(_3885, fast::max(_3892, _3899)), fast::max(_3906, _3913)) - fast::min(fast::min(_3885, fast::min(_3892, _3899)), fast::min(_3906, _3913));
    float _4391 = as_type<float>(2129764351u - as_type<uint>(_3943));
    float _4407 = fast::min(fast::min(_4131, fast::min(_4174, _4260)), _4303);
    float _4419 = fast::min(fast::min(_4133, fast::min(_4176, _4262)), _4305);
    float _4431 = fast::min(fast::min(_4135, fast::min(_4178, _4264)), _4307);
    float _3973 = fast::max(fast::max(_4131, fast::max(_4174, _4260)), _4303);
    float _3979 = fast::max(fast::max(_4133, fast::max(_4176, _4262)), _4305);
    float _3985 = fast::max(fast::max(_4135, fast::max(_4178, _4264)), _4307);
    float _4058 = (fast::max(-0.1875, fast::min(fast::max(fast::max(-(_4407 * (0.25 / _3973)), (1.0 - _3973) * (1.0 / ((4.0 * _4407) + (-4.0)))), fast::max(fast::max(-(_4419 * (0.25 / _3979)), (1.0 - _3979) * (1.0 / ((4.0 * _4419) + (-4.0)))), fast::max(-(_4431 * (0.25 / _3985)), (1.0 - _3985) * (1.0 / ((4.0 * _4431) + (-4.0)))))), 0.0)) * _1774) * (((-0.5) * fast::clamp(abs((0.25 * (((_3885 + _3892) + _3906) + _3913)) - _3899) * (_4391 * (((-_4391) * _3943) + 2.0)), 0.0, 1.0)) + 1.0);
    float _4061 = (4.0 * _4058) + 1.0;
    float _4516 = as_type<float>(2129764351u - as_type<uint>(_4061));
    float _4508 = _4516 * (((-_4516) * _4061) + 2.0);
    if (all(_4916 < uint2(int2(_262.get_width(), _262.get_height()))))
    {
        _262.write(float4(float3(((_4058 * (((_4131 + _4174) + _4303) + _4260)) + _4217) * _4508, ((_4058 * (((_4133 + _4176) + _4305) + _4262)) + _4219) * _4508, ((_4058 * (((_4135 + _4178) + _4307) + _4264)) + _4221) * _4508) / _946, 1.0), uint2(_3794));
    }
}

