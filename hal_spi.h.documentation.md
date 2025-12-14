# hal_spi.h — Detailed reference & maintenance guide

Repository location:
- File: NS/include/layer1_hal/hal_spi.h
- URL: https://github.com/whoIsStella/A_V/blob/main/NS/include/layer1_hal/hal_spi.h

Purpose
-------
Defines the Hardware Abstraction Layer API for SPI (Serial Peripheral Interface) communication. SPI is used for high-speed communication with EEG ADCs and display controllers.

Why this file matters
---------------------
- Primary interface for EEG data acquisition via SPI ADCs
- Supports display communication for visual feedback
- Provides both blocking and DMA-based non-blocking transfers
- Critical for real-time data acquisition performance

Type definitions
---------------

1. spi_mode_t
   - Defines SPI clock polarity (CPOL) and phase (CPHA) combinations
   - MODE_0 (CPOL=0, CPHA=0): Most common, clock idles low, data captured on rising edge
   - MODE_1 (CPOL=0, CPHA=1): Clock idles low, data captured on falling edge
   - MODE_2 (CPOL=1, CPHA=0): Clock idles high, data captured on falling edge
   - MODE_3 (CPOL=1, CPHA=1): Clock idles high, data captured on rising edge
   - Check ADC/display datasheet for required mode

2. spi_datasize_t
   - 8-bit or 16-bit data frame size
   - Most devices use 8-bit mode
   - 16-bit mode reduces overhead for 16-bit data transfers

3. spi_firstbit_t
   - MSB (most significant bit) first: Standard, used by most devices
   - LSB (least significant bit) first: Rare, check device datasheet

4. spi_baudrate_prescaler_t
   - Clock divider: 2, 4, 8, 16, 32, 64, 128, 256
   - Actual baudrate = APB_clock / divider
   - EEG ADCs typically run at 10-20 MHz
   - Displays may run slower (1-10 MHz)

5. spi_config_t
   - Configuration structure passed to hal_spi_init()
   - mode: SPI mode (see above)
   - baudrate: Desired baudrate in Hz (actual will be closest achievable)
   - data_size: 8 or 16 bits
   - first_bit: MSB or LSB first
   - use_hardware_cs: If true, uses hardware NSS pin; if false, manage CS via GPIO
   - enable_dma: If true, enables DMA support for non-blocking transfers

6. spi_handle_t
   - Internal handle structure (opaque to users)
   - Stores configuration, state, DMA handles, callbacks
   - One handle per SPI peripheral (SPI1, SPI2, SPI3)

Public API
----------

1. hal_spi_init(spi_base, config)
   - Initializes SPI peripheral with given configuration
   - Enables clock, configures GPIO pins (SCK, MOSI, MISO, optional NSS)
   - Sets up DMA if enabled
   - Returns STATUS_OK on success

2. hal_spi_deinit(spi_base)
   - Disables SPI peripheral and clock
   - Releases GPIO pins

3. Blocking transfers:
   - hal_spi_transfer_byte(): Single byte, returns received byte
   - hal_spi_transfer(): Full-duplex, can be TX-only or RX-only
   - hal_spi_transmit(): TX-only convenience function
   - hal_spi_receive(): RX-only convenience function
   - All block until transfer completes

4. DMA transfers:
   - hal_spi_transfer_dma(): Starts non-blocking transfer, returns immediately
   - Use callback to know when complete
   - hal_spi_is_busy(): Check if transfer is ongoing
   - hal_spi_wait_ready(): Block until transfer completes (with timeout)

5. hal_spi_set_callback(spi_base, callback)
   - Sets callback for DMA transfer completion
   - Callback runs in interrupt context

Usage patterns
-------------

Blocking transfer (simple, for small/infrequent transfers):
```c
hal_spi_init((void*)SPI1_BASE, &config);
uint8_t rx = hal_spi_transfer_byte((void*)SPI1_BASE, 0xFF);
```

