// Generated from mesh_graph.frag by Scripts/compile-shaders.sh — do not edit.
// Edit the GLSL and rerun the script (needs glslc, spirv-cross, spirv-opt and naga-cli).
// spirv-fnv1a64: 62bc8e7f643170fb
// glsl-fnv1a64: c60a0588c23b5f97

diagnostic(off, derivative_uniformity);

struct MaterialGraphValues {
    values: array<vec4<f32>>,
}

struct Frame {
    viewProj: mat4x4<f32>,
    lightViewProj: mat4x4<f32>,
    currentViewProj: mat4x4<f32>,
    previousViewProj: mat4x4<f32>,
    lightDir: vec4<f32>,
    lightColor: vec4<f32>,
    cameraPos: vec4<f32>,
    fogColor: vec4<f32>,
    skyColor: vec4<f32>,
    groundColor: vec4<f32>,
    shadowParams: vec4<f32>,
    viewDepth: vec4<f32>,
    clusterScale: vec4<f32>,
    clusterGrid: vec4<f32>,
    cascadeMatrices: array<mat4x4<f32>, 4>,
    spotShadowMatrices: array<mat4x4<f32>, 8>,
    cascadeSplits: vec4<f32>,
    cascadeBlendStarts: vec4<f32>,
    cascadeNormalOffsets: vec4<f32>,
    cascadeBiases: vec4<f32>,
    shadowDepthRow: vec4<f32>,
    shadowInfo: vec4<f32>,
    shadowAtlas: vec4<f32>,
    shadowTiles: vec4<f32>,
    shadowFaces: vec4<f32>,
    shadowLocal: vec4<f32>,
    spotShadowParams: array<vec4<f32>, 8>,
    pointShadowPositions: array<vec4<f32>, 4>,
    pointShadowParams: array<vec4<f32>, 4>,
    environment: vec4<f32>,
    reflectionViewProj: mat4x4<f32>,
    reflectionPlane: vec4<f32>,
    reflectionParams: vec4<f32>,
    reflectionExtra: vec4<f32>,
    probes: vec4<f32>,
}

struct LightPositions {
    data: array<vec4<f32>, 1024>,
}

struct LightColors {
    data: array<vec4<f32>, 1024>,
}

struct LightDirections {
    data: array<vec4<f32>, 1024>,
}

struct LightCells {
    data: array<vec4<u32>, 1024>,
}

struct LightIndices {
    data: array<vec4<u32>, 1024>,
}

struct MaterialGraphPush {
    params: vec4<f32>,
}

struct MaterialData {
    baseColor: vec4<f32>,
    params: vec4<f32>,
    uvRow0_: vec4<f32>,
    uvRow1_: vec4<f32>,
    surface: vec4<f32>,
    emissive: vec4<f32>,
    flags: vec4<f32>,
}

struct ProbeData {
    words: array<vec4<u32>>,
}

struct FragmentOutput {
    @location(0) member: vec4<f32>,
    @location(1) member_1: vec2<f32>,
}

@group(2) @binding(9) 
var baseColorMap: texture_2d<f32>;
@group(2) @binding(17) 
var materialSampler: sampler;
var<private> gUV: vec2<f32>;
@group(2) @binding(10) 
var metallicRoughnessMap: texture_2d<f32>;
@group(2) @binding(11) 
var normalMap: texture_2d<f32>;
@group(2) @binding(12) 
var occlusionMap: texture_2d<f32>;
@group(2) @binding(13) 
var emissiveMap: texture_2d<f32>;
@group(2) @binding(24) 
var<storage> graphValues: MaterialGraphValues;
var<private> gBaseColor: vec3<f32>;
var<private> gVertexColor: vec4<f32>;
var<private> gPosition: vec3<f32>;
var<private> gNormal: vec3<f32>;
var<private> gView: vec3<f32>;
var<private> gTime: f32;
var<private> gOpacity: f32;
var<private> gNormalTS: vec3<f32>;
var<private> gMetallic: f32;
var<private> gRoughness: f32;
var<private> gEmissive: vec3<f32>;
var<private> gOcclusion: f32;
@group(0) @binding(0) 
var<uniform> frame: Frame;
@group(1) @binding(1) 
var shadowMap_sampler: sampler_comparison;
@group(1) @binding(0) 
var shadowMap_image: texture_depth_2d;
@group(2) @binding(14) 
var environmentAtlas: texture_2d<f32>;
@group(2) @binding(15) 
var brdfTable: texture_2d<f32>;
@group(2) @binding(23) 
var brdfSampler: sampler;
@group(2) @binding(3) 
var<uniform> lightPositions: LightPositions;
var<private> vWorldPos_1: vec3<f32>;
@group(2) @binding(4) 
var<uniform> lightColors: LightColors;
@group(2) @binding(5) 
var<uniform> lightDirections: LightDirections;
var<private> gl_FragCoord_1: vec4<f32>;
@group(2) @binding(6) 
var<uniform> lightCells: LightCells;
@group(2) @binding(7) 
var<uniform> lightIndices: LightIndices;
var<private> vUV_1: vec2<f32>;
var<private> vNormal_1: vec3<f32>;
var<private> vColor_1: vec4<f32>;
@group(3) @binding(0) 
var<uniform> graphPush: MaterialGraphPush;
var<private> vTangent_1: vec4<f32>;
@group(2) @binding(2) 
var<uniform> material: MaterialData;
var<private> gl_FrontFacing_1: bool;
var<private> vParams_1: vec4<f32>;
var<private> outColor: vec4<f32>;
var<private> outMotion: vec2<f32>;
var<private> vCurrentClip_1: vec4<f32>;
var<private> vPreviousClip_1: vec4<f32>;
@group(2) @binding(25) 
var<storage> probeData: ProbeData;

fn motionVector_u0028_vf4_u003b_vf4_u003b(current: ptr<function, vec4<f32>>, previous: ptr<function, vec4<f32>>) -> vec2<f32> {
    let _e193 = (*previous)[3u];
    if (_e193 <= 0f) {
        return vec2<f32>(0f, 0f);
    }
    let _e195 = (*previous);
    let _e198 = (*previous)[3u];
    let _e201 = (*current);
    let _e204 = (*current)[3u];
    return (((_e195.xy / vec2(_e198)) - (_e201.xy / vec2(_e204))) * vec2<f32>(0.5f, -0.5f));
}

fn planarReflected_u0028_vf3_u003b_vf3_u003b_vf3_u003b_f1_u003b(fallback: ptr<function, vec3<f32>>, n: ptr<function, vec3<f32>>, ng: ptr<function, vec3<f32>>, roughness: ptr<function, f32>) -> vec3<f32> {
    var pn: vec3<f32>;
    var tolerance: f32;
    var onPlane: f32;
    var facing: f32;
    var glossy: f32;
    var weight: f32;
    var p: vec3<f32>;
    var clip: vec4<f32>;
    var uv: vec2<f32>;
    var radius: f32;
    var sum: vec3<f32>;
    var coverage: f32;
    var i: i32;
    var r: f32;
    var a: f32;
    var tap: vec2<f32>;
    var inside: vec2<f32>;
    var edge: f32;
    var t: vec4<f32>;
    var planar: vec3<f32>;

    let _e215 = frame.reflectionPlane;
    pn = _e215.xyz;
    let _e219 = frame.reflectionExtra[0u];
    tolerance = _e219;
    let _e220 = tolerance;
    let _e222 = tolerance;
    let _e223 = pn;
    let _e224 = vWorldPos_1;
    let _e228 = frame.reflectionPlane[3u];
    onPlane = (1f - smoothstep((_e220 * 0.5f), _e222, abs((dot(_e223, _e224) - _e228))));
    let _e233 = (*ng);
    let _e234 = pn;
    facing = smoothstep(0.5f, 0.9f, dot(_e233, _e234));
    let _e239 = frame.reflectionParams[1u];
    let _e243 = frame.reflectionParams[1u];
    let _e244 = (*roughness);
    glossy = (1f - smoothstep((_e239 * 0.5f), _e243, _e244));
    let _e249 = frame.reflectionParams[0u];
    let _e250 = onPlane;
    let _e252 = facing;
    let _e254 = glossy;
    weight = (((_e249 * _e250) * _e252) * _e254);
    let _e256 = weight;
    if (_e256 <= 0f) {
        let _e258 = (*fallback);
        return _e258;
    }
    let _e259 = vWorldPos_1;
    let _e260 = (*n);
    let _e261 = pn;
    let _e262 = (*n);
    let _e263 = pn;
    let _e269 = frame.reflectionParams[3u];
    p = (_e259 + ((_e260 - (_e261 * dot(_e262, _e263))) * _e269));
    let _e273 = frame.reflectionViewProj;
    let _e274 = p;
    clip = (_e273 * vec4<f32>(_e274.x, _e274.y, _e274.z, 1f));
    let _e281 = clip[0u];
    let _e283 = clip[1u];
    let _e287 = clip[3u];
    uv = (((vec2<f32>(_e281, -(_e283)) / vec2(_e287)) * 0.5f) + vec2(0.5f));
    let _e295 = frame.reflectionParams[2u];
    let _e296 = (*roughness);
    radius = (_e295 * _e296);
    sum = vec3<f32>(0f, 0f, 0f);
    coverage = 0f;
    i = 0i;
    loop {
        let _e298 = i;
        if (_e298 < 12i) {
            let _e300 = i;
            let _e305 = radius;
            r = (sqrt(((f32(_e300) + 0.5f) / 12f)) * _e305);
            let _e307 = i;
            a = (f32(_e307) * 2.3999631f);
            let _e310 = uv;
            let _e311 = a;
            let _e315 = frame.reflectionExtra[1u];
            let _e317 = a;
            let _e320 = r;
            tap = (_e310 + (vec2<f32>((cos(_e311) * _e315), sin(_e317)) * _e320));
            let _e323 = tap;
            let _e324 = tap;
            inside = min(_e323, (vec2(1f) - _e324));
            let _e329 = inside[0u];
            let _e331 = inside[1u];
            edge = smoothstep(0f, 0.04f, min(_e329, _e331));
            let _e334 = tap;
            let _e338 = textureSampleLevel(occlusionMap, materialSampler, clamp(_e334, vec2(0f), vec2(1f)), 0f);
            t = _e338;
            let _e339 = t;
            let _e341 = t;
            let _e347 = edge;
            let _e349 = sum;
            sum = (_e349 + ((_e339.xyz / (vec3(1f) - min(_e341.xyz, vec3<f32>(0.995f, 0.995f, 0.995f)))) * _e347));
            let _e352 = t[3u];
            let _e353 = edge;
            let _e355 = coverage;
            coverage = (_e355 + (_e352 * _e353));
            continue;
        } else {
            break;
        }
        continuing {
            let _e357 = i;
            i = (_e357 + 1i);
        }
    }
    let _e359 = sum;
    let _e362 = (*fallback);
    let _e363 = coverage;
    planar = ((_e359 / vec3(12f)) + (_e362 * (1f - (_e363 / 12f))));
    let _e368 = (*fallback);
    let _e369 = planar;
    let _e370 = weight;
    return mix(_e368, _e369, vec3(_e370));
}

