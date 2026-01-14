/*
 * kernel_offsets.h - Kernel structure offsets for iOS 26.1 (23B85)
 * 
 * Target: iPhone Air (iPhone18,4) - Apple A19 Pro
 * 
 * These offsets are derived from kernelcache analysis and must be
 * verified/updated for each iOS version and device combination.
 */

#ifndef SEPWN_KERNEL_OFFSETS_H
#define SEPWN_KERNEL_OFFSETS_H

#include "common.h"

/* Kernel Offsets Structure */
typedef struct {
    /* Base addresses (to be filled at runtime) */
    kaddr_t kernel_base;
    kaddr_t kernel_slide;
    
    /* Important kernel symbols */
    kaddr_t allproc;            /* List of all processes */
    kaddr_t kernproc;           /* Kernel process */
    kaddr_t kernel_task;        /* Kernel task port */
    kaddr_t kernel_map;         /* Kernel VM map */
    
    /* Process structure (struct proc) offsets */
    uint32_t proc_p_list_le_next;   /* LIST_ENTRY(proc) p_list */
    uint32_t proc_p_list_le_prev;
    uint32_t proc_task;             /* task_t p_task */
    uint32_t proc_p_pid;            /* pid_t p_pid */
    uint32_t proc_p_ucred;          /* kauth_cred_t p_ucred */
    uint32_t proc_p_fd;             /* struct filedesc *p_fd */
    uint32_t proc_p_flag;           /* int p_flag */
    uint32_t proc_p_csflags;        /* uint32_t p_csflags */
    uint32_t proc_p_textvp;         /* struct vnode *p_textvp */
    
    /* Credential structure (struct ucred) offsets */
    uint32_t ucred_cr_ref;          /* u_long cr_ref */
    uint32_t ucred_cr_uid;          /* uid_t cr_uid */
    uint32_t ucred_cr_ruid;         /* uid_t cr_ruid */
    uint32_t ucred_cr_svuid;        /* uid_t cr_svuid */
    uint32_t ucred_cr_ngroups;      /* short cr_ngroups */
    uint32_t ucred_cr_groups;       /* gid_t cr_groups[NGROUPS] */
    uint32_t ucred_cr_rgid;         /* gid_t cr_rgid */
    uint32_t ucred_cr_svgid;        /* gid_t cr_svgid */
    uint32_t ucred_cr_gmuid;        /* uid_t cr_gmuid */
    uint32_t ucred_cr_flags;        /* int cr_flags */
    uint32_t ucred_cr_label;        /* struct label *cr_label */
    
    /* Task structure offsets */
    uint32_t task_lck_mtx_data;     /* lck_mtx_t lock */
    uint32_t task_ref_count;        /* os_ref_atomic_t ref_count */
    uint32_t task_active;           /* boolean_t active */
    uint32_t task_map;              /* vm_map_t map */
    uint32_t task_itk_space;        /* ipc_space_t itk_space */
    uint32_t task_bsd_info;         /* void *bsd_info (proc) */
    uint32_t task_t_flags;          /* uint64_t t_flags */
    uint32_t task_all_image_info_addr;
    uint32_t task_all_image_info_size;
    
    /* IPC Space offsets */
    uint32_t ipc_space_is_table;    /* ipc_entry_t is_table */
    uint32_t ipc_space_is_table_size;
    
    /* IPC Entry offsets */
    uint32_t ipc_entry_ie_object;   /* ipc_object_t ie_object */
    uint32_t ipc_entry_ie_bits;     /* ie_bits */
    uint32_t ipc_entry_size;        /* sizeof(struct ipc_entry) */
    
    /* IPC Port offsets */
    uint32_t ipc_port_ip_kobject;   /* ipc_kobject_t ip_kobject */
    uint32_t ipc_port_ip_receiver;
    uint32_t ipc_port_ip_srights;
    
    /* VM Map offsets */
    uint32_t vm_map_hdr;            /* struct vm_map_header hdr */
    uint32_t vm_map_pmap;           /* pmap_t pmap */
    uint32_t vm_map_min_offset;
    uint32_t vm_map_max_offset;
    
    /* Sandbox/MACF offsets */
    uint32_t sandbox_slot;          /* Sandbox slot in label */
    
    /* AMFI/Code Signing */
    kaddr_t amfi_allow_any_signature;
    kaddr_t cs_enforcement_disable;
    kaddr_t cs_require_lv;
    
    /* PPL/Trust Cache */
    kaddr_t ppl_trust_cache_rt;
    
    /* IOKit offsets */
    uint32_t iouc_external_method;
    
} kernel_offsets_t;

