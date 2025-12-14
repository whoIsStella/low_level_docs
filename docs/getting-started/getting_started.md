## Quick Start

### Prerequisites

```bash
# Install ARM toolchain
sudo apt-get install gcc-arm-none-eabi

# Install build tools
sudo apt-get install build-essential make

# Install debugging tools
sudo apt-get install openocd gdb-multiarch

# Verify installation
arm-none-eabi-gcc --version
make --version
openocd --version
```

### Build and Test

```bash
# Clone or navigate to repository
cd NS

# Build firmware for embedded target
make

# Build and run unit tests on host
make test

# Flash to hardware (requires ST-Link connected)
make flash

# Start interactive debugging session
make debug
```

### Expected Output

#### Successful Build:
```
===================================
Build complete: NS.elf
===================================
   text    data     bss     dec     hex filename
  45234    1024   12456   58714    e55a build/NS.elf
```

#### Successful Tests:
```
===================================
Running tests...
===================================

╔════════════════════════════════════════════════════╗
║ Test Suite: Ring Buffer                           ║
╚════════════════════════════════════════════════════╝

  [1/3] Ring Buffer Init...
    ✓ PASSED
  [2/3] Ring Buffer Write/Read...
    ✓ PASSED
  [3/3] Ring Buffer Full...
    ✓ PASSED

  Results: 3/3 passed, 0 failed
  ✓ ALL TESTS PASSED!
```

---

## Architecture

### Layered System Design

```
┌─────────────────────────────────────────────────────┐
│  Layer 5: Application                               │
│  - Neurofeedback Engine                             │
│  - Main Control Loop                                │
├─────────────────────────────────────────────────────┤
│  Layer 4: Signal Processing                         │
│  - FFT Engine (CMSIS-DSP)                          │
│  - EEG Processor (Band Power, Features)            │
│  - Audio Processor (RMS, THD, Modulation)          │
├─────────────────────────────────────────────────────┤
│  Layer 3: Data Structures                           │
│  - Lock-free Ring Buffers (SPSC)                   │
│  - Time Synchronization (µs precision)             │
├─────────────────────────────────────────────────────┤
│  Layer 2: Device Drivers                            │
│  - EEG Driver (ADS1299, SPI+DMA)                   │
│  - Audio Driver (CS43L22, I2S+DMA)                 │
├─────────────────────────────────────────────────────┤
│  Layer 1: Hardware Abstraction Layer (HAL)          │
│  - GPIO, Timer, DMA, SPI, I2S                      │
│  - Portable hardware interface                      │
├─────────────────────────────────────────────────────┤
│  Layer 0: Bare Metal / Boot                         │
│  - Startup Code, Vector Table                      │
│  - C Runtime Initialization                         │
└─────────────────────────────────────────────────────┘
```

### Data Flow

```
 EEG Electrodes
      ↓
 ADS1299 ADC → SPI → DMA → Ring Buffer (EEG)
                                ↓
                           EEG Processor
                            (FFT, Bands)
                                ↓
                        Neurofeedback Engine
                                ↓
                         Audio Processor
                                ↓
 Ring Buffer (Audio) → DMA → I2S → CS43L22 DAC
      ↓
  Headphones
```

---

## Project Structure

```
NS/
├── Makefile                  # Production build system
├── README.md                 # This file
├── PRODUCTION_TESTING.md     # Testing & debugging guide
│
├── linker/
│   └── STM32F407VGTx_FLASH.ld  # Linker script
│
├── openocd.cfg               # OpenOCD configuration
├── .gdbinit                  # GDB initialization
│
├── include/                  # Public headers
│   ├── common_types.h        # Shared type definitions
│   ├── config/
│   │   ├── hardware_config.h # Hardware-specific config
│   │   └── system_config.h   # Application config
│   ├── layer1_hal/           # HAL interfaces
│   ├── layer2_drivers/       # Driver interfaces
│   ├── layer3_datastructs/   # Data structure interfaces
│   ├── layer4_processing/    # Processing interfaces
│   └── layer5_application/   # Application interfaces
│
├── src/                      # Implementation
│   ├── layer0_baremetal/     # Startup code
│   ├── layer1_hal/           # HAL implementations
│   ├── layer2_drivers/       # Driver implementations
│   ├── layer3_datastructs/   # Data structure implementations
│   ├── layer4_processing/    # Processing implementations
│   └── layer5_application/   # Application code
│
├── tests/                    # Test suite
│   ├── test_framework.h      # Lightweight test framework
│   ├── test_all.c            # Main test runner
│   └── test_ring_buffer.c    # Individual test suite
│
├── docs/                     # Comprehensive documentation
│   ├── README.md             # Documentation index
│   ├── cheatsheet_hal.md     # HAL quick reference
│   ├── cheatsheet_porting.md # Porting guide
│   └── *.documentation.md    # Per-file documentation
│
└── build/                    # Build output (generated)
    ├── obj/                  # Object files
    ├── test/                 # Test binaries
    ├── NS.elf        # Firmware (ELF)
    ├── NS.bin        # Firmware (binary)
    ├── NS.hex        # Firmware (hex)
    └── NS.map        # Linker map
```

