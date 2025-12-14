# fft_engine.h — Detailed reference & maintenance guide

Repository location:
- File: NS/include/layer4_processing/fft_engine.h
- URL: https://github.com/whoIsStella/A_V/blob/main/NS/include/layer4_processing/fft_engine.h

Purpose
-------
Provides Fast Fourier Transform (FFT) functionality for frequency-domain analysis of EEG and audio signals. Critical for extracting frequency band powers from EEG data and audio spectrum analysis.

Why this file matters
---------------------
- Converts time-domain signals to frequency domain for analysis
- Enables EEG band power calculation (Delta, Theta, Alpha, Beta, Gamma)
- Provides audio spectrum analysis for feedback visualization
- Performance-critical: FFT must complete within sample period

Implementation approach
----------------------
Likely uses an optimized FFT library such as:
- ARM CMSIS-DSP library (optimized for Cortex-M)
- KISS FFT (simple, portable)
- Custom radix-2 FFT implementation

Key features expected:
- Power-of-2 FFT sizes (128, 256, 512, 1024, 2048)
- Real FFT optimizations (input is real-valued, not complex)
- In-place computation to minimize memory usage
- Window functions (Hanning, Hamming) to reduce spectral leakage
- Magnitude spectrum computation

API functions (typical):
- fft_init(): Initialize FFT engine with size
- fft_compute_real(): Perform real-valued FFT
- fft_compute_magnitude(): Compute magnitude spectrum
- fft_apply_window(): Apply windowing function
- fft_get_bin_frequency(): Convert bin number to frequency in Hz

Performance considerations
-------------------------
- FFT complexity: O(N log N) where N is FFT size
- 512-point FFT: ~5000-10000 cycles (~50-100 µs @ 100 MHz)
- Must complete before next EEG sample arrives (~1953 µs)
- CMSIS-DSP optimizations: SIMD instructions, loop unrolling

Integration notes
----------------
- Used by: eeg_processor for band power calculation
- Used by: audio_processor for spectrum analysis
- FFT sizes defined in system_config.h (FFT_SIZE_EEG, FFT_SIZE_AUDIO)
- Window overlap: Configured in system_config.h (FFT_OVERLAP)

Common applications
------------------
- EEG frequency band analysis (0.5-50 Hz)
- Audio spectrum for visualization
- Real-time spectrogram generation
- Harmonic analysis

Where to look next
------------------
- eeg_processor.h for FFT usage in EEG analysis
- audio_processor.h for audio spectrum analysis
- CMSIS-DSP documentation for optimization details
Declares Fast Fourier Transform engine for frequency-domain analysis of EEG and audio signals. Provides:
- FFT computation (512-point for EEG, 2048-point for audio)
- Power spectrum calculation
- Windowing functions (Hann, Hamming, Blackman)
- Band power extraction for EEG frequency bands
- Real-time optimization for embedded constraints

Why this file matters
---------------------
- FFT is core to extracting EEG band powers (delta, theta, alpha, beta, gamma) for neurofeedback.
- Audio spectrum analysis enables frequency-selective modulation.
- Fixed-point or optimized floating-point implementations critical for real-time performance.
- Window selection affects spectral leakage and frequency resolution.

API overview
------------
- fft_init: Initialize FFT engine with configuration (size, window type)
- fft_compute: Perform FFT on input buffer, output magnitude spectrum
- fft_compute_power_spectrum: FFT + magnitude calculation
- fft_extract_band_power: Sum power in frequency range
- fft_extract_eeg_bands: Calculate all EEG bands in one call

Configuration
-------------
- FFT_SIZE_EEG (512) from system_config.h
- FFT_SIZE_AUDIO (2048) from system_config.h
- Uses ARM CMSIS-DSP library for optimized FFT (arm_cfft_f32)
- Requires buffer alignment for SIMD operations

Performance considerations
--------------------------
- 512-point FFT: ~10k cycles on Cortex-M4 with FPU
- 2048-point FFT: ~50k cycles
- At 168MHz, 512-point FFT takes ~60µs
- Must complete within sample period (EEG: 1953µs, audio: 10.7ms per 512 samples)

Where to look next
------------------
- fft_engine.c: Implementation using CMSIS-DSP
- eeg_processor.c: Uses FFT for band power extraction
- audio_processor.c: Uses FFT for spectral analysis
- system_config.h: FFT size definitions and band limits