/* Default offsets for iOS 26.1 (23B85) on iPhone Air */
/* These are placeholder values - must be verified from kernelcache analysis */
static const kernel_offsets_t OFFSETS_IOS_26_1_23B85_IPHONE18_4 = {
    /* Base addresses (filled at runtime) */
    .kernel_base = 0xFFFFFFF007004000ULL,
    .kernel_slide = 0,
    
    /* Kernel symbols (offsets from kernel base) */
    .allproc = 0x00C00000,          /* Placeholder */
    .kernproc = 0x00C00008,         /* Placeholder */
    .kernel_task = 0x00C00010,      /* Placeholder */
    .kernel_map = 0x00C00018,       /* Placeholder */
    
    /* Process structure offsets */
    .proc_p_list_le_next = 0x00,
    .proc_p_list_le_prev = 0x08,
    .proc_task = 0x10,
    .proc_p_pid = 0x68,
    .proc_p_ucred = 0xD8,
    .proc_p_fd = 0xE8,
    .proc_p_flag = 0x100,
    .proc_p_csflags = 0x2A0,
    .proc_p_textvp = 0x2B0,
    
    /* Credential structure offsets */
    .ucred_cr_ref = 0x00,
    .ucred_cr_uid = 0x18,
    .ucred_cr_ruid = 0x1C,
    .ucred_cr_svuid = 0x20,
    .ucred_cr_ngroups = 0x24,
    .ucred_cr_groups = 0x28,
    .ucred_cr_rgid = 0x68,
    .ucred_cr_svgid = 0x6C,
    .ucred_cr_gmuid = 0x70,
    .ucred_cr_flags = 0x74,
    .ucred_cr_label = 0x78,
    
    /* Task structure offsets */
    .task_lck_mtx_data = 0x00,
    .task_ref_count = 0x10,
    .task_active = 0x18,
    .task_map = 0x28,
    .task_itk_space = 0x330,
    .task_bsd_info = 0x3A0,
    .task_t_flags = 0x3D0,
    .task_all_image_info_addr = 0x3E0,
    .task_all_image_info_size = 0x3E8,
    
    /* IPC Space offsets */
    .ipc_space_is_table = 0x20,
    .ipc_space_is_table_size = 0x18,
    
    /* IPC Entry offsets */
    .ipc_entry_ie_object = 0x00,
    .ipc_entry_ie_bits = 0x08,
    .ipc_entry_size = 0x18,
    
    /* IPC Port offsets */
    .ipc_port_ip_kobject = 0x68,
    .ipc_port_ip_receiver = 0x60,
    .ipc_port_ip_srights = 0xA0,
    
    /* VM Map offsets */
    .vm_map_hdr = 0x10,
    .vm_map_pmap = 0x48,
    .vm_map_min_offset = 0x50,
    .vm_map_max_offset = 0x58,
    
    /* Sandbox */
    .sandbox_slot = 0x10,
    
    /* AMFI/Code Signing (offsets from kernel base) */
    .amfi_allow_any_signature = 0x00D00000,  /* Placeholder */
    .cs_enforcement_disable = 0x00D00008,    /* Placeholder */
    .cs_require_lv = 0x00D00010,             /* Placeholder */
    
    /* PPL/Trust Cache */
    .ppl_trust_cache_rt = 0x00E00000,        /* Placeholder */
    
    /* IOKit */
    .iouc_external_method = 0x5B8,
};

/* Function declarations */
int offsets_init(void);
const kernel_offsets_t* offsets_get(void);
int offsets_set_slide(kaddr_t slide);
kaddr_t offsets_get_symbol(const char *name);

#endif /* SEPWN_KERNEL_OFFSETS_H */
