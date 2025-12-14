# audio_driver.c — Detailed reference & maintenance guide

Repository location:
- File: NS/src/layer2_drivers/audio_driver.c

Purpose
-------
Implements audio driver interfacing with I2S codec via HAL, managing buffering and synchronization.

Implementation details
----------------------
- Initializes CS43L22 or similar I2C-controlled codec
- Configures I2S for 48kHz, 24-bit stereo
- Sets up DMA circular mode with double-buffering
- Implements callback routing from I2S ISR to application
- Handles volume control via codec I2C interface

Key functions
-------------
- audio_driver_init: Codec I2C init, I2S configuration, DMA setup
- audio_driver_start: Enable I2S and DMA transfer
- I2S callback handlers: Route to application, manage buffer pointers
- Volume control: Send I2C commands to codec

Where to look next
------------------
- audio_driver.h: API documentation
- hal_i2s.c: I2S implementation
- hal_dma.c: DMA implementation
