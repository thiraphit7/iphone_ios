/*
 * jailbreak.h - Main Jailbreak Interface
 * 
 * This header declares the main jailbreak API.
 */

#ifndef SEPWN_JAILBREAK_H
#define SEPWN_JAILBREAK_H

#include "common.h"
#include "kernel_offsets.h"
#include "kernel_rw.h"
#include "pac_bypass.h"
#include "exploit_utils.h"

/* Jailbreak Stages */
typedef enum {
    STAGE_INIT = 0,
    STAGE_INFO_LEAK = 1,
    STAGE_KERNEL_RW = 2,
    STAGE_PAC_BYPASS = 3,
    STAGE_ESCALATE = 4,
    STAGE_PATCH = 5,
    STAGE_POST_EXPLOIT = 6,
    STAGE_COMPLETE = 7,
    STAGE_COUNT
} jailbreak_stage_t;

/* Stage Names */
static const char *STAGE_NAMES[] = {
    "Initialization",
    "Information Leak",
    "Kernel Read/Write",
    "PAC Bypass",
    "Privilege Escalation",
    "Kernel Patching",
    "Post-Exploitation",
    "Complete"
};

/* Jailbreak State */
typedef struct {
    jailbreak_stage_t stage;
    bool success;
    
    /* Kernel Info */
    kaddr_t kernel_base;
    kaddr_t kernel_slide;
    
    /* Process Info */
    pid_t our_pid;
    kaddr_t our_proc;
    kaddr_t our_task;
    kaddr_t our_ucred;
    
    /* Kernel Task Port */
    mach_port_t tfp0;
    
    /* Capabilities */
    bool has_kernel_read;
    bool has_kernel_write;
    bool has_pac_bypass;
    bool is_root;
    bool is_unsandboxed;
    
    /* Error Info */
    int error_code;
    char error_message[256];
    
} jailbreak_state_t;

/* Callbacks */
typedef void (*jailbreak_progress_cb)(jailbreak_stage_t stage, int progress, const char *message);
typedef void (*jailbreak_log_cb)(const char *message);

/* Configuration */
typedef struct {
    bool verbose;
    bool dry_run;
    bool skip_post_exploit;
    jailbreak_progress_cb progress_callback;
    jailbreak_log_cb log_callback;
} jailbreak_config_t;

/* Main API */
int jailbreak_init(jailbreak_config_t *config);
int jailbreak_run(void);
void jailbreak_cleanup(void);

/* Stage Functions */
int jailbreak_stage_info_leak(void);
int jailbreak_stage_kernel_rw(void);
int jailbreak_stage_pac_bypass(void);
int jailbreak_stage_escalate(void);
int jailbreak_stage_patch(void);
int jailbreak_stage_post_exploit(void);

/* State Access */
const jailbreak_state_t* jailbreak_get_state(void);
jailbreak_stage_t jailbreak_get_stage(void);
bool jailbreak_is_complete(void);
const char* jailbreak_get_error(void);

/* Utility */
void jailbreak_print_status(void);
void jailbreak_print_banner(void);

/* Post-Jailbreak */
int jailbreak_spawn_root_shell(void);
int jailbreak_remount_rootfs(void);
int jailbreak_install_bootstrap(void);

#endif /* SEPWN_JAILBREAK_H */
