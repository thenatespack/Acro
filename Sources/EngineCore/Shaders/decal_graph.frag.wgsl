// Generated from decal_graph.frag by Scripts/compile-shaders.sh — do not edit.
// Edit the GLSL and rerun the script (needs glslc, spirv-cross, spirv-opt and naga-cli).
// spirv-fnv1a64: 0e14b12390ec91a5
// glsl-fnv1a64: bfa194a2c6dcdead

diagnostic(off, derivative_uniformity);

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
}

struct MaterialGraphValues {
    values: array<vec4<f32>>,
}

struct DecalData {
    model: mat4x4<f32>,
    inverseModel: mat4x4<f32>,
    inverseViewProj: mat4x4<f32>,
    color: vec4<f32>,
    params: vec4<f32>,
    axis: vec4<f32>,
}

struct MaterialGraphPush {
    params: vec4<f32>,
    eye: vec4<f32>,
}

struct LightCells {
    data: array<vec4<u32>, 1024>,
}

struct LightIndices {
    data: array<vec4<u32>, 1024>,
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

@group(0) @binding(0) 
var<uniform> frame: Frame;
@group(1) @binding(1) 
var shadowMap_sampler: sampler_comparison;
@group(1) @binding(0) 
var shadowMap_image: texture_depth_2d;
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
@group(2) @binding(14) 
var environmentAtlas: texture_2d<f32>;
@group(2) @binding(15) 
var sceneDepth: texture_2d<f32>;
@group(2) @binding(2) 
var<uniform> decal: DecalData;
var<private> gl_FragCoord_1: vec4<f32>;
@group(3) @binding(0) 
var<uniform> graphPush: MaterialGraphPush;
@group(2) @binding(6) 
var<uniform> lightCells: LightCells;
@group(2) @binding(7) 
var<uniform> lightIndices: LightIndices;
@group(2) @binding(3) 
var<uniform> lightPositions: LightPositions;
@group(2) @binding(4) 
var<uniform> lightColors: LightColors;
@group(2) @binding(5) 
var<uniform> lightDirections: LightDirections;
var<private> outColor: vec4<f32>;

fn shadowPCF_u0028_vf2_u003b_f1_u003b_vf4_u003b(uv: ptr<function, vec2<f32>>, ref_: ptr<function, f32>, bounds: ptr<function, vec4<f32>>) -> f32 {
    var texel: vec2<f32>;
    var radius: i32;
    var p: vec2<f32>;
    var base: vec2<f32>;
    var st: vec2<f32>;
    var w: array<vec2<f32>, 3>;
    var o: array<vec2<f32>, 3>;
    var n: i32;
    var norm: f32;
    var sum: f32;
    var j: i32;
    var i: i32;
    var tap: vec2<f32>;

    let _e174 = frame.shadowAtlas;
    texel = _e174.xy;
    let _e178 = frame.shadowAtlas[2u];
    radius = i32(_e178);
    let _e180 = radius;
    if (_e180 <= 0i) {
        let _e182 = (*uv);
        let _e183 = (*bounds);
        let _e185 = (*bounds);
        let _e187 = clamp(_e182, _e183.xy, _e185.zw);
        let _e188 = (*ref_);
        let _e191 = vec3<f32>(_e187.x, _e187.y, _e188);
        let _e194 = textureSampleCompare(shadowMap_image, shadowMap_sampler, _e191.xy, _e191.z);
        return _e194;
    }
    let _e195 = (*uv);
    let _e196 = texel;
    p = (_e195 / _e196);
    let _e198 = p;
    base = floor((_e198 + vec2(0.5f)));
    let _e202 = p;
    let _e205 = base;
    st = ((_e202 + vec2(0.5f)) - _e205);
    let _e207 = base;
    let _e210 = texel;
    base = ((_e207 - vec2(0.5f)) * _e210);
    let _e212 = radius;
    if (_e212 == 1i) {
        let _e214 = st;
        w[0i] = (vec2(3f) - (_e214 * 2f));
        let _e219 = st;
        w[1i] = (vec2(1f) + (_e219 * 2f));
        let _e224 = st;
        let _e228 = w[0i];
        o[0i] = (((vec2(2f) - _e224) / _e228) - vec2(1f));
        let _e233 = st;
        let _e235 = w[1i];
        o[1i] = ((_e233 / _e235) + vec2(1f));
        n = 2i;
        norm = 0.0625f;
    } else {
        let _e240 = st;
        w[0i] = (vec2(4f) - (_e240 * 3f));
        w[1i] = vec2<f32>(7f, 7f);
        let _e246 = st;
        w[2i] = (vec2(1f) + (_e246 * 3f));
        let _e251 = st;
        let _e256 = w[0i];
        o[0i] = (((vec2(3f) - (_e251 * 2f)) / _e256) - vec2(2f));
        let _e261 = st;
        let _e265 = w[1i];
        o[1i] = ((vec2(3f) + _e261) / _e265);
        let _e268 = st;
        let _e270 = w[2i];
        o[2i] = ((_e268 / _e270) + vec2(2f));
        n = 3i;
        norm = 0.0069444445f;
    }
    sum = 0f;
    j = 0i;
    loop {
        let _e275 = j;
        let _e276 = n;
        if (_e275 < _e276) {
            i = 0i;
            loop {
                let _e278 = i;
                let _e279 = n;
                if (_e278 < _e279) {
                    let _e281 = base;
                    let _e282 = i;
                    let _e285 = o[_e282][0u];
                    let _e286 = j;
                    let _e289 = o[_e286][1u];
                    let _e291 = texel;
                    let _e294 = (*bounds);
                    let _e296 = (*bounds);
                    tap = clamp((_e281 + (vec2<f32>(_e285, _e289) * _e291)), _e294.xy, _e296.zw);
                    let _e299 = i;
                    let _e302 = w[_e299][0u];
                    let _e303 = j;
                    let _e306 = w[_e303][1u];
                    let _e308 = tap;
                    let _e309 = (*ref_);
                    let _e312 = vec3<f32>(_e308.x, _e308.y, _e309);
                    let _e315 = textureSampleCompare(shadowMap_image, shadowMap_sampler, _e312.xy, _e312.z);
                    let _e317 = sum;
                    sum = (_e317 + ((_e302 * _e306) * _e315));
                    continue;
                } else {
                    break;
                }
                continuing {
                    let _e319 = i;
                    i = (_e319 + 1i);
                }
            }
            continue;
        } else {
            break;
        }
        continuing {
            let _e321 = j;
            j = (_e321 + 1i);
        }
    }
    let _e323 = sum;
    let _e324 = norm;
    return (_e323 * _e324);
}

fn tileShadow_u0028_vf2_u003b_f1_u003b_vf2_u003b_vf2_u003b(local: ptr<function, vec2<f32>>, ref_1: ptr<function, f32>, origin: ptr<function, vec2<f32>>, size: ptr<function, vec2<f32>>) -> f32 {
    var halfTexel: vec2<f32>;
    var param: vec2<f32>;
    var param_1: f32;
    var param_2: vec4<f32>;

    let _e166 = frame.shadowAtlas;
    halfTexel = (_e166.xy * 0.5f);
    let _e169 = (*origin);
    let _e170 = (*local);
    let _e171 = (*size);
    let _e174 = (*origin);
    let _e175 = halfTexel;
    let _e176 = (_e174 + _e175);
    let _e177 = (*origin);
    let _e178 = (*size);
    let _e180 = halfTexel;
    let _e181 = ((_e177 + _e178) - _e180);
    param = (_e169 + (_e170 * _e171));
    let _e187 = (*ref_1);
    param_1 = _e187;
    param_2 = vec4<f32>(_e176.x, _e176.y, _e181.x, _e181.y);
    let _e188 = shadowPCF_u0028_vf2_u003b_f1_u003b_vf4_u003b((&param), (&param_1), (&param_2));
    return _e188;
}

fn localShadow_u0028_u1_u003b_vf3_u003b_vf3_u003b_vf3_u003b(index: ptr<function, u32>, p_1: ptr<function, vec3<f32>>, ng: ptr<function, vec3<f32>>, l: ptr<function, vec3<f32>>) -> f32 {
    var spots: u32;
    var params: vec4<f32>;
    var clip0_: vec4<f32>;
    var texel_1: f32;
    var q: vec3<f32>;
    var clip: vec4<f32>;
    var local_1: vec3<f32>;
    var param_3: vec2<f32>;
    var param_4: f32;
    var param_5: vec2<f32>;
    var param_6: vec2<f32>;
    var point: u32;
    var position: vec4<f32>;
    var params_1: vec4<f32>;
    var texel_2: f32;
    var d: vec3<f32>;
    var a: vec3<f32>;
    var face: i32;
    var m: f32;
    var st_1: vec2<f32>;
    var indexable: array<vec3<f32>, 6>;
    var indexable_1: array<vec3<f32>, 6>;
    var ref_2: f32;
    var origin_1: vec2<f32>;
    var param_7: vec2<f32>;
    var param_8: f32;
    var param_9: vec2<f32>;
    var param_10: vec2<f32>;
    var phi_663_: bool;
    var phi_670_: bool;
    var phi_677_: bool;
    var phi_684_: bool;
    var phi_768_: bool;

    let _e191 = frame.shadowInfo[2u];
    spots = u32(_e191);
    let _e193 = (*index);
    let _e194 = spots;
    if (_e193 < _e194) {
        let _e196 = (*index);
        let _e199 = frame.spotShadowParams[_e196];
        params = _e199;
        let _e200 = (*index);
        let _e203 = frame.spotShadowMatrices[_e200];
        let _e204 = (*p_1);
        clip0_ = (_e203 * vec4<f32>(_e204.x, _e204.y, _e204.z, 1f));
        let _e211 = params[2u];
        let _e213 = clip0_[3u];
        texel_1 = (_e211 * max(_e213, 0f));
        let _e216 = (*p_1);
        let _e217 = (*ng);
        let _e218 = texel_1;
        let _e221 = frame.shadowLocal[0u];
        let _e225 = (*l);
        let _e226 = texel_1;
        let _e229 = frame.shadowLocal[1u];
        q = ((_e216 + (_e217 * (_e218 * _e221))) + (_e225 * (_e226 * _e229)));
        let _e233 = (*index);
        let _e236 = frame.spotShadowMatrices[_e233];
        let _e237 = q;
        clip = (_e236 * vec4<f32>(_e237.x, _e237.y, _e237.z, 1f));
        let _e244 = clip[3u];
        if (_e244 <= 0f) {
            return 1f;
        }
        let _e246 = clip;
        let _e249 = clip[3u];
        local_1 = (_e246.xyz / vec3(_e249));
        let _e253 = local_1[0u];
        let _e254 = (_e253 < 0f);
        phi_663_ = _e254;
        if !(_e254) {
            let _e257 = local_1[0u];
            phi_663_ = (_e257 > 1f);
        }
        let _e260 = phi_663_;
        phi_670_ = _e260;
        if !(_e260) {
            let _e263 = local_1[1u];
            phi_670_ = (_e263 < 0f);
        }
        let _e266 = phi_670_;
        phi_677_ = _e266;
        if !(_e266) {
            let _e269 = local_1[1u];
            phi_677_ = (_e269 > 1f);
        }
        let _e272 = phi_677_;
        phi_684_ = _e272;
        if !(_e272) {
            let _e275 = local_1[2u];
            phi_684_ = (_e275 > 1f);
        }
        let _e278 = phi_684_;
        if _e278 {
            return 1f;
        }
        let _e279 = local_1;
        param_3 = _e279.xy;
        let _e282 = local_1[2u];
        param_4 = _e282;
        let _e283 = params;
        param_5 = _e283.xy;
        let _e286 = frame.shadowTiles;
        param_6 = _e286.zw;
        let _e288 = tileShadow_u0028_vf2_u003b_f1_u003b_vf2_u003b_vf2_u003b((&param_3), (&param_4), (&param_5), (&param_6));
        return _e288;
    }
    let _e289 = (*index);
    let _e290 = spots;
    point = (_e289 - _e290);
    let _e292 = point;
    let _e295 = frame.shadowInfo[3u];
    if (_e292 >= u32(_e295)) {
        return 1f;
    }
    let _e298 = point;
    let _e301 = frame.pointShadowPositions[_e298];
    position = _e301;
    let _e302 = point;
    let _e305 = frame.pointShadowParams[_e302];
    params_1 = _e305;
    let _e307 = position[3u];
    let _e308 = (*p_1);
    let _e309 = position;
    texel_2 = (_e307 * length((_e308 - _e309.xyz)));
    let _e314 = (*p_1);
    let _e315 = (*ng);
    let _e316 = texel_2;
    let _e319 = frame.shadowLocal[0u];
    let _e323 = (*l);
    let _e324 = texel_2;
    let _e327 = frame.shadowLocal[1u];
    let _e331 = position;
    d = (((_e314 + (_e315 * (_e316 * _e319))) + (_e323 * (_e324 * _e327))) - _e331.xyz);
    let _e334 = d;
    a = abs(_e334);
    let _e337 = a[0u];
    let _e339 = a[1u];
    let _e340 = (_e337 >= _e339);
    phi_768_ = _e340;
    if _e340 {
        let _e342 = a[0u];
        let _e344 = a[2u];
        phi_768_ = (_e342 >= _e344);
    }
    let _e347 = phi_768_;
    if _e347 {
        let _e349 = d[0u];
        face = select(1i, 0i, (_e349 > 0f));
        let _e353 = a[0u];
        m = _e353;
    } else {
        let _e355 = a[1u];
        let _e357 = a[2u];
        if (_e355 >= _e357) {
            let _e360 = d[1u];
            face = select(3i, 2i, (_e360 > 0f));
            let _e364 = a[1u];
            m = _e364;
        } else {
            let _e366 = d[2u];
            face = select(5i, 4i, (_e366 > 0f));
            let _e370 = a[2u];
            m = _e370;
        }
    }
    let _e371 = m;
    if (_e371 <= 0f) {
        return 1f;
    }
    let _e373 = d;
    let _e374 = face;
    indexable = array<vec3<f32>, 6>(vec3<f32>(0f, 0f, 1f), vec3<f32>(0f, 0f, -1f), vec3<f32>(-1f, 0f, 0f), vec3<f32>(-1f, 0f, 0f), vec3<f32>(-1f, 0f, 0f), vec3<f32>(1f, 0f, 0f));
    let _e376 = indexable[_e374];
    let _e378 = d;
    let _e379 = face;
    indexable_1 = array<vec3<f32>, 6>(vec3<f32>(0f, 1f, 0f), vec3<f32>(0f, 1f, 0f), vec3<f32>(0f, 0f, -1f), vec3<f32>(0f, 0f, 1f), vec3<f32>(0f, 1f, 0f), vec3<f32>(0f, 1f, 0f));
    let _e381 = indexable_1[_e379];
    let _e384 = m;
    let _e387 = frame.shadowFaces[2u];
    st_1 = (vec2<f32>(dot(_e373, _e376), dot(_e378, _e381)) / vec2((_e384 * _e387)));
    let _e392 = params_1[2u];
    let _e394 = params_1[3u];
    let _e395 = m;
    ref_2 = (_e392 + (_e394 / _e395));
    let _e398 = ref_2;
    if (_e398 > 1f) {
        return 1f;
    }
    let _e400 = params_1;
    let _e402 = face;
    let _e411 = face;
    let _e416 = frame.shadowFaces;
    origin_1 = (_e400.xy + (vec2<f32>(f32((_e402 - (i32(floor((f32(_e402) / f32(3i)))) * 3i))), f32((_e411 / 3i))) * _e416.xy));
    let _e421 = st_1[0u];
    let _e425 = st_1[1u];
    param_7 = vec2<f32>((0.5f + (0.5f * _e421)), (0.5f - (0.5f * _e425)));
    let _e429 = ref_2;
    param_8 = _e429;
    let _e430 = origin_1;
    param_9 = _e430;
    let _e432 = frame.shadowFaces;
    param_10 = _e432.xy;
    let _e434 = tileShadow_u0028_vf2_u003b_f1_u003b_vf2_u003b_vf2_u003b((&param_7), (&param_8), (&param_9), (&param_10));
    return _e434;
}

fn hemisphere_u0028_vf3_u003b(d_1: ptr<function, vec3<f32>>) -> vec3<f32> {
    let _e159 = frame.groundColor;
    let _e162 = frame.skyColor;
    let _e165 = (*d_1)[1u];
    let _e172 = frame.skyColor[3u];
    return (mix(_e159.xyz, _e162.xyz, vec3(((_e165 * 0.5f) + 0.5f))) * _e172);
}

fn sampleEquirect_u0028_t21_u003b_p1_u003b_vi4_u003b_vf2_u003b(image: texture_2d<f32>, s: sampler, region: ptr<function, vec4<i32>>, uv_1: ptr<function, vec2<f32>>) -> vec3<f32> {
    var p_2: vec2<f32>;
    var f: vec2<f32>;
    var t: vec2<f32>;
    var x0_: i32;
    var y0_: i32;
    var x1_: i32;
    var local_2: i32;
    var y1_: i32;
    var a_1: vec3<f32>;
    var b: vec3<f32>;
    var c: vec3<f32>;
    var d_2: vec3<f32>;

    let _e173 = (*uv_1);
    let _e174 = (*region);
    p_2 = ((_e173 * vec2<f32>(_e174.zw)) - vec2(0.5f));
    let _e180 = p_2;
    f = floor(_e180);
    let _e182 = p_2;
    let _e183 = f;
    t = (_e182 - _e183);
    let _e186 = f[0u];
    x0_ = i32(_e186);
    let _e189 = f[1u];
    y0_ = i32(_e189);
    let _e191 = x0_;
    if (_e191 < 0i) {
        let _e194 = (*region)[2u];
        let _e195 = x0_;
        x0_ = (_e195 + _e194);
    }
    let _e197 = x0_;
    let _e199 = (*region)[2u];
    if (_e197 >= _e199) {
        let _e202 = (*region)[2u];
        let _e203 = x0_;
        x0_ = (_e203 - _e202);
    }
    let _e205 = x0_;
    let _e208 = (*region)[2u];
    if ((_e205 + 1i) == _e208) {
        local_2 = 0i;
    } else {
        let _e210 = x0_;
        local_2 = (_e210 + 1i);
    }
    let _e212 = local_2;
    x1_ = _e212;
    let _e213 = y0_;
    let _e216 = (*region)[3u];
    y1_ = min((_e213 + 1i), (_e216 - 1i));
    let _e219 = y0_;
    y0_ = max(_e219, 0i);
    let _e221 = (*region);
    let _e223 = x0_;
    let _e224 = y0_;
    let _e227 = textureLoad(image, (_e221.xy + vec2<i32>(_e223, _e224)), 0i);
    a_1 = _e227.xyz;
    let _e229 = (*region);
    let _e231 = x1_;
    let _e232 = y0_;
    let _e235 = textureLoad(image, (_e229.xy + vec2<i32>(_e231, _e232)), 0i);
    b = _e235.xyz;
    let _e237 = (*region);
    let _e239 = x0_;
    let _e240 = y1_;
    let _e243 = textureLoad(image, (_e237.xy + vec2<i32>(_e239, _e240)), 0i);
    c = _e243.xyz;
    let _e245 = (*region);
    let _e247 = x1_;
    let _e248 = y1_;
    let _e251 = textureLoad(image, (_e245.xy + vec2<i32>(_e247, _e248)), 0i);
    d_2 = _e251.xyz;
    let _e253 = a_1;
    let _e254 = b;
    let _e256 = t[0u];
    let _e259 = c;
    let _e260 = d_2;
    let _e262 = t[0u];
    let _e266 = t[1u];
    return mix(mix(_e253, _e254, vec3(_e256)), mix(_e259, _e260, vec3(_e262)), vec3(_e266));
}

fn equirectUV_u0028_vf3_u003b(d_3: ptr<function, vec3<f32>>) -> vec2<f32> {
    let _e159 = (*d_3)[0u];
    let _e161 = (*d_3)[2u];
    let _e167 = (*d_3)[1u];
    return vec2<f32>(((atan2(_e159, -(_e161)) * 0.15915494f) + 0.5f), (acos(clamp(_e167, -1f, 1f)) * 0.31830987f));
}

fn environmentDirection_u0028_vf3_u003b_vf2_u003b(d_4: ptr<function, vec3<f32>>, cs: ptr<function, vec2<f32>>) -> vec3<f32> {
    let _e160 = (*cs)[0u];
    let _e162 = (*d_4)[0u];
    let _e165 = (*cs)[1u];
    let _e167 = (*d_4)[2u];
    let _e171 = (*d_4)[1u];
    let _e173 = (*cs)[1u];
    let _e175 = (*d_4)[0u];
    let _e178 = (*cs)[0u];
    let _e180 = (*d_4)[2u];
    return vec3<f32>(((_e160 * _e162) - (_e165 * _e167)), _e171, ((_e173 * _e175) + (_e178 * _e180)));
}

fn environmentRadiance_u0028_vf3_u003b_f1_u003b(d_5: ptr<function, vec3<f32>>, roughness: ptr<function, f32>) -> vec3<f32> {
    var uv_2: vec2<f32>;
    var param_11: vec3<f32>;
    var param_12: vec2<f32>;
    var param_13: vec3<f32>;
    var level: f32;
    var i_1: i32;
    var a_2: vec3<f32>;
    var param_14: vec4<i32>;
    var indexable_2: array<vec4<i32>, 6>;
    var param_15: vec2<f32>;
    var b_1: vec3<f32>;
    var param_16: vec4<i32>;
    var indexable_3: array<vec4<i32>, 6>;
    var param_17: vec2<f32>;

    let _e173 = (*d_5);
    param_11 = _e173;
    let _e175 = frame.environment;
    param_12 = _e175.zw;
    let _e177 = environmentDirection_u0028_vf3_u003b_vf2_u003b((&param_11), (&param_12));
    param_13 = _e177;
    let _e178 = equirectUV_u0028_vf3_u003b((&param_13));
    uv_2 = _e178;
    let _e179 = (*roughness);
    level = (_e179 * 5f);
    let _e181 = level;
    i_1 = min(i32(_e181), 4i);
    let _e184 = i_1;
    indexable_2 = array<vec4<i32>, 6>(vec4<i32>(0i, 0i, 512i, 256i), vec4<i32>(0i, 256i, 256i, 128i), vec4<i32>(256i, 256i, 128i, 64i), vec4<i32>(384i, 256i, 64i, 32i), vec4<i32>(448i, 256i, 32i, 16i), vec4<i32>(480i, 256i, 16i, 8i));
    let _e186 = indexable_2[_e184];
    param_14 = _e186;
    let _e187 = uv_2;
    param_15 = _e187;
    let _e188 = sampleEquirect_u0028_t21_u003b_p1_u003b_vi4_u003b_vf2_u003b(environmentAtlas, materialSampler, (&param_14), (&param_15));
    a_2 = _e188;
    let _e189 = i_1;
    indexable_3 = array<vec4<i32>, 6>(vec4<i32>(0i, 0i, 512i, 256i), vec4<i32>(0i, 256i, 256i, 128i), vec4<i32>(256i, 256i, 128i, 64i), vec4<i32>(384i, 256i, 64i, 32i), vec4<i32>(448i, 256i, 32i, 16i), vec4<i32>(480i, 256i, 16i, 8i));
    let _e192 = indexable_3[(_e189 + 1i)];
    param_16 = _e192;
    let _e193 = uv_2;
    param_17 = _e193;
    let _e194 = sampleEquirect_u0028_t21_u003b_p1_u003b_vi4_u003b_vf2_u003b(environmentAtlas, materialSampler, (&param_16), (&param_17));
    b_1 = _e194;
    let _e195 = a_2;
    let _e196 = b_1;
    let _e197 = level;
    let _e198 = i_1;
    let _e205 = frame.environment[1u];
    return (mix(_e195, _e196, vec3((_e197 - f32(_e198)))) * _e205);
}

fn shBasis_u0028_vf3_u003b_f1_u005b_9_u005d_u003b(d_6: ptr<function, vec3<f32>>, y: ptr<function, array<f32, 9>>) {
    (*y)[0i] = 0.282095f;
    let _e161 = (*d_6)[1u];
    (*y)[1i] = (0.488603f * _e161);
    let _e165 = (*d_6)[2u];
    (*y)[2i] = (0.488603f * _e165);
    let _e169 = (*d_6)[0u];
    (*y)[3i] = (0.488603f * _e169);
    let _e173 = (*d_6)[0u];
    let _e176 = (*d_6)[1u];
    (*y)[4i] = ((1.092548f * _e173) * _e176);
    let _e180 = (*d_6)[1u];
    let _e183 = (*d_6)[2u];
    (*y)[5i] = ((1.092548f * _e180) * _e183);
    let _e187 = (*d_6)[2u];
    let _e190 = (*d_6)[2u];
    (*y)[6i] = (0.315392f * (((3f * _e187) * _e190) - 1f));
    let _e196 = (*d_6)[0u];
    let _e199 = (*d_6)[2u];
    (*y)[7i] = ((1.092548f * _e196) * _e199);
    let _e203 = (*d_6)[0u];
    let _e205 = (*d_6)[0u];
    let _e208 = (*d_6)[1u];
    let _e210 = (*d_6)[1u];
    (*y)[8i] = (0.546274f * ((_e203 * _e205) - (_e208 * _e210)));
    return;
}

fn environmentIrradiance_u0028_vf3_u003b(n_1: ptr<function, vec3<f32>>) -> vec3<f32> {
    var param_18: vec3<f32>;
    var param_19: vec2<f32>;
    var y_1: array<f32, 9>;
    var param_20: vec3<f32>;
    var param_21: array<f32, 9>;
    var sum_1: vec3<f32>;
    var i_2: i32;

    let _e165 = (*n_1);
    param_18 = _e165;
    let _e167 = frame.environment;
    param_19 = _e167.zw;
    let _e169 = environmentDirection_u0028_vf3_u003b_vf2_u003b((&param_18), (&param_19));
    param_20 = _e169;
    shBasis_u0028_vf3_u003b_f1_u005b_9_u005d_u003b((&param_20), (&param_21));
    let _e170 = param_21;
    y_1 = _e170;
    sum_1 = vec3<f32>(0f, 0f, 0f);
    i_2 = 0i;
    loop {
        let _e171 = i_2;
        if (_e171 < 9i) {
            let _e173 = i_2;
            let _e176 = textureLoad(environmentAtlas, (vec2<i32>(496i, 256i) + vec2<i32>(_e173, 0i)), 0i);
            let _e178 = i_2;
            let _e180 = y_1[_e178];
            let _e182 = sum_1;
            sum_1 = (_e182 + (_e176.xyz * _e180));
            continue;
        } else {
            break;
        }
        continuing {
            let _e184 = i_2;
            i_2 = (_e184 + 1i);
        }
    }
    let _e186 = sum_1;
    let _e190 = frame.environment[1u];
    return (max(_e186, vec3<f32>(0f, 0f, 0f)) * _e190);
}

fn environmentBRDF_u0028_f1_u003b_f1_u003b(NoV: ptr<function, f32>, roughness_1: ptr<function, f32>) -> vec2<f32> {
    var r: vec4<f32>;
    var a004_: f32;

    let _e161 = (*roughness_1);
    r = ((vec4<f32>(-1f, -0.0275f, -0.572f, 0.022f) * _e161) + vec4<f32>(1f, 0.0425f, 1.04f, -0.04f));
    let _e165 = r[0u];
    let _e167 = r[0u];
    let _e169 = (*NoV);
    let _e174 = r[0u];
    let _e177 = r[1u];
    a004_ = ((min((_e165 * _e167), exp2((-9.28f * _e169))) * _e174) + _e177);
    let _e179 = a004_;
    let _e181 = r;
    return ((vec2<f32>(-1.04f, 1.04f) * _e179) + _e181.zw);
}

fn visibilitySmithGGXCorrelated_u0028_f1_u003b_f1_u003b_f1_u003b(NoV_1: ptr<function, f32>, NoL: ptr<function, f32>, a_3: ptr<function, f32>) -> f32 {
    var a2_: f32;
    var ggxV: f32;
    var ggxL: f32;

    let _e163 = (*a_3);
    let _e164 = (*a_3);
    a2_ = (_e163 * _e164);
    let _e166 = (*NoL);
    let _e167 = (*NoV_1);
    let _e168 = (*NoV_1);
    let _e170 = a2_;
    let _e173 = a2_;
    ggxV = (_e166 * sqrt((((_e167 * _e168) * (1f - _e170)) + _e173)));
    let _e177 = (*NoV_1);
    let _e178 = (*NoL);
    let _e179 = (*NoL);
    let _e181 = a2_;
    let _e184 = a2_;
    ggxL = (_e177 * sqrt((((_e178 * _e179) * (1f - _e181)) + _e184)));
    let _e188 = ggxV;
    let _e189 = ggxL;
    return (0.5f / max((_e188 + _e189), 0.00001f));
}

fn distributionGGX_u0028_f1_u003b_f1_u003b(NoH: ptr<function, f32>, a_4: ptr<function, f32>) -> f32 {
    var a2_1: f32;
    var d_7: f32;

    let _e161 = (*a_4);
    let _e162 = (*a_4);
    a2_1 = (_e161 * _e162);
    let _e164 = (*NoH);
    let _e165 = (*NoH);
    let _e167 = a2_1;
    d_7 = (((_e164 * _e165) * (_e167 - 1f)) + 1f);
    let _e171 = a2_1;
    let _e172 = d_7;
    let _e174 = d_7;
    return (_e171 / ((3.1415927f * _e172) * _e174));
}

fn fresnelSchlick_u0028_vf3_u003b_f1_u003b(f0_: ptr<function, vec3<f32>>, VoH: ptr<function, f32>) -> vec3<f32> {
    var f_1: f32;

    let _e160 = (*VoH);
    f_1 = pow((1f - _e160), 5f);
    let _e163 = (*f0_);
    let _e164 = (*f0_);
    let _e166 = f_1;
    return (_e163 + ((vec3<f32>(1f, 1f, 1f) - _e164) * _e166));
}

fn cascadeShadow_u0028_i1_u003b_vf3_u003b(c_1: ptr<function, i32>, p_3: ptr<function, vec3<f32>>) -> f32 {
    var local_3: vec3<f32>;
    var origin_2: vec2<f32>;
    var param_22: vec2<f32>;
    var param_23: f32;
    var param_24: vec2<f32>;
    var param_25: vec2<f32>;
    var phi_393_: bool;
    var phi_400_: bool;
    var phi_407_: bool;

    let _e165 = (*c_1);
    let _e168 = frame.cascadeMatrices[_e165];
    let _e169 = (*p_3);
    local_3 = (_e168 * vec4<f32>(_e169.x, _e169.y, _e169.z, 1f)).xyz;
    let _e177 = local_3[0u];
    let _e178 = (_e177 < 0f);
    phi_393_ = _e178;
    if !(_e178) {
        let _e181 = local_3[0u];
        phi_393_ = (_e181 > 1f);
    }
    let _e184 = phi_393_;
    phi_400_ = _e184;
    if !(_e184) {
        let _e187 = local_3[1u];
        phi_400_ = (_e187 < 0f);
    }
    let _e190 = phi_400_;
    phi_407_ = _e190;
    if !(_e190) {
        let _e193 = local_3[1u];
        phi_407_ = (_e193 > 1f);
    }
    let _e196 = phi_407_;
    if _e196 {
        return 1f;
    }
    let _e197 = (*c_1);
    let _e200 = (*c_1);
    let _e206 = frame.shadowTiles;
    origin_2 = (vec2<f32>(f32((_e197 & 1i)), f32((_e200 >> bitcast<u32>(1i)))) * _e206.xy);
    let _e210 = local_3[2u];
    let _e212 = (*c_1);
    let _e215 = frame.cascadeBiases[_e212];
    let _e217 = local_3;
    param_22 = _e217.xy;
    param_23 = (min(_e210, 1f) - _e215);
    let _e219 = origin_2;
    param_24 = _e219;
    let _e221 = frame.shadowTiles;
    param_25 = _e221.xy;
    let _e223 = tileShadow_u0028_vf2_u003b_f1_u003b_vf2_u003b_vf2_u003b((&param_22), (&param_23), (&param_24), (&param_25));
    return _e223;
}

fn directionalShadow_u0028_vf3_u003b_vf3_u003b_vf3_u003b(p_4: ptr<function, vec3<f32>>, ng_1: ptr<function, vec3<f32>>, tint: ptr<function, vec3<f32>>) -> f32 {
    var count: i32;
    var depth: f32;
    var c_2: i32;
    var s_1: f32;
    var param_26: i32;
    var param_27: vec3<f32>;
    var t_1: vec3<f32>;
    var indexable_4: array<vec3<f32>, 4>;
    var start: f32;
    var f_2: f32;
    var param_28: i32;
    var param_29: vec3<f32>;
    var indexable_5: array<vec3<f32>, 4>;
    var phi_479_: bool;

    (*tint) = vec3<f32>(1f, 1f, 1f);
    let _e175 = frame.shadowInfo[0u];
    count = i32(_e175);
    let _e178 = frame.shadowDepthRow;
    let _e180 = (*p_4);
    let _e184 = frame.shadowDepthRow[3u];
    depth = (dot(_e178.xyz, _e180) + _e184);
    c_2 = 0i;
    loop {
        let _e186 = c_2;
        let _e187 = count;
        let _e189 = (_e186 < (_e187 - 1i));
        phi_479_ = _e189;
        if _e189 {
            let _e190 = depth;
            let _e191 = c_2;
            let _e194 = frame.cascadeSplits[_e191];
            phi_479_ = (_e190 > _e194);
        }
        let _e197 = phi_479_;
        if _e197 {
            let _e198 = c_2;
            c_2 = (_e198 + 1i);
            continue;
        } else {
            break;
        }
    }
    let _e200 = depth;
    let _e201 = c_2;
    let _e204 = frame.cascadeSplits[_e201];
    if (_e200 > _e204) {
        return 1f;
    }
    let _e206 = (*p_4);
    let _e207 = (*ng_1);
    let _e208 = c_2;
    let _e211 = frame.cascadeNormalOffsets[_e208];
    let _e214 = c_2;
    param_26 = _e214;
    param_27 = (_e206 + (_e207 * _e211));
    let _e215 = cascadeShadow_u0028_i1_u003b_vf3_u003b((&param_26), (&param_27));
    s_1 = _e215;
    let _e216 = c_2;
    indexable_4 = array<vec3<f32>, 4>(vec3<f32>(1f, 0.45f, 0.45f), vec3<f32>(0.45f, 1f, 0.45f), vec3<f32>(0.5f, 0.6f, 1f), vec3<f32>(1f, 1f, 0.4f));
    let _e218 = indexable_4[_e216];
    t_1 = _e218;
    let _e219 = c_2;
    let _e222 = frame.cascadeBlendStarts[_e219];
    start = _e222;
    let _e223 = depth;
    let _e224 = start;
    if (_e223 > _e224) {
        let _e226 = depth;
        let _e227 = start;
        let _e229 = c_2;
        let _e232 = frame.cascadeSplits[_e229];
        let _e233 = start;
        f_2 = ((_e226 - _e227) / (_e232 - _e233));
        let _e236 = c_2;
        let _e238 = count;
        if ((_e236 + 1i) < _e238) {
            let _e240 = s_1;
            let _e241 = c_2;
            let _e243 = (*p_4);
            let _e244 = (*ng_1);
            let _e245 = c_2;
            let _e249 = frame.cascadeNormalOffsets[(_e245 + 1i)];
            param_28 = (_e241 + 1i);
            param_29 = (_e243 + (_e244 * _e249));
            let _e252 = cascadeShadow_u0028_i1_u003b_vf3_u003b((&param_28), (&param_29));
            let _e253 = f_2;
            s_1 = mix(_e240, _e252, _e253);
            let _e255 = t_1;
            let _e256 = c_2;
            indexable_5 = array<vec3<f32>, 4>(vec3<f32>(1f, 0.45f, 0.45f), vec3<f32>(0.45f, 1f, 0.45f), vec3<f32>(0.5f, 0.6f, 1f), vec3<f32>(1f, 1f, 0.4f));
            let _e259 = indexable_5[(_e256 + 1i)];
            let _e260 = f_2;
            t_1 = mix(_e255, _e259, vec3(_e260));
        } else {
            let _e263 = s_1;
            let _e264 = f_2;
            s_1 = mix(_e263, 1f, _e264);
        }
    }
    let _e268 = frame.shadowAtlas[3u];
    if (_e268 > 0.5f) {
        let _e270 = t_1;
        (*tint) = _e270;
    }
    let _e271 = s_1;
    return _e271;
}

fn graphSurface_u0028_() {
    var a_5: vec4<f32>;
    var b_2: vec4<f32>;
    var c_3: vec4<f32>;
    var d_8: vec4<f32>;
    var e: vec4<f32>;
    var v: vec4<f32>;

    let _e163 = gUV;
    let _e164 = textureSample(baseColorMap, materialSampler, _e163);
    a_5 = _e164;
    let _e165 = gUV;
    let _e166 = textureSample(metallicRoughnessMap, materialSampler, _e165);
    b_2 = _e166;
    let _e167 = gUV;
    let _e168 = textureSample(normalMap, materialSampler, _e167);
    c_3 = _e168;
    let _e169 = gUV;
    let _e170 = textureSample(occlusionMap, materialSampler, _e169);
    d_8 = _e170;
    let _e171 = gUV;
    let _e172 = textureSample(emissiveMap, materialSampler, _e171);
    e = _e172;
    let _e175 = graphValues.values[0i];
    v = _e175;
    let _e176 = a_5;
    let _e178 = gVertexColor;
    let _e181 = v;
    let _e184 = gPosition;
    let _e185 = gNormal;
    let _e187 = gView;
    let _e189 = gTime;
    gBaseColor = (((_e176.xyz * _e178.xyz) * _e181.xyz) + (((_e184 + _e185) + _e187) * _e189));
    let _e193 = a_5[3u];
    let _e195 = v[3u];
    gOpacity = (_e193 * _e195);
    let _e197 = c_3;
    gNormalTS = ((_e197.xyz * 2f) - vec3(1f));
    let _e203 = b_2[2u];
    gMetallic = _e203;
    let _e205 = b_2[1u];
    gRoughness = _e205;
    let _e206 = e;
    gEmissive = _e206.xyz;
    let _e209 = d_8[0u];
    gOcclusion = _e209;
    return;
}

fn decalSpace_u0028_vf3_u003b(p_5: ptr<function, vec3<f32>>) -> vec3<f32> {
    let _e159 = decal.inverseModel;
    let _e160 = (*p_5);
    return (_e159 * vec4<f32>(_e160.x, _e160.y, _e160.z, 1f)).xyz;
}

fn depthPoint_u0028_vi2_u003b_vi2_u003b(t_2: ptr<function, vec2<i32>>, size_1: ptr<function, vec2<i32>>) -> vec3<f32> {
    var z: f32;
    var ndc: vec2<f32>;
    var world: vec4<f32>;

    let _e162 = (*t_2);
    let _e163 = (*size_1);
    (*t_2) = clamp(_e162, vec2<i32>(0i, 0i), (_e163 - vec2(1i)));
    let _e167 = (*t_2);
    let _e168 = textureLoad(sceneDepth, _e167, 0i);
    z = _e168.x;
    let _e171 = (*t_2)[0u];
    let _e175 = (*size_1)[0u];
    let _e181 = (*t_2)[1u];
    let _e185 = (*size_1)[1u];
    ndc = vec2<f32>(((((f32(_e171) + 0.5f) / f32(_e175)) * 2f) - 1f), (1f - (((f32(_e181) + 0.5f) / f32(_e185)) * 2f)));
    let _e192 = decal.inverseViewProj;
    let _e193 = ndc;
    let _e194 = z;
    world = (_e192 * vec4<f32>(_e193.x, _e193.y, _e194, 1f));
    let _e199 = world;
    let _e202 = world[3u];
    return (_e199.xyz / vec3(_e202));
}

fn main_1() {
    var size_2: vec2<i32>;
    var texel_3: vec2<i32>;
    var p_6: vec3<f32>;
    var param_30: vec2<i32>;
    var param_31: vec2<i32>;
    var q_1: vec3<f32>;
    var param_32: vec3<f32>;
    var px: vec3<f32>;
    var param_33: vec2<i32>;
    var param_34: vec2<i32>;
    var mx: vec3<f32>;
    var param_35: vec2<i32>;
    var param_36: vec2<i32>;
    var py: vec3<f32>;
    var param_37: vec2<i32>;
    var param_38: vec2<i32>;
    var my: vec3<f32>;
    var param_39: vec2<i32>;
    var param_40: vec2<i32>;
    var ax: vec3<f32>;
    var bx: vec3<f32>;
    var ay: vec3<f32>;
    var by: vec3<f32>;
    var tx: vec3<f32>;
    var ty: vec3<f32>;
    var v_1: vec3<f32>;
    var n_2: vec3<f32>;
    var local_4: vec3<f32>;
    var uv_3: vec2<f32>;
    var duvdx: vec2<f32>;
    var param_41: vec3<f32>;
    var duvdy: vec2<f32>;
    var param_42: vec3<f32>;
    var albedo: vec3<f32>;
    var alpha: f32;
    var metallic: f32;
    var gt: vec3<f32>;
    var gb: vec3<f32>;
    var m_1: vec3<f32>;
    var roughness_2: f32;
    var a_6: f32;
    var f0_1: vec3<f32>;
    var diffuse: vec3<f32>;
    var l_1: vec3<f32>;
    var h: vec3<f32>;
    var shadow: f32;
    var cascadeTint: vec3<f32>;
    var param_43: vec3<f32>;
    var param_44: vec3<f32>;
    var param_45: vec3<f32>;
    var light: vec3<f32>;
    var NoV_2: f32;
    var NoL_1: f32;
    var NoH_1: f32;
    var VoH_1: f32;
    var F: vec3<f32>;
    var param_46: vec3<f32>;
    var param_47: f32;
    var specular: vec3<f32>;
    var param_48: f32;
    var param_49: f32;
    var param_50: f32;
    var param_51: f32;
    var param_52: f32;
    var color: vec3<f32>;
    var dfg: vec2<f32>;
    var param_53: f32;
    var param_54: f32;
    var irradiance: vec3<f32>;
    var param_55: vec3<f32>;
    var reflected: vec3<f32>;
    var param_56: vec3<f32>;
    var param_57: f32;
    var param_58: f32;
    var param_59: f32;
    var param_60: vec3<f32>;
    var param_61: vec3<f32>;
    var specularAmbient: vec3<f32>;
    var ao: f32;
    var depth_1: f32;
    var tile: vec2<f32>;
    var slice: f32;
    var cluster: u32;
    var cell: u32;
    var first: u32;
    var count_1: u32;
    var i_3: u32;
    var word: u32;
    var li: u32;
    var position_1: vec4<f32>;
    var toLight: vec3<f32>;
    var d2_: f32;
    var x: f32;
    var window: f32;
    var pl: vec3<f32>;
    var lc: vec4<f32>;
    var direction: vec4<f32>;
    var cone: f32;
    var radiance: vec3<f32>;
    var param_62: u32;
    var param_63: vec3<f32>;
    var param_64: vec3<f32>;
    var param_65: vec3<f32>;
    var ph: vec3<f32>;
    var pNoL: f32;
    var pNoH: f32;
    var pF: vec3<f32>;
    var param_66: vec3<f32>;
    var param_67: f32;
    var pSpecular: vec3<f32>;
    var param_68: f32;
    var param_69: f32;
    var param_70: f32;
    var param_71: f32;
    var param_72: f32;
    var dist: f32;
    var fog: f32;
    var phi_1766_: bool;
    var phi_1773_: bool;

    let _e274 = textureDimensions(sceneDepth, 0i);
    size_2 = vec2<i32>(_e274);
    let _e276 = gl_FragCoord_1;
    texel_3 = vec2<i32>(_e276.xy);
    let _e279 = texel_3;
    param_30 = _e279;
    let _e280 = size_2;
    param_31 = _e280;
    let _e281 = depthPoint_u0028_vi2_u003b_vi2_u003b((&param_30), (&param_31));
    p_6 = _e281;
    let _e282 = p_6;
    param_32 = _e282;
    let _e283 = decalSpace_u0028_vf3_u003b((&param_32));
    q_1 = _e283;
    let _e284 = q_1;
    if any((abs(_e284) > vec3<f32>(0.5f, 0.5f, 0.5f))) {
        discard;
    }
    let _e288 = texel_3;
    param_33 = (_e288 + vec2<i32>(1i, 0i));
    let _e290 = size_2;
    param_34 = _e290;
    let _e291 = depthPoint_u0028_vi2_u003b_vi2_u003b((&param_33), (&param_34));
    px = _e291;
    let _e292 = texel_3;
    param_35 = (_e292 - vec2<i32>(1i, 0i));
    let _e294 = size_2;
    param_36 = _e294;
    let _e295 = depthPoint_u0028_vi2_u003b_vi2_u003b((&param_35), (&param_36));
    mx = _e295;
    let _e296 = texel_3;
    param_37 = (_e296 + vec2<i32>(0i, 1i));
    let _e298 = size_2;
    param_38 = _e298;
    let _e299 = depthPoint_u0028_vi2_u003b_vi2_u003b((&param_37), (&param_38));
    py = _e299;
    let _e300 = texel_3;
    param_39 = (_e300 - vec2<i32>(0i, 1i));
    let _e302 = size_2;
    param_40 = _e302;
    let _e303 = depthPoint_u0028_vi2_u003b_vi2_u003b((&param_39), (&param_40));
    my = _e303;
    let _e304 = px;
    let _e305 = p_6;
    ax = (_e304 - _e305);
    let _e307 = p_6;
    let _e308 = mx;
    bx = (_e307 - _e308);
    let _e310 = py;
    let _e311 = p_6;
    ay = (_e310 - _e311);
    let _e313 = p_6;
    let _e314 = my;
    by = (_e313 - _e314);
    let _e316 = ax;
    let _e317 = ax;
    let _e319 = bx;
    let _e320 = bx;
    let _e323 = ax;
    let _e324 = bx;
    tx = select(_e324, _e323, vec3((dot(_e316, _e317) < dot(_e319, _e320))));
    let _e327 = ay;
    let _e328 = ay;
    let _e330 = by;
    let _e331 = by;
    let _e334 = ay;
    let _e335 = by;
    ty = select(_e335, _e334, vec3((dot(_e327, _e328) < dot(_e330, _e331))));
    let _e339 = frame.cameraPos;
    let _e341 = p_6;
    v_1 = (_e339.xyz - _e341);
    let _e343 = tx;
    let _e344 = ty;
    n_2 = cross(_e343, _e344);
    let _e346 = n_2;
    let _e347 = n_2;
    if (dot(_e346, _e347) > 0.00000000000000000001f) {
        let _e350 = n_2;
        local_4 = normalize(_e350);
    } else {
        let _e352 = v_1;
        local_4 = normalize(_e352);
    }
    let _e354 = local_4;
    n_2 = _e354;
    let _e355 = n_2;
    let _e356 = v_1;
    if (dot(_e355, _e356) < 0f) {
        let _e359 = n_2;
        n_2 = -(_e359);
    }
    let _e361 = v_1;
    v_1 = normalize(_e361);
    let _e364 = q_1[0u];
    let _e367 = q_1[1u];
    uv_3 = vec2<f32>((_e364 + 0.5f), (0.5f - _e367));
    let _e370 = p_6;
    let _e371 = tx;
    param_41 = (_e370 + _e371);
    let _e373 = decalSpace_u0028_vf3_u003b((&param_41));
    let _e375 = q_1;
    duvdx = ((_e373.xy - _e375.xy) * vec2<f32>(1f, -1f));
    let _e379 = p_6;
    let _e380 = ty;
    param_42 = (_e379 + _e380);
    let _e382 = decalSpace_u0028_vf3_u003b((&param_42));
    let _e384 = q_1;
    duvdy = ((_e382.xy - _e384.xy) * vec2<f32>(1f, -1f));
    let _e388 = uv_3;
    gUV = _e388;
    let _e389 = p_6;
    gPosition = _e389;
    let _e390 = n_2;
    gNormal = _e390;
    let _e391 = v_1;
    gView = _e391;
    let _e393 = decal.color;
    gVertexColor = _e393;
    let _e396 = graphPush.params[0u];
    gTime = _e396;
    graphSurface_u0028_();
    let _e398 = decal.color;
    let _e400 = gBaseColor;
    albedo = (_e398.xyz * max(_e400, vec3<f32>(0f, 0f, 0f)));
    let _e405 = decal.color[3u];
    let _e406 = gOpacity;
    alpha = (_e405 * clamp(_e406, 0f, 1f));
    let _e409 = gMetallic;
    metallic = clamp(_e409, 0f, 1f);
    let _e413 = decal.model[0];
    let _e415 = n_2;
    let _e416 = n_2;
    let _e419 = decal.model[0];
    gt = (_e413.xyz - (_e415 * dot(_e416, _e419.xyz)));
    let _e426 = decal.model[1];
    let _e428 = n_2;
    let _e429 = n_2;
    let _e432 = decal.model[1];
    gb = (_e426.xyz - (_e428 * dot(_e429, _e432.xyz)));
    let _e437 = gt;
    let _e438 = gt;
    let _e440 = (dot(_e437, _e438) > 0.000000000001f);
    phi_1766_ = _e440;
    if _e440 {
        let _e441 = gb;
        let _e442 = gb;
        phi_1766_ = (dot(_e441, _e442) > 0.000000000001f);
    }
    let _e446 = phi_1766_;
    phi_1773_ = _e446;
    if _e446 {
        let _e447 = gNormalTS;
        let _e448 = gNormalTS;
        phi_1773_ = (dot(_e447, _e448) > 0.000000000001f);
    }
    let _e452 = phi_1773_;
    if _e452 {
        let _e453 = gNormalTS;
        m_1 = normalize(_e453);
        let _e455 = gt;
        let _e458 = m_1[0u];
        let _e460 = gb;
        let _e463 = m_1[1u];
        let _e466 = n_2;
        let _e468 = m_1[2u];
        n_2 = normalize((((normalize(_e455) * _e458) + (normalize(_e460) * _e463)) + (_e466 * _e468)));
        let _e472 = n_2;
        let _e473 = v_1;
        if (dot(_e472, _e473) < 0f) {
            let _e476 = n_2;
            let _e477 = v_1;
            let _e478 = n_2;
            let _e479 = v_1;
            n_2 = normalize((_e476 - (_e477 * (dot(_e478, _e479) - 0.001f))));
        }
    }
    let _e487 = decal.params[2u];
    if (_e487 > 0f) {
        let _e489 = n_2;
        let _e491 = decal.axis;
        let _e497 = decal.params[2u];
        let _e500 = alpha;
        alpha = (_e500 * clamp((dot(_e489, -(_e491.xyz)) / _e497), 0f, 1f));
    }
    let _e502 = alpha;
    if (_e502 <= 0f) {
        discard;
    }
    let _e504 = gRoughness;
    roughness_2 = clamp(_e504, 0.045f, 1f);
    let _e506 = roughness_2;
    let _e507 = roughness_2;
    a_6 = (_e506 * _e507);
    let _e509 = albedo;
    let _e510 = metallic;
    f0_1 = mix(vec3<f32>(0.04f, 0.04f, 0.04f), _e509, vec3(_e510));
    let _e513 = albedo;
    let _e514 = metallic;
    diffuse = (_e513 * (1f - _e514));
    let _e518 = frame.lightDir;
    l_1 = normalize(_e518.xyz);
    let _e521 = l_1;
    let _e522 = v_1;
    h = normalize((_e521 + _e522));
    shadow = 1f;
    let _e527 = frame.lightColor[3u];
    if (_e527 > 0.5f) {
        let _e529 = p_6;
        param_43 = _e529;
        let _e530 = n_2;
        param_44 = _e530;
        let _e531 = directionalShadow_u0028_vf3_u003b_vf3_u003b_vf3_u003b((&param_43), (&param_44), (&param_45));
        let _e532 = param_45;
        cascadeTint = _e532;
        shadow = _e531;
    }
    let _e534 = frame.lightColor;
    let _e538 = frame.lightDir[3u];
    light = (_e534.xyz * _e538);
    let _e540 = n_2;
    let _e541 = v_1;
    NoV_2 = max(dot(_e540, _e541), 0.0001f);
    let _e544 = n_2;
    let _e545 = l_1;
    NoL_1 = clamp(dot(_e544, _e545), 0f, 1f);
    let _e548 = n_2;
    let _e549 = h;
    NoH_1 = clamp(dot(_e548, _e549), 0f, 1f);
    let _e552 = v_1;
    let _e553 = h;
    VoH_1 = clamp(dot(_e552, _e553), 0f, 1f);
    let _e556 = f0_1;
    param_46 = _e556;
    let _e557 = VoH_1;
    param_47 = _e557;
    let _e558 = fresnelSchlick_u0028_vf3_u003b_f1_u003b((&param_46), (&param_47));
    F = _e558;
    let _e559 = NoH_1;
    param_48 = _e559;
    let _e560 = a_6;
    param_49 = _e560;
    let _e561 = distributionGGX_u0028_f1_u003b_f1_u003b((&param_48), (&param_49));
    let _e562 = NoV_2;
    param_50 = _e562;
    let _e563 = NoL_1;
    param_51 = _e563;
    let _e564 = a_6;
    param_52 = _e564;
    let _e565 = visibilitySmithGGXCorrelated_u0028_f1_u003b_f1_u003b_f1_u003b((&param_50), (&param_51), (&param_52));
    let _e567 = F;
    specular = ((_e567 * (_e561 * _e565)) * 3.1415927f);
    let _e570 = F;
    let _e572 = diffuse;
    let _e574 = specular;
    let _e576 = NoL_1;
    let _e578 = light;
    let _e580 = shadow;
    color = ((((((vec3<f32>(1f, 1f, 1f) - _e570) * _e572) + _e574) * _e576) * _e578) * _e580);
    let _e584 = frame.environment[0u];
    if (_e584 > 0.5f) {
        let _e586 = NoV_2;
        param_53 = _e586;
        let _e587 = roughness_2;
        param_54 = _e587;
        let _e588 = environmentBRDF_u0028_f1_u003b_f1_u003b((&param_53), (&param_54));
        dfg = _e588;
        let _e589 = n_2;
        param_55 = _e589;
        let _e590 = environmentIrradiance_u0028_vf3_u003b((&param_55));
        irradiance = _e590;
        let _e591 = v_1;
        let _e593 = n_2;
        param_56 = reflect(-(_e591), _e593);
        let _e595 = roughness_2;
        param_57 = _e595;
        let _e596 = environmentRadiance_u0028_vf3_u003b_f1_u003b((&param_56), (&param_57));
        reflected = _e596;
    } else {
        let _e597 = NoV_2;
        param_58 = _e597;
        let _e598 = roughness_2;
        param_59 = _e598;
        let _e599 = environmentBRDF_u0028_f1_u003b_f1_u003b((&param_58), (&param_59));
        dfg = _e599;
        let _e600 = n_2;
        param_60 = _e600;
        let _e601 = hemisphere_u0028_vf3_u003b((&param_60));
        irradiance = _e601;
        let _e602 = v_1;
        let _e604 = n_2;
        param_61 = reflect(-(_e602), _e604);
        let _e606 = hemisphere_u0028_vf3_u003b((&param_61));
        let _e607 = irradiance;
        let _e608 = roughness_2;
        reflected = mix(_e606, _e607, vec3(_e608));
    }
    let _e611 = f0_1;
    let _e613 = dfg[0u];
    let _e616 = dfg[1u];
    specularAmbient = ((_e611 * _e613) + vec3(_e616));
    let _e619 = gOcclusion;
    ao = clamp(_e619, 0f, 1f);
    let _e621 = specularAmbient;
    let _e623 = diffuse;
    let _e625 = irradiance;
    let _e627 = specularAmbient;
    let _e628 = reflected;
    let _e631 = ao;
    let _e633 = color;
    color = (_e633 + (((((vec3<f32>(1f, 1f, 1f) - _e621) * _e623) * _e625) + (_e627 * _e628)) * _e631));
    let _e637 = frame.clusterGrid[3u];
    if (_e637 > 0.5f) {
        let _e640 = frame.viewDepth;
        let _e642 = p_6;
        let _e646 = frame.viewDepth[3u];
        depth_1 = (dot(_e640.xyz, _e642) + _e646);
        let _e648 = gl_FragCoord_1;
        let _e651 = frame.clusterScale;
        let _e656 = frame.clusterGrid;
        tile = clamp(floor((_e648.xy * _e651.xy)), vec2<f32>(0f, 0f), (_e656.xy - vec2(1f)));
        let _e661 = depth_1;
        let _e666 = frame.clusterScale[2u];
        let _e670 = frame.clusterScale[3u];
        let _e675 = frame.clusterGrid[2u];
        slice = clamp(floor(((log2(max(_e661, 0.000001f)) * _e666) + _e670)), 0f, (_e675 - 1f));
        let _e678 = slice;
        let _e681 = frame.clusterGrid[1u];
        let _e684 = tile[1u];
        let _e688 = frame.clusterGrid[0u];
        let _e691 = tile[0u];
        cluster = u32(((((_e678 * _e681) + _e684) * _e688) + _e691));
        let _e694 = cluster;
        let _e697 = cluster;
        let _e702 = lightCells.data[(_e694 >> bitcast<u32>(2i))][(_e697 & 3u)];
        cell = _e702;
        let _e703 = cell;
        first = (_e703 & 65535u);
        let _e705 = cell;
        count_1 = (_e705 >> bitcast<u32>(16i));
        let _e708 = first;
        i_3 = _e708;
        loop {
            let _e709 = i_3;
            let _e710 = first;
            let _e711 = count_1;
            if (_e709 < (_e710 + _e711)) {
                let _e714 = i_3;
                word = (_e714 / 3u);
                let _e716 = word;
                let _e719 = word;
                let _e724 = lightIndices.data[(_e716 >> bitcast<u32>(2i))][(_e719 & 3u)];
                let _e725 = i_3;
                let _e726 = word;
                li = ((_e724 >> bitcast<u32>(((_e725 - (_e726 * 3u)) * 10u))) & 1023u);
                let _e733 = li;
                let _e736 = lightPositions.data[_e733];
                position_1 = _e736;
                let _e737 = position_1;
                let _e739 = p_6;
                toLight = (_e737.xyz - _e739);
                let _e741 = toLight;
                let _e742 = toLight;
                d2_ = dot(_e741, _e742);
                let _e744 = d2_;
                let _e746 = position_1[3u];
                x = (_e744 * _e746);
                let _e748 = x;
                let _e749 = x;
                window = clamp((1f - (_e748 * _e749)), 0f, 1f);
                let _e753 = toLight;
                let _e754 = d2_;
                pl = (_e753 * inverseSqrt(max(_e754, 0.00000001f)));
                let _e758 = li;
                let _e761 = lightColors.data[_e758];
                lc = _e761;
                let _e762 = li;
                let _e765 = lightDirections.data[_e762];
                direction = _e765;
                let _e766 = pl;
                let _e768 = direction;
                let _e772 = lc[3u];
                let _e775 = direction[3u];
                cone = clamp(((dot(-(_e766), _e768.xyz) * _e772) + _e775), 0f, 1f);
                let _e778 = lc;
                let _e780 = window;
                let _e781 = window;
                let _e783 = cone;
                let _e785 = cone;
                let _e787 = d2_;
                radiance = (_e778.xyz * ((((_e780 * _e781) * _e783) * _e785) / max(_e787, 0.0001f)));
                let _e791 = li;
                param_62 = _e791;
                let _e792 = p_6;
                param_63 = _e792;
                let _e793 = n_2;
                param_64 = _e793;
                let _e794 = pl;
                param_65 = _e794;
                let _e795 = localShadow_u0028_u1_u003b_vf3_u003b_vf3_u003b_vf3_u003b((&param_62), (&param_63), (&param_64), (&param_65));
                let _e796 = radiance;
                radiance = (_e796 * _e795);
                let _e798 = pl;
                let _e799 = v_1;
                ph = normalize((_e798 + _e799));
                let _e802 = n_2;
                let _e803 = pl;
                pNoL = clamp(dot(_e802, _e803), 0f, 1f);
                let _e806 = n_2;
                let _e807 = ph;
                pNoH = clamp(dot(_e806, _e807), 0f, 1f);
                let _e810 = v_1;
                let _e811 = ph;
                let _e814 = f0_1;
                param_66 = _e814;
                param_67 = clamp(dot(_e810, _e811), 0f, 1f);
                let _e815 = fresnelSchlick_u0028_vf3_u003b_f1_u003b((&param_66), (&param_67));
                pF = _e815;
                let _e816 = pNoH;
                param_68 = _e816;
                let _e817 = a_6;
                param_69 = _e817;
                let _e818 = distributionGGX_u0028_f1_u003b_f1_u003b((&param_68), (&param_69));
                let _e819 = NoV_2;
                param_70 = _e819;
                let _e820 = pNoL;
                param_71 = _e820;
                let _e821 = a_6;
                param_72 = _e821;
                let _e822 = visibilitySmithGGXCorrelated_u0028_f1_u003b_f1_u003b_f1_u003b((&param_70), (&param_71), (&param_72));
                let _e824 = pF;
                pSpecular = ((_e824 * (_e818 * _e822)) * 3.1415927f);
                let _e827 = pF;
                let _e829 = diffuse;
                let _e831 = pSpecular;
                let _e833 = pNoL;
                let _e835 = radiance;
                let _e837 = color;
                color = (_e837 + (((((vec3<f32>(1f, 1f, 1f) - _e827) * _e829) + _e831) * _e833) * _e835));
                continue;
            } else {
                break;
            }
            continuing {
                let _e839 = i_3;
                i_3 = (_e839 + bitcast<u32>(1i));
            }
        }
    }
    let _e842 = albedo;
    let _e845 = decal.params[0u];
    let _e847 = gEmissive;
    let _e850 = color;
    color = (_e850 + ((_e842 * _e845) + max(_e847, vec3<f32>(0f, 0f, 0f))));
    let _e853 = frame.cameraPos;
    let _e855 = p_6;
    dist = length((_e853.xyz - _e855));
    let _e858 = dist;
    let _e862 = frame.fogColor[3u];
    fog = (1f - exp((-(_e858) * _e862)));
    let _e866 = color;
    let _e868 = frame.fogColor;
    let _e870 = fog;
    let _e872 = mix(_e866, _e868.xyz, vec3(_e870));
    let _e873 = alpha;
    outColor = vec4<f32>(_e872.x, _e872.y, _e872.z, _e873);
    return;
}

@fragment 
fn main(@builtin(position) gl_FragCoord: vec4<f32>) -> @location(0) vec4<f32> {
    gl_FragCoord_1 = gl_FragCoord;
    main_1();
    let _e3 = outColor;
    return _e3;
}
