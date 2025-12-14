# Porting Guide Cheat Sheet

## Overview
Quick reference for porting NS firmware to different MCUs, boards, or architectures.

## Step 1: Hardware Configuration (hardware_config.h)
Update for target MCU and board:
```c
// MCU Selection
#define MCU_STM32F407  // Change to target family

// Clock Configuration
#define SYSTEM_CLOCK_HZ    168000000  // Update for target
#define APB1_CLOCK_HZ      42000000
#define APB2_CLOCK_HZ      84000000

// Memory Layout
#define FLASH_BASE  0x08000000  // Check datasheet
#define SRAM_BASE   0x20000000
#define FLASH_SIZE  (1024 * 1024)  // 1MB
#define SRAM_SIZE   (192 * 1024)   // 192KB

// GPIO Pin Assignments
#define EEG_CS_PORT         GPIOA
#define EEG_CS_PIN          4
#define EEG_DRDY_PORT       GPIOA
#define EEG_DRDY_PIN        3
// ... update all pin mappings
```

## Step 2: HAL Layer Porting (hal_*.c)

### GPIO (hal_gpio.c)
- Update register addresses for target MCU
- Adjust alternate function selection
- Update RCC clock enable bits
```c
// Example: STM32F4 → STM32H7
#define GPIOA_BASE  0x58020000  // H7 address
#define RCC_AHB4ENR_GPIOAEN (1 << 0)  // H7 clock bit
```

### DMA (hal_dma.c)
- Update DMA base addresses
- Adjust stream/channel mapping
- Update interrupt vector numbers
```c
// STM32F4: 8 streams per DMA, 8 channels per stream
// STM32H7: MDMA, DMA1/2 different architecture
```

### SPI (hal_spi.c)
- Update SPI base addresses
- Adjust clock source (APB1 vs APB2)
- Update baudrate prescaler calculation
```c
// Check which SPI is on which APB bus
// Update prescaler formula for clock differences
```

### I2S (hal_i2s.c)
- Update I2S PLL configuration
- Adjust prescaler calculations
- Some MCUs have dedicated SAI instead of I2S

### Timer (hal_timer.c)
- Select appropriate timer peripheral
- Update prescaler for microsecond resolution
- Adjust cycle counter access (DWT on Cortex-M)

## Step 3: Linker Script (linker_script.ld)
Update memory regions:
```ld
MEMORY
{
  FLASH (rx)  : ORIGIN = 0x08000000, LENGTH = 1024K
  RAM (rwx)   : ORIGIN = 0x20000000, LENGTH = 192K
  CCMRAM (rw) : ORIGIN = 0x10000000, LENGTH = 64K
}
```

Update stack and heap sizes:
```ld
_Min_Heap_Size = 0x400;   /* 1KB */
_Min_Stack_Size = 0x1000; /* 4KB */
```

## Step 4: Startup Code (startup.c)
- Update vector table for target MCU interrupt count
- Adjust SystemInit() for clock configuration
- Update PLL settings for desired frequency
```c
// Example: STM32F407 has 98 interrupts
// STM32H743 has 150 interrupts
__attribute__((used, section(".isr_vector")))
void (* const vectors[])(void) = {
    (void(*)(void))&_estack,
    Reset_Handler,
    // ... add all interrupts for target
};
```

## Step 5: Makefile Updates
```makefile
# Toolchain
CC = arm-none-eabi-gcc

# MCU-specific flags
CFLAGS += -mcpu=cortex-m4      # Change for target (m0/m3/m4/m7)
CFLAGS += -mfpu=fpv4-sp-d16    # Change for FPU type
CFLAGS += -DSTM32F407xx        # Update MCU define

# Linker script
LDFLAGS += -T stm32f407.ld     # Update for target
```

