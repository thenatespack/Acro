// Generated from env_prefilter.frag by Scripts/compile-shaders.sh — do not edit.
// Edit the GLSL and rerun the script (needs glslc, spirv-cross, spirv-opt and naga-cli).
// spirv-fnv1a64: 16e3facbf0fb45b3
// glsl-fnv1a64: 0e339047ceace433

diagnostic(off, derivative_uniformity);

struct type_12 {
    member: vec2<i32>,
    member_1: vec2<f32>,
    member_2: f32,
    member_3: i32,
}

var<private> global: vec4<f32>;
@group(3) @binding(0) 
var<uniform> global_1: type_12;
@group(2) @binding(9) 
var global_2: texture_2d<f32>;
@group(2) @binding(17) 
var global_3: sampler;
var<private> global_4: vec4<f32>;

fn function_() {
    var phi_639_: f32;
    var phi_638_: vec3<f32>;
    var phi_637_: i32;
    var phi_640_: i32;
    var phi_641_: i32;
    var phi_658_: f32;
    var phi_657_: vec3<f32>;
    var local: f32;
    var local_1: vec3<f32>;
    var local_2: f32;
    var local_3: vec3<f32>;

    let _e25 = global;
    let _e28 = global_1.member_1;
    let _e29 = (_e25.xy / _e28);
    let _e32 = ((_e29.x - 0.5f) * 6.2831855f);
    let _e34 = (_e29.y * 3.1415927f);
    let _e35 = sin(_e34);
    let _e38 = cos(_e34);
    let _e42 = vec3<f32>((_e35 * sin(_e32)), _e38, (-(_e35) * cos(_e32)));
    let _e48 = normalize(cross(select(vec3<f32>(1f, 0f, 0f), vec3<f32>(0f, 1f, 0f), vec3((abs(_e38) < 0.999f))), _e42));
    let _e51 = global_1.member;
    let _e54 = vec4<i32>(0i, 0i, _e51.x, _e51.y);
    let _e56 = global_1.member_2;
    phi_639_ = 0f;
    phi_638_ = vec3<f32>(0f, 0f, 0f);
    phi_637_ = 0i;
    loop {
        let _e59 = phi_639_;
        let _e61 = phi_638_;
        let _e63 = phi_637_;
        let _e65 = global_1.member_3;
        local = _e59;
        local_1 = _e61;
        if (_e63 < _e65) {
            let _e73 = (f32(reverseBits(bitcast<u32>(_e63))) * 0.00000000023283064f);
            let _e74 = (6.2831855f * (f32(_e63) / f32(_e65)));
            let _e80 = sqrt(((1f - _e73) / (1f + (((_e56 * _e56) - 1f) * _e73))));
            let _e84 = sqrt(max((1f - (_e80 * _e80)), 0f));
            let _e93 = (((_e48 * (_e84 * cos(_e74))) + (cross(_e42, _e48) * (_e84 * sin(_e74)))) + (_e42 * _e80));
            let _e97 = ((_e93 * (2f * dot(_e42, _e93))) - _e42);
            let _e98 = dot(_e42, _e97);
            phi_658_ = _e59;
            phi_657_ = _e61;
            if (_e98 > 0f) {
                let _e114 = ((vec2<f32>(((atan2(_e97.x, -(_e97.z)) * 0.15915494f) + 0.5f), (acos(clamp(_e97.y, -1f, 1f)) * 0.31830987f)) * vec2<f32>(_e54.zw)) - vec2<f32>(0.5f, 0.5f));
                let _e115 = floor(_e114);
                let _e116 = (_e114 - _e115);
                let _e118 = i32(_e115.x);
                let _e120 = i32(_e115.y);
                phi_640_ = _e118;
                if (_e118 < 0i) {
                    phi_640_ = (_e118 + _e51.x);
                }
                let _e124 = phi_640_;
                phi_641_ = _e124;
                if (_e124 >= _e51.x) {
                    phi_641_ = (_e124 - _e51.x);
                }
                let _e128 = phi_641_;
                let _e129 = (_e128 + 1i);
                let _e131 = select(_e129, 0i, (_e129 == _e51.x));
                let _e134 = min((_e120 + 1i), (_e51.y - 1i));
                let _e135 = max(_e120, 0i);
                let _e136 = _e54.xy;
                let _e139 = textureLoad(global_2, (_e136 + vec2<i32>(_e128, _e135)), 0i);
                let _e143 = textureLoad(global_2, (_e136 + vec2<i32>(_e131, _e135)), 0i);
                let _e147 = textureLoad(global_2, (_e136 + vec2<i32>(_e128, _e134)), 0i);
                let _e151 = textureLoad(global_2, (_e136 + vec2<i32>(_e131, _e134)), 0i);
                let _e154 = vec3(_e116.x);
                phi_658_ = (_e59 + _e98);
                phi_657_ = (_e61 + (mix(mix(_e139.xyz, _e143.xyz, _e154), mix(_e147.xyz, _e151.xyz, _e154), vec3(_e116.y)) * _e98));
            }
            let _e164 = phi_658_;
            let _e166 = phi_657_;
            local_2 = _e164;
            local_3 = _e166;
            continue;
        } else {
            break;
        }
        continuing {
            let _e181 = local_2;
            phi_639_ = _e181;
            let _e184 = local_3;
            phi_638_ = _e184;
            phi_637_ = (_e63 + 1i);
        }
    }
    let _e169 = local;
    let _e173 = local_1;
    let _e174 = (_e173 / vec3(max(_e169, 0.000001f)));
    global_4 = vec4<f32>(_e174.x, _e174.y, _e174.z, 1f);
    return;
}

@fragment 
fn main(@builtin(position) param: vec4<f32>) -> @location(0) vec4<f32> {
    global = param;
    function_();
    let _e3 = global_4;
    return _e3;
}
