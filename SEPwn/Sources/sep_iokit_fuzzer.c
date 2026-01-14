/*
 * iOS 26.1 SEP IOKit Fuzzer
 * Target: AppleSEPManager, AppleSEPKeyStore, AppleSEPCredentialManager
 * 
 * This fuzzer targets the externalMethod interface of SEP-related KEXTs
 * to discover memory corruption vulnerabilities.
 * 
 * Build: clang -o sep_fuzzer sep_iokit_fuzzer.c -framework IOKit -framework CoreFoundation
 * Usage: ./sep_fuzzer [service_name] [iterations]
 * 
 * Author: Security Research Team
 * Date: January 2026
 */

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <stdint.h>
#include <time.h>
#include <unistd.h>
#include <mach/mach.h>
#include <IOKit/IOKitLib.h>
#include <CoreFoundation/CoreFoundation.h>

/* SEP-related service names discovered from kernelcache analysis */
static const char *SEP_SERVICES[] = {
    "AppleSEPManager",
    "AppleSEPKeyStore", 
    "AppleSEPCredentialManager",
    "ApplePearlSEPDriver",
    "AKSAnalytics",
    "ExclaveSEPManagerProxy",
    "IOBiometricFamily",
    NULL
};

/* User client types to try */
static const uint32_t UC_TYPES[] = {0, 1, 2, 3, 4, 5, 10, 100, 0xFFFFFFFF};
#define NUM_UC_TYPES (sizeof(UC_TYPES) / sizeof(UC_TYPES[0]))

/* Selector ranges based on analysis */
#define MAX_SELECTOR 256

/* Fuzzing configuration */
typedef struct {
    uint32_t iterations;
    uint32_t max_scalar_count;
    uint32_t max_struct_size;
    int verbose;
    int crash_on_error;
    char *target_service;
} fuzzer_config_t;

/* Statistics */
typedef struct {
    uint64_t total_calls;
    uint64_t successful_calls;
    uint64_t error_calls;
    uint64_t interesting_errors;
    uint64_t crashes;
} fuzzer_stats_t;

/* Global state */
static fuzzer_config_t g_config = {
    .iterations = 10000,
    .max_scalar_count = 16,
    .max_struct_size = 0x10000,
    .verbose = 0,
    .crash_on_error = 0,
    .target_service = NULL
};

static fuzzer_stats_t g_stats = {0};

/* Interesting error codes that may indicate vulnerabilities */
static const kern_return_t INTERESTING_ERRORS[] = {
    0xe00002bc,  /* kIOReturnBadArgument - may indicate missing validation */
    0xe00002c2,  /* kIOReturnNotPrivileged */
    0xe00002ed,  /* kIOReturnOverrun - buffer overflow indicator */
    0xe00002ee,  /* kIOReturnUnderrun */
    0xe00002c7,  /* kIOReturnNoMemory - heap exhaustion */
    0xe00002be,  /* kIOReturnNotOpen */
    0xe00002c9,  /* kIOReturnInternalError */
};
#define NUM_INTERESTING_ERRORS (sizeof(INTERESTING_ERRORS) / sizeof(INTERESTING_ERRORS[0]))

/* Mutation strategies */
typedef enum {
    MUTATE_RANDOM,
    MUTATE_BOUNDARY,
    MUTATE_BITFLIP,
    MUTATE_ARITHMETIC,
    MUTATE_SPECIAL_VALUES,
    MUTATE_FORMAT_STRING,
    NUM_MUTATIONS
} mutation_strategy_t;

/* Special values for integer fuzzing */
static const uint64_t SPECIAL_VALUES[] = {
    0x0,
    0x1,
    0x7F,
    0x80,
    0xFF,
    0x7FFF,
    0x8000,
    0xFFFF,
    0x7FFFFFFF,
    0x80000000,
    0xFFFFFFFF,
    0x7FFFFFFFFFFFFFFF,
    0x8000000000000000,
    0xFFFFFFFFFFFFFFFF,
    /* Kernel address patterns */
    0xFFFFFFF000000000,
    0xFFFFFFF007004000,
    /* PAC patterns */
    0x0000000100000000,
    0x8000000000000000,
};
#define NUM_SPECIAL_VALUES (sizeof(SPECIAL_VALUES) / sizeof(SPECIAL_VALUES[0]))

/* Format string patterns for info leak testing */
static const char *FORMAT_STRINGS[] = {
    "%p%p%p%p%p%p%p%p",
    "%x%x%x%x%x%x%x%x",
    "%s%s%s%s",
    "%n%n%n%n",
    "AAAA%08x.%08x.%08x.%08x",
    "%llx%llx%llx%llx",
};
#define NUM_FORMAT_STRINGS (sizeof(FORMAT_STRINGS) / sizeof(FORMAT_STRINGS[0]))

