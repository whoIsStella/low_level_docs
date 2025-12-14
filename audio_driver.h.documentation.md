# audio_driver.h — Detailed reference & maintenance guide

Repository location:
- File: NS/include/layer2_drivers/audio_driver.h
- URL: https://github.com/whoIsStella/A_V/blob/main/NS/include/layer2_drivers/audio_driver.h

Purpose
-------
Provides high-level audio codec driver interface. Manages I2S communication, DMA buffering, and audio format configuration for neurofeedback audio output.

Why this file matters
---------------------
- Abstracts audio codec hardware details
- Manages double-buffering for glitch-free playback
- Handles sample rate and format configuration
- Critical for low-latency audio output (<10ms)

Expected functionality
---------------------
- Audio codec initialization (I2C configuration + I2S data)
- Start/stop audio streaming
- Set volume, sample rate, bit depth
- Provide ring buffer interface for audio samples
- Handle I2S DMA interrupts for buffer management

Typical API functions:
- audio_driver_init(): Initialize codec and I2S interface
- audio_driver_start(): Begin audio streaming
- audio_driver_stop(): Stop streaming
- audio_driver_write_samples(): Write to output ring buffer
- audio_driver_set_volume(): Control output volume
- audio_driver_get_buffer_level(): Check buffer fill level

Double-buffering pattern:
- Two DMA buffers (ping-pong)
- While DMA outputs buffer A, application fills buffer B
- Half-transfer interrupt signals buffer switch
- Prevents buffer underruns

Integration notes
----------------
- Uses hal_i2s for digital audio interface
- Uses hal_dma for zero-CPU transfers
- Provides ring_buffer interface to audio_processor
- Sample rate: 48 kHz typical (defined in hardware_config.h)

Where to look next
------------------
- hal_i2s.h for I2S HAL interface
- audio_processor.h for audio processing
- Audio codec datasheet for configuration details
