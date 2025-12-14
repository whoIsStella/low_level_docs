# hal_dma.c — Detailed reference & maintenance guide

Repository location:
- File: NS/src/layer1_hal/hal_dma.c
- URL: https://github.com/whoIsStella/A_V/blob/main/NS/src/layer1_hal/hal_dma.c

Purpose
-------
This file implements the DMA (Direct Memory Access) Hardware Abstraction Layer for STM32F4 microcontrollers. It provides:
- DMA stream initialization and configuration
- Circular and normal DMA transfer modes
- Double-buffering (ping-pong) support
- Interrupt-driven completion callbacks
- Transfer management (start, stop, abort)
- Status and remaining transfer count queries

Why this file matters
---------------------
- DMA is critical for zero-copy data streaming from SPI (EEG) and I2S (audio) peripherals.
- Incorrect configuration causes data corruption, system hangs, or hard faults.
- Timing-sensitive transfers (audio at 48 kHz) require precise DMA operation without CPU intervention.
- Circular mode with double-buffering enables continuous streaming without data loss.

Implementation details
----------------------

### Hardware register definitions
The file defines STM32F4-specific constants:
- RCC_AHB1ENR_DMA1EN/DMA2EN: Clock enable bits.
- DMA1_BASE, DMA2_BASE: Controller base addresses (0x40026000, 0x40026400).
- Stream register offsets: CR (control), NDTR (count), PAR (peripheral addr), M0AR/M1AR (memory addrs), FCR (FIFO).
- Interrupt registers: LISR/HISR (status), LIFCR/HIFCR (clear flags).
- Bit definitions for control register: enable, interrupts, circular, double-buffer, priority, channel selection.

### Private helper functions
- **get_stream_cr/ndtr/par/m0ar/m1ar**: Compute register addresses for a given stream.
  - Stream base = DMA_BASE + 0x10 + (stream * 0x18): Each stream has 24-byte (0x18) register block.
- **get_isr_register/get_ifcr_register**: Select low or high interrupt register based on stream number.
  - Streams 0-3 use LISR/LIFCR, streams 4-7 use HISR/HIFCR.
- **get_flag_offset**: Maps stream number to bit offset in interrupt register.
  - Pattern: [0, 6, 16, 22] repeated twice for 8 streams.
- **enable_dma_clock**: Enables RCC clock for DMA1 or DMA2 and adds stabilization delay.

### Public API implementation

**hal_dma_init(dma_handle_t* handle)**
- Validates handle parameters (stream 0-7, channel 0-7).
- Enables DMA controller clock via RCC.
- Disables stream (waits for EN bit to clear with timeout).
- Clears all interrupt flags for the stream.
- Configures control register:
  - Channel selection (CHSEL bits 25-27).
  - Priority (PL bits 16-17): 0=low, 1=medium, 2=high, 3=very high.
  - Data sizes (MSIZE, PSIZE): 0=byte, 1=halfword, 2=word.
  - Increment modes for memory and peripheral.
  - Direction: 0=periph-to-mem, 1=mem-to-periph, 2=mem-to-mem.
  - Circular mode (CIRC bit).
  - Double-buffer mode (DBM bit).
  - Interrupt enables (TCIE, HTIE, TEIE).
- Configures NVIC interrupt with priority based on usage (EEG/audio higher priority than display).
- Returns STATUS_OK or error code.

**hal_dma_configure_transfer(dma_handle_t* handle, ...)**
- Sets peripheral address (PAR register).
- Sets memory address(es): M0AR for single buffer, M0AR/M1AR for double-buffer.
- Sets transfer count (NDTR).
- Validates alignment: memory and peripheral addresses must be aligned to data size.
  - Word transfers require 4-byte alignment.
- Returns STATUS_INVALID_PARAM if alignment fails.

**hal_dma_start(dma_handle_t* handle)**
- Enables stream by setting EN bit in control register.
- DMA begins transferring data immediately.
- Returns STATUS_OK.

**hal_dma_stop(dma_handle_t* handle)**
- Clears EN bit.
- Waits for stream to actually stop (EN bit clears).
- Returns STATUS_TIMEOUT if stream doesn't stop within timeout period.

**hal_dma_abort(dma_handle_t* handle)**
- Immediately disables stream without waiting.
- Clears all interrupt flags.
- Used for emergency shutdown or error recovery.

**hal_dma_get_status(dma_handle_t* handle)**
- Reads interrupt status register (ISR).
- Checks for transfer complete (TCIF), half-transfer (HTIF), transfer error (TEIF), FIFO error (FEIF).
- Returns corresponding status code.