---

## Configuration

### System Configuration

Edit `include/config/system_config.h`:

```c
// RTOS vs Superloop
#define ENABLE_RTOS                 0      // 0 = bare metal, 1 = FreeRTOS

// Feature flags
#define ENABLE_USB_COMMUNICATION    1
#define ENABLE_BLUETOOTH            0
#define ENABLE_DISPLAY              1
#define ENABLE_SD_CARD_LOGGING      0

// Debug & diagnostics
#define DEBUG_ENABLE                1
#define ENABLE_PERFORMANCE_COUNTERS 1
#define ENABLE_BUFFER_OVERFLOW_CHECK 1

// Buffer sizes
#define EEG_DMA_BUFFER_SIZE         512
#define AUDIO_DMA_BUFFER_SIZE       1024
#define FFT_SIZE_EEG                512
#define FFT_SIZE_AUDIO              2048
```

### Hardware Configuration

Edit `include/config/hardware_config.h`:

```c
// Target MCU
#define MCU_STM32F407       1

// Clock configuration
#define SYSTEM_CLOCK_HZ     168000000UL  // 168 MHz

// EEG configuration
#define EEG_CHANNEL_COUNT       19
#define EEG_SAMPLE_RATE_HZ      512
#define EEG_INTERFACE           EEG_INTERFACE_SPI

// Audio configuration
#define AUDIO_SAMPLE_RATE_HZ    48000
#define AUDIO_CHANNELS          2
```

---

## Build System

### Makefile Targets

| Command | Description |
|---------|-------------|
| `make` | Build firmware (default) |
| `make all` | Build firmware + bin + hex |
| `make test` | Build and run unit tests |
| `make flash` | Flash to target via OpenOCD |
| `make debug` | Start GDB session |
| `make openocd` | Start OpenOCD server |
| `make size` | Show memory usage |
| `make disasm` | Generate disassembly |
| `make symbols` | Generate symbol table |
| `make clean` | Remove build artifacts |
| `make help` | Show all targets |
| `make info` | Show build configuration |

### Build Customization

```bash
# Debug build (no optimization)
make OPT=-O0

# Production build (optimized, no debug)
make OPT=-O3 DEBUG=-g0 PRODUCTION=1

# Verbose build
make VERBOSE=1

# Parallel build
make -j4
```

---

## Testing

### Unit Tests

The system includes comprehensive unit tests for:
- **Ring Buffers**: Initialization, read/write, wraparound, full/empty states
- **FFT Engine**: Accuracy, windowing, sine wave detection
- **EEG Processor**: Band power calculation, feature extraction
- **Audio Processor**: RMS calculation, signal quality

Run tests:
```bash
make test
```

### Integration Tests

Hardware-in-the-loop tests:
```bash
# Build test firmware
make test_hardware

# Flash to target
make flash

# Monitor via serial (115200 baud)
screen /dev/ttyUSB0 115200
```

### Performance Tests

Measure real-time performance:
```c
// In main loop, check timing
uint32_t loop_time = time_sync_end_measure(&loop_marker);
if (loop_time > 50000) {  // 50ms warning
    printf("[WARNING] Loop took %u us\n", loop_time);
}
```

---

## Debugging

### Serial Console

```bash
# Connect to UART (default: USART2, 115200 baud)
screen /dev/ttyUSB0 115200

# Expected output:
# ╔════════════════════════════════════════════════════╗
# ║       NS Embedded System v1.0             ║
# ║              'Less Fluorescent' 2025              ║
# ╚════════════════════════════════════════════════════╝
#
# [INIT] Initializing hardware abstraction layer...
# [INIT] Initializing time synchronization...
# ...
```

### GDB Debugging

**Terminal 1**: Start OpenOCD server
```bash
make openocd
```

**Terminal 2**: Start GDB
```bash
make debug

# GDB custom commands (defined in .gdbinit):
(gdb) connect          # Connect to target
(gdb) flash            # Flash firmware
(gdb) reset_run        # Reset and continue
(gdb) reset_halt       # Reset and halt
(gdb) break_on_error   # Break on exceptions
(gdb) show_stack       # Display stack
```

### Common GDB Commands

```gdb
# Set breakpoints
break main
break eeg_driver_init
break HardFault_Handler

# Examine variables
print g_eeg_driver
print g_audio_driver
print g_nf_engine

# Examine ring buffers
print g_eeg_rb
print ring_buffer_available(&g_eeg_rb)
print ring_buffer_usage_percent(&g_eeg_rb)

# Memory inspection
x/32xw $sp              # View stack
x/32xw 0x20000000       # View RAM

# Watchpoints
watch g_eeg_driver.sample_count
watch g_audio_rb.write_index
```

