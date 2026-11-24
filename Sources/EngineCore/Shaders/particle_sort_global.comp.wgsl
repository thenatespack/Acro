// Generated from particle_sort_global.comp by Scripts/compile-shaders.sh — do not edit.
// Edit the GLSL and rerun the script (needs glslc, spirv-cross, spirv-opt and naga-cli).
// spirv-fnv1a64: 65183d349d72525a
// glsl-fnv1a64: ccd34339da422625

diagnostic(off, derivative_uniformity);

struct type_5 {
    member: vec4<u32>,
}

struct type_11 {
    member: array<vec2<u32>>,
}

var<private> global: vec3<u32>;
@group(3) @binding(0) 
var<uniform> global_1: type_5;
@group(2) @binding(31) 
var<storage, read_write> global_2: type_11;

fn function_() {
    var phi_87_: bool;
    var phi_88_: bool;

    let _e10 = global[0u];
    let _e13 = global_1.member[1u];
    let _e18 = (((2u * _e13) * (_e10 / _e13)) + (_e10 % _e13));
    let _e22 = global_2.member[_e18];
    let _e25 = global_2.member[(_e18 + _e13)];
    let _e28 = global_1.member[0u];
    let _e33 = (_e25.x < _e22.x);
    phi_88_ = _e33;
    if !(_e33) {
        let _e35 = (_e25.x == _e22.x);
        phi_87_ = _e35;
        if _e35 {
            phi_87_ = (_e25.y < _e22.y);
        }
        let _e40 = phi_87_;
        phi_88_ = _e40;
    }
    let _e42 = phi_88_;
    if (_e42 == ((_e18 & _e28) == 0u)) {
        global_2.member[_e18] = _e25;
        global_2.member[(_e18 + _e13)] = _e22;
    }
    return;
}

@compute @workgroup_size(256, 1, 1) 
fn main(@builtin(global_invocation_id) param: vec3<u32>) {
    global = param;
    function_();
}
