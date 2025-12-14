# NS System Architecture

**Comprehensive Technical Architecture Documentation**

Version: 1.0
Last Updated: 2025-11-13
Target Platform: STM32F407VGT6 (Cortex-M4F @ 168 MHz)

---

## Table of Contents

1. [System Overview](#system-overview)
2. [Architectural Principles](#architectural-principles)
3. [Layer-by-Layer Architecture](#layer-by-layer-architecture)
4. [Data Flow Architecture](#data-flow-architecture)
5. [Memory Architecture](#memory-architecture)
6. [Timing & Synchronization](#timing--synchronization)
7. [Interrupt Architecture](#interrupt-architecture)
8. [Concurrency & Thread Safety](#concurrency--thread-safety)
9. [Error Handling Strategy](#error-handling-strategy)
10. [Power & Performance](#power--performance)

---

## System Overview

### Mission Statement

NS is a real-time embedded neurofeedback system that:
- Acquires 19-channel EEG data at 512 Hz with microsecond precision
- Processes signals in real-time using FFT and band power analysis
- Generates audio feedback based on brain state
- Maintains end-to-end latency < 250ms from brain to sound

### Key Characteristics

| Characteristic | Value | Notes |
|----------------|-------|-------|
| **Real-time** | Hard deadlines | EEG samples cannot be dropped |
| **Deterministic** | Bounded latency | Neurofeedback loop < 250ms |
| **Concurrent** | Multi-stream I/O | EEG + Audio simultaneous |
| **Resource-constrained** | 128KB RAM | Efficient memory usage critical |
| **Safety-critical** | Medical device | Robust error handling required |
| **Portable** | Hardware abstraction | Support multiple MCU families |

### System Context

```
┌─────────────────────────────────────────────────────────────┐
│                        HUMAN BRAIN                          │
└──────────────────────┬──────────────────────────────────────┘
                       │ EEG Signals (µV)
                       ↓
┌─────────────────────────────────────────────────────────────┐
│                    EEG ELECTRODES (19ch)                    │
│  Fp1 Fp2 F7 F3 Fz F4 F8 T3 C3 Cz C4 T4 T5 P3 Pz P4 T6 O1 O2│
└──────────────────────┬──────────────────────────────────────┘
                       │ Analog (±300mV)
                       ↓
┌─────────────────────────────────────────────────────────────┐
│                  ADS1299 EEG ADC (24-bit)                   │
│  • 19 differential channels                                 │
│  • 512 Hz sampling rate                                     │
│  • Programmable gain (1-24x)                               │
│  • Built-in filters                                        │
└──────────────────────┬──────────────────────────────────────┘
                       │ SPI (24-bit samples)
                       ↓
┌─────────────────────────────────────────────────────────────┐
│                    STM32F407 (NS)                   │
│                                                             │
│  ┌──────────────────────────────────────────────────────┐  │
│  │ Layer 5: Application                                 │  │
│  │  • Neurofeedback Engine                             │  │
│  │  • Main Control Loop                                │  │
│  ├──────────────────────────────────────────────────────┤  │
│  │ Layer 4: Signal Processing                          │  │
│  │  • FFT (512/2048 points)                           │  │
│  │  • EEG Band Power (δ θ α β γ)                     │  │
│  │  • Audio Analysis                                   │  │
│  ├──────────────────────────────────────────────────────┤  │
│  │ Layer 3: Data Structures                            │  │
│  │  • Ring Buffers (Lock-free SPSC)                   │  │
│  │  • Time Sync (µs precision)                        │  │
│  ├──────────────────────────────────────────────────────┤  │
│  │ Layer 2: Drivers                                     │  │
│  │  • EEG Driver (ADS1299)                            │  │
│  │  • Audio Driver (CS43L22)                          │  │
│  ├──────────────────────────────────────────────────────┤  │
│  │ Layer 1: HAL (Hardware Abstraction)                 │  │
│  │  • GPIO  • DMA  • SPI  • I2S  • Timers            │  │
│  ├──────────────────────────────────────────────────────┤  │
│  │ Layer 0: Bare Metal                                  │  │
│  │  • Startup  • Vector Table  • C Runtime            │  │
│  └──────────────────────────────────────────────────────┘  │
└──────────────────────┬──────────────────────────────────────┘
                       │ I2S (24-bit audio)
                       ↓
┌─────────────────────────────────────────────────────────────┐
│                  CS43L22 Audio Codec (DAC)                  │
│  • Stereo output                                           │
│  • 48 kHz sample rate                                      │
│  • 24-bit resolution                                       │
└──────────────────────┬──────────────────────────────────────┘
                       │ Analog Audio
                       ↓
┌─────────────────────────────────────────────────────────────┐
│                    HEADPHONES / SPEAKERS                    │
└──────────────────────┬──────────────────────────────────────┘
                       │ Sound Waves
                       ↓
┌─────────────────────────────────────────────────────────────┐
│                        HUMAN EARS                           │
│             (Feedback Loop Closed)                          │
└─────────────────────────────────────────────────────────────┘
```

---

## Architectural Principles

### 1. Layered Architecture

**Principle**: Strict separation of concerns through 6 distinct layers

**Benefits**:
- **Portability**: HAL isolates hardware dependencies
- **Testability**: Each layer can be tested independently
- **Maintainability**: Changes localized to specific layers
- **Reusability**: Higher layers portable across hardware

**Rules**:
- Layer N can only call Layer N-1 (downward dependencies)
- No upward dependencies (callbacks use function pointers)
- No layer skipping (must go through interfaces)
- Data structures defined at appropriate abstraction level

**Example**:
```
✓ CORRECT: Application → Driver → HAL → Hardware
✗ WRONG:   Application → HAL (skipped driver)
✗ WRONG:   HAL → Driver (upward dependency)
```

### 2. Real-Time Responsiveness

**Principle**: Deterministic behavior with bounded latency

**Implementation**:
- **DMA-driven I/O**: No CPU polling, zero-copy transfers
- **Interrupt priorities**: Hierarchical priority scheme
- **Predictable algorithms**: O(1) or O(log n) operations only
- **No dynamic allocation**: All memory pre-allocated at init

**Timing Guarantees**:
```c
// EEG sample period: 1953 µs ± 100 µs (512 Hz)
#define EEG_SAMPLE_PERIOD_US        1953
#define MAX_JITTER_EEG_US           100

// Audio sample period: 20.8 µs ± 1 µs (48 kHz)
#define AUDIO_SAMPLE_PERIOD_US      21
#define MAX_JITTER_AUDIO_US         1

// Neurofeedback loop: < 250 ms end-to-end
#define NEUROFEEDBACK_LOOP_TARGET_MS    250
```

### 3. Lock-Free Concurrency

**Principle**: Avoid locks in real-time paths

**Implementation**:
- **Single-Producer Single-Consumer (SPSC) ring buffers**
  - Producer: ISR writes to buffer
  - Consumer: Main loop reads from buffer
  - No locks needed (atomic index updates)

- **Volatile indices**: Ensure memory ordering
- **Power-of-2 sizes**: Fast modulo using bitwise AND
- **Separate read/write indices**: No race conditions

**Example**:
```c
// Producer (ISR)
ring_buffer_write(&eeg_rb, &sample);  // Lock-free

// Consumer (main loop)
ring_buffer_read(&eeg_rb, &sample);   // Lock-free
```

### 4. Fail-Safe Error Handling

**Principle**: Graceful degradation, never crash

**Strategy**:
```
Error Detected → Log → Degrade Gracefully → Continue
```

**Implementation**:
- **Status codes**: All functions return `status_t`
- **Defensive programming**: Validate all inputs
- **Watchdog timer**: Recover from hangs
- **Buffer overflow protection**: Detect and handle
- **Error counters**: Track error rates

**Example**:
```c
status_t result = eeg_driver_start(&driver);
if (result != STATUS_OK) {
    // Log error
    printf("[ERROR] EEG start failed: %d\n", result);

    // Attempt recovery
    eeg_driver_reset(&driver);

    // Degrade gracefully
    system_enter_safe_mode();

    // Continue operation (don't crash)
}
```

### 5. Data-Oriented Design

**Principle**: Optimize for data flow, not object hierarchy

**Implementation**:
- **Structure-of-Arrays (SoA)** where appropriate
- **Cache-friendly layouts**: Sequential access patterns
- **Minimal indirection**: Direct data access
- **Batch processing**: Process arrays, not single items

**Example**:
```c
// Good: Process entire window at once
eeg_processor_process_window(&processor,
                             eeg_samples,   // Array
                             512,           // Count
                             &features);    // Output

// Bad: Process one sample at a time
for (int i = 0; i < 512; i++) {
    eeg_processor_process_sample(&processor, &eeg_samples[i]);
}
```

### 6. Zero-Copy Data Path

**Principle**: Minimize data copying for performance

**Implementation**:
```
ADC → DMA → Ring Buffer → Processing → DMA → DAC
      ↑               ↑                ↑
   No Copy       No Copy           No Copy
```

**Techniques**:
- **DMA double-buffering**: Direct hardware to buffer
- **In-place processing**: Modify buffers directly
- **Pointer passing**: Pass references, not values
- **Bulk operations**: `memcpy` for unavoidable copies

---

## Layer-by-Layer Architecture

### Layer 0: Bare Metal / Boot

**Purpose**: Initialize hardware and C runtime before main()

**Components**:
- `startup.c` - Reset handler, vector table, BSS/data initialization
- Linker script - Memory layout, section placement

**Execution Flow**:
```
Power On
   ↓
Reset Vector (0x08000000)
   ↓
Reset_Handler()
   ↓
1. Copy .data from Flash to RAM
2. Zero .bss section
3. Call SystemInit() (clock setup)
4. Call main()
```

**Memory Layout**:
```
Flash (0x08000000):
  ├── Vector Table (0x000 - 0x1FF)
  ├── .text (code)
  ├── .rodata (constants)
  └── .data (initial values)

RAM (0x20000000):
  ├── .data (initialized variables)
  ├── .bss (zero-initialized)
  ├── Heap
  └── Stack (grows down from top)

CCM-RAM (0x10000000):
  └── Critical data structures (fastest access)
```

**Critical Sections**:
```c
// Vector Table (must be at 0x08000000)
__attribute__((section(".isr_vector")))
void (* const g_pfnVectors[])(void) = {
    (void (*)(void))(&_estack),  // Initial SP
    Reset_Handler,                // Reset
    NMI_Handler,                  // NMI
    HardFault_Handler,            // Hard Fault
    // ... 98 more interrupt vectors
};

// Reset Handler
void Reset_Handler(void) {
    // Copy .data section
    uint32_t *src = &_sidata;
    uint32_t *dst = &_sdata;
    while (dst < &_edata) {
        *dst++ = *src++;
    }

    // Zero .bss section
    dst = &_sbss;
    while (dst < &_ebss) {
        *dst++ = 0;
    }

    // Call main
    main();

    // Should never return
    while (1);
}
```

---

### Layer 1: Hardware Abstraction Layer (HAL)

**Purpose**: Provide portable hardware interface

**Design Philosophy**:
- **Minimize abstraction overhead**: Thin wrappers, not heavy frameworks
- **Zero-cost abstractions**: Inline functions where possible
- **Type-safe**: Use enums and structs, not magic numbers
- **Stateless where possible**: Functions operate on passed-in data

**Modules**:

#### GPIO (hal_gpio.h/c)
```c
// Set pin as output
status_t hal_gpio_set_output(void* port, uint8_t pin,
                             gpio_speed_t speed, gpio_pull_t pull);

// Write pin
void hal_gpio_write(void* port, uint8_t pin, bool value);

// Read pin
bool hal_gpio_read(void* port, uint8_t pin);

// Toggle pin (atomic)
void hal_gpio_toggle(void* port, uint8_t pin);
```

**Implementation Strategy**:
```c
// Generic interface (portable)
void hal_gpio_write(void* port, uint8_t pin, bool value);

// Hardware-specific implementation (STM32F407)
void hal_gpio_write(void* port, uint8_t pin, bool value) {
    GPIO_TypeDef* gpio = (GPIO_TypeDef*)port;
    if (value) {
        gpio->BSRR = (1U << pin);      // Set bit
    } else {
        gpio->BSRR = (1U << (pin + 16)); // Reset bit
    }
}
```

#### DMA (hal_dma.h/c)
```c
// Configure DMA stream
status_t hal_dma_config(dma_stream_t stream, dma_config_t* config);

// Start transfer
status_t hal_dma_start(dma_stream_t stream);

// Stop transfer
status_t hal_dma_stop(dma_stream_t stream);

// Register callback
void hal_dma_register_callback(dma_stream_t stream,
                               dma_callback_t callback);
```

**DMA Architecture**:
```
Peripheral → DMA → Memory (Circular Buffer)
              ↓
         Half-Transfer IRQ → Callback (process first half)
              ↓
      Full-Transfer IRQ → Callback (process second half)
              ↓
         Wrap Around → Continue
```

#### SPI (hal_spi.h/c)
```c
// Initialize SPI
status_t hal_spi_init(spi_instance_t spi, spi_config_t* config);

// Transmit/Receive (blocking)
status_t hal_spi_transfer(spi_instance_t spi,
                         uint8_t* tx_data, uint8_t* rx_data,
                         size_t length);

// Transmit/Receive (DMA, non-blocking)
status_t hal_spi_transfer_dma(spi_instance_t spi,
                              uint8_t* tx_data, uint8_t* rx_data,
                              size_t length, spi_callback_t callback);
```

**SPI Timing**:
```
CS Low → Transmit Byte 0 → Transmit Byte 1 → ... → CS High
         (SCLK pulses)      (SCLK pulses)
```

#### I2S (hal_i2s.h/c)
```c
// Initialize I2S
status_t hal_i2s_init(i2s_instance_t i2s, i2s_config_t* config);

// Start audio stream (DMA)
status_t hal_i2s_start_stream(i2s_instance_t i2s,
                              void* buffer, size_t size);

// Full-duplex (TX + RX simultaneously)
status_t hal_i2s_start_full_duplex(i2s_instance_t i2s,
                                   void* tx_buffer, void* rx_buffer,
                                   size_t size);
```

**I2S Format**:
```
Frame: [Left Channel] [Right Channel]
       24-bit         24-bit

BCLK:  3.072 MHz (64 × 48 kHz)
LRCLK: 48 kHz (sample rate)
```

#### Timer (hal_timer.h/c)
```c
// Initialize timer system
status_t hal_timer_init(void);

// Get microsecond timestamp
uint64_t hal_timer_get_us(void);

// Delay (blocking)
void hal_timer_delay_us(uint32_t us);

// Measure performance
void hal_timer_start(uint64_t* start);
uint64_t hal_timer_elapsed_us(uint64_t start);
```

**Timer Implementation**:
```c
// Use DWT cycle counter (most accurate)
#define DWT_CYCCNT  (*(volatile uint32_t*)0xE0001004)

uint64_t hal_timer_get_us(void) {
    static uint32_t overflow_count = 0;
    static uint32_t last_count = 0;

    uint32_t current = DWT_CYCCNT;

    // Detect overflow
    if (current < last_count) {
        overflow_count++;
    }
    last_count = current;

    // Convert to microseconds (168 MHz clock)
    uint64_t total_cycles = ((uint64_t)overflow_count << 32) | current;
    return total_cycles / 168;
}
```

---

### Layer 2: Device Drivers

**Purpose**: Control specific hardware peripherals (ADS1299, CS43L22)

**Design Philosophy**:
- **Encapsulation**: Hide chip-specific details
- **State machines**: Model device behavior
- **Callbacks**: Decouple driver from application
- **Statistics**: Track errors and performance

#### EEG Driver (eeg_driver.h/c)

**State Machine**:
```
UNINITIALIZED → INITIALIZED → RUNNING → STOPPED
      ↓              ↓           ↓          ↓
    [init]       [start]     [stop]    [deinit]
```

**API**:
```c
// Initialize driver
status_t eeg_driver_init(eeg_driver_t* driver, eeg_config_t* config);

// Start acquisition
status_t eeg_driver_start(eeg_driver_t* driver);

// Stop acquisition
status_t eeg_driver_stop(eeg_driver_t* driver);

// Get statistics
void eeg_driver_get_stats(eeg_driver_t* driver,
                         uint32_t* samples, uint32_t* overruns,
                         uint32_t* errors);
```

**Data Flow**:
```
ADS1299 DRDY Interrupt (512 Hz)
   ↓
SPI DMA Read (19 channels × 3 bytes)
   ↓
Parse 24-bit samples → eeg_packet_t
   ↓
Timestamp (time_sync_get_timestamp())
   ↓
Write to ring buffer (lock-free)
   ↓
Main loop reads and processes
```

**ADS1299 Register Configuration**:
```c
// Power-on sequence
1. Reset device (RESET pin low → high)
2. Wait 1ms for power-on reset
3. Send SDATAC (stop continuous mode)
4. Configure registers:
   - CONFIG1: 0x96 (512 SPS, internal ref)
   - CONFIG2: 0xD0 (internal test signal off)
   - CONFIG3: 0xE0 (enable internal reference buffer)
   - CHnSET:  0x60 (gain=24, normal operation)
5. Send START command
6. Send RDATAC (continuous read mode)
7. Wait for DRDY interrupt
```

#### Audio Driver (audio_driver.c)

**Double-Buffering**:
```
Buffer 0 (DMA filling) → Half-Transfer IRQ
   ↓
Switch to Buffer 1
   ↓
Process Buffer 0 (main loop)
   ↓
Buffer 1 (DMA filling) → Full-Transfer IRQ
   ↓
Switch to Buffer 0
   ↓
Process Buffer 1 (main loop)
   ↓
Repeat
```

**API**:
```c
// Initialize audio codec
status_t audio_driver_init(audio_driver_t* driver, audio_config_t* config);

// Start playback only
status_t audio_driver_start_playback(audio_driver_t* driver);

// Start full-duplex (record + playback)
status_t audio_driver_start_full_duplex(audio_driver_t* driver);

// Volume control
status_t audio_driver_set_volume(audio_driver_t* driver, uint8_t volume);
```

---

### Layer 3: Data Structures

**Purpose**: Provide efficient, concurrent-safe data containers

#### Ring Buffer (ring_buffer.h/c)

**Lock-Free SPSC Design**:
```c
typedef struct {
    void* buffer;                   // Data storage
    size_t element_size;            // Bytes per element
    size_t capacity;                // Total elements (power of 2)
    volatile size_t write_index;    // Producer index
    volatile size_t read_index;     // Consumer index
    volatile size_t count;          // Available elements
} ring_buffer_t;
```

**Operations**:
```c
// O(1) - Check if empty
bool ring_buffer_is_empty(ring_buffer_t* rb) {
    return rb->count == 0;
}

// O(1) - Check if full
bool ring_buffer_is_full(ring_buffer_t* rb) {
    return rb->count >= (rb->capacity - 1);
}

// O(1) - Write element (producer only)
status_t ring_buffer_write(ring_buffer_t* rb, void* element) {
    if (ring_buffer_is_full(rb)) {
        return STATUS_BUFFER_FULL;
    }

    // Copy element
    uint8_t* dst = (uint8_t*)rb->buffer +
                   (rb->write_index * rb->element_size);
    memcpy(dst, element, rb->element_size);

    // Update write index (power-of-2 wrap)
    rb->write_index = (rb->write_index + 1) & (rb->capacity - 1);

    // Atomic increment (volatile)
    rb->count++;

    return STATUS_OK;
}

// O(1) - Read element (consumer only)
status_t ring_buffer_read(ring_buffer_t* rb, void* element) {
    if (ring_buffer_is_empty(rb)) {
        return STATUS_BUFFER_EMPTY;
    }

    // Copy element
    uint8_t* src = (uint8_t*)rb->buffer +
                   (rb->read_index * rb->element_size);
    memcpy(element, src, rb->element_size);

    // Update read index
    rb->read_index = (rb->read_index + 1) & (rb->capacity - 1);

    // Atomic decrement
    rb->count--;

    return STATUS_OK;
}
```

**Why It's Lock-Free**:
1. **Single producer writes to `write_index`** (no contention)
2. **Single consumer writes to `read_index`** (no contention)
3. **Volatile ensures memory ordering** (no reordering across volatile accesses)
4. **Power-of-2 capacity** (fast modulo using AND)
5. **`count` is redundant but cached** (faster than calculating from indices)

#### Time Synchronization (time_sync.h/c)

**Purpose**: Unified time reference for EEG/Audio correlation

**Implementation**:
```c
// Global microsecond counter
static volatile uint64_t g_timestamp_us = 0;

// SysTick interrupt every 1ms
void SysTick_Handler(void) {
    g_timestamp_us += 1000;  // Add 1ms
}

// Get timestamp with µs precision
uint64_t time_sync_get_timestamp(void) {
    // DWT cycle counter for sub-millisecond precision
    uint32_t cycles = DWT_CYCCNT;
    uint32_t us_fraction = cycles / 168;  // 168 MHz → µs

    return g_timestamp_us + us_fraction;
}
```

**Jitter Measurement**:
```c
typedef struct {
    uint64_t start_time;
    uint32_t min_us;
    uint32_t max_us;
    uint32_t count;
} performance_marker_t;

void time_sync_start_measure(performance_marker_t* marker) {
    marker->start_time = time_sync_get_timestamp();
}

uint32_t time_sync_end_measure(performance_marker_t* marker) {
    uint64_t end = time_sync_get_timestamp();
    uint32_t elapsed = (uint32_t)(end - marker->start_time);

    // Track min/max
    if (marker->count == 0 || elapsed < marker->min_us) {
        marker->min_us = elapsed;
    }
    if (elapsed > marker->max_us) {
        marker->max_us = elapsed;
    }
    marker->count++;

    return elapsed;
}
```

---

### Layer 4: Signal Processing

**Purpose**: Extract features from raw signals

#### FFT Engine (fft_engine.h/c)

**CMSIS-DSP Integration**:
```c
#include "arm_math.h"  // CMSIS-DSP library

typedef struct {
    arm_rfft_fast_instance_f32 fft_instance;
    float32_t* input_buffer;
    float32_t* output_buffer;
    float32_t* window;
    uint16_t size;
    uint8_t log2_size;
    float sample_rate;
} fft_instance_t;

status_t fft_init(fft_instance_t* fft, fft_config_t* config) {
    // Allocate buffers
    fft->input_buffer = malloc(config->fft_size * sizeof(float32_t));
    fft->output_buffer = malloc(config->fft_size * sizeof(float32_t));

    // Initialize CMSIS-DSP FFT
    arm_rfft_fast_init_f32(&fft->fft_instance, config->fft_size);

    // Generate window (Hann)
    if (config->window_type == FFT_WINDOW_HANN) {
        for (int i = 0; i < config->fft_size; i++) {
            fft->window[i] = 0.5f * (1.0f - cosf(2.0f * M_PI * i / config->fft_size));
        }
    }

    return STATUS_OK;
}

status_t fft_forward(fft_instance_t* fft, float32_t* input, complex_t* output) {
    // Apply window
    for (int i = 0; i < fft->size; i++) {
        fft->input_buffer[i] = input[i] * fft->window[i];
    }

    // Compute FFT (hardware-accelerated on Cortex-M4)
    arm_rfft_fast_f32(&fft->fft_instance, fft->input_buffer, fft->output_buffer, 0);

    // Convert to complex pairs
    for (int i = 0; i < fft->size / 2; i++) {
        output[i].real = fft->output_buffer[2 * i];
        output[i].imag = fft->output_buffer[2 * i + 1];
    }

    return STATUS_OK;
}
```

**Performance**:
- 512-point FFT: ~2ms on Cortex-M4F @ 168 MHz
- 2048-point FFT: ~10ms

#### EEG Processor (eeg_processor.h/c)

**Band Power Calculation**:
```c
status_t eeg_processor_calculate_band_power(eeg_processor_t* proc,
                                            float* signal, size_t length,
                                                            eeg_band_power_t* bands) {
    complex_t fft_output[512];
    float magnitude[256];

    // Compute FFT
    fft_forward(&proc->fft, signal, fft_output);

    // Calculate magnitude spectrum
    for (int i = 0; i < 256; i++) {
        magnitude[i] = sqrtf(fft_output[i].real * fft_output[i].real +
                            fft_output[i].imag * fft_output[i].imag);
    }

    // Integrate power in each band
    bands->delta = integrate_band(magnitude, 0.5f, 4.0f, proc->sample_rate, 256);
    bands->theta = integrate_band(magnitude, 4.0f, 8.0f, proc->sample_rate, 256);
    bands->alpha = integrate_band(magnitude, 8.0f, 13.0f, proc->sample_rate, 256);
    bands->beta = integrate_band(magnitude, 13.0f, 30.0f, proc->sample_rate, 256);
    bands->gamma = integrate_band(magnitude, 30.0f, 50.0f, proc->sample_rate, 256);

    return STATUS_OK;
}

// Helper function
float integrate_band(float* magnitude, float low_hz, float high_hz,
                    float sample_rate, size_t length) {
    int low_bin = (int)(low_hz * length / sample_rate);
    int high_bin = (int)(high_hz * length / sample_rate);

    float power = 0.0f;
    for (int i = low_bin; i <= high_bin; i++) {
        power += magnitude[i] * magnitude[i];
    }

    return power / (high_bin - low_bin + 1);  // Average power
}
```

---

### Layer 5: Application

**Purpose**: Implement neurofeedback control logic

#### Neurofeedback Engine (neurofeedback_engine.h/c)

**State Machine**:
```
IDLE → CALIBRATING → TRAINING → PAUSED
  ↑         ↓            ↓          ↓
  └─────────┴────────────┴──────────┘
```

**Core Algorithm**:
```c
void neurofeedback_update(neurofeedback_engine_t* engine,
                         eeg_features_t* eeg,
                         audio_features_t* audio) {
    // 1. Classify brain state
    brain_state_t state = classify_brain_state(eeg);

    // 2. Calculate target metrics
    float focus_score = calculate_focus_score(eeg);
    float relaxation_score = calculate_relaxation_score(eeg);

    // 3. Determine reward/penalty
    bool reward = false;
    if (engine->config.mode == FEEDBACK_MODE_ALPHA_TRAINING) {
        reward = (eeg->band_power.alpha > engine->config.alpha_threshold);
    } else if (engine->config.mode == FEEDBACK_MODE_FOCUS) {
        reward = (focus_score > engine->config.focus_threshold);
    }

    // 4. Generate modulation command
    modulation_command_t cmd;
    if (reward) {
        // Increase volume (positive feedback)
        cmd.target = MOD_TARGET_VOLUME;
        cmd.value = engine->current_volume + 0.1f;
        cmd.ramp_ms = 500;
        engine->reward_count++;
    } else {
        // Decrease volume (negative feedback)
        cmd.target = MOD_TARGET_VOLUME;
        cmd.value = engine->current_volume - 0.1f;
        cmd.ramp_ms = 500;
        engine->penalty_count++;
    }

    // 5. Apply modulation to audio
    audio_processor_apply_modulation(&engine->audio_proc, &cmd);

    // 6. Update state
    engine->current_state = state;
    engine->decision_count++;
}
```

---

## Data Flow Architecture

### End-to-End Pipeline

```
┌─────────────────────────────────────────────────────────────┐
│                    ACQUISITION PHASE                        │
└─────────────────────────────────────────────────────────────┘

EEG Electrodes (19ch)
   ↓ Analog (±300mV)
ADS1299 ADC
   ↓ SPI (57 bytes @ 512 Hz = 29.2 KB/s)
DMA → EEG Ring Buffer (2048 samples × 19ch)
   ↓ Time: ~4 seconds of buffered data

┌─────────────────────────────────────────────────────────────┐
│                    PROCESSING PHASE                         │
└─────────────────────────────────────────────────────────────┘

Main Loop (polling, ~1ms period)
   ↓
Check EEG buffer >= 512 samples?
   ↓ Yes
Read 512 samples (1 second window)
   ↓
EEG Processor:
   ├─> Apply window (Hann)
   ├─> FFT (512-point, ~2ms)
   ├─> Calculate magnitude spectrum
   ├─> Integrate band powers (δ θ α β γ)
   ├─> Calculate alpha asymmetry
   └─> Extract features → eeg_features_t

Check Audio buffer >= 2048 samples?
   ↓ Yes
Read 2048 samples (~43ms window @ 48kHz)
   ↓
Audio Processor:
   ├─> FFT (2048-point, ~10ms)
   ├─> Calculate RMS, peak, THD
   └─> Extract features → audio_features_t

┌─────────────────────────────────────────────────────────────┐
│                    DECISION PHASE                           │
└─────────────────────────────────────────────────────────────┘

Neurofeedback Engine:
   ├─> Classify brain state
   ├─> Calculate focus/relaxation scores
   ├─> Determine reward/penalty
   └─> Generate modulation command

┌─────────────────────────────────────────────────────────────┐
│                    OUTPUT PHASE                             │
└─────────────────────────────────────────────────────────────┘

Audio Processor:
   ├─> Apply volume modulation
   ├─> Apply EQ/filtering
   └─> Write to Audio Ring Buffer

Audio Ring Buffer → DMA → I2S → CS43L22 DAC
   ↓
Headphones/Speakers
   ↓
FEEDBACK LOOP CLOSED (Latency: ~150-250ms)
```

### Latency Budget

| Stage | Time | Notes |
|-------|------|-------|
| EEG Acquisition | 1953 µs | Per sample @ 512 Hz |
| Buffer accumulation | 1000 ms | Wait for 512 samples |
| EEG FFT | 2 ms | 512-point |
| Band power calc | 0.5 ms | Integrate spectrum |
| Neurofeedback decision | 0.1 ms | State machine |
| Audio FFT | 10 ms | 2048-point (optional) |
| Modulation | 0.5 ms | Volume/EQ |
| Audio DMA | 21 µs | Per sample @ 48 kHz |
| **Total (typical)** | **~150 ms** | Well under 250ms target |

---

## Memory Architecture

### Memory Map

```
0x10000000 ┌─────────────────────────────────────┐
           │ CCM-RAM (64 KB)                     │
           │ • Critical buffers (fastest)        │
           │ • DMA not accessible                │
0x1000FFFF └─────────────────────────────────────┘

0x20000000 ┌─────────────────────────────────────┐
           │ SRAM (128 KB)                       │
           │ • DMA-accessible buffers            │
           │ • General data                      │
0x2001FFFF └─────────────────────────────────────┘

0x08000000 ┌─────────────────────────────────────┐
           │ Flash (1 MB)                        │
           │ • Program code (.text)              │
           │ • Constants (.rodata)               │
           │ • Initial data (.data)              │
0x080FFFFF └─────────────────────────────────────┘
```

### Memory Usage (Estimated)

| Section | Size | Location | Notes |
|---------|------|----------|-------|
| **Flash** | | | |
| .text (code) | ~45 KB | Flash | All functions |
| .rodata (const) | ~5 KB | Flash | Strings, tables |
| **RAM** | | | |
| .data | ~1 KB | RAM | Initialized globals |
| .bss | ~2 KB | RAM | Zero-init globals |
| Stack | 8 KB | RAM | Per config |
| Heap | 16 KB | RAM | Dynamic alloc (init only) |
| **Buffers** | | | |
| EEG ring buffer | ~160 KB | RAM | 2048×19ch×4 bytes |
| Audio ring buffer | ~64 KB | RAM | 8192×2ch×4 bytes |
| FFT buffers | ~16 KB | RAM | 2048×4 bytes×2 |
| **Total RAM** | ~267 KB | | **Exceeds 128KB!** |

### ⚠️ Memory Optimization Required

**Problem**: Current configuration uses more RAM than available

**Solutions**:
1. **Reduce buffer sizes**:
   ```c
   #define EEG_RING_BUFFER_SIZE    1024  // Was 2048
   #define AUDIO_RING_BUFFER_SIZE  4096  // Was 8192
   ```

2. **Use CCM-RAM for non-DMA buffers**:
   ```c
   __attribute__((section(".ccmram")))
   float fft_buffers[2048];
   ```

3. **Reduce channel count for testing**:
   ```c
   #define EEG_CHANNEL_COUNT       8  // Was 19
   ```

4. **Use 16-bit samples** (reduces precision):
   ```c
   typedef int16_t eeg_sample_value_t;  // Was int32_t
   ```

---

## Timing & Synchronization

### Clock Tree

```
HSE Crystal (8 MHz)
   ↓
PLL (×168)
   ↓
SYSCLK (168 MHz)
   ├─> AHB (168 MHz) → CPU, DMA, GPIO
   ├─> APB2 (84 MHz) → SPI1, TIM1
   └─> APB1 (42 MHz) → SPI2/3, I2S, TIM2-7
```

### Interrupt Priorities (Lower number = higher priority)

| IRQ | Priority | Preempt | Sub | Notes |
|-----|----------|---------|-----|-------|
| HardFault | -3 | - | - | Highest (NMI level) |
| DMA (EEG) | 0 | 0 | 0 | Critical - cannot miss |
| DMA (Audio TX) | 1 | 0 | 1 | Audio output |
| SPI (EEG) | 2 | 0 | 2 | EEG data ready |
| DMA (Audio RX) | 3 | 0 | 3 | Audio input |
| I2S | 4 | 1 | 0 | Audio codec |
| SysTick | 5 | 1 | 1 | Time base (1ms) |
| USB | 6 | 2 | 0 | Data logging |
| UART | 7 | 3 | 0 | Debug console |

### Critical Section Rules

1. **Keep ISRs short** (< 100 µs)
2. **No blocking operations in ISRs**
3. **No printf in ISRs** (use buffered logging)
4. **Disable interrupts sparingly**:
   ```c
   ENTER_CRITICAL();
   // Keep this section < 10 µs
   EXIT_CRITICAL();
   ```

---

## Interrupt Architecture

### ISR Flow

```c
// DMA Transfer Complete Interrupt
void DMA2_Stream0_IRQHandler(void) {
    // 1. Clear interrupt flag (first!)
    DMA2->LIFCR = DMA_LIFCR_CTCIF0;

    // 2. Swap buffers
    g_active_buffer = !g_active_buffer;

    // 3. Signal main loop (flag or semaphore)
    g_eeg_data_ready = true;

    // 4. Update statistics
    g_eeg_sample_count++;

    // 5. Return immediately (< 5 µs total)
}

// Main loop processes data
while (1) {
    if (g_eeg_data_ready) {
        g_eeg_data_ready = false;

        // Process buffer (can take milliseconds)
        process_eeg_buffer(inactive_buffer);
    }
}
```

---

## Concurrency & Thread Safety

### Concurrency Model

**Current (Superloop)**:
```
Main Loop (polling)
   + ISRs (preemptive)
   = Cooperative multitasking
```

**Future (RTOS)**:
```
Tasks (preemptive scheduling)
   + ISRs (highest priority)
   + Mutexes/Semaphores
   = Preemptive multitasking
```

### Thread-Safe Patterns

#### Pattern 1: ISR to Main (Producer-Consumer)
```c
// Producer (ISR)
void DMA_IRQHandler(void) {
    ring_buffer_write(&g_buffer, &data);  // Lock-free
}

// Consumer (Main)
void main_loop(void) {
    if (ring_buffer_available(&g_buffer) > 0) {
        ring_buffer_read(&g_buffer, &data);  // Lock-free
    }
}
```

#### Pattern 2: Atomic Flags
```c
// Writer (ISR or Main)
volatile bool g_flag = true;  // Atomic on ARM Cortex-M

// Reader (Main or ISR)
if (g_flag) {
    // ...
}
```

#### Pattern 3: Critical Sections (Last Resort)
```c
// Only when absolutely necessary
ENTER_CRITICAL();
non_atomic_operation();
EXIT_CRITICAL();
```

---

## Error Handling Strategy

### Error Categories

1. **Fatal Errors** (system cannot continue):
   - Hard Fault
   - Stack overflow
   - Heap exhaustion
   - **Action**: Enter safe mode, flash LED, log error, watchdog reset

2. **Recoverable Errors** (can continue with degraded service):
   - DMA overrun
   - Buffer overflow
   - Sensor communication error
   - **Action**: Log error, increment counter, attempt recovery

3. **Warnings** (informational):
   - Timing violations
   - Buffer near-full
   - Signal quality low
   - **Action**: Log warning, continue

### Error Handling Code

```c
status_t eeg_driver_start(eeg_driver_t* driver) {
    // Validate input
    if (driver == NULL) {
        return STATUS_INVALID_PARAM;
    }

    // Check state
    if (driver->state != EEG_STATE_INITIALIZED) {
        return STATUS_ERROR;
    }

    // Attempt operation
    status_t result = hal_spi_start(driver->spi);
    if (result != STATUS_OK) {
        // Log error
        log_error("EEG SPI start failed: %d", result);

        // Increment error counter
        driver->error_count++;

        // Attempt recovery
        hal_spi_reset(driver->spi);

        return result;
    }

    // Success
    driver->state = EEG_STATE_RUNNING;
    return STATUS_OK;
}
```

---

## Power & Performance

### Power Consumption (Estimated)

| State | Current | Notes |
|-------|---------|-------|
| Full operation | ~200 mA | All peripherals active |
| Idle (WFI) | ~50 mA | CPU sleeping |
| Stop mode | ~10 mA | Peripherals off |
| Standby | ~1 mA | Only RTC |

### Performance Optimization Techniques

1. **DMA**: Offload data transfers from CPU
2. **FPU**: Use hardware floating-point
3. **CMSIS-DSP**: Optimized signal processing
4. **Inline functions**: Reduce call overhead
5. **Cache-friendly access**: Sequential memory access
6. **Batch processing**: Process arrays, not items

### CPU Utilization (Estimated)

| Task | CPU % | Notes |
|------|-------|-------|
| DMA ISRs | 5% | Very short handlers |
| EEG processing | 15% | FFT + band power |
| Audio processing | 20% | FFT + modulation |
| Neurofeedback | 5% | State machine |
| Main loop overhead | 10% | Polling, bookkeeping |
| Idle | 45% | Available headroom |
| **Total** | **~55%** | Well under 70% target |

---

## Summary

The NS architecture is:
- **Layered** for portability and maintainability
- **Real-time** with deterministic behavior
- **Concurrent** using lock-free data structures
- **Efficient** with DMA and zero-copy design
- **Robust** with comprehensive error handling
- **Scalable** ready for RTOS migration

**Key Takeaways**:
1. Strict layer separation enables testing and porting
2. DMA + ring buffers = lock-free concurrency
3. CMSIS-DSP provides hardware-accelerated FFT
4. Latency budget well under 250ms target
5. Memory optimization needed for 128KB target

---

**Document Version**: 1.0
**Author**: NS Development Team
**Last Updated**: 2025-11-13