fn environmentBRDF_u0028_f1_u003b_f1_u003b(NoV: ptr<function, f32>, roughness_1: ptr<function, f32>) -> vec2<f32> {
    var r_1: vec4<f32>;
    var a004_: f32;

    let _e194 = (*roughness_1);
    r_1 = ((vec4<f32>(-1f, -0.0275f, -0.572f, 0.022f) * _e194) + vec4<f32>(1f, 0.0425f, 1.04f, -0.04f));
    let _e198 = r_1[0u];
    let _e200 = r_1[0u];
    let _e202 = (*NoV);
    let _e207 = r_1[0u];
    let _e210 = r_1[1u];
    a004_ = ((min((_e198 * _e200), exp2((-9.28f * _e202))) * _e207) + _e210);
    let _e212 = a004_;
    let _e214 = r_1;
    return ((vec2<f32>(-1.04f, 1.04f) * _e212) + _e214.zw);
}

fn sampleEquirect_u0028_t21_u003b_p1_u003b_vi4_u003b_vf2_u003b(image: texture_2d<f32>, s: sampler, region: ptr<function, vec4<i32>>, uv_1: ptr<function, vec2<f32>>) -> vec3<f32> {
    var p_1: vec2<f32>;
    var f: vec2<f32>;
    var t_1: vec2<f32>;
    var x0_: i32;
    var y0_: i32;
    var x1_: i32;
    var local: i32;
    var y1_: i32;
    var a_1: vec3<f32>;
    var b: vec3<f32>;
    var c: vec3<f32>;
    var d: vec3<f32>;

    let _e206 = (*uv_1);
    let _e207 = (*region);
    p_1 = ((_e206 * vec2<f32>(_e207.zw)) - vec2(0.5f));
    let _e213 = p_1;
    f = floor(_e213);
    let _e215 = p_1;
    let _e216 = f;
    t_1 = (_e215 - _e216);
    let _e219 = f[0u];
    x0_ = i32(_e219);
    let _e222 = f[1u];
    y0_ = i32(_e222);
    let _e224 = x0_;
    if (_e224 < 0i) {
        let _e227 = (*region)[2u];
        let _e228 = x0_;
        x0_ = (_e228 + _e227);
    }
    let _e230 = x0_;
    let _e232 = (*region)[2u];
    if (_e230 >= _e232) {
        let _e235 = (*region)[2u];
        let _e236 = x0_;
        x0_ = (_e236 - _e235);
    }
    let _e238 = x0_;
    let _e241 = (*region)[2u];
    if ((_e238 + 1i) == _e241) {
        local = 0i;
    } else {
        let _e243 = x0_;
        local = (_e243 + 1i);
    }
    let _e245 = local;
    x1_ = _e245;
    let _e246 = y0_;
    let _e249 = (*region)[3u];
    y1_ = min((_e246 + 1i), (_e249 - 1i));
    let _e252 = y0_;
    y0_ = max(_e252, 0i);
    let _e254 = (*region);
    let _e256 = x0_;
    let _e257 = y0_;
    let _e260 = textureLoad(image, (_e254.xy + vec2<i32>(_e256, _e257)), 0i);
    a_1 = _e260.xyz;
    let _e262 = (*region);
    let _e264 = x1_;
    let _e265 = y0_;
    let _e268 = textureLoad(image, (_e262.xy + vec2<i32>(_e264, _e265)), 0i);
    b = _e268.xyz;
    let _e270 = (*region);
    let _e272 = x0_;
    let _e273 = y1_;
    let _e276 = textureLoad(image, (_e270.xy + vec2<i32>(_e272, _e273)), 0i);
    c = _e276.xyz;
    let _e278 = (*region);
    let _e280 = x1_;
    let _e281 = y1_;
    let _e284 = textureLoad(image, (_e278.xy + vec2<i32>(_e280, _e281)), 0i);
    d = _e284.xyz;
    let _e286 = a_1;
    let _e287 = b;
    let _e289 = t_1[0u];
    let _e292 = c;
    let _e293 = d;
    let _e295 = t_1[0u];
    let _e299 = t_1[1u];
    return mix(mix(_e286, _e287, vec3(_e289)), mix(_e292, _e293, vec3(_e295)), vec3(_e299));
}

fn equirectUV_u0028_vf3_u003b(d_1: ptr<function, vec3<f32>>) -> vec2<f32> {
    let _e192 = (*d_1)[0u];
    let _e194 = (*d_1)[2u];
    let _e200 = (*d_1)[1u];
    return vec2<f32>(((atan2(_e192, -(_e194)) * 0.15915494f) + 0.5f), (acos(clamp(_e200, -1f, 1f)) * 0.31830987f));
}

fn environmentDirection_u0028_vf3_u003b_vf2_u003b(d_2: ptr<function, vec3<f32>>, cs: ptr<function, vec2<f32>>) -> vec3<f32> {
    let _e193 = (*cs)[0u];
    let _e195 = (*d_2)[0u];
    let _e198 = (*cs)[1u];
    let _e200 = (*d_2)[2u];
    let _e204 = (*d_2)[1u];
    let _e206 = (*cs)[1u];
    let _e208 = (*d_2)[0u];
    let _e211 = (*cs)[0u];
    let _e213 = (*d_2)[2u];
    return vec3<f32>(((_e193 * _e195) - (_e198 * _e200)), _e204, ((_e206 * _e208) + (_e211 * _e213)));
}

fn environmentRadiance_u0028_vf3_u003b_f1_u003b(d_3: ptr<function, vec3<f32>>, roughness_2: ptr<function, f32>) -> vec3<f32> {
    var uv_2: vec2<f32>;
    var param: vec3<f32>;
    var param_1: vec2<f32>;
    var param_2: vec3<f32>;
    var level: f32;
    var i_1: i32;
    var a_2: vec3<f32>;
    var param_3: vec4<i32>;
    var indexable: array<vec4<i32>, 6>;
    var param_4: vec2<f32>;
    var b_1: vec3<f32>;
    var param_5: vec4<i32>;
    var indexable_1: array<vec4<i32>, 6>;
    var param_6: vec2<f32>;

    let _e206 = (*d_3);
    param = _e206;
    let _e208 = frame.environment;
    param_1 = _e208.zw;
    let _e210 = environmentDirection_u0028_vf3_u003b_vf2_u003b((&param), (&param_1));
    param_2 = _e210;
    let _e211 = equirectUV_u0028_vf3_u003b((&param_2));
    uv_2 = _e211;
    let _e212 = (*roughness_2);
    level = (_e212 * 5f);
    let _e214 = level;
    i_1 = min(i32(_e214), 4i);
    let _e217 = i_1;
    indexable = array<vec4<i32>, 6>(vec4<i32>(0i, 0i, 512i, 256i), vec4<i32>(0i, 256i, 256i, 128i), vec4<i32>(256i, 256i, 128i, 64i), vec4<i32>(384i, 256i, 64i, 32i), vec4<i32>(448i, 256i, 32i, 16i), vec4<i32>(480i, 256i, 16i, 8i));
    let _e219 = indexable[_e217];
    param_3 = _e219;
    let _e220 = uv_2;
    param_4 = _e220;
    let _e221 = sampleEquirect_u0028_t21_u003b_p1_u003b_vi4_u003b_vf2_u003b(environmentAtlas, materialSampler, (&param_3), (&param_4));
    a_2 = _e221;
    let _e222 = i_1;
    indexable_1 = array<vec4<i32>, 6>(vec4<i32>(0i, 0i, 512i, 256i), vec4<i32>(0i, 256i, 256i, 128i), vec4<i32>(256i, 256i, 128i, 64i), vec4<i32>(384i, 256i, 64i, 32i), vec4<i32>(448i, 256i, 32i, 16i), vec4<i32>(480i, 256i, 16i, 8i));
    let _e225 = indexable_1[(_e222 + 1i)];
    param_5 = _e225;
    let _e226 = uv_2;
    param_6 = _e226;
    let _e227 = sampleEquirect_u0028_t21_u003b_p1_u003b_vi4_u003b_vf2_u003b(environmentAtlas, materialSampler, (&param_5), (&param_6));
    b_1 = _e227;
    let _e228 = a_2;
    let _e229 = b_1;
    let _e230 = level;
    let _e231 = i_1;
    let _e238 = frame.environment[1u];
    return (mix(_e228, _e229, vec3((_e230 - f32(_e231)))) * _e238);
}

fn environmentBRDFTable_u0028_f1_u003b_f1_u003b(NoV_1: ptr<function, f32>, roughness_3: ptr<function, f32>) -> vec2<f32> {
    var uv_3: vec2<f32>;

    let _e193 = (*NoV_1);
    let _e194 = (*roughness_3);
    uv_3 = (((vec2<f32>(_e193, _e194) * 31f) + vec2(0.5f)) / vec2(32f));
    let _e201 = uv_3;
    let _e202 = textureSample(brdfTable, brdfSampler, _e201);
    return _e202.xy;
}

