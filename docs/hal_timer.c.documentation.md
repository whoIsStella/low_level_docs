# hal_timer.c — Detailed reference & maintenance guide

Repository location:
- File: NS/src/layer1_hal/hal_timer.c
- URL: https://github.com/whoIsStella/A_V/blob/main/NS/src/layer1_hal/hal_timer.c

Purpose
-------
Implements a high-resolution timing HAL used by the system for microsecond timestamps and performance profiling. It uses:
- TIM2 as a 32-bit free-running timer (assumed peripheral)
- DWT cycle counter for CPU cycle counting

It exposes:
- hal_timer_init: configures TIM2 at 1 MHz resolution (1 us per tick)
- hal_timer_get_us / hal_timer_get_ms: monotonic timestamps
- hal_timer_delay_us / hal_timer_delay_ms: busy-wait delays
- hal_timer_start_measure / hal_timer_end_measure: quick performance measurement helpers
- hal_timer_get_cycles: returns DWT cycle counter

Design assumptions
------------------
- TIM2_BASE is 0x40000000 in this file (this is a placeholder). Confirm TIM2's real base address for your MCU (STM32F4 TIM2 base is typically 0x40000000? double-check).
- The code assumes APB1 clock (APB1_CLOCK_HZ) defined in hardware_config.h and uses it to compute a prescaler for 1 MHz timer.
- TIM2 is configured as 32-bit with ARR = 0xFFFFFFFF — this makes overflow infrequent (~71 minutes at 1 MHz) and code includes an overflow counter to build a 64-bit timestamp.

Key implementation points
-------------------------
- TIM2_IRQHandler increments `g_timer_overflow_count` when an update interrupt occurs and clears TIM2_SR flag.
- hal_timer_init:
  - Enables TIM2 clock via RCC_APB1ENR TIM2EN bit.
  - Configures PSC, ARR, DIER, NVIC, and starts timer.
  - Enables DWT cycle counter for fine-grained profiling.
- hal_timer_get_us:
  - Reads overflow count and counter value in a loop to protect against the counter overflowing between reads; returns combined 64-bit timestamp.
- Busy-wait delays:
  - hal_timer_delay_us uses hal_timer_get_us to busy loop. This is CPU-blocking — acceptable for short delays but bad for long waits and power consumption.

Caveats & corrections you may need
----------------------------------
- TIM2_BASE address:
  - Confirm with your device reference manual the correct TIM2 base address and update the macro if necessary. Using an incorrect base results in reading/writing unrelated addresses.
- DWT availability:
  - DWT cycle counter is a Core feature but may be unavailable or disabled on certain cores. Attempting to enable DWT without checking could be harmless on Cortex-M3/M4 but verify via CMSIS macros or CPU ID.
- TIM2 CR1/DIER/SR bit definitions are used by literal constants (1<<0). Using CMSIS symbolic names (e.g., TIM_CR1_CEN) is clearer and less error-prone.
- Race conditions:
  - hal_timer_get_us reads `g_timer_overflow_count` and TIM2_CNT; if TIM2 IRQ isn't enabled or happens after reads, the do/while loop protects consistency. However ensure TIM2 IRQ actually fires on overflow (DIER set) — otherwise `g_timer_overflow_count` never increases.

Interrupt & NVIC behavior
-------------------------
- TIM2 overflow increments the overflow counter in ISR. NVIC priority uses IRQ_PRIORITY_TIMER macro from hardware_config.h.
- If TIM2 interrupt gets disabled (e.g., by other code), overflow counting stops; hal_timer_get_us will still return lower-resolution timestamp (wrapped every 2^32 ticks). Ensure DIER/UART or other code don't disable TIM2 interrupts.

Usage examples
--------------
Basic initialization and usage:
```c
hal_timer_init();
uint64_t t0 = hal_timer_get_us();
// do something
uint64_t t1 = hal_timer_get_us();
uint32_t elapsed_us = (uint32_t)(t1 - t0);
```

Performance measurement:
```c
performance_marker_t m;
hal_timer_start_measure(&m);
// code to measure
uint32_t dur_us = hal_timer_end_measure(&m);
```

Modifications & extensions
--------------------------
- Replace busy-wait delays with OS sleep when running under an RTOS (if SYSTEM_CONFIG ENABLE_RTOS == 1). Use an RTOS delay method if available.
- Provide an API to select timer used (TIM2 vs other 32-bit timer) — currently hard-coded TIM2.
- Add calibration step if APB1 clock can change at runtime (update PSC when clock changes or call hal_timer_init after clock reconfiguration).

Debugging tips
--------------
- If hal_timer_get_us increments incorrectly:
  - Verify TIM2 CNT is readable and increments.
  - Ensure TIM2 interrupt is enabled so overflow is captured.
  - Confirm the prescaler value — if APB1_CLOCK_HZ macro is wrong, prescaler will be wrong and timer won't run at 1 MHz.

Testing recommendations
-----------------------
- Validate that hal_timer_get_us increases monotonically across overflow events (simulate long-run test or force ARR to smaller value).
- Check DWT_CYCCNT increments by single cycles when code runs — compare to known core frequency.

Where to look next
------------------
- hal_timer.h for API contract and types.
- hardware_config.h: confirm APB1 clock and TIM2 alias.
- startup.c & system_init: ensure timer init is called after clocks are configured.