// Generated from mesh_paint_wind.vert by Scripts/compile-shaders.sh — do not edit.
// Edit the GLSL and rerun the script (needs glslc, spirv-cross, spirv-opt and naga-cli).
// spirv-fnv1a64: 023ebea853a1ac2b
// glsl-fnv1a64: 215608e612af82e4

diagnostic(off, derivative_uniformity);

struct type_7 {
    member: array<vec4<f32>, 8>,
    member_1: vec4<f32>,
    member_2: vec4<f32>,
    member_3: vec4<f32>,
    member_4: vec4<f32>,
}

struct type_17 {
    @builtin(position) member: vec4<f32>,
    member_1: f32,
    member_2: array<f32, 1>,
    member_3: array<f32, 1>,
}

struct type_19 {
    member: mat4x4<f32>,
    member_1: mat4x4<f32>,
    member_2: mat4x4<f32>,
    member_3: mat4x4<f32>,
    member_4: vec4<f32>,
    member_5: vec4<f32>,
    member_6: vec4<f32>,
    member_7: vec4<f32>,
    member_8: vec4<f32>,
    member_9: vec4<f32>,
    member_10: vec4<f32>,
}

struct VertexOutput {
    @builtin(position) member: vec4<f32>,
    @location(0) member_1: vec3<f32>,
    @location(1) member_2: vec3<f32>,
    @location(2) member_3: vec2<f32>,
    @location(3) member_4: vec4<f32>,
    @location(5) member_5: vec4<f32>,
    @location(6) member_6: vec4<f32>,
    @location(7) member_7: vec4<f32>,
    @location(8) member_8: vec4<f32>,
    @location(4) member_9: vec3<f32>,
    @location(9) member_10: vec4<f32>,
    @location(10) member_11: vec4<f32>,
}

@group(2) @binding(2) 
var<uniform> global: type_7;
var<private> global_1: vec4<f32>;
var<private> global_2: vec4<f32>;
var<private> global_3: vec4<f32>;
var<private> global_4: vec4<f32>;
var<private> global_5: vec4<f32>;
var<private> global_6: vec4<f32>;
var<private> global_7: vec4<f32>;
var<private> global_8: vec4<f32>;
var<private> global_9: vec3<f32>;
var<private> global_10: type_17 = type_17(vec4<f32>(0f, 0f, 0f, 1f), 1f, array<f32, 1>(), array<f32, 1>());
@group(0) @binding(0) 
var<uniform> global_11: type_19;
var<private> global_12: vec3<f32>;
var<private> global_13: vec3<f32>;
var<private> global_14: vec3<f32>;
var<private> global_15: vec2<f32>;
var<private> global_16: vec2<f32>;
var<private> global_17: vec4<f32>;
var<private> global_18: vec4<f32>;
var<private> global_19: vec4<f32>;
var<private> global_20: vec4<f32>;
var<private> global_21: vec4<f32>;
var<private> global_22: vec4<f32>;
var<private> global_23: vec4<f32>;
var<private> global_24: vec4<f32>;
var<private> global_25: vec3<f32>;
var<private> global_26: vec4<f32>;
var<private> global_27: vec4<f32>;
var<private> global_28: vec4<f32>;
var<private> global_29: vec4<f32>;