DMA transfer (for high-throughput, non-blocking):
```c
hal_spi_init((void*)SPI1_BASE, &config_with_dma);
hal_spi_set_callback((void*)SPI1_BASE, my_callback);
hal_spi_transfer_dma((void*)SPI1_BASE, tx_buf, rx_buf, 512);
// ... do other work ...
hal_spi_wait_ready((void*)SPI1_BASE, 100);  // Wait max 100ms
```

Integration notes
----------------
- SPI peripherals: SPI1 (APB2), SPI2/SPI3 (APB1)
- APB clock frequencies defined in hardware_config.h
- GPIO pins for SPI must be configured in alternate function mode
- CS/NSS pin: Can use hardware control or manual GPIO for multi-device buses
- For multiple devices on same SPI bus, use GPIO CS and share SCK/MOSI/MISO

Common pitfalls
---------------
- Wrong SPI mode causes garbled data—check device datasheet
- Baudrate too high: Exceeds device max speed, causes errors
- Baudrate too low: Wastes time, may cause buffer overruns in continuous acquisition
- Forgetting to configure GPIO pins for SPI alternate function
- Using hardware CS with multiple devices—requires manual CS via GPIO
- Not checking busy status before starting new DMA transfer

Performance considerations
-------------------------
- Blocking transfers: Simple but tie up CPU
- DMA transfers: Best for large/continuous transfers, frees CPU
- DMA overhead: ~1-2 µs setup time, worthwhile for transfers > 10 bytes
- SPI baudrate: Limited by APB clock and prescaler options
- For EEG at 512 Hz with 20 channels × 24 bits: ~30 KB/s, easily handled by SPI

Porting notes
-------------
- SPI register layout varies by MCU family
- STM32F1/F4/H7 all have similar SPI but different register addresses
- Other vendors (NXP, TI, etc.) require API reimplementation
- Keep API consistent for portability at application level

Where to look next
------------------
- hal_spi.c for implementation details
- eeg_driver.c for SPI usage example with ADC
- hardware_config.h for SPI pin assignments and clock frequencies
- STM32F4 reference manual for detailed SPI register descriptions
This header declares the SPI (Serial Peripheral Interface) Hardware Abstraction Layer for high-speed serial communication with peripherals like EEG ADCs and displays. Provides:
- Master-mode SPI configuration (modes 0-3)
- Blocking and DMA-based transfers
- Configurable data size (8/16-bit), clock polarity/phase, and baud rate
- Full-duplex, transmit-only, and receive-only operations

Why this file matters
---------------------
- SPI is the primary interface for EEG ADC (ADS1299) communication, requiring precise timing and low latency.
- Display updates rely on SPI for framebuffer transfers.
- Incorrect SPI mode or timing breaks communication with ADCs, causing data corruption or no data.
- DMA integration enables continuous high-speed transfers without CPU intervention.

API semantics
-------------

### Configuration types
- **spi_mode_t**: Clock polarity (CPOL) and phase (CPHA) combinations (modes 0-3). ADS1299 typically uses mode 1.
- **spi_datasize_t**: 8-bit or 16-bit transfers. Most peripherals use 8-bit.
- **spi_firstbit_t**: MSB or LSB first. Standard is MSB first.
- **spi_baudrate_prescaler_t**: Clock divider (2, 4, 8, ..., 256). Actual baud rate = APB_CLOCK / divider.
- **spi_config_t**: Complete configuration including mode, baud rate, data size, hardware CS control, DMA enable.
- **spi_handle_t**: Runtime handle containing base address, config, state (busy, initialized), DMA handles, callbacks.

### Initialization
- **hal_spi_init**: Configures SPI peripheral registers, enables clock, sets up GPIO pins (SCK, MISO, MOSI, NSS), optionally configures DMA.
- **hal_spi_deinit**: Disables SPI, releases resources, deconfigures pins.

