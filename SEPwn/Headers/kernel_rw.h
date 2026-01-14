/*
 * kernel_rw.h - Kernel Read/Write Primitives
 * 
 * This header declares the kernel memory access primitives
 * used by the jailbreak.
 */

#ifndef SEPWN_KERNEL_RW_H
#define SEPWN_KERNEL_RW_H

#include "common.h"

/* Kernel R/W State */
typedef struct {
    bool initialized;
    kaddr_t kernel_base;
    kaddr_t kernel_slide;
    mach_port_t tfp0;
    io_connect_t exploit_connection;
} kernel_rw_state_t;

/* Initialization */
int kernel_rw_init(kaddr_t kernel_base, kaddr_t kernel_slide);
void kernel_rw_cleanup(void);
bool kernel_rw_is_initialized(void);

/* Read Primitives */
uint64_t kernel_read64(kaddr_t addr);
uint32_t kernel_read32(kaddr_t addr);
uint16_t kernel_read16(kaddr_t addr);
uint8_t kernel_read8(kaddr_t addr);
void kernel_read(kaddr_t addr, void *buf, size_t len);

/* Write Primitives */
void kernel_write64(kaddr_t addr, uint64_t value);
void kernel_write32(kaddr_t addr, uint32_t value);
void kernel_write16(kaddr_t addr, uint16_t value);
void kernel_write8(kaddr_t addr, uint8_t value);
void kernel_write(kaddr_t addr, const void *buf, size_t len);

/* Utility Functions */
kaddr_t kernel_alloc(size_t size);
void kernel_free(kaddr_t addr, size_t size);
int kernel_memcpy(kaddr_t dst, kaddr_t src, size_t len);

/* tfp0 Access */
mach_port_t kernel_get_tfp0(void);
int kernel_set_tfp0(mach_port_t tfp0);

/* Testing */
int kernel_rw_test(void);

#endif /* SEPWN_KERNEL_RW_H */
