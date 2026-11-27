// Generated from mesh_fur.vert by Scripts/compile-shaders.sh — do not edit.
// Edit the GLSL and rerun the script (needs glslc, spirv-cross, spirv-opt and naga-cli).
// spirv-fnv1a64: f59096b5c8e27aa5
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
    var phi_1313_: vec3<f32>;
    var phi_1315_: vec3<f32>;
    var phi_1314_: vec3<f32>;
    var local: bool;
    var phi_1317_: f32;
    var local_1: bool;
    var phi_1318_: f32;
    var local_2: bool;
    var local_3: bool;
    var phi_510_: bool;
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
    var local_16: f32;
    var phi_1319_: vec3<f32>;
    var phi_1320_: vec3<f32>;
    var local_17: vec3<f32>;
    var local_18: vec3<f32>;
    var local_19: mat3x3<f32>;
    var local_20: vec3<f32>;

    let _e68 = global_6;
    let _e69 = global_7;
    let _e70 = global_8;
    let _e71 = global_9;
    let _e76 = global_1.member_1[6i][0u];
    switch bitcast<i32>(0u) {
        default: {
            let _e78 = global_2;
            let _e82 = vec4<f32>(_e78.x, _e78.y, _e78.z, 1f);
            let _e84 = (mat4x4<f32>(_e68, _e69, _e70, _e71) * _e82).xyz;
            let _e85 = _e68.xyz;
            let _e86 = _e69.xyz;
            let _e87 = _e70.xyz;
            let _e90 = cross(_e85, _e86);
            let _e91 = mat3x3<f32>(cross(_e86, _e87), cross(_e87, _e85), _e90);
            let _e95 = global_3;
            let _e98 = normalize(((_e91 * _e95) * select(1f, -1f, (dot(_e90, _e87) < 0f))));
            let _e102 = global_1.member_1[2i][0u];
            let _e106 = global_1.member_1[3i][3u];
            let _e107 = (_e106 > 0.5f);
            let _e111 = global_1.member_1[5i];
            let _e112 = _e111.xy;
            let _e113 = _e71.xz;
            let _e118 = ((dot(_e113, _e112) * 0.35f) + (dot(_e113, vec2<f32>(0.83f, -0.57f)) * 1.7f));
            let _e132 = global_1.member_1[5i][3u];
            let _e138 = (dot(_e71.xyz, vec3<f32>(3.1f, 2.3f, 2.7f)) * 3f);
            let _e151 = vec3<f32>(_e111.x, 0f, _e111.y);
            let _e155 = global_1.member_1[5i][2u];
            let _e161 = global[2u];
            let _e163 = global[3u];
            let _e168 = global_1.member_1[0i][0u];
            let _e171 = (vec3<f32>(_e161, 0f, _e163) / vec3(max(_e168, 0.001f)));
            let _e173 = (((_e151 * (((_e155 * (1f + (_e132 * (((0.5f + ((0.5f * sin(((_e76 * 0.61f) + _e118))) * sin(((_e76 * 0.23f) + (_e118 * 0.7f))))) * 1.6f) - 0.6f)))) * (0.7f + ((0.3f * sin(((_e76 * 4.7f) + _e138))) * sin(((_e76 * 2.9f) + (_e138 * 0.37f)))))) * 0.35f)) + _e171) * _e102);
            local = _e107;
            local_1 = _e107;
            local_2 = _e107;
            local_3 = _e107;
            local_4 = _e78;
            local_5 = _e95;
            local_6 = _e82;
            local_7 = _e95;
            local_8 = _e112;
            local_9 = _e132;
            local_10 = _e155;
            local_11 = _e151;
            local_12 = _e171;
            local_13 = _e102;
            local_14 = _e107;
            local_15 = _e168;
            local_16 = _e168;
            local_17 = _e90;
            local_18 = _e87;
            local_19 = _e91;
            local_20 = _e95;
            if _e107 {
                let _e175 = global_4[1u];
                let _e189 = global_5;
                phi_1315_ = normalize(((mat3x3<f32>(vec3<f32>(_e68.x, _e68.y, _e68.z), vec3<f32>(_e69.x, _e69.y, _e69.z), vec3<f32>(_e70.x, _e70.y, _e70.z)) * _e189.xyz) + (_e173 * (2f * _e175))));
                phi_1314_ = (_e84 + (_e173 * ((_e168 * _e175) * _e175)));
                break;
            }
            let _e201 = global[1u];
            let _e203 = global_5[3u];
            let _e206 = (_e168 * max((_e203 - 1f), 0f));
            if (_e201 <= 0f) {
                phi_1315_ = _e98;
                phi_1314_ = (_e84 + (_e98 * ((_e206 * 0.04f) + 0.0004f)));
                break;
            }
            let _e225 = global_5;
            let _e227 = (mat3x3<f32>(vec3<f32>(_e68.x, _e68.y, _e68.z), vec3<f32>(_e69.x, _e69.y, _e69.z), vec3<f32>(_e70.x, _e70.y, _e70.z)) * _e225.xyz);
            let _e229 = min(length(_e227), 1f);
            let _e233 = global_1.member_1[1i][3u];
            let _e236 = (vec3<f32>(0f, -(_e233), 0f) + _e173);
            let _e250 = (_e206 * _e201);
            let _e251 = (normalize((((_e98 * (1f - _e229)) + _e227) + (_e236 * (0.5f * _e201)))) * _e250);
            let _e252 = dot(_e251, _e98);
            let _e253 = (_e250 * 0.12f);
            phi_1313_ = _e251;
            if (_e252 < _e253) {
                phi_1313_ = (_e251 + (_e98 * (_e253 - _e252)));
            }
            let _e259 = phi_1313_;
            phi_1315_ = normalize((((_e98 * (1f - _e229)) + _e227) + (_e236 * _e201)));
            phi_1314_ = (_e84 + _e259);
            break;
        }
    }
    let _e262 = phi_1315_;
    let _e264 = phi_1314_;
    let _e266 = global_10.member;
    let _e270 = vec4<f32>(_e264.x, _e264.y, _e264.z, 1f);
    global_11.member = (_e266 * _e270);
    let _e275 = global_11.member[1u];
    global_11.member[1u] = -(_e275);
    let _e278 = local;
    if _e278 {
        let _e280 = global_4[1u];
        phi_1317_ = _e280;
    } else {
        let _e282 = global[1u];
        phi_1317_ = _e282;
    }
    let _e284 = phi_1317_;
    let _e286 = local_1;
    if _e286 {
        let _e288 = global_5[3u];
        phi_1318_ = fract(_e288);
    } else {
        phi_1318_ = 0f;
    }
    let _e291 = phi_1318_;
    let _e293 = local_2;
    let _e296 = local_3;
    let _e297 = !(_e296);
    phi_510_ = _e297;
    if _e297 {
        let _e299 = global[1u];
        phi_510_ = (_e299 <= 0f);
    }
    let _e302 = phi_510_;
    global_12 = vec4<f32>(_e284, _e291, select(0f, 1f, _e293), select(0f, 1f, _e302));
    let _e305 = global_4;
    global_13 = _e305;
    let _e307 = local_4;
    global_14 = _e307;
    let _e309 = local_5;
    global_15 = _e309;
    let _e310 = global_16;
    let _e311 = global_17;
    let _e312 = global_18;
    let _e313 = global_19;
    let _e318 = global_1.member_1[6i][1u];
    switch bitcast<i32>(0u) {
        default: {
            let _e321 = local_6;
            let _e323 = (mat4x4<f32>(_e310, _e311, _e312, _e313) * _e321).xyz;
            let _e324 = _e310.xyz;
            let _e325 = _e311.xyz;
            let _e326 = _e312.xyz;
            let _e329 = cross(_e324, _e325);
            let _e335 = local_7;
            let _e338 = normalize(((mat3x3<f32>(cross(_e325, _e326), cross(_e326, _e324), _e329) * _e335) * select(1f, -1f, (dot(_e329, _e326) < 0f))));
            let _e340 = _e313.xz;
            let _e342 = local_8;
            let _e347 = ((dot(_e340, _e342) * 0.35f) + (dot(_e340, vec2<f32>(0.83f, -0.57f)) * 1.7f));
            let _e361 = local_9;
            let _e365 = (dot(_e313.xyz, vec3<f32>(3.1f, 2.3f, 2.7f)) * 3f);
            let _e377 = local_10;
            let _e382 = local_11;
            let _e385 = local_12;
            let _e388 = local_13;
            let _e389 = (((_e382 * (((_e377 * (1f + (_e361 * (((0.5f + ((0.5f * sin(((_e318 * 0.61f) + _e347))) * sin(((_e318 * 0.23f) + (_e347 * 0.7f))))) * 1.6f) - 0.6f)))) * (0.7f + ((0.3f * sin(((_e318 * 4.7f) + _e365))) * sin(((_e318 * 2.9f) + (_e365 * 0.37f)))))) * 0.35f)) + _e385) * _e388);
            let _e391 = local_14;
            if _e391 {
                let _e393 = global_4[1u];
                let _e395 = local_15;
                phi_1320_ = (_e323 + (_e389 * ((_e395 * _e393) * _e393)));
                break;
            }
            let _e401 = global[1u];
            let _e403 = global_5[3u];
            let _e407 = local_16;
            let _e408 = (_e407 * max((_e403 - 1f), 0f));
            if (_e401 <= 0f) {
                phi_1320_ = (_e323 + (_e338 * ((_e408 * 0.04f) + 0.0004f)));
                break;
            }
            let _e427 = global_5;
            let _e429 = (mat3x3<f32>(vec3<f32>(_e310.x, _e310.y, _e310.z), vec3<f32>(_e311.x, _e311.y, _e311.z), vec3<f32>(_e312.x, _e312.y, _e312.z)) * _e427.xyz);
            let _e435 = global_1.member_1[1i][3u];
            let _e446 = (_e408 * _e401);
            let _e447 = (normalize((((_e338 * (1f - min(length(_e429), 1f))) + _e429) + ((vec3<f32>(0f, -(_e435), 0f) + _e389) * (0.5f * _e401)))) * _e446);
            let _e448 = dot(_e447, _e338);
            let _e449 = (_e446 * 0.12f);
            phi_1319_ = _e447;
            if (_e448 < _e449) {
                phi_1319_ = (_e447 + (_e338 * (_e449 - _e448)));
            }
            let _e455 = phi_1319_;
            phi_1320_ = (_e323 + _e455);
            break;
        }
    }
    let _e458 = phi_1320_;
    let _e460 = local_17;
    let _e462 = local_18;
    global_20 = _e264;
    let _e467 = local_19;
    let _e469 = local_20;
    global_21 = ((_e467 * _e469) * select(1f, -1f, (dot(_e460, _e462) < 0f)));
    let _e472 = global_23;
    global_22 = _e472;
    let _e474 = global[0u];
    global_24 = vec4<f32>(_e474, 0f, 0f, 0f);
    let _e477 = global_10.member_2;
    let _e480 = global_10.member_3;
    global_25 = (_e477 * _e270);
    global_26 = (_e480 * vec4<f32>(_e458.x, _e458.y, _e458.z, 1f));
    global_27 = _e262;
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
