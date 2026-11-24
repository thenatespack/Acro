// Generated from ui.frag by Scripts/compile-shaders.sh — do not edit.
// Edit the GLSL and rerun the script (needs glslc, spirv-cross, spirv-opt and naga-cli).
// spirv-fnv1a64: 14116735d09891bb
// glsl-fnv1a64: d75b6e9d41c2b8b4

diagnostic(off, derivative_uniformity);

@group(2) @binding(9) 
var global: texture_2d<f32>;
@group(2) @binding(17) 
var global_1: sampler;
var<private> global_2: vec2<f32>;
var<private> global_3: vec4<f32>;
var<private> global_4: vec2<f32>;
var<private> global_5: vec2<f32>;
var<private> global_6: vec4<f32>;
var<private> global_7: vec4<f32>;
var<private> global_8: vec4<f32>;

fn function_() {
    var phi_329_: f32;
    var phi_328_: f32;
    var phi_330_: f32;
    var phi_335_: f32;
    var phi_333_: vec4<f32>;
    var phi_332_: vec4<f32>;
    var phi_331_: vec4<f32>;

    let _e32 = global_2;
    let _e33 = textureSample(global, global_1, _e32);
    let _e35 = global_3[1u];
    let _e37 = i32((_e35 + 0.5f));
    let _e39 = global_3[0u];
    let _e40 = global_4;
    let _e41 = global_5;
    let _e42 = global_6;
    if (_e40.x < 0f) {
        if (_e40.y < 0f) {
            phi_329_ = _e42.x;
        } else {
            phi_329_ = _e42.w;
        }
        let _e50 = phi_329_;
        phi_330_ = _e50;
    } else {
        if (_e40.y < 0f) {
            phi_328_ = _e42.y;
        } else {
            phi_328_ = _e42.z;
        }
        let _e56 = phi_328_;
        phi_330_ = _e56;
    }
    let _e58 = phi_330_;
    let _e62 = ((abs(_e40) - _e41) + vec2(_e58));
    let _e70 = ((min(max(_e62.x, _e62.y), 0f) + length(max(_e62, vec2<f32>(0f, 0f)))) - _e58);
    if (_e39 > 0f) {
        let _e72 = (0.5f * _e39);
        phi_335_ = clamp((0.5f - (abs((_e70 + _e72)) - _e72)), 0f, 1f);
    } else {
        phi_335_ = clamp((0.5f - _e70), 0f, 1f);
    }
    let _e81 = phi_335_;
    let _e82 = global_7;
    let _e83 = clamp(_e82, vec4<f32>(0f, 0f, 0f, 0f), vec4<f32>(1f, 1f, 1f, 1f));
    let _e84 = _e83.xyz;
    let _e90 = mix((_e84 * vec3<f32>(0.07739938f, 0.07739938f, 0.07739938f)), pow(((_e84 + vec3<f32>(0.055f, 0.055f, 0.055f)) * vec3<f32>(0.94786733f, 0.94786733f, 0.94786733f)), vec3<f32>(2.4f, 2.4f, 2.4f)), step(vec3<f32>(0.04045f, 0.04045f, 0.04045f), _e84));
    let _e95 = vec4<f32>(_e90.x, _e90.y, _e90.z, _e83.w);
    if (_e37 == 1i) {
        phi_331_ = (_e95 * _e33);
    } else {
        if (_e37 == 2i) {
            phi_332_ = vec4<f32>(_e95.x, _e95.y, _e95.z, (_e83.w * _e33.w));
        } else {
            phi_333_ = _e95;
            if (_e37 == 3i) {
                let _e110 = global_3[2u];
                phi_333_ = vec4<f32>(_e95.x, _e95.y, _e95.z, (_e83.w * clamp((((_e33.w - 0.5f) / max(_e110, 0.0001f)) + 0.5f), 0f, 1f)));
            }
            let _e122 = phi_333_;
            phi_332_ = _e122;
        }
        let _e124 = phi_332_;
        phi_331_ = _e124;
    }
    let _e126 = phi_331_;
    global_8 = vec4<f32>(_e126.x, _e126.y, _e126.z, (_e126.w * _e81));
    return;
}

@fragment 
fn main(@location(0) param: vec2<f32>, @location(5) @interpolate(flat) param_1: vec4<f32>, @location(2) param_2: vec2<f32>, @location(3) @interpolate(flat) param_3: vec2<f32>, @location(4) @interpolate(flat) param_4: vec4<f32>, @location(1) param_5: vec4<f32>) -> @location(0) vec4<f32> {
    global_2 = param;
    global_3 = param_1;
    global_4 = param_2;
    global_5 = param_3;
    global_6 = param_4;
    global_7 = param_5;
    function_();
    let _e13 = global_8;
    return _e13;
}