## Step 6: Test and Validate
1. **Build**: `make clean && make`
2. **Flash**: `make flash`
3. **Test GPIO**: Toggle LED to verify basic functionality
4. **Test Timer**: Verify microsecond timing accuracy
5. **Test DMA**: Run ring buffer tests
6. **Test SPI**: Communicate with EEG ADC
7. **Test I2S**: Verify audio output
8. **Full System**: Run neurofeedback loop

## Common Porting Scenarios

### STM32F4 → STM32H7
- Update clock tree (different PLL structure)
- Change DMA addressing (MDMA, DMA1/2 differences)
- Update cache management (D-cache on H7)
- Adjust UART/SPI base addresses

### STM32 → NXP i.MX RT
- Completely different register layouts
- Update all HAL implementations
- Different GPIO model (GPIO1-5 vs. GPIOA-I)
- Different DMA (eDMA vs. DMA controller)
- Keep API compatible, reimplement HAL

### Cortex-M4 → Cortex-M0+
- Remove FPU code (no hardware float)
- Adjust -mcpu flag
- Some instructions not available
- May need software floating point
- Reduce optimization for code size

### Bare Metal → FreeRTOS
- Update ENTER_CRITICAL/EXIT_CRITICAL
- Replace busy waits with vTaskDelay
- Use RTOS primitives (semaphores, queues)
- Adjust stack sizes per task
- Enable RTOS in system_config.h

## MCU-Specific Gotchas

### STM32F1
- No GPIO alternate function register (use AFIO)
- Different DMA (channels, not streams)
- Lower clock speed (72 MHz max)

### STM32F4
- GPIO AF register for pin muxing
- DMA streams + channels
- 168 MHz capable

### STM32H7
- Dual-core variants
- D-cache requires careful management
- Different clock tree
- Higher performance (400+ MHz)

### NXP Kinetis
- Different GPIO naming (PTA, PTB, etc.)
- Different register layouts entirely
- Clock gating via SIM module

## Quick Checklist
- [ ] Update hardware_config.h with pin assignments
- [ ] Update MCU define in Makefile
- [ ] Port HAL register access (hal_*.c)
- [ ] Update linker script memory regions
- [ ] Update startup.c vector table
- [ ] Verify clock configuration
- [ ] Test each HAL module individually
- [ ] Run full test suite
- [ ] Validate timing requirements
- [ ] Check memory usage (stack/heap)

## Resources
- **MCU Reference Manual**: Peripheral register descriptions
- **Datasheet**: Memory map, pin assignments, electrical specs
- **CMSIS Headers**: Standard peripheral definitions
- **HAL/LL Libraries**: Vendor-provided code for reference
- **Community Forums**: STM32, NXP, ARM communities

## Debugging Porting Issues
```c
// Basic "Hello World" test
hal_timer_init();
while(1) {
    hal_gpio_toggle(LED_PORT, LED_PIN);
    hal_timer_delay_ms(500);
}

// Check if code boots
// In Reset_Handler, toggle LED before jumping to main

// Verify clock frequency
// Measure timer accuracy with oscilloscope

// Check register writes
// Use debugger to inspect peripheral registers
```

## Performance Optimization After Porting
- Adjust compiler optimization (-O2, -O3, -Os)
- Enable link-time optimization (LTO)
- Use target-specific SIMD (if available)
- Tune cache settings (instruction/data cache)
- Profile with timer to find bottlenecks
# Porting Checklist for New MCU or Board

## Files Requiring Modification

### 1. Hardware Configuration
**File:** `NS/include/config/hardware_config.h`

**Update:**
- [ ] MCU selection define (`MCU_STM32F407` → `MCU_YOUR_CHIP`)
- [ ] Clock frequencies (SYSTEM_CLOCK_HZ, APB1/APB2_CLOCK_HZ)
- [ ] Memory layout (FLASH_BASE, SRAM_BASE, sizes)
- [ ] Peripheral base addresses (SPI, I2S, DMA, GPIO)
- [ ] Pin assignments (EEG_SPI_*, AUDIO_I2S_*, display pins)
- [ ] DMA stream/channel mappings
- [ ] IRQ numbers and priorities

