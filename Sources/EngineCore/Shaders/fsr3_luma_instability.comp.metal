// Generated from fsr3_luma_instability.comp by Scripts/compile-shaders.sh — do not edit.
// Edit the GLSL and rerun the script (needs glslc and spirv-cross).
// spirv-fnv1a64: 55bcae762df76012
// glsl-fnv1a64: 90ab26ec2374ec68

#include <metal_stdlib>
#include <simd/simd.h>

using namespace metal;

struct _149
{
    int2 _m0;
    int2 _m1;
    int2 _m2;
    int2 _m3;
    float4 _m4;
    float2 _m5;
    float2 _m6;
    float2 _m7;
    float _m8;
    float _m9;
    float _m10;
    float _m11;
    float _m12;
    float _m13;
    float _m14;
    float _m15;
    float _m16;
    float _m17;
    float _m18;
    uint2 _m19;
};

constant uint3 gl_WorkGroupSize [[maybe_unused]] = uint3(8u, 8u, 1u);

kernel void compute_main(constant _149& _151 [[buffer(16)]], texture2d<float> _283 [[texture(1)]], texture2d<float> _265 [[texture(2)]], texture2d<float> _212 [[texture(3)]], texture2d<float> _238 [[texture(5)]], texture2d<float, access::write> _198 [[texture(8)]], texture2d<float, access::write> _251 [[texture(9)]], sampler _216 [[sampler(1)]], uint3 gl_GlobalInvocationID [[thread_position_in_grid]])
{
    int2 _643 = int2(gl_GlobalInvocationID.xy);
    float4 _1342;
    if (all(gl_GlobalInvocationID.xy < uint2(int2(_265.get_width(), _265.get_height()))))
    {
        _1342 = _265.read(uint2(_643), 0);
    }
    else
    {
        _1342 = float4(0.0);
    }
    float2 _720 = float2(_151._m0);
    float2 _721 = (float2(_643) + float2(0.5)) / _720;
    float2 _731 = float2(_151._m1);
    float2 _736 = (_721 + (_151._m6 / _731)) + _1342.xy;
    float _864 = _736.x;
    bool _865 = _864 >= 0.0;
    bool _871;
    if (_865)
    {
        _871 = _864 <= 1.0;
    }
    else
    {
        _871 = _865;
    }
    bool _883;
    if (_871)
    {
        float _874 = _736.y;
        bool _875 = _874 >= 0.0;
        bool _881;
        if (_875)
        {
            _881 = _874 <= 1.0;
        }
        else
        {
            _881 = _875;
        }
        _883 = _881;
    }
    else
    {
        _883 = _871;
    }
    float4 _1352;
    float _1359;
    if (_883)
    {
        float2 _914 = fast::max(float2(0.5), fast::min((_721 + (_151._m5 / _720)) * _720, _720 - float2(0.5))) / _720;
        float4 _932 = _283.sample(_216, _914, level(0.0));
        float4 _1357;
        float _1360;
        if (fast::clamp(_932.w, 0.0, 1.0) > 0.89999997615814208984375)
        {
            float _1007 = (_151._m18 == 0.0) ? 1.0 : _151._m18;
            float _770 = _238.sample(_216, _914, level(0.0)).x * _1007;
            float4 _1315 = (_212.sample(_216, (fast::max(float2(0.5), fast::min(_736 * _731, _731 - float2(0.5))) / _720), level(0.0)) * _151._m10) * _1007;
            float _1134 = _770 - _1315.x;
            float _1224 = fast::max(_770, _1315.x);
            float _1347;
            if (_1224 != 0.0)
            {
                _1347 = fast::min(_770, _1315.x) / _1224;
            }
            else
            {
                _1347 = 1.0;
            }
            float _1350;
            if (_1347 < 1.0)
            {
                float _1349;
                _1349 = _1347;
                float _1365;
                for (int _1348 = 1; _1348 <= 3; _1349 = _1365, _1348++)
                {
                    float _1252 = fast::max(_770, _1315[_1348]);
                    float _1361;
                    if (_1252 != 0.0)
                    {
                        _1361 = fast::min(_770, _1315[_1348]) / _1252;
                    }
                    else
                    {
                        _1361 = 0.0;
                    }
                    if (sign(_1134) == sign(_770 - _1315[_1348]))
                    {
                        _1365 = fast::max(_1349, _1361);
                    }
                    else
                    {
                        _1365 = _1349;
                    }
                }
                _1350 = float(_1349 > _1347);
            }
            else
            {
                _1350 = 0.0;
            }
            _1315.w = _1315.z;
            _1315.z = _1315.y;
            _1315.y = _1315.x;
            _1315.x = _770;
            float4 _1190 = _1315;
            float4 _1192 = _1190 / float4(_1007);
            _1315 = _1192;
            _1360 = (_1350 * float(_1315.w != 0.0)) * ((((1.0 - fast::clamp(length(_1342.xy * float2(3840.0, 2160.0)) * 0.0500000007450580596923828125, 0.0, 1.0)) * (1.0 - fast::clamp(_932.y, 0.0, 1.0))) * (1.0 - fast::clamp(_932.x, 0.0, 1.0))) * (1.0 - fast::clamp(_932.z, 0.0, 1.0)));
            _1357 = _1192;
        }
        else
        {
            _1360 = 0.0;
            _1357 = float4(0.0);
        }
        _1359 = _1360;
        _1352 = _1357;
    }
    else
    {
        _1359 = 0.0;
        _1352 = float4(0.0);
    }
    if (all(gl_GlobalInvocationID.xy < uint2(int2(_198.get_width(), _198.get_height()))))
    {
        _198.write(_1352, uint2(_643));
    }
    if (all(gl_GlobalInvocationID.xy < uint2(int2(_251.get_width(), _251.get_height()))))
    {
        _251.write(float4(_1359, 0.0, 0.0, 0.0), uint2(_643));
    }
}

