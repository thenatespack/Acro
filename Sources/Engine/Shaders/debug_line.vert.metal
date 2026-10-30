// Generated from debug_line.vert by Scripts/compile-shaders.sh — do not edit.
// Edit the GLSL and rerun the script (needs glslc and spirv-cross).
// spirv-fnv1a64: 6642f30ccaf40729
// glsl-fnv1a64: 2270d0a3345da869

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

struct _11
{
    float4x4 _m0;
    float4 _m1;
};

constant spvUnsafeArray<float2, 6> _197 = spvUnsafeArray<float2, 6>({ float2(0.0, -1.0), float2(1.0, -1.0), float2(1.0), float2(0.0, -1.0), float2(1.0), float2(0.0, 1.0) });

struct vertex_main_out
{
    float4 m_82 [[user(locn0)]];
    float2 m_102 [[user(locn1)]];
    float4 gl_Position [[position]];
};

struct vertex_main_in
{
    float4 m_20 [[attribute(0)]];
    float4 m_33 [[attribute(1)]];
    float4 m_83 [[attribute(2)]];
};

vertex vertex_main_out vertex_main(vertex_main_in in [[stage_in]], constant _11& _13 [[buffer(16)]], uint gl_VertexIndex [[vertex_id]])
{
    vertex_main_out out = {};
    do
    {
        float4 _29 = _13._m0 * float4(in.m_20.xyz, 1.0);
        float4 _40 = _13._m0 * float4(in.m_33.xyz, 1.0);
        bool _51 = _13._m1.z > 0.5;
        float _316;
        if (_51)
        {
            _316 = _29.w - _29.z;
        }
        else
        {
            _316 = _29.z;
        }
        float _318;
        if (_51)
        {
            _318 = _40.w - _40.z;
        }
        else
        {
            _318 = _40.z;
        }
        out.m_82 = in.m_83;
        bool _87 = _316 < 0.0;
        bool _89 = _318 < 0.0;
        if (_87 && _89)
        {
            out.gl_Position = float4(0.0, 0.0, 0.5, 1.0);
            out.m_102 = float2(0.0);
            break;
        }
        float4 _323;
        if (_87)
        {
            _323 = mix(_29, _40, float4(_316 / (_316 - _318)));
        }
        else
        {
            _323 = _29;
        }
        float4 _324;
        if (_89)
        {
            _324 = mix(_40, _29, float4(_318 / (_318 - _316)));
        }
        else
        {
            _324 = _40;
        }
        float2 _141 = _13._m1.xy * 0.5;
        float2 _150 = (_323.xy / float2(_323.w)) * _141;
        float2 _159 = (_324.xy / float2(_324.w)) * _141;
        float2 _163 = _159 - _150;
        float _166 = length(_163);
        float2 _326;
        if (_166 > 9.9999997473787516355514526367188e-05)
        {
            _326 = _163 / float2(_166);
        }
        else
        {
            _326 = float2(1.0, 0.0);
        }
        bool _209 = _197[int(gl_VertexIndex)].x > 0.5;
        float4 _216 = select(_323, _324, bool4(_209));
        float _329;
        if (in.m_20.w >= 0.0)
        {
            _329 = in.m_20.w;
        }
        else
        {
            _329 = (((-in.m_20.w) * _141.y) * _13._m1.w) / _216.w;
        }
        float _243 = 0.5 * _329;
        float _246 = _243 + 1.0;
        float _258 = _197[int(gl_VertexIndex)].y * _246;
        out.gl_Position = float4((((select(_150, _159, bool2(_209)) + (float2(-_326.y, _326.x) * _258)) + (_326 * ((_209 ? 1.0 : (-1.0)) * _246))) / _141) * _216.w, _216.zw);
        out.m_102 = float2(_258, _243);
        out.gl_Position.y = -out.gl_Position.y;
        break;
    } while(false);
    out.gl_Position.y = -(out.gl_Position.y);    // Invert Y-axis for Metal
    return out;
}

