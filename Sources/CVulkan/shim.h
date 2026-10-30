#pragma once
#ifdef __APPLE__
// VkPhysicalDevicePortabilitySubsetFeaturesKHR (MoltenVK) lives in vulkan_beta.h.
#define VK_ENABLE_BETA_EXTENSIONS
#endif
#include <vulkan/vulkan.h>