**Validation:**
- [ ] Check new MCU's reference manual for correct addresses
- [ ] Verify clock tree matches configuration
- [ ] Confirm GPIO pins support required alternate functions

---

### 2. HAL Implementations
**Files:** `NS/src/layer1_hal/*.c`

#### hal_gpio.c
- [ ] RCC register address for GPIO clock enable (RCC_AHB1ENR offset)
- [ ] GPIO port base addresses (GPIOA_BASE, etc.)
- [ ] Alternate function register layout (AFRL/AFRH)

#### hal_dma.c
- [ ] DMA controller base addresses
- [ ] Stream register offsets (may differ on STM32H7, F7)
- [ ] Interrupt flag bit positions
- [ ] DMA IRQ numbers (DMA1_Stream0_IRQn, etc.)

#### hal_spi.c
- [ ] SPI peripheral base addresses
- [ ] Control register bit definitions (CR1, CR2)
- [ ] Status register flags (SR)
- [ ] Baud rate prescaler calculation (depends on APB clock)

#### hal_i2s.c
- [ ] I2S/SPI base addresses (some MCUs have separate I2S peripherals)
- [ ] I2S PLL configuration (PLLI2S registers)
- [ ] Clock calculation for audio frequencies

#### hal_timer.c (if exists)
- [ ] Timer base addresses (TIM2, TIM3, etc.)
- [ ] Prescaler and reload register offsets
- [ ] Timer IRQ numbers

---

### 3. Startup Code
**File:** `NS/src/layer0_baremetal/startup.c`