### Blocking transfers
- **hal_spi_transfer_byte**: Single byte full-duplex transfer. Returns received byte. Useful for command/response protocols.
- **hal_spi_transfer**: Multi-byte full-duplex. Transmit and receive simultaneously. Either buffer can be NULL for unidirectional.
- **hal_spi_transmit**: TX-only, discards received data. Faster for write-only operations.
- **hal_spi_receive**: RX-only, transmits dummy bytes. Used for reading data from ADC.

### DMA transfers
- **hal_spi_transfer_dma**: Non-blocking DMA transfer. Returns immediately, callback invoked on completion.
- **hal_spi_is_busy**: Check if transfer in progress.
- **hal_spi_wait_ready**: Block until transfer complete with timeout.
- **hal_spi_set_callback**: Register callback for DMA completion or error.

Hardware couplings
------------------
- **GPIO configuration**: SCK, MISO, MOSI, NSS pins must be configured as alternate function (see hal_gpio.h). Pin assignments in hardware_config.h.
- **Clock source**: SPI1/4/5/6 on APB2, SPI2/3 on APB1. Baud rate depends on APB clock frequency.
- **DMA mapping**: Each SPI has dedicated DMA streams/channels (consult STM32F407 reference manual). EEG SPI typically uses DMA2_Stream0 (RX) and DMA2_Stream3 (TX).
- **NSS management**: Hardware CS (use_hardware_cs=true) or manual GPIO control for multi-slave setups.

Usage patterns
--------------

**EEG ADC initialization:**
```c
spi_config_t eeg_spi_cfg = {
    .mode = SPI_MODE_1,          // CPOL=0, CPHA=1 for ADS1299
    .baudrate = 8000000,         // 8 MHz
    .data_size = SPI_DATASIZE_8BIT,
    .first_bit = SPI_FIRSTBIT_MSB,
    .use_hardware_cs = false,    // Manual CS for command sequences
    .enable_dma = true           // DMA for continuous streaming
};
hal_spi_init((void*)SPI1_BASE, &eeg_spi_cfg);
```

**Reading EEG samples with DMA:**
```c
static uint8_t rx_buffer[512];
hal_spi_receive_dma((void*)SPI1_BASE, rx_buffer, 512);
// Callback invoked when complete
```

Threading & ISR considerations
-------------------------------
- Blocking functions (hal_spi_transfer, hal_spi_transmit, hal_spi_receive) poll status register. Don't call from ISRs.
- DMA callbacks run in ISR context. Keep short, set flags or enqueue data.
- Multiple SPI peripherals can operate concurrently if using separate instances.
- Protect shared SPI resources with critical sections if multiple contexts access same peripheral.

Debugging tips
--------------
- **No communication**: Verify pin configuration (AF mode, correct SPI pins), check clock enable, verify slave device powered.
- **Garbage data**: Wrong SPI mode, incorrect baud rate (too fast for slave), or bit order mismatch.
- **DMA not working**: Ensure DMA handles configured correctly, callbacks registered, and SPI DMA enable bits set (TXDMAEN/RXDMAEN in SPI_CR2).
- **Timing issues**: Use logic analyzer to verify clock frequency and timing vs. slave requirements.

Common pitfalls
---------------
- Using blocking transfers in high-frequency loops causes CPU starvation.
- Not checking hal_spi_is_busy before starting new transfer causes STATUS_BUSY or data corruption.
- Hardware CS doesn't work with multi-slave buses; use manual GPIO CS control.
- DMA requires properly aligned buffers (4-byte for word transfers).
- Forgetting to configure DMA streams in hardware_config.h causes initialization failure.

Porting notes
-------------
- Register offsets and bit definitions are STM32F4-specific.
- Other STM32 families (F7, H7) have similar SPI but may add features (FIFO, TI mode).
- Non-STM32 MCUs require complete rewrite targeting their SPI controller architecture.

Where to look next
------------------
- hal_spi.c: Implementation of these API functions.
- hal_dma.h: DMA configuration used by SPI transfers.
- hardware_config.h: SPI pin assignments and DMA stream mappings.
- eeg_driver.c: Example SPI usage for ADC communication.
- STM32F407 Reference Manual RM0090: Chapter 28 (SPI).
