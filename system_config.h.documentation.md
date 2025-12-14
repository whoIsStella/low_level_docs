# system_config.h — Detailed reference & maintenance guide

Repository location:
- File: NS/include/config/system_config.h
- URL: https://github.com/whoIsStella/A_V/blob/main/NS/include/config/system_config.h

Purpose
-------
This file centralizes system-wide runtime configuration constants, buffer sizes, processing parameters, and feature flags. It defines:
- Buffer memory allocations for EEG, audio, and display
- Stack size allocations
- FFT configuration and EEG frequency band definitions
- Timing requirements and jitter tolerances
- Feature enable/disable flags
- Debug and diagnostics settings

Why this file matters
---------------------
- Changing buffer sizes affects memory layout and must be coordinated with linker script memory regions.
- Sample rate and timing constants are used by HAL timers and DMA drivers; modifications require validation of timing accuracy.
- Feature flags control entire subsystems (USB, Bluetooth, RTOS); toggling them affects build dependencies and initialization sequences.
- Many processing modules (FFT engine, EEG processor) directly reference constants defined here.

Sections explained
------------------

1. **Buffer sizes & memory allocation**
   - EEG_DMA_BUFFER_SIZE (512): Size of double-buffered DMA transfer. Must be power-of-2 for efficient DMA.
   - EEG_RING_BUFFER_SIZE: Computed as EEG_BUFFER_SIZE * 2. Provides buffering between DMA and processing.
   - EEG_TOTAL_BUFFER_MEMORY: Total RAM needed (~160 KB). Ensure SRAM allocation in linker script.
   - Similar structure for AUDIO buffers (~64 KB total).
   - DISPLAY_FRAMEBUFFER_SIZE: Computed from width × height × bytes-per-pixel (~150 KB).
   - Stack sizes: MAIN_STACK_SIZE (4KB), task stack sizes for potential RTOS use.

2. **Processing configuration**
   - FFT_SIZE_EEG (512): FFT window size for EEG analysis. Must match buffer sizes.
   - FFT_SIZE_AUDIO (2048): Larger window for audio frequency resolution.
   - FFT_OVERLAP (0.5f): 50% overlap for smoother spectral analysis.
   - EEG band definitions: Standard clinical bands (delta, theta, alpha, beta, gamma) in Hz.

3. **Timing requirements**
   - EEG_SAMPLE_PERIOD_US: Computed from EEG_SAMPLE_RATE_HZ (~1953 µs for 512 Hz).
   - AUDIO_SAMPLE_PERIOD_US: Computed from AUDIO_SAMPLE_RATE_HZ (~20.8 µs for 48 kHz).
   - MAX_JITTER tolerances: 100 µs for EEG, 1 µs for audio. Used for validation in time_sync module.
   - NEUROFEEDBACK_LOOP_TARGET_MS (250): End-to-end latency target from brain signal to audio output.

4. **Feature flags**
   - ENABLE_USB_COMMUNICATION: Controls USB stack inclusion.
   - ENABLE_BLUETOOTH: Reserved for future wireless support.
   - ENABLE_DISPLAY: Controls display driver and framebuffer allocation.
   - ENABLE_SD_CARD_LOGGING: Reserved for data logging support.
   - ENABLE_RTOS (0): 0 = bare metal, 1 = FreeRTOS. Affects scheduler and synchronization primitives.

5. **Debug & diagnostics**
   - DEBUG_ENABLE: Master debug flag.
   - DEBUG_UART_PORT, DEBUG_UART_BAUDRATE: Serial debug output configuration.
   - ENABLE_PERFORMANCE_COUNTERS: Tracks execution times for profiling.
   - ENABLE_BUFFER_OVERFLOW_CHECK: Runtime validation of buffer boundaries.
   - ENABLE_STACK_OVERFLOW_CHECK: Detects stack corruption.

Key definitions
---------------
- Buffer sizes are tightly coupled to hardware_config.h constants (channel counts, sample rates).
- Changing EEG_DMA_BUFFER_SIZE requires corresponding changes in hal_dma.c DMA stream configuration.
- FFT sizes should be powers of 2 for efficient computation with standard FFT libraries.
- Total memory budget: ~160KB (EEG) + ~64KB (audio) + ~150KB (display) = ~374KB. Verify against available SRAM.

Assumptions & couplings
-----------------------
- Assumes hardware_config.h provides EEG_CHANNEL_COUNT, AUDIO_CHANNELS, EEG_BUFFER_SIZE, AUDIO_BUFFER_SIZE, DISPLAY_WIDTH, DISPLAY_HEIGHT, DISPLAY_BPP.
- Ring buffer implementations in layer3_datastructs/ring_buffer.c expect sizes defined here.
- Processing modules (fft_engine.c, eeg_processor.c) use FFT_SIZE_* constants directly.
- Timing constants assume accurate clock configuration (SYSTEM_CLOCK_HZ from hardware_config.h).

Safety & testing
----------------
- Always validate total memory usage against linker script before deployment.
- Test buffer overflow detection by intentionally exceeding buffer boundaries in a test environment.
- Verify timing jitter with oscilloscope or logic analyzer after changing sample rates.
- When changing FFT_SIZE, revalidate processing latency against NEUROFEEDBACK_LOOP_TARGET_MS.
- Feature flags should be tested in both enabled and disabled states to ensure no dead code issues.

Common pitfalls
---------------
- Setting buffer sizes too small causes data loss; too large wastes precious RAM.
- Mismatched FFT_SIZE and buffer sizes lead to incomplete windows or buffer underruns.
- Enabling RTOS without providing FreeRTOS configuration and initialization code causes build failures.
- Debug UART conflicts with other peripherals if pins overlap.
- Stack overflow checks add overhead; disable in production after validation.

Examples
--------
**Increasing EEG buffer size:**
```c
// Before
#define EEG_DMA_BUFFER_SIZE         512

// After (for lower latency with higher sample rate)
#define EEG_DMA_BUFFER_SIZE         256
```
After change: Update linker script if total memory changes, revalidate DMA timing, rebuild and test.

**Enabling RTOS:**
```c
#define ENABLE_RTOS                 1
```
Requires: Add FreeRTOS source files, create FreeRTOSConfig.h, modify main.c to call vTaskStartScheduler().

Where to look next
------------------
- hardware_config.h: Board-specific hardware parameters referenced by this file.
- common_types.h: Data structures (eeg_packet_t, audio_packet_t) sized according to these configurations.
- ring_buffer.h/c: Uses RING_BUFFER_SIZE constants.
- fft_engine.h/c: Uses FFT_SIZE_* constants.
- linker_script.ld: Verify memory regions accommodate total buffer allocations.
- main.c: Initialization sequences controlled by feature flags.