- [ ] Vector table entries (adjust count for MCU's interrupt count)
- [ ] IRQ handler function names (match DMA, SPI, I2S IRQ names)
- [ ] Reset handler (may need different SystemInit call)
- [ ] Stack pointer initialization (_estack from linker script)

**Note:** Some toolchains provide startup files (STM32CubeIDE, Keil). Consider using vendor-provided startup.s.

---

### 4. Linker Script
**File:** `STM32F407VETx_FLASH.ld` (or your equivalent)

- [ ] MEMORY regions (FLASH origin & length, RAM origin & length)
- [ ] Stack size (_Min_Stack_Size)
- [ ] Heap size (_Min_Heap_Size)
- [ ] Section placement (.text, .data, .bss, .heap, .stack)
- [ ] CCM RAM region (if available on new MCU)

**Validation:**
- [ ] FLASH size matches MCU (e.g., 512KB → 0x80000)
- [ ] RAM size matches MCU (e.g., 128KB → 0x20000)
- [ ] _estack address points to top of RAM

---

### 5. System Configuration
**File:** `NS/include/config/system_config.h`

- [ ] Verify buffer sizes fit in new MCU's RAM
- [ ] Adjust sample rates if new ADC/codec has different capabilities
- [ ] Update FFT sizes if RAM constrained

---

### 6. Makefile
**File:** `NS/Makefile`

- [ ] MCU flags (`-mcpu=cortex-m4` → `-mcpu=cortex-m7`, etc.)
- [ ] FPU flags (`-mfpu=fpv4-sp-d16` vs `-mfpu=fpv5-d16`)
- [ ] Linker script path
- [ ] OpenOCD configuration (new MCU may need different .cfg file)

---

## Common Porting Pitfalls

### Clock Configuration
**Problem:** Peripheral clocks run at unexpected frequencies  
**Fix:**
1. Trace clock tree from PLL to peripheral (reference manual)
2. Verify RCC->CFGR register settings
3. Confirm prescalers (AHB, APB1, APB2)
4. Test with timer or UART to measure actual clock

### DMA Mapping
**Problem:** DMA transfers don't start or fail silently  
**Fix:**
1. Check MCU's DMA request mapping table (DMA channel ↔ peripheral)
2. STM32F4 uses streams+channels; some MCUs use different schemes
3. Verify stream/channel in `hardware_config.h` matches reference manual

### Interrupt Priority Scheme
**Problem:** IRQs don't fire or fire out of order  
**Fix:**
1. Check if new MCU has different priority levels (4-bit vs 3-bit)
2. Verify preemption vs sub-priority grouping (PRIGROUP setting)
3. Lower number = higher priority (may differ on other architectures)

### Memory Alignment
**Problem:** Hard faults on DMA or unaligned accesses  
**Fix:**
1. Enable alignment fault detection (SCB->CCR UNALIGN_TRP)
2. Check Cortex-M variant (M0/M0+ don't support unaligned access)
3. Add alignment attributes to buffers

### GPIO Alternate Functions
**Problem:** Peripherals don't appear on pins  
**Fix:**
1. Check AF number for pins (varies by MCU, consult datasheet)
2. Verify GPIO_AF* value in hal_gpio.c
3. Ensure RCC clock for GPIO port is enabled

### Missing Peripherals
**Problem:** New board lacks I2S or has different codec  
**Fix:**
1. Check if MCU has required peripherals (some STM32F1 lack I2S)
2. Consider software fallbacks (I2S → SPI + external codec)
3. Update driver layer to support new codec if different

---

## Post-Porting Validation Checklist

### Basic Sanity Checks
- [ ] Firmware builds without errors
- [ ] Firmware flashes successfully
- [ ] Reset handler runs (LED blink or UART output)
- [ ] Clocks configured correctly (measure with timer or oscilloscope)

### Peripheral Validation
- [ ] GPIO: Toggle pin, measure with scope/multimeter
- [ ] Timer: Verify timebase accuracy (1ms tick)
- [ ] DMA: Simple memory-to-memory transfer
- [ ] SPI: Loopback test (MISO → MOSI)
- [ ] I2S: Verify bit clock frequency with scope

### Driver Validation
- [ ] EEG SPI: Read ADS1299 device ID register
- [ ] Audio I2S: Generate test tone (1kHz sine wave)
- [ ] Ring buffers: Run unit tests (test_ring_buffer.c)

### Integration Testing
- [ ] EEG data acquisition for 10 seconds (check for drops)
- [ ] Audio playback continuous for 60 seconds (check for glitches)
- [ ] Neurofeedback loop: EEG → processing → audio modulation
- [ ] Measure end-to-end latency (<250ms target)

### Performance Profiling
- [ ] CPU usage at idle, during EEG+audio streaming
- [ ] Measure ISR execution time (GPIO toggle method)
- [ ] Check stack high-water mark (no overflow)
- [ ] Verify RAM usage (heap, .data, .bss, stack)

---

## Useful Debugging Commands

```bash
# Check binary size and section breakdown
arm-none-eabi-size -A NS.elf

# Disassemble to verify code generation
arm-none-eabi-objdump -d NS.elf > disassembly.txt

# Find symbol addresses (check ISR vector table)
arm-none-eabi-nm NS.elf | grep IRQHandler

# Check memory layout from map file
grep -A 20 "Memory Configuration" NS.map
```

## References by MCU Family

**STM32F7:**
- Reference Manual: RM0385 (additional ART accelerator, cache)
- DMA: Similar to F4 but with DMAMUX on some variants

**STM32H7:**
- Reference Manual: RM0399 (DMAMUX, MDMA, dual-core on some)
- Dual-bank flash, different clock tree

**STM32L4:**
- Reference Manual: RM0351 (low-power, different DMA)
- Power modes, MSI clock source

**Other Vendors:**
- NXP Kinetis: Completely different DMA (eDMA), different GPIO, no AF number
- Microchip SAM: DMAC descriptor-based, different I2S (I2SC)
- Nordic nRF52: GPIOTE for events, EASYDMA, no I2S on some variants
