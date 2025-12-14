# hal_i2s.h — Detailed reference & maintenance guide

Repository location:
- File: NS/include/layer1_hal/hal_i2s.h
- URL: https://github.com/whoIsStella/A_V/blob/main/NS/include/layer1_hal/hal_i2s.h

Purpose
-------
Defines the Hardware Abstraction Layer API for I2S (Inter-IC Sound) digital audio interface. I2S is the standard for high-quality digital audio transmission between audio codecs and processors.

Why this file matters
---------------------
- Primary interface for digital audio I/O with audio codecs
- Supports stereo audio with 16/24/32-bit samples at various sample rates
- Critical for low-latency neurofeedback audio output
- DMA-based operation ensures glitch-free audio streaming

Type definitions
---------------

1. i2s_mode_t
   - MASTER_TX: MCU generates clock and transmits audio
   - MASTER_RX: MCU generates clock and receives audio
   - SLAVE_TX/RX: External device generates clock
   - MASTER_FULL_DUPLEX: Simultaneous TX and RX (uses main I2S + extended I2S)

2. i2s_standard_t
   - I2S_STANDARD_PHILIPS: Standard I2S protocol (most common)
   - MSB/LSB justified: Alternative alignment standards
   - PCM_SHORT/LONG: For PCM/TDM protocols

3. i2s_dataformat_t
   - 16B: 16-bit data on 16-bit frame (compact)
   - 16B_EXTENDED: 16-bit data on 32-bit frame (compatibility)
   - 24B: 24-bit data on 32-bit frame (high quality)
   - 32B: 32-bit data on 32-bit frame (maximum precision)

4. i2s_audiofreq_t
   - Standard audio sample rates: 8k, 16k, 22.05k, 32k, 44.1k, 48k, 96k, 192k Hz
   - Neurofeedback system typically uses 48 kHz for balance of quality and processing load

5. i2s_config_t
   - mode: Operating mode (see above)
   - standard: Protocol standard (typically Philips)
   - data_format: Sample bit depth
   - audio_freq: Sample rate
   - cpol: Clock polarity (LOW=normal)
   - mclk_output: Enable master clock (MCLK) for external codec PLL
   - enable_dma: Use DMA for transfers (always recommended)

6. i2s_handle_t
   - Stores configuration, state, DMA handles, callbacks
   - i2s_base: Main I2S peripheral (actually an SPI peripheral in I2S mode)
   - i2s_ext_base: Extended I2S for full-duplex (separate RX path)

Public API
----------

1. hal_i2s_init(i2s_base, config)
   - Initializes I2S peripheral with configuration
   - Calculates and sets prescalers for desired sample rate
   - Configures GPIO pins (WS, CK, SD, optionally MCLK)
   - Sets up DMA channels for TX and/or RX
   - Returns STATUS_OK on success

2. hal_i2s_deinit(i2s_base)
   - Stops transfers and disables I2S
   - Releases GPIO and DMA resources

3. DMA transfer functions:
   - hal_i2s_transmit_dma(): Start audio output (non-blocking)
   - hal_i2s_receive_dma(): Start audio input (non-blocking)
   - hal_i2s_transceive_dma(): Start full-duplex operation
   - All accept buffer pointer and size (in samples, not bytes)

4. Control functions:
   - hal_i2s_stop_tx/rx(): Stop transmission or reception
   - hal_i2s_pause/resume(): Temporarily halt/resume without stopping DMA
   - hal_i2s_is_busy(): Check if transfer is ongoing

5. hal_i2s_set_callbacks()
   - Sets callbacks for RX complete, TX complete, and errors
   - Half-transfer callbacks also available for double-buffering
   - Callbacks run in interrupt context—must be fast

Integration notes
----------------
- I2S is implemented using SPI peripherals in I2S mode (STM32F4)
- Full-duplex mode uses two SPI peripherals: main + extended (e.g., SPI2 + I2S2ext)
- Requires precise clock configuration for standard audio sample rates
- PLL or dedicated I2S clock source ensures accurate sample rates
- MCLK output: Some codecs require 256× or 384× master clock for internal PLL

Buffer management
----------------
- Double-buffering recommended for continuous playback
- Half-transfer interrupt allows processing one buffer while DMA fills the other
- Buffer size: Balance latency vs. overhead (typically 128-2048 samples)
- Circular DMA mode: Automatic restart for continuous streaming

