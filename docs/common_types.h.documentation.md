# common_types.h — Detailed reference & maintenance guide

Repository location:
- File: NS/include/common_types.h
- URL: https://github.com/whoIsStella/A_V/blob/main/NS/include/common_types.h

Purpose
-------
This header provides a comprehensive set of type definitions, data structures, and utility macros used throughout the NS codebase. It serves as the central type system defining:
- Status and error codes
- EEG and audio data structures
- Signal processing structures (FFT features, band powers)
- Modulation and control structures
- Buffer management types
- Timing and synchronization types
- System state enumeration
- Utility macros for common operations

Why this file matters
---------------------
- All modules include this file directly or transitively, making it a core dependency.
- Changes to structure layouts affect memory alignment, DMA transfers, and inter-module interfaces.
- Adding or removing status codes impacts error handling throughout the codebase.
- The data structures define the wire format for DMA transfers and potential external communication.
- Utility macros are used extensively; changing them affects compiled code size and behavior.

Sections explained
------------------

1. STATUS & ERROR CODES (status_t enum)
   - STATUS_OK: Success (value 0, can use `if (!status)` idiom)
   - STATUS_ERROR: Generic error
   - STATUS_BUSY: Resource in use
   - STATUS_TIMEOUT: Operation timeout
   - STATUS_INVALID_PARAM: Invalid function parameter
   - STATUS_NOT_INITIALIZED: Attempted operation on uninitialized resource
   - STATUS_BUFFER_FULL/EMPTY: Ring buffer state
   - STATUS_DMA_ERROR, STATUS_HARDWARE_ERROR: Hardware failures
   - STATUS_OUT_OF_MEMORY: Allocation failure
   - Consistent return type across all APIs

2. EEG DATA STRUCTURES
   - eeg_sample_t: Single channel sample (24-bit ADC value, quality metric)
   - eeg_packet_t: Complete multi-channel sample with timestamp (packed for efficient storage)
   - eeg_config_t: Configuration parameters for EEG acquisition

3. AUDIO DATA STRUCTURES
   - audio_sample_t: Stereo frame (left/right channels)
   - audio_packet_t: Audio sample with timestamp
   - audio_config_t: Audio system configuration

4. SIGNAL PROCESSING DATA STRUCTURES
   - eeg_band_power_t: Frequency band powers (Delta, Theta, Alpha, Beta, Gamma)
   - eeg_features_t: Processed EEG features for neurofeedback
   - audio_features_t: Audio spectrum analysis results

5. MODULATION & CONTROL STRUCTURES
   - modulation_target_t: Targets for audio modulation (volume, EQ, etc.)
   - ramp_curve_t: Transition curve types
   - modulation_command_t: Command for audio parameter modulation

6. BUFFER MANAGEMENT STRUCTURES
   - ring_buffer_t: Generic circular buffer metadata
   - dma_buffer_t: Double-buffer (ping-pong) for DMA

7. TIMING & SYNCHRONIZATION
   - performance_marker_t: Timestamp + cycle count for profiling
   - timing_stats_t: Min/max/avg timing statistics

8. SYSTEM STATE
   - system_state_t: Overall system state machine enum

9. UTILITY MACROS
   - MIN, MAX, CLAMP: Value manipulation
   - ARRAY_SIZE: Array element count
   - ALIGN_4/8: Memory alignment
   - BIT_SET/CLEAR/TOGGLE/CHECK: Bit manipulation
   - ENTER_CRITICAL/EXIT_CRITICAL: Interrupt control
   - Compiler attributes: SECTION, ALIGNED, PACKED, WEAK, USED, UNUSED

Design principles
----------------

Packed structures:
- `__attribute__((packed))` on eeg_packet_t and audio_packet_t
- Prevents compiler padding, ensures consistent layout
- Critical for DMA, network transmission, and file storage
- Trade-off: May incur performance penalty on unaligned access

Timestamps:
- uint64_t microsecond timestamps throughout
- Consistent time base enables synchronization
- Wraps after ~584,000 years (not a practical concern)

Quality metrics:
- EEG samples include per-channel quality (0-100)
- Based on electrode impedance and signal integrity
- Allows runtime quality monitoring and bad data rejection

Volatile usage:
- Ring buffer indices are volatile (shared with ISRs)
- DMA buffer state is volatile (modified by DMA interrupts)

Common usage patterns
--------------------

Status code checking:
```c
status_t result = hal_spi_init(config);
if (result != STATUS_OK) {
    // Handle error
}
```

Data packet handling:
```c
eeg_packet_t packet;
packet.timestamp_us = hal_timer_get_us();
packet.sample_number = counter++;
// Fill channels...
ring_buffer_write(&eeg_buffer, &packet);
```

Bit manipulation:
```c
BIT_SET(GPIO_PORT->ODR, PIN_LED);
BIT_CLEAR(GPIO_PORT->ODR, PIN_CS);
```

