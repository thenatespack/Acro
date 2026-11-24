// Generated from particle.vert by Scripts/compile-shaders.sh — do not edit.
// Edit the GLSL and rerun the script (needs glslc, spirv-cross, spirv-opt and naga-cli).
// spirv-fnv1a64: d1b36d15948f0ddb
// glsl-fnv1a64: 79f4205eb434eb36

diagnostic(off, derivative_uniformity);

struct type_8 {
    member: mat4x4<f32>,
    member_1: vec4<f32>,
    member_2: array<vec4<f32>, 4>,
    member_3: vec4<f32>,
    member_4: vec4<f32>,
    member_5: vec4<f32>,
    member_6: vec4<f32>,
    member_7: vec4<f32>,
    member_8: vec4<f32>,
    member_9: vec4<f32>,
    member_10: vec4<f32>,
}

struct type_13 {
    member: vec4<f32>,
    member_1: vec4<f32>,
    member_2: vec4<f32>,
}

struct type_15 {
    member: array<type_13>,
}

struct type_18 {
    member: array<u32>,
}

struct type_31 {
    @builtin(position) member: vec4<f32>,
    member_1: f32,
    member_2: array<f32, 1>,
    member_3: array<f32, 1>,
}

struct VertexOutput {
    @location(0) member: vec2<f32>,
    @location(1) member_1: vec4<f32>,
    @location(2) member_2: vec4<f32>,
    @location(3) member_3: f32,
    @builtin(position) member_4: vec4<f32>,
}

@group(2) @binding(2) 
var<uniform> global: type_8;
@group(2) @binding(24) 
var<storage> global_1: type_15;
@group(2) @binding(25) 
var<storage> global_2: type_18;
var<private> global_3: i32;
var<private> global_4: i32;
var<private> global_5: vec2<f32>;
var<private> global_6: vec4<f32>;
var<private> global_7: vec4<f32>;
var<private> global_8: f32;
var<private> global_9: type_31 = type_31(vec4<f32>(0f, 0f, 0f, 1f), 1f, array<f32, 1>(), array<f32, 1>());

