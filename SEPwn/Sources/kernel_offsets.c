/*
 * kernel_offsets.c - Kernel Offsets Implementation
 * 
 * This file manages kernel structure offsets for different iOS versions.
 */

#include "kernel_offsets.h"

/* Global offsets instance */
static kernel_offsets_t g_offsets;
static bool g_offsets_initialized = false;

/* Initialize offsets for current device/iOS version */
int offsets_init(void) {
    if (g_offsets_initialized) {
        return 0;
    }
    
    /* Copy default offsets for iOS 26.1 on iPhone Air */
    memcpy(&g_offsets, &OFFSETS_IOS_26_1_23B85_IPHONE18_4, sizeof(kernel_offsets_t));
    
    g_offsets_initialized = true;
    
    LOG_INFO("Kernel offsets initialized for iOS %s (%s)", TARGET_IOS_VERSION, TARGET_BUILD);
    
    return 0;
}

/* Get current offsets */
const kernel_offsets_t* offsets_get(void) {
    if (!g_offsets_initialized) {
        offsets_init();
    }
    return &g_offsets;
}

/* Set kernel slide */
int offsets_set_slide(kaddr_t slide) {
    if (!g_offsets_initialized) {
        offsets_init();
    }
    
    g_offsets.kernel_slide = slide;
    g_offsets.kernel_base = OFFSETS_IOS_26_1_23B85_IPHONE18_4.kernel_base + slide;
    
    LOG_INFO("Kernel slide set to 0x%016llx", slide);
    LOG_INFO("Kernel base: 0x%016llx", g_offsets.kernel_base);
    
    return 0;
}

/* Get symbol address by name */
kaddr_t offsets_get_symbol(const char *name) {
    if (!g_offsets_initialized) {
        offsets_init();
    }
    
    /* Simple symbol lookup */
    if (strcmp(name, "allproc") == 0) {
        return g_offsets.kernel_base + g_offsets.allproc;
    } else if (strcmp(name, "kernproc") == 0) {
        return g_offsets.kernel_base + g_offsets.kernproc;
    } else if (strcmp(name, "kernel_task") == 0) {
        return g_offsets.kernel_base + g_offsets.kernel_task;
    } else if (strcmp(name, "kernel_map") == 0) {
        return g_offsets.kernel_base + g_offsets.kernel_map;
    }
    
    LOG_WARN("Unknown symbol: %s", name);
    return 0;
}
