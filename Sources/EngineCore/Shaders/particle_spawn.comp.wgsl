// Generated from particle_spawn.comp by Scripts/compile-shaders.sh — do not edit.
// Edit the GLSL and rerun the script (needs glslc, spirv-cross, spirv-opt and naga-cli).
// spirv-fnv1a64: a674f14677076885
// glsl-fnv1a64: 6b04d3897b976218

diagnostic(off, derivative_uniformity);

struct type_7 {
    member: mat4x4<f32>,
    member_1: vec4<f32>,
    member_2: vec4<f32>,
    member_3: vec4<f32>,
    member_4: vec4<f32>,
    member_5: vec4<f32>,
    member_6: vec4<f32>,
    member_7: vec4<f32>,
    member_8: vec4<f32>,
    member_9: vec4<u32>,
    member_10: vec4<u32>,
    member_11: vec4<f32>,
    member_12: vec4<u32>,
    member_13: vec4<f32>,
    member_14: vec4<f32>,
    member_15: vec4<f32>,
    member_16: mat4x4<f32>,
    member_17: mat4x4<f32>,
    member_18: array<vec4<f32>, 8>,
}

struct type_8 {
    member: type_7,
}

struct type_22 {
    member: array<u32>,
}

struct type_25 {
    member: u32,
    member_1: f32,
}

struct type_28 {
    member: array<vec4<f32>>,
}

struct type_31 {
    member: vec4<f32>,
    member_1: vec4<f32>,
    member_2: vec4<f32>,
}

struct type_33 {
    member: array<type_31>,
}

@group(2) @binding(2) 
var<uniform> global: type_8;
var<private> global_1: vec3<u32>;
@group(2) @binding(29) 
var<storage> global_2: type_22;
@group(3) @binding(0) 
var<uniform> global_3: type_25;
@group(2) @binding(28) 
var<storage> global_4: type_28;
@group(2) @binding(24) 
var<storage, read_write> global_5: type_33;