fn visibilitySmithGGXCorrelated_u0028_f1_u003b_f1_u003b_f1_u003b(NoV_2: ptr<function, f32>, NoL: ptr<function, f32>, a_3: ptr<function, f32>) -> f32 {
    var a2_: f32;
    var ggxV: f32;
    var ggxL: f32;

    let _e196 = (*a_3);
    let _e197 = (*a_3);
    a2_ = (_e196 * _e197);
    let _e199 = (*NoL);
    let _e200 = (*NoV_2);
    let _e201 = (*NoV_2);
    let _e203 = a2_;
    let _e206 = a2_;
    ggxV = (_e199 * sqrt((((_e200 * _e201) * (1f - _e203)) + _e206)));
    let _e210 = (*NoV_2);
    let _e211 = (*NoL);
    let _e212 = (*NoL);
    let _e214 = a2_;
    let _e217 = a2_;
    ggxL = (_e210 * sqrt((((_e211 * _e212) * (1f - _e214)) + _e217)));
    let _e221 = ggxV;
    let _e222 = ggxL;
    return (0.5f / max((_e221 + _e222), 0.00001f));
}

fn distributionGGX_u0028_f1_u003b_f1_u003b(NoH: ptr<function, f32>, a_4: ptr<function, f32>) -> f32 {
    var a2_1: f32;
    var d_4: f32;

    let _e194 = (*a_4);
    let _e195 = (*a_4);
    a2_1 = (_e194 * _e195);
    let _e197 = (*NoH);
    let _e198 = (*NoH);
    let _e200 = a2_1;
    d_4 = (((_e197 * _e198) * (_e200 - 1f)) + 1f);
    let _e204 = a2_1;
    let _e205 = d_4;
    let _e207 = d_4;
    return (_e204 / ((3.1415927f * _e205) * _e207));
}

fn fresnelSchlick_u0028_vf3_u003b_f1_u003b(f0_: ptr<function, vec3<f32>>, VoH: ptr<function, f32>) -> vec3<f32> {
    var f_1: f32;

    let _e193 = (*VoH);
    f_1 = pow((1f - _e193), 5f);
    let _e196 = (*f0_);
    let _e197 = (*f0_);
    let _e199 = f_1;
    return (_e196 + ((vec3<f32>(1f, 1f, 1f) - _e197) * _e199));
}

fn shadowPCF_u0028_vf2_u003b_f1_u003b_vf4_u003b(uv_4: ptr<function, vec2<f32>>, ref_: ptr<function, f32>, bounds: ptr<function, vec4<f32>>) -> f32 {
    var texel: vec2<f32>;
    var radius_1: i32;
    var p_2: vec2<f32>;
    var base: vec2<f32>;
    var st: vec2<f32>;
    var w: array<vec2<f32>, 3>;
    var o: array<vec2<f32>, 3>;
    var n_1: i32;
    var norm: f32;
    var sum_1: f32;
    var j: i32;
    var i_2: i32;
    var tap_1: vec2<f32>;

    let _e207 = frame.shadowAtlas;
    texel = _e207.xy;
    let _e211 = frame.shadowAtlas[2u];
    radius_1 = i32(_e211);
    let _e213 = radius_1;
    if (_e213 <= 0i) {
        let _e215 = (*uv_4);
        let _e216 = (*bounds);
        let _e218 = (*bounds);
        let _e220 = clamp(_e215, _e216.xy, _e218.zw);
        let _e221 = (*ref_);
        let _e224 = vec3<f32>(_e220.x, _e220.y, _e221);
        let _e227 = textureSampleCompare(shadowMap_image, shadowMap_sampler, _e224.xy, _e224.z);
        return _e227;
    }
    let _e228 = (*uv_4);
    let _e229 = texel;
    p_2 = (_e228 / _e229);
    let _e231 = p_2;
    base = floor((_e231 + vec2(0.5f)));
    let _e235 = p_2;
    let _e238 = base;
    st = ((_e235 + vec2(0.5f)) - _e238);
    let _e240 = base;
    let _e243 = texel;
    base = ((_e240 - vec2(0.5f)) * _e243);
    let _e245 = radius_1;
    if (_e245 == 1i) {
        let _e247 = st;
        w[0i] = (vec2(3f) - (_e247 * 2f));
        let _e252 = st;
        w[1i] = (vec2(1f) + (_e252 * 2f));
        let _e257 = st;
        let _e261 = w[0i];
        o[0i] = (((vec2(2f) - _e257) / _e261) - vec2(1f));
        let _e266 = st;
        let _e268 = w[1i];
        o[1i] = ((_e266 / _e268) + vec2(1f));
        n_1 = 2i;
        norm = 0.0625f;
    } else {
        let _e273 = st;
        w[0i] = (vec2(4f) - (_e273 * 3f));
        w[1i] = vec2<f32>(7f, 7f);
        let _e279 = st;
        w[2i] = (vec2(1f) + (_e279 * 3f));
        let _e284 = st;
        let _e289 = w[0i];
        o[0i] = (((vec2(3f) - (_e284 * 2f)) / _e289) - vec2(2f));
        let _e294 = st;
        let _e298 = w[1i];
        o[1i] = ((vec2(3f) + _e294) / _e298);
        let _e301 = st;
        let _e303 = w[2i];
        o[2i] = ((_e301 / _e303) + vec2(2f));
        n_1 = 3i;
        norm = 0.0069444445f;
    }
    sum_1 = 0f;
    j = 0i;
    loop {
        let _e308 = j;
        let _e309 = n_1;
        if (_e308 < _e309) {
            i_2 = 0i;
            loop {
                let _e311 = i_2;
                let _e312 = n_1;
                if (_e311 < _e312) {
                    let _e314 = base;
                    let _e315 = i_2;
                    let _e318 = o[_e315][0u];
                    let _e319 = j;
                    let _e322 = o[_e319][1u];
                    let _e324 = texel;
                    let _e327 = (*bounds);
                    let _e329 = (*bounds);
                    tap_1 = clamp((_e314 + (vec2<f32>(_e318, _e322) * _e324)), _e327.xy, _e329.zw);
                    let _e332 = i_2;
                    let _e335 = w[_e332][0u];
                    let _e336 = j;
                    let _e339 = w[_e336][1u];
                    let _e341 = tap_1;
                    let _e342 = (*ref_);
                    let _e345 = vec3<f32>(_e341.x, _e341.y, _e342);
                    let _e348 = textureSampleCompare(shadowMap_image, shadowMap_sampler, _e345.xy, _e345.z);
                    let _e350 = sum_1;
                    sum_1 = (_e350 + ((_e335 * _e339) * _e348));
                    continue;
                } else {
                    break;
                }
                continuing {
                    let _e352 = i_2;
                    i_2 = (_e352 + 1i);
                }
            }
            continue;
        } else {
            break;
        }
        continuing {
            let _e354 = j;
            j = (_e354 + 1i);
        }
    }
    let _e356 = sum_1;
    let _e357 = norm;
    return (_e356 * _e357);
}

fn tileShadow_u0028_vf2_u003b_f1_u003b_vf2_u003b_vf2_u003b(local_1: ptr<function, vec2<f32>>, ref_1: ptr<function, f32>, origin: ptr<function, vec2<f32>>, size: ptr<function, vec2<f32>>) -> f32 {
    var halfTexel: vec2<f32>;
    var param_7: vec2<f32>;
    var param_8: f32;
    var param_9: vec4<f32>;

    let _e199 = frame.shadowAtlas;
    halfTexel = (_e199.xy * 0.5f);
    let _e202 = (*origin);
    let _e203 = (*local_1);
    let _e204 = (*size);
    let _e207 = (*origin);
    let _e208 = halfTexel;
    let _e209 = (_e207 + _e208);
    let _e210 = (*origin);
    let _e211 = (*size);
    let _e213 = halfTexel;
    let _e214 = ((_e210 + _e211) - _e213);
    param_7 = (_e202 + (_e203 * _e204));
    let _e220 = (*ref_1);
    param_8 = _e220;
    param_9 = vec4<f32>(_e209.x, _e209.y, _e214.x, _e214.y);
    let _e221 = shadowPCF_u0028_vf2_u003b_f1_u003b_vf4_u003b((&param_7), (&param_8), (&param_9));
    return _e221;
}

