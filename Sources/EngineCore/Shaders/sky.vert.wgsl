// Generated from sky.vert by Scripts/compile-shaders.sh — do not edit.
// Edit the GLSL and rerun the script (needs glslc, spirv-cross, spirv-opt and naga-cli).
// spirv-fnv1a64: 4235d2bddf84cd91
// glsl-fnv1a64: ad1a15be52517b55

diagnostic(off, derivative_uniformity);

struct type_8 {
    member: mat4x4<f32>,
    member_1: vec4<f32>,
    member_2: vec4<f32>,
    member_3: vec4<f32>,
    member_4: vec4<f32>,
    member_5: vec4<f32>,
    member_6: vec4<f32>,
    member_7: vec4<f32>,
    member_8: vec4<f32>,
}

struct type_16 {
    @builtin(position) member: vec4<f32>,
    member_1: f32,
    member_2: array<f32, 1>,
    member_3: array<f32, 1>,
}

struct VertexOutput {
    @location(0) member: vec4<f32>,
    @builtin(position) member_1: vec4<f32>,
}

var<private> global: i32;
var<private> global_1: vec4<f32>;
@group(2) @binding(2) 
var<uniform> global_2: type_8;
var<private> global_3: type_16 = type_16(vec4<f32>(0f, 0f, 0f, 1f), 1f, array<f32, 1>(), array<f32, 1>());

fn function_() {
    let _e15 = global;
    let _e24 = ((vec2<f32>(f32(((_e15 << bitcast<u32>(1i)) & 2i)), f32((_e15 & 2i))) * 2f) - vec2<f32>(1f, 1f));
    let _e26 = global_2.member;
    let _e29 = global_2.member_2[0u];
    let _e32 = vec4<f32>(_e24.x, _e24.y, _e29, 1f);
    global_1 = (_e26 * _e32);
    let _e36 = global_2.member_2[2u];
    if (_e36 > 0.5f) {
        let _e40 = (_e26 * vec4<f32>(_e24.x, _e24.y, (1f - _e29), 1f));
        let _e41 = global_1;
        let _e44 = global_1[3u];
        let _e51 = ((_e41.xyz / vec3(_e44)) - (_e40.xyz / vec3(_e40.w)));
        global_1 = vec4<f32>(_e51.x, _e51.y, _e51.z, 1f);
    }
    global_3.member = _e32;
    let _e59 = global_3.member[1u];
    global_3.member[1u] = -(_e59);
    return;
}

@vertex 
fn main(@builtin(vertex_index) param: u32) -> VertexOutput {
    global = i32(param);
    function_();
    let _e7 = global_3.member.y;
    global_3.member.y = -(_e7);
    let _e9 = global_1;
    let _e10 = global_3.member;
    return VertexOutput(_e9, _e10);
}
