// Generated from decal_graph.frag by Scripts/compile-shaders.sh — do not edit.
// Edit the GLSL and rerun the script (needs glslc and spirv-cross).
// spirv-fnv1a64: 0e14b12390ec91a5
// glsl-fnv1a64: 8aa7d4326f83b219

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

struct Frame
{
    float4x4 viewProj;
    float4x4 lightViewProj;
    float4x4 currentViewProj;
    float4x4 previousViewProj;
    float4 lightDir;
    float4 lightColor;
    float4 cameraPos;
    float4 fogColor;
    float4 skyColor;
    float4 groundColor;
    float4 shadowParams;
    float4 viewDepth;
    float4 clusterScale;
    float4 clusterGrid;
    float4x4 cascadeMatrices[4];
    float4x4 spotShadowMatrices[8];
    float4 cascadeSplits;
    float4 cascadeBlendStarts;
    float4 cascadeNormalOffsets;
    float4 cascadeBiases;
    float4 shadowDepthRow;
    float4 shadowInfo;
    float4 shadowAtlas;
    float4 shadowTiles;
    float4 shadowFaces;
    float4 shadowLocal;
    float4 spotShadowParams[8];
    float4 pointShadowPositions[4];
    float4 pointShadowParams[4];
    float4 environment;
};

struct MaterialGraphValues
{
    float4 values[1];
};

struct DecalData
{
    float4x4 model;
    float4x4 inverseModel;
    float4x4 inverseViewProj;
    float4 color;
    float4 params;
    float4 axis;
};

struct MaterialGraphPush
{
    float4 params;
    float4 eye;
};

struct LightCells
{
    uint4 data[1024];
};

struct LightIndices
{
    uint4 data[1024];
};

struct LightPositions
{
    float4 data[1024];
};

struct LightColors
{
    float4 data[1024];
};

struct LightDirections
{
    float4 data[1024];
};

constant spvUnsafeArray<float3, 4> _512 = spvUnsafeArray<float3, 4>({ float3(1.0, 0.449999988079071044921875, 0.449999988079071044921875), float3(0.449999988079071044921875, 1.0, 0.449999988079071044921875), float3(0.5, 0.60000002384185791015625, 1.0), float3(1.0, 1.0, 0.4000000059604644775390625) });
constant spvUnsafeArray<float3, 6> _816 = spvUnsafeArray<float3, 6>({ float3(0.0, 0.0, 1.0), float3(0.0, 0.0, -1.0), float3(-1.0, 0.0, 0.0), float3(-1.0, 0.0, 0.0), float3(-1.0, 0.0, 0.0), float3(1.0, 0.0, 0.0) });
constant spvUnsafeArray<float3, 6> _825 = spvUnsafeArray<float3, 6>({ float3(0.0, 1.0, 0.0), float3(0.0, 1.0, 0.0), float3(0.0, 0.0, -1.0), float3(0.0, 0.0, 1.0), float3(0.0, 1.0, 0.0), float3(0.0, 1.0, 0.0) });
constant spvUnsafeArray<int4, 6> _1328 = spvUnsafeArray<int4, 6>({ int4(0, 0, 512, 256), int4(0, 256, 256, 128), int4(256, 256, 128, 64), int4(384, 256, 64, 32), int4(448, 256, 32, 16), int4(480, 256, 16, 8) });

struct fragment_main_out
{
    float4 outColor [[color(0)]];
};

static inline __attribute__((always_inline))
float3 depthPoint(thread int2& t, thread const int2& size, sampler materialSampler, texture2d<float> sceneDepth, constant DecalData& decal)
{
    t = clamp(t, int2(0), size - int2(1));
    float z = sceneDepth.read(uint2(t), 0).x;
    float2 ndc = float2((((float(t.x) + 0.5) / float(size.x)) * 2.0) - 1.0, 1.0 - (((float(t.y) + 0.5) / float(size.y)) * 2.0));
    float4 world = decal.inverseViewProj * float4(ndc, z, 1.0);
    return world.xyz / float3(world.w);
}

static inline __attribute__((always_inline))
float3 decalSpace(thread const float3& p, constant DecalData& decal)
{
    return (decal.inverseModel * float4(p, 1.0)).xyz;
}

