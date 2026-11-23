// Generated from mesh_graph.frag by Scripts/compile-shaders.sh — do not edit.
// Edit the GLSL and rerun the script (needs glslc and spirv-cross).
// spirv-fnv1a64: 3dc19c25f182291a
// glsl-fnv1a64: 1e784319ea196fd3

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

struct ProbeBasis
{
    float4 a;
    float4 b;
    float c;
};

struct MaterialGraphValues
{
    float4 values[1];
};

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
    float4x4 reflectionViewProj;
    float4 reflectionPlane;
    float4 reflectionParams;
    float4 reflectionExtra;
    float4 probes;
};

struct ProbeData
{
    uint4 words[1];
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

struct LightCells
{
    uint4 data[1024];
};

struct LightIndices
{
    uint4 data[1024];
};

struct MaterialGraphPush
{
    float4 params;
};

struct MaterialData
{
    float4 baseColor;
    float4 params;
    float4 uvRow0;
    float4 uvRow1;
    float4 surface;
    float4 emissive;
    float4 flags;
};

constant spvUnsafeArray<float3, 4> _743 = spvUnsafeArray<float3, 4>({ float3(1.0, 0.449999988079071044921875, 0.449999988079071044921875), float3(0.449999988079071044921875, 1.0, 0.449999988079071044921875), float3(0.5, 0.60000002384185791015625, 1.0), float3(1.0, 1.0, 0.4000000059604644775390625) });
constant spvUnsafeArray<float3, 6> _1047 = spvUnsafeArray<float3, 6>({ float3(0.0, 0.0, 1.0), float3(0.0, 0.0, -1.0), float3(-1.0, 0.0, 0.0), float3(-1.0, 0.0, 0.0), float3(-1.0, 0.0, 0.0), float3(1.0, 0.0, 0.0) });
constant spvUnsafeArray<float3, 6> _1056 = spvUnsafeArray<float3, 6>({ float3(0.0, 1.0, 0.0), float3(0.0, 1.0, 0.0), float3(0.0, 0.0, -1.0), float3(0.0, 0.0, 1.0), float3(0.0, 1.0, 0.0), float3(0.0, 1.0, 0.0) });
constant spvUnsafeArray<int3, 6> _1438 = spvUnsafeArray<int3, 6>({ int3(0, 256, 128), int3(32768, 128, 64), int3(40960, 64, 32), int3(43008, 32, 16), int3(43520, 16, 8), int3(43648, 8, 4) });
constant spvUnsafeArray<int4, 6> _2672 = spvUnsafeArray<int4, 6>({ int4(0, 0, 512, 256), int4(0, 256, 256, 128), int4(256, 256, 128, 64), int4(384, 256, 64, 32), int4(448, 256, 32, 16), int4(480, 256, 16, 8) });

struct fragment_main_out
{
    float4 outColor [[color(0)]];
    float2 outMotion [[color(1)]];
};

struct fragment_main_in
{
    float3 vWorldPos [[user(locn0)]];
    float3 vNormal [[user(locn1)]];
    float2 vUV [[user(locn2)]];
    float4 vColor [[user(locn3)]];
    float4 vParams [[user(locn5)]];
    float4 vCurrentClip [[user(locn6)]];
    float4 vPreviousClip [[user(locn7)]];
    float4 vTangent [[user(locn8)]];
};

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
        float3 _404 = float3(fast::clamp(uv, bounds.xy, bounds.zw), ref);
        return spvDepthCast(shadowMap).sample_compare(shadowMapSmplr, _404.xy, _404.z);
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
            float3 _557 = float3(tap, ref);
            sum += ((w[i].x * w[j].y) * spvDepthCast(shadowMap).sample_compare(shadowMapSmplr, _557.xy, _557.z));
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
    bool _617 = local.x < 0.0;
    bool _624;
    if (!_617)
    {
        _624 = local.x > 1.0;
    }
    else
    {
        _624 = _617;
    }
    bool _631;
    if (!_624)
    {
        _631 = local.y < 0.0;
    }
    else
    {
        _631 = _624;
    }
    bool _638;
    if (!_631)
    {
        _638 = local.y > 1.0;
    }
    else
    {
        _638 = _631;
    }
    if (_638)
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
        bool _701 = c < (count - 1);
        bool _710;
        if (_701)
        {
            _710 = depth > frame.cascadeSplits[c];
        }
        else
        {
            _710 = _701;
        }
        if (_710)
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
    float3 t = _743[c];
    float start = frame.cascadeBlendStarts[c];
    if (depth > start)
    {
        float f = (depth - start) / (frame.cascadeSplits[c] - start);
        if ((c + 1) < count)
        {
            int param_2 = c + 1;
            float3 param_3 = p + (ng * frame.cascadeNormalOffsets[c + 1]);
            s = mix(s, cascadeShadow(param_2, param_3, frame, shadowMap, shadowMapSmplr), f);
            t = mix(t, _743[c + 1], float3(f));
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
float3 environmentIrradiance(thread const float3& n, sampler materialSampler, constant Frame& frame, texture2d<float> environmentAtlas)
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
float3 hemisphere(thread const float3& d, constant Frame& frame)
{
    return mix(frame.groundColor.xyz, frame.skyColor.xyz, float3((d.y * 0.5) + 0.5)) * frame.skyColor.w;
}

static inline __attribute__((always_inline))
float4 probeVec4(thread const int& i, const device ProbeData& probeData)
{
    return as_type<float4>(probeData.words[i]);
}

static inline __attribute__((always_inline))
float3 probeLocal(thread const int& record, thread const float3& p, const device ProbeData& probeData)
{
    int param = record;
    float4 r0 = probeVec4(param, probeData);
    int param_1 = record + 1;
    float4 r1 = probeVec4(param_1, probeData);
    int param_2 = record + 2;
    float4 r2 = probeVec4(param_2, probeData);
    return float3(dot(r0.xyz, p) + r0.w, dot(r1.xyz, p) + r1.w, dot(r2.xyz, p) + r2.w);
}

static inline __attribute__((always_inline))
float probeInfluence(thread const float3& q, thread const float3& halfExtents, thread const float& blend)
{
    float3 d = halfExtents - abs(q);
    float inside = fast::min(d.x, fast::min(d.y, d.z));
    if (inside <= 0.0)
    {
        return 0.0;
    }
    if (blend <= 0.0)
    {
        return 1.0;
    }
    float t = fast::min(inside / blend, 1.0);
    return (t * t) * (3.0 - (2.0 * t));
}

static inline __attribute__((always_inline))
int probeInt(thread const int& i, const device ProbeData& probeData)
{
    return int(((device uint*)&probeData.words[i])[0u]);
}

static inline __attribute__((always_inline))
float3 probeLocalDirection(thread const int& record, thread const float3& d, const device ProbeData& probeData)
{
    int param = record;
    int param_1 = record + 1;
    int param_2 = record + 2;
    return float3(dot(probeVec4(param, probeData).xyz, d), dot(probeVec4(param_1, probeData).xyz, d), dot(probeVec4(param_2, probeData).xyz, d));
}

static inline __attribute__((always_inline))
ProbeBasis probeBasis(thread const float3& d)
{
    ProbeBasis y;
    y.a = float4(0.2820949852466583251953125, 0.48860299587249755859375 * d.y, 0.48860299587249755859375 * d.z, 0.48860299587249755859375 * d.x);
    y.b = float4((1.09254801273345947265625 * d.x) * d.y, (1.09254801273345947265625 * d.y) * d.z, 0.3153919875621795654296875 * (((3.0 * d.z) * d.z) - 1.0), (1.09254801273345947265625 * d.x) * d.z);
    y.c = 0.546274006366729736328125 * ((d.x * d.x) - (d.y * d.y));
    return y;
}

static inline __attribute__((always_inline))
bool probeValid(thread const int& first, const device ProbeData& probeData)
{
    return float2(as_type<half2>(((device uint*)&probeData.words[first + 3])[1u])).y > 0.5;
}

static inline __attribute__((always_inline))
float3 probeSHDot(thread const int& first, thread const ProbeBasis& y, const device ProbeData& probeData)
{
    uint4 a = probeData.words[first];
    uint4 b = probeData.words[first + 1];
    uint4 d = probeData.words[first + 2];
    uint4 e = probeData.words[first + 3];
    float2 h0 = float2(as_type<half2>(a.x));
    float2 h1 = float2(as_type<half2>(a.y));
    float2 h2 = float2(as_type<half2>(a.z));
    float2 h3 = float2(as_type<half2>(a.w));
    float2 h4 = float2(as_type<half2>(b.x));
    float2 h5 = float2(as_type<half2>(b.y));
    float2 h6 = float2(as_type<half2>(b.z));
    float2 h7 = float2(as_type<half2>(b.w));
    float2 h8 = float2(as_type<half2>(d.x));
    float2 h9 = float2(as_type<half2>(d.y));
    float2 h10 = float2(as_type<half2>(d.z));
    float2 h11 = float2(as_type<half2>(d.w));
    float2 h12 = float2(as_type<half2>(e.x));
    float2 h13 = float2(as_type<half2>(e.y));
    float3 _2118 = (((((((float3(h0, h1.x) * y.a.x) + (float3(h1.y, h2) * y.a.y)) + (float3(h3, h4.x) * y.a.z)) + (float3(h4.y, h5) * y.a.w)) + (float3(h6, h7.x) * y.b.x)) + (float3(h7.y, h8) * y.b.y)) + (float3(h9, h10.x) * y.b.z)) + (float3(h10.y, h11) * y.b.w);
    return _2118 + (float3(h12, h13.x) * y.c);
}

static inline __attribute__((always_inline))
float4 probeCorner(thread const int3& o, thread const int3& g0, thread const int3& nc, thread const float3& f, thread const float3& cells, thread const float3& halfExtents, thread const float3& q, thread const float3& nl, thread const int& shFirst, thread const ProbeBasis& y, const device ProbeData& probeData)
{
    int3 cell = min((g0 + o), (nc - int3(1)));
    int sh = shFirst + ((cell.x + (nc.x * (cell.y + (nc.y * cell.z)))) * 4);
    float3 t = mix(float3(1.0) - f, f, float3(o));
    float3 toProbe = ((-halfExtents) + ((((float3(cell) + float3(0.5)) / cells) * halfExtents) * 2.0)) - q;
    float b = (dot(toProbe * rsqrt(fast::max(dot(toProbe, toProbe), 1.0000000133514319600180897396058e-10)), nl) + 1.0) * 0.5;
    int param = sh;
    float weight = (((t.x * t.y) * t.z) * ((b * b) + 0.20000000298023223876953125)) * float(probeValid(param, probeData));
    int param_1 = sh;
    ProbeBasis param_2 = y;
    return float4(probeSHDot(param_1, param_2, probeData) * weight, weight);
}

static inline __attribute__((always_inline))
float3 probeIrradiance(thread const float3& fallback, thread const float3& p, thread const float3& n, thread const float3& v, constant Frame& frame, const device ProbeData& probeData)
{
    int volumes = int(frame.probes.y);
    int firstRecord = int(frame.probes.x) * 8;
    float3 result = fallback;
    for (int j = 0; j < volumes; j++)
    {
        int record = firstRecord + (j * 8);
        int param = record + 3;
        float4 box = probeVec4(param, probeData);
        int param_1 = record;
        float3 param_2 = p;
        float3 q = probeLocal(param_1, param_2, probeData);
        float3 param_3 = q;
        float3 param_4 = box.xyz;
        float param_5 = box.w;
        float w = probeInfluence(param_3, param_4, param_5);
        if (w <= 0.0)
        {
            continue;
        }
        int param_6 = record + 4;
        float3 cells = probeVec4(param_6, probeData).xyz;
        int param_7 = record + 5;
        float4 bias0 = probeVec4(param_7, probeData);
        int param_8 = record + 6;
        int shFirst = probeInt(param_8, probeData);
        int param_9 = record;
        float3 param_10 = n;
        float3 nl = probeLocalDirection(param_9, param_10, probeData);
        int param_11 = record;
        float3 param_12 = (p + (n * bias0.x)) + (v * bias0.y);
        float3 qb = probeLocal(param_11, param_12, probeData);
        float3 g = fast::clamp((((qb + box.xyz) / fast::max(box.xyz * 2.0, float3(9.9999999747524270787835121154785e-07))) * cells) - float3(0.5), float3(0.0), cells - float3(1.0));
        int3 nc = int3(cells);
        int3 g0 = min(int3(g), max((nc - int3(2)), int3(0)));
        float3 f = g - float3(g0);
        float3 param_13 = nl;
        ProbeBasis y = probeBasis(param_13);
        float4 acc = float4(0.0);
        int3 param_14 = int3(0);
        int3 param_15 = g0;
        int3 param_16 = nc;
        float3 param_17 = f;
        float3 param_18 = cells;
        float3 param_19 = box.xyz;
        float3 param_20 = q;
        float3 param_21 = nl;
        int param_22 = shFirst;
        ProbeBasis param_23 = y;
        acc += probeCorner(param_14, param_15, param_16, param_17, param_18, param_19, param_20, param_21, param_22, param_23, probeData);
        int3 param_24 = int3(1, 0, 0);
        int3 param_25 = g0;
        int3 param_26 = nc;
        float3 param_27 = f;
        float3 param_28 = cells;
        float3 param_29 = box.xyz;
        float3 param_30 = q;
        float3 param_31 = nl;
        int param_32 = shFirst;
        ProbeBasis param_33 = y;
        acc += probeCorner(param_24, param_25, param_26, param_27, param_28, param_29, param_30, param_31, param_32, param_33, probeData);
        int3 param_34 = int3(0, 1, 0);
        int3 param_35 = g0;
        int3 param_36 = nc;
        float3 param_37 = f;
        float3 param_38 = cells;
        float3 param_39 = box.xyz;
        float3 param_40 = q;
        float3 param_41 = nl;
        int param_42 = shFirst;
        ProbeBasis param_43 = y;
        acc += probeCorner(param_34, param_35, param_36, param_37, param_38, param_39, param_40, param_41, param_42, param_43, probeData);
        int3 param_44 = int3(1, 1, 0);
        int3 param_45 = g0;
        int3 param_46 = nc;
        float3 param_47 = f;
        float3 param_48 = cells;
        float3 param_49 = box.xyz;
        float3 param_50 = q;
        float3 param_51 = nl;
        int param_52 = shFirst;
        ProbeBasis param_53 = y;
        acc += probeCorner(param_44, param_45, param_46, param_47, param_48, param_49, param_50, param_51, param_52, param_53, probeData);
        int3 param_54 = int3(0, 0, 1);
        int3 param_55 = g0;
        int3 param_56 = nc;
        float3 param_57 = f;
        float3 param_58 = cells;
        float3 param_59 = box.xyz;
        float3 param_60 = q;
        float3 param_61 = nl;
        int param_62 = shFirst;
        ProbeBasis param_63 = y;
        acc += probeCorner(param_54, param_55, param_56, param_57, param_58, param_59, param_60, param_61, param_62, param_63, probeData);
        int3 param_64 = int3(1, 0, 1);
        int3 param_65 = g0;
        int3 param_66 = nc;
        float3 param_67 = f;
        float3 param_68 = cells;
        float3 param_69 = box.xyz;
        float3 param_70 = q;
        float3 param_71 = nl;
        int param_72 = shFirst;
        ProbeBasis param_73 = y;
        acc += probeCorner(param_64, param_65, param_66, param_67, param_68, param_69, param_70, param_71, param_72, param_73, probeData);
        int3 param_74 = int3(0, 1, 1);
        int3 param_75 = g0;
        int3 param_76 = nc;
        float3 param_77 = f;
        float3 param_78 = cells;
        float3 param_79 = box.xyz;
        float3 param_80 = q;
        float3 param_81 = nl;
        int param_82 = shFirst;
        ProbeBasis param_83 = y;
        acc += probeCorner(param_74, param_75, param_76, param_77, param_78, param_79, param_80, param_81, param_82, param_83, probeData);
        int3 param_84 = int3(1);
        int3 param_85 = g0;
        int3 param_86 = nc;
        float3 param_87 = f;
        float3 param_88 = cells;
        float3 param_89 = box.xyz;
        float3 param_90 = q;
        float3 param_91 = nl;
        int param_92 = shFirst;
        ProbeBasis param_93 = y;
        acc += probeCorner(param_84, param_85, param_86, param_87, param_88, param_89, param_90, param_91, param_92, param_93, probeData);
        float3 sum = acc.xyz;
        float total = acc.w;
        if (total > 9.9999997473787516355514526367188e-06)
        {
            result = mix(result, (fast::max(sum, float3(0.0)) / float3(total)) * bias0.z, float3(w));
        }
    }
    return result;
}

static inline __attribute__((always_inline))
uint2 clusterLights(constant Frame& frame, thread float3& vWorldPos, thread float4& gl_FragCoord, constant LightCells& lightCells)
{
    float depth = dot(frame.viewDepth.xyz, vWorldPos) + frame.viewDepth.w;
    float2 tile = fast::clamp(floor(gl_FragCoord.xy * frame.clusterScale.xy), float2(0.0), frame.clusterGrid.xy - float2(1.0));
    float slice = fast::clamp(floor((log2(fast::max(depth, 9.9999999747524270787835121154785e-07)) * frame.clusterScale.z) + frame.clusterScale.w), 0.0, frame.clusterGrid.z - 1.0);
    uint cluster = uint((((slice * frame.clusterGrid.y) + tile.y) * frame.clusterGrid.x) + tile.x);
    uint cell = lightCells.data[cluster >> uint(2)][cluster & 3u];
    return uint2(cell & 65535u, cell >> uint(16));
}

static inline __attribute__((always_inline))
uint lightIndex(thread const uint& i, constant LightIndices& lightIndices)
{
    uint word = i / 3u;
    return (lightIndices.data[word >> uint(2)][word & 3u] >> ((i - (word * 3u)) * 10u)) & 1023u;
}

static inline __attribute__((always_inline))
float3 punctualRadiance(thread const uint& i, thread float3& l, constant LightPositions& lightPositions, thread float3& vWorldPos, constant LightColors& lightColors, constant LightDirections& lightDirections)
{
    float4 position = lightPositions.data[i];
    float3 toLight = position.xyz - vWorldPos;
    float d2 = dot(toLight, toLight);
    float x = d2 * position.w;
    float window = fast::clamp(1.0 - (x * x), 0.0, 1.0);
    l = toLight * rsqrt(fast::max(d2, 9.9999999392252902907785028219223e-09));
    float4 color = lightColors.data[i];
    float4 direction = lightDirections.data[i];
    float cone = fast::clamp((dot(-l, direction.xyz) * color.w) + direction.w, 0.0, 1.0);
    return color.xyz * ((((window * window) * cone) * cone) / fast::max(d2, 9.9999997473787516355514526367188e-05));
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
        bool _887 = local.x < 0.0;
        bool _894;
        if (!_887)
        {
            _894 = local.x > 1.0;
        }
        else
        {
            _894 = _887;
        }
        bool _901;
        if (!_894)
        {
            _901 = local.y < 0.0;
        }
        else
        {
            _901 = _894;
        }
        bool _908;
        if (!_901)
        {
            _908 = local.y > 1.0;
        }
        else
        {
            _908 = _901;
        }
        bool _915;
        if (!_908)
        {
            _915 = local.z > 1.0;
        }
        else
        {
            _915 = _908;
        }
        if (_915)
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
    bool _991 = a.x >= a.y;
    bool _999;
    if (_991)
    {
        _999 = a.x >= a.z;
    }
    else
    {
        _999 = _991;
    }
    int face;
    float m;
    if (_999)
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
    float2 st = float2(dot(d, _1047[face]), dot(d, _1056[face])) / float2(m * frame.shadowFaces.z);
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
float2 environmentBRDFTable(thread const float& NoV, thread const float& roughness, texture2d<float> brdfTable, sampler brdfSampler)
{
    float2 uv = ((float2(NoV, roughness) * 31.0) + float2(0.5)) / float2(32.0);
    return brdfTable.sample(brdfSampler, uv).xy;
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
    int _1212;
    if ((x0 + 1) == region.z)
    {
        _1212 = 0;
    }
    else
    {
        _1212 = x0 + 1;
    }
    int x1 = _1212;
    int y1 = min((y0 + 1), (region.w - 1));
    y0 = max(y0, 0);
    float3 a = image.read(uint2((region.xy + int2(x0, y0))), 0).xyz;
    float3 b = image.read(uint2((region.xy + int2(x1, y0))), 0).xyz;
    float3 c = image.read(uint2((region.xy + int2(x0, y1))), 0).xyz;
    float3 d = image.read(uint2((region.xy + int2(x1, y1))), 0).xyz;
    return mix(mix(a, b, float3(t.x)), mix(c, d, float3(t.x)), float3(t.y));
}

static inline __attribute__((always_inline))
float3 environmentRadiance(thread const float3& d, thread const float& roughness, sampler materialSampler, constant Frame& frame, texture2d<float> environmentAtlas)
{
    float3 param = d;
    float2 param_1 = frame.environment.zw;
    float3 param_2 = environmentDirection(param, param_1);
    float2 uv = equirectUV(param_2);
    float level0 = roughness * 5.0;
    int i = min(int(level0), 4);
    int4 param_3 = _2672[i];
    float2 param_4 = uv;
    float3 a = sampleEquirect(environmentAtlas, materialSampler, param_3, param_4);
    int4 param_5 = _2672[i + 1];
    float2 param_6 = uv;
    float3 b = sampleEquirect(environmentAtlas, materialSampler, param_5, param_6);
    return mix(a, b, float3(level0 - float(i))) * frame.environment.y;
}

static inline __attribute__((always_inline))
float2 environmentBRDF(thread const float& NoV, thread const float& roughness)
{
    float4 r = (float4(-1.0, -0.0274999998509883880615234375, -0.572000026702880859375, 0.02199999988079071044921875) * roughness) + float4(1.0, 0.0425000004470348358154296875, 1.03999996185302734375, -0.039999999105930328369140625);
    float a004 = (fast::min(r.x * r.x, exp2((-9.27999973297119140625) * NoV)) * r.x) + r.y;
    return (float2(-1.03999996185302734375, 1.03999996185302734375) * a004) + r.zw;
}

static inline __attribute__((always_inline))
float3 probeBoxProjected(thread const float3& q, thread const float3& r, thread const float3& halfExtents, thread const float3& capture)
{
    float3 o = fast::clamp(q, -halfExtents, halfExtents);
    float3 planes = mix(-halfExtents, halfExtents, step(float3(0.0), r));
    float3 safe = mix(float3(9.9999999747524270787835121154785e-07), r, step(float3(9.9999999747524270787835121154785e-07), abs(r)));
    float3 ts = mix(float3(1000000015047466219876688855040.0), (planes - o) / safe, step(float3(9.9999999747524270787835121154785e-07), abs(r)));
    float t = fast::max(fast::min(ts.x, fast::min(ts.y, ts.z)), 0.0);
    float3 d = (o + (r * t)) - capture;
    float3 _1765;
    if (dot(d, d) > 9.9999999600419720025001879548654e-13)
    {
        _1765 = fast::normalize(d);
    }
    else
    {
        _1765 = r;
    }
    return _1765;
}

static inline __attribute__((always_inline))
float3 probeTexel(thread const int& first, thread const int& x, thread const int& y, thread const int& width, const device ProbeData& probeData)
{
    int t = (first + (y * width)) + x;
    uint4 pair = probeData.words[t >> 1];
    uint2 _1400;
    if ((t & 1) == 0)
    {
        _1400 = pair.xy;
    }
    else
    {
        _1400 = pair.zw;
    }
    uint2 texel = _1400;
    return float3(float2(as_type<half2>(texel.x)), float2(as_type<half2>(texel.y)).x);
}

static inline __attribute__((always_inline))
float3 sampleProbeLevel(thread const int& image, thread const int& level0, thread const float2& uv, const device ProbeData& probeData)
{
    int3 l = _1438[level0];
    int first = image + l.x;
    float2 p = (uv * float2(l.yz)) - float2(0.5);
    float2 f = floor(p);
    float2 t = p - f;
    int x0 = int(f.x);
    int y0 = int(f.y);
    if (x0 < 0)
    {
        x0 += l.y;
    }
    if (x0 >= l.y)
    {
        x0 -= l.y;
    }
    int _1496;
    if ((x0 + 1) == l.y)
    {
        _1496 = 0;
    }
    else
    {
        _1496 = x0 + 1;
    }
    int x1 = _1496;
    int y1 = min((y0 + 1), (l.z - 1));
    y0 = max(y0, 0);
    int param = first;
    int param_1 = x0;
    int param_2 = y0;
    int param_3 = l.y;
    float3 a = probeTexel(param, param_1, param_2, param_3, probeData);
    int param_4 = first;
    int param_5 = x1;
    int param_6 = y0;
    int param_7 = l.y;
    float3 b = probeTexel(param_4, param_5, param_6, param_7, probeData);
    int param_8 = first;
    int param_9 = x0;
    int param_10 = y1;
    int param_11 = l.y;
    float3 c = probeTexel(param_8, param_9, param_10, param_11, probeData);
    int param_12 = first;
    int param_13 = x1;
    int param_14 = y1;
    int param_15 = l.y;
    float3 d = probeTexel(param_12, param_13, param_14, param_15, probeData);
    return mix(mix(a, b, float3(t.x)), mix(c, d, float3(t.x)), float3(t.y));
}

static inline __attribute__((always_inline))
float3 probeImageRadiance(thread const int& image, thread const float3& d, thread const float& roughness, const device ProbeData& probeData)
{
    float3 param = d;
    float2 uv = equirectUV(param);
    float level0 = roughness * 5.0;
    int i = min(int(level0), 4);
    int param_1 = image;
    int param_2 = i;
    float2 param_3 = uv;
    int param_4 = image;
    int param_5 = i + 1;
    float2 param_6 = uv;
    return mix(sampleProbeLevel(param_1, param_2, param_3, probeData), sampleProbeLevel(param_4, param_5, param_6, probeData), float3(level0 - float(i)));
}

static inline __attribute__((always_inline))
float3 probeReflection(thread const float3& fallback, thread const float3& p, thread const float3& r, thread const float& roughness, constant Frame& frame, const device ProbeData& probeData)
{
    int count = int(frame.probes.x);
    float3 sum = float3(0.0);
    float total = 0.0;
    float3 _1846;
    for (int i = 0; i < count; i++)
    {
        if (total > 0.999000012874603271484375)
        {
            break;
        }
        int record = i * 8;
        int param = record;
        float3 param_1 = p;
        float3 q = probeLocal(param, param_1, probeData);
        int param_2 = record + 3;
        float4 influence = probeVec4(param_2, probeData);
        float3 param_3 = q;
        float3 param_4 = influence.xyz;
        float param_5 = influence.w;
        float w = probeInfluence(param_3, param_4, param_5);
        if (w <= 0.0)
        {
            continue;
        }
        int param_6 = record + 4;
        float4 projection = probeVec4(param_6, probeData);
        int param_7 = record + 5;
        float4 capture = probeVec4(param_7, probeData);
        int param_8 = record;
        float3 param_9 = r;
        float3 rl = probeLocalDirection(param_8, param_9, probeData);
        if (projection.w > 0.5)
        {
            float3 param_10 = q;
            float3 param_11 = rl;
            float3 param_12 = projection.xyz;
            float3 param_13 = capture.xyz;
            _1846 = probeBoxProjected(param_10, param_11, param_12, param_13);
        }
        else
        {
            _1846 = rl;
        }
        float3 d = _1846;
        int param_14 = record + 6;
        int param_15 = probeInt(param_14, probeData);
        float3 param_16 = d;
        float param_17 = roughness;
        float3 c = probeImageRadiance(param_15, param_16, param_17, probeData) * capture.w;
        float a = w * (1.0 - total);
        sum += (c * a);
        total += a;
    }
    return sum + (fallback * (1.0 - total));
}

static inline __attribute__((always_inline))
float3 planarReflected(thread const float3& fallback, thread const float3& n, thread const float3& ng, thread const float& roughness, sampler materialSampler, texture2d<float> occlusionMap, constant Frame& frame, thread float3& vWorldPos)
{
    float3 pn = frame.reflectionPlane.xyz;
    float tolerance = frame.reflectionExtra.x;
    float onPlane = 1.0 - smoothstep(tolerance * 0.5, tolerance, abs(dot(pn, vWorldPos) - frame.reflectionPlane.w));
    float facing = smoothstep(0.5, 0.89999997615814208984375, dot(ng, pn));
    float glossy = 1.0 - smoothstep(frame.reflectionParams.y * 0.5, frame.reflectionParams.y, roughness);
    float weight = ((frame.reflectionParams.x * onPlane) * facing) * glossy;
    if (weight <= 0.0)
    {
        return fallback;
    }
    float3 p = vWorldPos + ((n - (pn * dot(n, pn))) * frame.reflectionParams.w);
    float4 clip = frame.reflectionViewProj * float4(p, 1.0);
    float2 uv = ((float2(clip.x, -clip.y) / float2(clip.w)) * 0.5) + float2(0.5);
    float radius = frame.reflectionParams.z * roughness;
    float3 sum = float3(0.0);
    float coverage = 0.0;
    for (int i = 0; i < 12; i++)
    {
        float r = sqrt((float(i) + 0.5) / 12.0) * radius;
        float a = float(i) * 2.3999631404876708984375;
        float2 tap = uv + (float2(cos(a) * frame.reflectionExtra.y, sin(a)) * r);
        float2 inside = fast::min(tap, float2(1.0) - tap);
        float edge = smoothstep(0.0, 0.039999999105930328369140625, fast::min(inside.x, inside.y));
        float4 t = occlusionMap.sample(materialSampler, fast::clamp(tap, float2(0.0), float2(1.0)), level(0.0));
        sum += ((t.xyz / (float3(1.0) - fast::min(t.xyz, float3(0.99500000476837158203125)))) * edge);
        coverage += (t.w * edge);
    }
    float3 planar = (sum / float3(12.0)) + (fallback * (1.0 - (coverage / 12.0)));
    return mix(fallback, planar, float3(weight));
}

static inline __attribute__((always_inline))
float2 motionVector(thread const float4& current, thread const float4& previous)
{
    if (previous.w <= 0.0)
    {
        return float2(0.0);
    }
    return ((previous.xy / float2(previous.w)) - (current.xy / float2(current.w))) * float2(0.5, -0.5);
}

fragment fragment_main_out fragment_main(fragment_main_in in [[stage_in]], constant MaterialData& material [[buffer(2)]], constant LightPositions& lightPositions [[buffer(3)]], constant LightColors& lightColors [[buffer(4)]], constant LightDirections& lightDirections [[buffer(5)]], constant LightCells& lightCells [[buffer(6)]], constant LightIndices& lightIndices [[buffer(7)]], constant Frame& frame [[buffer(15)]], constant MaterialGraphPush& graphPush [[buffer(16)]], const device MaterialGraphValues& graphValues [[buffer(20)]], const device ProbeData& probeData [[buffer(21)]], texture2d<float> shadowMap [[texture(0)]], texture2d<float> baseColorMap [[texture(1)]], texture2d<float> metallicRoughnessMap [[texture(2)]], texture2d<float> normalMap [[texture(3)]], texture2d<float> occlusionMap [[texture(4)]], texture2d<float> emissiveMap [[texture(5)]], texture2d<float> environmentAtlas [[texture(6)]], texture2d<float> brdfTable [[texture(7)]], sampler shadowMapSmplr [[sampler(0)]], sampler materialSampler [[sampler(1)]], sampler brdfSampler [[sampler(7)]], float4 gl_FragCoord [[position]], bool gl_FrontFacing [[front_facing]])
{
    fragment_main_out out = {};
    float2 gUV = in.vUV;
    float3 gPosition = in.vWorldPos;
    float3 gNormal = fast::normalize(in.vNormal);
    float3 gView = fast::normalize(frame.cameraPos.xyz - in.vWorldPos);
    float4 gVertexColor = in.vColor;
    float gTime = graphPush.params.x;
    float3 gBaseColor;
    float gOpacity;
    float3 gNormalTS;
    float gMetallic;
    float gRoughness;
    float3 gEmissive;
    float gOcclusion;
    graphSurface(baseColorMap, materialSampler, gUV, metallicRoughnessMap, normalMap, occlusionMap, emissiveMap, graphValues, gBaseColor, gVertexColor, gPosition, gNormal, gView, gTime, gOpacity, gNormalTS, gMetallic, gRoughness, gEmissive, gOcclusion);
    float3 albedo = in.vColor.xyz * fast::max(gBaseColor, float3(0.0));
    float opacity = in.vColor.w * fast::clamp(gOpacity, 0.0, 1.0);
    if (graphPush.params.y > 0.5)
    {
        if (gOpacity < graphPush.params.z)
        {
            discard_fragment();
        }
        opacity = in.vColor.w;
    }
    float3 n = fast::normalize(in.vNormal);
    float3 gt = in.vTangent.xyz - (n * dot(n, in.vTangent.xyz));
    bool _3275 = dot(gt, gt) > 9.9999999600419720025001879548654e-13;
    bool _3282;
    if (_3275)
    {
        _3282 = dot(gNormalTS, gNormalTS) > 9.9999999600419720025001879548654e-13;
    }
    else
    {
        _3282 = _3275;
    }
    if (_3282)
    {
        gt = fast::normalize(gt);
        float3 gb = cross(n, gt) * ((in.vTangent.w < 0.0) ? (-1.0) : 1.0);
        float3 m = fast::normalize(gNormalTS);
        n = fast::normalize(((gt * m.x) + (gb * m.y)) + (n * m.z));
    }
    bool pbr = material.emissive.w > 0.5;
    float _3324;
    if (pbr)
    {
        _3324 = fast::clamp(material.params.z, 0.0, 1.0);
    }
    else
    {
        _3324 = 0.0;
    }
    float translucency = _3324;
    bool _3339;
    if (pbr)
    {
        _3339 = !gl_FrontFacing;
    }
    else
    {
        _3339 = pbr;
    }
    if (_3339 && (translucency <= 0.0))
    {
        n = -n;
    }
    float3 l = fast::normalize(frame.lightDir.xyz);
    float3 v = fast::normalize(frame.cameraPos.xyz - in.vWorldPos);
    float3 h = fast::normalize(l + v);
    float3 ng = fast::normalize(in.vNormal) * (gl_FrontFacing ? 1.0 : (-1.0));
    bool receivesShadows = in.vParams.x > 0.5;
    float shadow = 1.0;
    if ((frame.lightColor.w > 0.5) && receivesShadows)
    {
        float3 param = in.vWorldPos;
        float3 param_1 = ng;
        float3 param_2;
        float _3389 = directionalShadow(param, param_1, param_2, frame, shadowMap, shadowMapSmplr);
        float3 cascadeTint = param_2;
        shadow = _3389;
        albedo *= cascadeTint;
    }
    float3 light = frame.lightColor.xyz * frame.lightDir.w;
    float ao = fast::clamp(gOcclusion, 0.0, 1.0);
    float vertexAO = abs(in.vTangent.w);
    if (vertexAO > 0.0)
    {
        ao *= fast::min(vertexAO, 1.0);
    }
    float3 indirect;
    float3 color;
    if (!pbr)
    {
        float ndotl = dot(n, l);
        float3 diffuse = light * fast::max(ndotl, 0.0);
        float3 specular = light * ((powr(fast::max(dot(n, h), 0.0), material.params.w) * material.params.z) * step(0.0, ndotl));
        float3 _3449;
        if (frame.environment.x > 0.5)
        {
            float3 param_3 = n;
            _3449 = environmentIrradiance(param_3, materialSampler, frame, environmentAtlas);
        }
        else
        {
            float3 param_4 = n;
            _3449 = hemisphere(param_4, frame);
        }
        indirect = _3449;
        if (frame.probes.y > 0.5)
        {
            float3 param_5 = indirect;
            float3 param_6 = in.vWorldPos;
            float3 param_7 = n;
            float3 param_8 = v;
            indirect = probeIrradiance(param_5, param_6, param_7, param_8, frame, probeData);
        }
        float3 ambient = indirect * ao;
        color = (albedo * (ambient + (diffuse * shadow))) + (specular * shadow);
        if (frame.clusterGrid.w > 0.5)
        {
            uint2 cell = clusterLights(frame, in.vWorldPos, gl_FragCoord, lightCells);
            float3 param_11;
            for (uint i = cell.x; i < (cell.x + cell.y); i++)
            {
                uint param_9 = i;
                uint li = lightIndex(param_9, lightIndices);
                uint param_10 = li;
                float3 _3521 = punctualRadiance(param_10, param_11, lightPositions, in.vWorldPos, lightColors, lightDirections);
                float3 pl = param_11;
                float3 radiance = _3521;
                if (receivesShadows)
                {
                    uint param_12 = li;
                    float3 param_13 = in.vWorldPos;
                    float3 param_14 = ng;
                    float3 param_15 = pl;
                    radiance *= localShadow(param_12, param_13, param_14, param_15, frame, shadowMap, shadowMapSmplr);
                }
                float pndotl = dot(n, pl);
                float3 ph = fast::normalize(pl + v);
                color += (((albedo * fast::max(pndotl, 0.0)) * radiance) + (radiance * ((powr(fast::max(dot(n, ph), 0.0), material.params.w) * material.params.z) * step(0.0, pndotl))));
            }
        }
    }
    else
    {
        float metallic = fast::clamp(gMetallic, 0.0, 1.0);
        float roughness = fast::clamp(gRoughness, 0.04500000178813934326171875, 1.0);
        float a = roughness * roughness;
        float3 diffuseColor = albedo * (1.0 - metallic);
        float3 f0 = mix(float3(0.039999999105930328369140625), albedo, float3(metallic));
        float3 sn = n;
        if (translucency > 0.0)
        {
            float3 face = cross(dfdx(in.vWorldPos), dfdy(in.vWorldPos));
            if (dot(face, face) > 9.9999996826552253889678874634872e-21)
            {
                sn = fast::normalize((fast::normalize(face) * ((dot(face, v) < 0.0) ? (-1.0) : 1.0)) + (n - fast::normalize(in.vNormal)));
            }
        }
        float NoV = fast::max(dot(sn, v), 9.9999997473787516355514526367188e-05);
        float NoL = fast::clamp(dot(n, l), 0.0, 1.0);
        float sNoL = fast::clamp(dot(sn, l), 0.0, 1.0);
        float NoH = fast::clamp(dot(sn, h), 0.0, 1.0);
        float VoH = fast::clamp(dot(v, h), 0.0, 1.0);
        if (translucency > 0.0)
        {
            NoV = fast::max(NoV, 0.5);
            VoH = fast::max(VoH, 0.5);
        }
        float3 param_16 = f0;
        float param_17 = VoH;
        float3 F = fresnelSchlick(param_16, param_17);
        float param_18 = NoH;
        float param_19 = a;
        float param_20 = NoV;
        float param_21 = sNoL;
        float param_22 = a;
        float3 specular_1 = (F * (distributionGGX(param_18, param_19) * visibilitySmithGGXCorrelated(param_20, param_21, param_22))) * 3.1415927410125732421875;
        float3 direct = (((((float3(1.0) - F) * diffuseColor) * NoL) + (specular_1 * sNoL)) * light) * shadow;
        if (translucency > 0.0)
        {
            float through = fast::clamp(-dot(sn, l), 0.0, 1.0);
            float toward = powr(fast::clamp(dot(-v, l), 0.0, 1.0), 3.0);
            direct += (((((diffuseColor * light) * shadow) * translucency) * through) * (0.3499999940395355224609375 + (0.64999997615814208984375 * toward)));
        }
        float2 dfg;
        float3 irradiance;
        float3 reflected;
        if (frame.environment.x > 0.5)
        {
            float param_23 = NoV;
            float param_24 = roughness;
            dfg = environmentBRDFTable(param_23, param_24, brdfTable, brdfSampler);
            float3 param_25 = n;
            irradiance = environmentIrradiance(param_25, materialSampler, frame, environmentAtlas);
            float3 param_26 = reflect(-v, sn);
            float param_27 = roughness;
            reflected = environmentRadiance(param_26, param_27, materialSampler, frame, environmentAtlas);
        }
        else
        {
            float param_28 = NoV;
            float param_29 = roughness;
            dfg = environmentBRDF(param_28, param_29);
            float3 param_30 = n;
            irradiance = hemisphere(param_30, frame);
            float3 param_31 = reflect(-v, sn);
            reflected = mix(hemisphere(param_31, frame), irradiance, float3(roughness));
        }
        if (frame.probes.y > 0.5)
        {
            float3 param_32 = irradiance;
            float3 param_33 = in.vWorldPos;
            float3 param_34 = n;
            float3 param_35 = v;
            irradiance = probeIrradiance(param_32, param_33, param_34, param_35, frame, probeData);
        }
        if (frame.probes.x > 0.5)
        {
            float3 param_36 = reflected;
            float3 param_37 = in.vWorldPos;
            float3 param_38 = reflect(-v, sn);
            float param_39 = roughness;
            reflected = probeReflection(param_36, param_37, param_38, param_39, frame, probeData);
        }
        indirect = irradiance;
        bool _3810 = material.flags.w > 0.5;
        bool _3816;
        if (_3810)
        {
            _3816 = frame.reflectionExtra.z > 0.5;
        }
        else
        {
            _3816 = _3810;
        }
        if (_3816)
        {
            float3 param_40 = reflected;
            float3 param_41 = n;
            float3 param_42 = ng;
            float param_43 = roughness;
            reflected = planarReflected(param_40, param_41, param_42, param_43, materialSampler, occlusionMap, frame, in.vWorldPos);
        }
        float3 specularAmbient = (f0 * dfg.x) + float3(dfg.y);
        float3 ambient_1 = ((((float3(1.0) - specularAmbient) * diffuseColor) * irradiance) + (specularAmbient * reflected)) * ao;
        color = direct + ambient_1;
        if (frame.clusterGrid.w > 0.5)
        {
            uint2 cell_1 = clusterLights(frame, in.vWorldPos, gl_FragCoord, lightCells);
            float3 param_46;
            for (uint i_1 = cell_1.x; i_1 < (cell_1.x + cell_1.y); i_1++)
            {
                uint param_44 = i_1;
                uint li_1 = lightIndex(param_44, lightIndices);
                uint param_45 = li_1;
                float3 _3884 = punctualRadiance(param_45, param_46, lightPositions, in.vWorldPos, lightColors, lightDirections);
                float3 pl_1 = param_46;
                float3 radiance_1 = _3884;
                if (receivesShadows)
                {
                    uint param_47 = li_1;
                    float3 param_48 = in.vWorldPos;
                    float3 param_49 = ng;
                    float3 param_50 = pl_1;
                    radiance_1 *= localShadow(param_47, param_48, param_49, param_50, frame, shadowMap, shadowMapSmplr);
                }
                float3 ph_1 = fast::normalize(pl_1 + v);
                float pNoL = fast::clamp(dot(n, pl_1), 0.0, 1.0);
                float pNoH = fast::clamp(dot(n, ph_1), 0.0, 1.0);
                float3 param_51 = f0;
                float param_52 = fast::clamp(dot(v, ph_1), 0.0, 1.0);
                float3 pF = fresnelSchlick(param_51, param_52);
                float param_53 = pNoH;
                float param_54 = a;
                float param_55 = NoV;
                float param_56 = pNoL;
                float param_57 = a;
                float3 pSpecular = (pF * (distributionGGX(param_53, param_54) * visibilitySmithGGXCorrelated(param_55, param_56, param_57))) * 3.1415927410125732421875;
                color += (((((float3(1.0) - pF) * diffuseColor) + pSpecular) * pNoL) * radiance_1);
            }
        }
    }
    color = mix(color, albedo, float3(material.params.y));
    color += (fast::max(gEmissive, float3(0.0)) * (float3(1.0) + in.vParams.yzw));
    float dist = length(frame.cameraPos.xyz - in.vWorldPos);
    float fog = 1.0 - exp((-dist) * frame.fogColor.w);
    if (frame.groundColor.w != 0.0)
    {
        float k = frame.groundColor.w;
        float3 toEye = in.vWorldPos - frame.cameraPos.xyz;
        float x = k * toEye.y;
        float _4007;
        if (abs(x) < 9.9999997473787516355514526367188e-05)
        {
            _4007 = 1.0 - (0.5 * x);
        }
        else
        {
            _4007 = (1.0 - exp(fast::min(-x, 60.0))) / x;
        }
        float span = _4007;
        float atEye = frame.fogColor.w * exp(fast::min((-k) * (frame.cameraPos.y - frame.cameraPos.w), 30.0));
        fog = 1.0 - exp(((-dist) * atEye) * span);
    }
    if (frame.probes.z > 0.5)
    {
        color = indirect * ao;
        fog = 0.0;
    }
    float3 rgb = mix(color, frame.fogColor.xyz, float3(fog));
    if (frame.reflectionExtra.w > 0.5)
    {
        rgb /= (float3(1.0) + rgb);
    }
    out.outColor = float4(rgb, opacity);
    float4 param_58 = in.vCurrentClip;
    float4 param_59 = in.vPreviousClip;
    out.outMotion = motionVector(param_58, param_59);
    return out;
}

