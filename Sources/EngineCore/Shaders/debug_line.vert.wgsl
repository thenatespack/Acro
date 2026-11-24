// Generated from debug_line.vert by Scripts/compile-shaders.sh — do not edit.
// Edit the GLSL and rerun the script (needs glslc, spirv-cross, spirv-opt and naga-cli).
// spirv-fnv1a64: 6642f30ccaf40729
// glsl-fnv1a64: 2270d0a3345da869

diagnostic(off, derivative_uniformity);

struct type_3 {
    member: mat4x4<f32>,
    member_1: vec4<f32>,
}

struct type_12 {
    @builtin(position) member: vec4<f32>,
    member_1: f32,
    member_2: array<f32, 1>,
    member_3: array<f32, 1>,
}

struct VertexOutput {
    @location(0) member: vec4<f32>,
    @builtin(position) member_1: vec4<f32>,
    @location(1) @interpolate(linear) member_2: vec2<f32>,
}

@group(3) @binding(0) 
var<uniform> global: type_3;
var<private> global_1: vec4<f32>;
var<private> global_2: vec4<f32>;
var<private> global_3: vec4<f32>;
var<private> global_4: vec4<f32>;
var<private> global_5: type_12 = type_12(vec4<f32>(0f, 0f, 0f, 1f), 1f, array<f32, 1>(), array<f32, 1>());
var<private> global_6: vec2<f32>;
var<private> global_7: i32;

fn function_() {
    var local: array<vec2<f32>, 6>;
    var phi_316_: f32;
    var phi_318_: f32;
    var phi_323_: vec4<f32>;
    var phi_324_: vec4<f32>;
    var phi_326_: vec2<f32>;
    var phi_329_: f32;

    switch bitcast<i32>(0u) {
        default: {
            let _e31 = global.member;
            let _e32 = global_1;
            let _e37 = (_e31 * vec4<f32>(_e32.x, _e32.y, _e32.z, 1f));
            let _e38 = global_2;
            let _e43 = (_e31 * vec4<f32>(_e38.x, _e38.y, _e38.z, 1f));
            let _e46 = global.member_1[2u];
            let _e47 = (_e46 > 0.5f);
            if _e47 {
                phi_316_ = (_e37.w - _e37.z);
            } else {
                phi_316_ = _e37.z;
            }
            let _e53 = phi_316_;
            if _e47 {
                phi_318_ = (_e43.w - _e43.z);
            } else {
                phi_318_ = _e43.z;
            }
            let _e59 = phi_318_;
            let _e60 = global_4;
            global_3 = _e60;
            let _e61 = (_e53 < 0f);
            let _e62 = (_e59 < 0f);
            if (_e61 && _e62) {
                global_5.member = vec4<f32>(0f, 0f, 0.5f, 1f);
                global_6 = vec2<f32>(0f, 0f);
                break;
            }
            phi_323_ = _e37;
            if _e61 {
                phi_323_ = mix(_e37, _e43, vec4((_e53 / (_e53 - _e59))));
            }
            let _e70 = phi_323_;
            phi_324_ = _e43;
            if _e62 {
                phi_324_ = mix(_e43, _e37, vec4((_e59 / (_e59 - _e53))));
            }
            let _e76 = phi_324_;
            let _e78 = global.member_1;
            let _e80 = (_e78.xy * 0.5f);
            let _e85 = ((_e70.xy / vec2(_e70.w)) * _e80);
            let _e90 = ((_e76.xy / vec2(_e76.w)) * _e80);
            let _e91 = (_e90 - _e85);
            let _e92 = length(_e91);
            if (_e92 > 0.0001f) {
                phi_326_ = (_e91 / vec2(_e92));
            } else {
                phi_326_ = vec2<f32>(1f, 0f);
            }
            let _e97 = phi_326_;
            let _e102 = global_7;
            local = array<vec2<f32>, 6>(vec2<f32>(0f, -1f), vec2<f32>(1f, -1f), vec2<f32>(1f, 1f), vec2<f32>(0f, -1f), vec2<f32>(1f, 1f), vec2<f32>(0f, 1f));
            let _e104 = local[_e102];
            let _e106 = (_e104.x > 0.5f);
            let _e108 = select(_e70, _e76, vec4(_e106));
            let _e110 = global_1[3u];
            if (_e110 >= 0f) {
                phi_329_ = _e110;
            } else {
                let _e117 = global.member_1[3u];
                phi_329_ = (((-(_e110) * _e80.y) * _e117) / _e108.w);
            }
            let _e122 = phi_329_;
            let _e123 = (0.5f * _e122);
            let _e124 = (_e123 + 1f);
            let _e128 = (_e104.y * _e124);
            let _e137 = ((((select(_e85, _e90, vec2(_e106)) + (vec2<f32>(-(_e97.y), _e97.x) * _e128)) + (_e97 * (select(-1f, 1f, _e106) * _e124))) / _e80) * _e108.w);
            global_5.member = vec4<f32>(_e137.x, _e137.y, _e108.z, _e108.w);
            global_6 = vec2<f32>(_e128, _e123);
            let _e146 = global_5.member[1u];
            global_5.member[1u] = -(_e146);
            break;
        }
    }
    return;
}

@vertex 
fn main(@location(0) param: vec4<f32>, @location(1) param_1: vec4<f32>, @location(2) param_2: vec4<f32>, @builtin(vertex_index) param_3: u32) -> VertexOutput {
    global_1 = param;
    global_2 = param_1;
    global_4 = param_2;
    global_7 = i32(param_3);
    function_();
    let _e14 = global_5.member.y;
    global_5.member.y = -(_e14);
    let _e16 = global_3;
    let _e17 = global_5.member;
    let _e18 = global_6;
    return VertexOutput(_e16, _e17, _e18);
}