static inline __attribute__((always_inline))
void graphSurface(texture2d<float> baseColorMap, sampler materialSampler, thread float2& gUV, texture2d<float> metallicRoughnessMap, texture2d<float> normalMap, texture2d<float> occlusionMap, texture2d<float> emissiveMap, const device MaterialGraphValues& graphValues, thread float3& gBaseColor, thread float4& gVertexColor, thread float3& gPosition, thread float3& gNormal, thread float3& gView, thread float& gTime, thread float& gOpacity, thread float3& gNormalTS, thread float& gMetallic, thread float& gRoughness, thread float3& gEmissive, thread float& gOcclusion)
{
    float4 a = baseColorMap.sample(materialSampler, gUV);
    float4 b = metallicRoughnessMap.sample(materialSampler, gUV);
    float4 c = normalMap.sample(materialSampler, gUV);
    float4 d = occlusionMap.sample(materialSampler, gUV);
    float4 e = emissiveMap.sample(materialSampler, gUV);
    float4 v = graphValues.values[0];
    gBaseColor = ((a.xyz * gVertexColor.xyz) * v.xyz) + (((gPosition + gNormal) + gView) * gTime);
    gOpacity = a.w * v.w;
    gNormalTS = (c.xyz * 2.0) - float3(1.0);
    gMetallic = b.z;
    gRoughness = b.y;
    gEmissive = e.xyz;
    gOcclusion = d.x;
}

static inline __attribute__((always_inline))
float shadowPCF(thread const float2& uv, thread const float& ref, thread const float4& bounds, constant Frame& frame, texture2d<float> shadowMap, sampler shadowMapSmplr)
{
    float2 texel = frame.shadowAtlas.xy;
    int radius = int(frame.shadowAtlas.z);
    if (radius <= 0)
    {
        float3 _166 = float3(fast::clamp(uv, bounds.xy, bounds.zw), ref);
        return spvDepthCast(shadowMap).sample_compare(shadowMapSmplr, _166.xy, _166.z);
    }
    float2 p = uv / texel;
    float2 base = floor(p + float2(0.5));
    float2 st = (p + float2(0.5)) - base;
    base = (base - float2(0.5)) * texel;
    spvUnsafeArray<float2, 3> w;
    spvUnsafeArray<float2, 3> o;
    int n;
    float norm;
    if (radius == 1)
    {
        w[0] = float2(3.0) - (st * 2.0);
        w[1] = float2(1.0) + (st * 2.0);
        o[0] = ((float2(2.0) - st) / w[0]) - float2(1.0);
        o[1] = (st / w[1]) + float2(1.0);
        n = 2;
        norm = 0.0625;
    }
    else
    {
        w[0] = float2(4.0) - (st * 3.0);
        w[1] = float2(7.0);
        w[2] = float2(1.0) + (st * 3.0);
        o[0] = ((float2(3.0) - (st * 2.0)) / w[0]) - float2(2.0);
        o[1] = (float2(3.0) + st) / w[1];
        o[2] = (st / w[2]) + float2(2.0);
        n = 3;
        norm = 0.0069444444961845874786376953125;
    }
    float sum = 0.0;
    for (int j = 0; j < n; j++)
    {
        for (int i = 0; i < n; i++)
        {
            float2 tap = fast::clamp(base + (float2(o[i].x, o[j].y) * texel), bounds.xy, bounds.zw);
            float3 _326 = float3(tap, ref);
            sum += ((w[i].x * w[j].y) * spvDepthCast(shadowMap).sample_compare(shadowMapSmplr, _326.xy, _326.z));
        }
    }
    return sum * norm;
}

static inline __attribute__((always_inline))
float tileShadow(thread const float2& local, thread const float& ref, thread const float2& origin, thread const float2& size, constant Frame& frame, texture2d<float> shadowMap, sampler shadowMapSmplr)
{
    float2 halfTexel = frame.shadowAtlas.xy * 0.5;
    float2 param = origin + (local * size);
    float param_1 = ref;
    float4 param_2 = float4(origin + halfTexel, (origin + size) - halfTexel);
    return shadowPCF(param, param_1, param_2, frame, shadowMap, shadowMapSmplr);
}

