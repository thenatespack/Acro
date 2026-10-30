// Generated from taau.frag by Scripts/compile-shaders.sh — do not edit.
// Edit the GLSL and rerun the script (needs glslc and spirv-cross).
// spirv-fnv1a64: 7c6a34f0121a6bb5

#pragma clang diagnostic ignored "-Wmissing-prototypes"
#pragma clang diagnostic ignored "-Wmissing-braces"

#include <metal_stdlib>
#include <simd/simd.h>

using namespace metal;

template<typename T, size_t Num>
struct spvUnsafeArray
{
    T elements[Num ? Num : 1];
    
    thread T& operator [] (size_t pos) thread
    {
        return elements[pos];
    }
    constexpr const thread T& operator [] (size_t pos) const thread
    {
        return elements[pos];
    }
    
    device T& operator [] (size_t pos) device
    {
        return elements[pos];
    }
    constexpr const device T& operator [] (size_t pos) const device
    {
        return elements[pos];
    }
    
    constexpr const constant T& operator [] (size_t pos) const constant
    {
        return elements[pos];
    }
    
    threadgroup T& operator [] (size_t pos) threadgroup
    {
        return elements[pos];
    }
    constexpr const threadgroup T& operator [] (size_t pos) const threadgroup
    {
        return elements[pos];
    }
};

struct _115
{
    float2 _m0;
    float2 _m1;
    float2 _m2;
    float2 _m3;
    int2 _m4;
    int2 _m5;
    float _m6;
    float _m7;
};

struct fragment_main_out
{
    float4 m_376 [[color(0)]];
};

