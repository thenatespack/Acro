// Generated from mesh_fur.vert by Scripts/compile-shaders.sh — do not edit.
// Edit the GLSL and rerun the script (needs glslc, spirv-cross, spirv-opt and naga-cli).
// spirv-fnv1a64: bf1c24389d9605dd
// glsl-fnv1a64: c770a578588d3aa5

diagnostic(off, derivative_uniformity);

struct type_9 {
    member: array<vec4<f32>, 8>,
    member_1: array<vec4<f32>, 8>,
}

struct type_18 {
    member: mat4x4<f32>,
    member_1: mat4x4<f32>,
    member_2: mat4x4<f32>,
    member_3: mat4x4<f32>,
}

struct type_22 {
    @builtin(position) member: vec4<f32>,
    member_1: f32,
    member_2: array<f32, 1>,
    member_3: array<f32, 1>,
}

struct VertexOutput {
    @builtin(position) member: vec4<f32>,
    @location(8) member_1: vec4<f32>,
    @location(2) member_2: vec2<f32>,
    @location(4) member_3: vec3<f32>,
    @location(10) member_4: vec3<f32>,
    @location(0) member_5: vec3<f32>,
    @location(1) member_6: vec3<f32>,
    @location(3) member_7: vec4<f32>,
    @location(5) member_8: vec4<f32>,
    @location(6) member_9: vec4<f32>,
    @location(7) member_10: vec4<f32>,
    @location(9) member_11: vec3<f32>,
}

var<private> global: vec4<f32>;
@group(2) @binding(2) 
var<uniform> global_1: type_9;
var<private> global_2: vec3<f32>;
var<private> global_3: vec3<f32>;
var<private> global_4: vec2<f32>;
var<private> global_5: vec4<f32>;
var<private> global_6: vec4<f32>;
var<private> global_7: vec4<f32>;
var<private> global_8: vec4<f32>;
var<private> global_9: vec4<f32>;
@group(0) @binding(0) 
var<uniform> global_10: type_18;
var<private> global_11: type_22 = type_22(vec4<f32>(0f, 0f, 0f, 1f), 1f, array<f32, 1>(), array<f32, 1>());
var<private> global_12: vec4<f32>;
var<private> global_13: vec2<f32>;
var<private> global_14: vec3<f32>;
var<private> global_15: vec3<f32>;
var<private> global_16: vec4<f32>;
var<private> global_17: vec4<f32>;
var<private> global_18: vec4<f32>;
var<private> global_19: vec4<f32>;
var<private> global_20: vec3<f32>;
var<private> global_21: vec3<f32>;
var<private> global_22: vec4<f32>;
var<private> global_23: vec4<f32>;
var<private> global_24: vec4<f32>;
var<private> global_25: vec4<f32>;
var<private> global_26: vec4<f32>;
var<private> global_27: vec3<f32>;