Common pitfalls
---------------
- Sample rate inaccuracy: Check actual clock vs. desired rate
- Wrong I2S standard: Codec and MCU must match (Philips vs. MSB/LSB)
- Buffer underrun: Processing too slow, causes audio glitches
- Buffer overrun: Not reading fast enough, causes data loss
- GPIO not configured: No clock or data on pins
- Forgetting MCLK: Some codecs require it for internal clock generation

Audio quality considerations
----------------------------
- 16-bit: Good quality, lower processing load
- 24-bit: High quality, typical for professional audio
- 32-bit: Maximum precision, rarely needed for neurofeedback
- 48 kHz: Standard for digital audio, good balance
- 96 kHz+: High resolution, higher processing load

Performance notes
-----------------
- DMA-based I2S: Zero CPU for data transfer
- Interrupt overhead: ~1-2 µs per callback (half-transfer, transfer-complete)
- Latency: Buffer size / sample rate (e.g., 128 samples @ 48kHz = 2.67ms)
- For neurofeedback target of 250ms end-to-end, I2S latency is negligible

Porting notes
-------------
- STM32F4: I2S implemented via SPI peripherals
- STM32H7: Dedicated SAI (Serial Audio Interface) preferred over I2S
- Other STM32: Check if SPI supports I2S mode
- Other vendors: May have dedicated I2S or SAI peripherals

Where to look next
------------------
- audio_driver.c for I2S usage example
- hal_dma.c for DMA implementation details
- Audio codec datasheet for I2S timing and configuration
- STM32F4 reference manual for I2S/SPI register details
This header declares the I2S (Inter-IC Sound) Hardware Abstraction Layer for high-quality digital audio I/O with external codecs. Provides:
- Stereo audio streaming (16/24/32-bit samples)
- Master and slave modes
- Multiple audio standards (Philips I2S, MSB/LSB justified, PCM)
- DMA-based continuous streaming
- Full-duplex operation (simultaneous TX/RX)
- Standard audio frequencies (8kHz to 192kHz)

Why this file matters
---------------------
- I2S is the primary interface for audio codec communication, requiring sample-accurate timing.
- Neurofeedback latency (<250ms) depends on efficient I2S streaming without buffer underruns/overruns.
- 24-bit audio format matches codec requirements and provides high dynamic range.
- DMA integration enables real-time audio processing without CPU intervention.
- Full-duplex mode allows simultaneous audio input (monitoring) and output (modulated audio).

API semantics
-------------

### Configuration types
- **i2s_mode_t**: Master TX/RX, slave TX/RX, or full-duplex. NS uses master mode.
- **i2s_standard_t**: Philips I2S standard (default), MSB/LSB justified, PCM short/long frame.
- **i2s_dataformat_t**: 16-bit, 16-bit extended, 24-bit, or 32-bit data formats. System uses 24-bit.
- **i2s_audiofreq_t**: Standard frequencies from 8kHz to 192kHz. System uses 48kHz.
- **i2s_cpol_t**: Clock polarity (low/high). Typically low for Philips standard.
- **i2s_config_t**: Complete configuration including mode, standard, format, frequency, MCLK enable, DMA enable.
- **i2s_handle_t**: Runtime handle with peripheral base addresses (I2S and extended I2S for full-duplex), DMA handles, state flags, callbacks.

### Initialization
- **hal_i2s_init**: Configures I2S peripheral (actually uses SPI in I2S mode on STM32), enables clocks, sets up GPIO, configures DMA if enabled.
- **hal_i2s_deinit**: Disables I2S, stops DMA, releases resources.

### DMA operations
- **hal_i2s_transmit_dma**: Start continuous TX using DMA. Buffer contains audio samples (count is samples, not bytes).
- **hal_i2s_receive_dma**: Start continuous RX using DMA.
- **hal_i2s_transceive_dma**: Full-duplex operation with separate TX and RX buffers.
- **hal_i2s_stop_tx / hal_i2s_stop_rx**: Stop transmission or reception.
- **hal_i2s_pause / hal_i2s_resume**: Pause/resume streaming without reinitialization.

### Callbacks
- **hal_i2s_set_callbacks**: Register callbacks for RX complete, TX complete, RX half-complete, TX half-complete, and errors.
- Half-complete callbacks enable double-buffering: process one half while DMA fills the other.