Critical sections:
```c
ENTER_CRITICAL();
// Atomic operation
shared_variable++;
EXIT_CRITICAL();
```

Integration notes
----------------
- Included by: Nearly every source file
- Depends on: Standard C library headers only (stdint, stdbool, stddef)
- Defines used in: Ring buffers, DMA handlers, signal processing, drivers
- Status codes: Consistent across all layers

Extending this file
------------------
When adding new types:
- Group related types together
- Use consistent naming conventions (_t suffix for types)
- Add documentation comments
- Consider packed attribute for structures used in DMA/storage
- Use volatile for hardware-related or ISR-shared fields

Performance considerations
-------------------------
- Packed structures may cause unaligned access penalties on Cortex-M
- For performance-critical paths, consider natural alignment
- Bit manipulation macros compile to single instructions
- Critical section macros: ~2-3 cycles overhead

Common pitfalls
---------------
- Forgetting packed attribute: Causes DMA misalignment
- Using non-volatile for ISR-shared data: Compiler optimization issues
- Inconsistent status code usage: Confuses error handling
- Wrong alignment assumptions: Crashes on strict-alignment architectures

Porting considerations
---------------------
- Status codes: Portable across platforms
- ENTER_CRITICAL/EXIT_CRITICAL: Must adapt to RTOS if using one
- Compiler attributes: GCC-specific, adjust for other compilers
- Packed attribute: Check compiler syntax (MSVC uses #pragma pack)

Where to look next
------------------
- ring_buffer.h for ring_buffer_t usage
- hal_dma.h for dma_buffer_t usage
- eeg_processor.h for eeg_band_power_t and eeg_features_t usage
- audio_processor.h for audio_features_t usage
### 1. Status & error codes (status_t)
Standard return type for all HAL and driver functions. Enum values:
- STATUS_OK (0): Success, zero value for easy boolean checks.
- STATUS_ERROR: Generic error, use more specific codes when possible.
- STATUS_BUSY: Resource currently in use, retry later.
- STATUS_TIMEOUT: Operation didn't complete in expected time.
- STATUS_INVALID_PARAM: Caller provided invalid arguments.
- STATUS_NOT_INITIALIZED: Module not initialized before use.
- STATUS_BUFFER_FULL / BUFFER_EMPTY: Ring buffer states.
- STATUS_DMA_ERROR: DMA transfer failure.
- STATUS_HARDWARE_ERROR: Peripheral hardware fault.
- STATUS_OUT_OF_MEMORY: Memory allocation failed.

### 2. EEG data structures
- **eeg_sample_t**: Single channel sample with quality metric (0-100 for electrode impedance).
  - value: 24-bit ADC value sign-extended to 32-bit.
  - quality: Higher is better; <50 indicates poor contact.
  
- **eeg_packet_t**: Complete multi-channel sample at one time point.
  - __attribute__((packed)): No padding, matches DMA transfer format.
  - timestamp_us: Microsecond timestamp for synchronization with audio.
  - sample_number: Sequential counter for detecting drops.
  - channels[]: Array sized by EEG_CHANNEL_COUNT from hardware_config.h.
  
- **eeg_config_t**: Configuration for EEG driver initialization.
  - Includes filter enables (notch filters for 50/60Hz line noise).

### 3. Audio data structures
- **audio_sample_t**: Stereo frame (left/right channels).
  - 24-bit values sign-extended to 32-bit to match I2S codec format.
  
- **audio_packet_t**: Single stereo frame with metadata.
  - Packed structure for DMA efficiency.
  
- **audio_config_t**: Audio stream configuration.

### 4. Signal processing structures
- **eeg_band_power_t**: Spectral power in standard EEG frequency bands.
  - Computed by FFT engine from raw EEG data.
  - Used by neurofeedback engine for protocol implementation.
  
- **eeg_features_t**: Higher-level features extracted from EEG.
  - alpha_asymmetry: Frontal alpha left-right difference, indicator of emotional valence.
  - total_power: Sum across all bands, indicates overall brain activity level.
  
- **audio_features_t**: Audio quality metrics.
  - spectrum[]: Half-size FFT output (positive frequencies only).
  - thd, rms_level, peak_level: Audio quality and dynamics metrics.

### 5. Modulation & control structures
- **modulation_target_t**: Enum of audio parameters that can be modulated by EEG.
  - Volume, EQ bands, saturation, compression.
  
- **ramp_curve_t**: Defines transition curve for parameter changes.
  - LINEAR, EXPONENTIAL, LOGARITHMIC for perceptually smooth transitions.
  
- **modulation_command_t**: Complete modulation instruction.
  - Includes target, value, ramp time, curve, and priority.
  - Priority determines which command wins if multiple commands target same parameter.

### 6. Buffer management structures
- **ring_buffer_t**: Generic SPSC (single-producer single-consumer) ring buffer.
  - Volatile indices for thread-safe operation without locks.
  - element_size and capacity for generic use with any data type.
  - Used by ring_buffer.c implementation.
  
- **dma_buffer_t**: Ping-pong (double buffer) metadata.
  - Used by DMA drivers to manage continuous streaming.
  - active_buffer indicates which buffer is currently being filled.
  - transfer_complete flag signals buffer ready for processing.

### 7. Timing & synchronization
- **performance_marker_t**: Timestamp and cycle count for profiling.
  - Used with DWT (Data Watchpoint and Trace) cycle counter.
  
- **timing_stats_t**: Accumulated statistics for performance analysis.
  - min/max/avg tracking for latency measurements.

### 8. System state
- **system_state_t**: Overall system state machine enum.
  - Tracks initialization, calibration, running, error states.
  - Used by main.c and neurofeedback_engine.c.

### 9. Utility macros
- **MIN/MAX/CLAMP**: Standard numeric helpers.
- **ARRAY_SIZE**: Compile-time array length.
- **ALIGN_4/ALIGN_8**: Round up to alignment boundary (critical for DMA).
- **IS_ALIGNED_4/IS_ALIGNED_8**: Check pointer alignment.
- **BIT_SET/CLEAR/TOGGLE/CHECK**: Bit manipulation for register access.
- **ENTER_CRITICAL/EXIT_CRITICAL**: Disable/enable interrupts for atomic sections.
- **Compiler attributes**: SECTION, ALIGNED, PACKED, WEAK, USED, UNUSED.

Conventions
-----------
- All structures use typedef with _t suffix.
- Enums use UPPERCASE_WITH_UNDERSCORES for values.
- Packed structures (__attribute__((packed))) are used where memory layout must match hardware (DMA, external interfaces).
- Volatile qualifiers on shared indices indicate cross-context access.
- Timestamp fields are uint64_t in microseconds for long-term precision.

Critical considerations
-----------------------
- **Memory alignment**: DMA requires 4-byte or 8-byte aligned buffers depending on transfer size. Always use ALIGN_* macros for DMA buffers.
- **Structure packing**: Changing packed structures breaks DMA transfers and external communication. Document any changes thoroughly.
- **Status code handling**: Always check status_t return values. Ignoring errors leads to cascading failures.
- **Atomic access**: ring_buffer_t indices are volatile but not atomic; assumes single reader/single writer. Multi-producer or multi-consumer requires additional synchronization.

Safety & testing
----------------
- Validate structure sizes with sizeof() in test code to detect unexpected padding.
- Test alignment macros with various inputs (odd/even addresses).
- Verify ENTER_CRITICAL/EXIT_CRITICAL nesting behavior.
- Test ring buffer operations under high load to detect race conditions.
- Use static_assert (C11) where possible to enforce compile-time constraints.

Common pitfalls
---------------
- Forgetting to pack structures for DMA causes alignment errors and corrupted data.
- Using non-volatile indices in ring buffers leads to optimization bugs (compiler caches values).
- Not checking buffer alignment before DMA transfer causes DMA_ERROR.
- Returning generic STATUS_ERROR instead of specific codes makes debugging difficult.
- Overusing ENTER_CRITICAL creates long interrupt latency and timing issues.
- Bit manipulation macros used on non-volatile registers may be optimized incorrectly by compiler.

Usage examples
--------------

**Checking alignment before DMA:**
```c
void* buffer = malloc(1024);
if (!IS_ALIGNED_4(buffer)) {
    // Handle error or reallocate with aligned_alloc
    return STATUS_INVALID_PARAM;
}
```

**Safe error propagation:**
```c
status_t result = hal_dma_init(&dma_config);
if (result != STATUS_OK) {
    // Log specific error code
    debug_printf("DMA init failed: %d\n", result);
    return result;
}
```

**Atomic ring buffer access pattern:**
```c
ENTER_CRITICAL();
size_t available = ring_buffer->count;
if (available > 0) {
    // Safe to read
}
EXIT_CRITICAL();
```

Extending and maintenance
-------------------------
- **Adding new status codes**: Insert before STATUS_OUT_OF_MEMORY to maintain ABI compatibility.
- **Extending structures**: Add new fields at end of struct to minimize impact on existing code.
- **New data types**: Follow existing naming conventions (_t suffix, typedef).
- **Modifying macros**: Consider backward compatibility; many modules depend on exact behavior.

Where to look next
------------------
- hardware_config.h: Defines constants referenced in structure definitions (EEG_CHANNEL_COUNT, FFT_SIZE_AUDIO).
- system_config.h: Provides buffer size configurations used to size arrays in these structures.
- ring_buffer.c: Implementation using ring_buffer_t definition.
- hal_dma.c: Uses packed structures for DMA transfer configuration.
- All other modules: Nearly every file includes common_types.h.
