# audio_processor.h — Detailed reference & maintenance guide

Repository location:
- File: NS/include/layer4_processing/audio_processor.h
- URL: https://github.com/whoIsStella/A_V/blob/main/NS/include/layer4_processing/audio_processor.h

Purpose
-------
Processes audio signals for neurofeedback modulation. Applies EEG-driven effects such as volume modulation, filtering, and spectral modifications based on brain state.

Why this file matters
---------------------
- Implements the audio output side of the neurofeedback loop
- Translates EEG features into audio parameter changes
- Ensures smooth, artifact-free modulation
- Critical for achieving therapeutic neurofeedback effects

Expected functionality
---------------------
- Volume/gain modulation based on EEG band power
- Frequency-selective filtering (EQ) controlled by brain state
- Spectral warping or emphasis
- Smooth parameter ramping to avoid audible clicks
- Latency-optimized processing (<10ms audio path)

API functions (typical):
- audio_processor_init(): Initialize processor
- audio_processor_set_modulation(): Apply EEG-based modulation
- audio_processor_process_block(): Process audio samples
- audio_processor_set_volume(): Set output volume
- audio_processor_apply_eq(): Apply equalization

Integration notes
----------------
- Receives audio from audio_driver (I2S input)
- Applies modulation based on eeg_features from eeg_processor
- Outputs to audio_driver (I2S output)
- Uses fft_engine for spectral processing if needed

Performance requirements
-----------------------
- Must process audio block in < block_size / sample_rate time
- Example: 128 samples @ 48kHz = 2.67ms processing budget
- Includes FFT (if used), filtering, modulation, and smoothing

Where to look next
------------------
- neurofeedback_engine.h for overall system integration
- audio_driver.h for audio I/O interface
- eeg_processor.h for EEG feature extraction

Purpose
-------
Declares audio signal processing module for real-time audio analysis and modulation. Provides:
- Spectral analysis (FFT-based)
- Audio quality metrics (RMS, peak, THD)
- EQ and filtering
- Dynamic range processing
- Modulation parameter application

Why this file matters
---------------------
- Implements neurofeedback audio modulation based on EEG state
- Ensures audio quality while applying brain-controlled effects
- Real-time constraints require efficient DSP algorithms
- Modulation must be perceptually smooth (no clicks/pops)

API overview
------------
- audio_processor_init: Initialize with sample rate and buffer size
- audio_processor_process_block: Process audio buffer (main function)
- audio_processor_set_modulation: Apply EEG-driven parameter changes
- audio_processor_get_features: Extract audio quality metrics
- audio_processor_apply_eq: Frequency-selective gain adjustment

Key processing stages
---------------------
1. Input buffering and format conversion
2. Spectral analysis (FFT)
3. Feature extraction (RMS, THD, spectrum)
4. Modulation application (volume, EQ, saturation)
5. Output formatting and buffering

Where to look next
------------------
- audio_processor.c: Implementation
- fft_engine.h: FFT computations
- audio_driver.c: Audio I/O
- neurofeedback_engine.c: Modulation command generation
