# hal_i2s.c — Detailed reference & maintenance guide

Repository location:
- File: NS/src/layer1_hal/hal_i2s.c
- URL: https://github.com/whoIsStella/A_V/blob/main/NS/src/layer1_hal/hal_i2s.c

Purpose
-------
Implements the I2S (Inter-IC Sound) Hardware Abstraction Layer for STM32F4. Provides digital audio interface for high-quality audio I/O with audio codecs. Note that I2S is implemented using SPI peripherals in I2S mode on STM32F4.

Why this file matters
---------------------
- Critical for glitch-free audio output in neurofeedback system
- Manages precise audio sample timing (e.g., 48 kHz)
- Supports DMA for zero-CPU audio streaming
- Incorrect configuration causes audio artifacts or silence

Implementation details
---------------------

1. Hardware register definitions
   - I2S uses SPI peripheral registers plus I2S-specific registers
   - I2S_I2SCFGR: I2S configuration (mode, standard, data format)
   - I2S_I2SPR: I2S prescaler for sample rate generation
   - Shared registers: CR2 (DMA enable), SR (status), DR (data)
   - Important: Set I2SMOD bit to enable I2S mode (vs. SPI mode)

2. Private variables
   - g_i2s_handles[2]: Static array for I2S2 and I2S3 handles
   - STM32F4: I2S2 and I2S3 available (SPI2/SPI3 in I2S mode)
   - Stores configuration, state, DMA handles, callbacks

3. Helper functions
   - get_i2s_handle(i2s_base): Maps base address to handle
   - enable_i2s_clock(i2s_base): Enables RCC clock for I2S peripheral
   - calculate_prescaler(audio_freq, i2sdiv, odd): Computes prescaler values

4. Prescaler calculation
   - Formula: Fs = I2SxCLK / [256 * ((2 * I2SDIV) + ODD)]
   - I2SxCLK typically derived from PLL (e.g., 84 MHz)
   - 256 factor assumes 16-bit stereo (16 bits × 2 channels × 8 MCLKs)
   - ODD bit: Fine-tunes frequency for exact sample rate
   - I2SDIV range: 2-255

5. hal_i2s_init()
   - Validates base address and configuration
   - Enables I2S clock via RCC
   - Configures GPIO pins (WS, CK, SD, optional MCLK) for I2S alternate function
   - Sets I2SCFGR register:
     * CHLEN: Channel length (16 or 32 bits)
     * DATLEN: Data length (16, 24, or 32 bits)
     * CKPOL: Clock polarity (normally low)
     * I2SSTD: Standard (Philips, MSB, LSB, PCM)
     * I2SCFG: Mode (master TX/RX, slave TX/RX, full duplex)
     * I2SMOD: Set to 1 to enable I2S mode
   - Calculates and sets prescaler (I2SPR register)
   - Enables MCLK output if requested
   - Sets up DMA channels if enabled
   - Enables I2S peripheral (I2SE bit)

6. hal_i2s_transmit_dma() / hal_i2s_receive_dma()
   - Configures TX or RX DMA channel
   - Links DMA to I2S DR register
   - Enables I2S DMA request (TXDMAEN or RXDMAEN in CR2)
   - Starts DMA transfer
   - Returns immediately (non-blocking)

7. hal_i2s_transceive_dma() (full-duplex)
   - Uses main I2S peripheral for TX
   - Uses extended I2S (I2Sxext) for RX
   - Both share same clock
   - Requires careful synchronization

8. Control functions
   - hal_i2s_stop_tx/rx(): Disables I2S and stops DMA
   - hal_i2s_pause(): Disables I2S without stopping DMA (can resume quickly)
   - hal_i2s_resume(): Re-enables I2S
   - hal_i2s_is_busy(): Checks BSY flag in SR register

9. Interrupt handling
   - DMA callbacks: Transfer complete, half-transfer, error
   - Callbacks run in interrupt context
   - Typical pattern: Half-transfer callback signals buffer switch
   - Application processes one buffer while DMA fills the other