fragment fragment_main_out fragment_main(constant _115& _117 [[buffer(16)]], texture2d<float> _217 [[texture(1)]], texture2d<float> _285 [[texture(2)]], texture2d<float> _337 [[texture(3)]], texture2d<float> _103 [[texture(4)]], sampler _107 [[sampler(1)]], float4 gl_FragCoord [[position]])
{
    fragment_main_out out = {};
    do
    {
        float2 _140 = gl_FragCoord.xy * _117._m0;
        int2 _148 = int2(floor(_140 + _117._m2));
        float2 _158 = ((float2(_148) + float2(0.5)) - _117._m2) - _140;
        bool _166 = _117._m7 > 0.5;
        float _184 = _166 ? (-1.0) : 2.0;
        float3 _777;
        float _778;
        float _779;
        float3 _780;
        int2 _784;
        float3 _790;
        float3 _795;
        float3 _800;
        float3 _805;
        _805 = float3(-1000000000.0);
        _800 = float3(1000000000.0);
        _795 = float3(0.0);
        _790 = float3(0.0);
        _784 = _148;
        _780 = float3(0.0);
        _779 = 0.0;
        _778 = 0.0;
        _777 = float3(0.0);
        float3 _813;
        float _814;
        float3 _815;
        float _816;
        float3 _817;
        float3 _818;
        float3 _819;
        float3 _820;
        float _821;
        int2 _826;
        int _776 = -1;
        float _822 = _184;
        for (; _776 <= 1; _805 = _820, _800 = _819, _795 = _818, _790 = _817, _784 = _826, _780 = _815, _779 = _816, _778 = _814, _777 = _813, _776++, _822 = _821)
        {
            _821 = _822;
            _820 = _805;
            _819 = _800;
            _818 = _795;
            _817 = _790;
            _816 = _779;
            _815 = _780;
            _814 = _778;
            _813 = _777;
            _826 = _784;
            float3 _258;
            float _261;
            float3 _266;
            float _269;
            float3 _272;
            float3 _277;
            float3 _280;
            float3 _283;
            float _864;
            int2 _866;
            for (int _811 = -1; _811 <= 1; _821 = _864, _820 = _283, _819 = _280, _818 = _277, _817 = _272, _816 = _269, _815 = _266, _814 = _261, _813 = _258, _811++, _826 = _866)
            {
                int2 _215 = clamp(_148 + int2(_811, _776), int2(0), _117._m4);
                float4 _223 = _217.read(uint2(_215), 0);
                float _597 = _223.x;
                float _598 = _597 * 0.25;
                float _601 = _223.y * 0.5;
                float _604 = _223.z;
                float _605 = _604 * 0.25;
                float3 _625 = float3((_598 + _601) + _605, 0.5 * (_597 - _604), (_601 - _598) - _605);
                float2 _234 = _158 + float2(float(_811), float(_776));
                float2 _239 = _234 * _117._m1;
                float _631 = fast::max(1.0 - (dot(_234, _234) * 0.4444444477558135986328125), 0.0);
                float _634 = _631 * _631;
                float _640 = fast::max(1.0 - dot(_239, _239), 0.0);
                float _643 = _640 * _640;
                _258 = _813 + (_625 * _634);
                _261 = _814 + _634;
                _266 = _815 + (_625 * _643);
                _269 = _816 + _643;
                _272 = _817 + _625;
                _277 = _818 + (_625 * _625);
                _280 = fast::min(_819, _625);
                _283 = fast::max(_820, _625);
                float4 _291 = _285.read(uint2(_215), 0);
                float _292 = _291.x;
                bool _823;
                if (_166)
                {
                    _823 = _292 > _821;
                }
                else
                {
                    _823 = _292 < _821;
                }
                _864 = _823 ? _292 : _821;
                _866 = select(_826, _215, bool2(_823));
            }
        }
        float3 _317 = _777 / float3(_778);
        float3 _781;
        if (_779 > 0.0009765625)
        {
            _781 = _780 / float3(_779);
        }
        else
        {
            _781 = _317;
        }
        float _334 = fast::min(_779, 1.0);
        float2 _349 = gl_FragCoord.xy + (_337.read(uint2(_784), 0).xy * _117._m3);
        bool _354 = _117._m6 < 0.5;
        bool _362;
        if (_354)
        {
            _362 = all(_349 >= float2(0.0));
        }
        else
        {
            _362 = _354;
        }
        bool _370;
        if (_362)
        {
            _370 = all(_349 <= _117._m3);
        }
        else
        {
            _370 = _362;
        }
        if (!_370)
        {
            float _647 = _317.x;
            float _649 = _317.y;
            float _652 = _317.z;
            out.m_376 = float4((_647 + _649) - _652, _647 + _652, (_647 - _649) - _652, _334);
            break;
        }
        float2 _389 = _349 - float2(0.5);
        float2 _392 = floor(_389);
        float2 _396 = _389 - _392;
        int2 _401 = int2(_392) - int2(1);
        float2 _407 = _396 * 0.5;
        float2 _413 = _396 * (float2(-0.5) + (_396 * (float2(1.0) - _407)));
        float2 _417 = _396 * _396;
        float2 _421 = _396 * 1.5;
        float2 _426 = float2(1.0) + (_417 * (float2(-2.5) + _421));
        float2 _437 = _396 * (float2(0.5) + (_396 * (float2(2.0) - _421)));
        float2 _446 = _417 * (float2(-0.5) + _407);
        spvUnsafeArray<float, 4> _459 = spvUnsafeArray<float, 4>({ _413.x, _426.x, _437.x, _446.x });
        spvUnsafeArray<float, 4> _450 = _459;
        spvUnsafeArray<float, 4> _469 = spvUnsafeArray<float, 4>({ _413.y, _426.y, _437.y, _446.y });
        spvUnsafeArray<float, 4> _460 = _469;
        int _785;
        float3 _806;
        _806 = float3(0.0);
        _785 = 0;
        float3 _509;
        for (; _785 < 4; _806 = _509, _785++)
        {
            float3 _808;
            _808 = float3(0.0);
            for (int _807 = 0; _807 < 4; )
            {
                _808 += (_103.read(uint2(clamp(_401 + int2(_807, _785), int2(0), _117._m5)), 0).xyz * _450[_807]);
                _807++;
                continue;
            }
            _509 = _806 + (_808 * _460[_785]);
        }
        float3 _529 = _790 * 0.111111111938953399658203125;
        float3 _544 = sqrt(fast::max((_795 * 0.111111111938953399658203125) - (_529 * _529), float3(0.0))) * 1.25;
        float _684 = _806.x * 0.25;
        float _687 = _806.y * 0.5;
        float _691 = _806.z * 0.25;
        float _569 = fast::min(_103.read(uint2(clamp(int2(floor(_349)), int2(0), _117._m5)), 0).w, 12.0) + _334;
        float3 _577 = mix(fast::clamp(float3((_684 + _687) + _691, 0.5 * (_806.x - _806.z), (_687 - _684) - _691), fast::max(_800, _529 - _544), fast::min(_805, _529 + _544)), _781, float3(_334 / fast::max(_569, 0.0009765625)));
        float _715 = _577.x;
        float _717 = _577.y;
        float _720 = _577.z;
        out.m_376 = float4((_715 + _717) - _720, _715 + _720, (_715 - _717) - _720, fast::min(_569, 12.0));
        break;
    } while(false);
    return out;
}