fn function_() {
    var phi_1376_: f32;
    var phi_1377_: vec3<f32>;
    var phi_1379_: vec3<f32>;
    var phi_1378_: vec3<f32>;
    var local: bool;
    var phi_505_: bool;
    var local_1: bool;
    var phi_1381_: f32;
    var local_2: bool;
    var phi_1382_: f32;
    var local_3: bool;
    var phi_1383_: f32;
    var phi_543_: bool;
    var local_4: vec3<f32>;
    var local_5: vec3<f32>;
    var local_6: vec4<f32>;
    var local_7: vec3<f32>;
    var local_8: vec2<f32>;
    var local_9: f32;
    var local_10: f32;
    var local_11: vec3<f32>;
    var local_12: vec3<f32>;
    var local_13: f32;
    var local_14: bool;
    var local_15: f32;
    var phi_1384_: f32;
    var local_16: f32;
    var phi_1385_: vec3<f32>;
    var phi_1386_: vec3<f32>;
    var local_17: vec3<f32>;
    var local_18: vec3<f32>;
    var local_19: mat3x3<f32>;
    var local_20: vec3<f32>;

    let _e69 = global_6;
    let _e70 = global_7;
    let _e71 = global_8;
    let _e72 = global_9;
    let _e77 = global_1.member_1[6i][0u];
    switch bitcast<i32>(0u) {
        default: {
            let _e79 = global_2;
            let _e83 = vec4<f32>(_e79.x, _e79.y, _e79.z, 1f);
            let _e85 = (mat4x4<f32>(_e69, _e70, _e71, _e72) * _e83).xyz;
            let _e86 = _e69.xyz;
            let _e87 = _e70.xyz;
            let _e88 = _e71.xyz;
            let _e91 = cross(_e86, _e87);
            let _e92 = mat3x3<f32>(cross(_e87, _e88), cross(_e88, _e86), _e91);
            let _e96 = global_3;
            let _e99 = normalize(((_e92 * _e96) * select(1f, -1f, (dot(_e91, _e88) < 0f))));
            let _e103 = global_1.member_1[2i][0u];
            let _e107 = global_1.member_1[3i][3u];
            let _e108 = (_e107 > 0.5f);
            let _e112 = global_1.member_1[5i];
            let _e113 = _e112.xy;
            let _e114 = _e72.xz;
            let _e119 = ((dot(_e114, _e113) * 0.35f) + (dot(_e114, vec2<f32>(0.83f, -0.57f)) * 1.7f));
            let _e133 = global_1.member_1[5i][3u];
            let _e139 = (dot(_e72.xyz, vec3<f32>(3.1f, 2.3f, 2.7f)) * 3f);
            let _e152 = vec3<f32>(_e112.x, 0f, _e112.y);
            let _e156 = global_1.member_1[5i][2u];
            let _e162 = global[2u];
            let _e164 = global[3u];
            let _e169 = global_1.member_1[0i][0u];
            let _e172 = (vec3<f32>(_e162, 0f, _e164) / vec3(max(_e169, 0.001f)));
            let _e174 = (((_e152 * (((_e156 * (1f + (_e133 * (((0.5f + ((0.5f * sin(((_e77 * 0.61f) + _e119))) * sin(((_e77 * 0.23f) + (_e119 * 0.7f))))) * 1.6f) - 0.6f)))) * (0.7f + ((0.3f * sin(((_e77 * 4.7f) + _e139))) * sin(((_e77 * 2.9f) + (_e139 * 0.37f)))))) * 0.35f)) + _e172) * _e103);
            local = _e108;
            local_1 = _e108;
            local_2 = _e108;
            local_3 = _e108;
            local_4 = _e79;
            local_5 = _e96;
            local_6 = _e83;
            local_7 = _e96;
            local_8 = _e113;
            local_9 = _e133;
            local_10 = _e156;
            local_11 = _e152;
            local_12 = _e172;
            local_13 = _e103;
            local_14 = _e108;
            local_15 = _e169;
            local_16 = _e169;
            local_17 = _e91;
            local_18 = _e88;
            local_19 = _e92;
            local_20 = _e96;
            if _e108 {
                let _e176 = global_4[1u];
                let _e190 = global_5;
                phi_1379_ = normalize(((mat3x3<f32>(vec3<f32>(_e69.x, _e69.y, _e69.z), vec3<f32>(_e70.x, _e70.y, _e70.z), vec3<f32>(_e71.x, _e71.y, _e71.z)) * _e190.xyz) + (_e174 * (2f * _e176))));
                phi_1378_ = (_e85 + (_e174 * ((_e169 * _e176) * _e176)));
                break;
            }
            let _e202 = global[1u];
            let _e203 = (_e202 > 1.5f);
            if _e203 {
                let _e205 = global_4[1u];
                phi_1376_ = _e205;
            } else {
                phi_1376_ = _e202;
            }
            let _e207 = phi_1376_;
            let _e209 = global_5[3u];
            let _e212 = (_e169 * max((_e209 - 1f), 0f));
            if ((_e207 <= 0f) && !(_e203)) {
                phi_1379_ = _e99;
                phi_1378_ = (_e85 + (_e99 * ((_e212 * 0.04f) + 0.0004f)));
                break;
            }
            let _e233 = global_5;
            let _e235 = (mat3x3<f32>(vec3<f32>(_e69.x, _e69.y, _e69.z), vec3<f32>(_e70.x, _e70.y, _e70.z), vec3<f32>(_e71.x, _e71.y, _e71.z)) * _e233.xyz);
            let _e237 = min(length(_e235), 1f);
            let _e241 = global_1.member_1[1i][3u];
            let _e244 = (vec3<f32>(0f, -(_e241), 0f) + _e174);
            let _e258 = (_e212 * _e207);
            let _e259 = (normalize((((_e99 * (1f - _e237)) + _e235) + (_e244 * (0.5f * _e207)))) * _e258);
            let _e260 = dot(_e259, _e99);
            let _e261 = (_e258 * 0.12f);
            phi_1377_ = _e259;
            if (_e260 < _e261) {
                phi_1377_ = (_e259 + (_e99 * (_e261 - _e260)));
            }
            let _e267 = phi_1377_;
            phi_1379_ = normalize((((_e99 * (1f - _e237)) + _e235) + (_e244 * _e207)));
            phi_1378_ = (_e85 + _e267);
            break;
        }
    }
    let _e270 = phi_1379_;
    let _e272 = phi_1378_;
    let _e274 = global_10.member;
    let _e278 = vec4<f32>(_e272.x, _e272.y, _e272.z, 1f);
    global_11.member = (_e274 * _e278);
    let _e283 = global_11.member[1u];
    global_11.member[1u] = -(_e283);
    let _e286 = local;
    let _e287 = !(_e286);
    phi_505_ = _e287;
    if _e287 {
        let _e289 = global[1u];
        phi_505_ = (_e289 > 1.5f);
    }
    let _e292 = phi_505_;
    let _e294 = local_1;
    if (_e294 || _e292) {
        let _e297 = global_4[1u];
        phi_1381_ = _e297;
    } else {
        let _e299 = global[1u];
        phi_1381_ = _e299;
    }
    let _e301 = phi_1381_;
    let _e303 = local_2;
    if _e303 {
        let _e305 = global_5[3u];
        phi_1382_ = fract(_e305);
    } else {
        phi_1382_ = 0f;
    }
    let _e308 = phi_1382_;
    let _e310 = local_3;
    if _e310 {
        phi_1383_ = 1f;
    } else {
        phi_1383_ = select(0f, 2f, _e292);
    }
    let _e313 = phi_1383_;
    phi_543_ = _e287;
    if _e287 {
        let _e315 = global[1u];
        phi_543_ = (_e315 <= 0f);
    }
    let _e318 = phi_543_;
    global_12 = vec4<f32>(_e301, _e308, _e313, select(0f, 1f, _e318));
    let _e321 = global_4;
    global_13 = _e321;
    let _e323 = local_4;
    global_14 = _e323;
    let _e325 = local_5;
    global_15 = _e325;
    let _e326 = global_16;
    let _e327 = global_17;
    let _e328 = global_18;
    let _e329 = global_19;
    let _e334 = global_1.member_1[6i][1u];
    switch bitcast<i32>(0u) {
        default: {
            let _e337 = local_6;
            let _e339 = (mat4x4<f32>(_e326, _e327, _e328, _e329) * _e337).xyz;
            let _e340 = _e326.xyz;
            let _e341 = _e327.xyz;
            let _e342 = _e328.xyz;
            let _e345 = cross(_e340, _e341);
            let _e351 = local_7;
            let _e354 = normalize(((mat3x3<f32>(cross(_e341, _e342), cross(_e342, _e340), _e345) * _e351) * select(1f, -1f, (dot(_e345, _e342) < 0f))));
            let _e356 = _e329.xz;
            let _e358 = local_8;
            let _e363 = ((dot(_e356, _e358) * 0.35f) + (dot(_e356, vec2<f32>(0.83f, -0.57f)) * 1.7f));
            let _e377 = local_9;
            let _e381 = (dot(_e329.xyz, vec3<f32>(3.1f, 2.3f, 2.7f)) * 3f);
            let _e393 = local_10;
            let _e398 = local_11;
            let _e401 = local_12;
            let _e404 = local_13;
            let _e405 = (((_e398 * (((_e393 * (1f + (_e377 * (((0.5f + ((0.5f * sin(((_e334 * 0.61f) + _e363))) * sin(((_e334 * 0.23f) + (_e363 * 0.7f))))) * 1.6f) - 0.6f)))) * (0.7f + ((0.3f * sin(((_e334 * 4.7f) + _e381))) * sin(((_e334 * 2.9f) + (_e381 * 0.37f)))))) * 0.35f)) + _e401) * _e404);
            let _e407 = local_14;
            if _e407 {
                let _e409 = global_4[1u];
                let _e411 = local_15;
                phi_1386_ = (_e339 + (_e405 * ((_e411 * _e409) * _e409)));
                break;
            }
            let _e417 = global[1u];
            let _e418 = (_e417 > 1.5f);
            if _e418 {
                let _e420 = global_4[1u];
                phi_1384_ = _e420;
            } else {
                phi_1384_ = _e417;
            }
            let _e422 = phi_1384_;
            let _e424 = global_5[3u];
            let _e428 = local_16;
            let _e429 = (_e428 * max((_e424 - 1f), 0f));
            if ((_e422 <= 0f) && !(_e418)) {
                phi_1386_ = (_e339 + (_e354 * ((_e429 * 0.04f) + 0.0004f)));
                break;
            }
            let _e450 = global_5;
            let _e452 = (mat3x3<f32>(vec3<f32>(_e326.x, _e326.y, _e326.z), vec3<f32>(_e327.x, _e327.y, _e327.z), vec3<f32>(_e328.x, _e328.y, _e328.z)) * _e450.xyz);
            let _e458 = global_1.member_1[1i][3u];
            let _e469 = (_e429 * _e422);
            let _e470 = (normalize((((_e354 * (1f - min(length(_e452), 1f))) + _e452) + ((vec3<f32>(0f, -(_e458), 0f) + _e405) * (0.5f * _e422)))) * _e469);
            let _e471 = dot(_e470, _e354);
            let _e472 = (_e469 * 0.12f);
            phi_1385_ = _e470;
            if (_e471 < _e472) {
                phi_1385_ = (_e470 + (_e354 * (_e472 - _e471)));
            }
            let _e478 = phi_1385_;
            phi_1386_ = (_e339 + _e478);
            break;
        }
    }
    let _e481 = phi_1386_;
    let _e483 = local_17;
    let _e485 = local_18;
    global_20 = _e272;
    let _e490 = local_19;
    let _e492 = local_20;
    global_21 = ((_e490 * _e492) * select(1f, -1f, (dot(_e483, _e485) < 0f)));
    let _e495 = global_23;
    global_22 = _e495;
    let _e497 = global[0u];
    global_24 = vec4<f32>(_e497, 0f, 0f, 0f);
    let _e500 = global_10.member_2;
    let _e503 = global_10.member_3;
    global_25 = (_e500 * _e278);
    global_26 = (_e503 * vec4<f32>(_e481.x, _e481.y, _e481.z, 1f));
    global_27 = _e270;
    return;
}

