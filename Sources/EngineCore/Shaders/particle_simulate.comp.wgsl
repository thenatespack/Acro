// Generated from particle_simulate.comp by Scripts/compile-shaders.sh — do not edit.
// Edit the GLSL and rerun the script (needs glslc, spirv-cross, spirv-opt and naga-cli).
// spirv-fnv1a64: 7703e1905e9de69b
// glsl-fnv1a64: 5d5bb0d5847c61fe

diagnostic(off, derivative_uniformity);

struct type_10 {
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

struct type_11 {
    member: type_10,
}

struct type_25 {
    member: vec4<f32>,
    member_1: vec4<f32>,
    member_2: vec4<f32>,
}

struct type_27 {
    member: array<type_25>,
}

struct type_32 {
    member: array<u32>,
}

@group(2) @binding(2) 
var<uniform> global: type_11;
@group(2) @binding(9) 
var global_1: texture_2d<f32>;
@group(2) @binding(17) 
var global_2: sampler;
var<private> global_3: vec3<u32>;
var<private> global_4: u32;
var<workgroup> global_5: atomic<u32>;
var<workgroup> global_6: atomic<u32>;
var<workgroup> global_7: atomic<u32>;
var<workgroup> global_8: atomic<u32>;
@group(2) @binding(24) 
var<storage, read_write> global_9: type_27;
@group(2) @binding(27) 
var<storage, read_write> global_10: type_32;
@group(2) @binding(25) 
var<storage, read_write> global_11: type_32;
var<private> global_12: vec3<u32>;

fn function_() {
    var phi_4027_: f32;
    var phi_4026_: f32;
    var phi_4030_: vec3<f32>;
    var phi_4029_: vec3<f32>;
    var phi_4028_: vec3<f32>;
    var phi_4031_: vec3<f32>;
    var phi_4032_: f32;
    var phi_4038_: vec3<f32>;
    var phi_4159_: vec4<f32>;
    var phi_4053_: f32;
    var phi_4047_: vec4<f32>;
    var phi_4046_: vec4<f32>;
    var phi_4049_: vec3<f32>;
    var phi_4050_: vec3<f32>;
    var phi_1317_: bool;
    var phi_1323_: bool;
    var phi_4065_: vec3<f32>;
    var phi_4063_: vec3<f32>;
    var phi_4133_: bool;
    var phi_4064_: vec3<f32>;
    var phi_4062_: vec3<f32>;
    var phi_4061_: u32;
    var phi_2860_: bool;
    var phi_4268_: vec3<f32>;
    var phi_4272_: vec3<f32>;
    var phi_4270_: vec3<f32>;
    var phi_4269_: bool;
    var phi_4248_: vec3<f32>;
    var phi_2922_: bool;
    var phi_4260_: vec3<f32>;
    var phi_4264_: vec3<f32>;
    var phi_4262_: vec3<f32>;
    var phi_4261_: bool;
    var phi_2984_: bool;
    var phi_4253_: vec3<f32>;
    var phi_4257_: vec3<f32>;
    var phi_4255_: vec3<f32>;
    var phi_4254_: bool;
    var phi_4277_: vec3<f32>;
    var phi_4275_: vec3<f32>;
    var phi_4265_: bool;
    var phi_2739_: bool;
    var phi_2746_: bool;
    var phi_2761_: bool;
    var phi_3046_: bool;
    var phi_4243_: vec3<f32>;
    var phi_4247_: vec3<f32>;
    var phi_4245_: vec3<f32>;
    var phi_4244_: bool;
    var phi_3108_: bool;
    var phi_4236_: vec3<f32>;
    var phi_4240_: vec3<f32>;
    var phi_4238_: vec3<f32>;
    var phi_4237_: bool;
    var phi_3170_: bool;
    var phi_4229_: vec3<f32>;
    var phi_4233_: vec3<f32>;
    var phi_4231_: vec3<f32>;
    var phi_4230_: bool;
    var phi_3232_: bool;
    var phi_4196_: vec3<f32>;
    var phi_4200_: vec3<f32>;
    var phi_4198_: vec3<f32>;
    var phi_4197_: bool;
    var phi_3294_: bool;
    var phi_4203_: vec3<f32>;
    var phi_4207_: vec3<f32>;
    var phi_4205_: vec3<f32>;
    var phi_4204_: bool;
    var phi_3356_: bool;
    var phi_4213_: vec3<f32>;
    var phi_4217_: vec3<f32>;
    var phi_4215_: vec3<f32>;
    var phi_4214_: bool;
    var phi_4276_: vec3<f32>;
    var phi_4274_: vec3<f32>;
    var phi_4273_: bool;
    var local: vec3<f32>;
    var local_1: vec3<f32>;
    var local_2: vec3<f32>;
    var phi_3469_: bool;
    var phi_3478_: bool;
    var phi_3487_: bool;
    var phi_3518_: bool;
    var local_3: vec3<f32>;
    var phi_4077_: vec3<f32>;
    var local_4: vec3<f32>;
    var local_5: vec3<f32>;
    var local_6: vec3<f32>;
    var phi_4080_: vec3<f32>;
    var phi_4084_: vec3<f32>;
    var phi_4082_: vec3<f32>;
    var phi_4081_: bool;
    var phi_4153_: vec3<f32>;
    var phi_4149_: vec3<f32>;
    var phi_1391_: bool;
    var local_7: bool;
    var phi_1413_: bool;
    var phi_1415_: bool;
    var phi_4184_: bool;
    var phi_4182_: bool;
    var phi_4180_: vec4<f32>;
    var phi_4179_: vec4<f32>;
    var local_8: bool;
    var local_9: vec3<f32>;
    var local_10: vec3<f32>;
    var local_11: vec3<f32>;
    var local_12: vec3<f32>;
    var local_13: vec3<f32>;
    var local_14: vec3<f32>;
    var local_15: vec3<f32>;
    var local_16: vec3<f32>;
    var local_17: vec3<f32>;
    var local_18: vec3<f32>;
    var local_19: vec3<f32>;
    var local_20: vec3<f32>;
    var local_21: vec3<f32>;

    let _e91 = global_3[0u];
    let _e95 = global.member.member_10[0u];
    let _e96 = global_4;
    let _e97 = (_e96 == 0u);
    if _e97 {
        atomicStore((&global_5), 0u);
        atomicStore((&global_6), 0u);
        atomicStore((&global_7), 0u);
        atomicStore((&global_8), 0u);
    }
    workgroupBarrier();
    if (_e91 < _e95) {
        let _e102 = global_9.member[_e91].member;
        let _e104 = global_9.member[_e91].member_1;
        let _e106 = global_9.member[_e91].member_2;
        let _e110 = global.member.member_8[3u];
        let _e115 = global.member.member_9[0u];
        let _e117 = (((_e91 + _e95) - _e115) % _e95);
        let _e121 = global.member.member_9[1u];
        let _e122 = (_e117 < _e121);
        phi_4159_ = _e106;
        phi_4053_ = _e110;
        phi_4047_ = _e102;
        phi_4046_ = _e104;
        if _e122 {
            let _e126 = global.member.member_9[2u];
            let _e131 = global.member.member_9[3u];
            let _e133 = ((_e131 * 747796405u) + 2891336453u);
            let _e140 = (((_e133 >> bitcast<u32>(((_e133 >> bitcast<u32>(28u)) + 4u))) ^ _e133) * 277803737u);
            let _e146 = ((((_e126 + _e117) ^ ((_e140 >> bitcast<u32>(22u)) ^ _e140)) * 747796405u) + 2891336453u);
            let _e153 = (((_e146 >> bitcast<u32>(((_e146 >> bitcast<u32>(28u)) + 4u))) ^ _e146) * 277803737u);
            let _e156 = ((_e153 >> bitcast<u32>(22u)) ^ _e153);
            let _e159 = global.member.member_1;
            let _e164 = global.member.member_1[0u];
            let _e165 = u32(_e164);
            if (_e165 == 1u) {
                let _e168 = ((_e156 * 747796405u) + 2891336453u);
                let _e175 = (((_e168 >> bitcast<u32>(((_e168 >> bitcast<u32>(28u)) + 4u))) ^ _e168) * 277803737u);
                let _e183 = ((f32((((_e175 >> bitcast<u32>(22u)) ^ _e175) >> bitcast<u32>(8i))) * 0.00000011920929f) - 1f);
                let _e186 = (((_e156 + 2654435769u) * 747796405u) + 2891336453u);
                let _e193 = (((_e186 >> bitcast<u32>(((_e186 >> bitcast<u32>(28u)) + 4u))) ^ _e186) * 277803737u);
                let _e200 = (f32((((_e193 >> bitcast<u32>(22u)) ^ _e193) >> bitcast<u32>(8i))) * 0.00000037450704f);
                let _e208 = (vec2<f32>(cos(_e200), sin(_e200)) * sqrt(max((1f - (_e183 * _e183)), 0f)));
                let _e216 = (((_e156 + 1013904242u) * 747796405u) + 2891336453u);
                let _e223 = (((_e216 >> bitcast<u32>(((_e216 >> bitcast<u32>(28u)) + 4u))) ^ _e216) * 277803737u);
                phi_4028_ = ((vec3<f32>(_e208.x, _e208.y, _e183) * _e159.y) * pow((f32((((_e223 >> bitcast<u32>(22u)) ^ _e223) >> bitcast<u32>(8i))) * 0.000000059604645f), 0.33333334f));
            } else {
                if (_e165 == 2u) {
                    let _e235 = ((_e156 * 747796405u) + 2891336453u);
                    let _e242 = (((_e235 >> bitcast<u32>(((_e235 >> bitcast<u32>(28u)) + 4u))) ^ _e235) * 277803737u);
                    let _e252 = (((_e156 + 2654435769u) * 747796405u) + 2891336453u);
                    let _e259 = (((_e252 >> bitcast<u32>(((_e252 >> bitcast<u32>(28u)) + 4u))) ^ _e252) * 277803737u);
                    let _e269 = (((_e156 + 1013904242u) * 747796405u) + 2891336453u);
                    let _e276 = (((_e269 >> bitcast<u32>(((_e269 >> bitcast<u32>(28u)) + 4u))) ^ _e269) * 277803737u);
                    phi_4029_ = (((vec3<f32>((f32((((_e242 >> bitcast<u32>(22u)) ^ _e242) >> bitcast<u32>(8i))) * 0.000000059604645f), (f32((((_e259 >> bitcast<u32>(22u)) ^ _e259) >> bitcast<u32>(8i))) * 0.000000059604645f), (f32((((_e276 >> bitcast<u32>(22u)) ^ _e276) >> bitcast<u32>(8i))) * 0.000000059604645f)) * 2f) - vec3<f32>(1f, 1f, 1f)) * _e159.yzw);
                } else {
                    phi_4030_ = vec3<f32>(0f, 0f, 0f);
                    if (_e165 == 3u) {
                        let _e291 = ((_e156 * 747796405u) + 2891336453u);
                        let _e298 = (((_e291 >> bitcast<u32>(((_e291 >> bitcast<u32>(28u)) + 4u))) ^ _e291) * 277803737u);
                        let _e305 = (f32((((_e298 >> bitcast<u32>(22u)) ^ _e298) >> bitcast<u32>(8i))) * 0.000000059604645f);
                        let _e310 = (((_e156 + 2654435769u) * 747796405u) + 2891336453u);
                        let _e317 = (((_e310 >> bitcast<u32>(((_e310 >> bitcast<u32>(28u)) + 4u))) ^ _e310) * 277803737u);
                        let _e323 = f32((((_e317 >> bitcast<u32>(22u)) ^ _e317) >> bitcast<u32>(8i)));
                        let _e329 = global.member.member_8[0u];
                        phi_4027_ = (_e159.y * sqrt(_e305));
                        phi_4026_ = (_e323 * 0.00000037450704f);
                        if (_e329 > 0f) {
                            let _e331 = (_e159.y * _e305);
                            let _e339 = global.member.member_11[0u];
                            let _e344 = global.member.member_8[1u];
                            let _e349 = (((_e156 + 3668340011u) * 747796405u) + 2891336453u);
                            let _e356 = (((_e349 >> bitcast<u32>(((_e349 >> bitcast<u32>(28u)) + 4u))) ^ _e349) * 277803737u);
                            let _e368 = global.member.member_8[2u];
                            phi_4027_ = _e331;
                            phi_4026_ = (((((floor(((_e323 * 0.000000059604645f) * _e329)) * 6.2831855f) / _e329) + _e339) + (_e331 * _e344)) + (((f32((((_e356 >> bitcast<u32>(22u)) ^ _e356) >> bitcast<u32>(8i))) * 0.000000059604645f) - 0.5f) * _e368));
                        }
                        let _e372 = phi_4027_;
                        let _e374 = phi_4026_;
                        let _e379 = (((_e156 + 1013904242u) * 747796405u) + 2891336453u);
                        let _e386 = (((_e379 >> bitcast<u32>(((_e379 >> bitcast<u32>(28u)) + 4u))) ^ _e379) * 277803737u);
                        phi_4030_ = vec3<f32>((cos(_e374) * _e372), (((f32((((_e386 >> bitcast<u32>(22u)) ^ _e386) >> bitcast<u32>(8i))) * 0.000000059604645f) - 0.5f) * _e159.z), (sin(_e374) * _e372));
                    }
                    let _e401 = phi_4030_;
                    phi_4029_ = _e401;
                }
                let _e403 = phi_4029_;
                phi_4028_ = _e403;
            }
            let _e405 = phi_4028_;
            let _e408 = global.member.member_2;
            let _e410 = normalize(_e408.xyz);
            let _e417 = normalize(cross(select(vec3<f32>(1f, 0f, 0f), vec3<f32>(0f, 1f, 0f), vec3((abs(_e410.y) < 0.99f))), _e410));
            let _e422 = global.member.member_2[3u];
            let _e425 = (((_e156 + 2027808484u) * 747796405u) + 2891336453u);
            let _e432 = (((_e425 >> bitcast<u32>(((_e425 >> bitcast<u32>(28u)) + 4u))) ^ _e425) * 277803737u);
            let _e440 = mix(_e422, 1f, (f32((((_e432 >> bitcast<u32>(22u)) ^ _e432) >> bitcast<u32>(8i))) * 0.000000059604645f));
            let _e447 = (((_e156 + 387276957u) * 747796405u) + 2891336453u);
            let _e454 = (((_e447 >> bitcast<u32>(((_e447 >> bitcast<u32>(28u)) + 4u))) ^ _e447) * 277803737u);
            let _e461 = (f32((((_e454 >> bitcast<u32>(22u)) ^ _e454) >> bitcast<u32>(8i))) * 0.00000037450704f);
            let _e473 = global.member.member_3[0u];
            let _e477 = global.member.member_3[1u];
            let _e480 = (((_e156 + 3041712726u) * 747796405u) + 2891336453u);
            let _e487 = (((_e480 >> bitcast<u32>(((_e480 >> bitcast<u32>(28u)) + 4u))) ^ _e480) * 277803737u);
            let _e496 = (((_e410 * _e440) + (((_e417 * cos(_e461)) + (cross(_e410, _e417) * sin(_e461))) * sqrt(max((1f - (_e440 * _e440)), 0f)))) * mix(_e473, _e477, (f32((((_e487 >> bitcast<u32>(22u)) ^ _e487) >> bitcast<u32>(8i))) * 0.000000059604645f)));
            let _e500 = global.member.member_4[3u];
            phi_4038_ = _e496;
            if (_e500 != 0f) {
                let _e503 = length(_e405.xz);
                if (_e503 > 0.0001f) {
                    phi_4031_ = (vec3<f32>(-(_e405.z), 0f, _e405.x) / vec3(_e503));
                } else {
                    phi_4031_ = vec3<f32>(0f, 0f, 0f);
                }
                let _e512 = phi_4031_;
                let _e516 = global.member.member_6[3u];
                if (_e516 > 0f) {
                    phi_4032_ = (sqrt(_e516) * _e503);
                } else {
                    phi_4032_ = 1f;
                }
                let _e521 = phi_4032_;
                phi_4038_ = (_e496 + ((_e512 * _e500) * _e521));
            }
            let _e526 = phi_4038_;
            let _e529 = global.member.member;
            let _e534 = (_e529 * vec4<f32>(_e405.x, _e405.y, _e405.z, 1f));
            let _e543 = (_e529 * vec4<f32>(_e526.x, _e526.y, _e526.z, 0f));
            let _e547 = global.member.member_3[2u];
            let _e551 = global.member.member_3[3u];
            let _e554 = (((_e156 + 1401181199u) * 747796405u) + 2891336453u);
            let _e561 = (((_e554 >> bitcast<u32>(((_e554 >> bitcast<u32>(28u)) + 4u))) ^ _e554) * 277803737u);
            let _e578 = global.member.member_4[0u];
            let _e582 = global.member.member_4[1u];
            let _e585 = (((_e156 + 4055616968u) * 747796405u) + 2891336453u);
            let _e592 = (((_e585 >> bitcast<u32>(((_e585 >> bitcast<u32>(28u)) + 4u))) ^ _e585) * 277803737u);
            let _e603 = (((_e156 + 2415085441u) * 747796405u) + 2891336453u);
            let _e610 = (((_e603 >> bitcast<u32>(((_e603 >> bitcast<u32>(28u)) + 4u))) ^ _e603) * 277803737u);
            let _e620 = (((_e156 + 774553914u) * 747796405u) + 2891336453u);
            let _e627 = (((_e620 >> bitcast<u32>(((_e620 >> bitcast<u32>(28u)) + 4u))) ^ _e620) * 277803737u);
            let _e639 = global.member.member_4[2u];
            let _e643 = (((_e156 + 3428989683u) * 747796405u) + 2891336453u);
            let _e650 = (((_e643 >> bitcast<u32>(((_e643 >> bitcast<u32>(28u)) + 4u))) ^ _e643) * 277803737u);
            phi_4159_ = vec4<f32>(mix(_e578, _e582, (f32((((_e592 >> bitcast<u32>(22u)) ^ _e592) >> bitcast<u32>(8i))) * 0.000000059604645f)), (f32((((_e610 >> bitcast<u32>(22u)) ^ _e610) >> bitcast<u32>(8i))) * 0.00000037450704f), (((f32((((_e627 >> bitcast<u32>(22u)) ^ _e627) >> bitcast<u32>(8i))) * 0.00000011920929f) - 1f) * _e639), (f32((((_e650 >> bitcast<u32>(22u)) ^ _e650) >> bitcast<u32>(8i))) * 0.000000059604645f));
            phi_4053_ = (_e110 * ((f32((_e121 - _e117)) - 0.5f) / f32(_e121)));
            phi_4047_ = vec4<f32>(_e534.x, _e534.y, _e534.z, 0f);
            phi_4046_ = vec4<f32>(_e543.x, _e543.y, _e543.z, max(mix(_e547, _e551, (f32((((_e561 >> bitcast<u32>(22u)) ^ _e561) >> bitcast<u32>(8i))) * 0.000000059604645f)), 0.001f));
        }
        let _e666 = phi_4159_;
        let _e668 = phi_4053_;
        let _e670 = phi_4047_;
        let _e672 = phi_4046_;
        phi_4184_ = false;
        phi_4182_ = false;
        phi_4180_ = _e670;
        phi_4179_ = _e672;
        if (_e672.w > 0f) {
            let _e675 = _e670.xyz;
            let _e679 = global.member.member_5;
            let _e680 = _e679.xyz;
            let _e684 = global.member.member_6[0u];
            phi_4049_ = _e680;
            if (_e684 != 0f) {
                let _e689 = global.member.member_6[1u];
                let _e690 = (_e675 * _e689);
                let _e694 = global.member.member_6[2u];
                phi_4049_ = fma(vec3(_e684), vec3<f32>(sin((((_e690.y * 1.7f) + (_e690.z * 0.9f)) + _e694)), sin((((_e690.z * 1.3f) + (_e690.x * 1.1f)) + (_e694 * 1.21f))), sin((((_e690.x * 1.5f) + (_e690.y * 0.7f)) + (_e694 * 0.83f)))), _e680);
            }
            let _e719 = phi_4049_;
            let _e723 = global.member.member_6[3u];
            phi_4050_ = _e719;
            if (_e723 != 0f) {
                let _e728 = global.member.member[3];
                phi_4050_ = fma((_e728.xyz - _e675), vec3(_e723), _e719);
            }
            let _e734 = phi_4050_;
            let _e735 = vec3(_e668);
            let _e740 = global.member.member_5[3u];
            let _e743 = (fma(_e734, _e735, _e672.xyz) / vec3(fma(_e740, _e668, 1f)));
            let _e744 = fma(_e743, _e735, _e675);
            let _e748 = global.member.member_7[0u];
            let _e749 = (_e748 > 0f);
            phi_1317_ = _e749;
            if _e749 {
                let _e754 = global.member.member_7[1u];
                phi_1317_ = (_e744.y < _e754);
            }
            let _e757 = phi_1317_;
            phi_1323_ = _e757;
            if _e757 {
                phi_1323_ = (_e743.y < 0f);
            }
            let _e761 = phi_1323_;
            phi_4065_ = _e743;
            phi_4063_ = _e744;
            if _e761 {
                let _e765 = global.member.member_7[1u];
                let _e771 = global.member.member_7[2u];
                let _e783 = global.member.member_7[3u];
                let _e786 = (_e743.xz * (1f - _e783));
                phi_4065_ = vec3<f32>(_e786.x, (-(_e743.y) * _e771), _e786.y);
                phi_4063_ = vec3<f32>(_e744.x, fma((_e765 - _e744.y), _e771, _e765), _e744.z);
            }
            let _e791 = phi_4065_;
            let _e793 = phi_4063_;
            phi_4133_ = _e761;
            phi_4064_ = _e791;
            phi_4062_ = _e793;
            phi_4061_ = 0u;
            loop {
                let _e795 = phi_4133_;
                let _e797 = phi_4064_;
                let _e799 = phi_4062_;
                let _e801 = phi_4061_;
                let _e805 = global.member.member_12[1u];
                local = _e799;
                local_1 = _e799;
                local_2 = _e799;
                local_3 = _e799;
                local_4 = _e797;
                local_5 = _e799;
                local_6 = _e797;
                local_11 = _e797;
                local_12 = _e797;
                local_13 = _e797;
                local_14 = _e797;
                local_15 = _e797;
                local_16 = _e799;
                local_17 = _e799;
                local_18 = _e799;
                local_19 = _e799;
                local_20 = _e797;
                local_21 = _e799;
                local_7 = _e795;
                if (_e801 < _e805) {
                    switch bitcast<i32>(0u) {
                        default: {
                            let _e808 = (2u * _e801);
                            let _e812 = global.member.member_18[_e808];
                            let _e817 = global.member.member_18[(_e808 + 1u)];
                            let _e819 = u32(_e812.w);
                            let _e820 = (_e819 & 3u);
                            let _e821 = (_e819 >= 4u);
                            let _e823 = (_e799 - _e812.xyz);
                            if (_e820 == 0u) {
                                let _e825 = _e817.xyz;
                                let _e827 = -(dot(_e823, _e825));
                                switch bitcast<i32>(0u) {
                                    default: {
                                        let _e829 = (_e827 <= 0f);
                                        phi_2860_ = _e829;
                                        if !(_e829) {
                                            phi_2860_ = (dot(_e797, _e825) >= 0f);
                                        }
                                        let _e834 = phi_2860_;
                                        if _e834 {
                                            phi_4272_ = _e797;
                                            phi_4270_ = _e799;
                                            phi_4269_ = false;
                                            break;
                                        }
                                        let _e838 = global.member.member_7[2u];
                                        switch bitcast<i32>(0u) {
                                            default: {
                                                let _e844 = dot(_e797, _e825);
                                                if (_e844 >= 0f) {
                                                    phi_4268_ = _e797;
                                                    break;
                                                }
                                                let _e846 = (_e825 * _e844);
                                                let _e851 = global.member.member_7[3u];
                                                phi_4268_ = (((_e797 - _e846) * (1f - _e851)) - (_e846 * _e838));
                                                break;
                                            }
                                        }
                                        let _e857 = phi_4268_;
                                        phi_4272_ = _e857;
                                        phi_4270_ = fma(_e825, vec3((_e827 * (1f + _e838))), _e799);
                                        phi_4269_ = true;
                                        break;
                                    }
                                }
                                let _e859 = phi_4272_;
                                let _e861 = phi_4270_;
                                let _e863 = phi_4269_;
                                phi_4276_ = _e859;
                                phi_4274_ = _e861;
                                phi_4273_ = _e863;
                                break;
                            }
                            if (_e820 == 1u) {
                                let _e865 = length(_e823);
                                if (_e865 > 0.000001f) {
                                    phi_4248_ = (_e823 / vec3(_e865));
                                } else {
                                    phi_4248_ = vec3<f32>(0f, 1f, 0f);
                                }
                                let _e870 = phi_4248_;
                                if _e821 {
                                    let _e871 = -(_e870);
                                    let _e873 = (_e865 - _e817.x);
                                    switch bitcast<i32>(0u) {
                                        default: {
                                            let _e875 = (_e873 <= 0f);
                                            phi_2922_ = _e875;
                                            if !(_e875) {
                                                phi_2922_ = (dot(_e797, _e871) >= 0f);
                                            }
                                            let _e880 = phi_2922_;
                                            if _e880 {
                                                phi_4264_ = _e797;
                                                phi_4262_ = _e799;
                                                phi_4261_ = false;
                                                break;
                                            }
                                            let _e884 = global.member.member_7[2u];
                                            switch bitcast<i32>(0u) {
                                                default: {
                                                    let _e890 = dot(_e797, _e871);
                                                    if (_e890 >= 0f) {
                                                        phi_4260_ = _e797;
                                                        break;
                                                    }
                                                    let _e892 = (_e871 * _e890);
                                                    let _e897 = global.member.member_7[3u];
                                                    phi_4260_ = (((_e797 - _e892) * (1f - _e897)) - (_e892 * _e884));
                                                    break;
                                                }
                                            }
                                            let _e903 = phi_4260_;
                                            phi_4264_ = _e903;
                                            phi_4262_ = fma(_e871, vec3((_e873 * (1f + _e884))), _e799);
                                            phi_4261_ = true;
                                            break;
                                        }
                                    }
                                    let _e905 = phi_4264_;
                                    let _e907 = phi_4262_;
                                    let _e909 = phi_4261_;
                                    phi_4277_ = _e905;
                                    phi_4275_ = _e907;
                                    phi_4265_ = _e909;
                                } else {
                                    let _e911 = (_e817.x - _e865);
                                    switch bitcast<i32>(0u) {
                                        default: {
                                            let _e913 = (_e911 <= 0f);
                                            phi_2984_ = _e913;
                                            if !(_e913) {
                                                phi_2984_ = (dot(_e797, _e870) >= 0f);
                                            }
                                            let _e918 = phi_2984_;
                                            if _e918 {
                                                phi_4257_ = _e797;
                                                phi_4255_ = _e799;
                                                phi_4254_ = false;
                                                break;
                                            }
                                            let _e922 = global.member.member_7[2u];
                                            switch bitcast<i32>(0u) {
                                                default: {
                                                    let _e928 = dot(_e797, _e870);
                                                    if (_e928 >= 0f) {
                                                        phi_4253_ = _e797;
                                                        break;
                                                    }
                                                    let _e930 = (_e870 * _e928);
                                                    let _e935 = global.member.member_7[3u];
                                                    phi_4253_ = (((_e797 - _e930) * (1f - _e935)) - (_e930 * _e922));
                                                    break;
                                                }
                                            }
                                            let _e941 = phi_4253_;
                                            phi_4257_ = _e941;
                                            phi_4255_ = fma(_e870, vec3((_e911 * (1f + _e922))), _e799);
                                            phi_4254_ = true;
                                            break;
                                        }
                                    }
                                    let _e943 = phi_4257_;
                                    let _e945 = phi_4255_;
                                    let _e947 = phi_4254_;
                                    phi_4277_ = _e943;
                                    phi_4275_ = _e945;
                                    phi_4265_ = _e947;
                                }
                                let _e949 = phi_4277_;
                                let _e951 = phi_4275_;
                                let _e953 = phi_4265_;
                                phi_4276_ = _e949;
                                phi_4274_ = _e951;
                                phi_4273_ = _e953;
                                break;
                            }
                            let _e956 = (_e817.xyz - abs(_e823));
                            let _e959 = select(1f, -1f, (_e823.x < 0f));
                            let _e962 = select(1f, -1f, (_e823.y < 0f));
                            let _e965 = select(1f, -1f, (_e823.z < 0f));
                            if !(_e821) {
                                let _e968 = (_e956.x <= 0f);
                                let _e969 = !(_e968);
                                phi_2739_ = _e968;
                                if _e969 {
                                    phi_2739_ = (_e956.y <= 0f);
                                }
                                let _e973 = phi_2739_;
                                phi_2746_ = _e973;
                                if !(_e973) {
                                    phi_2746_ = (_e956.z <= 0f);
                                }
                                let _e978 = phi_2746_;
                                if _e978 {
                                    phi_4276_ = _e797;
                                    phi_4274_ = _e799;
                                    phi_4273_ = false;
                                    break;
                                }
                                let _e980 = (_e956.x <= _e956.y);
                                phi_2761_ = _e980;
                                if _e980 {
                                    phi_2761_ = (_e956.x <= _e956.z);
                                }
                                let _e984 = phi_2761_;
                                if _e984 {
                                    let _e985 = vec3<f32>(_e959, 0f, 0f);
                                    switch bitcast<i32>(0u) {
                                        default: {
                                            phi_3046_ = _e968;
                                            if _e969 {
                                                phi_3046_ = (dot(_e797, _e985) >= 0f);
                                            }
                                            let _e990 = phi_3046_;
                                            if _e990 {
                                                phi_4247_ = _e797;
                                                phi_4245_ = _e799;
                                                phi_4244_ = false;
                                                break;
                                            }
                                            let _e994 = global.member.member_7[2u];
                                            switch bitcast<i32>(0u) {
                                                default: {
                                                    let _e1000 = dot(_e797, _e985);
                                                    if (_e1000 >= 0f) {
                                                        phi_4243_ = _e797;
                                                        break;
                                                    }
                                                    let _e1002 = (_e985 * _e1000);
                                                    let _e1007 = global.member.member_7[3u];
                                                    phi_4243_ = (((_e797 - _e1002) * (1f - _e1007)) - (_e1002 * _e994));
                                                    break;
                                                }
                                            }
                                            let _e1013 = phi_4243_;
                                            phi_4247_ = _e1013;
                                            phi_4245_ = fma(_e985, vec3((_e956.x * (1f + _e994))), _e799);
                                            phi_4244_ = true;
                                            break;
                                        }
                                    }
                                    let _e1015 = phi_4247_;
                                    let _e1017 = phi_4245_;
                                    let _e1019 = phi_4244_;
                                    phi_4276_ = _e1015;
                                    phi_4274_ = _e1017;
                                    phi_4273_ = _e1019;
                                    break;
                                }
                                if (_e956.y <= _e956.z) {
                                    let _e1022 = vec3<f32>(0f, _e962, 0f);
                                    switch bitcast<i32>(0u) {
                                        default: {
                                            let _e1024 = (_e956.y <= 0f);
                                            phi_3108_ = _e1024;
                                            if !(_e1024) {
                                                phi_3108_ = (dot(_e797, _e1022) >= 0f);
                                            }
                                            let _e1029 = phi_3108_;
                                            if _e1029 {
                                                phi_4240_ = _e797;
                                                phi_4238_ = _e799;
                                                phi_4237_ = false;
                                                break;
                                            }
                                            let _e1033 = global.member.member_7[2u];
                                            switch bitcast<i32>(0u) {
                                                default: {
                                                    let _e1039 = dot(_e797, _e1022);
                                                    if (_e1039 >= 0f) {
                                                        phi_4236_ = _e797;
                                                        break;
                                                    }
                                                    let _e1041 = (_e1022 * _e1039);
                                                    let _e1046 = global.member.member_7[3u];
                                                    phi_4236_ = (((_e797 - _e1041) * (1f - _e1046)) - (_e1041 * _e1033));
                                                    break;
                                                }
                                            }
                                            let _e1052 = phi_4236_;
                                            phi_4240_ = _e1052;
                                            phi_4238_ = fma(_e1022, vec3((_e956.y * (1f + _e1033))), _e799);
                                            phi_4237_ = true;
                                            break;
                                        }
                                    }
                                    let _e1054 = phi_4240_;
                                    let _e1056 = phi_4238_;
                                    let _e1058 = phi_4237_;
                                    phi_4276_ = _e1054;
                                    phi_4274_ = _e1056;
                                    phi_4273_ = _e1058;
                                    break;
                                }
                                let _e1059 = vec3<f32>(0f, 0f, _e965);
                                switch bitcast<i32>(0u) {
                                    default: {
                                        let _e1061 = (_e956.z <= 0f);
                                        phi_3170_ = _e1061;
                                        if !(_e1061) {
                                            phi_3170_ = (dot(_e797, _e1059) >= 0f);
                                        }
                                        let _e1066 = phi_3170_;
                                        if _e1066 {
                                            phi_4233_ = _e797;
                                            phi_4231_ = _e799;
                                            phi_4230_ = false;
                                            break;
                                        }
                                        let _e1070 = global.member.member_7[2u];
                                        switch bitcast<i32>(0u) {
                                            default: {
                                                let _e1076 = dot(_e797, _e1059);
                                                if (_e1076 >= 0f) {
                                                    phi_4229_ = _e797;
                                                    break;
                                                }
                                                let _e1078 = (_e1059 * _e1076);
                                                let _e1083 = global.member.member_7[3u];
                                                phi_4229_ = (((_e797 - _e1078) * (1f - _e1083)) - (_e1078 * _e1070));
                                                break;
                                            }
                                        }
                                        let _e1089 = phi_4229_;
                                        phi_4233_ = _e1089;
                                        phi_4231_ = fma(_e1059, vec3((_e956.z * (1f + _e1070))), _e799);
                                        phi_4230_ = true;
                                        break;
                                    }
                                }
                                let _e1091 = phi_4233_;
                                let _e1093 = phi_4231_;
                                let _e1095 = phi_4230_;
                                phi_4276_ = _e1091;
                                phi_4274_ = _e1093;
                                phi_4273_ = _e1095;
                                break;
                            }
                            let _e1097 = vec3<f32>(-(_e959), 0f, 0f);
                            let _e1099 = -(_e956.x);
                            switch bitcast<i32>(0u) {
                                default: {
                                    let _e1101 = (_e1099 <= 0f);
                                    phi_3232_ = _e1101;
                                    if !(_e1101) {
                                        phi_3232_ = (dot(_e797, _e1097) >= 0f);
                                    }
                                    let _e1106 = phi_3232_;
                                    if _e1106 {
                                        phi_4200_ = _e797;
                                        phi_4198_ = _e799;
                                        phi_4197_ = false;
                                        break;
                                    }
                                    let _e1110 = global.member.member_7[2u];
                                    switch bitcast<i32>(0u) {
                                        default: {
                                            let _e1116 = dot(_e797, _e1097);
                                            if (_e1116 >= 0f) {
                                                phi_4196_ = _e797;
                                                break;
                                            }
                                            let _e1118 = (_e1097 * _e1116);
                                            let _e1123 = global.member.member_7[3u];
                                            phi_4196_ = (((_e797 - _e1118) * (1f - _e1123)) - (_e1118 * _e1110));
                                            break;
                                        }
                                    }
                                    let _e1129 = phi_4196_;
                                    phi_4200_ = _e1129;
                                    phi_4198_ = fma(_e1097, vec3((_e1099 * (1f + _e1110))), _e799);
                                    phi_4197_ = true;
                                    break;
                                }
                            }
                            let _e1131 = phi_4200_;
                            let _e1133 = phi_4198_;
                            let _e1135 = phi_4197_;
                            let _e1137 = vec3<f32>(0f, -(_e962), 0f);
                            let _e1139 = -(_e956.y);
                            switch bitcast<i32>(0u) {
                                default: {
                                    let _e1141 = (_e1139 <= 0f);
                                    phi_3294_ = _e1141;
                                    if !(_e1141) {
                                        phi_3294_ = (dot(_e1131, _e1137) >= 0f);
                                    }
                                    let _e1146 = phi_3294_;
                                    if _e1146 {
                                        phi_4207_ = _e1131;
                                        phi_4205_ = _e1133;
                                        phi_4204_ = false;
                                        break;
                                    }
                                    let _e1150 = global.member.member_7[2u];
                                    switch bitcast<i32>(0u) {
                                        default: {
                                            let _e1156 = dot(_e1131, _e1137);
                                            if (_e1156 >= 0f) {
                                                phi_4203_ = _e1131;
                                                break;
                                            }
                                            let _e1158 = (_e1137 * _e1156);
                                            let _e1163 = global.member.member_7[3u];
                                            phi_4203_ = (((_e1131 - _e1158) * (1f - _e1163)) - (_e1158 * _e1150));
                                            break;
                                        }
                                    }
                                    let _e1169 = phi_4203_;
                                    phi_4207_ = _e1169;
                                    phi_4205_ = fma(_e1137, vec3((_e1139 * (1f + _e1150))), _e1133);
                                    phi_4204_ = true;
                                    break;
                                }
                            }
                            let _e1171 = phi_4207_;
                            let _e1173 = phi_4205_;
                            let _e1175 = phi_4204_;
                            let _e1178 = vec3<f32>(0f, 0f, -(_e965));
                            let _e1180 = -(_e956.z);
                            switch bitcast<i32>(0u) {
                                default: {
                                    let _e1182 = (_e1180 <= 0f);
                                    phi_3356_ = _e1182;
                                    if !(_e1182) {
                                        phi_3356_ = (dot(_e1171, _e1178) >= 0f);
                                    }
                                    let _e1187 = phi_3356_;
                                    if _e1187 {
                                        phi_4217_ = _e1171;
                                        phi_4215_ = _e1173;
                                        phi_4214_ = false;
                                        break;
                                    }
                                    let _e1191 = global.member.member_7[2u];
                                    switch bitcast<i32>(0u) {
                                        default: {
                                            let _e1197 = dot(_e1171, _e1178);
                                            if (_e1197 >= 0f) {
                                                phi_4213_ = _e1171;
                                                break;
                                            }
                                            let _e1199 = (_e1178 * _e1197);
                                            let _e1204 = global.member.member_7[3u];
                                            phi_4213_ = (((_e1171 - _e1199) * (1f - _e1204)) - (_e1199 * _e1191));
                                            break;
                                        }
                                    }
                                    let _e1210 = phi_4213_;
                                    phi_4217_ = _e1210;
                                    phi_4215_ = fma(_e1178, vec3((_e1180 * (1f + _e1191))), _e1173);
                                    phi_4214_ = true;
                                    break;
                                }
                            }
                            let _e1212 = phi_4217_;
                            let _e1214 = phi_4215_;
                            let _e1216 = phi_4214_;
                            phi_4276_ = _e1212;
                            phi_4274_ = _e1214;
                            phi_4273_ = (_e1216 || (_e1175 || _e1135));
                            break;
                        }
                    }
                    let _e1219 = phi_4276_;
                    let _e1221 = phi_4274_;
                    let _e1223 = phi_4273_;
                    local_8 = select(_e795, true, _e1223);
                    local_9 = _e1219;
                    local_10 = _e1221;
                    continue;
                } else {
                    break;
                }
                continuing {
                    let _e1599 = local_8;
                    phi_4133_ = _e1599;
                    let _e1602 = local_9;
                    phi_4064_ = _e1602;
                    let _e1605 = local_10;
                    phi_4062_ = _e1605;
                    phi_4061_ = (_e801 + bitcast<u32>(1i));
                }
            }
            let _e1230 = global.member.member_12[0u];
            let _e1232 = ((_e1230 & 1u) != 0u);
            let _e1698 = local_20;
            phi_4153_ = _e1698;
            let _e1701 = local_21;
            phi_4149_ = _e1701;
            phi_1391_ = _e1232;
            if _e1232 {
                switch bitcast<i32>(0u) {
                    default: {
                        let _e1236 = global.member.member_16;
                        let _e1238 = local;
                        let _e1241 = local_1;
                        let _e1244 = local_2;
                        let _e1247 = (_e1236 * vec4<f32>(_e1238.x, _e1241.y, _e1244.z, 1f));
                        if (_e1247.w <= 0f) {
                            let _e1679 = local_12;
                            phi_4084_ = _e1679;
                            let _e1688 = local_16;
                            phi_4082_ = _e1688;
                            phi_4081_ = false;
                            break;
                        }
                        let _e1252 = global.member.member_13;
                        let _e1253 = _e1252.yz;
                        let _e1263 = (vec2<f32>((((_e1247.x / _e1247.w) * 0.5f) + 0.5f), (0.5f - ((_e1247.y / _e1247.w) * 0.5f))) * _e1253);
                        let _e1265 = (_e1263.x < 0f);
                        phi_3469_ = _e1265;
                        if !(_e1265) {
                            phi_3469_ = (_e1263.y < 0f);
                        }
                        let _e1270 = phi_3469_;
                        phi_3478_ = _e1270;
                        if !(_e1270) {
                            phi_3478_ = (_e1263.x >= _e1252.y);
                        }
                        let _e1275 = phi_3478_;
                        phi_3487_ = _e1275;
                        if !(_e1275) {
                            phi_3487_ = (_e1263.y >= _e1252.z);
                        }
                        let _e1281 = phi_3487_;
                        if _e1281 {
                            let _e1681 = local_13;
                            phi_4084_ = _e1681;
                            let _e1690 = local_17;
                            phi_4082_ = _e1690;
                            phi_4081_ = false;
                            break;
                        }
                        let _e1282 = vec2<i32>(_e1263);
                        let _e1283 = textureLoad(global_1, _e1282, 0i);
                        let _e1288 = global.member.member_14[0u];
                        let _e1292 = global.member.member_14[1u];
                        let _e1295 = (_e1247.w - (_e1288 / (_e1283.x + _e1292)));
                        let _e1296 = (_e1295 <= 0f);
                        phi_3518_ = _e1296;
                        if !(_e1296) {
                            let _e1301 = global.member.member_13[0u];
                            phi_3518_ = (_e1295 >= _e1301);
                        }
                        let _e1304 = phi_3518_;
                        if _e1304 {
                            let _e1683 = local_14;
                            phi_4084_ = _e1683;
                            let _e1692 = local_18;
                            phi_4082_ = _e1692;
                            phi_4081_ = false;
                            break;
                        }
                        let _e1306 = (vec2<i32>(_e1253) - vec2<i32>(1i, 1i));
                        let _e1307 = clamp(_e1282, vec2<i32>(0i, 0i), _e1306);
                        let _e1308 = textureLoad(global_1, _e1307, 0i);
                        let _e1326 = global.member.member_17;
                        let _e1328 = (_e1326 * vec4<f32>(((((f32(_e1307.x) + 0.5f) / _e1252.y) * 2f) - 1f), (1f - (((f32(_e1307.y) + 0.5f) / _e1252.z) * 2f)), _e1308.x, 1f));
                        let _e1332 = (_e1328.xyz / vec3(_e1328.w));
                        let _e1334 = clamp((_e1282 + vec2<i32>(1i, 0i)), vec2<i32>(0i, 0i), _e1306);
                        let _e1335 = textureLoad(global_1, _e1334, 0i);
                        let _e1350 = (_e1326 * vec4<f32>(((((f32(_e1334.x) + 0.5f) / _e1252.y) * 2f) - 1f), (1f - (((f32(_e1334.y) + 0.5f) / _e1252.z) * 2f)), _e1335.x, 1f));
                        let _e1355 = ((_e1350.xyz / vec3(_e1350.w)) - _e1332);
                        let _e1357 = clamp((_e1282 - vec2<i32>(1i, 0i)), vec2<i32>(0i, 0i), _e1306);
                        let _e1358 = textureLoad(global_1, _e1357, 0i);
                        let _e1373 = (_e1326 * vec4<f32>(((((f32(_e1357.x) + 0.5f) / _e1252.y) * 2f) - 1f), (1f - (((f32(_e1357.y) + 0.5f) / _e1252.z) * 2f)), _e1358.x, 1f));
                        let _e1378 = (_e1332 - (_e1373.xyz / vec3(_e1373.w)));
                        let _e1380 = clamp((_e1282 + vec2<i32>(0i, 1i)), vec2<i32>(0i, 0i), _e1306);
                        let _e1381 = textureLoad(global_1, _e1380, 0i);
                        let _e1396 = (_e1326 * vec4<f32>(((((f32(_e1380.x) + 0.5f) / _e1252.y) * 2f) - 1f), (1f - (((f32(_e1380.y) + 0.5f) / _e1252.z) * 2f)), _e1381.x, 1f));
                        let _e1401 = ((_e1396.xyz / vec3(_e1396.w)) - _e1332);
                        let _e1403 = clamp((_e1282 - vec2<i32>(0i, 1i)), vec2<i32>(0i, 0i), _e1306);
                        let _e1404 = textureLoad(global_1, _e1403, 0i);
                        let _e1419 = (_e1326 * vec4<f32>(((((f32(_e1403.x) + 0.5f) / _e1252.y) * 2f) - 1f), (1f - (((f32(_e1403.y) + 0.5f) / _e1252.z) * 2f)), _e1404.x, 1f));
                        let _e1424 = (_e1332 - (_e1419.xyz / vec3(_e1419.w)));
                        let _e1435 = cross(select(_e1378, _e1355, vec3((dot(_e1355, _e1355) < dot(_e1378, _e1378)))), select(_e1424, _e1401, vec3((dot(_e1401, _e1401) < dot(_e1424, _e1424)))));
                        let _e1438 = global.member.member_15;
                        let _e1441 = local_3;
                        let _e1442 = (_e1438.xyz - _e1441);
                        let _e1447 = normalize(select(_e1435, _e1442, vec3((dot(_e1435, _e1435) < 0.00000000000000000001f))));
                        phi_4077_ = _e1447;
                        if (dot(_e1447, _e1442) < 0f) {
                            phi_4077_ = -(_e1447);
                        }
                        let _e1452 = phi_4077_;
                        let _e1454 = local_4;
                        let _e1455 = dot(_e1454, _e1452);
                        let _e1456 = (_e1455 >= 0f);
                        if _e1456 {
                            let _e1685 = local_15;
                            phi_4084_ = _e1685;
                            let _e1694 = local_19;
                            phi_4082_ = _e1694;
                            phi_4081_ = false;
                            break;
                        }
                        let _e1460 = local_5;
                        switch bitcast<i32>(0u) {
                            default: {
                                if _e1456 {
                                    let _e1676 = local_11;
                                    phi_4080_ = _e1676;
                                    break;
                                }
                                let _e1463 = (_e1452 * _e1455);
                                let _e1465 = local_6;
                                let _e1470 = global.member.member_7[3u];
                                let _e1476 = global.member.member_7[2u];
                                phi_4080_ = (((_e1465 - _e1463) * (1f - _e1470)) - (_e1463 * _e1476));
                                break;
                            }
                        }
                        let _e1480 = phi_4080_;
                        phi_4084_ = _e1480;
                        phi_4082_ = fma(normalize(_e1442), vec3(_e1295), _e1460);
                        phi_4081_ = true;
                        break;
                    }
                }
                let _e1482 = phi_4084_;
                let _e1484 = phi_4082_;
                let _e1486 = phi_4081_;
                phi_4153_ = _e1482;
                phi_4149_ = _e1484;
                phi_1391_ = _e1486;
            }
            let _e1488 = phi_4153_;
            let _e1490 = phi_4149_;
            let _e1492 = phi_1391_;
            let _e1494 = local_7;
            let _e1495 = select(_e1494, true, _e1492);
            let _e1497 = (_e670.w + _e668);
            let _e1498 = (_e1497 < _e672.w);
            phi_1415_ = _e1498;
            if _e1498 {
                phi_1413_ = _e1495;
                if _e1495 {
                    phi_1413_ = ((_e1230 & 2u) != 0u);
                }
                let _e1502 = phi_1413_;
                phi_1415_ = !(_e1502);
            }
            let _e1505 = phi_1415_;
            phi_4184_ = _e1495;
            phi_4182_ = !(_e1505);
            phi_4180_ = vec4<f32>(_e1490.x, _e1490.y, _e1490.z, _e1497);
            phi_4179_ = vec4<f32>(_e1488.x, _e1488.y, _e1488.z, select(0f, _e672.w, _e1505));
        }
        let _e1517 = phi_4184_;
        let _e1519 = phi_4182_;
        let _e1521 = phi_4180_;
        let _e1523 = phi_4179_;
        global_9.member[_e91].member = _e1521;
        global_9.member[_e91].member_1 = _e1523;
        global_9.member[_e91].member_2 = _e666;
        let _e1536 = global.member.member_12[0u];
        if ((_e1536 & 4u) != 0u) {
            global_10.member[_e91] = ((select(0u, 1u, _e1519) | select(0u, 2u, _e1517)) | select(0u, 4u, _e122));
        }
        if (_e1523.w > 0f) {
            let _e1548 = atomicAdd((&global_5), 1u);
        }
        if _e1519 {
            let _e1549 = atomicAdd((&global_6), 1u);
        }
        if _e1517 {
            let _e1550 = atomicAdd((&global_7), 1u);
        }
        if _e122 {
            let _e1551 = atomicAdd((&global_8), 1u);
        }
    }
    workgroupBarrier();
    if _e97 {
        let _e1555 = global.member.member_10[1u];
        let _e1557 = global_12[0u];
        let _e1559 = atomicLoad((&global_5));
        global_11.member[(4u + _e1557)] = _e1559;
        let _e1564 = atomicLoad((&global_6));
        global_11.member[((4u + _e1555) + _e1557)] = _e1564;
        let _e1570 = atomicLoad((&global_7));
        global_11.member[((4u + (2u * _e1555)) + _e1557)] = _e1570;
        let _e1576 = atomicLoad((&global_8));
        global_11.member[((4u + (3u * _e1555)) + _e1557)] = _e1576;
    }
    return;
}

@compute @workgroup_size(256, 1, 1) 
fn main(@builtin(global_invocation_id) param: vec3<u32>, @builtin(local_invocation_index) param_1: u32, @builtin(workgroup_id) param_2: vec3<u32>) {
    global_3 = param;
    global_4 = param_1;
    global_12 = param_2;
    function_();
}