fn function_() {
    var phi_979_: vec3<f32>;
    var phi_980_: vec3<f32>;

    let _e74 = global_1;
    let _e75 = global_2;
    let _e76 = global_3;
    let _e77 = global_4;
    let _e78 = mat4x4<f32>(_e74, _e75, _e76, _e77);
    let _e79 = global_5;
    let _e80 = global_6;
    let _e81 = global_7;
    let _e82 = global_8;
    let _e83 = mat4x4<f32>(_e79, _e80, _e81, _e82);
    let _e84 = global_9;
    let _e87 = global.member_4[0u];
    let _e89 = global.member_1;
    let _e94 = vec4<f32>(_e89.x, _e89.y, _e89.z, 1f);
    let _e108 = mat3x3<f32>(vec3<f32>(_e74.x, _e74.y, _e74.z), vec3<f32>(_e75.x, _e75.y, _e75.z), vec3<f32>(_e76.x, _e76.y, _e76.z));
    let _e110 = global.member_2;
    let _e111 = _e110.xyz;
    let _e114 = max(dot(_e111, (_e84 - _e89.xyz)), 0f);
    let _e117 = global.member_3[2u];
    let _e119 = global.member_3;
    let _e120 = _e119.xy;
    let _e121 = (_e78 * _e94).xz;
    let _e126 = ((dot(_e121, _e120) * 0.35f) + (dot(_e121, vec2<f32>(0.83f, -0.57f)) * 1.7f));
    let _e139 = global.member_3[3u];
    let _e143 = (1f + (_e139 * (((0.5f + ((0.5f * sin(((_e87 * 0.61f) + _e126))) * sin(((_e87 * 0.23f) + (_e126 * 0.7f))))) * 1.6f) - 0.6f)));
    let _e157 = global.member_2[3u];
    let _e158 = ((((((_e117 * _e143) * (0.75f + (0.25f * sin(((_e87 * 1.7f) + (_e126 * 1.3f)))))) * 0.06f) * _e114) * _e114) * _e157);
    let _e162 = vec3<f32>(_e119.x, 0f, _e119.y);
    let _e163 = (transpose(_e108) * _e162);
    let _e164 = dot(_e163, _e163);
    if (_e164 > 0.000000000001f) {
        phi_979_ = (_e163 * inverseSqrt(_e164));
    } else {
        phi_979_ = vec3<f32>(0f, 0f, 0f);
    }
    let _e169 = phi_979_;
    let _e173 = max(_e114, 0.001f);
    let _e177 = dot(_e84, vec3<f32>(3.1f, 2.3f, 2.7f));
    let _e183 = (_e177 * 1.7f);
    let _e192 = global.member_1[3u];
    let _e193 = (_e192 * _e117);
    let _e198 = clamp((_e114 * 3f), 0f, 1f);
    let _e209 = vec3<f32>(sin(((_e177 * 1.3f) + 1f)), cos((_e177 * 0.9f)), sin((_e183 + 2f)));
    let _e212 = (_e84 + (((_e169 * _e158) - (_e111 * (((0.5f * _e158) * _e158) / _e173))) + (_e209 * ((((_e193 * (0.6f + (0.4f * _e143))) * _e198) * 0.02f) * (sin((((_e87 * 7.3f) + _e177) + _e126)) + (0.5f * sin((((_e87 * 11.1f) + _e183) + (_e126 * 2.1f)))))))));
    let _e215 = global.member_4[1u];
    let _e230 = (_e83 * _e94).xz;
    let _e235 = ((dot(_e230, _e120) * 0.35f) + (dot(_e230, vec2<f32>(0.83f, -0.57f)) * 1.7f));
    let _e249 = (1f + (_e139 * (((0.5f + ((0.5f * sin(((_e215 * 0.61f) + _e235))) * sin(((_e215 * 0.23f) + (_e235 * 0.7f))))) * 1.6f) - 0.6f)));
    let _e261 = ((((((_e117 * _e249) * (0.75f + (0.25f * sin(((_e215 * 1.7f) + (_e235 * 1.3f)))))) * 0.06f) * _e114) * _e114) * _e157);
    let _e263 = (transpose(mat3x3<f32>(vec3<f32>(_e79.x, _e79.y, _e79.z), vec3<f32>(_e80.x, _e80.y, _e80.z), vec3<f32>(_e81.x, _e81.y, _e81.z))) * _e162);
    let _e264 = dot(_e263, _e263);
    if (_e264 > 0.000000000001f) {
        phi_980_ = (_e263 * inverseSqrt(_e264));
    } else {
        phi_980_ = vec3<f32>(0f, 0f, 0f);
    }
    let _e269 = phi_980_;
    let _e295 = (_e84 + (((_e269 * _e261) - (_e111 * (((0.5f * _e261) * _e261) / _e173))) + (_e209 * ((((_e193 * (0.6f + (0.4f * _e249))) * _e198) * 0.02f) * (sin((((_e215 * 7.3f) + _e177) + _e235)) + (0.5f * sin((((_e215 * 11.1f) + _e183) + (_e235 * 2.1f)))))))));
    let _e300 = (_e78 * vec4<f32>(_e212.x, _e212.y, _e212.z, 1f));
    let _e306 = _e74.xyz;
    let _e307 = _e75.xyz;
    let _e308 = _e76.xyz;
    let _e311 = cross(_e306, _e307);
    let _e315 = select(1f, -1f, (dot(_e311, _e308) < 0f));
    let _e317 = global_11.member;
    global_10.member = (_e317 * _e300);
    let _e322 = global_10.member[1u];
    global_10.member[1u] = -(_e322);
    global_12 = _e300.xyz;
    let _e325 = global_14;
    global_13 = ((mat3x3<f32>(cross(_e307, _e308), cross(_e308, _e306), _e311) * _e325) * _e315);
    let _e328 = global_16;
    global_15 = _e328;
    let _e329 = global_18;
    global_17 = _e329;
    let _e330 = global_20;
    global_19 = _e330;
    let _e332 = global_11.member_2;
    global_21 = (_e332 * _e300);
    let _e335 = global_11.member_3;
    global_22 = (_e335 * (_e83 * vec4<f32>(_e295.x, _e295.y, _e295.z, 1f)));
    let _e337 = global_24;
    let _e339 = (_e108 * _e337.xyz);
    let _e341 = global_24[3u];
    global_23 = vec4<f32>(_e339.x, _e339.y, _e339.z, (_e341 * _e315));
    global_25 = _e84;
    let _e347 = global_27;
    global_26 = _e347;
    let _e348 = global_29;
    global_28 = _e348;
    return;
}