/* Logging */
#define LOG_INFO(fmt, ...) \
    do { if (g_config.verbose) printf("[INFO] " fmt "\n", ##__VA_ARGS__); } while(0)

#define LOG_ERROR(fmt, ...) \
    fprintf(stderr, "[ERROR] " fmt "\n", ##__VA_ARGS__)

#define LOG_VULN(fmt, ...) \
    printf("[VULN] " fmt "\n", ##__VA_ARGS__)

#define LOG_CRASH(fmt, ...) \
    printf("[CRASH] " fmt "\n", ##__VA_ARGS__)

/* Random number generation */
static uint64_t xorshift64_state = 0;

static void seed_random(void) {
    xorshift64_state = time(NULL) ^ getpid();
}

static uint64_t random64(void) {
    uint64_t x = xorshift64_state;
    x ^= x << 13;
    x ^= x >> 7;
    x ^= x << 17;
    xorshift64_state = x;
    return x;
}

static uint32_t random32(void) {
    return (uint32_t)random64();
}

static uint32_t random_range(uint32_t min, uint32_t max) {
    if (min >= max) return min;
    return min + (random32() % (max - min + 1));
}

/* Check if error is interesting */
static int is_interesting_error(kern_return_t kr) {
    for (size_t i = 0; i < NUM_INTERESTING_ERRORS; i++) {
        if (kr == INTERESTING_ERRORS[i]) {
            return 1;
        }
    }
    return 0;
}

/* Generate mutated scalar value */
static uint64_t generate_scalar(mutation_strategy_t strategy) {
    switch (strategy) {
        case MUTATE_RANDOM:
            return random64();
            
        case MUTATE_BOUNDARY:
            return SPECIAL_VALUES[random_range(0, NUM_SPECIAL_VALUES - 1)];
            
        case MUTATE_BITFLIP: {
            uint64_t val = random64();
            int bit = random_range(0, 63);
            return val ^ (1ULL << bit);
        }
        
        case MUTATE_ARITHMETIC: {
            uint64_t base = SPECIAL_VALUES[random_range(0, NUM_SPECIAL_VALUES - 1)];
            int delta = (int)random_range(0, 16) - 8;
            return base + delta;
        }
        
        case MUTATE_SPECIAL_VALUES:
            return SPECIAL_VALUES[random_range(0, NUM_SPECIAL_VALUES - 1)];
            
        default:
            return random64();
    }
}

/* Generate mutated struct data */
static void generate_struct(uint8_t *buf, size_t size, mutation_strategy_t strategy) {
    switch (strategy) {
        case MUTATE_RANDOM:
            for (size_t i = 0; i < size; i++) {
                buf[i] = random32() & 0xFF;
            }
            break;
            
        case MUTATE_BOUNDARY:
            memset(buf, 0xFF, size);
            /* Insert special values at key offsets */
            if (size >= 8) {
                *(uint64_t*)buf = SPECIAL_VALUES[random_range(0, NUM_SPECIAL_VALUES - 1)];
            }
            break;
            
        case MUTATE_BITFLIP:
            memset(buf, 0, size);
            for (size_t i = 0; i < size / 8 + 1; i++) {
                size_t byte_idx = random_range(0, size - 1);
                int bit = random_range(0, 7);
                buf[byte_idx] ^= (1 << bit);
            }
            break;
            
        case MUTATE_FORMAT_STRING: {
            const char *fmt = FORMAT_STRINGS[random_range(0, NUM_FORMAT_STRINGS - 1)];
            size_t fmt_len = strlen(fmt);
            if (fmt_len < size) {
                memcpy(buf, fmt, fmt_len);
                memset(buf + fmt_len, 0, size - fmt_len);
            } else {
                memcpy(buf, fmt, size);
            }
            break;
        }
        
        default:
            for (size_t i = 0; i < size; i++) {
                buf[i] = random32() & 0xFF;
            }
    }
}

/* Find and open IOKit service */
static io_connect_t open_service(const char *service_name, uint32_t uc_type) {
    io_service_t service = IOServiceGetMatchingService(
        kIOMainPortDefault,
        IOServiceMatching(service_name)
    );
    
    if (!service) {
        LOG_INFO("Service not found: %s", service_name);
        return 0;
    }
    
    io_connect_t connection = 0;
    kern_return_t kr = IOServiceOpen(service, mach_task_self(), uc_type, &connection);
    IOObjectRelease(service);
    
    if (kr != KERN_SUCCESS) {
        LOG_INFO("Failed to open service %s with type %u: 0x%x", service_name, uc_type, kr);
        return 0;
    }
    
    return connection;
}

/* Fuzz a single selector */
static void fuzz_selector(io_connect_t connection, const char *service_name, 
                          uint32_t uc_type, uint32_t selector) {
    mutation_strategy_t strategy = random_range(0, NUM_MUTATIONS - 1);
    
    /* Generate input scalars */
    uint32_t input_scalar_count = random_range(0, g_config.max_scalar_count);
    uint64_t input_scalars[16] = {0};
    for (uint32_t i = 0; i < input_scalar_count && i < 16; i++) {
        input_scalars[i] = generate_scalar(strategy);
    }
    
    /* Generate input struct */
    size_t input_struct_size = random_range(0, g_config.max_struct_size);
    uint8_t *input_struct = NULL;
    if (input_struct_size > 0) {
        input_struct = malloc(input_struct_size);
        if (input_struct) {
            generate_struct(input_struct, input_struct_size, strategy);
        } else {
            input_struct_size = 0;
        }
    }
    
    /* Prepare output buffers */
    uint64_t output_scalars[16] = {0};
    uint32_t output_scalar_count = 16;
    uint8_t output_struct[0x1000] = {0};
    size_t output_struct_size = sizeof(output_struct);
    
    /* Make the call */
    kern_return_t kr = IOConnectCallMethod(
        connection,
        selector,
        input_scalars,
        input_scalar_count,
        input_struct,
        input_struct_size,
        output_scalars,
        &output_scalar_count,
        output_struct,
        &output_struct_size
    );
    
    g_stats.total_calls++;
    
    if (kr == KERN_SUCCESS) {
        g_stats.successful_calls++;
        LOG_INFO("Success: %s[%u] selector %u", service_name, uc_type, selector);
        
        /* Check output for potential info leaks */
        for (uint32_t i = 0; i < output_scalar_count; i++) {
            /* Check for kernel address patterns */
            if ((output_scalars[i] & 0xFFFFFF0000000000ULL) == 0xFFFFFFF000000000ULL) {
                LOG_VULN("Potential kernel address leak: %s[%u] selector %u scalar[%u] = 0x%llx",
                         service_name, uc_type, selector, i, output_scalars[i]);
            }
        }
    } else {
        g_stats.error_calls++;
        
        if (is_interesting_error(kr)) {
            g_stats.interesting_errors++;
            LOG_VULN("Interesting error: %s[%u] selector %u returned 0x%x (strategy=%d, scalars=%u, struct_size=%zu)",
                     service_name, uc_type, selector, kr, strategy, input_scalar_count, input_struct_size);
        }
    }
    
    if (input_struct) {
        free(input_struct);
    }
}

/* Fuzz a service with all user client types */
static void fuzz_service(const char *service_name) {
    printf("[*] Fuzzing service: %s\n", service_name);
    
    for (size_t uc_idx = 0; uc_idx < NUM_UC_TYPES; uc_idx++) {
        uint32_t uc_type = UC_TYPES[uc_idx];
        
        io_connect_t connection = open_service(service_name, uc_type);
        if (!connection) {
            continue;
        }
        
        printf("[*] Opened %s with UC type %u\n", service_name, uc_type);
        
        /* Fuzz all selectors */
        for (uint32_t selector = 0; selector < MAX_SELECTOR; selector++) {
            for (uint32_t iter = 0; iter < g_config.iterations / MAX_SELECTOR + 1; iter++) {
                fuzz_selector(connection, service_name, uc_type, selector);
            }
        }
        
        IOServiceClose(connection);
    }
}

/* Print usage */
static void print_usage(const char *prog) {
    printf("iOS 26.1 SEP IOKit Fuzzer\n");
    printf("Usage: %s [options]\n", prog);
    printf("Options:\n");
    printf("  -s <service>   Target specific service\n");
    printf("  -i <count>     Number of iterations (default: 10000)\n");
    printf("  -v             Verbose output\n");
    printf("  -h             Show this help\n");
    printf("\nAvailable services:\n");
    for (int i = 0; SEP_SERVICES[i]; i++) {
        printf("  - %s\n", SEP_SERVICES[i]);
    }
}

/* Print statistics */
static void print_stats(void) {
    printf("\n=== Fuzzing Statistics ===\n");
    printf("Total calls:        %llu\n", g_stats.total_calls);
    printf("Successful calls:   %llu\n", g_stats.successful_calls);
    printf("Error calls:        %llu\n", g_stats.error_calls);
    printf("Interesting errors: %llu\n", g_stats.interesting_errors);
    printf("Crashes detected:   %llu\n", g_stats.crashes);
}

int main(int argc, char *argv[]) {
    int opt;
    
    while ((opt = getopt(argc, argv, "s:i:vh")) != -1) {
        switch (opt) {
            case 's':
                g_config.target_service = optarg;
                break;
            case 'i':
                g_config.iterations = atoi(optarg);
                break;
            case 'v':
                g_config.verbose = 1;
                break;
            case 'h':
            default:
                print_usage(argv[0]);
                return 0;
        }
    }
    
    printf("=== iOS 26.1 SEP IOKit Fuzzer ===\n");
    printf("Iterations: %u\n", g_config.iterations);
    printf("Max struct size: 0x%x\n", g_config.max_struct_size);
    
    seed_random();
    
    if (g_config.target_service) {
        fuzz_service(g_config.target_service);
    } else {
        for (int i = 0; SEP_SERVICES[i]; i++) {
            fuzz_service(SEP_SERVICES[i]);
        }
    }
    
    print_stats();
    
    return 0;
}
