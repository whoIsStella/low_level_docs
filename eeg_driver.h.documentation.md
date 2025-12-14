# eeg_driver.h — Detailed reference & maintenance guide

Repository location:
- File: NS/include/layer2_drivers/eeg_driver.h
- URL: https://github.com/whoIsStella/A_V/blob/main/NS/include/layer2_drivers/eeg_driver.h

Purpose
-------
Provides high-level EEG ADC driver interface. Manages SPI communication with multi-channel EEG ADC (e.g., ADS1299) and handles continuous data acquisition via DMA.

Why this file matters
---------------------
- Primary interface for brain signal acquisition
- Manages timing-critical sample acquisition (512 Hz)
- Handles multi-channel data formatting and quality assessment
- Critical for real-time neurofeedback performance

Expected functionality
---------------------
- EEG ADC initialization via SPI (register configuration)
- Start/stop continuous acquisition
- Configure sample rate, channel count, gain
- Manage data ready (DRDY) interrupt
- Provide ring buffer interface for EEG packets
- Electrode impedance measurement
- Lead-off detection

Typical API functions:
- eeg_driver_init(): Initialize ADC and SPI interface
- eeg_driver_start_acquisition(): Begin continuous sampling
- eeg_driver_stop_acquisition(): Stop sampling
- eeg_driver_read_samples(): Get samples from ring buffer
- eeg_driver_set_channel_gain(): Configure per-channel gain
- eeg_driver_measure_impedance(): Measure electrode impedance

ADC considerations (e.g., ADS1299):
- 24-bit resolution per channel
- Up to 8 channels simultaneous
- SPI interface for data and configuration
- DRDY signal indicates new sample available
- Sample rate: 250/500/512/1000 Hz configurable

Integration notes
----------------
- Uses hal_spi for ADC communication
- Uses hal_gpio for DRDY interrupt
- Uses hal_dma for bulk data transfer
- Outputs eeg_packet_t to eeg_processor via ring_buffer

Performance requirements
-----------------------
- Must read all channels within sample period (1953 µs @ 512 Hz)
- SPI transfer: 24 bits × 8 channels = 192 bits = 24 bytes
- At 10 MHz SPI: ~2.4 µs transfer time
- Leaves ~1900 µs for processing

Where to look next
------------------
- hal_spi.h for SPI HAL interface
- eeg_processor.h for data processing
- ADS1299 datasheet for register configuration

Purpose
-------
Declares high-level EEG driver for ADS1299 ADC via SPI. Manages multi-channel data acquisition, buffering, and quality monitoring.

Why this file matters
---------------------
- Abstracts ADS1299 command protocol complexity
- Manages continuous data acquisition via SPI DMA
- Provides electrode quality monitoring
- Handles sample rate configuration and synchronization

API overview
------------
- eeg_driver_init: Initialize ADS1299 via SPI commands
- eeg_driver_start/stop: Start/stop continuous acquisition
- eeg_driver_set_callback: Register data-ready callback
- eeg_driver_get_packet: Retrieve latest EEG sample
- eeg_driver_check_quality: Get electrode impedance quality

Configuration
-------------
- Channel count, sample rate, gain, bias settings
- Lead-off detection for electrode quality
- Test signal generation for validation

Where to look next
------------------
- eeg_driver.c: Implementation
- hal_spi.h: SPI communication
- ADS1299 datasheet: Register map and commands