static inline __attribute__((always_inline))
float cascadeShadow(thread const int& c, thread const float3& p, constant Frame& frame, texture2d<float> shadowMap, sampler shadowMapSmplr)
{
    float3 local = (frame.cascadeMatrices[c] * float4(p, 1.0)).xyz;
    bool _386 = local.x < 0.0;
    bool _393;
    if (!_386)
    {
        _393 = local.x > 1.0;
    }
    else
    {
        _393 = _386;
    }
    bool _400;
    if (!_393)
    {
        _400 = local.y < 0.0;
    }
    else
    {
        _400 = _393;
    }
    bool _407;
    if (!_400)
    {
        _407 = local.y > 1.0;
    }
    else
    {
        _407 = _400;
    }
    if (_407)
    {
        return 1.0;
    }
    float2 origin = float2(float(c & 1), float(c >> 1)) * frame.shadowTiles.xy;
    float2 param = local.xy;
    float param_1 = fast::min(local.z, 1.0) - frame.cascadeBiases[c];
    float2 param_2 = origin;
    float2 param_3 = frame.shadowTiles.xy;
    return tileShadow(param, param_1, param_2, param_3, frame, shadowMap, shadowMapSmplr);
}

static inline __attribute__((always_inline))
float directionalShadow(thread const float3& p, thread const float3& ng, thread float3& tint, constant Frame& frame, texture2d<float> shadowMap, sampler shadowMapSmplr)
{
    tint = float3(1.0);
    int count = int(frame.shadowInfo.x);
    float depth = dot(frame.shadowDepthRow.xyz, p) + frame.shadowDepthRow.w;
    int c = 0;
    for (;;)
    {
        bool _470 = c < (count - 1);
        bool _479;
        if (_470)
        {
            _479 = depth > frame.cascadeSplits[c];
        }
        else
        {
            _479 = _470;
        }
        if (_479)
        {
            c++;
            continue;
        }
        else
        {
            break;
        }
    }
    if (depth > frame.cascadeSplits[c])
    {
        return 1.0;
    }
    int param = c;
    float3 param_1 = p + (ng * frame.cascadeNormalOffsets[c]);
    float s = cascadeShadow(param, param_1, frame, shadowMap, shadowMapSmplr);
    float3 t = _512[c];
    float start = frame.cascadeBlendStarts[c];
    if (depth > start)
    {
        float f = (depth - start) / (frame.cascadeSplits[c] - start);
        if ((c + 1) < count)
        {
            int param_2 = c + 1;
            float3 param_3 = p + (ng * frame.cascadeNormalOffsets[c + 1]);
            s = mix(s, cascadeShadow(param_2, param_3, frame, shadowMap, shadowMapSmplr), f);
            t = mix(t, _512[c + 1], float3(f));
        }
        else
        {
            s = mix(s, 1.0, f);
        }
    }
    if (frame.shadowAtlas.w > 0.5)
    {
        tint = t;
    }
    return s;
}

static inline __attribute__((always_inline))
float3 fresnelSchlick(thread const float3& f0, thread const float& VoH)
{
    float f = powr(1.0 - VoH, 5.0);
    return f0 + ((float3(1.0) - f0) * f);
}

static inline __attribute__((always_inline))
float distributionGGX(thread const float& NoH, thread const float& a)
{
    float a2 = a * a;
    float d = ((NoH * NoH) * (a2 - 1.0)) + 1.0;
    return a2 / ((3.1415927410125732421875 * d) * d);
}

static inline __attribute__((always_inline))
float visibilitySmithGGXCorrelated(thread const float& NoV, thread const float& NoL, thread const float& a)
{
    float a2 = a * a;
    float ggxV = NoL * sqrt(((NoV * NoV) * (1.0 - a2)) + a2);
    float ggxL = NoV * sqrt(((NoL * NoL) * (1.0 - a2)) + a2);
    return 0.5 / fast::max(ggxV + ggxL, 9.9999997473787516355514526367188e-06);
}

