// FSR 3.1 upscaler, pass 1 (SDK: ffx_fsr3upscaler_prepare_inputs_pass): dilates depth and motion
// vectors (nearest depth in 3x3), reprojects depth into the previous frame (atomic min/max into
// the reconstructed-depth buffer), and stores farthest depth in meters and luma. Included by
// fsr3_prepare_inputs.comp (standard depth) and fsr3_prepare_inputs_reversed.comp.
// See fsr3_callbacks.glsl for the bindings and FidelityFX/LICENSE.txt for the license.

#define FSR3UPSCALER_BIND_SRV_INPUT_MOTION_VECTORS                      9   // texture 1
#define FSR3UPSCALER_BIND_SRV_INPUT_DEPTH                               10  // texture 2
#define FSR3UPSCALER_BIND_SRV_INPUT_COLOR                               11  // texture 3
#define FSR3UPSCALER_BIND_UAV_DILATED_MOTION_VECTORS                    32  // storage texture 0
#define FSR3UPSCALER_BIND_UAV_DILATED_DEPTH                             33  // storage texture 1
#define FSR3UPSCALER_BIND_UAV_FARTHEST_DEPTH                            34  // storage texture 2
#define FSR3UPSCALER_BIND_UAV_CURRENT_LUMA                              35  // storage texture 3
#define FSR3UPSCALER_BIND_BUFFER_RECONSTRUCTED_PREV_NEAREST_DEPTH       24  // storage buffer 0

#include "fsr3_callbacks.glsl"
#include "FidelityFX/fsr3upscaler/ffx_fsr3upscaler_common.h"
#include "FidelityFX/fsr3upscaler/ffx_fsr3upscaler_prepare_inputs.h"

layout(local_size_x = 8, local_size_y = 8, local_size_z = 1) in;

void main()
{
    PrepareInputs(FfxInt32x2(gl_GlobalInvocationID.xy));
}