fn localShadow_u0028_u1_u003b_vf3_u003b_vf3_u003b_vf3_u003b(index: ptr<function, u32>, p_3: ptr<function, vec3<f32>>, ng_1: ptr<function, vec3<f32>>, l: ptr<function, vec3<f32>>) -> f32 {
    var spots: u32;
    var params: vec4<f32>;
    var clip0_: vec4<f32>;
    var texel_1: f32;
    var q: vec3<f32>;
    var clip_1: vec4<f32>;
    var local_2: vec3<f32>;
    var param_10: vec2<f32>;
    var param_11: f32;
    var param_12: vec2<f32>;
    var param_13: vec2<f32>;
    var point: u32;
    var position: vec4<f32>;
    var params_1: vec4<f32>;
    var texel_2: f32;
    var d_5: vec3<f32>;
    var a_5: vec3<f32>;
    var face: i32;
    var m: f32;
    var st_1: vec2<f32>;
    var indexable_2: array<vec3<f32>, 6>;
    var indexable_3: array<vec3<f32>, 6>;
    var ref_2: f32;
    var origin_1: vec2<f32>;
    var param_14: vec2<f32>;
    var param_15: f32;
    var param_16: vec2<f32>;
    var param_17: vec2<f32>;
    var phi_803_: bool;
    var phi_810_: bool;
    var phi_817_: bool;
    var phi_824_: bool;
    var phi_908_: bool;

    let _e224 = frame.shadowInfo[2u];
    spots = u32(_e224);
    let _e226 = (*index);
    let _e227 = spots;
    if (_e226 < _e227) {
        let _e229 = (*index);
        let _e232 = frame.spotShadowParams[_e229];
        params = _e232;
        let _e233 = (*index);
        let _e236 = frame.spotShadowMatrices[_e233];
        let _e237 = (*p_3);
        clip0_ = (_e236 * vec4<f32>(_e237.x, _e237.y, _e237.z, 1f));
        let _e244 = params[2u];
        let _e246 = clip0_[3u];
        texel_1 = (_e244 * max(_e246, 0f));
        let _e249 = (*p_3);
        let _e250 = (*ng_1);
        let _e251 = texel_1;
        let _e254 = frame.shadowLocal[0u];
        let _e258 = (*l);
        let _e259 = texel_1;
        let _e262 = frame.shadowLocal[1u];
        q = ((_e249 + (_e250 * (_e251 * _e254))) + (_e258 * (_e259 * _e262)));
        let _e266 = (*index);
        let _e269 = frame.spotShadowMatrices[_e266];
        let _e270 = q;
        clip_1 = (_e269 * vec4<f32>(_e270.x, _e270.y, _e270.z, 1f));
        let _e277 = clip_1[3u];
        if (_e277 <= 0f) {
            return 1f;
        }
        let _e279 = clip_1;
        let _e282 = clip_1[3u];
        local_2 = (_e279.xyz / vec3(_e282));
        let _e286 = local_2[0u];
        let _e287 = (_e286 < 0f);
        phi_803_ = _e287;
        if !(_e287) {
            let _e290 = local_2[0u];
            phi_803_ = (_e290 > 1f);
        }
        let _e293 = phi_803_;
        phi_810_ = _e293;
        if !(_e293) {
            let _e296 = local_2[1u];
            phi_810_ = (_e296 < 0f);
        }
        let _e299 = phi_810_;
        phi_817_ = _e299;
        if !(_e299) {
            let _e302 = local_2[1u];
            phi_817_ = (_e302 > 1f);
        }
        let _e305 = phi_817_;
        phi_824_ = _e305;
        if !(_e305) {
            let _e308 = local_2[2u];
            phi_824_ = (_e308 > 1f);
        }
        let _e311 = phi_824_;
        if _e311 {
            return 1f;
        }
        let _e312 = local_2;
        param_10 = _e312.xy;
        let _e315 = local_2[2u];
        param_11 = _e315;
        let _e316 = params;
        param_12 = _e316.xy;
        let _e319 = frame.shadowTiles;
        param_13 = _e319.zw;
        let _e321 = tileShadow_u0028_vf2_u003b_f1_u003b_vf2_u003b_vf2_u003b((&param_10), (&param_11), (&param_12), (&param_13));
        return _e321;
    }
    let _e322 = (*index);
    let _e323 = spots;
    point = (_e322 - _e323);
    let _e325 = point;
    let _e328 = frame.shadowInfo[3u];
    if (_e325 >= u32(_e328)) {
        return 1f;
    }
    let _e331 = point;
    let _e334 = frame.pointShadowPositions[_e331];
    position = _e334;
    let _e335 = point;
    let _e338 = frame.pointShadowParams[_e335];
    params_1 = _e338;
    let _e340 = position[3u];
    let _e341 = (*p_3);
    let _e342 = position;
    texel_2 = (_e340 * length((_e341 - _e342.xyz)));
    let _e347 = (*p_3);
    let _e348 = (*ng_1);
    let _e349 = texel_2;
    let _e352 = frame.shadowLocal[0u];
    let _e356 = (*l);
    let _e357 = texel_2;
    let _e360 = frame.shadowLocal[1u];
    let _e364 = position;
    d_5 = (((_e347 + (_e348 * (_e349 * _e352))) + (_e356 * (_e357 * _e360))) - _e364.xyz);
    let _e367 = d_5;
    a_5 = abs(_e367);
    let _e370 = a_5[0u];
    let _e372 = a_5[1u];
    let _e373 = (_e370 >= _e372);
    phi_908_ = _e373;
    if _e373 {
        let _e375 = a_5[0u];
        let _e377 = a_5[2u];
        phi_908_ = (_e375 >= _e377);
    }
    let _e380 = phi_908_;
    if _e380 {
        let _e382 = d_5[0u];
        face = select(1i, 0i, (_e382 > 0f));
        let _e386 = a_5[0u];
        m = _e386;
    } else {
        let _e388 = a_5[1u];
        let _e390 = a_5[2u];
        if (_e388 >= _e390) {
            let _e393 = d_5[1u];
            face = select(3i, 2i, (_e393 > 0f));
            let _e397 = a_5[1u];
            m = _e397;
        } else {
            let _e399 = d_5[2u];
            face = select(5i, 4i, (_e399 > 0f));
            let _e403 = a_5[2u];
            m = _e403;
        }
    }
    let _e404 = m;
    if (_e404 <= 0f) {
        return 1f;
    }
    let _e406 = d_5;
    let _e407 = face;
    indexable_2 = array<vec3<f32>, 6>(vec3<f32>(0f, 0f, 1f), vec3<f32>(0f, 0f, -1f), vec3<f32>(-1f, 0f, 0f), vec3<f32>(-1f, 0f, 0f), vec3<f32>(-1f, 0f, 0f), vec3<f32>(1f, 0f, 0f));
    let _e409 = indexable_2[_e407];
    let _e411 = d_5;
    let _e412 = face;
    indexable_3 = array<vec3<f32>, 6>(vec3<f32>(0f, 1f, 0f), vec3<f32>(0f, 1f, 0f), vec3<f32>(0f, 0f, -1f), vec3<f32>(0f, 0f, 1f), vec3<f32>(0f, 1f, 0f), vec3<f32>(0f, 1f, 0f));
    let _e414 = indexable_3[_e412];
    let _e417 = m;
    let _e420 = frame.shadowFaces[2u];
    st_1 = (vec2<f32>(dot(_e406, _e409), dot(_e411, _e414)) / vec2((_e417 * _e420)));
    let _e425 = params_1[2u];
    let _e427 = params_1[3u];
    let _e428 = m;
    ref_2 = (_e425 + (_e427 / _e428));
    let _e431 = ref_2;
    if (_e431 > 1f) {
        return 1f;
    }
    let _e433 = params_1;
    let _e435 = face;
    let _e444 = face;
    let _e449 = frame.shadowFaces;
    origin_1 = (_e433.xy + (vec2<f32>(f32((_e435 - (i32(floor((f32(_e435) / f32(3i)))) * 3i))), f32((_e444 / 3i))) * _e449.xy));
    let _e454 = st_1[0u];
    let _e458 = st_1[1u];
    param_14 = vec2<f32>((0.5f + (0.5f * _e454)), (0.5f - (0.5f * _e458)));
    let _e462 = ref_2;
    param_15 = _e462;
    let _e463 = origin_1;
    param_16 = _e463;
    let _e465 = frame.shadowFaces;
    param_17 = _e465.xy;
    let _e467 = tileShadow_u0028_vf2_u003b_f1_u003b_vf2_u003b_vf2_u003b((&param_14), (&param_15), (&param_16), (&param_17));
    return _e467;
}

fn punctualRadiance_u0028_u1_u003b_vf3_u003b(i_3: ptr<function, u32>, l_1: ptr<function, vec3<f32>>) -> vec3<f32> {
    var position_1: vec4<f32>;
    var toLight: vec3<f32>;
    var d2_: f32;
    var x: f32;
    var window: f32;
    var color: vec4<f32>;
    var direction: vec4<f32>;
    var cone: f32;

    let _e200 = (*i_3);
    let _e203 = lightPositions.data[_e200];
    position_1 = _e203;
    let _e204 = position_1;
    let _e206 = vWorldPos_1;
    toLight = (_e204.xyz - _e206);
    let _e208 = toLight;
    let _e209 = toLight;
    d2_ = dot(_e208, _e209);
    let _e211 = d2_;
    let _e213 = position_1[3u];
    x = (_e211 * _e213);
    let _e215 = x;
    let _e216 = x;
    window = clamp((1f - (_e215 * _e216)), 0f, 1f);
    let _e220 = toLight;
    let _e221 = d2_;
    (*l_1) = (_e220 * inverseSqrt(max(_e221, 0.00000001f)));
    let _e225 = (*i_3);
    let _e228 = lightColors.data[_e225];
    color = _e228;
    let _e229 = (*i_3);
    let _e232 = lightDirections.data[_e229];
    direction = _e232;
    let _e233 = (*l_1);
    let _e235 = direction;
    let _e239 = color[3u];
    let _e242 = direction[3u];
    cone = clamp(((dot(-(_e233), _e235.xyz) * _e239) + _e242), 0f, 1f);
    let _e245 = color;
    let _e247 = window;
    let _e248 = window;
    let _e250 = cone;
    let _e252 = cone;
    let _e254 = d2_;
    return (_e245.xyz * ((((_e247 * _e248) * _e250) * _e252) / max(_e254, 0.0001f)));
}

fn lightIndex_u0028_u1_u003b(i_4: ptr<function, u32>) -> u32 {
    var word: u32;

    let _e192 = (*i_4);
    word = (_e192 / 3u);
    let _e194 = word;
    let _e197 = word;
    let _e202 = lightIndices.data[(_e194 >> bitcast<u32>(2i))][(_e197 & 3u)];
    let _e203 = (*i_4);
    let _e204 = word;
    return ((_e202 >> bitcast<u32>(((_e203 - (_e204 * 3u)) * 10u))) & 1023u);
}