static inline __attribute__((always_inline))
float2 environmentBRDF(thread const float& NoV, thread const float& roughness)
{
    float4 r = (float4(-1.0, -0.0274999998509883880615234375, -0.572000026702880859375, 0.02199999988079071044921875) * roughness) + float4(1.0, 0.0425000004470348358154296875, 1.03999996185302734375, -0.039999999105930328369140625);
    float a004 = (fast::min(r.x * r.x, exp2((-9.27999973297119140625) * NoV)) * r.x) + r.y;
    return (float2(-1.03999996185302734375, 1.03999996185302734375) * a004) + r.zw;
}

static inline __attribute__((always_inline))
float3 environmentDirection(thread const float3& d, thread const float2& cs)
{
    return float3((cs.x * d.x) - (cs.y * d.z), d.y, (cs.y * d.x) + (cs.x * d.z));
}

static inline __attribute__((always_inline))
void shBasis(thread const float3& d, thread spvUnsafeArray<float, 9>& y)
{
    y[0] = 0.2820949852466583251953125;
    y[1] = 0.48860299587249755859375 * d.y;
    y[2] = 0.48860299587249755859375 * d.z;
    y[3] = 0.48860299587249755859375 * d.x;
    y[4] = (1.09254801273345947265625 * d.x) * d.y;
    y[5] = (1.09254801273345947265625 * d.y) * d.z;
    y[6] = 0.3153919875621795654296875 * (((3.0 * d.z) * d.z) - 1.0);
    y[7] = (1.09254801273345947265625 * d.x) * d.z;
    y[8] = 0.546274006366729736328125 * ((d.x * d.x) - (d.y * d.y));
}

static inline __attribute__((always_inline))
float3 environmentIrradiance(thread const float3& n, constant Frame& frame, sampler materialSampler, texture2d<float> environmentAtlas)
{
    float3 param = n;
    float2 param_1 = frame.environment.zw;
    float3 param_2 = environmentDirection(param, param_1);
    spvUnsafeArray<float, 9> param_3;
    shBasis(param_2, param_3);
    spvUnsafeArray<float, 9> y = param_3;
    float3 sum = float3(0.0);
    for (int i = 0; i < 9; i++)
    {
        sum += (environmentAtlas.read(uint2((int2(496, 256) + int2(i, 0))), 0).xyz * y[i]);
    }
    return fast::max(sum, float3(0.0)) * frame.environment.y;
}

static inline __attribute__((always_inline))
float2 equirectUV(thread const float3& d)
{
    return float2((precise::atan2(d.x, -d.z) * 0.15915493667125701904296875) + 0.5, acos(fast::clamp(d.y, -1.0, 1.0)) * 0.3183098733425140380859375);
}

static inline __attribute__((always_inline))
float3 sampleEquirect(texture2d<float> image, sampler s, thread const int4& region, thread const float2& uv)
{
    float2 p = (uv * float2(region.zw)) - float2(0.5);
    float2 f = floor(p);
    float2 t = p - f;
    int x0 = int(f.x);
    int y0 = int(f.y);
    if (x0 < 0)
    {
        x0 += region.z;
    }
    if (x0 >= region.z)
    {
        x0 -= region.z;
    }
    int _980;
    if ((x0 + 1) == region.z)
    {
        _980 = 0;
    }
    else
    {
        _980 = x0 + 1;
    }
    int x1 = _980;
    int y1 = min((y0 + 1), (region.w - 1));
    y0 = max(y0, 0);
    float3 a = image.read(uint2((region.xy + int2(x0, y0))), 0).xyz;
    float3 b = image.read(uint2((region.xy + int2(x1, y0))), 0).xyz;
    float3 c = image.read(uint2((region.xy + int2(x0, y1))), 0).xyz;
    float3 d = image.read(uint2((region.xy + int2(x1, y1))), 0).xyz;
    return mix(mix(a, b, float3(t.x)), mix(c, d, float3(t.x)), float3(t.y));
}