fn function_() {
    var local: array<vec2<f32>, 6>;
    var phi_746_: i32;
    var phi_749_: f32;
    var phi_750_: f32;
    var local_1: f32;
    var phi_751_: vec3<f32>;
    var phi_759_: f32;
    var phi_757_: f32;
    var phi_758_: f32;
    var phi_756_: f32;
    var phi_754_: vec3<f32>;
    var phi_752_: vec3<f32>;
    var phi_760_: i32;
    var phi_763_: vec4<f32>;
    var phi_764_: vec4<f32>;
    var local_2: vec4<f32>;
    var local_3: vec4<f32>;
    var local_4: vec4<f32>;
    var phi_765_: f32;
    var phi_767_: f32;
    var phi_768_: f32;
    var phi_771_: f32;
    var phi_770_: f32;
    var local_5: f32;
    var local_6: vec4<f32>;

    let _e44 = global_3;
    let _e47 = global_2.member[_e44];
    let _e51 = global_1.member[_e47].member;
    let _e53 = global_1.member[_e47].member_1;
    let _e55 = global_1.member[_e47].member_2;
    let _e56 = global_4;
    local = array<vec2<f32>, 6>(vec2<f32>(-1f, -1f), vec2<f32>(1f, -1f), vec2<f32>(1f, 1f), vec2<f32>(-1f, -1f), vec2<f32>(1f, 1f), vec2<f32>(-1f, 1f));
    let _e58 = local[_e56];
    let _e63 = clamp((_e51.w / max(_e53.w, 0.00001f)), 0f, 1f);
    let _e67 = global.member_7[1u];
    let _e71 = global.member_4[0u];
    phi_746_ = 1i;
    phi_749_ = _e71;
    loop {
        let _e73 = phi_746_;
        let _e75 = phi_749_;
        local_1 = _e75;
        if (_e73 < 4i) {
            if (_e73 >= i32(_e67)) {
                break;
            }
            let _e78 = (_e73 - 1i);
            let _e81 = global.member_5[_e78];
            let _e84 = global.member_5[_e73];
            phi_750_ = _e75;
            if (_e63 > _e81) {
                let _e88 = global.member_4[_e78];
                let _e91 = global.member_4[_e73];
                phi_750_ = mix(_e88, _e91, clamp(((_e63 - _e81) / max((_e84 - _e81), 0.00001f)), 0f, 1f));
            }
            let _e99 = phi_750_;
            local_5 = _e99;
            continue;
        } else {
            break;
        }
        continuing {
            phi_746_ = (_e73 + 1i);
            let _e350 = local_5;
            phi_749_ = _e350;
        }
    }
    let _e102 = local_1;
    let _e104 = _e51.xyz;
    let _e106 = global.member_1;
    let _e108 = (_e106.xyz - _e104);
    if (dot(_e108, _e108) > 0.0000000001f) {
        phi_751_ = normalize(_e108);
    } else {
        phi_751_ = vec3<f32>(0f, 0f, 1f);
    }
    let _e113 = phi_751_;
    let _e120 = normalize(cross(select(vec3<f32>(1f, 0f, 0f), vec3<f32>(0f, 1f, 0f), vec3((abs(_e113.y) < 0.999f))), _e113));
    let _e121 = cross(_e113, _e120);
    let _e122 = _e53.xyz;
    let _e125 = (_e122 - (_e113 * dot(_e122, _e113)));
    let _e126 = length(_e125);
    let _e129 = global.member_6[0u];
    if ((_e129 > 0f) && (_e126 > 0.0001f)) {
        let _e134 = (_e125 / vec3(_e126));
        let _e138 = global.member_6[3u];
        if (_e138 > 0.5f) {
            phi_759_ = ((0.5f * _e129) * _e126);
            phi_757_ = 1f;
        } else {
            phi_759_ = 0f;
            phi_757_ = (1f + (_e129 * _e126));
        }
        let _e145 = phi_759_;
        let _e147 = phi_757_;
        phi_758_ = _e145;
        phi_756_ = _e147;
        phi_754_ = _e134;
        phi_752_ = cross(_e134, _e113);
    } else {
        let _e151 = (_e55.y + (_e55.z * _e51.w));
        let _e152 = cos(_e151);
        let _e153 = sin(_e151);
        phi_758_ = 0f;
        phi_756_ = 1f;
        phi_754_ = ((_e121 * _e152) - (_e120 * _e153));
        phi_752_ = ((_e120 * _e152) + (_e121 * _e153));
    }
    let _e161 = phi_758_;
    let _e163 = phi_756_;
    let _e165 = phi_754_;
    let _e167 = phi_752_;
    let _e178 = ((_e104 + (((_e167 * _e58.x) + ((_e165 * _e58.y) * _e163)) * (_e55.x * _e102))) + (_e165 * (_e58.y * _e161)));
    let _e181 = global.member_7[0u];
    let _e185 = global.member_2[0i];
    phi_760_ = 1i;
    phi_763_ = _e185;
    loop {
        let _e187 = phi_760_;
        let _e189 = phi_763_;
        local_2 = _e189;
        local_3 = _e189;
        local_4 = _e189;
        if (_e187 < 4i) {
            if (_e187 >= i32(_e181)) {
                break;
            }
            let _e192 = (_e187 - 1i);
            let _e195 = global.member_3[_e192];
            let _e198 = global.member_3[_e187];
            phi_764_ = _e189;
            if (_e63 > _e195) {
                let _e202 = global.member_2[_e192];
                let _e205 = global.member_2[_e187];
                phi_764_ = mix(_e202, _e205, vec4(clamp(((_e63 - _e195) / max((_e198 - _e195), 0.00001f)), 0f, 1f)));
            }
            let _e214 = phi_764_;
            local_6 = _e214;
            continue;
        } else {
            break;
        }
        continuing {
            phi_760_ = (_e187 + 1i);
            let _e363 = local_6;
            phi_763_ = _e363;
        }
    }
    let _e218 = global.member_6[1u];
    let _e222 = global.member_6[2u];
    let _e226 = local_2;
    let _e230 = (_e226.xyz * (_e218 * mix(1f, _e55.w, _e222)));
    let _e233 = local_4;
    let _e238 = vec4<f32>(_e230.x, _e233.y, _e233.z, _e233.w);
    let _e244 = vec4<f32>(_e238.x, _e230.y, _e238.z, _e238.w);
    global_5 = _e58;
    global_6 = vec4<f32>(_e244.x, _e244.y, _e230.z, _e244.w);
    global_7 = vec4<f32>(0f, 0f, 0f, 0f);
    global_8 = 0f;
    let _e253 = global.member_9[2u];
    if (_e253 > 0.5f) {
        let _e257 = global.member_8[2u];
        let _e260 = global.member_8[3u];
        let _e261 = (_e260 > 0f);
        if _e261 {
            phi_765_ = (_e51.w * _e260);
        } else {
            phi_765_ = (_e63 * _e257);
        }
        let _e265 = phi_765_;
        let _e268 = global.member_9[0u];
        let _e269 = (_e268 > 0.5f);
        phi_767_ = _e265;
        if _e269 {
            phi_767_ = (_e265 + floor((_e55.w * _e257)));
        }
        let _e274 = phi_767_;
        let _e277 = floor(_e274);
        let _e280 = global.member_9[1u];
        if (_e280 > 0.5f) {
            phi_768_ = (_e274 - _e277);
        } else {
            phi_768_ = 0f;
        }
        let _e284 = phi_768_;
        global_8 = _e284;
        let _e285 = (_e277 + 1f);
        if select(_e261, _e269, !(_e261)) {
            phi_771_ = (_e285 - (floor((_e285 / _e257)) * _e257));
            phi_770_ = (_e277 - (floor((_e277 / _e257)) * _e257));
        } else {
            let _e294 = (_e257 - 1f);
            phi_771_ = min(_e285, _e294);
            phi_770_ = min(_e277, _e294);
        }
        let _e298 = phi_771_;
        let _e300 = phi_770_;
        let _e305 = vec2<f32>(((_e58.x * 0.5f) + 0.5f), (0.5f - (_e58.y * 0.5f)));
        let _e308 = global.member_8[0u];
        let _e318 = global.member_8;
        let _e319 = _e318.xy;
        let _e320 = ((vec2<f32>((_e300 - (floor((_e300 / _e308)) * _e308)), floor((_e300 / _e308))) + _e305) / _e319);
        let _e329 = ((vec2<f32>((_e298 - (floor((_e298 / _e308)) * _e308)), floor((_e298 / _e308))) + _e305) / _e319);
        global_7 = vec4<f32>(_e320.x, _e320.y, _e329.x, _e329.y);
    }
    let _e336 = global.member;
    global_9.member = (_e336 * vec4<f32>(_e178.x, _e178.y, _e178.z, 1f));
    let _e345 = global_9.member[1u];
    global_9.member[1u] = -(_e345);
    return;
}

@vertex 
fn main(@builtin(instance_index) param: u32, @builtin(vertex_index) param_1: u32) -> VertexOutput {
    global_3 = i32(param);
    global_4 = i32(param_1);
    function_();
    let _e13 = global_9.member.y;
    global_9.member.y = -(_e13);
    let _e15 = global_5;
    let _e16 = global_6;
    let _e17 = global_7;
    let _e18 = global_8;
    let _e19 = global_9.member;
    return VertexOutput(_e15, _e16, _e17, _e18, _e19);
}