---

## Production Deployment

### Pre-Deployment Checklist

- [ ] All unit tests pass
- [ ] Hardware integration tests pass
- [ ] Real-time performance validated
- [ ] Memory usage < 80%
- [ ] CPU usage < 70%
- [ ] No memory leaks (24-hour test)
- [ ] EEG signal quality verified
- [ ] Audio output quality verified (THD < 0.1%)
- [ ] Neurofeedback loop latency < 250ms
- [ ] Code review completed
- [ ] Documentation updated

### Flash Production Firmware

```bash
# Build optimized production binary
make clean
make OPT=-O3 PRODUCTION=1

# Verify size
arm-none-eabi-size build/NS.elf

# Flash to target
make flash

# Verify operation
screen /dev/ttyUSB0 115200

# Log production test results
echo "S/N: XXXXXXXX - PASS - $(date)" >> production_log.txt
```

### Quality Control

See [PRODUCTION_TESTING.md](PRODUCTION_TESTING.md) for:
- Detailed testing procedures
- Performance validation
- Hardware test procedures
- Troubleshooting guide
- Production QC checklist

---

## FreeBSD Kernel Integration

### Current Mode: Superloop (Bare Metal)

The system currently runs in superloop mode with:
- Polled event processing
- DMA-driven I/O
- Non-blocking operations
- Priority-based scheduling in main loop

### Future Mode: RTOS (FreeRTOS)

To enable FreeRTOS:

1. **Set RTOS flag**:
```c
// In include/config/system_config.h
#define ENABLE_RTOS  1
```

2. **Add FreeRTOS sources**:
```bash
# Download FreeRTOS
wget https://github.com/FreeRTOS/FreeRTOS-Kernel/releases/...

# Add to Makefile
FREERTOS_SOURCES = FreeRTOS/tasks.c FreeRTOS/queue.c ...
```

3. **Create tasks**:
```c
// In main.c
xTaskCreate(task_eeg_acquisition, "EEG", 512, NULL, 4, NULL);
xTaskCreate(task_audio_output, "Audio", 512, NULL, 3, NULL);
xTaskCreate(task_signal_processing, "DSP", 1024, NULL, 2, NULL);
```

---

## Hardware Requirements

### Minimum Hardware

- **MCU**: STM32F407VGT6 (Cortex-M4F, 168 MHz)
  - 1 MB Flash
  - 128 KB RAM + 64 KB CCM
  - FPU for signal processing
- **EEG Frontend**: ADS1299 (19-channel, 24-bit ADC)
- **Audio Codec**: CS43L22 or equivalent (I2S)
- **Debug Interface**: ST-Link V2/V3
- **Power**: 5V @ 1A minimum

### Recommended Development Board

- STM32F4-Discovery
- Custom NS board (schematic in `hardware/`)

### Peripherals Used

- **SPI1**: EEG ADC communication
- **I2S2/I2S3**: Audio codec (full-duplex)
- **DMA1**: Audio streams
- **DMA2**: EEG stream
- **TIM2**: Microsecond timebase
- **USART2**: Debug console
- **USB OTG**: Data logging (optional)

---

## Documentation

### Quick References

- [README.md](README.md) - This file
- [PRODUCTION_TESTING.md](PRODUCTION_TESTING.md) - Testing & debugging
- [docs/README.md](docs/README.md) - Full documentation index
- [docs/cheatsheet_hal.md](docs/cheatsheet_hal.md) - HAL quick reference
- [docs/cheatsheet_porting.md](docs/cheatsheet_porting.md) - Porting guide

### Detailed Documentation

Over 3,200 lines of maintenance-focused documentation covering:
- Every source file and header
- Hardware integration details
- Porting considerations
- Common pitfalls and debugging tips
- API usage examples

Access at: `docs/`

---

## Contributing

### Code Style

- **C Standard**: GNU11
- **Indentation**: 4 spaces
- **Naming**: snake_case for functions/variables, UPPER_CASE for macros
- **Comments**: Doxygen-style for public APIs

### Before Submitting

1. Run tests: `make test`
2. Check build: `make clean && make`
3. Run static analysis: `cppcheck --enable=all src/`
4. Update documentation
5. Test on hardware

---

## License

Copyright (c) 2025 NS Development Team

---

## Support

For issues, questions, or contributions:
- **Documentation**: See `docs/` directory
- **Testing Guide**: See `PRODUCTION_TESTING.md`
- **Hardware Issues**: Check schematics in `hardware/`

---

## Acknowledgments

- **STMicroelectronics**: STM32F4 platform
- **Texas Instruments**: ADS1299 EEG ADC
- **ARM**: CMSIS-DSP library
- **FreeRTOS**: Real-time kernel

---

**Version**: 1.0
**Last Updated**: 2025-11-13
**Status**: Production Ready
**Target**: FreeBSD Kernel (RTOS/Superloop) on STM32F407
