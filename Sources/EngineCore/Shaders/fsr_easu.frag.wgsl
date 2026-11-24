// Generated from fsr_easu.frag by Scripts/compile-shaders.sh — do not edit.
// Edit the GLSL and rerun the script (needs glslc, spirv-cross, spirv-opt and naga-cli).
// spirv-fnv1a64: b2217e23cd67f5c6
// glsl-fnv1a64: f4f79e5faaec3c70

diagnostic(off, derivative_uniformity);

struct type_8 {
    member: vec2<f32>,
    member_1: vec2<i32>,
}

@group(1) @binding(1) 
var global: sampler;
@group(1) @binding(0) 
var global_1: texture_2d<f32>;
@group(3) @binding(0) 
var<uniform> global_2: type_8;
var<private> global_3: vec4<f32>;
var<private> global_4: vec4<f32>;

fn function_() {
    var phi_2686_: f32;

    let _e47 = global_3;
    let _e50 = global_2.member;
    let _e52 = ((_e47.xy * _e50) - vec2<f32>(0.5f, 0.5f));
    let _e53 = floor(_e52);
    let _e54 = (_e52 - _e53);
    let _e55 = vec2<i32>(_e53);
    let _e58 = global_2.member_1;
    let _e60 = textureLoad(global_1, clamp((_e55 + vec2<i32>(0i, -1i)), vec2<i32>(0i, 0i), _e58), 0i);
    let _e64 = textureLoad(global_1, clamp((_e55 + vec2<i32>(1i, -1i)), vec2<i32>(0i, 0i), _e58), 0i);
    let _e68 = textureLoad(global_1, clamp((_e55 + vec2<i32>(-1i, 0i)), vec2<i32>(0i, 0i), _e58), 0i);
    let _e71 = textureLoad(global_1, clamp(_e55, vec2<i32>(0i, 0i), _e58), 0i);
    let _e72 = _e71.xyz;
    let _e75 = textureLoad(global_1, clamp((_e55 + vec2<i32>(1i, 0i)), vec2<i32>(0i, 0i), _e58), 0i);
    let _e76 = _e75.xyz;
    let _e79 = textureLoad(global_1, clamp((_e55 + vec2<i32>(2i, 0i)), vec2<i32>(0i, 0i), _e58), 0i);
    let _e83 = textureLoad(global_1, clamp((_e55 + vec2<i32>(-1i, 1i)), vec2<i32>(0i, 0i), _e58), 0i);
    let _e87 = textureLoad(global_1, clamp((_e55 + vec2<i32>(0i, 1i)), vec2<i32>(0i, 0i), _e58), 0i);
    let _e88 = _e87.xyz;
    let _e91 = textureLoad(global_1, clamp((_e55 + vec2<i32>(1i, 1i)), vec2<i32>(0i, 0i), _e58), 0i);
    let _e92 = _e91.xyz;
    let _e95 = textureLoad(global_1, clamp((_e55 + vec2<i32>(2i, 1i)), vec2<i32>(0i, 0i), _e58), 0i);
    let _e99 = textureLoad(global_1, clamp((_e55 + vec2<i32>(0i, 2i)), vec2<i32>(0i, 0i), _e58), 0i);
    let _e103 = textureLoad(global_1, clamp((_e55 + vec2<i32>(1i, 2i)), vec2<i32>(0i, 0i), _e58), 0i);
    let _e111 = ((_e60.z * 0.5f) + ((_e60.x * 0.5f) + _e60.y));
    let _e118 = ((_e64.z * 0.5f) + ((_e64.x * 0.5f) + _e64.y));
    let _e125 = ((_e68.z * 0.5f) + ((_e68.x * 0.5f) + _e68.y));
    let _e132 = ((_e71.z * 0.5f) + ((_e71.x * 0.5f) + _e71.y));
    let _e139 = ((_e75.z * 0.5f) + ((_e75.x * 0.5f) + _e75.y));
    let _e146 = ((_e79.z * 0.5f) + ((_e79.x * 0.5f) + _e79.y));
    let _e153 = ((_e83.z * 0.5f) + ((_e83.x * 0.5f) + _e83.y));
    let _e160 = ((_e87.z * 0.5f) + ((_e87.x * 0.5f) + _e87.y));
    let _e167 = ((_e91.z * 0.5f) + ((_e91.x * 0.5f) + _e91.y));
    let _e174 = ((_e95.z * 0.5f) + ((_e95.x * 0.5f) + _e95.y));
    let _e181 = ((_e99.z * 0.5f) + ((_e99.x * 0.5f) + _e99.y));
    let _e188 = ((_e103.z * 0.5f) + ((_e103.x * 0.5f) + _e103.y));
    let _e190 = (1f - _e54.x);
    let _e192 = (1f - _e54.y);
    let _e193 = (_e190 * _e192);
    let _e196 = abs((_e139 - _e132));
    let _e202 = (_e139 - _e125);
    let _e206 = clamp((abs(_e202) * bitcast<f32>((2129690299u - bitcast<u32>(max(_e196, abs((_e132 - _e125))))))), 0f, 1f);
    let _e210 = abs((_e160 - _e132));
    let _e216 = (_e160 - _e111);
    let _e220 = clamp((abs(_e216) * bitcast<f32>((2129690299u - bitcast<u32>(max(_e210, abs((_e132 - _e111))))))), 0f, 1f);
    let _e224 = (_e54.x * _e192);
    let _e231 = (_e146 - _e132);
    let _e236 = clamp((abs(_e231) * bitcast<f32>((2129690299u - bitcast<u32>(max(abs((_e146 - _e139)), _e196))))), 0f, 1f);
    let _e242 = abs((_e167 - _e139));
    let _e248 = (_e167 - _e118);
    let _e253 = clamp((abs(_e248) * bitcast<f32>((2129690299u - bitcast<u32>(max(_e242, abs((_e139 - _e118))))))), 0f, 1f);
    let _e257 = (_e190 * _e54.y);
    let _e260 = abs((_e167 - _e160));
    let _e266 = (_e167 - _e153);
    let _e271 = clamp((abs(_e266) * bitcast<f32>((2129690299u - bitcast<u32>(max(_e260, abs((_e160 - _e153))))))), 0f, 1f);
    let _e281 = (_e181 - _e132);
    let _e286 = clamp((abs(_e281) * bitcast<f32>((2129690299u - bitcast<u32>(max(abs((_e181 - _e160)), _e210))))), 0f, 1f);
    let _e290 = (_e54.x * _e54.y);
    let _e297 = (_e174 - _e160);
    let _e299 = ((((_e202 * _e193) + (_e231 * _e224)) + (_e266 * _e257)) + (_e297 * _e290));
    let _e302 = clamp((abs(_e297) * bitcast<f32>((2129690299u - bitcast<u32>(max(abs((_e174 - _e167)), _e260))))), 0f, 1f);
    let _e312 = (_e188 - _e139);
    let _e315 = vec2<f32>(_e299, ((((_e216 * _e193) + (_e248 * _e224)) + (_e281 * _e257)) + (_e312 * _e290)));
    let _e318 = clamp((abs(_e312) * bitcast<f32>((2129690299u - bitcast<u32>(max(abs((_e188 - _e167)), _e242))))), 0f, 1f);
    let _e321 = (((((((_e193 * ((_e206 * _e206) + (_e220 * _e220))) + ((_e236 * _e236) * _e224)) + ((_e253 * _e253) * _e224)) + ((_e271 * _e271) * _e257)) + ((_e286 * _e286) * _e257)) + ((_e302 * _e302) * _e290)) + ((_e318 * _e318) * _e290));
    let _e322 = (_e315 * _e315);
    let _e325 = (_e322.x + _e322.y);
    let _e326 = (_e325 < 0.000030517578f);
    if _e326 {
        phi_2686_ = 1f;
    } else {
        phi_2686_ = bitcast<f32>((1597275508u - (bitcast<u32>(_e325) >> bitcast<u32>(1i))));
    }
    let _e333 = phi_2686_;
    let _e338 = (vec2<f32>(select(_e299, 1f, _e326), _e315.y) * _e333);
    let _e339 = (_e321 * _e321);
    let _e358 = vec2<f32>((1f + (((((_e338.x * _e338.x) + (_e338.y * _e338.y)) * bitcast<f32>((2129690299u - bitcast<u32>(max(abs(_e338.x), abs(_e338.y)))))) - 1f) * (0.25f * _e339))), (1f - (_e339 * 0.125f)));
    let _e360 = (0.5f + (_e339 * -0.0725f));
    let _e363 = bitcast<f32>((2129690299u - bitcast<u32>(_e360)));
    let _e364 = (vec2<f32>(0f, -1f) - _e54);
    let _e370 = -(_e338.y);
    let _e375 = (vec2<f32>(((_e364.x * _e338.x) + (_e364.y * _e338.y)), ((_e364.x * _e370) + (_e364.y * _e338.x))) * _e358);
    let _e381 = min(((_e375.x * _e375.x) + (_e375.y * _e375.y)), _e363);
    let _e383 = ((0.4f * _e381) - 1f);
    let _e385 = ((_e360 * _e381) - 1f);
    let _e390 = (((1.5625f * (_e383 * _e383)) - 0.5625f) * (_e385 * _e385));
    let _e392 = (vec2<f32>(1f, -1f) - _e54);
    let _e402 = (vec2<f32>(((_e392.x * _e338.x) + (_e392.y * _e338.y)), ((_e392.x * _e370) + (_e392.y * _e338.x))) * _e358);
    let _e408 = min(((_e402.x * _e402.x) + (_e402.y * _e402.y)), _e363);
    let _e410 = ((0.4f * _e408) - 1f);
    let _e412 = ((_e360 * _e408) - 1f);
    let _e417 = (((1.5625f * (_e410 * _e410)) - 0.5625f) * (_e412 * _e412));
    let _e421 = (vec2<f32>(-1f, 1f) - _e54);
    let _e431 = (vec2<f32>(((_e421.x * _e338.x) + (_e421.y * _e338.y)), ((_e421.x * _e370) + (_e421.y * _e338.x))) * _e358);
    let _e437 = min(((_e431.x * _e431.x) + (_e431.y * _e431.y)), _e363);
    let _e439 = ((0.4f * _e437) - 1f);
    let _e441 = ((_e360 * _e437) - 1f);
    let _e446 = (((1.5625f * (_e439 * _e439)) - 0.5625f) * (_e441 * _e441));
    let _e450 = (vec2<f32>(0f, 1f) - _e54);
    let _e460 = (vec2<f32>(((_e450.x * _e338.x) + (_e450.y * _e338.y)), ((_e450.x * _e370) + (_e450.y * _e338.x))) * _e358);
    let _e466 = min(((_e460.x * _e460.x) + (_e460.y * _e460.y)), _e363);
    let _e468 = ((0.4f * _e466) - 1f);
    let _e470 = ((_e360 * _e466) - 1f);
    let _e475 = (((1.5625f * (_e468 * _e468)) - 0.5625f) * (_e470 * _e470));
    let _e479 = -(_e54);
    let _e489 = (vec2<f32>(((_e479.x * _e338.x) + (_e479.y * _e338.y)), ((_e479.x * _e370) + (_e479.y * _e338.x))) * _e358);
    let _e495 = min(((_e489.x * _e489.x) + (_e489.y * _e489.y)), _e363);
    let _e497 = ((0.4f * _e495) - 1f);
    let _e499 = ((_e360 * _e495) - 1f);
    let _e504 = (((1.5625f * (_e497 * _e497)) - 0.5625f) * (_e499 * _e499));
    let _e508 = (vec2<f32>(-1f, 0f) - _e54);
    let _e518 = (vec2<f32>(((_e508.x * _e338.x) + (_e508.y * _e338.y)), ((_e508.x * _e370) + (_e508.y * _e338.x))) * _e358);
    let _e524 = min(((_e518.x * _e518.x) + (_e518.y * _e518.y)), _e363);
    let _e526 = ((0.4f * _e524) - 1f);
    let _e528 = ((_e360 * _e524) - 1f);
    let _e533 = (((1.5625f * (_e526 * _e526)) - 0.5625f) * (_e528 * _e528));
    let _e537 = (vec2<f32>(1f, 1f) - _e54);
    let _e547 = (vec2<f32>(((_e537.x * _e338.x) + (_e537.y * _e338.y)), ((_e537.x * _e370) + (_e537.y * _e338.x))) * _e358);
    let _e553 = min(((_e547.x * _e547.x) + (_e547.y * _e547.y)), _e363);
    let _e555 = ((0.4f * _e553) - 1f);
    let _e557 = ((_e360 * _e553) - 1f);
    let _e562 = (((1.5625f * (_e555 * _e555)) - 0.5625f) * (_e557 * _e557));
    let _e566 = (vec2<f32>(2f, 1f) - _e54);
    let _e576 = (vec2<f32>(((_e566.x * _e338.x) + (_e566.y * _e338.y)), ((_e566.x * _e370) + (_e566.y * _e338.x))) * _e358);
    let _e582 = min(((_e576.x * _e576.x) + (_e576.y * _e576.y)), _e363);
    let _e584 = ((0.4f * _e582) - 1f);
    let _e586 = ((_e360 * _e582) - 1f);
    let _e591 = (((1.5625f * (_e584 * _e584)) - 0.5625f) * (_e586 * _e586));
    let _e595 = (vec2<f32>(2f, 0f) - _e54);
    let _e605 = (vec2<f32>(((_e595.x * _e338.x) + (_e595.y * _e338.y)), ((_e595.x * _e370) + (_e595.y * _e338.x))) * _e358);
    let _e611 = min(((_e605.x * _e605.x) + (_e605.y * _e605.y)), _e363);
    let _e613 = ((0.4f * _e611) - 1f);
    let _e615 = ((_e360 * _e611) - 1f);
    let _e620 = (((1.5625f * (_e613 * _e613)) - 0.5625f) * (_e615 * _e615));
    let _e624 = (vec2<f32>(1f, 0f) - _e54);
    let _e634 = (vec2<f32>(((_e624.x * _e338.x) + (_e624.y * _e338.y)), ((_e624.x * _e370) + (_e624.y * _e338.x))) * _e358);
    let _e640 = min(((_e634.x * _e634.x) + (_e634.y * _e634.y)), _e363);
    let _e642 = ((0.4f * _e640) - 1f);
    let _e644 = ((_e360 * _e640) - 1f);
    let _e649 = (((1.5625f * (_e642 * _e642)) - 0.5625f) * (_e644 * _e644));
    let _e653 = (vec2<f32>(1f, 2f) - _e54);
    let _e663 = (vec2<f32>(((_e653.x * _e338.x) + (_e653.y * _e338.y)), ((_e653.x * _e370) + (_e653.y * _e338.x))) * _e358);
    let _e669 = min(((_e663.x * _e663.x) + (_e663.y * _e663.y)), _e363);
    let _e671 = ((0.4f * _e669) - 1f);
    let _e673 = ((_e360 * _e669) - 1f);
    let _e678 = (((1.5625f * (_e671 * _e671)) - 0.5625f) * (_e673 * _e673));
    let _e682 = (vec2<f32>(0f, 2f) - _e54);
    let _e692 = (vec2<f32>(((_e682.x * _e338.x) + (_e682.y * _e338.y)), ((_e682.x * _e370) + (_e682.y * _e338.x))) * _e358);
    let _e698 = min(((_e692.x * _e692.x) + (_e692.y * _e692.y)), _e363);
    let _e700 = ((0.4f * _e698) - 1f);
    let _e702 = ((_e360 * _e698) - 1f);
    let _e707 = (((1.5625f * (_e700 * _e700)) - 0.5625f) * (_e702 * _e702));
    let _e720 = min(max(max(_e72, _e76), max(_e88, _e92)), max(min(min(_e72, _e76), min(_e88, _e92)), (((((((((((((_e60.xyz * _e390) + (_e64.xyz * _e417)) + (_e83.xyz * _e446)) + (_e88 * _e475)) + (_e72 * _e504)) + (_e68.xyz * _e533)) + (_e92 * _e562)) + (_e95.xyz * _e591)) + (_e79.xyz * _e620)) + (_e76 * _e649)) + (_e103.xyz * _e678)) + (_e99.xyz * _e707)) * (1f / (((((((((((_e390 + _e417) + _e446) + _e475) + _e504) + _e533) + _e562) + _e591) + _e620) + _e649) + _e678) + _e707)))));
    global_4 = vec4<f32>(_e720.x, _e720.y, _e720.z, 1f);
    return;
}

@fragment 
fn main(@builtin(position) param: vec4<f32>) -> @location(0) vec4<f32> {
    global_3 = param;
    function_();
    let _e3 = global_4;
    return _e3;
}
