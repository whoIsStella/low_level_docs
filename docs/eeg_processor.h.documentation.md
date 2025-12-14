# eeg_processor.h — Detailed reference & maintenance guide

Repository location:
- File: NS/include/layer4_processing/eeg_processor.h
- URL: https://github.com/whoIsStella/A_V/blob/main/NS/include/layer4_processing/eeg_processor.h

Purpose
-------
Extracts meaningful features from raw EEG signals. Computes frequency band powers (Delta, Theta, Alpha, Beta, Gamma) and derived metrics for neurofeedback control.

Why this file matters
---------------------
- Converts raw EEG voltage samples into actionable brain state metrics
- Calculates band powers used to drive audio modulation
- Implements artifact rejection and quality assessment
- Performance-critical: Must keep up with 512 Hz EEG sample rate

Expected functionality
---------------------
- FFT-based frequency band power extraction
- Alpha asymmetry calculation (left vs. right hemisphere)
- Artifact detection (eye blinks, muscle activity)
- Signal quality assessment
- Temporal smoothing to reduce noise

Typical API functions:
- eeg_processor_init(): Initialize processor
- eeg_processor_add_sample(): Add new EEG sample
- eeg_processor_compute_features(): Compute band powers and features
- eeg_processor_get_alpha_power(): Get alpha band power
- eeg_processor_get_quality(): Get signal quality metric

EEG bands (defined in system_config.h):
- Delta: 0.5-4 Hz (deep sleep)
- Theta: 4-8 Hz (meditation, drowsiness)
- Alpha: 8-13 Hz (relaxed, eyes closed)
- Beta: 13-30 Hz (active thinking, focus)
- Gamma: 30-50 Hz (high-level cognition)

Processing pipeline:
1. Buffer EEG samples (512 points for 1-second window @ 512 Hz)
2. Apply window function (Hanning) to reduce spectral leakage
3. Compute FFT (512-point)
4. Sum power in each frequency band
5. Normalize by total power
6. Apply temporal smoothing
7. Output eeg_features_t structure

Performance requirements
-----------------------
- Must process EEG window in < sample_period (1953 µs for 512 Hz)
- FFT computation: ~50-100 µs
- Band power summation: ~10 µs
- Total budget: <200 µs per sample

Integration notes
----------------
- Receives eeg_packet_t from eeg_driver via ring_buffer
- Uses fft_engine for frequency analysis
- Outputs eeg_features_t to neurofeedback_engine
- Quality metrics used for gating feedback

Where to look next
------------------
- fft_engine.h for FFT implementation
- neurofeedback_engine.h for feature usage
- eeg_driver.h for data acquisition
- common_types.h for eeg_features_t definition

Purpose
-------
Declares EEG signal processing module for extracting brain state features. Provides:
- Band power extraction (delta, theta, alpha, beta, gamma)
- Artifact detection and rejection
- Alpha asymmetry calculation
- Feature normalization and smoothing
- Quality assessment

Why this file matters
---------------------
- Extracts neurofeedback-relevant features from raw EEG
- Band powers drive audio modulation decisions
- Artifact rejection prevents false detections
- Alpha asymmetry indicates emotional/cognitive states
- Quality metrics ensure reliable measurements

API overview
------------
- eeg_processor_init: Initialize with configuration
- eeg_processor_process_packet: Process single EEG packet
- eeg_processor_extract_features: Compute EEG features from buffer
- eeg_processor_get_band_powers: Get current band power values
- eeg_processor_get_quality: Get signal quality metrics

Processing pipeline
-------------------
1. Input validation and quality check
2. Artifact detection (amplitude thresholds, gradient checks)
3. FFT computation (512-point)
4. Band power extraction (integrate spectrum in band ranges)
5. Alpha asymmetry calculation (left-right frontal alpha difference)
6. Feature smoothing (moving average/exponential smoothing)
7. Normalization (z-score or baseline division)

Where to look next
------------------
- eeg_processor.c: Implementation
- fft_engine.h: FFT operations
- eeg_driver.c: Raw EEG data source
- neurofeedback_engine.c: Feature consumer