### Status
- **hal_i2s_is_busy**: Check if transfer in progress.

Hardware couplings
------------------
- **SPI/I2S peripheral**: STM32F4 I2S uses SPI hardware in I2S mode. I2S2, I2S3 available (I2S1 not on all devices).
- **Extended I2S**: For full-duplex, uses I2S2ext/I2S3ext (extended peripheral sharing pins).
- **GPIO pins**: SD (serial data), CK (serial clock), WS (word select/LRCK), optionally MCK (master clock).
- **Clock configuration**: I2S PLL (PLLI2S) provides clock. Must be configured in system init to generate exact audio frequencies.
- **DMA mapping**: I2S has dedicated DMA streams. E.g., I2S3_RX on DMA1_Stream0, I2S3_TX on DMA1_Stream7.

Usage patterns
--------------

**Audio codec initialization:**
```c
i2s_config_t audio_i2s_cfg = {
    .mode = I2S_MODE_MASTER_FULL_DUPLEX,
    .standard = I2S_STANDARD_PHILIPS,
    .data_format = I2S_DATAFORMAT_24B,  // 24-bit on 32-bit frame
    .audio_freq = I2S_AUDIOFREQ_48K,
    .cpol = I2S_CPOL_LOW,
    .mclk_output = true,        // 256*Fs for codec
    .enable_dma = true
};
hal_i2s_init((void*)SPI3_BASE, &audio_i2s_cfg);
```

**Double-buffered streaming:**
```c
static int32_t tx_buffer[2][1024];  // Ping-pong buffers
static int32_t rx_buffer[2][1024];
static volatile uint8_t active_half = 0;

void i2s_half_complete_cb(void) {
    // Process inactive half
    process_audio(tx_buffer[1 - active_half], rx_buffer[1 - active_half], 1024);
}

void i2s_complete_cb(void) {
    active_half = 1 - active_half;
    // Process other half
    process_audio(tx_buffer[active_half], rx_buffer[active_half], 1024);
}

hal_i2s_set_callbacks((void*)SPI3_BASE, i2s_complete_cb, i2s_half_complete_cb, error_cb);
hal_i2s_transceive_dma((void*)SPI3_BASE, tx_buffer[0], rx_buffer[0], 2048);  // Total samples
```

Threading & ISR considerations
-------------------------------
- Callbacks invoked from DMA ISR at high priority. Keep processing minimal.
- Audio processing in callbacks must complete before next half-transfer to avoid underrun/overrun.
- At 48kHz with 1024-sample buffer, half-complete callback fires every ~10.7ms.
- Use ring buffers to decouple I2S callbacks from processing tasks if needed.

Debugging tips
--------------
- **No audio output**: Check PLLI2S configuration, verify GPIO AF settings, ensure codec reset/power.
- **Distorted audio**: Wrong data format, incorrect clock frequency, or buffer alignment issue.
- **Underrun/overrun**: Processing in callbacks takes too long. Reduce processing or use larger buffers.
- **DMA not triggering**: Verify I2S DMA enable bits, check DMA stream/channel configuration.
- Use oscilloscope to verify I2S clock frequency matches expected (e.g., 48kHz * 64 = 3.072MHz bit clock).

Common pitfalls
---------------
- Buffer size (samples) vs. byte count confusion. API uses sample count, but DMA configuration uses bytes.
- Forgetting to configure PLLI2S results in incorrect audio frequency.
- Master clock (MCK) required by some codecs; forgetting mclk_output=true causes no audio.
- Extended I2S for full-duplex shares pins; incorrect pin configuration causes conflicts.
- Not using double-buffering causes audio glitches due to processing delays.

Porting notes
-------------
- STM32F7/H7 have enhanced I2S with deeper FIFOs and additional features.
- Other MCU families (NXP, Microchip) have different I2S implementations (SAI, I2SC). Requires architecture-specific rewrite.
- Some MCUs have dedicated I2S peripherals separate from SPI.

Where to look next
------------------
- hal_i2s.c: Implementation details.
- hal_dma.h: DMA configuration for I2S transfers.
- audio_driver.c: High-level audio driver using I2S HAL.
- hardware_config.h: I2S pin and DMA assignments.
- STM32F407 Reference Manual RM0090: Chapter 28 (SPI/I2S).
