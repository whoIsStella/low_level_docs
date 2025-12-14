# NS Production Testing & Debugging Guide

## Overview

This document provides comprehensive instructions for testing, running, and debugging the NS embedded system for production deployment on FreeBSD kernel (RTOS or Superloop architecture).

## Table of Contents

1. [Development Environment Setup](#development-environment-setup)
2. [Build System](#build-system)
3. [Testing Strategy](#testing-strategy)
4. [Hardware Testing](#hardware-testing)
5. [Debugging Procedures](#debugging-procedures)
6. [Performance Validation](#performance-validation)
7. [Production Deployment](#production-deployment)
8. [Troubleshooting](#troubleshooting)

---

## Development Environment Setup

### Required Tools

#### ARM Toolchain
```bash
# Install ARM GCC toolchain
sudo apt-get install gcc-arm-none-eabi

# Verify installation
arm-none-eabi-gcc --version
```

#### Build Tools
```bash
# Install build essentials
sudo apt-get install build-essential make

# Install debugging tools
sudo apt-get install openocd gdb-multiarch

# Install serial terminal
sudo apt-get install screen picocom minicom
```

#### Optional Tools
```bash
# Static analysis
sudo apt-get install cppcheck clang-tidy

# Code coverage
sudo apt-get install gcov lcov

# Performance profiling
sudo apt-get install valgrind
```

### Hardware Requirements

- **Target Board**: STM32F407VGT6 or compatible
- **Debug Probe**: ST-Link V2/V3 or J-Link
- **EEG Frontend**: ADS1299 19-channel EEG ADC
- **Audio Codec**: CS43L22 or compatible I2S codec
- **USB Connection**: For debugging and data logging
- **Power Supply**: 5V, minimum 1A

---

## Build System

### Quick Start

```bash
# Navigate to project directory
cd NS

# Build firmware (ARM target)
make

# Build and run host tests
make test

# Clean build artifacts
make clean

# Show available targets
make help
```

### Build Targets

| Target | Description |
|--------|-------------|
| `make` or `make all` | Build embedded firmware |
| `make test` | Build and run unit tests on host |
| `make flash` | Flash firmware to target via OpenOCD |
| `make debug` | Start GDB debugging session |
| `make openocd` | Start OpenOCD server |
| `make size` | Show memory usage |
| `make disasm` | Generate disassembly listing |
| `make symbols` | Generate symbol table |
| `make clean` | Remove build artifacts |

### Build Configuration

Edit `include/config/system_config.h` to configure:
- RTOS vs Superloop mode (`ENABLE_RTOS`)
- Debug features (`DEBUG_ENABLE`)
- Performance counters
- Buffer sizes
- Feature flags (USB, Bluetooth, Display, SD card logging)

---

## Testing Strategy

### Layer-by-Layer Testing Approach

The NS system uses a 6-layer architecture. Test from bottom to top:

#### 1. Layer 0: Bare Metal / Boot
**Test**: System boots and enters main()
```bash
# Flash minimal firmware with just startup code
make clean && make MINIMAL=1
make flash
# Check via serial console for boot message
```

#### 2. Layer 1: Hardware Abstraction Layer (HAL)
**Tests**:
- GPIO toggle (LED blink)
- Timer accuracy (measure with oscilloscope)
- DMA transfers
- SPI communication (loopback test)
- I2S audio output (tone generation)

**Validation**:
```c
// tests/test_hal.c
bool test_gpio_toggle(void);
bool test_timer_accuracy(void);
bool test_dma_transfer(void);
bool test_spi_loopback(void);
bool test_i2s_tone_output(void);
```

#### 3. Layer 2: Device Drivers
**Tests**:
- EEG driver initialization
- EEG data acquisition (check sample rate)
- Audio codec configuration
- Audio playback and recording

**Validation**:
```bash
# Run driver integration tests
make test_drivers
```

#### 4. Layer 3: Data Structures
**Tests**: (Already implemented in `tests/test_all.c`)
- Ring buffer operations
- Time synchronization accuracy
- Memory allocation patterns

**Run**:
```bash
make test
# Should see: Ring Buffer, Time Sync tests PASS
```

#### 5. Layer 4: Signal Processing
**Tests**: (Already implemented in `tests/test_all.c`)
- FFT accuracy (sine wave test)
- EEG band power calculation
- Audio RMS calculation

**Run**:
```bash
make test
# Should see: FFT, EEG Processor, Audio Processor tests PASS
```

#### 6. Layer 5: Application
**Tests**:
- Neurofeedback engine state machine
- End-to-end latency measurement (EEG → Audio)
- Real-time performance under load

---

## Hardware Testing

### Pre-Deployment Checklist

#### Power Supply Test
- [ ] Measure 3.3V rail stability (< 50mV ripple)
- [ ] Measure 5V rail current consumption
- [ ] Test voltage drop under full load
- [ ] Verify reverse polarity protection

#### EEG Frontend Test
- [ ] SPI communication with ADS1299
- [ ] Register read/write verification
- [ ] Continuous data acquisition at 512 Hz
- [ ] Electrode impedance measurement
- [ ] Noise floor measurement (< 1 µVrms)
- [ ] Input common-mode rejection (> 90 dB)

#### Audio System Test
- [ ] I2S codec initialization
- [ ] DAC output signal quality (THD < 0.1%)
- [ ] ADC input signal quality
- [ ] Full-duplex operation
- [ ] Sample rate accuracy (48 kHz ±0.1%)

#### Timing Test
- [ ] System clock accuracy (168 MHz ±0.01%)
- [ ] EEG sample period jitter (< 100 µs)
- [ ] Audio sample period jitter (< 1 µs)
- [ ] Neurofeedback loop latency (< 250 ms target)

#### Memory Test
- [ ] SRAM integrity test
- [ ] CCM-RAM functionality
- [ ] Flash write/erase cycles
- [ ] Stack usage profiling (no overflow)
- [ ] Heap fragmentation analysis

### Hardware Test Commands

```bash
# 1. Flash test firmware
make test_hardware
make flash

# 2. Connect serial console (115200 baud)
screen /dev/ttyUSB0 115200

# 3. You should see:
# [INIT] Initializing hardware...
# [TEST] GPIO Test: PASS
# [TEST] Timer Test: PASS
# [TEST] DMA Test: PASS
# ...

# 4. Observe LED patterns:
# - Solid ON: Boot successful
# - Slow blink (1 Hz): Normal operation
# - Fast blink (10 Hz): Error condition
# - Rapid flash: Critical fault
```

---

## Debugging Procedures

### Serial Debugging (Basic)

```bash
# Connect to serial console
screen /dev/ttyUSB0 115200

# Look for debug output:
# [INIT] System initialization...
# [ERROR] descriptions
# [WARNING] descriptions
# [INFO] status updates
```

### OpenOCD + GDB Debugging (Advanced)

#### Terminal 1: Start OpenOCD
```bash
cd NS
make openocd

# Should see:
# Info : stlink_usb_init_mode: SWIM init failed
# Info : Listening on port 3333 for gdb connections
```

#### Terminal 2: Start GDB
```bash
cd NS
make debug

# Or manually:
arm-none-eabi-gdb build/NS.elf

# GDB commands:
(gdb) target remote localhost:3333
(gdb) monitor reset halt
(gdb) load
(gdb) break main
(gdb) continue
```

### Common Debug Commands

```gdb
# Reset and halt
monitor reset halt

# Continue execution
continue

# Single step
step
next

# Breakpoints
break main
break hal_timer_init
break HardFault_Handler

# Examine memory
x/32xw 0x20000000  # View 32 words of RAM
x/s 0x08000000     # View string at address

# Examine registers
info registers
print $pc
print $sp

# Examine variables
print g_eeg_driver
print g_audio_driver
print g_nf_engine

# Backtrace
backtrace

# Watch variables
watch g_eeg_driver.sample_count
```

### Debugging Common Issues

#### System Won't Boot
```gdb
# Check if code is loaded
x/32xw 0x08000000

# Check vector table
x/32xw 0x08000000

# Check stack pointer
print/x $sp

# Break at reset handler
break Reset_Handler
monitor reset halt
continue
```

#### Hard Fault
```gdb
# Break on hard fault
break HardFault_Handler

# When hit, examine fault registers
print/x *(uint32_t*)0xE000ED28  # CFSR
print/x *(uint32_t*)0xE000ED2C  # HFSR
print/x *(uint32_t*)0xE000ED30  # DFSR
print/x *(uint32_t*)0xE000ED34  # MMFAR
print/x *(uint32_t*)0xE000ED38  # BFAR
```

#### Buffer Overflow/Underflow
```gdb
# Check ring buffer state
print g_eeg_rb
print g_audio_rb

# Watch buffer writes
watch g_eeg_rb.write_index
watch g_audio_rb.write_index

# Check buffer usage
print ring_buffer_usage_percent(&g_eeg_rb)
```

#### Timing Issues
```c
// Add performance markers in code
performance_marker_t marker;
time_sync_start_measure(&marker);
// ... code to measure ...
uint32_t elapsed = time_sync_end_measure(&marker);
printf("Elapsed: %u us\n", elapsed);
```

---

## Performance Validation

### Real-Time Performance Metrics

| Metric | Target | Critical | How to Measure |
|--------|--------|----------|----------------|
| EEG Sample Rate | 512 Hz | ±1% | Oscilloscope on DRDY pin |
| EEG Jitter | < 50 µs | < 100 µs | `time_sync` measurements |
| Audio Sample Rate | 48 kHz | ±0.1% | Audio analyzer |
| Audio Jitter | < 1 µs | < 10 µs | I2S clock measurement |
| Neurofeedback Latency | < 200 ms | < 250 ms | End-to-end timestamp |
| CPU Usage | < 70% | < 90% | DWT cycle counter |
| Buffer Usage | < 50% | < 90% | `ring_buffer_usage_percent()` |

### Performance Testing Script

```c
// tests/test_performance.c
void test_eeg_timing(void) {
    uint32_t samples[1000];
    for (int i = 0; i < 1000; i++) {
        samples[i] = measure_eeg_sample_period_us();
    }

    // Calculate statistics
    uint32_t mean = calculate_mean(samples, 1000);
    uint32_t stddev = calculate_stddev(samples, 1000);
    uint32_t max_jitter = calculate_max_jitter(samples, 1000);

    printf("EEG Timing:\n");
    printf("  Mean: %u us (target: 1953 us)\n", mean);
    printf("  Stddev: %u us\n", stddev);
    printf("  Max jitter: %u us (limit: 100 us)\n", max_jitter);

    TEST_ASSERT(max_jitter < 100, "EEG jitter too high");
}
```

### Load Testing

```c
// Stress test: Maximum throughput
void stress_test_full_load(void) {
    // Enable all processing
    enable_all_eeg_channels();
    enable_audio_full_duplex();
    enable_neurofeedback();
    enable_usb_streaming();
    enable_display_updates();

    // Run for 60 seconds
    uint32_t start = time_sync_get_timestamp_ms();
    while ((time_sync_get_timestamp_ms() - start) < 60000) {
        // Monitor for errors
        if (check_buffer_overruns() || check_timing_violations()) {
            printf("[FAIL] System cannot handle full load\n");
            return;
        }
    }

    printf("[PASS] Full load stress test\n");
}
```

---

## Production Deployment

### Pre-Deployment Validation Checklist

#### Code Quality
- [ ] All unit tests pass (`make test`)
- [ ] No compiler warnings (`make WERROR=1`)
- [ ] Static analysis clean (`cppcheck --enable=all src/`)
- [ ] Code review completed
- [ ] Documentation updated

#### Functional Tests
- [ ] EEG acquisition validated with known signal
- [ ] Audio output quality verified (THD < 0.1%)
- [ ] Neurofeedback loop functioning correctly
- [ ] All LED indicators working
- [ ] USB communication stable
- [ ] Error handling tested (fault injection)

#### Performance Tests
- [ ] Real-time deadlines met (no missed samples)
- [ ] CPU utilization < 70% under normal load
- [ ] Memory usage < 80% of available
- [ ] No memory leaks (run for 24 hours)
- [ ] Temperature stability (< 60°C)

#### Reliability Tests
- [ ] Power cycle test (100 cycles, no failures)
- [ ] Long-duration test (48 hours continuous operation)
- [ ] Electromagnetic compatibility (EMC) testing
- [ ] Electrostatic discharge (ESD) testing
- [ ] Vibration and shock testing (if applicable)

### Production Flash Procedure

```bash
# 1. Build production firmware (optimized, debug off)
cd NS
make clean
make PRODUCTION=1

# 2. Verify binary
ls -lh build/NS.bin
arm-none-eabi-size build/NS.elf

# 3. Flash to target
make flash

# 4. Verify operation
screen /dev/ttyUSB0 115200

# 5. Run production test suite
# (observe LED patterns, check serial output)

# 6. Log serial number and test results
echo "S/N: XXXXXXXX - PASS" >> production_log.txt
```

### Quality Control

1. **Functional Test Fixture**: Create automated test jig
   - Apply known EEG test signals
   - Verify audio output
   - Check all I/O
   - Log results

2. **Calibration**:
   - EEG gain calibration (per channel)
   - Audio DAC calibration
   - System clock trimming

3. **Burn-In Testing**:
   - Run at elevated temperature (50°C) for 24 hours
   - Monitor for failures or degradation

---

## Troubleshooting

### Common Issues and Solutions

#### Issue: System doesn't boot
**Symptoms**: No serial output, LED off
**Possible Causes**:
- Power supply issue
- Flash not programmed
- Clock configuration error
- Stack overflow in startup

**Debug Steps**:
```bash
# 1. Check power
# Measure 3.3V rail

# 2. Verify flash programming
openocd -f openocd.cfg -c "init; flash read_bank 0 /tmp/flash.bin; exit"
ls -lh /tmp/flash.bin

# 3. Debug with GDB
make debug
(gdb) break Reset_Handler
(gdb) monitor reset halt
(gdb) continue
```

#### Issue: EEG data shows all zeros
**Symptoms**: `g_eeg_driver.rx_ring_buffer` has all zero samples
**Possible Causes**:
- SPI not initialized
- ADS1299 not powered
- DRDY interrupt not firing
- DMA not configured

**Debug Steps**:
```gdb
# Check SPI registers
x/32xw 0x40013000  # SPI1 base

# Check DMA configuration
x/32xw 0x40026000  # DMA2 base

# Check interrupt enables
print/x *(uint32_t*)0xE000E100  # NVIC ISER

# Manually read ADS1299 ID register
# (should be 0x3E for ADS1299)
```

#### Issue: Audio has distortion/noise
**Symptoms**: High THD, audible artifacts
**Possible Causes**:
- I2S clock jitter
- Buffer underrun
- Incorrect sample rate
- Codec not configured

**Debug Steps**:
```c
// Check audio buffer status
printf("Audio buffer usage: %d%%\n",
    ring_buffer_usage_percent(&g_audio_rb));

// Check for underruns
uint32_t rx, tx, underruns, overruns;
audio_driver_get_stats(&g_audio_driver, &rx, &tx, &underruns, &overruns);
printf("Underruns: %u, Overruns: %u\n", underruns, overruns);
```

#### Issue: Timing violations / missed deadlines
**Symptoms**: "Loop took XXX us" warnings
**Possible Causes**:
- ISR too long
- Processing too slow
- Cache misses
- Blocking operations in critical path

**Debug Steps**:
```c
// Profile individual functions
performance_marker_t m;
time_sync_start_measure(&m);
eeg_processor_process_window(...);
uint32_t elapsed = time_sync_end_measure(&m);
printf("EEG processing: %u us\n", elapsed);

// Check ISR execution time
// (add timing code in ISR)

// Reduce processing load
// - Lower FFT size
// - Reduce channel count
// - Optimize algorithms
```

---

## FreeBSD Kernel Integration

### RTOS Mode (FreeRTOS)

To enable RTOS mode:

```c
// In include/config/system_config.h
#define ENABLE_RTOS  1
```

**Required Changes**:
1. Add FreeRTOS source files to Makefile
2. Implement task creation in `main.c`
3. Replace polling with task notifications
4. Add mutex/semaphore protection for shared resources

**Task Structure**:
```c
// Suggested task priorities
xTaskCreate(task_eeg_acquisition, "EEG", 512, NULL, 4, NULL);  // Highest
xTaskCreate(task_audio_output, "Audio", 512, NULL, 3, NULL);
xTaskCreate(task_signal_processing, "DSP", 1024, NULL, 2, NULL);
xTaskCreate(task_neurofeedback, "NF", 512, NULL, 2, NULL);
xTaskCreate(task_usb_communication, "USB", 512, NULL, 1, NULL);  // Lowest
```

### Superloop Mode (Bare Metal)

Current implementation uses superloop in `main.c:253-299`.

**Optimization**:
- Minimize blocking operations
- Use state machines for long operations
- Poll buffers efficiently
- Add low-power sleep when idle

---

## Appendix

### Useful Resources

- [STM32F407 Reference Manual](https://www.st.com/resource/en/reference_manual/rm0090-stm32f405415-stm32f407417-stm32f427437-and-stm32f429439-advanced-armbased-32bit-mcus-stmicroelectronics.pdf)
- [ADS1299 Datasheet](https://www.ti.com/lit/ds/symlink/ads1299.pdf)
- [ARM Cortex-M4 Technical Reference](https://developer.arm.com/documentation/100166/0001/)
- [FreeRTOS Documentation](https://www.freertos.org/Documentation/RTOS_book.html)

### Glossary

- **EEG**: Electroencephalography
- **ADC**: Analog-to-Digital Converter
- **DAC**: Digital-to-Analog Converter
- **I2S**: Inter-IC Sound bus
- **SPI**: Serial Peripheral Interface
- **DMA**: Direct Memory Access
- **FFT**: Fast Fourier Transform
- **THD**: Total Harmonic Distortion
- **ISR**: Interrupt Service Routine
- **RTOS**: Real-Time Operating System
- **CCM**: Core-Coupled Memory

---

**Document Version**: 1.0
**Last Updated**: 2025-11-13
**Author**: NS Development Team
