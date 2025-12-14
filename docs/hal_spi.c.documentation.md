# hal_spi.c — Detailed reference & maintenance guide

Repository location:
- File: NS/src/layer1_hal/hal_spi.c
- URL: https://github.com/whoIsStella/A_V/blob/main/NS/src/layer1_hal/hal_spi.c

Purpose
-------
Implements the SPI (Serial Peripheral Interface) Hardware Abstraction Layer for STM32F4. Provides both blocking and DMA-based SPI communication for EEG ADCs and display controllers.

Why this file matters
---------------------
- Critical for EEG data acquisition from SPI-based ADCs (e.g., ADS1299)
- Enables display communication for visual feedback
- Supports high-speed transfers with DMA for real-time performance
- Incorrect SPI timing or configuration causes data corruption

Implementation details
---------------------

1. Hardware register definitions
   - Maps STM32F4 SPI peripheral registers (SPI1/SPI2/SPI3)
   - SPI1 on APB2 bus, SPI2/SPI3 on APB1 bus (different clock domains)
   - Registers: CR1 (control 1), CR2 (control 2), SR (status), DR (data)
   - Bit definitions for mode, phase, polarity, frame format, interrupts

2. Private variables
   - g_spi_handles[3]: Static array storing state for up to 3 SPI peripherals
   - Each handle includes configuration, DMA handles, callbacks, and status

3. Helper functions
   - get_spi_handle(spi_base): Maps base address to handle (SPI1/2/3)
   - enable_spi_clock(spi_base): Enables RCC clock for specified SPI peripheral
   - calculate_prescaler(spi_base, baudrate): Determines closest achievable baudrate prescaler
   - configure_spi_gpio(spi_base): Sets GPIO pins (SCK, MOSI, MISO, NSS) to alternate function mode

4. hal_spi_init()
   - Validates base address and configuration
   - Enables SPI and GPIO clocks
   - Configures GPIO pins for SPI alternate function
   - Disables SPI before configuration
   - Sets CR1: master mode, clock polarity/phase, baudrate prescaler, frame format
   - Sets CR2: DMA enable bits if requested
   - Enables SPI peripheral (SPE bit)
   - Initializes DMA if enabled
   - Returns STATUS_OK on success

5. hal_spi_transfer_byte()
   - Waits for TXE (transmit empty) flag
   - Writes byte to DR register
   - Waits for RXNE (receive not empty) flag
   - Reads and returns received byte
   - Simple but blocks CPU

6. hal_spi_transfer() / hal_spi_transmit() / hal_spi_receive()
   - Blocking transfer functions
   - Loop through buffer, transferring byte-by-byte
   - Check busy status and wait for completion
   - Suitable for small transfers or initialization

7. hal_spi_transfer_dma()
   - Sets up TX and RX DMA channels
   - Enables SPI DMA requests (TXDMAEN, RXDMAEN in CR2)
   - Starts both DMA transfers simultaneously
   - Returns immediately (non-blocking)
   - Callback fires when complete

8. Status functions
   - hal_spi_is_busy(): Checks BSY flag in SR register
   - hal_spi_wait_ready(): Polls BSY flag with timeout

Register manipulation
--------------------
- CR1 configuration: Must disable SPI (clear SPE) before changing most settings
- Master mode: Set MSTR bit
- Clock: CPOL and CPHA bits define SPI mode
- Baudrate: BR[2:0] bits set prescaler (2, 4, 8, 16, 32, 64, 128, 256)
- DMA: Enable TXDMAEN and RXDMAEN in CR2
- Status flags: TXE (TX empty), RXNE (RX not empty), BSY (busy)

GPIO configuration
-----------------
- SPI pins must be configured as alternate function (AF5 for SPI1/2/3 on STM32F4)
- SCK: Clock output (push-pull, high speed)
- MOSI: Master out, slave in (push-pull, high speed)
- MISO: Master in, slave out (input, pull-up optional)
- NSS: Chip select (can be manual GPIO or hardware controlled)

DMA integration
--------------
- TX DMA: Memory-to-peripheral, writes to SPI DR register
- RX DMA: Peripheral-to-memory, reads from SPI DR register
- Both must be configured and started for full-duplex transfers
- For TX-only: Still need RX DMA to drain RX FIFO (or dummy reads)
- Callbacks fire in interrupt context

Common pitfalls
---------------
- Wrong SPI mode (CPOL/CPHA): Causes phase shift, garbled data
- Baudrate too high: Exceeds device max speed
- Not configuring GPIO alternate function: No signals on pins
- Forgetting to manage CS pin: Multiple devices conflict
- DMA buffer alignment: Some devices require word-aligned buffers
- Not checking busy before starting new transfer

Porting notes
-------------
- STM32F1: Similar SPI but different GPIO configuration (no AF selection)
- STM32H7: Additional FIFO settings, different DMA channels
- Other MCUs: Register layouts vary significantly
- Keep API stable for portability

Performance considerations
-------------------------
- Blocking transfers: Simple but tie up CPU, ~1 µs per byte overhead
- DMA transfers: ~2 µs setup, then zero CPU, best for > 10 bytes
- SPI clock: Limited by APB clock and prescaler, typical 10-20 MHz for EEG ADCs
- GPIO slew rate: Set to high speed for clean signals at MHz rates

