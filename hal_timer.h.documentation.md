# hal_timer.h — Detailed reference & maintenance guide

Repository location:
- File: NS/src/layer1_hal/hal_timer.h
- URL: https://github.com/whoIsStella/A_V/blob/main/NS/src/layer1_hal/hal_timer.h

Purpose
-------
Declares the high-resolution timer HAL used by the firmware. Provides microsecond timestamps, delays, and lightweight performance measurement utilities. This is essential for EEG and audio synchronization.

API summary
-----------
- status_t hal_timer_init(void)
  - Initialize the timer subsystem (TIM2 + DWT).
- uint64_t hal_timer_get_us(void)
  - Returns a 64-bit monotonic microsecond timestamp.
- uint64_t hal_timer_get_ms(void)
  - Millisecond timestamp convenience wrapper.
- uint32_t hal_timer_get_cycles(void)
  - Returns CPU cycle counter from DWT.
- void hal_timer_delay_us(uint32_t us)
  - Blocking busy-wait for microseconds.
- void hal_timer_delay_ms(uint32_t ms)
  - Blocking millisecond delay.
- Performance markers:
  - hal_timer_start_measure(performance_marker_t* marker)
  - hal_timer_end_measure(performance_marker_t* marker) -> duration in microseconds

Types
-----
- timer_handle_t
  - timer_base: peripheral base address
  - frequency_hz: configured timer frequency (expected 1 MHz)
  - prescaler: hardware prescaler value
  - initialized: boolean flag

Important notes for integrators
------------------------------
- The header expects common_types.h and hardware_config.h to be included. `performance_marker_t` is defined in common_types.h.
- If running under an RTOS, block-style delays should be replaced by RTOS sleep calls. Consider adding wrapper functions that call OS delay when ENABLE_RTOS is set.

Extending the API
-----------------
- Add non-blocking wait with callback (schedule wake-up).
- Add support for multiple timer backends or clock reconfiguration notifications.

Where to look next
------------------
- hal_timer.c for implementation details, constants, and register usage.
- hardware_config.h for APB1 clock and TIM2 alias.
