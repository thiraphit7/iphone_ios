/*
 * common.h - Common definitions for SEPwn iOS 26.1 Jailbreak
 * 
 * This header contains common macros, types, and declarations
 * used throughout the jailbreak codebase.
 */

#ifndef SEPWN_COMMON_H
#define SEPWN_COMMON_H

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <stdint.h>
#include <stdbool.h>
#include <unistd.h>
#include <mach/mach.h>
#include <mach/mach_vm.h>
#include <IOKit/IOKitLib.h>
#include <CoreFoundation/CoreFoundation.h>

/* Version Information */
#define SEPWN_NAME          "SEPwn"
#define SEPWN_VERSION       "1.0.0"
#define SEPWN_BUILD         "20260115"
#define TARGET_IOS_VERSION  "26.1"
#define TARGET_BUILD        "23B85"
#define TARGET_DEVICE       "iPhone18,4"

/* Kernel Address Constants */
#define KERNEL_BASE_MASK        0xFFFFFFF000000000ULL
#define KERNEL_BASE_PATTERN     0xFFFFFFF007000000ULL
#define KERNEL_SLIDE_MAX        0x0000000100000000ULL
#define KERNEL_POINTER_MASK     0x0000007FFFFFFFFFULL

/* PAC Constants */
#define PAC_MASK_UPPER          0xFF80000000000000ULL
#define PAC_MASK_LOWER          0x007FFFFFFFFFFFFFULL

/* IOKit Return Codes */
#define kIOReturnSuccess        0
#define kIOReturnError          0xe00002bc
#define kIOReturnNoMemory       0xe00002c7
#define kIOReturnBadArgument    0xe00002c2

/* Logging Macros */
#ifdef DEBUG
    #define LOG_DEBUG(fmt, ...) printf("[DEBUG] " fmt "\n", ##__VA_ARGS__)
#else
    #define LOG_DEBUG(fmt, ...)
#endif

#define LOG_INFO(fmt, ...)  printf("[*] " fmt "\n", ##__VA_ARGS__)
#define LOG_OK(fmt, ...)    printf("[+] " fmt "\n", ##__VA_ARGS__)
#define LOG_ERR(fmt, ...)   printf("[-] " fmt "\n", ##__VA_ARGS__)
#define LOG_WARN(fmt, ...)  printf("[!] " fmt "\n", ##__VA_ARGS__)

/* Utility Macros */
#define ARRAY_SIZE(arr)     (sizeof(arr) / sizeof((arr)[0]))
#define ALIGN(x, a)         (((x) + (a) - 1) & ~((a) - 1))
#define MIN(a, b)           ((a) < (b) ? (a) : (b))
#define MAX(a, b)           ((a) > (b) ? (a) : (b))

/* Error Handling */
#define CHECK_KERN(kr, msg) do { \
    if ((kr) != KERN_SUCCESS) { \
        LOG_ERR("%s: 0x%x", (msg), (kr)); \
        return -1; \
    } \
} while(0)

#define CHECK_NULL(ptr, msg) do { \
    if ((ptr) == NULL) { \
        LOG_ERR("%s: NULL pointer", (msg)); \
        return -1; \
    } \
} while(0)

/* Type Definitions */
typedef uint64_t kaddr_t;   /* Kernel address */
typedef uint64_t kptr_t;    /* Kernel pointer (may include PAC) */

/* Jailbreak State */
typedef enum {
    JB_STATE_INIT = 0,
    JB_STATE_INFO_LEAK,
    JB_STATE_KERNEL_RW,
    JB_STATE_PAC_BYPASS,
    JB_STATE_ESCALATED,
    JB_STATE_PATCHED,
    JB_STATE_COMPLETE,
    JB_STATE_FAILED
} jb_state_t;

/* Callback Types */
typedef void (*progress_callback_t)(int stage, int progress, const char *message);
typedef void (*log_callback_t)(const char *message);

/* Global Configuration */
typedef struct {
    bool verbose;
    bool dry_run;
    bool skip_checks;
    progress_callback_t progress_cb;
    log_callback_t log_cb;
} sepwn_config_t;

extern sepwn_config_t g_config;

#endif /* SEPWN_COMMON_H */