fn clusterLights_u0028_() -> vec2<u32> {
    var depth: f32;
    var tile: vec2<f32>;
    var slice: f32;
    var cluster: u32;
    var cell: u32;

    let _e196 = frame.viewDepth;
    let _e198 = vWorldPos_1;
    let _e202 = frame.viewDepth[3u];
    depth = (dot(_e196.xyz, _e198) + _e202);
    let _e204 = gl_FragCoord_1;
    let _e207 = frame.clusterScale;
    let _e212 = frame.clusterGrid;
    tile = clamp(floor((_e204.xy * _e207.xy)), vec2<f32>(0f, 0f), (_e212.xy - vec2(1f)));
    let _e217 = depth;
    let _e222 = frame.clusterScale[2u];
    let _e226 = frame.clusterScale[3u];
    let _e231 = frame.clusterGrid[2u];
    slice = clamp(floor(((log2(max(_e217, 0.000001f)) * _e222) + _e226)), 0f, (_e231 - 1f));
    let _e234 = slice;
    let _e237 = frame.clusterGrid[1u];
    let _e240 = tile[1u];
    let _e244 = frame.clusterGrid[0u];
    let _e247 = tile[0u];
    cluster = u32(((((_e234 * _e237) + _e240) * _e244) + _e247));
    let _e250 = cluster;
    let _e253 = cluster;
    let _e258 = lightCells.data[(_e250 >> bitcast<u32>(2i))][(_e253 & 3u)];
    cell = _e258;
    let _e259 = cell;
    let _e261 = cell;
    return vec2<u32>((_e259 & 65535u), (_e261 >> bitcast<u32>(16i)));
}

fn hemisphere_u0028_vf3_u003b(d_6: ptr<function, vec3<f32>>) -> vec3<f32> {
    let _e192 = frame.groundColor;
    let _e195 = frame.skyColor;
    let _e198 = (*d_6)[1u];
    let _e205 = frame.skyColor[3u];
    return (mix(_e192.xyz, _e195.xyz, vec3(((_e198 * 0.5f) + 0.5f))) * _e205);
}

fn shBasis_u0028_vf3_u003b_f1_u005b_9_u005d_u003b(d_7: ptr<function, vec3<f32>>, y: ptr<function, array<f32, 9>>) {
    (*y)[0i] = 0.282095f;
    let _e194 = (*d_7)[1u];
    (*y)[1i] = (0.488603f * _e194);
    let _e198 = (*d_7)[2u];
    (*y)[2i] = (0.488603f * _e198);
    let _e202 = (*d_7)[0u];
    (*y)[3i] = (0.488603f * _e202);
    let _e206 = (*d_7)[0u];
    let _e209 = (*d_7)[1u];
    (*y)[4i] = ((1.092548f * _e206) * _e209);
    let _e213 = (*d_7)[1u];
    let _e216 = (*d_7)[2u];
    (*y)[5i] = ((1.092548f * _e213) * _e216);
    let _e220 = (*d_7)[2u];
    let _e223 = (*d_7)[2u];
    (*y)[6i] = (0.315392f * (((3f * _e220) * _e223) - 1f));
    let _e229 = (*d_7)[0u];
    let _e232 = (*d_7)[2u];
    (*y)[7i] = ((1.092548f * _e229) * _e232);
    let _e236 = (*d_7)[0u];
    let _e238 = (*d_7)[0u];
    let _e241 = (*d_7)[1u];
    let _e243 = (*d_7)[1u];
    (*y)[8i] = (0.546274f * ((_e236 * _e238) - (_e241 * _e243)));
    return;
}

fn environmentIrradiance_u0028_vf3_u003b(n_2: ptr<function, vec3<f32>>) -> vec3<f32> {
    var param_18: vec3<f32>;
    var param_19: vec2<f32>;
    var y_1: array<f32, 9>;
    var param_20: vec3<f32>;
    var param_21: array<f32, 9>;
    var sum_2: vec3<f32>;
    var i_5: i32;

    let _e198 = (*n_2);
    param_18 = _e198;
    let _e200 = frame.environment;
    param_19 = _e200.zw;
    let _e202 = environmentDirection_u0028_vf3_u003b_vf2_u003b((&param_18), (&param_19));
    param_20 = _e202;
    shBasis_u0028_vf3_u003b_f1_u005b_9_u005d_u003b((&param_20), (&param_21));
    let _e203 = param_21;
    y_1 = _e203;
    sum_2 = vec3<f32>(0f, 0f, 0f);
    i_5 = 0i;
    loop {
        let _e204 = i_5;
        if (_e204 < 9i) {
            let _e206 = i_5;
            let _e209 = textureLoad(environmentAtlas, (vec2<i32>(496i, 256i) + vec2<i32>(_e206, 0i)), 0i);
            let _e211 = i_5;
            let _e213 = y_1[_e211];
            let _e215 = sum_2;
            sum_2 = (_e215 + (_e209.xyz * _e213));
            continue;
        } else {
            break;
        }
        continuing {
            let _e217 = i_5;
            i_5 = (_e217 + 1i);
        }
    }
    let _e219 = sum_2;
    let _e223 = frame.environment[1u];
    return (max(_e219, vec3<f32>(0f, 0f, 0f)) * _e223);
}

fn cascadeShadow_u0028_i1_u003b_vf3_u003b(c_1: ptr<function, i32>, p_4: ptr<function, vec3<f32>>) -> f32 {
    var local_3: vec3<f32>;
    var origin_2: vec2<f32>;
    var param_22: vec2<f32>;
    var param_23: f32;
    var param_24: vec2<f32>;
    var param_25: vec2<f32>;
    var phi_533_: bool;
    var phi_540_: bool;
    var phi_547_: bool;

    let _e198 = (*c_1);
    let _e201 = frame.cascadeMatrices[_e198];
    let _e202 = (*p_4);
    local_3 = (_e201 * vec4<f32>(_e202.x, _e202.y, _e202.z, 1f)).xyz;
    let _e210 = local_3[0u];
    let _e211 = (_e210 < 0f);
    phi_533_ = _e211;
    if !(_e211) {
        let _e214 = local_3[0u];
        phi_533_ = (_e214 > 1f);
    }
    let _e217 = phi_533_;
    phi_540_ = _e217;
    if !(_e217) {
        let _e220 = local_3[1u];
        phi_540_ = (_e220 < 0f);
    }
    let _e223 = phi_540_;
    phi_547_ = _e223;
    if !(_e223) {
        let _e226 = local_3[1u];
        phi_547_ = (_e226 > 1f);
    }
    let _e229 = phi_547_;
    if _e229 {
        return 1f;
    }
    let _e230 = (*c_1);
    let _e233 = (*c_1);
    let _e239 = frame.shadowTiles;
    origin_2 = (vec2<f32>(f32((_e230 & 1i)), f32((_e233 >> bitcast<u32>(1i)))) * _e239.xy);
    let _e243 = local_3[2u];
    let _e245 = (*c_1);
    let _e248 = frame.cascadeBiases[_e245];
    let _e250 = local_3;
    param_22 = _e250.xy;
    param_23 = (min(_e243, 1f) - _e248);
    let _e252 = origin_2;
    param_24 = _e252;
    let _e254 = frame.shadowTiles;
    param_25 = _e254.xy;
    let _e256 = tileShadow_u0028_vf2_u003b_f1_u003b_vf2_u003b_vf2_u003b((&param_22), (&param_23), (&param_24), (&param_25));
    return _e256;
}

fn directionalShadow_u0028_vf3_u003b_vf3_u003b_vf3_u003b(p_5: ptr<function, vec3<f32>>, ng_2: ptr<function, vec3<f32>>, tint: ptr<function, vec3<f32>>) -> f32 {
    var count: i32;
    var depth_1: f32;
    var c_2: i32;
    var s_1: f32;
    var param_26: i32;
    var param_27: vec3<f32>;
    var t_2: vec3<f32>;
    var indexable_4: array<vec3<f32>, 4>;
    var start: f32;
    var f_2: f32;
    var param_28: i32;
    var param_29: vec3<f32>;
    var indexable_5: array<vec3<f32>, 4>;
    var phi_619_: bool;

    (*tint) = vec3<f32>(1f, 1f, 1f);
    let _e208 = frame.shadowInfo[0u];
    count = i32(_e208);
    let _e211 = frame.shadowDepthRow;
    let _e213 = (*p_5);
    let _e217 = frame.shadowDepthRow[3u];
    depth_1 = (dot(_e211.xyz, _e213) + _e217);
    c_2 = 0i;
    loop {
        let _e219 = c_2;
        let _e220 = count;
        let _e222 = (_e219 < (_e220 - 1i));
        phi_619_ = _e222;
        if _e222 {
            let _e223 = depth_1;
            let _e224 = c_2;
            let _e227 = frame.cascadeSplits[_e224];
            phi_619_ = (_e223 > _e227);
        }
        let _e230 = phi_619_;
        if _e230 {
            let _e231 = c_2;
            c_2 = (_e231 + 1i);
            continue;
        } else {
            break;
        }
    }
    let _e233 = depth_1;
    let _e234 = c_2;
    let _e237 = frame.cascadeSplits[_e234];
    if (_e233 > _e237) {
        return 1f;
    }
    let _e239 = (*p_5);
    let _e240 = (*ng_2);
    let _e241 = c_2;
    let _e244 = frame.cascadeNormalOffsets[_e241];
    let _e247 = c_2;
    param_26 = _e247;
    param_27 = (_e239 + (_e240 * _e244));
    let _e248 = cascadeShadow_u0028_i1_u003b_vf3_u003b((&param_26), (&param_27));
    s_1 = _e248;
    let _e249 = c_2;
    indexable_4 = array<vec3<f32>, 4>(vec3<f32>(1f, 0.45f, 0.45f), vec3<f32>(0.45f, 1f, 0.45f), vec3<f32>(0.5f, 0.6f, 1f), vec3<f32>(1f, 1f, 0.4f));
    let _e251 = indexable_4[_e249];
    t_2 = _e251;
    let _e252 = c_2;
    let _e255 = frame.cascadeBlendStarts[_e252];
    start = _e255;
    let _e256 = depth_1;
    let _e257 = start;
    if (_e256 > _e257) {
        let _e259 = depth_1;
        let _e260 = start;
        let _e262 = c_2;
        let _e265 = frame.cascadeSplits[_e262];
        let _e266 = start;
        f_2 = ((_e259 - _e260) / (_e265 - _e266));
        let _e269 = c_2;
        let _e271 = count;
        if ((_e269 + 1i) < _e271) {
            let _e273 = s_1;
            let _e274 = c_2;
            let _e276 = (*p_5);
            let _e277 = (*ng_2);
            let _e278 = c_2;
            let _e282 = frame.cascadeNormalOffsets[(_e278 + 1i)];
            param_28 = (_e274 + 1i);
            param_29 = (_e276 + (_e277 * _e282));
            let _e285 = cascadeShadow_u0028_i1_u003b_vf3_u003b((&param_28), (&param_29));
            let _e286 = f_2;
            s_1 = mix(_e273, _e285, _e286);
            let _e288 = t_2;
            let _e289 = c_2;
            indexable_5 = array<vec3<f32>, 4>(vec3<f32>(1f, 0.45f, 0.45f), vec3<f32>(0.45f, 1f, 0.45f), vec3<f32>(0.5f, 0.6f, 1f), vec3<f32>(1f, 1f, 0.4f));
            let _e292 = indexable_5[(_e289 + 1i)];
            let _e293 = f_2;
            t_2 = mix(_e288, _e292, vec3(_e293));
        } else {
            let _e296 = s_1;
            let _e297 = f_2;
            s_1 = mix(_e296, 1f, _e297);
        }
    }
    let _e301 = frame.shadowAtlas[3u];
    if (_e301 > 0.5f) {
        let _e303 = t_2;
        (*tint) = _e303;
    }
    let _e304 = s_1;
    return _e304;
}