Where to look next
------------------
- hal_spi.h for API documentation
- eeg_driver.c for practical usage example
- hal_dma.c for DMA implementation details
- STM32F4 reference manual for register descriptions
- ADC datasheet for SPI timing requirements
Implements the SPI Hardware Abstraction Layer declared in hal_spi.h. Provides register-level control of STM32F4 SPI peripherals for communication with EEG ADCs, displays, and other SPI devices.

Implementation overview
-----------------------
- Configures SPI control registers (CR1, CR2) for mode, baud rate, data size.
- Enables RCC clocks for SPI peripherals.
- Implements polling-based blocking transfers using status register (SR) flags.
- Integrates with hal_dma for non-blocking transfers.
- Manages callbacks for asynchronous transfer completion.
- Handles timeout and error conditions.

Key functions
-------------

**hal_spi_init**:
- Enables SPI clock in RCC (APB1ENR or APB2ENR depending on SPI number).
- Configures CR1: master mode, baud rate prescaler, CPOL/CPHA, data size, bit order.
- Configures CR2: DMA enables (TXDMAEN, RXDMAEN), NSS management, frame format.
- Configures GPIO pins as AF mode (requires hal_gpio.h).
- If DMA enabled, configures DMA streams using hal_dma_init.
- Enables SPI peripheral (SPE bit in CR1).

**hal_spi_transfer_byte**:
- Wait for TXE (transmit buffer empty).
- Write byte to data register (DR).
- Wait for RXNE (receive buffer not empty).
- Read and return received byte.
- Timeout handling to prevent infinite loops.

**hal_spi_transfer**:
- Loop over length, calling transfer_byte for each.
- Supports NULL tx_buffer (sends 0xFF) or NULL rx_buffer (discards received data).
- Returns STATUS_OK or STATUS_TIMEOUT.

**hal_spi_transmit**:
- Similar to transfer but only transmits, discards RX data.
- Optimized by not reading DR after RXNE.

**hal_spi_receive**:
- Transmits dummy bytes (0xFF) and reads received data.
- Used for peripherals that generate data after dummy clocks.

**hal_spi_transfer_dma**:
- Configures DMA TX stream with source = tx_buffer, destination = SPI_DR.
- Configures DMA RX stream with source = SPI_DR, destination = rx_buffer.
- Enables SPI DMA requests (TXDMAEN, RXDMAEN in CR2).
- Starts DMA streams.
- Returns immediately; callbacks invoked on completion.

**hal_spi_is_busy**:
- Checks BSY flag in status register.
- Also checks DMA transfer status if DMA enabled.

**hal_spi_wait_ready**:
- Polls hal_spi_is_busy with timeout.
- Returns STATUS_OK when ready or STATUS_TIMEOUT.

**hal_spi_set_callback**:
- Stores callback function pointer in handle.
- Callback invoked from DMA ISR when transfer completes.

Hardware details
----------------
- **SPI registers**: CR1 (control 1), CR2 (control 2), SR (status), DR (data).
- **CR1 bits**: SPE (enable), BIDIMODE, CRCEN, DFF (data frame format), RXONLY, SSM (software slave management), SSI, LSBFIRST, BR (baud rate), MSTR (master), CPOL, CPHA.
- **CR2 bits**: TXDMAEN, RXDMAEN, SSOE, FRF, ERRIE, RXNEIE, TXEIE.
- **SR flags**: TXE (TX empty), RXNE (RX not empty), BSY (busy), OVR (overrun), MODF (mode fault), CRCERR, FRE (frame error).
- **Baud rate**: fPCLK / (2, 4, 8, 16, 32, 64, 128, 256). Calculate prescaler based on desired baud and APB clock.

Error handling
--------------
- **Overrun (OVR)**: RX buffer not read in time. Clear by reading DR and SR.
- **Mode fault (MODF)**: NSS pulled low in master mode. Clear by reading SR and writing CR1.
- **CRC error**: Mismatch in hardware CRC (if enabled). Read SR to clear.
- **Timeout**: Function returns STATUS_TIMEOUT if operation doesn't complete. Caller should reset SPI or handle error.

Debugging tips
--------------
- Use oscilloscope or logic analyzer to verify clock frequency and data integrity.
- Check that APB clock matches expected frequency (affects baud rate calculation).
- Verify GPIO pins are correctly configured (AF mode, speed, pull resistors).
- For DMA issues, check DMA stream enable, channel selection, and interrupt enables.
- Enable error interrupts (ERRIE in CR2) to catch hardware faults.

Common pitfalls
---------------
- Not waiting for BSY flag to clear before disabling SPI causes incomplete transfers.
- Reading DR while TXE=0 or RXNE=0 causes undefined behavior.
- DMA buffer alignment must match transfer size (word transfers need 4-byte alignment).
- Changing configuration while SPI enabled (SPE=1) may corrupt state; disable first.
- Not handling OVR flag in high-speed RX causes data loss.

Maintenance checklist
---------------------
- [ ] Verify register addresses match current MCU.
- [ ] Test all SPI modes (0-3) with target peripherals.
- [ ] Validate baud rate calculation against APB clock.
- [ ] Test timeout values under worst-case conditions.
- [ ] Verify DMA integration with both TX and RX streams.
- [ ] Test error recovery (OVR, MODF).

Where to look next
------------------
- hal_spi.h: API documentation.
- hal_dma.c: DMA transfer implementation.
- eeg_driver.c: Real-world SPI usage example.
- STM32F407 Reference Manual RM0090: Chapter 28 (SPI).
