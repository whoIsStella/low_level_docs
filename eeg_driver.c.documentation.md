# eeg_driver.c — Detailed reference & maintenance guide

Repository location:
- File: NS/src/layer2_drivers/eeg_driver.c
- URL: https://github.com/whoIsStella/A_V/blob/main/NS/src/layer2_drivers/eeg_driver.c

Purpose
-------
Implements the EEG ADC driver for continuous multi-channel brain signal acquisition. Manages SPI communication, DMA transfers, and data formatting.

Why this file matters
---------------------
- Critical path for real-time EEG data acquisition
- Handles timing-sensitive ADC readout
- Manages data quality and lead-off detection
- Incorrect implementation causes data loss or corruption

Implementation details (typical)
-------------------------------
1. Initialization:
   - Configure SPI peripheral (mode, speed)
   - Configure GPIO for CS and DRDY pins
   - Write ADC configuration registers
   - Set channel count, gain, sample rate
   - Enable internal reference
   - Start conversion

2. DRDY interrupt handler:
   - Triggered when new sample available
   - Assert CS low
   - Initiate SPI DMA transfer (read 24 bits × N channels)
   - Deassert CS when complete
   - Convert 24-bit samples to 32-bit sign-extended
   - Pack into eeg_packet_t
   - Write to ring buffer

3. Register configuration:
   - CONFIG1: Sample rate selection
   - CONFIG2: Test signal, reference
   - CONFIG3: Bias settings
   - CHnSET: Per-channel gain, power down, input selection
   - LOFF: Lead-off detection parameters

4. Data formatting:
   - ADC outputs 24-bit two's complement
   - Convert to 32-bit sign-extended integer
   - Store with timestamp and channel quality

5. Quality assessment:
   - Check lead-off status
   - Detect saturation (min/max values)
   - Compute per-channel quality metric (0-100)

Common pitfalls
---------------
- DRDY timing: Must read within sample period or data lost
- SPI mode mismatch: Wrong CPOL/CPHA causes garbled data
- Forgetting sign extension: Positive values interpreted as negative
- Not checking lead-off: Collecting invalid data
- Buffer overflow: Ring buffer too small for processing latency

Integration notes
----------------
- Uses hal_spi_transfer_dma() for efficient readout
- Uses time_sync for packet timestamping
- Outputs to ring_buffer_t for eeg_processor consumption
- DRDY interrupt priority: Must be high to prevent missed samples

Where to look next
------------------
- eeg_driver.h for API documentation
- hal_spi.c for SPI implementation
- ADS1299 datasheet for register details
- eeg_processor.c for data consumption

Purpose
-------
Implements ADS1299 EEG ADC driver using SPI HAL. Handles register configuration, continuous data acquisition, and data parsing.

Implementation details
----------------------
- Sends SPI commands for register read/write (RREG, WREG)
- Configures sample rate (SPS), PGA gain, input mux
- Enables lead-off detection for quality monitoring
- Starts continuous data read mode (RDATAC)
- DMA circular mode transfers raw ADC data
- Parses 24-bit samples from SPI data stream
- Converts to eeg_packet_t format with quality metrics

Key functions
-------------
- eeg_driver_init: Reset ADC, configure registers, setup SPI DMA
- eeg_driver_start_acquisition: Send START command, enable RDATAC
- SPI DMA callback: Parse samples, assemble eeg_packet_t, invoke user callback
- Quality monitoring: Read LOFF_STATP/N registers for lead-off detection

ADS1299 specifics
-----------------
- 24-bit ADC, 8 channels, up to 16kSPS
- SPI mode 1 (CPOL=0, CPHA=1)
- Commands: WAKEUP, STANDBY, RESET, START, STOP, RDATAC, SDATAC, RDATA, RREG, WREG
- Data format: 24-bit samples MSB-first, preceded by status bytes
- Lead-off detection: AC or DC excitation, configurable thresholds

Where to look next
------------------
- eeg_driver.h: API documentation
- hal_spi.c: SPI implementation
- ADS1299 datasheet: Complete register and timing specifications
