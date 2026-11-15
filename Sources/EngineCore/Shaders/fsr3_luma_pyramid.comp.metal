// Generated from fsr3_luma_pyramid.comp by Scripts/compile-shaders.sh — do not edit.
// Edit the GLSL and rerun the script (needs glslc and spirv-cross).
// spirv-fnv1a64: 5580087f5b2989dc
// glsl-fnv1a64: ec70f5918fe39a9f

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

struct _351
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

kernel void compute_main(constant _351& _353 [[buffer(16)]], texture2d<float> _417 [[texture(1)]], texture2d<float> _380 [[texture(2)]], texture2d<float, access::write> _403 [[texture(8)]], uint3 gl_WorkGroupID [[threadgroup_position_in_grid]], uint gl_LocalInvocationIndex [[thread_index_in_threadgroup]])
{
    threadgroup uint _494;
    threadgroup spvUnsafeArray<spvUnsafeArray<float, 16>, 16> _637;
    threadgroup spvUnsafeArray<spvUnsafeArray<float, 16>, 16> _643;
    threadgroup spvUnsafeArray<spvUnsafeArray<float, 16>, 16> _648;
    threadgroup spvUnsafeArray<spvUnsafeArray<float, 16>, 16> _653;
    do
    {
        uint _2091;
        uint _2094;
        uint _1900 = gl_LocalInvocationIndex % 64u;
        uint _1908 = insert_bits(extract_bits(_1900, uint(2), uint(3)), _1900, uint(0), uint(1)) + (8u * ((gl_LocalInvocationIndex >> uint(6)) % 2u));
        uint _1914 = insert_bits(extract_bits(_1900, uint(3), uint(3)), extract_bits(_1900, uint(1), uint(2)), uint(0), uint(2)) + (8u * (gl_LocalInvocationIndex >> uint(7)));
        do
        {
            int2 _2089 = int2(gl_WorkGroupID.xy * uint2(64u));
            _2091 = _1908 * 2u;
            int _2092 = int(_2091);
            _2094 = _1914 * 2u;
            int _2095 = int(_2094);
            int2 _2097 = _2089 + int2(_2092, _2095);
            int2 _2101 = int2(gl_WorkGroupID.xy * uint2(32u));
            int _2103 = int(_1908);
            int _2105 = int(_1914);
            int2 _2107 = _2101 + int2(_2103, _2105);
            uint2 _2109 = uint2(_2097);
            int2 _2409 = int2(float2(_2097));
            int _2446 = _353._m0.x - 1;
            int _2454 = _353._m0.y - 1;
            int2 _10129 = int2(max(0, min(_2409.x, _2446)), max(0, min(_2409.y, _2454)));
            uint2 _2485 = uint2(_10129);
            float4 _10049;
            if (all(_2485 < uint2(int2(_417.get_width(), _417.get_height()))))
            {
                _10049 = _417.read(uint2(_10129), 0);
            }
            else
            {
                _10049 = float4(0.0);
            }
            float4 _10050;
            if (all(_2485 < uint2(int2(_380.get_width(), _380.get_height()))))
            {
                _10050 = _380.read(uint2(_10129), 0);
            }
            else
            {
                _10050 = float4(0.0);
            }
            float4 _9666 = float4(0.0);
            _9666.x = fast::max(6.099999882280826568603515625e-05, log(_10049.x));
            _9666.y = _10049.x;
            _9666.z = _10050.x;
            int2 _2537 = int2(float2(int2(_2109 + uint2(0u, 1u))));
            int2 _10130 = int2(max(0, min(_2537.x, _2446)), max(0, min(_2537.y, _2454)));
            uint2 _2613 = uint2(_10130);
            float4 _10051;
            if (all(_2613 < uint2(int2(_417.get_width(), _417.get_height()))))
            {
                _10051 = _417.read(uint2(_10130), 0);
            }
            else
            {
                _10051 = float4(0.0);
            }
            float4 _10052;
            if (all(_2613 < uint2(int2(_380.get_width(), _380.get_height()))))
            {
                _10052 = _380.read(uint2(_10130), 0);
            }
            else
            {
                _10052 = float4(0.0);
            }
            float4 _9682 = float4(0.0);
            _9682.x = fast::max(6.099999882280826568603515625e-05, log(_10051.x));
            _9682.y = _10051.x;
            _9682.z = _10052.x;
            int2 _2665 = int2(float2(int2(_2109 + uint2(1u, 0u))));
            int2 _10131 = int2(max(0, min(_2665.x, _2446)), max(0, min(_2665.y, _2454)));
            uint2 _2741 = uint2(_10131);
            float4 _10053;
            if (all(_2741 < uint2(int2(_417.get_width(), _417.get_height()))))
            {
                _10053 = _417.read(uint2(_10131), 0);
            }
            else
            {
                _10053 = float4(0.0);
            }
            float4 _10054;
            if (all(_2741 < uint2(int2(_380.get_width(), _380.get_height()))))
            {
                _10054 = _380.read(uint2(_10131), 0);
            }
            else
            {
                _10054 = float4(0.0);
            }
            float4 _9698 = float4(0.0);
            _9698.x = fast::max(6.099999882280826568603515625e-05, log(_10053.x));
            _9698.y = _10053.x;
            _9698.z = _10054.x;
            int2 _2793 = int2(float2(int2(_2109 + uint2(1u))));
            int2 _10132 = int2(max(0, min(_2793.x, _2446)), max(0, min(_2793.y, _2454)));
            uint2 _2869 = uint2(_10132);
            float4 _10055;
            if (all(_2869 < uint2(int2(_417.get_width(), _417.get_height()))))
            {
                _10055 = _417.read(uint2(_10132), 0);
            }
            else
            {
                _10055 = float4(0.0);
            }
            float4 _10056;
            if (all(_2869 < uint2(int2(_380.get_width(), _380.get_height()))))
            {
                _10056 = _380.read(uint2(_10132), 0);
            }
            else
            {
                _10056 = float4(0.0);
            }
            float4 _9714 = float4(0.0);
            _9714.x = fast::max(6.099999882280826568603515625e-05, log(_10055.x));
            _9714.y = _10055.x;
            _9714.z = _10056.x;
            spvUnsafeArray<float4, 4> _2035;
            _2035[0] = (((_9666 + _9682) + _9698) + _9714) * 0.25;
            if (all(uint2(_2107) < uint2(int2(_403.get_width(), _403.get_height()))))
            {
                _403.write(float4(_2035[0].z, 0.0, 0.0, 0.0), uint2(_2107));
            }
            int _2125 = int(_2091 + 32u);
            int2 _2130 = _2089 + int2(_2125, _2095);
            int _2137 = int(_1908 + 16u);
            int2 _2141 = _2101 + int2(_2137, _2105);
            uint2 _2143 = uint2(_2130);
            int2 _3117 = int2(float2(_2130));
            int2 _10133 = int2(max(0, min(_3117.x, _2446)), max(0, min(_3117.y, _2454)));
            uint2 _3193 = uint2(_10133);
            float4 _10065;
            if (all(_3193 < uint2(int2(_417.get_width(), _417.get_height()))))
            {
                _10065 = _417.read(uint2(_10133), 0);
            }
            else
            {
                _10065 = float4(0.0);
            }
            float4 _10066;
            if (all(_3193 < uint2(int2(_380.get_width(), _380.get_height()))))
            {
                _10066 = _380.read(uint2(_10133), 0);
            }
            else
            {
                _10066 = float4(0.0);
            }
            float4 _9731 = float4(0.0);
            _9731.x = fast::max(6.099999882280826568603515625e-05, log(_10065.x));
            _9731.y = _10065.x;
            _9731.z = _10066.x;
            int2 _3245 = int2(float2(int2(_2143 + uint2(0u, 1u))));
            int2 _10134 = int2(max(0, min(_3245.x, _2446)), max(0, min(_3245.y, _2454)));
            uint2 _3321 = uint2(_10134);
            float4 _10067;
            if (all(_3321 < uint2(int2(_417.get_width(), _417.get_height()))))
            {
                _10067 = _417.read(uint2(_10134), 0);
            }
            else
            {
                _10067 = float4(0.0);
            }
            float4 _10068;
            if (all(_3321 < uint2(int2(_380.get_width(), _380.get_height()))))
            {
                _10068 = _380.read(uint2(_10134), 0);
            }
            else
            {
                _10068 = float4(0.0);
            }
            float4 _9747 = float4(0.0);
            _9747.x = fast::max(6.099999882280826568603515625e-05, log(_10067.x));
            _9747.y = _10067.x;
            _9747.z = _10068.x;
            int2 _3373 = int2(float2(int2(_2143 + uint2(1u, 0u))));
            int2 _10135 = int2(max(0, min(_3373.x, _2446)), max(0, min(_3373.y, _2454)));
            uint2 _3449 = uint2(_10135);
            float4 _10069;
            if (all(_3449 < uint2(int2(_417.get_width(), _417.get_height()))))
            {
                _10069 = _417.read(uint2(_10135), 0);
            }
            else
            {
                _10069 = float4(0.0);
            }
            float4 _10070;
            if (all(_3449 < uint2(int2(_380.get_width(), _380.get_height()))))
            {
                _10070 = _380.read(uint2(_10135), 0);
            }
            else
            {
                _10070 = float4(0.0);
            }
            float4 _9763 = float4(0.0);
            _9763.x = fast::max(6.099999882280826568603515625e-05, log(_10069.x));
            _9763.y = _10069.x;
            _9763.z = _10070.x;
            int2 _3501 = int2(float2(int2(_2143 + uint2(1u))));
            int2 _10136 = int2(max(0, min(_3501.x, _2446)), max(0, min(_3501.y, _2454)));
            uint2 _3577 = uint2(_10136);
            float4 _10071;
            if (all(_3577 < uint2(int2(_417.get_width(), _417.get_height()))))
            {
                _10071 = _417.read(uint2(_10136), 0);
            }
            else
            {
                _10071 = float4(0.0);
            }
            float4 _10072;
            if (all(_3577 < uint2(int2(_380.get_width(), _380.get_height()))))
            {
                _10072 = _380.read(uint2(_10136), 0);
            }
            else
            {
                _10072 = float4(0.0);
            }
            float4 _9779 = float4(0.0);
            _9779.x = fast::max(6.099999882280826568603515625e-05, log(_10071.x));
            _9779.y = _10071.x;
            _9779.z = _10072.x;
            _2035[1] = (((_9731 + _9747) + _9763) + _9779) * 0.25;
            if (all(uint2(_2141) < uint2(int2(_403.get_width(), _403.get_height()))))
            {
                _403.write(float4(_2035[1].z, 0.0, 0.0, 0.0), uint2(_2141));
            }
            int _2162 = int(_2094 + 32u);
            int2 _2164 = _2089 + int2(_2092, _2162);
            int _2173 = int(_1914 + 16u);
            int2 _2175 = _2101 + int2(_2103, _2173);
            uint2 _2177 = uint2(_2164);
            int2 _3825 = int2(float2(_2164));
            int2 _10137 = int2(max(0, min(_3825.x, _2446)), max(0, min(_3825.y, _2454)));
            uint2 _3901 = uint2(_10137);
            float4 _10081;
            if (all(_3901 < uint2(int2(_417.get_width(), _417.get_height()))))
            {
                _10081 = _417.read(uint2(_10137), 0);
            }
            else
            {
                _10081 = float4(0.0);
            }
            float4 _10082;
            if (all(_3901 < uint2(int2(_380.get_width(), _380.get_height()))))
            {
                _10082 = _380.read(uint2(_10137), 0);
            }
            else
            {
                _10082 = float4(0.0);
            }
            float4 _9796 = float4(0.0);
            _9796.x = fast::max(6.099999882280826568603515625e-05, log(_10081.x));
            _9796.y = _10081.x;
            _9796.z = _10082.x;
            int2 _3953 = int2(float2(int2(_2177 + uint2(0u, 1u))));
            int2 _10138 = int2(max(0, min(_3953.x, _2446)), max(0, min(_3953.y, _2454)));
            uint2 _4029 = uint2(_10138);
            float4 _10083;
            if (all(_4029 < uint2(int2(_417.get_width(), _417.get_height()))))
            {
                _10083 = _417.read(uint2(_10138), 0);
            }
            else
            {
                _10083 = float4(0.0);
            }
            float4 _10084;
            if (all(_4029 < uint2(int2(_380.get_width(), _380.get_height()))))
            {
                _10084 = _380.read(uint2(_10138), 0);
            }
            else
            {
                _10084 = float4(0.0);
            }
            float4 _9812 = float4(0.0);
            _9812.x = fast::max(6.099999882280826568603515625e-05, log(_10083.x));
            _9812.y = _10083.x;
            _9812.z = _10084.x;
            int2 _4081 = int2(float2(int2(_2177 + uint2(1u, 0u))));
            int2 _10139 = int2(max(0, min(_4081.x, _2446)), max(0, min(_4081.y, _2454)));
            uint2 _4157 = uint2(_10139);
            float4 _10085;
            if (all(_4157 < uint2(int2(_417.get_width(), _417.get_height()))))
            {
                _10085 = _417.read(uint2(_10139), 0);
            }
            else
            {
                _10085 = float4(0.0);
            }
            float4 _10086;
            if (all(_4157 < uint2(int2(_380.get_width(), _380.get_height()))))
            {
                _10086 = _380.read(uint2(_10139), 0);
            }
            else
            {
                _10086 = float4(0.0);
            }
            float4 _9828 = float4(0.0);
            _9828.x = fast::max(6.099999882280826568603515625e-05, log(_10085.x));
            _9828.y = _10085.x;
            _9828.z = _10086.x;
            int2 _4209 = int2(float2(int2(_2177 + uint2(1u))));
            int2 _10140 = int2(max(0, min(_4209.x, _2446)), max(0, min(_4209.y, _2454)));
            uint2 _4285 = uint2(_10140);
            float4 _10087;
            if (all(_4285 < uint2(int2(_417.get_width(), _417.get_height()))))
            {
                _10087 = _417.read(uint2(_10140), 0);
            }
            else
            {
                _10087 = float4(0.0);
            }
            float4 _10088;
            if (all(_4285 < uint2(int2(_380.get_width(), _380.get_height()))))
            {
                _10088 = _380.read(uint2(_10140), 0);
            }
            else
            {
                _10088 = float4(0.0);
            }
            float4 _9844 = float4(0.0);
            _9844.x = fast::max(6.099999882280826568603515625e-05, log(_10087.x));
            _9844.y = _10087.x;
            _9844.z = _10088.x;
            _2035[2] = (((_9796 + _9812) + _9828) + _9844) * 0.25;
            if (all(uint2(_2175) < uint2(int2(_403.get_width(), _403.get_height()))))
            {
                _403.write(float4(_2035[2].z, 0.0, 0.0, 0.0), uint2(_2175));
            }
            int2 _2199 = _2089 + int2(_2125, _2162);
            int2 _2211 = _2101 + int2(_2137, _2173);
            uint2 _2213 = uint2(_2199);
            int2 _4533 = int2(float2(_2199));
            int2 _10141 = int2(max(0, min(_4533.x, _2446)), max(0, min(_4533.y, _2454)));
            uint2 _4609 = uint2(_10141);
            float4 _10097;
            if (all(_4609 < uint2(int2(_417.get_width(), _417.get_height()))))
            {
                _10097 = _417.read(uint2(_10141), 0);
            }
            else
            {
                _10097 = float4(0.0);
            }
            float4 _10098;
            if (all(_4609 < uint2(int2(_380.get_width(), _380.get_height()))))
            {
                _10098 = _380.read(uint2(_10141), 0);
            }
            else
            {
                _10098 = float4(0.0);
            }
            float4 _9861 = float4(0.0);
            _9861.x = fast::max(6.099999882280826568603515625e-05, log(_10097.x));
            _9861.y = _10097.x;
            _9861.z = _10098.x;
            int2 _4661 = int2(float2(int2(_2213 + uint2(0u, 1u))));
            int2 _10142 = int2(max(0, min(_4661.x, _2446)), max(0, min(_4661.y, _2454)));
            uint2 _4737 = uint2(_10142);
            float4 _10099;
            if (all(_4737 < uint2(int2(_417.get_width(), _417.get_height()))))
            {
                _10099 = _417.read(uint2(_10142), 0);
            }
            else
            {
                _10099 = float4(0.0);
            }
            float4 _10100;
            if (all(_4737 < uint2(int2(_380.get_width(), _380.get_height()))))
            {
                _10100 = _380.read(uint2(_10142), 0);
            }
            else
            {
                _10100 = float4(0.0);
            }
            float4 _9877 = float4(0.0);
            _9877.x = fast::max(6.099999882280826568603515625e-05, log(_10099.x));
            _9877.y = _10099.x;
            _9877.z = _10100.x;
            int2 _4789 = int2(float2(int2(_2213 + uint2(1u, 0u))));
            int2 _10143 = int2(max(0, min(_4789.x, _2446)), max(0, min(_4789.y, _2454)));
            uint2 _4865 = uint2(_10143);
            float4 _10101;
            if (all(_4865 < uint2(int2(_417.get_width(), _417.get_height()))))
            {
                _10101 = _417.read(uint2(_10143), 0);
            }
            else
            {
                _10101 = float4(0.0);
            }
            float4 _10102;
            if (all(_4865 < uint2(int2(_380.get_width(), _380.get_height()))))
            {
                _10102 = _380.read(uint2(_10143), 0);
            }
            else
            {
                _10102 = float4(0.0);
            }
            float4 _9893 = float4(0.0);
            _9893.x = fast::max(6.099999882280826568603515625e-05, log(_10101.x));
            _9893.y = _10101.x;
            _9893.z = _10102.x;
            int2 _4917 = int2(float2(int2(_2213 + uint2(1u))));
            int2 _10144 = int2(max(0, min(_4917.x, _2446)), max(0, min(_4917.y, _2454)));
            uint2 _4993 = uint2(_10144);
            float4 _10103;
            if (all(_4993 < uint2(int2(_417.get_width(), _417.get_height()))))
            {
                _10103 = _417.read(uint2(_10144), 0);
            }
            else
            {
                _10103 = float4(0.0);
            }
            float4 _10104;
            if (all(_4993 < uint2(int2(_380.get_width(), _380.get_height()))))
            {
                _10104 = _380.read(uint2(_10144), 0);
            }
            else
            {
                _10104 = float4(0.0);
            }
            float4 _9909 = float4(0.0);
            _9909.x = fast::max(6.099999882280826568603515625e-05, log(_10103.x));
            _9909.y = _10103.x;
            _9909.z = _10104.x;
            _2035[3] = (((_9861 + _9877) + _9893) + _9909) * 0.25;
            if (all(uint2(_2211) < uint2(int2(_403.get_width(), _403.get_height()))))
            {
                _403.write(float4(_2035[3].z, 0.0, 0.0, 0.0), uint2(_2211));
            }
            if (_353._m19.x <= 1u)
            {
                break;
            }
            for (uint _10113 = 0u; _10113 < 4u; _10113++)
            {
                _637[_1908][_1914] = _2035[_10113].x;
                _643[_1908][_1914] = _2035[_10113].y;
                _648[_1908][_1914] = _2035[_10113].z;
                _653[_1908][_1914] = _2035[_10113].w;
                threadgroup_barrier(mem_flags::mem_device | mem_flags::mem_threadgroup | mem_flags::mem_texture);
                if (gl_LocalInvocationIndex < 64u)
                {
                    uint _2251 = _2091 + 1u;
                    uint _2261 = _2094 + 1u;
                    _2035[_10113] = (((float4(_637[_2091][_2094], _643[_2091][_2094], _648[_2091][_2094], _653[_2091][_2094]) + float4(_637[_2251][_2094], _643[_2251][_2094], _648[_2251][_2094], _653[_2251][_2094])) + float4(_637[_2091][_2261], _643[_2091][_2261], _648[_2091][_2261], _653[_2091][_2261])) + float4(_637[_2251][_2261], _643[_2251][_2261], _648[_2251][_2261], _653[_2251][_2261])) * 0.25;
                }
                threadgroup_barrier(mem_flags::mem_device | mem_flags::mem_threadgroup | mem_flags::mem_texture);
            }
            if (gl_LocalInvocationIndex < 64u)
            {
                _637[_1908][_1914] = _2035[0].x;
                _643[_1908][_1914] = _2035[0].y;
                _648[_1908][_1914] = _2035[0].z;
                _653[_1908][_1914] = _2035[0].w;
                uint _2312 = _1908 + 8u;
                _637[_2312][_1914] = _2035[1].x;
                _643[_2312][_1914] = _2035[1].y;
                _648[_2312][_1914] = _2035[1].z;
                _653[_2312][_1914] = _2035[1].w;
                uint _2321 = _1914 + 8u;
                _637[_1908][_2321] = _2035[2].x;
                _643[_1908][_2321] = _2035[2].y;
                _648[_1908][_2321] = _2035[2].z;
                _653[_1908][_2321] = _2035[2].w;
                _637[_2312][_2321] = _2035[3].x;
                _643[_2312][_2321] = _2035[3].y;
                _648[_2312][_2321] = _2035[3].z;
                _653[_2312][_2321] = _2035[3].w;
            }
            break;
        } while(false);
        do
        {
            if (_353._m19.x <= 2u)
            {
                break;
            }
            threadgroup_barrier(mem_flags::mem_device | mem_flags::mem_threadgroup | mem_flags::mem_texture);
            if (gl_LocalInvocationIndex < 64u)
            {
                uint _5636 = _2091 + 1u;
                uint _5646 = _2094 + 1u;
                float _5728 = _637[_2091][_2094];
                float _5732 = _643[_2091][_2094];
                float _5736 = _648[_2091][_2094];
                float _5747 = _637[_5636][_2094];
                float _5751 = _643[_5636][_2094];
                float _5755 = _648[_5636][_2094];
                float _5766 = _637[_2091][_5646];
                float _5770 = _643[_2091][_5646];
                float _5774 = _648[_2091][_5646];
                float _5785 = _637[_5636][_5646];
                float _5789 = _643[_5636][_5646];
                float _5793 = _648[_5636][_5646];
                float4 _5808 = (((float4(_5728, _5732, _5736, _653[_2091][_2094]) + float4(_5747, _5751, _5755, _653[_5636][_2094])) + float4(_5766, _5770, _5774, _653[_2091][_5646])) + float4(_5785, _5789, _5793, _653[_5636][_5646])) * 0.25;
                uint _5674 = _2091 + (_1914 % 2u);
                _637[_5674][_2094] = _5808.x;
                _643[_5674][_2094] = _5808.y;
                _648[_5674][_2094] = _5808.z;
                _653[_5674][_2094] = _5808.w;
            }
            if (_353._m19.x <= 3u)
            {
                break;
            }
            threadgroup_barrier(mem_flags::mem_device | mem_flags::mem_threadgroup | mem_flags::mem_texture);
            if (gl_LocalInvocationIndex < 16u)
            {
                uint _5974 = _1908 * 4u;
                uint _5978 = _1914 * 4u;
                uint _5983 = _5974 + 2u;
                uint _5992 = _5974 + 1u;
                uint _5995 = _5978 + 2u;
                uint _6000 = _5974 + 3u;
                float _6077 = _637[_5974][_5978];
                float _6081 = _643[_5974][_5978];
                float _6085 = _648[_5974][_5978];
                float _6096 = _637[_5983][_5978];
                float _6100 = _643[_5983][_5978];
                float _6104 = _648[_5983][_5978];
                float _6115 = _637[_5992][_5995];
                float _6119 = _643[_5992][_5995];
                float _6123 = _648[_5992][_5995];
                float _6134 = _637[_6000][_5995];
                float _6138 = _643[_6000][_5995];
                float _6142 = _648[_6000][_5995];
                float4 _6157 = (((float4(_6077, _6081, _6085, _653[_5974][_5978]) + float4(_6096, _6100, _6104, _653[_5983][_5978])) + float4(_6115, _6119, _6123, _653[_5992][_5995])) + float4(_6134, _6138, _6142, _653[_6000][_5995])) * 0.25;
                uint _6023 = _5974 + _1914;
                _637[_6023][_5978] = _6157.x;
                _643[_6023][_5978] = _6157.y;
                _648[_6023][_5978] = _6157.z;
                _653[_6023][_5978] = _6157.w;
            }
            if (_353._m19.x <= 4u)
            {
                break;
            }
            threadgroup_barrier(mem_flags::mem_device | mem_flags::mem_threadgroup | mem_flags::mem_texture);
            if (gl_LocalInvocationIndex < 4u)
            {
                uint _6323 = _1908 * 8u;
                uint _6328 = _6323 + _2094;
                uint _6330 = _1914 * 8u;
                uint _6339 = (_6323 + 4u) + _2094;
                uint _6350 = (_6323 + 1u) + _2094;
                uint _6353 = _6330 + 4u;
                uint _6361 = (_6323 + 5u) + _2094;
                float _6436 = _637[_6328][_6330];
                float _6440 = _643[_6328][_6330];
                float _6444 = _648[_6328][_6330];
                float _6455 = _637[_6339][_6330];
                float _6459 = _643[_6339][_6330];
                float _6463 = _648[_6339][_6330];
                float _6474 = _637[_6350][_6353];
                float _6478 = _643[_6350][_6353];
                float _6482 = _648[_6350][_6353];
                float _6493 = _637[_6361][_6353];
                float _6497 = _643[_6361][_6353];
                float _6501 = _648[_6361][_6353];
                float4 _6516 = (((float4(_6436, _6440, _6444, _653[_6328][_6330]) + float4(_6455, _6459, _6463, _653[_6339][_6330])) + float4(_6474, _6478, _6482, _653[_6350][_6353])) + float4(_6493, _6497, _6501, _653[_6361][_6353])) * 0.25;
                uint _6384 = _1908 + _2094;
                _637[_6384][0u] = _6516.x;
                _643[_6384][0u] = _6516.y;
                _648[_6384][0u] = _6516.z;
                _653[_6384][0u] = _6516.w;
            }
            if (_353._m19.x <= 5u)
            {
                break;
            }
            threadgroup_barrier(mem_flags::mem_device | mem_flags::mem_threadgroup | mem_flags::mem_texture);
            break;
        } while(false);
        if (_353._m19.x <= 6u)
        {
            break;
        }
        if (gl_LocalInvocationIndex == 0u)
        {
            _494 = 0u;
        }
        threadgroup_barrier(mem_flags::mem_device | mem_flags::mem_threadgroup | mem_flags::mem_texture);
        if (_494 != (_353._m19.y - 1u))
        {
            break;
        }
        uint _7050;
        uint _7080;
        do
        {
            _7050 = _2091 + 1u;
            _7080 = _2094 + 1u;
            if (_353._m19.x <= 7u)
            {
                break;
            }
            _637[_1908][_1914] = 0.0;
            _643[_1908][_1914] = 0.0;
            _648[_1908][_1914] = 0.0;
            _653[_1908][_1914] = 0.0;
            break;
        } while(false);
        do
        {
            if (_353._m19.x <= 8u)
            {
                break;
            }
            threadgroup_barrier(mem_flags::mem_device | mem_flags::mem_threadgroup | mem_flags::mem_texture);
            if (gl_LocalInvocationIndex < 64u)
            {
                float _8440 = _637[_2091][_2094];
                float _8444 = _643[_2091][_2094];
                float _8448 = _648[_2091][_2094];
                float _8459 = _637[_7050][_2094];
                float _8463 = _643[_7050][_2094];
                float _8467 = _648[_7050][_2094];
                float _8478 = _637[_2091][_7080];
                float _8482 = _643[_2091][_7080];
                float _8486 = _648[_2091][_7080];
                float _8497 = _637[_7050][_7080];
                float _8501 = _643[_7050][_7080];
                float _8505 = _648[_7050][_7080];
                float4 _8520 = (((float4(_8440, _8444, _8448, _653[_2091][_2094]) + float4(_8459, _8463, _8467, _653[_7050][_2094])) + float4(_8478, _8482, _8486, _653[_2091][_7080])) + float4(_8497, _8501, _8505, _653[_7050][_7080])) * 0.25;
                uint _8386 = _2091 + (_1914 % 2u);
                _637[_8386][_2094] = _8520.x;
                _643[_8386][_2094] = _8520.y;
                _648[_8386][_2094] = _8520.z;
                _653[_8386][_2094] = _8520.w;
            }
            if (_353._m19.x <= 9u)
            {
                break;
            }
            threadgroup_barrier(mem_flags::mem_device | mem_flags::mem_threadgroup | mem_flags::mem_texture);
            if (gl_LocalInvocationIndex < 16u)
            {
                uint _8686 = _1908 * 4u;
                uint _8690 = _1914 * 4u;
                uint _8695 = _8686 + 2u;
                uint _8704 = _8686 + 1u;
                uint _8707 = _8690 + 2u;
                uint _8712 = _8686 + 3u;
                float _8789 = _637[_8686][_8690];
                float _8793 = _643[_8686][_8690];
                float _8797 = _648[_8686][_8690];
                float _8808 = _637[_8695][_8690];
                float _8812 = _643[_8695][_8690];
                float _8816 = _648[_8695][_8690];
                float _8827 = _637[_8704][_8707];
                float _8831 = _643[_8704][_8707];
                float _8835 = _648[_8704][_8707];
                float _8846 = _637[_8712][_8707];
                float _8850 = _643[_8712][_8707];
                float _8854 = _648[_8712][_8707];
                float4 _8869 = (((float4(_8789, _8793, _8797, _653[_8686][_8690]) + float4(_8808, _8812, _8816, _653[_8695][_8690])) + float4(_8827, _8831, _8835, _653[_8704][_8707])) + float4(_8846, _8850, _8854, _653[_8712][_8707])) * 0.25;
                uint _8735 = _8686 + _1914;
                _637[_8735][_8690] = _8869.x;
                _643[_8735][_8690] = _8869.y;
                _648[_8735][_8690] = _8869.z;
                _653[_8735][_8690] = _8869.w;
            }
            if (_353._m19.x <= 10u)
            {
                break;
            }
            threadgroup_barrier(mem_flags::mem_device | mem_flags::mem_threadgroup | mem_flags::mem_texture);
            if (gl_LocalInvocationIndex < 4u)
            {
                uint _9035 = _1908 * 8u;
                uint _9040 = _9035 + _2094;
                uint _9042 = _1914 * 8u;
                uint _9051 = (_9035 + 4u) + _2094;
                uint _9062 = (_9035 + 1u) + _2094;
                uint _9065 = _9042 + 4u;
                uint _9073 = (_9035 + 5u) + _2094;
                float _9148 = _637[_9040][_9042];
                float _9152 = _643[_9040][_9042];
                float _9156 = _648[_9040][_9042];
                float _9167 = _637[_9051][_9042];
                float _9171 = _643[_9051][_9042];
                float _9175 = _648[_9051][_9042];
                float _9186 = _637[_9062][_9065];
                float _9190 = _643[_9062][_9065];
                float _9194 = _648[_9062][_9065];
                float _9205 = _637[_9073][_9065];
                float _9209 = _643[_9073][_9065];
                float _9213 = _648[_9073][_9065];
                float4 _9228 = (((float4(_9148, _9152, _9156, _653[_9040][_9042]) + float4(_9167, _9171, _9175, _653[_9051][_9042])) + float4(_9186, _9190, _9194, _653[_9062][_9065])) + float4(_9205, _9209, _9213, _653[_9073][_9065])) * 0.25;
                uint _9096 = _1908 + _2094;
                _637[_9096][0u] = _9228.x;
                _643[_9096][0u] = _9228.y;
                _648[_9096][0u] = _9228.z;
                _653[_9096][0u] = _9228.w;
            }
            if (_353._m19.x <= 11u)
            {
                break;
            }
            threadgroup_barrier(mem_flags::mem_device | mem_flags::mem_threadgroup | mem_flags::mem_texture);
            break;
        } while(false);
        break;
    } while(false);
}

