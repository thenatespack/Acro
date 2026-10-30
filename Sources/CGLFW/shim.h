#pragma once
#ifdef __APPLE__
// Must match CVulkan/shim.h, or the two modules see conflicting Vulkan definitions.
#define VK_ENABLE_BETA_EXTENSIONS
#endif
// Including Vulkan first makes glfw3.h declare glfwCreateWindowSurface & friends.
#include <vulkan/vulkan.h>
#define GLFW_INCLUDE_NONE
#include <GLFW/glfw3.h>