static inline __attribute__((always_inline))
float3 environmentRadiance(thread const float3& d, thread const float& roughness, constant Frame& frame, sampler materialSampler, texture2d<float> environmentAtlas)
{
    float3 param = d;
    float2 param_1 = frame.environment.zw;
    float3 param_2 = environmentDirection(param, param_1);
    float2 uv = equirectUV(param_2);
    float level0 = roughness * 5.0;
    int i = min(int(level0), 4);
    int4 param_3 = _1328[i];
    float2 param_4 = uv;
    float3 a = sampleEquirect(environmentAtlas, materialSampler, param_3, param_4);
    int4 param_5 = _1328[i + 1];
    float2 param_6 = uv;
    float3 b = sampleEquirect(environmentAtlas, materialSampler, param_5, param_6);
    return mix(a, b, float3(level0 - float(i))) * frame.environment.y;
}

static inline __attribute__((always_inline))
float3 hemisphere(thread const float3& d, constant Frame& frame)
{
    return mix(frame.groundColor.xyz, frame.skyColor.xyz, float3((d.y * 0.5) + 0.5)) * frame.skyColor.w;
}

static inline __attribute__((always_inline))
float localShadow(thread const uint& index, thread const float3& p, thread const float3& ng, thread const float3& l, constant Frame& frame, texture2d<float> shadowMap, sampler shadowMapSmplr)
{
    uint spots = uint(frame.shadowInfo.z);
    if (index < spots)
    {
        float4 params = frame.spotShadowParams[index];
        float4 clip0 = frame.spotShadowMatrices[index] * float4(p, 1.0);
        float texel = params.z * fast::max(clip0.w, 0.0);
        float3 q = (p + (ng * (texel * frame.shadowLocal.x))) + (l * (texel * frame.shadowLocal.y));
        float4 clip = frame.spotShadowMatrices[index] * float4(q, 1.0);
        if (clip.w <= 0.0)
        {
            return 1.0;
        }
        float3 local = clip.xyz / float3(clip.w);
        bool _656 = local.x < 0.0;
        bool _663;
        if (!_656)
        {
            _663 = local.x > 1.0;
        }
        else
        {
            _663 = _656;
        }
        bool _670;
        if (!_663)
        {
            _670 = local.y < 0.0;
        }
        else
        {
            _670 = _663;
        }
        bool _677;
        if (!_670)
        {
            _677 = local.y > 1.0;
        }
        else
        {
            _677 = _670;
        }
        bool _684;
        if (!_677)
        {
            _684 = local.z > 1.0;
        }
        else
        {
            _684 = _677;
        }
        if (_684)
        {
            return 1.0;
        }
        float2 param = local.xy;
        float param_1 = local.z;
        float2 param_2 = params.xy;
        float2 param_3 = frame.shadowTiles.zw;
        return tileShadow(param, param_1, param_2, param_3, frame, shadowMap, shadowMapSmplr);
    }
    uint point = index - spots;
    if (point >= uint(frame.shadowInfo.w))
    {
        return 1.0;
    }
    float4 position = frame.pointShadowPositions[point];
    float4 params_1 = frame.pointShadowParams[point];
    float texel_1 = position.w * length(p - position.xyz);
    float3 d = ((p + (ng * (texel_1 * frame.shadowLocal.x))) + (l * (texel_1 * frame.shadowLocal.y))) - position.xyz;
    float3 a = abs(d);
    bool _760 = a.x >= a.y;
    bool _768;
    if (_760)
    {
        _768 = a.x >= a.z;
    }
    else
    {
        _768 = _760;
    }
    int face;
    float m;
    if (_768)
    {
        face = (d.x > 0.0) ? 0 : 1;
        m = a.x;
    }
    else
    {
        if (a.y >= a.z)
        {
            face = (d.y > 0.0) ? 2 : 3;
            m = a.y;
        }
        else
        {
            face = (d.z > 0.0) ? 4 : 5;
            m = a.z;
        }
    }
    if (m <= 0.0)
    {
        return 1.0;
    }
    float2 st = float2(dot(d, _816[face]), dot(d, _825[face])) / float2(m * frame.shadowFaces.z);
    float ref = params_1.z + (params_1.w / m);
    if (ref > 1.0)
    {
        return 1.0;
    }
    float2 origin = params_1.xy + (float2(float(spvSMod(face, 3)), float(face / 3)) * frame.shadowFaces.xy);
    float2 param_4 = float2(0.5 + (0.5 * st.x), 0.5 - (0.5 * st.y));
    float param_5 = ref;
    float2 param_6 = origin;
    float2 param_7 = frame.shadowFaces.xy;
    return tileShadow(param_4, param_5, param_6, param_7, frame, shadowMap, shadowMapSmplr);
}