@vertex 
fn main(@location(12) param: vec4<f32>, @location(0) param_1: vec3<f32>, @location(1) param_2: vec3<f32>, @location(2) param_3: vec2<f32>, @location(13) param_4: vec4<f32>, @location(3) param_5: vec4<f32>, @location(4) param_6: vec4<f32>, @location(5) param_7: vec4<f32>, @location(6) param_8: vec4<f32>, @location(7) param_9: vec4<f32>, @location(8) param_10: vec4<f32>, @location(9) param_11: vec4<f32>, @location(10) param_12: vec4<f32>, @location(11) param_13: vec4<f32>) -> VertexOutput {
    global = param;
    global_2 = param_1;
    global_3 = param_2;
    global_4 = param_3;
    global_5 = param_4;
    global_6 = param_5;
    global_7 = param_6;
    global_8 = param_7;
    global_9 = param_8;
    global_16 = param_9;
    global_17 = param_10;
    global_18 = param_11;
    global_19 = param_12;
    global_23 = param_13;
    function_();
    let _e42 = global_11.member.y;
    global_11.member.y = -(_e42);
    let _e44 = global_11.member;
    let _e45 = global_12;
    let _e46 = global_13;
    let _e47 = global_14;
    let _e48 = global_15;
    let _e49 = global_20;
    let _e50 = global_21;
    let _e51 = global_22;
    let _e52 = global_24;
    let _e53 = global_25;
    let _e54 = global_26;
    let _e55 = global_27;
    return VertexOutput(_e44, _e45, _e46, _e47, _e48, _e49, _e50, _e51, _e52, _e53, _e54, _e55);
}