fn graphSurface_u0028_() {
    var a_6: vec4<f32>;
    var b_2: vec4<f32>;
    var c_3: vec4<f32>;
    var d_8: vec4<f32>;
    var e: vec4<f32>;
    var v: vec4<f32>;

    let _e196 = gUV;
    let _e197 = textureSample(baseColorMap, materialSampler, _e196);
    a_6 = _e197;
    let _e198 = gUV;
    let _e199 = textureSample(metallicRoughnessMap, materialSampler, _e198);
    b_2 = _e199;
    let _e200 = gUV;
    let _e201 = textureSample(normalMap, materialSampler, _e200);
    c_3 = _e201;
    let _e202 = gUV;
    let _e203 = textureSample(occlusionMap, materialSampler, _e202);
    d_8 = _e203;
    let _e204 = gUV;
    let _e205 = textureSample(emissiveMap, materialSampler, _e204);
    e = _e205;
    let _e208 = graphValues.values[0i];
    v = _e208;
    let _e209 = a_6;
    let _e211 = gVertexColor;
    let _e214 = v;
    let _e217 = gPosition;
    let _e218 = gNormal;
    let _e220 = gView;
    let _e222 = gTime;
    gBaseColor = (((_e209.xyz * _e211.xyz) * _e214.xyz) + (((_e217 + _e218) + _e220) * _e222));
    let _e226 = a_6[3u];
    let _e228 = v[3u];
    gOpacity = (_e226 * _e228);
    let _e230 = c_3;
    gNormalTS = ((_e230.xyz * 2f) - vec3(1f));
    let _e236 = b_2[2u];
    gMetallic = _e236;
    let _e238 = b_2[1u];
    gRoughness = _e238;
    let _e239 = e;
    gEmissive = _e239.xyz;
    let _e242 = d_8[0u];
    gOcclusion = _e242;
    return;
}

