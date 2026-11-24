// Generated from decal.vert by Scripts/compile-shaders.sh — do not edit.
// Edit the GLSL and rerun the script (needs glslc, spirv-cross, spirv-opt and naga-cli).
// spirv-fnv1a64: 4554a98134ea4f9c
// glsl-fnv1a64: fb6d431f66aaae0b

diagnostic(off, derivative_uniformity);

struct type_3 {
    member: mat4x4<f32>,
    member_1: mat4x4<f32>,
    member_2: mat4x4<f32>,
    member_3: vec4<f32>,
    member_4: vec4<f32>,
    member_5: vec4<f32>,
}

struct type_17 {
    @builtin(position) member: vec4<f32>,
    member_1: f32,
    member_2: array<f32, 1>,
    member_3: array<f32, 1>,
}

struct type_19 {
    member: mat4x4<f32>,
}

@group(2) @binding(2) 
var<uniform> global: type_3;
var<private> global_1: i32;
var<private> global_2: type_17 = type_17(vec4<f32>(0f, 0f, 0f, 1f), 1f, array<f32, 1>(), array<f32, 1>());
@group(0) @binding(0) 
var<uniform> global_3: type_19;

fn function_() {
    var local: array<i32, 36>;
    var local_1: array<vec3<f32>, 8>;

    let _e31 = global.member;
    let _e32 = global_1;
    local = array<i32, 36>(1i, 3i, 7i, 1i, 7i, 5i, 0i, 4i, 6i, 0i, 6i, 2i, 2i, 6i, 7i, 2i, 7i, 3i, 0i, 1i, 5i, 0i, 5i, 4i, 4i, 5i, 7i, 4i, 7i, 6i, 0i, 2i, 3i, 0i, 3i, 1i);
    let _e34 = local[_e32];
    local_1 = array<vec3<f32>, 8>(vec3<f32>(-0.5f, -0.5f, -0.5f), vec3<f32>(0.5f, -0.5f, -0.5f), vec3<f32>(-0.5f, 0.5f, -0.5f), vec3<f32>(0.5f, 0.5f, -0.5f), vec3<f32>(-0.5f, -0.5f, 0.5f), vec3<f32>(0.5f, -0.5f, 0.5f), vec3<f32>(-0.5f, 0.5f, 0.5f), vec3<f32>(0.5f, 0.5f, 0.5f));
    let _e36 = local_1[_e34];
    let _e43 = global_3.member;
    global_2.member = (_e43 * (_e31 * vec4<f32>(_e36.x, _e36.y, _e36.z, 1f)));
    let _e48 = global_2.member[1u];
    global_2.member[1u] = -(_e48);
    return;
}

@vertex 
fn main(@builtin(vertex_index) param: u32) -> @builtin(position) vec4<f32> {
    global_1 = i32(param);
    function_();
    let _e6 = global_2.member.y;
    global_2.member.y = -(_e6);
    let _e8 = global_2.member;
    return _e8;
}
