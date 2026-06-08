-- linus/keywords/vulkan.lua
-- Vulkan API 1.3 (core). Uses volk or <vulkan/vulkan.h>.

return {

  -- ── Instance / Device ───────────────────────────────────────────────────────

  ["vkCreateInstance"] = [[
**`vkCreateInstance`** — Create a Vulkan instance (`<vulkan/vulkan.h>`)

```c
VkInstance inst;
VkApplicationInfo app  = { .sType = VK_STRUCTURE_TYPE_APPLICATION_INFO,
                           .pApplicationName = "App", .apiVersion = VK_API_VERSION_1_3 };
VkInstanceCreateInfo ci = { .sType = VK_STRUCTURE_TYPE_INSTANCE_CREATE_INFO,
                            .pApplicationInfo = &app };
vkCreateInstance(&ci, NULL, &inst);
// ...
vkDestroyInstance(inst, NULL);
```

**See also:** `vkDestroyInstance`, `vkEnumerateInstanceExtensionProperties`, `vkEnumerateInstanceLayerProperties`]],

  ["vkDestroyInstance"] = [[
**`vkDestroyInstance`** — Destroy a Vulkan instance (`<vulkan/vulkan.h>`)

```c
vkDestroyInstance(inst, NULL);   // NULL allocator uses default
```

**See also:** `vkCreateInstance`, `vkAllocationCallbacks`]],

  ["vkCreateDevice"] = [[
**`vkCreateDevice`** — Create a logical device (`<vulkan/vulkan.h>`)

```c
VkDevice device;
VkDeviceQueueCreateInfo qci = { .sType = VK_STRUCTURE_TYPE_DEVICE_QUEUE_CREATE_INFO,
                                 .queueFamilyIndex = 0, .queueCount = 1,
                                 .pQueuePriorities = &(float){1.0f} };
VkDeviceCreateInfo dci      = { .sType = VK_STRUCTURE_TYPE_DEVICE_CREATE_INFO,
                                .queueCreateInfoCount = 1, .pQueueCreateInfos = &qci };
vkCreateDevice(physDev, &dci, NULL, &device);
// ...
vkDestroyDevice(device, NULL);
```

**See also:** `vkDestroyDevice`, `vkEnumeratePhysicalDevices`, `vkGetPhysicalDeviceQueueFamilyProperties`]],

  ["vkDestroyDevice"] = [[
**`vkDestroyDevice`** — Destroy a logical device (`<vulkan/vulkan.h>`)

```c
vkDestroyDevice(device, NULL);   // invalidates all child objects
```

**See also:** `vkCreateDevice`]],

  ["vkEnumeratePhysicalDevices"] = [[
**`vkEnumeratePhysicalDevices`** — List physical GPUs (`<vulkan/vulkan.h>`)

```c
uint32_t count;
vkEnumeratePhysicalDevices(inst, &count, NULL);
VkPhysicalDevice *devices = malloc(count * sizeof(VkPhysicalDevice));
vkEnumeratePhysicalDevices(inst, &count, devices);
```

**See also:** `vkGetPhysicalDeviceProperties`, `vkGetPhysicalDeviceFeatures`, `vkGetPhysicalDeviceMemoryProperties`]],

  ["vkGetPhysicalDeviceProperties"] = [[
**`vkGetPhysicalDeviceProperties`** — Query device properties (`<vulkan/vulkan.h>`)

```c
VkPhysicalDeviceProperties props;
vkGetPhysicalDeviceProperties(physDev, &props);
// props.deviceName, props.apiVersion, props.limits.*
```

**See also:** `vkGetPhysicalDeviceFeatures`, `vkGetPhysicalDeviceMemoryProperties`, `vkEnumeratePhysicalDevices`]],

  -- ── Queue ───────────────────────────────────────────────────────────────────

  ["vkGetDeviceQueue"] = [[
**`vkGetDeviceQueue`** — Retrieve a queue handle (`<vulkan/vulkan.h>`)

```c
VkQueue queue;
vkGetDeviceQueue(device, queueFamilyIndex, queueIndex, &queue);

// Submit work:
VkSubmitInfo si = { .sType = VK_STRUCTURE_TYPE_SUBMIT_INFO, .commandBufferCount = 1,
                    .pCommandBuffers = &cmdBuf };
vkQueueSubmit(queue, 1, &si, VK_NULL_HANDLE);
vkQueueWaitIdle(queue);
```

**See also:** `vkCreateDevice`, `vkQueueSubmit`, `vkQueueWaitIdle`, `vkDeviceWaitIdle`]],

  ["vkQueueSubmit"] = [[
**`vkQueueSubmit`** — Submit command buffers to a queue (`<vulkan/vulkan.h>`)

```c
VkSemaphore waitSems[] = { imgAvail };
VkPipelineStageFlags waitStages[] = { VK_PIPELINE_STAGE_COLOR_ATTACHMENT_OUTPUT_BIT };
VkSemaphore signalSems[] = { renderDone };

VkSubmitInfo si = { .sType = VK_STRUCTURE_TYPE_SUBMIT_INFO,
                     .waitSemaphoreCount = 1, .pWaitSemaphores = waitSems,
                     .pWaitDstStageMask = waitStages,
                     .commandBufferCount = 1, .pCommandBuffers = &cmdBuf,
                     .signalSemaphoreCount = 1, .pSignalSemaphores = signalSems };
vkQueueSubmit(queue, 1, &si, VK_NULL_HANDLE);
```

**See also:** `vkQueueWaitIdle`, `vkDeviceWaitIdle`, `VkSubmitInfo`, `VkFence`]],

  ["vkQueueWaitIdle"] = [[
**`vkQueueWaitIdle`** — Wait until all submitted work completes (`<vulkan/vulkan.h>`)

```c
vkQueueWaitIdle(queue);   // blocks host until queue is idle
```

Prefer `vkWaitForFences` for synchronisation; `vkQueueWaitIdle` is a heavyweight debugging aid.

**See also:** `vkDeviceWaitIdle`, `vkQueueSubmit`, `VkFence`]],

  -- ── Surface / Swapchain ────────────────────────────────────────────────────

  ["vkCreateWin32SurfaceKHR"] = [[
**`vkCreateWin32SurfaceKHR`** — Create a Win32 surface (`<vulkan/vulkan.h>`)

```c
VkWin32SurfaceCreateInfoKHR ci = { .sType = VK_STRUCTURE_TYPE_WIN32_SURFACE_CREATE_INFO_KHR,
                                    .hinstance = hInstance, .hwnd = hWnd };
VkSurfaceKHR surface;
vkCreateWin32SurfaceKHR(inst, &ci, NULL, &surface);
```

**See also:** `vkDestroySurfaceKHR`, `vkGetPhysicalDeviceSurfaceCapabilitiesKHR`, `VkSurfaceKHR`]],

  ["vkCreateWaylandSurfaceKHR"] = [[
**`vkCreateWaylandSurfaceKHR`** — Create a Wayland surface (`<vulkan/vulkan.h>`)

```c
VkWaylandSurfaceCreateInfoKHR ci = { .sType = VK_STRUCTURE_TYPE_WAYLAND_SURFACE_CREATE_INFO_KHR,
                                      .display = display, .surface = surface };
VkSurfaceKHR vkSurface;
vkCreateWaylandSurfaceKHR(inst, &ci, NULL, &vkSurface);
```

**See also:** `vkDestroySurfaceKHR`, `vkGetPhysicalDeviceSurfaceCapabilitiesKHR`]],

  ["vkCreateSwapchainKHR"] = [[
**`vkCreateSwapchainKHR`** — Create a swapchain for presentation (`<vulkan/vulkan.h>`)

```c
VkSwapchainCreateInfoKHR ci = { .sType = VK_STRUCTURE_TYPE_SWAPCHAIN_CREATE_INFO_KHR,
                                 .surface = surface, .minImageCount = 2,
                                 .imageFormat = VK_FORMAT_B8G8R8A8_SRGB,
                                 .imageExtent = {width, height},
                                 .imageArrayLayers = 1,
                                 .imageUsage = VK_IMAGE_USAGE_COLOR_ATTACHMENT_BIT,
                                 .preTransform = caps.currentTransform,
                                 .compositeAlpha = VK_COMPOSITE_ALPHA_OPAQUE_BIT_KHR,
                                 .presentMode = VK_PRESENT_MODE_MAILBOX_KHR };
VkSwapchainKHR swapchain;
vkCreateSwapchainKHR(device, &ci, NULL, &swapchain);
```

**See also:** `vkDestroySwapchainKHR`, `vkGetSwapchainImagesKHR`, `vkAcquireNextImageKHR`, `vkQueuePresentKHR`]],

  ["vkDestroySwapchainKHR"] = [[
**`vkDestroySwapchainKHR`** — Destroy a swapchain (`<vulkan/vulkan.h>`)

```c
vkDestroySwapchainKHR(device, swapchain, NULL);
```

**See also:** `vkCreateSwapchainKHR`]],

  ["vkAcquireNextImageKHR"] = [[
**`vkAcquireNextImageKHR`** — Get the next swapchain image index (`<vulkan/vulkan.h>`)

```c
uint32_t imgIdx;
vkAcquireNextImageKHR(device, swapchain, UINT64_MAX, semaphore, VK_NULL_HANDLE, &imgIdx);
```

Wait on the semaphore before submitting rendering commands to that image.

**See also:** `vkCreateSwapchainKHR`, `vkQueuePresentKHR`, `VkSemaphore`]],

  ["vkQueuePresentKHR"] = [[
**`vkQueuePresentKHR`** — Present a swapchain image (`<vulkan/vulkan.h>`)

```c
VkPresentInfoKHR pi = { .sType = VK_STRUCTURE_TYPE_PRESENT_INFO_KHR,
                         .waitSemaphoreCount = 1, .pWaitSemaphores = &renderDone,
                         .swapchainCount = 1, .pSwapchains = &swapchain,
                         .pImageIndices = &imgIdx };
vkQueuePresentKHR(queue, &pi);
```

**See also:** `vkAcquireNextImageKHR`, `vkCreateSwapchainKHR`]],

  -- ── Render Pass / Pipeline ─────────────────────────────────────────────────

  ["vkCreateRenderPass"] = [[
**`vkCreateRenderPass`** — Describe subpass and attachment dependencies (`<vulkan/vulkan.h>`)

```c
VkAttachmentDescription colorAtt = { .format = VK_FORMAT_B8G8R8A8_SRGB,
                                      .loadOp = VK_ATTACHMENT_LOAD_OP_CLEAR,
                                      .storeOp = VK_ATTACHMENT_STORE_OP_STORE,
                                      .initialLayout = VK_IMAGE_LAYOUT_UNDEFINED,
                                      .finalLayout = VK_IMAGE_LAYOUT_PRESENT_SRC_KHR };
VkSubpassDescription subpass   = { .pipelineBindPoint = VK_PIPELINE_BIND_POINT_GRAPHICS,
                                    .colorAttachmentCount = 1,
                                    .pColorAttachments = &(VkAttachmentReference){
                                        .attachment = 0, .layout = VK_IMAGE_LAYOUT_COLOR_ATTACHMENT_OPTIMAL } };
VkRenderPassCreateInfo rpci    = { .sType = VK_STRUCTURE_TYPE_RENDER_PASS_CREATE_INFO,
                                    .attachmentCount = 1, .pAttachments = &colorAtt,
                                    .subpassCount = 1, .pSubpasses = &subpass };
VkRenderPass renderPass;
vkCreateRenderPass(device, &rpci, NULL, &renderPass);
```

**See also:** `vkDestroyRenderPass`, `vkCreateGraphicsPipelines`, `vkCmdBeginRenderPass`]],

  ["vkCmdBeginRenderPass"] = [[
**`vkCmdBeginRenderPass`** — Begin a render pass instance (`<vulkan/vulkan.h>`)

```c
VkClearValue clear = { .color = {0.0f, 0.0f, 0.0f, 1.0f} };
VkRenderPassBeginInfo rpbi = { .sType = VK_STRUCTURE_TYPE_RENDER_PASS_BEGIN_INFO,
                                .renderPass = renderPass, .framebuffer = framebuffer,
                                .renderArea = {0, 0, width, height},
                                .clearValueCount = 1, .pClearValues = &clear };
vkCmdBeginRenderPass(cmdBuf, &rpbi, VK_SUBPASS_CONTENTS_INLINE);
// ... draw calls ...
vkCmdEndRenderPass(cmdBuf);
```

**See also:** `vkCmdEndRenderPass`, `vkCreateRenderPass`, `VkFramebuffer`]],

  ["vkCmdEndRenderPass"] = [[
**`vkCmdEndRenderPass`** — End the current render pass (`<vulkan/vulkan.h>`)

```c
vkCmdEndRenderPass(cmdBuf);
```

Must follow `vkCmdBeginRenderPass`. The render pass instance is complete.

**See also:** `vkCmdBeginRenderPass`]],

  ["vkCreateGraphicsPipelines"] = [[
**`vkCreateGraphicsPipelines`** — Create graphics pipeline objects (`<vulkan/vulkan.h>`)

```c
VkGraphicsPipelineCreateInfo pci = { .sType = VK_STRUCTURE_TYPE_GRAPHICS_PIPELINE_CREATE_INFO,
                                      .stageCount = 2, .pStages = stages,
                                      .pVertexInputState = &vertexInput,
                                      .pInputAssemblyState = &inputAssembly,
                                      .pRasterizationState = &rasterState,
                                      .pMultisampleState = &multiSample,
                                      .pColorBlendState = &colorBlend,
                                      .layout = pipelineLayout,
                                      .renderPass = renderPass };
VkPipeline pipeline;
vkCreateGraphicsPipelines(device, VK_NULL_HANDLE, 1, &pci, NULL, &pipeline);
```

Expensive — create at init time and reuse. Pipeline cache with `vkCreatePipelineCache` speeds up re-creation.

**See also:** `vkDestroyPipeline`, `vkCreateComputePipelines`, `vkCreatePipelineCache`]],

  ["vkCreateComputePipelines"] = [[
**`vkCreateComputePipelines`** — Create compute pipeline (`<vulkan/vulkan.h>`)

```c
VkComputePipelineCreateInfo pci = { .sType = VK_STRUCTURE_TYPE_COMPUTE_PIPELINE_CREATE_INFO,
                                     .stage = computeStage, .layout = pipelineLayout };
VkPipeline pipeline;
vkCreateComputePipelines(device, VK_NULL_HANDLE, 1, &pci, NULL, &pipeline);
```

**See also:** `vkCreateGraphicsPipelines`, `vkCmdDispatch`]],

  ["vkCmdBindPipeline"] = [[
**`vkCmdBindPipeline`** — Bind a pipeline to a command buffer (`<vulkan/vulkan.h>`)

```c
vkCmdBindPipeline(cmdBuf, VK_PIPELINE_BIND_POINT_GRAPHICS, graphicsPipeline);
vkCmdBindPipeline(cmdBuf, VK_PIPELINE_BIND_POINT_COMPUTE, computePipeline);
```

**See also:** `vkCreateGraphicsPipelines`, `vkCreateComputePipelines`]],

  -- ── Shader Module ──────────────────────────────────────────────────────────

  ["vkCreateShaderModule"] = [[
**`vkCreateShaderModule`** — Create a shader module from SPIR-V (`<vulkan/vulkan.h>`)

```c
// Load SPIR-V binary into spirvCode (uint32_t*)
VkShaderModuleCreateInfo ci = { .sType = VK_STRUCTURE_TYPE_SHADER_MODULE_CREATE_INFO,
                                 .codeSize = codeSize, .pCode = spirvCode };
VkShaderModule sm;
vkCreateShaderModule(device, &ci, NULL, &sm);
// ...
vkDestroyShaderModule(device, sm, NULL);
```

Use `glslc` or `shaderc` to compile GLSL → SPIR-V offline.

**See also:** `vkDestroyShaderModule`, `VkPipelineShaderStageCreateInfo`]],

  ["vkDestroyShaderModule"] = [[
**`vkDestroyShaderModule`** — Destroy a shader module (`<vulkan/vulkan.h>`)

```c
vkDestroyShaderModule(device, shaderModule, NULL);
```

**See also:** `vkCreateShaderModule`]],

  -- ── Command Pool / Buffer ──────────────────────────────────────────────────

  ["vkCreateCommandPool"] = [[
**`vkCreateCommandPool`** — Create a command pool (`<vulkan/vulkan.h>`)

```c
VkCommandPoolCreateInfo ci = { .sType = VK_STRUCTURE_TYPE_COMMAND_POOL_CREATE_INFO,
                                .flags = VK_COMMAND_POOL_CREATE_RESET_COMMAND_BUFFER_BIT,
                                .queueFamilyIndex = qfi };
VkCommandPool pool;
vkCreateCommandPool(device, &ci, NULL, &pool);
// ...
vkDestroyCommandPool(device, pool, NULL);
```

Command buffers allocated from a pool can only be submitted to queues of the pool's family index.

**See also:** `vkDestroyCommandPool`, `vkAllocateCommandBuffers`, `vkResetCommandPool`]],

  ["vkAllocateCommandBuffers"] = [[
**`vkAllocateCommandBuffers`** — Allocate command buffers from a pool (`<vulkan/vulkan.h>`)

```c
VkCommandBufferAllocateInfo ai = { .sType = VK_STRUCTURE_TYPE_COMMAND_BUFFER_ALLOCATE_INFO,
                                    .commandPool = pool, .level = VK_COMMAND_BUFFER_LEVEL_PRIMARY,
                                    .commandBufferCount = 1 };
VkCommandBuffer cmdBuf;
vkAllocateCommandBuffers(device, &ai, &cmdBuf);
// ...
vkFreeCommandBuffers(device, pool, 1, &cmdBuf);
```

**See also:** `vkFreeCommandBuffers`, `vkBeginCommandBuffer`, `vkEndCommandBuffer`, `vkResetCommandBuffer`]],

  ["vkBeginCommandBuffer"] = [[
**`vkBeginCommandBuffer`** — Start recording a command buffer (`<vulkan/vulkan.h>`)

```c
VkCommandBufferBeginInfo bi = { .sType = VK_STRUCTURE_TYPE_COMMAND_BUFFER_BEGIN_INFO,
                                 .flags = VK_COMMAND_BUFFER_USAGE_ONE_TIME_SUBMIT_BIT };
vkBeginCommandBuffer(cmdBuf, &bi);
// ... record commands ...
vkEndCommandBuffer(cmdBuf);
```

**See also:** `vkEndCommandBuffer`, `vkResetCommandBuffer`, `vkAllocateCommandBuffers`]],

  ["vkEndCommandBuffer"] = [[
**`vkEndCommandBuffer`** — Finish recording a command buffer (`<vulkan/vulkan.h>`)

```c
vkEndCommandBuffer(cmdBuf);   // ready for submission
```

**See also:** `vkBeginCommandBuffer`, `vkQueueSubmit`]],

  ["vkCmdDraw"] = [[
**`vkCmdDraw`** — Issue non-indexed draw call (`<vulkan/vulkan.h>`)

```c
vkCmdDraw(cmdBuf, vertexCount, instanceCount, firstVertex, firstInstance);
```

**See also:** `vkCmdDrawIndexed`, `vkCmdDrawIndirect`]],

  ["vkCmdDrawIndexed"] = [[
**`vkCmdDrawIndexed`** — Issue indexed draw call (`<vulkan/vulkan.h>`)

```c
vkCmdDrawIndexed(cmdBuf, indexCount, instanceCount, firstIndex, vertexOffset, firstInstance);
```

Requires an index buffer bound via `vkCmdBindIndexBuffer`.

**See also:** `vkCmdDraw`, `vkCmdBindIndexBuffer`, `vkCmdDrawIndirect`]],

  ["vkCmdBindVertexBuffers"] = [[
**`vkCmdBindVertexBuffers`** — Bind vertex buffers (`<vulkan/vulkan.h>`)

```c
VkBuffer buffers[] = { vertexBuf };
VkDeviceSize offsets[] = { 0 };
vkCmdBindVertexBuffers(cmdBuf, 0, 1, buffers, offsets);
```

**See also:** `vkCmdBindIndexBuffer`, `vkCmdDraw`]],

  ["vkCmdBindIndexBuffer"] = [[
**`vkCmdBindIndexBuffer`** — Bind an index buffer (`<vulkan/vulkan.h>`)

```c
vkCmdBindIndexBuffer(cmdBuf, indexBuf, offset, VK_INDEX_TYPE_UINT32);
```

**See also:** `vkCmdBindVertexBuffers`, `vkCmdDrawIndexed`]],

  ["vkCmdBindDescriptorSets"] = [[
**`vkCmdBindDescriptorSets`** — Bind descriptor sets for a pipeline (`<vulkan/vulkan.h>`)

```c
vkCmdBindDescriptorSets(cmdBuf, VK_PIPELINE_BIND_POINT_GRAPHICS, pipelineLayout,
                        0, 1, &descriptorSet, 0, NULL);
```

**See also:** `vkAllocateDescriptorSets`, `vkUpdateDescriptorSets`, `VkDescriptorSet`]],

  -- ── Buffer / Image / Memory ────────────────────────────────────────────────

  ["vkCreateBuffer"] = [[
**`vkCreateBuffer`** — Create a buffer object (`<vulkan/vulkan.h>`)

```c
VkBufferCreateInfo ci = { .sType = VK_STRUCTURE_TYPE_BUFFER_CREATE_INFO,
                           .size = size, .usage = VK_BUFFER_USAGE_VERTEX_BUFFER_BIT
                                              | VK_BUFFER_USAGE_TRANSFER_DST_BIT };
VkBuffer buf;
vkCreateBuffer(device, &ci, NULL, &buf);
```

Does NOT allocate memory — call `vkAllocateMemory` and `vkBindBufferMemory` next.

**See also:** `vkDestroyBuffer`, `vkAllocateMemory`, `vkBindBufferMemory`, `vkGetBufferMemoryRequirements`]],

  ["vkDestroyBuffer"] = [[
**`vkDestroyBuffer`** — Destroy a buffer (`<vulkan/vulkan.h>`)

```c
vkDestroyBuffer(device, buf, NULL);
```

**See also:** `vkCreateBuffer`, `vkFreeMemory`]],

  ["vkAllocateMemory"] = [[
**`vkAllocateMemory`** — Allocate device memory (`<vulkan/vulkan.h>`)

```c
VkMemoryAllocateInfo ai = { .sType = VK_STRUCTURE_TYPE_MEMORY_ALLOCATE_INFO,
                             .allocationSize = memReqs.size,
                             .memoryTypeIndex = memTypeIdx };
VkDeviceMemory memory;
vkAllocateMemory(device, &ai, NULL, &memory);
// ...
vkFreeMemory(device, memory, NULL);
```

Prefer `VK_MEMORY_PROPERTY_DEVICE_LOCAL_BIT` for GPU-accessed resources. Use `VK_MEMORY_PROPERTY_HOST_VISIBLE_BIT | VK_MEMORY_PROPERTY_HOST_COHERENT_BIT` for staging.

**See also:** `vkFreeMemory`, `vkBindBufferMemory`, `vkBindImageMemory`, `vkGetBufferMemoryRequirements`, `vkMapMemory`]],

  ["vkFreeMemory"] = [[
**`vkFreeMemory`** — Free device memory (`<vulkan/vulkan.h>`)

```c
vkFreeMemory(device, memory, NULL);
```

**See also:** `vkAllocateMemory`]],

  ["vkBindBufferMemory"] = [[
**`vkBindBufferMemory`** — Bind device memory to a buffer (`<vulkan/vulkan.h>`)

```c
vkBindBufferMemory(device, buf, memory, offset);
```

**See also:** `vkAllocateMemory`, `vkCreateBuffer`, `vkGetBufferMemoryRequirements`]],

  ["vkMapMemory"] = [[
**`vkMapMemory`** — Map device memory to host-visible pointer (`<vulkan/vulkan.h>`)

```c
void *data;
vkMapMemory(device, memory, offset, size, 0, &data);
memcpy(data, source, size);
vkUnmapMemory(device, memory);
```

For host-coherent memory, writes are immediately visible. Otherwise, call `vkFlushMappedMemoryRanges`.

**See also:** `vkUnmapMemory`, `vkFlushMappedMemoryRanges`, `vkInvalidateMappedMemoryRanges`]],

  ["vkCreateImage"] = [[
**`vkCreateImage`** — Create an image object (`<vulkan/vulkan.h>`)

```c
VkImageCreateInfo ci = { .sType = VK_STRUCTURE_TYPE_IMAGE_CREATE_INFO,
                          .imageType = VK_IMAGE_TYPE_2D, .format = VK_FORMAT_R8G8B8A8_SRGB,
                          .extent = {width, height, 1}, .mipLevels = 1,
                          .arrayLayers = 1, .samples = VK_SAMPLE_COUNT_1_BIT,
                          .tiling = VK_IMAGE_TILING_OPTIMAL,
                          .usage = VK_IMAGE_USAGE_SAMPLED_BIT | VK_IMAGE_USAGE_TRANSFER_DST_BIT };
VkImage image;
vkCreateImage(device, &ci, NULL, &image);
```

**See also:** `vkDestroyImage`, `vkAllocateMemory`, `vkBindImageMemory`, `vkCreateImageView`, `vkGetImageMemoryRequirements`]],

  ["vkDestroyImage"] = [[
**`vkDestroyImage`** — Destroy an image (`<vulkan/vulkan.h>`)

```c
vkDestroyImage(device, image, NULL);
```

**See also:** `vkCreateImage`, `vkFreeMemory`]],

  ["vkCreateImageView"] = [[
**`vkCreateImageView`** — Create an image view (`<vulkan/vulkan.h>`)

```c
VkImageViewCreateInfo ci = { .sType = VK_STRUCTURE_TYPE_IMAGE_VIEW_CREATE_INFO,
                              .image = image, .viewType = VK_IMAGE_VIEW_TYPE_2D,
                              .format = VK_FORMAT_R8G8B8A8_SRGB,
                              .subresourceRange = { .aspectMask = VK_IMAGE_ASPECT_COLOR_BIT,
                                                     .baseMipLevel = 0, .levelCount = 1,
                                                     .baseArrayLayer = 0, .layerCount = 1 } };
VkImageView view;
vkCreateImageView(device, &ci, NULL, &view);
```

**See also:** `vkDestroyImageView`, `vkCreateImage`, `VkFramebuffer`]],

  ["vkCreateSampler"] = [[
**`vkCreateSampler`** — Create a sampler for texture filtering (`<vulkan/vulkan.h>`)

```c
VkSamplerCreateInfo ci = { .sType = VK_STRUCTURE_TYPE_SAMPLER_CREATE_INFO,
                            .magFilter = VK_FILTER_LINEAR, .minFilter = VK_FILTER_LINEAR,
                            .addressModeU = VK_SAMPLER_ADDRESS_MODE_REPEAT,
                            .addressModeV = VK_SAMPLER_ADDRESS_MODE_REPEAT,
                            .mipmapMode = VK_SAMPLER_MIPMAP_MODE_LINEAR };
VkSampler sampler;
vkCreateSampler(device, &ci, NULL, &sampler);
```

**See also:** `vkDestroySampler`, `vkCreateImageView`, `VkDescriptorImageInfo`]],

  -- ── Descriptors ─────────────────────────────────────────────────────────────

  ["vkCreateDescriptorSetLayout"] = [[
**`vkCreateDescriptorSetLayout`** — Define descriptor bindings (`<vulkan/vulkan.h>`)

```c
VkDescriptorSetLayoutBinding binding = { .binding = 0,
                                          .descriptorType = VK_DESCRIPTOR_TYPE_UNIFORM_BUFFER,
                                          .descriptorCount = 1,
                                          .stageFlags = VK_SHADER_STAGE_VERTEX_BIT };
VkDescriptorSetLayoutCreateInfo ci = { .sType = VK_STRUCTURE_TYPE_DESCRIPTOR_SET_LAYOUT_CREATE_INFO,
                                        .bindingCount = 1, .pBindings = &binding };
VkDescriptorSetLayout dsl;
vkCreateDescriptorSetLayout(device, &ci, NULL, &dsl);
```

**See also:** `vkDestroyDescriptorSetLayout`, `vkCreatePipelineLayout`, `vkAllocateDescriptorSets`]],

  ["vkAllocateDescriptorSets"] = [[
**`vkAllocateDescriptorSets`** — Allocate descriptor sets from a descriptor pool (`<vulkan/vulkan.h>`)

```c
VkDescriptorSetAllocateInfo ai = { .sType = VK_STRUCTURE_TYPE_DESCRIPTOR_SET_ALLOCATE_INFO,
                                    .descriptorPool = pool,
                                    .descriptorSetCount = 1,
                                    .pSetLayouts = &setLayout };
VkDescriptorSet ds;
vkAllocateDescriptorSets(device, &ai, &ds);
```

**See also:** `vkCreateDescriptorPool`, `vkUpdateDescriptorSets`, `vkCmdBindDescriptorSets`]],

  ["vkUpdateDescriptorSets"] = [[
**`vkUpdateDescriptorSets`** — Write or copy descriptor bindings (`<vulkan/vulkan.h>`)

```c
VkDescriptorBufferInfo bufInfo = { .buffer = uniformBuf, .offset = 0, .range = sizeof(Uniforms) };
VkWriteDescriptorSet wds = { .sType = VK_STRUCTURE_TYPE_WRITE_DESCRIPTOR_SET,
                              .dstSet = ds, .dstBinding = 0,
                              .descriptorCount = 1,
                              .descriptorType = VK_DESCRIPTOR_TYPE_UNIFORM_BUFFER,
                              .pBufferInfo = &bufInfo };
vkUpdateDescriptorSets(device, 1, &wds, 0, NULL);
```

**See also:** `vkAllocateDescriptorSets`, `vkCmdBindDescriptorSets`]],

  ["vkCreateDescriptorPool"] = [[
**`vkCreateDescriptorPool`** — Create a descriptor pool (`<vulkan/vulkan.h>`)

```c
VkDescriptorPoolSize ps = { .type = VK_DESCRIPTOR_TYPE_UNIFORM_BUFFER, .descriptorCount = 16 };
VkDescriptorPoolCreateInfo ci = { .sType = VK_STRUCTURE_TYPE_DESCRIPTOR_POOL_CREATE_INFO,
                                   .maxSets = 16, .poolSizeCount = 1, .pPoolSizes = &ps };
VkDescriptorPool pool;
vkCreateDescriptorPool(device, &ci, NULL, &pool);
```

**See also:** `vkDestroyDescriptorPool`, `vkAllocateDescriptorSets`, `vkResetDescriptorPool`]],

  -- ── Synchronisation ────────────────────────────────────────────────────────

  ["vkCreateSemaphore"] = [[
**`vkCreateSemaphore`** — Create a semaphore (`<vulkan/vulkan.h>`)

```c
VkSemaphoreCreateInfo ci = { .sType = VK_STRUCTURE_TYPE_SEMAPHORE_CREATE_INFO };
VkSemaphore sem;
vkCreateSemaphore(device, &ci, NULL, &sem);
```

Used to synchronise queue submissions (GPU→GPU). Binary semaphore — signalled once, consumed once.

**See also:** `vkDestroySemaphore`, `vkQueueSubmit`, `vkAcquireNextImageKHR`, `vkQueuePresentKHR`]],

  ["vkCreateFence"] = [[
**`vkCreateFence`** — Create a fence (`<vulkan/vulkan.h>`)

```c
VkFenceCreateInfo ci = { .sType = VK_STRUCTURE_TYPE_FENCE_CREATE_INFO };
VkFence fence;
vkCreateFence(device, &ci, NULL, &fence);
```

Used to synchronise GPU→CPU. Signalled when queue submission completes. `vkWaitForFences` blocks the host.

**See also:** `vkDestroyFence`, `vkWaitForFences`, `vkResetFences`, `vkQueueSubmit`]],

  ["vkWaitForFences"] = [[
**`vkWaitForFences`** — Block host until fences are signalled (`<vulkan/vulkan.h>`)

```c
vkWaitForFences(device, 1, &fence, VK_TRUE, UINT64_MAX);   // wait forever
```

**See also:** `vkCreateFence`, `vkResetFences`, `vkGetFenceStatus`]],

  ["vkResetFences"] = [[
**`vkResetFences`** — Reset fences to unsignalled state (`<vulkan/vulkan.h>`)

```c
vkResetFences(device, 1, &fence);
```

**See also:** `vkCreateFence`, `vkWaitForFences`]],

  ["vkCmdPipelineBarrier"] = [[
**`vkCmdPipelineBarrier`** — Insert a pipeline/memory barrier (`<vulkan/vulkan.h>`)

```c
VkImageMemoryBarrier barrier = { .sType = VK_STRUCTURE_TYPE_IMAGE_MEMORY_BARRIER,
                                  .oldLayout = VK_IMAGE_LAYOUT_UNDEFINED,
                                  .newLayout = VK_IMAGE_LAYOUT_TRANSFER_DST_OPTIMAL,
                                  .srcAccessMask = 0,
                                  .dstAccessMask = VK_ACCESS_TRANSFER_WRITE_BIT,
                                  .image = image,
                                  .subresourceRange = { .aspectMask = VK_IMAGE_ASPECT_COLOR_BIT,
                                                         .levelCount = 1, .layerCount = 1 } };
vkCmdPipelineBarrier(cmdBuf,
    VK_PIPELINE_STAGE_TOP_OF_PIPE_BIT, VK_PIPELINE_STAGE_TRANSFER_BIT,
    0, 0, NULL, 0, NULL, 1, &barrier);
```

**See also:** `VkImageMemoryBarrier`, `VkBufferMemoryBarrier`, `VkMemoryBarrier`]],

  -- ── Query / Misc ───────────────────────────────────────────────────────────

  ["vkCreateQueryPool"] = [[
**`vkCreateQueryPool`** — Create a query pool for timestamps or occlusion (`<vulkan/vulkan.h>`)

```c
VkQueryPoolCreateInfo ci = { .sType = VK_STRUCTURE_TYPE_QUERY_POOL_CREATE_INFO,
                              .queryType = VK_QUERY_TYPE_TIMESTAMP,
                              .queryCount = 2 };
VkQueryPool pool;
vkCreateQueryPool(device, &ci, NULL, &pool);

vkCmdWriteTimestamp(cmdBuf, VK_PIPELINE_STAGE_BOTTOM_OF_PIPE_BIT, pool, 0);
// ... work ...
vkCmdWriteTimestamp(cmdBuf, VK_PIPELINE_STAGE_BOTTOM_OF_PIPE_BIT, pool, 1);

uint64_t timestamps[2];
vkGetQueryPoolResults(device, pool, 0, 2, sizeof(timestamps), timestamps, sizeof(uint64_t),
                      VK_QUERY_RESULT_64_BIT | VK_QUERY_RESULT_WAIT_BIT);
float elapsed_ns = (float)(timestamps[1] - timestamps[0]) * props.limits.timestampPeriod;
```

**See also:** `vkDestroyQueryPool`, `vkCmdWriteTimestamp`, `vkCmdBeginQuery`, `vkGetQueryPoolResults`]],

  ["vkDeviceWaitIdle"] = [[
**`vkDeviceWaitIdle`** — Wait until all device queues are idle (`<vulkan/vulkan.h>`)

```c
vkDeviceWaitIdle(device);   // synchronous cleanup
```

Heavyweight — prefer `vkWaitForFences` or `vkQueueWaitIdle` for targeted synchronisation.

**See also:** `vkQueueWaitIdle`, `vkWaitForFences`]],

  ["vkGetFramebufferAttachments"] = [[
**`vkGetPhysicalDeviceSurfaceCapabilitiesKHR`** — Query surface capabilities (`<vulkan/vulkan.h>`)

```c
VkSurfaceCapabilitiesKHR caps;
vkGetPhysicalDeviceSurfaceCapabilitiesKHR(physDev, surface, &caps);
// caps.minImageCount, caps.maxImageCount, caps.currentExtent, caps.supportedUsageFlags
```

**See also:** `vkCreateSwapchainKHR`, `vkGetPhysicalDeviceSurfaceFormatsKHR`, `vkGetPhysicalDeviceSurfacePresentModesKHR`]],

  -- ── Debug ──────────────────────────────────────────────────────────────────

  ["vkCreateDebugUtilsMessengerEXT"] = [[
**`vkCreateDebugUtilsMessengerEXT`** — Set up debug callback (`<vulkan/vulkan.h>`, `VK_EXT_debug_utils`)

```c
static VKAPI_ATTR VkBool32 VKAPI_CALL debugCB(
    VkDebugUtilsMessageSeverityFlagBitsEXT, VkDebugUtilsMessageTypeFlagsEXT,
    const VkDebugUtilsMessengerCallbackDataEXT *data, void *) {
    fprintf(stderr, "[Vulkan] %s\n", data->pMessage);
    return VK_FALSE;
}

VkDebugUtilsMessengerCreateInfoEXT ci = { .sType = VK_STRUCTURE_TYPE_DEBUG_UTILS_MESSENGER_CREATE_INFO_EXT,
    .messageSeverity = VK_DEBUG_UTILS_MESSAGE_SEVERITY_WARNING_BIT_EXT
                     | VK_DEBUG_UTILS_MESSAGE_SEVERITY_ERROR_BIT_EXT,
    .messageType = VK_DEBUG_UTILS_MESSAGE_TYPE_GENERAL_BIT_EXT
                 | VK_DEBUG_UTILS_MESSAGE_TYPE_VALIDATION_BIT_EXT
                 | VK_DEBUG_UTILS_MESSAGE_TYPE_PERFORMANCE_BIT_EXT,
    .pfnUserCallback = debugCB };
VkDebugUtilsMessengerEXT dbg;
PFN_vkCreateDebugUtilsMessengerEXT fn = (PFN_vkCreateDebugUtilsMessengerEXT)
    vkGetInstanceProcAddr(inst, "vkCreateDebugUtilsMessengerEXT");
fn(inst, &ci, NULL, &dbg);
```

**See also:** `vkDestroyDebugUtilsMessengerEXT`, `vkGetInstanceProcAddr`, `VK_EXT_debug_utils`]],
}