Register configuration patterns
------------------------------

I2SCFGR register:
- Master TX mode: I2SCFG = 10b
- Philips standard: I2SSTD = 00b
- 24-bit data on 32-bit frame: DATLEN = 10b, CHLEN = 1
- Enable: I2SE = 1, I2SMOD = 1

I2SPR register:
- For 48 kHz from 84 MHz clock: I2SDIV ≈ 6, ODD = 1
- MCKOE = 1 to output master clock (for codec PLL)

CR2 register:
- TXDMAEN: Enable TX DMA
- RXDMAEN: Enable RX DMA

GPIO configuration
-----------------
I2S pins (typically):
- I2S2: PB12=WS, PB13=CK, PB15=SD, PC6=MCLK
- I2S3: PA15=WS, PC10=CK, PC12=SD, PC7=MCLK
- Configure as alternate function AF5 or AF6
- Set high speed for clean signals

DMA integration
--------------
- TX DMA: Memory-to-peripheral, writes to I2S_DR
- RX DMA: Peripheral-to-memory, reads from I2S_DR
- Circular mode for continuous streaming
- Double-buffering via half-transfer interrupt
- Priority: High (audio glitches audible if starved)

Sample rate accuracy
-------------------
- Depends on I2S clock source accuracy
- PLL-derived clocks: ±100 ppm typical
- Crystal oscillators: ±50 ppm typical
- Some codecs have internal PLL and can slave to MCLK
- For critical applications, use external crystal for I2S clock

Common pitfalls
---------------
- Wrong I2S standard: Codec and MCU must match (Philips vs. MSB/LSB)
- Incorrect prescaler: Wrong sample rate, pitch shift
- Missing MCLK: Some codecs require master clock for internal PLL
- DMA buffer underrun: Processing too slow, causes audio glitches (pops/clicks)
- Not configuring GPIO AF: No signals on pins
- Wrong channel length: 16-bit data on 16-bit frame vs. 32-bit frame
- Starting I2S before codec ready: Codec may not sync

Audio quality considerations
----------------------------
- Jitter: Keep interrupt latency low to minimize timing jitter
- DMA priority: Set high to prevent underruns
- Buffer size: Balance latency (small) vs. robustness (large)
- Typical: 128-512 samples @ 48 kHz = 2.67-10.67 ms latency
- Sample rate: 48 kHz standard, higher rates for pro audio

Full-duplex operation
---------------------
- Uses I2S2 (TX) + I2S2ext (RX), or I2S3 + I2S3ext
- Extended I2S shares clock with main I2S
- Both use same prescaler
- Synchronous operation guaranteed
- Requires two DMA channels (one for TX, one for RX)

Debugging tips
-------------
- Check I2S clock with oscilloscope (should match sample rate × 64 or × 256)
- Verify WS (word select) toggles at sample rate
- Check SD (serial data) has activity
- Use logic analyzer to decode I2S protocol
- Monitor DMA transfer count to detect underruns
- Listen for pops/clicks indicating buffer issues

Performance notes
----------------
- I2S data transfer: DMA-based, zero CPU overhead
- Interrupt overhead: ~1-2 µs per callback
- Prescaler calculation: ~10 µs (done once at init)
- Audio latency: Dominated by buffer size, not processing

Porting considerations
---------------------
- STM32F4: I2S implemented via SPI peripherals
- STM32F1: Limited I2S support, check availability
- STM32H7: Dedicated SAI (Serial Audio Interface) preferred over I2S
- STM32L4: Similar I2S to F4
- Other MCUs: May have dedicated I2S hardware or require external I2S codec

Where to look next
------------------
- hal_i2s.h for API documentation
- audio_driver.c for usage example
- Audio codec datasheet for I2S timing requirements
- STM32F4 reference manual for I2S/SPI register details
- AN3998: STM32 I2S audio application note
