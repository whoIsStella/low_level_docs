# time_sync.h — Detailed reference & maintenance guide

Repository location:
- File: NS/include/layer3_datastructs/time_sync.h
- URL: https://github.com/whoIsStella/A_V/blob/main/NS/include/layer3_datastructs/time_sync.h

Purpose
-------
Provides unified time synchronization service for correlating EEG and audio data streams for maintaining temporal alignment in the neurofeedback loop.

Why this file matters
---------------------
- Enables precise correlation between brain signals and audio output
- Handles clock drift between different data sources
- Provides performance measurement infrastructure
- Essential for maintaining <250ms end-to-end latency requirement

Type definitions
---------------

1. time_source_t
   - TIME_SOURCE_EEG: EEG ADC sample clock
   - TIME_SOURCE_AUDIO: Audio codec clock
   - TIME_SOURCE_SYSTEM: System timer (microsecond counter)
   - TIME_SOURCE_EXTERNAL: External sync signal (if available)
   - Allows tracking which clock domain generated a timestamp

2. timestamped_event_t
   - Generic timestamped event structure
   - timestamp_us: Event time in microseconds
   - source: Which clock generated this timestamp
   - sequence_number: Sequential event counter

3. sync_stats_t
   - drift_us: Accumulated drift in microseconds
   - correction_count: Number of corrections applied
   - drift_rate: Drift rate in us/s
   - last_sync_time: When last synchronization occurred
   - Used for monitoring clock stability

Public API
----------

1. time_sync_init()
   - Initializes time synchronization service
   - Sets up timer hardware
   - Resets statistics
   - Must be called before other time_sync functions

2. time_sync_get_timestamp()
   - Returns current synchronized timestamp in microseconds
   - Uses system timer as base
   - Applies drift correction if available
   - Monotonic (never goes backward)

3. Stamping functions:
   - time_sync_stamp_eeg_packet(packet): Adds timestamp to EEG packet
   - time_sync_stamp_audio_packet(packet): Adds timestamp to audio packet
   - Convenience wrappers around time_sync_get_timestamp()
   - Ensures consistent stamping methodology

4. time_sync_calculate_diff(timestamp1, timestamp2)
   - Computes signed difference: timestamp1 - timestamp2
   - Returns int64_t (can be negative)
   - Handles 64-bit wraparound correctly

5. time_sync_are_synchronized(eeg_ts, audio_ts, tolerance_us)
   - Checks if two timestamps are within tolerance
   - Returns true if |eeg_ts - audio_ts| <= tolerance_us
   - Used to detect synchronization drift

6. time_sync_correct_drift(reference_source)
   - Applies drift correction based on reference source
   - Compares system clock against EEG or audio clock
   - Adjusts internal offset to minimize drift
   - Should be called periodically (e.g., every second)

7. time_sync_get_stats(stats) / time_sync_reset_stats()
   - Retrieves or resets drift statistics
   - Essential for monitoring clock health

8. Performance measurement:
   - time_sync_start_measure(marker): Records start timestamp and cycle count
   - time_sync_end_measure(marker): Computes duration
   - Returns duration in microseconds
   - Uses DWT cycle counter for sub-microsecond precision

9. Utility functions:
   - time_sync_us_to_ms(): Converts microseconds to milliseconds
   - time_sync_ms_to_us(): Converts milliseconds to microseconds
   - Inline functions for zero overhead

Usage patterns
-------------

Timestamping EEG data (in DMA callback):
```c
void eeg_dma_complete_callback(void) {
    eeg_packet_t packet;
    read_eeg_adc(&packet);
    time_sync_stamp_eeg_packet(&packet);
    ring_buffer_write(&eeg_buffer, &packet);
}
```

Checking synchronization:
```c
if (time_sync_are_synchronized(eeg_ts, audio_ts, 1000)) {
    // Within 1ms - acceptable
    process_neurofeedback(eeg_data, audio_data);
} else {
    // Drift detected - log warning
}
```

Performance profiling:
```c
performance_marker_t marker;
time_sync_start_measure(&marker);
fft_process(data);
uint32_t duration_us = time_sync_end_measure(&marker);
```

Drift correction (called periodically):
```c
void system_maintenance_task(void) {
    time_sync_correct_drift(TIME_SOURCE_EEG);  // EEG is reference
    
    sync_stats_t stats;
    time_sync_get_stats(&stats);
    if (abs(stats.drift_us) > 10000) {  // >10ms drift
        log_warning("Clock drift detected");
    }
}
```

Clock drift considerations
-------------------------
- STM32F4 internal oscillator: ±1% typical
- Crystal oscillator: ±50 ppm typical (43 µs/s drift)
- Audio codec PLL: May drift relative to MCU clock
- EEG ADC clock: May be independent crystal
- Correction needed for long-running sessions (>1 hour)

Timing accuracy
--------------
- Microsecond resolution (1 µs)
- Sub-microsecond precision with cycle counter
- Jitter: <1 µs typical (depends on interrupt latency)
- Long-term stability: Depends on oscillator quality

Integration notes
----------------
- Used by: eeg_driver, audio_driver, neurofeedback_engine
- Depends on: hal_timer for hardware timer access
- Critical for: Maintaining <250ms end-to-end latency
- Timestamp wraparound: ~584,000 years (not a concern)

Common pitfalls
---------------
- Not calling time_sync_init(): Uninitialized timestamps
- Ignoring drift: Long sessions lose synchronization
- Mixed time sources: Comparing timestamps from different clocks
- Tolerance too tight: False positives on synchronization checks
- Not monitoring stats: Miss gradual drift accumulation

Performance considerations
-------------------------
- time_sync_get_timestamp(): ~0.5 µs
- time_sync_calculate_diff(): ~0.1 µs (single subtraction)
- Drift correction: ~2 µs (infrequent operation)
- Stamping overhead: Negligible in context of data acquisition

Where to look next
------------------
- hal_timer.h for underlying timer implementation
- eeg_driver.c and audio_driver.c for usage examples
- neurofeedback_engine.c for synchronization checking
Provides microsecond-precision timestamping and synchronization between EEG and audio data streams. Enables:
- System-wide timestamp generation from hardware timer
- Jitter measurement and validation
- Cross-stream synchronization for neurofeedback latency tracking
- Performance profiling support

Why this file matters
---------------------
- Accurate timestamps are essential for correlating brain signals with audio output.
- Neurofeedback target latency (<250ms) requires precise timing measurements.
- Jitter detection ensures data quality (EEG max 100µs, audio max 1µs).
- Synchronization enables closed-loop protocol validation.

API overview
------------
- Timestamp generation functions using DWT or TIM2
- Jitter calculation between samples
- Synchronization point marking
- Latency measurement utilities
- Statistics tracking

Hardware coupling
-----------------
- Uses Cortex-M DWT cycle counter or dedicated timer (TIM2)
- Requires SystemCoreClock variable for µs conversion
- Timer must be configured for continuous counting

Where to look next
------------------
- time_sync.c: Implementation using DWT/TIM2
- eeg_packet_t, audio_packet_t: Structures using timestamps
- neurofeedback_engine.c: Uses synchronization for latency measurement
