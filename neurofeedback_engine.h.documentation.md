# neurofeedback_engine.h — Detailed reference & maintenance guide

Repository location:
- File: NS/include/layer5_application/neurofeedback_engine.h
- URL: https://github.com/whoIsStella/A_V/blob/main/NS/include/layer5_application/neurofeedback_engine.h

Purpose
-------
Core neurofeedback control logic that integrates EEG processing and audio modulation. Implements the brain-to-audio feedback loop with protocol-specific algorithms.

Why this file matters
---------------------
- Implements the therapeutic neurofeedback protocol
- Translates brain state into audio parameter changes
- Manages training session flow and state
- Critical for achieving desired therapeutic outcomes

Expected functionality
---------------------
- Initialize neurofeedback session with protocol parameters
- Continuously process EEG features
- Generate audio modulation commands
- Manage training thresholds and adaptation
- Track session metrics and progress
- Handle state transitions (calibration, training, rest)

Typical API functions:
- neurofeedback_init(): Initialize engine with protocol
- neurofeedback_set_protocol(): Select training protocol
- neurofeedback_start_session(): Begin training session
- neurofeedback_process(): Main processing loop (called periodically)
- neurofeedback_get_state(): Get current state
- neurofeedback_get_metrics(): Get session metrics

Neurofeedback protocols (examples):
- Alpha enhancement: Increase alpha band power
- SMR training: Increase 12-15 Hz sensorimotor rhythm
- Alpha asymmetry: Balance left/right frontal alpha
- Theta/beta ratio: ADHD protocol

Control loop:
1. Read EEG features from eeg_processor
2. Compare to target thresholds
3. Compute modulation strength (reward/inhibit)
4. Generate modulation commands for audio_processor
5. Update thresholds based on performance
6. Log metrics

Integration notes
----------------
- Receives eeg_features_t from eeg_processor
- Sends modulation_command_t to audio_processor
- Uses time_sync for latency monitoring
- Target latency: <250ms brain-to-audio

Where to look next
------------------
- eeg_processor.h for input features
- audio_processor.h for modulation API
- main.c for system integration

Purpose
-------
Declares the top-level neurofeedback control engine integrating EEG processing, protocol execution, and audio modulation command generation.

Why this file matters
---------------------
- Implements closed-loop brain-computer interface logic
- Maps EEG features to audio modulation parameters
- Manages neurofeedback protocol state machine
- Ensures target latency (<250ms brain-to-audio)
- Coordinates all processing layers

API overview
------------
- neurofeedback_init: Initialize engine with protocol configuration
- neurofeedback_update: Main update loop (called periodically)
- neurofeedback_set_protocol: Select and configure protocol
- neurofeedback_get_state: Query current state and metrics
- neurofeedback_calibrate: Run baseline calibration phase

Protocol types
--------------
- Alpha enhancement: Increase alpha power → increase volume/pleasantness
- Alpha suppression: Decrease alpha power → modulate audio
- SMR (sensorimotor rhythm) training
- Custom protocols with user-defined mappings

Processing flow
---------------
1. Receive EEG features from eeg_processor
2. Apply protocol-specific mapping (feature → modulation)
3. Generate modulation commands with ramp parameters
4. Send commands to audio_processor
5. Track latency and performance metrics
6. Update protocol state (calibration, training, rest)

Where to look next
------------------
- neurofeedback_engine.c: Implementation
- eeg_processor.h: Feature extraction
- audio_processor.h: Modulation application
- main.c: Integration and scheduling
