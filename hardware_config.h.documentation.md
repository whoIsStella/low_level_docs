# hardware_config.h — Detailed reference & maintenance guide

Repository location:
- File: NS/include/config/hardware_config.h
- URL: https://github.com/whoIsStella/A_V/blob/main/NS/include/config/hardware_config.h

Purpose
-------
This file centralizes board- and MCU-specific configuration constants and macro aliases used across the HAL and application layers. It includes:
- MCU selection flags
- Clock configuration constants
- Memory layout constants
- Peripheral/board mappings (SPI, I2S, GPIO pins)
- DMA & IRQ priority defaults
- Timing and timer aliases

Why this file matters
---------------------
- Many HAL files (hal_dma.c, hal_gpio.c, hal_timer.c) directly reference constants defined here (APB1_CLOCK_HZ, DMA stream/channel macros, port aliases).
- Changing values here has broad impact; maintain careful coordination and test after changes.

Sections explained
------------------
1. MCU selection
   - `MCU_STM32F407` is defined. This indicates current code targets STM32F407 family.
   - If switching to other families (STM32H7), use separate MCU_* define and ensure all low-level register offsets and peripheral base addresses across HAL files are updated.

2. Clock configuration
   - SYSTEM_CLOCK_HZ, APB1_CLOCK_HZ, APB2_CLOCK_HZ: used to compute timer prescalers (e.g., TIM2).
   - Ensure these reflect actual PLL/clock config established by early system startup code (SystemInit/SystemClock_Config).

3. Memory layout
   - FLASH_BASE, SRAM_BASE, CCMRAM_BASE constants. Keep consistent with the linker script.

4. EEG & AUDIO hardware config
   - Provides channel counts, sample rates, SPI/I2S port names and DMA streams.
   - Examples: EEG_SPI_DMA_STREAM = DMA2_Stream0, EEG_SPI_DMA_CHANNEL = 3
   - These are symbolic names intended to be used by device initialization code. The HAL expects numeric base addresses for DMA and SPI definitions — you may need macros mapping symbolic names to numeric base addresses (e.g., SPI1 -> SPI1_BASE) elsewhere.

5. Display config
   - Interfaces and pin definitions for display control like DC, CS, RESET.

6. DMA configuration & IRQ priorities
   - DMA_EEG_PRIORITY, DMA_AUDIO_PRIORITY, DMA_DISPLAY_PRIORITY: enum-like symbols assigned to priorities used by HAL.
   - IRQ_PRIORITY_* macros: numeric NVIC priorities. Ensure the relationship (lower number = higher priority) matches your CMSIS implementation. If your toolchain uses reversed priority meaning, invert numbers accordingly.

Conventions and integration notes
---------------------------------
- Peripheral alias macros (e.g., SPI1, DMA1_Stream0) are used as human-friendly tokens in configuration. The HAL code uses numeric base addresses such as DMA1_BASE — ensure a mapping from these tokens to actual base addresses exists somewhere (a device header or board header). If these tokens are not mapped, replace them with numeric constants or add the mapping header.
- When adding new hardware (e.g., a different EEG board), add a board-specific config header that includes hardware_config.h and overrides specific macros with #undef / #define as needed.
- If switching to another MCU or package variant, update:
  - FLASH_SIZE, SRAM_SIZE, CCMRAM_SIZE
  - Peripheral base aliases
  - Clock frequencies if PLL config differs

Safety & testing
----------------
- After changing APB1/APB2 clock values, re-run tests that rely on timers, UART baud rates, and peripheral timings. Many subsystems assume clocks are set to particular values.
- When changing IRQ priorities, incremental test runs with DMA, audio, EEG streaming, and timer interrupts are essential to confirm latency/jitter constraints are satisfied.

Common pitfalls
---------------
- Mismatched names: code often uses `SPI1` as a token — ensure it maps to a numeric base in your platform headers.
- Incorrect priority ordering: CMSIS uses 0 as highest priority; ensure constants match that semantics.
- Heap/stack sizes: these must be consistent with the linker script and startup.c.

Extending for new boards
------------------------
- Create board-specific header: board_xyz.h which defines EEG_CS_PORT, EEG_CS_PIN, etc., then include it from project build configuration to override defaults.
- For multiple boards support, conditionally include board header based on a BOARD_xxx macro.

Where to look next
------------------
- hal_*.c files to see how these macros are consumed.
- linker_script.ld and system_config.h for stack/heap sizing coherence.
- Startup code ensuring clocks are configured to values assumed here.