fn main_1() {
    var albedo: vec3<f32>;
    var opacity: f32;
    var n_3: vec3<f32>;
    var gt: vec3<f32>;
    var gb: vec3<f32>;
    var m_1: vec3<f32>;
    var pbr: bool;
    var translucency: f32;
    var local_4: f32;
    var l_2: vec3<f32>;
    var v_1: vec3<f32>;
    var h: vec3<f32>;
    var ng_3: vec3<f32>;
    var receivesShadows: bool;
    var shadow: f32;
    var cascadeTint: vec3<f32>;
    var param_30: vec3<f32>;
    var param_31: vec3<f32>;
    var param_32: vec3<f32>;
    var light: vec3<f32>;
    var ao: f32;
    var vertexAO: f32;
    var ndotl: f32;
    var diffuse: vec3<f32>;
    var specular: vec3<f32>;
    var ambient: vec3<f32>;
    var local_5: vec3<f32>;
    var param_33: vec3<f32>;
    var param_34: vec3<f32>;
    var color_1: vec3<f32>;
    var cell_1: vec2<u32>;
    var i_6: u32;
    var li: u32;
    var param_35: u32;
    var radiance: vec3<f32>;
    var pl: vec3<f32>;
    var param_36: u32;
    var param_37: vec3<f32>;
    var param_38: u32;
    var param_39: vec3<f32>;
    var param_40: vec3<f32>;
    var param_41: vec3<f32>;
    var pndotl: f32;
    var ph: vec3<f32>;
    var metallic: f32;
    var roughness_4: f32;
    var a_7: f32;
    var diffuseColor: vec3<f32>;
    var f0_1: vec3<f32>;
    var sn: vec3<f32>;
    var face_1: vec3<f32>;
    var NoV_3: f32;
    var NoL_1: f32;
    var sNoL: f32;
    var NoH_1: f32;
    var VoH_1: f32;
    var F: vec3<f32>;
    var param_42: vec3<f32>;
    var param_43: f32;
    var specular_1: vec3<f32>;
    var param_44: f32;
    var param_45: f32;
    var param_46: f32;
    var param_47: f32;
    var param_48: f32;
    var direct: vec3<f32>;
    var through: f32;
    var toward: f32;
    var dfg: vec2<f32>;
    var param_49: f32;
    var param_50: f32;
    var irradiance: vec3<f32>;
    var param_51: vec3<f32>;
    var reflected: vec3<f32>;
    var param_52: vec3<f32>;
    var param_53: f32;
    var param_54: f32;
    var param_55: f32;
    var param_56: vec3<f32>;
    var param_57: vec3<f32>;
    var param_58: vec3<f32>;
    var param_59: vec3<f32>;
    var param_60: vec3<f32>;
    var param_61: f32;
    var specularAmbient: vec3<f32>;
    var ambient_1: vec3<f32>;
    var cell_2: vec2<u32>;
    var i_7: u32;
    var li_1: u32;
    var param_62: u32;
    var radiance_1: vec3<f32>;
    var pl_1: vec3<f32>;
    var param_63: u32;
    var param_64: vec3<f32>;
    var param_65: u32;
    var param_66: vec3<f32>;
    var param_67: vec3<f32>;
    var param_68: vec3<f32>;
    var ph_1: vec3<f32>;
    var pNoL: f32;
    var pNoH: f32;
    var pF: vec3<f32>;
    var param_69: vec3<f32>;
    var param_70: f32;
    var pSpecular: vec3<f32>;
    var param_71: f32;
    var param_72: f32;
    var param_73: f32;
    var param_74: f32;
    var param_75: f32;
    var dist: f32;
    var fog: f32;
    var k: f32;
    var toEye: vec3<f32>;
    var x_1: f32;
    var span: f32;
    var local_6: f32;
    var atEye: f32;
    var rgb: vec3<f32>;
    var param_76: vec4<f32>;
    var param_77: vec4<f32>;
    var phi_1987_: bool;
    var phi_2044_: bool;
    var phi_2474_: bool;

    let _e311 = vUV_1;
    gUV = _e311;
    let _e312 = vWorldPos_1;
    gPosition = _e312;
    let _e313 = vNormal_1;
    gNormal = normalize(_e313);
    let _e316 = frame.cameraPos;
    let _e318 = vWorldPos_1;
    gView = normalize((_e316.xyz - _e318));
    let _e321 = vColor_1;
    gVertexColor = _e321;
    let _e324 = graphPush.params[0u];
    gTime = _e324;
    graphSurface_u0028_();
    let _e325 = vColor_1;
    let _e327 = gBaseColor;
    albedo = (_e325.xyz * max(_e327, vec3<f32>(0f, 0f, 0f)));
    let _e331 = vColor_1[3u];
    let _e332 = gOpacity;
    opacity = (_e331 * clamp(_e332, 0f, 1f));
    let _e337 = graphPush.params[1u];
    if (_e337 > 0.5f) {
        let _e339 = gOpacity;
        let _e342 = graphPush.params[2u];
        if (_e339 < _e342) {
            discard;
        }
        let _e345 = vColor_1[3u];
        opacity = _e345;
    }
    let _e346 = vNormal_1;
    n_3 = normalize(_e346);
    let _e348 = vTangent_1;
    let _e350 = n_3;
    let _e351 = n_3;
    let _e352 = vTangent_1;
    gt = (_e348.xyz - (_e350 * dot(_e351, _e352.xyz)));
    let _e357 = gt;
    let _e358 = gt;
    let _e360 = (dot(_e357, _e358) > 0.000000000001f);
    phi_1987_ = _e360;
    if _e360 {
        let _e361 = gNormalTS;
        let _e362 = gNormalTS;
        phi_1987_ = (dot(_e361, _e362) > 0.000000000001f);
    }
    let _e366 = phi_1987_;
    if _e366 {
        let _e367 = gt;
        gt = normalize(_e367);
        let _e369 = n_3;
        let _e370 = gt;
        let _e373 = vTangent_1[3u];
        gb = (cross(_e369, _e370) * select(1f, -1f, (_e373 < 0f)));
        let _e377 = gNormalTS;
        m_1 = normalize(_e377);
        let _e379 = gt;
        let _e381 = m_1[0u];
        let _e383 = gb;
        let _e385 = m_1[1u];
        let _e388 = n_3;
        let _e390 = m_1[2u];
        n_3 = normalize((((_e379 * _e381) + (_e383 * _e385)) + (_e388 * _e390)));
    }
    let _e396 = material.emissive[3u];
    pbr = (_e396 > 0.5f);
    let _e398 = pbr;
    if _e398 {
        let _e401 = material.params[2u];
        local_4 = clamp(_e401, 0f, 1f);
    } else {
        local_4 = 0f;
    }
    let _e403 = local_4;
    translucency = _e403;
    let _e404 = pbr;
    phi_2044_ = _e404;
    if _e404 {
        let _e405 = gl_FrontFacing_1;
        phi_2044_ = !(_e405);
    }
    let _e408 = phi_2044_;
    let _e409 = translucency;
    if (_e408 && (_e409 <= 0f)) {
        let _e412 = n_3;
        n_3 = -(_e412);
    }
    let _e415 = frame.lightDir;
    l_2 = normalize(_e415.xyz);
    let _e419 = frame.cameraPos;
    let _e421 = vWorldPos_1;
    v_1 = normalize((_e419.xyz - _e421));
    let _e424 = l_2;
    let _e425 = v_1;
    h = normalize((_e424 + _e425));
    let _e428 = vNormal_1;
    let _e430 = gl_FrontFacing_1;
    ng_3 = (normalize(_e428) * select(-1f, 1f, _e430));
    let _e434 = vParams_1[0u];
    receivesShadows = (_e434 > 0.5f);
    shadow = 1f;
    let _e438 = frame.lightColor[3u];
    let _e440 = receivesShadows;
    if ((_e438 > 0.5f) && _e440) {
        let _e442 = vWorldPos_1;
        param_30 = _e442;
        let _e443 = ng_3;
        param_31 = _e443;
        let _e444 = directionalShadow_u0028_vf3_u003b_vf3_u003b_vf3_u003b((&param_30), (&param_31), (&param_32));
        let _e445 = param_32;
        cascadeTint = _e445;
        shadow = _e444;
        let _e446 = cascadeTint;
        let _e447 = albedo;
        albedo = (_e447 * _e446);
    }
    let _e450 = frame.lightColor;
    let _e454 = frame.lightDir[3u];
    light = (_e450.xyz * _e454);
    let _e456 = gOcclusion;
    ao = clamp(_e456, 0f, 1f);
    let _e459 = vTangent_1[3u];
    vertexAO = abs(_e459);
    let _e461 = vertexAO;
    if (_e461 > 0f) {
        let _e463 = vertexAO;
        let _e465 = ao;
        ao = (_e465 * min(_e463, 1f));
    }
    let _e467 = pbr;
    if !(_e467) {
        let _e469 = n_3;
        let _e470 = l_2;
        ndotl = dot(_e469, _e470);
        let _e472 = ndotl;
        let _e474 = light;
        diffuse = (_e474 * max(_e472, 0f));
        let _e476 = n_3;
        let _e477 = h;
        let _e482 = material.params[3u];
        let _e486 = material.params[2u];
        let _e488 = ndotl;
        let _e491 = light;
        specular = (_e491 * ((pow(max(dot(_e476, _e477), 0f), _e482) * _e486) * step(0f, _e488)));
        let _e495 = frame.environment[0u];
        if (_e495 > 0.5f) {
            let _e497 = n_3;
            param_33 = _e497;
            let _e498 = environmentIrradiance_u0028_vf3_u003b((&param_33));
            local_5 = _e498;
        } else {
            let _e499 = n_3;
            param_34 = _e499;
            let _e500 = hemisphere_u0028_vf3_u003b((&param_34));
            local_5 = _e500;
        }
        let _e501 = local_5;
        let _e502 = ao;
        ambient = (_e501 * _e502);
        let _e504 = albedo;
        let _e505 = ambient;
        let _e506 = diffuse;
        let _e507 = shadow;
        let _e511 = specular;
        let _e512 = shadow;
        color_1 = ((_e504 * (_e505 + (_e506 * _e507))) + (_e511 * _e512));
        let _e517 = frame.clusterGrid[3u];
        if (_e517 > 0.5f) {
            let _e519 = clusterLights_u0028_();
            cell_1 = _e519;
            let _e521 = cell_1[0u];
            i_6 = _e521;
            loop {
                let _e522 = i_6;
                let _e524 = cell_1[0u];
                let _e526 = cell_1[1u];
                if (_e522 < (_e524 + _e526)) {
                    let _e529 = i_6;
                    param_35 = _e529;
                    let _e530 = lightIndex_u0028_u1_u003b((&param_35));
                    li = _e530;
                    let _e531 = li;
                    param_36 = _e531;
                    let _e532 = punctualRadiance_u0028_u1_u003b_vf3_u003b((&param_36), (&param_37));
                    let _e533 = param_37;
                    pl = _e533;
                    radiance = _e532;
                    let _e534 = receivesShadows;
                    if _e534 {
                        let _e535 = li;
                        param_38 = _e535;
                        let _e536 = vWorldPos_1;
                        param_39 = _e536;
                        let _e537 = ng_3;
                        param_40 = _e537;
                        let _e538 = pl;
                        param_41 = _e538;
                        let _e539 = localShadow_u0028_u1_u003b_vf3_u003b_vf3_u003b_vf3_u003b((&param_38), (&param_39), (&param_40), (&param_41));
                        let _e540 = radiance;
                        radiance = (_e540 * _e539);
                    }
                    let _e542 = n_3;
                    let _e543 = pl;
                    pndotl = dot(_e542, _e543);
                    let _e545 = pl;
                    let _e546 = v_1;
                    ph = normalize((_e545 + _e546));
                    let _e549 = albedo;
                    let _e550 = pndotl;
                    let _e553 = radiance;
                    let _e555 = n_3;
                    let _e556 = ph;
                    let _e561 = material.params[3u];
                    let _e565 = material.params[2u];
                    let _e567 = pndotl;
                    let _e570 = radiance;
                    let _e573 = color_1;
                    color_1 = (_e573 + (((_e549 * max(_e550, 0f)) * _e553) + (_e570 * ((pow(max(dot(_e555, _e556), 0f), _e561) * _e565) * step(0f, _e567)))));
                    continue;
                } else {
                    break;
                }
                continuing {
                    let _e575 = i_6;
                    i_6 = (_e575 + bitcast<u32>(1i));
                }
            }
        }
    } else {
        let _e578 = gMetallic;
        metallic = clamp(_e578, 0f, 1f);
        let _e580 = gRoughness;
        roughness_4 = clamp(_e580, 0.045f, 1f);
        let _e582 = roughness_4;
        let _e583 = roughness_4;
        a_7 = (_e582 * _e583);
        let _e585 = albedo;
        let _e586 = metallic;
        diffuseColor = (_e585 * (1f - _e586));
        let _e589 = albedo;
        let _e590 = metallic;
        f0_1 = mix(vec3<f32>(0.04f, 0.04f, 0.04f), _e589, vec3(_e590));
        let _e593 = n_3;
        sn = _e593;
        let _e594 = translucency;
        if (_e594 > 0f) {
            let _e596 = vWorldPos_1;
            let _e597 = dpdx(_e596);
            let _e598 = vWorldPos_1;
            let _e599 = dpdy(_e598);
            face_1 = cross(_e597, _e599);
            let _e601 = face_1;
            let _e602 = face_1;
            if (dot(_e601, _e602) > 0.00000000000000000001f) {
                let _e605 = face_1;
                let _e607 = face_1;
                let _e608 = v_1;
                let _e613 = n_3;
                let _e614 = vNormal_1;
                sn = normalize(((normalize(_e605) * select(1f, -1f, (dot(_e607, _e608) < 0f))) + (_e613 - normalize(_e614))));
            }
        }
        let _e619 = sn;
        let _e620 = v_1;
        NoV_3 = max(dot(_e619, _e620), 0.0001f);
        let _e623 = n_3;
        let _e624 = l_2;
        NoL_1 = clamp(dot(_e623, _e624), 0f, 1f);
        let _e627 = sn;
        let _e628 = l_2;
        sNoL = clamp(dot(_e627, _e628), 0f, 1f);
        let _e631 = sn;
        let _e632 = h;
        NoH_1 = clamp(dot(_e631, _e632), 0f, 1f);
        let _e635 = v_1;
        let _e636 = h;
        VoH_1 = clamp(dot(_e635, _e636), 0f, 1f);
        let _e639 = translucency;
        if (_e639 > 0f) {
            let _e641 = NoV_3;
            NoV_3 = max(_e641, 0.5f);
            let _e643 = VoH_1;
            VoH_1 = max(_e643, 0.5f);
        }
        let _e645 = f0_1;
        param_42 = _e645;
        let _e646 = VoH_1;
        param_43 = _e646;
        let _e647 = fresnelSchlick_u0028_vf3_u003b_f1_u003b((&param_42), (&param_43));
        F = _e647;
        let _e648 = NoH_1;
        param_44 = _e648;
        let _e649 = a_7;
        param_45 = _e649;
        let _e650 = distributionGGX_u0028_f1_u003b_f1_u003b((&param_44), (&param_45));
        let _e651 = NoV_3;
        param_46 = _e651;
        let _e652 = sNoL;
        param_47 = _e652;
        let _e653 = a_7;
        param_48 = _e653;
        let _e654 = visibilitySmithGGXCorrelated_u0028_f1_u003b_f1_u003b_f1_u003b((&param_46), (&param_47), (&param_48));
        let _e656 = F;
        specular_1 = ((_e656 * (_e650 * _e654)) * 3.1415927f);
        let _e659 = F;
        let _e661 = diffuseColor;
        let _e663 = NoL_1;
        let _e665 = specular_1;
        let _e666 = sNoL;
        let _e669 = light;
        let _e671 = shadow;
        direct = ((((((vec3<f32>(1f, 1f, 1f) - _e659) * _e661) * _e663) + (_e665 * _e666)) * _e669) * _e671);
        let _e673 = translucency;
        if (_e673 > 0f) {
            let _e675 = sn;
            let _e676 = l_2;
            through = clamp(-(dot(_e675, _e676)), 0f, 1f);
            let _e680 = v_1;
            let _e682 = l_2;
            toward = pow(clamp(dot(-(_e680), _e682), 0f, 1f), 3f);
            let _e686 = diffuseColor;
            let _e687 = light;
            let _e689 = shadow;
            let _e691 = translucency;
            let _e693 = through;
            let _e695 = toward;
            let _e699 = direct;
            direct = (_e699 + (((((_e686 * _e687) * _e689) * _e691) * _e693) * (0.35f + (0.65f * _e695))));
        }
        let _e703 = frame.environment[0u];
        if (_e703 > 0.5f) {
            let _e705 = NoV_3;
            param_49 = _e705;
            let _e706 = roughness_4;
            param_50 = _e706;
            let _e707 = environmentBRDFTable_u0028_f1_u003b_f1_u003b((&param_49), (&param_50));
            dfg = _e707;
            let _e708 = n_3;
            param_51 = _e708;
            let _e709 = environmentIrradiance_u0028_vf3_u003b((&param_51));
            irradiance = _e709;
            let _e710 = v_1;
            let _e712 = sn;
            param_52 = reflect(-(_e710), _e712);
            let _e714 = roughness_4;
            param_53 = _e714;
            let _e715 = environmentRadiance_u0028_vf3_u003b_f1_u003b((&param_52), (&param_53));
            reflected = _e715;
        } else {
            let _e716 = NoV_3;
            param_54 = _e716;
            let _e717 = roughness_4;
            param_55 = _e717;
            let _e718 = environmentBRDF_u0028_f1_u003b_f1_u003b((&param_54), (&param_55));
            dfg = _e718;
            let _e719 = n_3;
            param_56 = _e719;
            let _e720 = hemisphere_u0028_vf3_u003b((&param_56));
            irradiance = _e720;
            let _e721 = v_1;
            let _e723 = sn;
            param_57 = reflect(-(_e721), _e723);
            let _e725 = hemisphere_u0028_vf3_u003b((&param_57));
            let _e726 = irradiance;
            let _e727 = roughness_4;
            reflected = mix(_e725, _e726, vec3(_e727));
        }
        let _e732 = material.flags[3u];
        let _e733 = (_e732 > 0.5f);
        phi_2474_ = _e733;
        if _e733 {
            let _e736 = frame.reflectionExtra[2u];
            phi_2474_ = (_e736 > 0.5f);
        }
        let _e739 = phi_2474_;
        if _e739 {
            let _e740 = reflected;
            param_58 = _e740;
            let _e741 = n_3;
            param_59 = _e741;
            let _e742 = ng_3;
            param_60 = _e742;
            let _e743 = roughness_4;
            param_61 = _e743;
            let _e744 = planarReflected_u0028_vf3_u003b_vf3_u003b_vf3_u003b_f1_u003b((&param_58), (&param_59), (&param_60), (&param_61));
            reflected = _e744;
        }
        let _e745 = f0_1;
        let _e747 = dfg[0u];
        let _e750 = dfg[1u];
        specularAmbient = ((_e745 * _e747) + vec3(_e750));
        let _e753 = specularAmbient;
        let _e755 = diffuseColor;
        let _e757 = irradiance;
        let _e759 = specularAmbient;
        let _e760 = reflected;
        let _e763 = ao;
        ambient_1 = (((((vec3<f32>(1f, 1f, 1f) - _e753) * _e755) * _e757) + (_e759 * _e760)) * _e763);
        let _e765 = direct;
        let _e766 = ambient_1;
        color_1 = (_e765 + _e766);
        let _e770 = frame.clusterGrid[3u];
        if (_e770 > 0.5f) {
            let _e772 = clusterLights_u0028_();
            cell_2 = _e772;
            let _e774 = cell_2[0u];
            i_7 = _e774;
            loop {
                let _e775 = i_7;
                let _e777 = cell_2[0u];
                let _e779 = cell_2[1u];
                if (_e775 < (_e777 + _e779)) {
                    let _e782 = i_7;
                    param_62 = _e782;
                    let _e783 = lightIndex_u0028_u1_u003b((&param_62));
                    li_1 = _e783;
                    let _e784 = li_1;
                    param_63 = _e784;
                    let _e785 = punctualRadiance_u0028_u1_u003b_vf3_u003b((&param_63), (&param_64));
                    let _e786 = param_64;
                    pl_1 = _e786;
                    radiance_1 = _e785;
                    let _e787 = receivesShadows;
                    if _e787 {
                        let _e788 = li_1;
                        param_65 = _e788;
                        let _e789 = vWorldPos_1;
                        param_66 = _e789;
                        let _e790 = ng_3;
                        param_67 = _e790;
                        let _e791 = pl_1;
                        param_68 = _e791;
                        let _e792 = localShadow_u0028_u1_u003b_vf3_u003b_vf3_u003b_vf3_u003b((&param_65), (&param_66), (&param_67), (&param_68));
                        let _e793 = radiance_1;
                        radiance_1 = (_e793 * _e792);
                    }
                    let _e795 = pl_1;
                    let _e796 = v_1;
                    ph_1 = normalize((_e795 + _e796));
                    let _e799 = n_3;
                    let _e800 = pl_1;
                    pNoL = clamp(dot(_e799, _e800), 0f, 1f);
                    let _e803 = n_3;
                    let _e804 = ph_1;
                    pNoH = clamp(dot(_e803, _e804), 0f, 1f);
                    let _e807 = v_1;
                    let _e808 = ph_1;
                    let _e811 = f0_1;
                    param_69 = _e811;
                    param_70 = clamp(dot(_e807, _e808), 0f, 1f);
                    let _e812 = fresnelSchlick_u0028_vf3_u003b_f1_u003b((&param_69), (&param_70));
                    pF = _e812;
                    let _e813 = pNoH;
                    param_71 = _e813;
                    let _e814 = a_7;
                    param_72 = _e814;
                    let _e815 = distributionGGX_u0028_f1_u003b_f1_u003b((&param_71), (&param_72));
                    let _e816 = NoV_3;
                    param_73 = _e816;
                    let _e817 = pNoL;
                    param_74 = _e817;
                    let _e818 = a_7;
                    param_75 = _e818;
                    let _e819 = visibilitySmithGGXCorrelated_u0028_f1_u003b_f1_u003b_f1_u003b((&param_73), (&param_74), (&param_75));
                    let _e821 = pF;
                    pSpecular = ((_e821 * (_e815 * _e819)) * 3.1415927f);
                    let _e824 = pF;
                    let _e826 = diffuseColor;
                    let _e828 = pSpecular;
                    let _e830 = pNoL;
                    let _e832 = radiance_1;
                    let _e834 = color_1;
                    color_1 = (_e834 + (((((vec3<f32>(1f, 1f, 1f) - _e824) * _e826) + _e828) * _e830) * _e832));
                    continue;
                } else {
                    break;
                }
                continuing {
                    let _e836 = i_7;
                    i_7 = (_e836 + bitcast<u32>(1i));
                }
            }
        }
    }
    let _e839 = color_1;
    let _e840 = albedo;
    let _e843 = material.params[1u];
    color_1 = mix(_e839, _e840, vec3(_e843));
    let _e846 = gEmissive;
    let _e848 = vParams_1;
    let _e852 = color_1;
    color_1 = (_e852 + (max(_e846, vec3<f32>(0f, 0f, 0f)) * (vec3<f32>(1f, 1f, 1f) + _e848.yzw)));
    let _e855 = frame.cameraPos;
    let _e857 = vWorldPos_1;
    dist = length((_e855.xyz - _e857));
    let _e860 = dist;
    let _e864 = frame.fogColor[3u];
    fog = (1f - exp((-(_e860) * _e864)));
    let _e870 = frame.groundColor[3u];
    if (_e870 != 0f) {
        let _e874 = frame.groundColor[3u];
        k = _e874;
        let _e875 = vWorldPos_1;
        let _e877 = frame.cameraPos;
        toEye = (_e875 - _e877.xyz);
        let _e880 = k;
        let _e882 = toEye[1u];
        x_1 = (_e880 * _e882);
        let _e884 = x_1;
        if (abs(_e884) < 0.0001f) {
            let _e887 = x_1;
            local_6 = (1f - (0.5f * _e887));
        } else {
            let _e890 = x_1;
            let _e895 = x_1;
            local_6 = ((1f - exp(min(-(_e890), 60f))) / _e895);
        }
        let _e897 = local_6;
        span = _e897;
        let _e900 = frame.fogColor[3u];
        let _e901 = k;
        let _e905 = frame.cameraPos[1u];
        let _e908 = frame.cameraPos[3u];
        atEye = (_e900 * exp(min((-(_e901) * (_e905 - _e908)), 30f)));
        let _e914 = dist;
        let _e916 = atEye;
        let _e918 = span;
        fog = (1f - exp(((-(_e914) * _e916) * _e918)));
    }
    let _e922 = color_1;
    let _e924 = frame.fogColor;
    let _e926 = fog;
    rgb = mix(_e922, _e924.xyz, vec3(_e926));
    let _e931 = frame.reflectionExtra[3u];
    if (_e931 > 0.5f) {
        let _e933 = rgb;
        let _e936 = rgb;
        rgb = (_e936 / (vec3(1f) + _e933));
    }
    let _e938 = rgb;
    let _e939 = opacity;
    outColor = vec4<f32>(_e938.x, _e938.y, _e938.z, _e939);
    let _e944 = vCurrentClip_1;
    param_76 = _e944;
    let _e945 = vPreviousClip_1;
    param_77 = _e945;
    let _e946 = motionVector_u0028_vf4_u003b_vf4_u003b((&param_76), (&param_77));
    outMotion = _e946;
    return;
}

@fragment 
fn main(@location(0) vWorldPos: vec3<f32>, @builtin(position) gl_FragCoord: vec4<f32>, @location(2) vUV: vec2<f32>, @location(1) vNormal: vec3<f32>, @location(3) vColor: vec4<f32>, @location(8) vTangent: vec4<f32>, @builtin(front_facing) gl_FrontFacing: bool, @location(5) vParams: vec4<f32>, @location(6) vCurrentClip: vec4<f32>, @location(7) vPreviousClip: vec4<f32>) -> FragmentOutput {
    vWorldPos_1 = vWorldPos;
    gl_FragCoord_1 = gl_FragCoord;
    vUV_1 = vUV;
    vNormal_1 = vNormal;
    vColor_1 = vColor;
    vTangent_1 = vTangent;
    gl_FrontFacing_1 = gl_FrontFacing;
    vParams_1 = vParams;
    vCurrentClip_1 = vCurrentClip;
    vPreviousClip_1 = vPreviousClip;
    main_1();
    let _e22 = outColor;
    let _e23 = outMotion;
    return FragmentOutput(_e22, _e23);
}