fragment fragment_main_out fragment_main(constant DecalData& decal [[buffer(2)]], constant LightPositions& lightPositions [[buffer(3)]], constant LightColors& lightColors [[buffer(4)]], constant LightDirections& lightDirections [[buffer(5)]], constant LightCells& lightCells [[buffer(6)]], constant LightIndices& lightIndices [[buffer(7)]], constant Frame& frame [[buffer(15)]], constant MaterialGraphPush& graphPush [[buffer(16)]], const device MaterialGraphValues& graphValues [[buffer(20)]], texture2d<float> shadowMap [[texture(0)]], texture2d<float> baseColorMap [[texture(1)]], texture2d<float> metallicRoughnessMap [[texture(2)]], texture2d<float> normalMap [[texture(3)]], texture2d<float> occlusionMap [[texture(4)]], texture2d<float> emissiveMap [[texture(5)]], texture2d<float> environmentAtlas [[texture(6)]], texture2d<float> sceneDepth [[texture(7)]], sampler shadowMapSmplr [[sampler(0)]], sampler materialSampler [[sampler(1)]], float4 gl_FragCoord [[position]])
{
    fragment_main_out out = {};
    int2 size = int2(sceneDepth.get_width(), sceneDepth.get_height());
    int2 texel = int2(gl_FragCoord.xy);
    int2 param = texel;
    int2 param_1 = size;
    float3 _1553 = depthPoint(param, param_1, materialSampler, sceneDepth, decal);
    float3 p = _1553;
    float3 param_2 = p;
    float3 q = decalSpace(param_2, decal);
    float2 gUV;
    float3 gBaseColor;
    float4 gVertexColor;
    float3 gPosition;
    float3 gNormal;
    float3 gView;
    float gTime;
    float gOpacity;
    float3 gNormalTS;
    float gMetallic;
    float gRoughness;
    float3 gEmissive;
    float gOcclusion;
    if (any(abs(q) > float3(0.5)))
    {
        discard_fragment();
    }
    int2 param_3 = texel + int2(1, 0);
    int2 param_4 = size;
    float3 _1574 = depthPoint(param_3, param_4, materialSampler, sceneDepth, decal);
    float3 px = _1574;
    int2 param_5 = texel - int2(1, 0);
    int2 param_6 = size;
    float3 _1581 = depthPoint(param_5, param_6, materialSampler, sceneDepth, decal);
    float3 mx = _1581;
    int2 param_7 = texel + int2(0, 1);
    int2 param_8 = size;
    float3 _1589 = depthPoint(param_7, param_8, materialSampler, sceneDepth, decal);
    float3 py = _1589;
    int2 param_9 = texel - int2(0, 1);
    int2 param_10 = size;
    float3 _1596 = depthPoint(param_9, param_10, materialSampler, sceneDepth, decal);
    float3 my = _1596;
    float3 ax = px - p;
    float3 bx = p - mx;
    float3 ay = py - p;
    float3 by = p - my;
    float3 tx = select(bx, ax, bool3(dot(ax, ax) < dot(bx, bx)));
    float3 ty = select(by, ay, bool3(dot(ay, ay) < dot(by, by)));
    float3 v = frame.cameraPos.xyz - p;
    float3 n = cross(tx, ty);
    float3 _1652;
    if (dot(n, n) > 9.9999996826552253889678874634872e-21)
    {
        _1652 = fast::normalize(n);
    }
    else
    {
        _1652 = fast::normalize(v);
    }
    n = _1652;
    if (dot(n, v) < 0.0)
    {
        n = -n;
    }
    v = fast::normalize(v);
    float2 uv = float2(q.x + 0.5, 0.5 - q.y);
    float3 param_11 = p + tx;
    float2 duvdx = (decalSpace(param_11, decal).xy - q.xy) * float2(1.0, -1.0);
    float3 param_12 = p + ty;
    float2 duvdy = (decalSpace(param_12, decal).xy - q.xy) * float2(1.0, -1.0);
    gUV = uv;
    gPosition = p;
    gNormal = n;
    gView = v;
    gVertexColor = decal.color;
    gTime = graphPush.params.x;
    graphSurface(baseColorMap, materialSampler, gUV, metallicRoughnessMap, normalMap, occlusionMap, emissiveMap, graphValues, gBaseColor, gVertexColor, gPosition, gNormal, gView, gTime, gOpacity, gNormalTS, gMetallic, gRoughness, gEmissive, gOcclusion);
    float3 albedo = decal.color.xyz * fast::max(gBaseColor, float3(0.0));
    float alpha = decal.color.w * fast::clamp(gOpacity, 0.0, 1.0);
    float metallic = fast::clamp(gMetallic, 0.0, 1.0);
    float3 gt = decal.model[0].xyz - (n * dot(n, decal.model[0].xyz));
    float3 gb = decal.model[1].xyz - (n * dot(n, decal.model[1].xyz));
    bool _1759 = dot(gt, gt) > 9.9999999600419720025001879548654e-13;
    bool _1766;
    if (_1759)
    {
        _1766 = dot(gb, gb) > 9.9999999600419720025001879548654e-13;
    }
    else
    {
        _1766 = _1759;
    }
    bool _1773;
    if (_1766)
    {
        _1773 = dot(gNormalTS, gNormalTS) > 9.9999999600419720025001879548654e-13;
    }
    else
    {
        _1773 = _1766;
    }
    if (_1773)
    {
        float3 m = fast::normalize(gNormalTS);
        n = fast::normalize(((fast::normalize(gt) * m.x) + (fast::normalize(gb) * m.y)) + (n * m.z));
        if (dot(n, v) < 0.0)
        {
            n = fast::normalize(n - (v * (dot(n, v) - 0.001000000047497451305389404296875)));
        }
    }
    if (decal.params.z > 0.0)
    {
        alpha *= fast::clamp(dot(n, -decal.axis.xyz) / decal.params.z, 0.0, 1.0);
    }
    if (alpha <= 0.0)
    {
        discard_fragment();
    }
    float roughness = fast::clamp(gRoughness, 0.04500000178813934326171875, 1.0);
    float a = roughness * roughness;
    float3 f0 = mix(float3(0.039999999105930328369140625), albedo, float3(metallic));
    float3 diffuse = albedo * (1.0 - metallic);
    float3 l = fast::normalize(frame.lightDir.xyz);
    float3 h = fast::normalize(l + v);
    float shadow = 1.0;
    if (frame.lightColor.w > 0.5)
    {
        float3 param_13 = p;
        float3 param_14 = n;
        float3 param_15;
        float _1876 = directionalShadow(param_13, param_14, param_15, frame, shadowMap, shadowMapSmplr);
        float3 cascadeTint = param_15;
        shadow = _1876;
    }
    float3 light = frame.lightColor.xyz * frame.lightDir.w;
    float NoV = fast::max(dot(n, v), 9.9999997473787516355514526367188e-05);
    float NoL = fast::clamp(dot(n, l), 0.0, 1.0);
    float NoH = fast::clamp(dot(n, h), 0.0, 1.0);
    float VoH = fast::clamp(dot(v, h), 0.0, 1.0);
    float3 param_16 = f0;
    float param_17 = VoH;
    float3 F = fresnelSchlick(param_16, param_17);
    float param_18 = NoH;
    float param_19 = a;
    float param_20 = NoV;
    float param_21 = NoL;
    float param_22 = a;
    float3 specular = (F * (distributionGGX(param_18, param_19) * visibilitySmithGGXCorrelated(param_20, param_21, param_22))) * 3.1415927410125732421875;
    float3 color = (((((float3(1.0) - F) * diffuse) + specular) * NoL) * light) * shadow;
    float2 dfg;
    float3 irradiance;
    float3 reflected;
    if (frame.environment.x > 0.5)
    {
        float param_23 = NoV;
        float param_24 = roughness;
        dfg = environmentBRDF(param_23, param_24);
        float3 param_25 = n;
        irradiance = environmentIrradiance(param_25, frame, materialSampler, environmentAtlas);
        float3 param_26 = reflect(-v, n);
        float param_27 = roughness;
        reflected = environmentRadiance(param_26, param_27, frame, materialSampler, environmentAtlas);
    }
    else
    {
        float param_28 = NoV;
        float param_29 = roughness;
        dfg = environmentBRDF(param_28, param_29);
        float3 param_30 = n;
        irradiance = hemisphere(param_30, frame);
        float3 param_31 = reflect(-v, n);
        reflected = mix(hemisphere(param_31, frame), irradiance, float3(roughness));
    }
    float3 specularAmbient = (f0 * dfg.x) + float3(dfg.y);
    float ao = fast::clamp(gOcclusion, 0.0, 1.0);
    color += (((((float3(1.0) - specularAmbient) * diffuse) * irradiance) + (specularAmbient * reflected)) * ao);
    if (frame.clusterGrid.w > 0.5)
    {
        float depth = dot(frame.viewDepth.xyz, p) + frame.viewDepth.w;
        float2 tile = fast::clamp(floor(gl_FragCoord.xy * frame.clusterScale.xy), float2(0.0), frame.clusterGrid.xy - float2(1.0));
        float slice = fast::clamp(floor((log2(fast::max(depth, 9.9999999747524270787835121154785e-07)) * frame.clusterScale.z) + frame.clusterScale.w), 0.0, frame.clusterGrid.z - 1.0);
        uint cluster = uint((((slice * frame.clusterGrid.y) + tile.y) * frame.clusterGrid.x) + tile.x);
        uint cell = lightCells.data[cluster >> uint(2)][cluster & 3u];
        uint first = cell & 65535u;
        uint count = cell >> uint(16);
        for (uint i = first; i < (first + count); i++)
        {
            uint word = i / 3u;
            uint li = (lightIndices.data[word >> uint(2)][word & 3u] >> ((i - (word * 3u)) * 10u)) & 1023u;
            float4 position = lightPositions.data[li];
            float3 toLight = position.xyz - p;
            float d2 = dot(toLight, toLight);
            float x = d2 * position.w;
            float window = fast::clamp(1.0 - (x * x), 0.0, 1.0);
            float3 pl = toLight * rsqrt(fast::max(d2, 9.9999999392252902907785028219223e-09));
            float4 lc = lightColors.data[li];
            float4 direction = lightDirections.data[li];
            float cone = fast::clamp((dot(-pl, direction.xyz) * lc.w) + direction.w, 0.0, 1.0);
            float3 radiance = lc.xyz * ((((window * window) * cone) * cone) / fast::max(d2, 9.9999997473787516355514526367188e-05));
            uint param_32 = li;
            float3 param_33 = p;
            float3 param_34 = n;
            float3 param_35 = pl;
            radiance *= localShadow(param_32, param_33, param_34, param_35, frame, shadowMap, shadowMapSmplr);
            float3 ph = fast::normalize(pl + v);
            float pNoL = fast::clamp(dot(n, pl), 0.0, 1.0);
            float pNoH = fast::clamp(dot(n, ph), 0.0, 1.0);
            float3 param_36 = f0;
            float param_37 = fast::clamp(dot(v, ph), 0.0, 1.0);
            float3 pF = fresnelSchlick(param_36, param_37);
            float param_38 = pNoH;
            float param_39 = a;
            float param_40 = NoV;
            float param_41 = pNoL;
            float param_42 = a;
            float3 pSpecular = (pF * (distributionGGX(param_38, param_39) * visibilitySmithGGXCorrelated(param_40, param_41, param_42))) * 3.1415927410125732421875;
            color += (((((float3(1.0) - pF) * diffuse) + pSpecular) * pNoL) * radiance);
        }
    }
    color += ((albedo * decal.params.x) + fast::max(gEmissive, float3(0.0)));
    float dist = length(frame.cameraPos.xyz - p);
    float fog = 1.0 - exp((-dist) * frame.fogColor.w);
    out.outColor = float4(mix(color, frame.fogColor.xyz, float3(fog)), alpha);
    return out;
}