**hal_dma_get_remaining_count(dma_handle_t* handle)**
- Reads NDTR register (remaining data count).
- Useful for progress monitoring and synchronization.

**hal_dma_get_current_target(dma_handle_t* handle)**
- Reads CT bit in control register.
- Returns 0 or 1 indicating which memory buffer is active in double-buffer mode.
- CPU should process the inactive buffer while DMA fills the active one.

**hal_dma_irq_handler(dma_handle_t* handle)**
- Called from actual IRQ handler (DMA1_Stream0_IRQHandler, etc.).
- Reads interrupt flags.
- Clears flags by writing to IFCR.
- Invokes registered callbacks:
  - transfer_complete_callback: Full transfer done or buffer switched in circular mode.
  - half_transfer_callback: Half of buffer filled (useful for double-buffering).
  - transfer_error_callback: Error occurred (wrong address, bus error, FIFO overrun).

Hardware couplings
------------------
- **RCC (Reset and Clock Control)**: DMA clock must be enabled before use. Register at RCC_BASE + 0x30.
- **NVIC**: Each DMA stream has dedicated IRQ line (DMA1_Stream0_IRQn through DMA2_Stream7_IRQn).
- **Peripheral request mapping**: DMA channel selection (0-7) maps to peripheral (e.g., SPI1_RX = channel 3 on certain streams). Consult STM32F407 reference manual Table 28.
- **Memory alignment**: Word (32-bit) transfers require 4-byte aligned addresses. Violating alignment causes hardware fault.

Threading & ISR considerations
-------------------------------
- DMA interrupt handlers run at hardware IRQ priority. Keep handlers short.
- Callbacks invoked from ISR context must be ISR-safe:
  - No blocking, no FreeRTOS calls (unless using FromISR variants).
  - Set flags or enqueue data; defer processing to main loop or lower-priority task.
- Ring buffer write indices typically updated in DMA ISR; read indices updated in main loop (SPSC pattern).
- For multi-channel DMA (e.g., multiple SPI devices), ensure each uses separate stream.

Debugging tips
--------------
- **DMA not starting**: Check that peripheral is also configured correctly and generating DMA requests.
- **DMA stops after one transfer**: Verify circular mode is enabled if continuous operation is needed.
- **Data corruption**: Check alignment, verify NDTR matches actual buffer size, ensure CPU doesn't access buffer during DMA transfer.
- **Transfer error interrupt**: Enable TEIE and check callback. Common cause: bus contention or illegal address.
- **Half-transfer interrupt not firing**: Ensure buffer size is even and HTIE is set.
- **Double-buffer mode issues**: Verify M1AR is set, DBM bit is set, and callbacks properly switch processing.

Porting to other MCUs
----------------------
- **STM32F7/H7**: Register layout similar but may have additional fields (burst mode, FIFO threshold). Update bit definitions.
- **Different vendor**: Complete rewrite. DMA architectures vary significantly (channels vs streams, descriptor-based vs register-based).
- **Non-STM32 Cortex-M**: Check if MCU has DMA or requires alternative (e.g., DMAC on SAMD51).

Safety & testing
----------------
- Always validate return status from hal_dma_init and hal_dma_start.
- Test abort functionality by triggering during active transfer and verifying clean shutdown.
- Verify callbacks fire at expected times using GPIO toggle or logic analyzer.
- Test with misaligned buffers (should return STATUS_INVALID_PARAM).
- Stress test with maximum transfer rates to detect timing issues.

Common pitfalls
---------------
- Forgetting to enable peripheral request (SPI_CR2_TXDMAEN, I2S_CR2_RXDMAEN, etc.) means DMA never starts.
- Using normal mode for continuous streaming causes single-shot behavior.
- Not clearing interrupt flags in ISR causes immediate re-entry (interrupt storm).
- Accessing buffer while DMA is writing causes race conditions and corruption.
- Setting wrong channel for peripheral causes DMA to never trigger.

Maintenance checklist
---------------------
- [ ] Verify register offsets match current MCU reference manual
- [ ] Test all callback paths (TC, HT, TE)
- [ ] Validate alignment checks for byte/halfword/word sizes
- [ ] Confirm priority settings match system requirements
- [ ] Test timeout values are adequate for slowest expected operation
- [ ] Document any MCU-specific quirks or errata workarounds

Where to look next
------------------
- hal_dma.h: Public API and dma_handle_t structure definition.
- hal_spi.c, hal_i2s.c: Users of DMA for peripheral transfers.
- hardware_config.h: DMA stream/channel assignments for EEG and audio.
- STM32F407 Reference Manual RM0090: Chapter 10 (DMA controller).
- startup.c: DMA interrupt vector definitions (DMA1_Stream0_IRQHandler, etc.).