fn function_() {
    var phi_1613_: f32;
    var phi_1612_: f32;
    var phi_1616_: vec3<f32>;
    var phi_1615_: vec3<f32>;
    var phi_1614_: vec3<f32>;
    var phi_1617_: vec3<f32>;
    var phi_1618_: f32;
    var phi_1624_: vec3<f32>;

    switch bitcast<i32>(0u) {
        default: {
            let _e59 = global_1[0u];
            let _e62 = global_2.member[5i];
            if (_e59 >= _e62) {
                break;
            }
            let _e65 = global_3.member;
            let _e69 = global_2.member[6i];
            let _e74 = global.member.member_9[3u];
            let _e76 = ((_e74 * 747796405u) + 2891336453u);
            let _e83 = (((_e76 >> bitcast<u32>(((_e76 >> bitcast<u32>(28u)) + 4u))) ^ _e76) * 277803737u);
            let _e89 = ((((_e69 + _e59) ^ ((_e83 >> bitcast<u32>(22u)) ^ _e83)) * 747796405u) + 2891336453u);
            let _e96 = (((_e89 >> bitcast<u32>(((_e89 >> bitcast<u32>(28u)) + 4u))) ^ _e89) * 277803737u);
            let _e99 = ((_e96 >> bitcast<u32>(22u)) ^ _e96);
            let _e102 = global.member.member_1;
            let _e107 = global.member.member_1[0u];
            let _e108 = u32(_e107);
            if (_e108 == 1u) {
                let _e111 = ((_e99 * 747796405u) + 2891336453u);
                let _e118 = (((_e111 >> bitcast<u32>(((_e111 >> bitcast<u32>(28u)) + 4u))) ^ _e111) * 277803737u);
                let _e126 = ((f32((((_e118 >> bitcast<u32>(22u)) ^ _e118) >> bitcast<u32>(8i))) * 0.00000011920929f) - 1f);
                let _e129 = (((_e99 + 2654435769u) * 747796405u) + 2891336453u);
                let _e136 = (((_e129 >> bitcast<u32>(((_e129 >> bitcast<u32>(28u)) + 4u))) ^ _e129) * 277803737u);
                let _e143 = (f32((((_e136 >> bitcast<u32>(22u)) ^ _e136) >> bitcast<u32>(8i))) * 0.00000037450704f);
                let _e151 = (vec2<f32>(cos(_e143), sin(_e143)) * sqrt(max((1f - (_e126 * _e126)), 0f)));
                let _e159 = (((_e99 + 1013904242u) * 747796405u) + 2891336453u);
                let _e166 = (((_e159 >> bitcast<u32>(((_e159 >> bitcast<u32>(28u)) + 4u))) ^ _e159) * 277803737u);
                phi_1614_ = ((vec3<f32>(_e151.x, _e151.y, _e126) * _e102.y) * pow((f32((((_e166 >> bitcast<u32>(22u)) ^ _e166) >> bitcast<u32>(8i))) * 0.000000059604645f), 0.33333334f));
            } else {
                if (_e108 == 2u) {
                    let _e178 = ((_e99 * 747796405u) + 2891336453u);
                    let _e185 = (((_e178 >> bitcast<u32>(((_e178 >> bitcast<u32>(28u)) + 4u))) ^ _e178) * 277803737u);
                    let _e195 = (((_e99 + 2654435769u) * 747796405u) + 2891336453u);
                    let _e202 = (((_e195 >> bitcast<u32>(((_e195 >> bitcast<u32>(28u)) + 4u))) ^ _e195) * 277803737u);
                    let _e212 = (((_e99 + 1013904242u) * 747796405u) + 2891336453u);
                    let _e219 = (((_e212 >> bitcast<u32>(((_e212 >> bitcast<u32>(28u)) + 4u))) ^ _e212) * 277803737u);
                    phi_1615_ = (((vec3<f32>((f32((((_e185 >> bitcast<u32>(22u)) ^ _e185) >> bitcast<u32>(8i))) * 0.000000059604645f), (f32((((_e202 >> bitcast<u32>(22u)) ^ _e202) >> bitcast<u32>(8i))) * 0.000000059604645f), (f32((((_e219 >> bitcast<u32>(22u)) ^ _e219) >> bitcast<u32>(8i))) * 0.000000059604645f)) * 2f) - vec3<f32>(1f, 1f, 1f)) * _e102.yzw);
                } else {
                    phi_1616_ = vec3<f32>(0f, 0f, 0f);
                    if (_e108 == 3u) {
                        let _e234 = ((_e99 * 747796405u) + 2891336453u);
                        let _e241 = (((_e234 >> bitcast<u32>(((_e234 >> bitcast<u32>(28u)) + 4u))) ^ _e234) * 277803737u);
                        let _e248 = (f32((((_e241 >> bitcast<u32>(22u)) ^ _e241) >> bitcast<u32>(8i))) * 0.000000059604645f);
                        let _e253 = (((_e99 + 2654435769u) * 747796405u) + 2891336453u);
                        let _e260 = (((_e253 >> bitcast<u32>(((_e253 >> bitcast<u32>(28u)) + 4u))) ^ _e253) * 277803737u);
                        let _e266 = f32((((_e260 >> bitcast<u32>(22u)) ^ _e260) >> bitcast<u32>(8i)));
                        let _e272 = global.member.member_8[0u];
                        phi_1613_ = (_e102.y * sqrt(_e248));
                        phi_1612_ = (_e266 * 0.00000037450704f);
                        if (_e272 > 0f) {
                            let _e274 = (_e102.y * _e248);
                            let _e282 = global.member.member_11[0u];
                            let _e287 = global.member.member_8[1u];
                            let _e292 = (((_e99 + 3668340011u) * 747796405u) + 2891336453u);
                            let _e299 = (((_e292 >> bitcast<u32>(((_e292 >> bitcast<u32>(28u)) + 4u))) ^ _e292) * 277803737u);
                            let _e311 = global.member.member_8[2u];
                            phi_1613_ = _e274;
                            phi_1612_ = (((((floor(((_e266 * 0.000000059604645f) * _e272)) * 6.2831855f) / _e272) + _e282) + (_e274 * _e287)) + (((f32((((_e299 >> bitcast<u32>(22u)) ^ _e299) >> bitcast<u32>(8i))) * 0.000000059604645f) - 0.5f) * _e311));
                        }
                        let _e315 = phi_1613_;
                        let _e317 = phi_1612_;
                        let _e322 = (((_e99 + 1013904242u) * 747796405u) + 2891336453u);
                        let _e329 = (((_e322 >> bitcast<u32>(((_e322 >> bitcast<u32>(28u)) + 4u))) ^ _e322) * 277803737u);
                        phi_1616_ = vec3<f32>((cos(_e317) * _e315), (((f32((((_e329 >> bitcast<u32>(22u)) ^ _e329) >> bitcast<u32>(8i))) * 0.000000059604645f) - 0.5f) * _e102.z), (sin(_e317) * _e315));
                    }
                    let _e344 = phi_1616_;
                    phi_1615_ = _e344;
                }
                let _e346 = phi_1615_;
                phi_1614_ = _e346;
            }
            let _e348 = phi_1614_;
            let _e351 = global.member.member_2;
            let _e353 = normalize(_e351.xyz);
            let _e360 = normalize(cross(select(vec3<f32>(1f, 0f, 0f), vec3<f32>(0f, 1f, 0f), vec3((abs(_e353.y) < 0.99f))), _e353));
            let _e365 = global.member.member_2[3u];
            let _e368 = (((_e99 + 2027808484u) * 747796405u) + 2891336453u);
            let _e375 = (((_e368 >> bitcast<u32>(((_e368 >> bitcast<u32>(28u)) + 4u))) ^ _e368) * 277803737u);
            let _e383 = mix(_e365, 1f, (f32((((_e375 >> bitcast<u32>(22u)) ^ _e375) >> bitcast<u32>(8i))) * 0.000000059604645f));
            let _e390 = (((_e99 + 387276957u) * 747796405u) + 2891336453u);
            let _e397 = (((_e390 >> bitcast<u32>(((_e390 >> bitcast<u32>(28u)) + 4u))) ^ _e390) * 277803737u);
            let _e404 = (f32((((_e397 >> bitcast<u32>(22u)) ^ _e397) >> bitcast<u32>(8i))) * 0.00000037450704f);
            let _e416 = global.member.member_3[0u];
            let _e420 = global.member.member_3[1u];
            let _e423 = (((_e99 + 3041712726u) * 747796405u) + 2891336453u);
            let _e430 = (((_e423 >> bitcast<u32>(((_e423 >> bitcast<u32>(28u)) + 4u))) ^ _e423) * 277803737u);
            let _e439 = (((_e353 * _e383) + (((_e360 * cos(_e404)) + (cross(_e353, _e360) * sin(_e404))) * sqrt(max((1f - (_e383 * _e383)), 0f)))) * mix(_e416, _e420, (f32((((_e430 >> bitcast<u32>(22u)) ^ _e430) >> bitcast<u32>(8i))) * 0.000000059604645f)));
            let _e443 = global.member.member_4[3u];
            phi_1624_ = _e439;
            if (_e443 != 0f) {
                let _e446 = length(_e348.xz);
                if (_e446 > 0.0001f) {
                    phi_1617_ = (vec3<f32>(-(_e348.z), 0f, _e348.x) / vec3(_e446));
                } else {
                    phi_1617_ = vec3<f32>(0f, 0f, 0f);
                }
                let _e455 = phi_1617_;
                let _e459 = global.member.member_6[3u];
                if (_e459 > 0f) {
                    phi_1618_ = (sqrt(_e459) * _e446);
                } else {
                    phi_1618_ = 1f;
                }
                let _e464 = phi_1618_;
                phi_1624_ = (_e439 + ((_e455 * _e443) * _e464));
            }
            let _e469 = phi_1624_;
            let _e472 = global.member.member;
            let _e477 = (_e472 * vec4<f32>(_e348.x, _e348.y, _e348.z, 1f));
            let _e481 = vec4<f32>(_e477.x, _e477.y, _e477.z, 0f);
            let _e486 = (_e472 * vec4<f32>(_e469.x, _e469.y, _e469.z, 0f));
            let _e490 = global.member.member_3[2u];
            let _e494 = global.member.member_3[3u];
            let _e497 = (((_e99 + 1401181199u) * 747796405u) + 2891336453u);
            let _e504 = (((_e497 >> bitcast<u32>(((_e497 >> bitcast<u32>(28u)) + 4u))) ^ _e497) * 277803737u);
            let _e517 = vec4<f32>(_e486.x, _e486.y, _e486.z, max(mix(_e490, _e494, (f32((((_e504 >> bitcast<u32>(22u)) ^ _e504) >> bitcast<u32>(8i))) * 0.000000059604645f)), 0.001f));
            let _e521 = global.member.member_4[0u];
            let _e525 = global.member.member_4[1u];
            let _e528 = (((_e99 + 4055616968u) * 747796405u) + 2891336453u);
            let _e535 = (((_e528 >> bitcast<u32>(((_e528 >> bitcast<u32>(28u)) + 4u))) ^ _e528) * 277803737u);
            let _e546 = (((_e99 + 2415085441u) * 747796405u) + 2891336453u);
            let _e553 = (((_e546 >> bitcast<u32>(((_e546 >> bitcast<u32>(28u)) + 4u))) ^ _e546) * 277803737u);
            let _e563 = (((_e99 + 774553914u) * 747796405u) + 2891336453u);
            let _e570 = (((_e563 >> bitcast<u32>(((_e563 >> bitcast<u32>(28u)) + 4u))) ^ _e563) * 277803737u);
            let _e582 = global.member.member_4[2u];
            let _e586 = (((_e99 + 3428989683u) * 747796405u) + 2891336453u);
            let _e593 = (((_e586 >> bitcast<u32>(((_e586 >> bitcast<u32>(28u)) + 4u))) ^ _e586) * 277803737u);
            let _e602 = (2u * (_e59 / _e65));
            let _e605 = global_4.member[_e602];
            let _e608 = (_e481.xyz + _e605.xyz);
            let _e614 = vec4<f32>(_e608.x, _e481.y, _e481.z, _e481.w);
            let _e620 = vec4<f32>(_e614.x, _e608.y, _e614.z, _e614.w);
            let _e630 = global_4.member[(_e602 + 1u)];
            let _e633 = global_3.member_1;
            let _e636 = fma(_e630.xyz, vec3(_e633), _e517.xyz);
            let _e642 = vec4<f32>(_e636.x, _e517.y, _e517.z, _e517.w);
            let _e648 = vec4<f32>(_e642.x, _e636.y, _e642.z, _e642.w);
            let _e657 = global_2.member[4i];
            let _e662 = global.member.member_10[0u];
            let _e663 = ((_e657 + _e59) % _e662);
            global_5.member[_e663].member = vec4<f32>(_e620.x, _e620.y, _e608.z, _e620.w);
            global_5.member[_e663].member_1 = vec4<f32>(_e648.x, _e648.y, _e636.z, _e648.w);
            global_5.member[_e663].member_2 = vec4<f32>(mix(_e521, _e525, (f32((((_e535 >> bitcast<u32>(22u)) ^ _e535) >> bitcast<u32>(8i))) * 0.000000059604645f)), (f32((((_e553 >> bitcast<u32>(22u)) ^ _e553) >> bitcast<u32>(8i))) * 0.00000037450704f), (((f32((((_e570 >> bitcast<u32>(22u)) ^ _e570) >> bitcast<u32>(8i))) * 0.00000011920929f) - 1f) * _e582), (f32((((_e593 >> bitcast<u32>(22u)) ^ _e593) >> bitcast<u32>(8i))) * 0.000000059604645f));
            break;
        }
    }
    return;
}

@compute @workgroup_size(256, 1, 1) 
fn main(@builtin(global_invocation_id) param: vec3<u32>) {
    global_1 = param;
    function_();
}