@vertex 
fn main(@location(3) param: vec4<f32>, @location(4) param_1: vec4<f32>, @location(5) param_2: vec4<f32>, @location(6) param_3: vec4<f32>, @location(7) param_4: vec4<f32>, @location(8) param_5: vec4<f32>, @location(9) param_6: vec4<f32>, @location(10) param_7: vec4<f32>, @location(0) param_8: vec3<f32>, @location(1) param_9: vec3<f32>, @location(2) param_10: vec2<f32>, @location(11) param_11: vec4<f32>, @location(12) param_12: vec4<f32>, @location(13) param_13: vec4<f32>, @location(14) param_14: vec4<f32>, @location(15) param_15: vec4<f32>) -> VertexOutput {
    global_1 = param;
    global_2 = param_1;
    global_3 = param_2;
    global_4 = param_3;
    global_5 = param_4;
    global_6 = param_5;
    global_7 = param_6;
    global_8 = param_7;
    global_9 = param_8;
    global_14 = param_9;
    global_16 = param_10;
    global_18 = param_11;
    global_20 = param_12;
    global_24 = param_13;
    global_27 = param_14;
    global_29 = param_15;
    function_();
    let _e46 = global_10.member.y;
    global_10.member.y = -(_e46);
    let _e48 = global_10.member;
    let _e49 = global_12;
    let _e50 = global_13;
    let _e51 = global_15;
    let _e52 = global_17;
    let _e53 = global_19;
    let _e54 = global_21;
    let _e55 = global_22;
    let _e56 = global_23;
    let _e57 = global_25;
    let _e58 = global_26;
    let _e59 = global_28;
    return VertexOutput(_e48, _e49, _e50, _e51, _e52, _e53, _e54, _e55, _e56, _e57, _e58, _e59);
}
