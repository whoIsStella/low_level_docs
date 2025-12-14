# NS API Reference

**Complete Function and Type Reference**

Version: 1.0
Last Updated: 2025-11-13

---

## Table of Contents

1. [Common Types](#common-types)
2. [Layer 1: HAL](#layer-1-hal)
3. [Layer 2: Drivers](#layer-2-drivers)
4. [Layer 3: Data Structures](#layer-3-data-structures)
5. [Layer 4: Signal Processing](#layer-4-signal-processing)
6. [Layer 5: Application](#layer-5-application)
7. [Usage Examples](#usage-examples)

---

## Common Types

### Status Codes

```c
typedef enum {
    STATUS_OK = 0,              // Operation successful
    STATUS_ERROR,               // Generic error
    STATUS_BUSY,                // Resource busy
    STATUS_TIMEOUT,             // Operation timed out
    STATUS_INVALID_PARAM,       // Invalid parameter
    STATUS_NOT_INITIALIZED,     // Module not initialized
    STATUS_BUFFER_FULL,         // Buffer is full
    STATUS_BUFFER_EMPTY,        // Buffer is empty
    STATUS_DMA_ERROR,           // DMA transfer error
    STATUS_HARDWARE_ERROR,      // Hardware fault
    STATUS_OUT_OF_MEMORY        // Memory allocation failed
} status_t;
```

**Usage**:
```c
status_t result = eeg_driver_init(&driver, &config);
if (result != STATUS_OK) {
    printf("Init failed: %d\n", result);
    return result;
}
```

### EEG Data Types

```c
// Single channel sample
typedef struct {
    int32_t value;          // 24-bit sign-extended to 32-bit (-8388608 to 8388607)
    uint8_t quality;        // 0-100, electrode impedance quality
} eeg_sample_t;

// Complete packet (all channels at one time point)
typedef struct {
    uint64_t timestamp_us;              // Microsecond timestamp
    uint32_t sample_number;             // Sequential counter
    eeg_sample_t channels[EEG_CHANNEL_COUNT];  // 19 channels
    uint8_t overall_quality;            // Average quality
} __attribute__((packed)) eeg_packet_t;

// Configuration
typedef struct {
    uint16_t sample_rate;               // Hz (512 typical)
    uint8_t channel_count;              // 19 for ADS1299
    uint8_t bit_depth;                  // 24
    bool enable_filters;                // Hardware filters on/off
    bool enable_notch_50hz;             // 50Hz notch (Europe)
    bool enable_notch_60hz;             // 60Hz notch (US)
} eeg_config_t;
```

### Audio Data Types

```c
// Stereo sample
typedef struct {
    int32_t left;           // 24-bit sign-extended
    int32_t right;          // 24-bit sign-extended
} audio_sample_t;

// Audio packet
typedef struct {
    uint64_t timestamp_us;
    uint32_t sample_number;
    audio_sample_t sample;
} __attribute__((packed)) audio_packet_t;

// Configuration
typedef struct {
    uint32_t sample_rate;   // Hz (48000 typical)
    uint8_t bit_depth;      // 24
    uint8_t channels;       // 1=mono, 2=stereo
} audio_config_t;
```

### Signal Processing Types

```c
// EEG frequency bands
typedef struct {
    float delta;            // 0.5-4 Hz
    float theta;            // 4-8 Hz
    float alpha;            // 8-13 Hz
    float beta;             // 13-30 Hz
    float gamma;            // 30-50 Hz
} eeg_band_power_t;

// Processed EEG features
typedef struct {
    uint64_t timestamp_us;
    eeg_band_power_t band_power;
    float alpha_asymmetry;  // Left - Right frontal alpha
    float total_power;
    uint8_t quality;
} eeg_features_t;

// Audio features
typedef struct {
    uint64_t timestamp_us;
    float spectrum[FFT_SIZE_AUDIO / 2];
    float thd;              // Total Harmonic Distortion
    float rms_level;        // RMS amplitude
    float peak_level;       // Peak amplitude
} audio_features_t;
```

---

## Layer 1: HAL

### GPIO (hal_gpio.h)

#### hal_gpio_set_output()
```c
status_t hal_gpio_set_output(void* port, uint8_t pin,
                             gpio_speed_t speed, gpio_pull_t pull);
```

**Description**: Configure GPIO pin as output

**Parameters**:
- `port`: GPIO port base address (e.g., `GPIOA_BASE`)
- `pin`: Pin number (0-15)
- `speed`: Output speed
  - `GPIO_SPEED_LOW`: 2 MHz
  - `GPIO_SPEED_MEDIUM`: 25 MHz
  - `GPIO_SPEED_FAST`: 50 MHz
  - `GPIO_SPEED_HIGH`: 100 MHz
- `pull`: Pull-up/down configuration
  - `GPIO_PULL_NONE`: No pull
  - `GPIO_PULL_UP`: Pull-up enabled
  - `GPIO_PULL_DOWN`: Pull-down enabled

**Returns**: `STATUS_OK` on success

**Example**:
```c
// Configure PD12 as output (LED)
hal_gpio_set_output((void*)GPIOD_BASE, 12, GPIO_SPEED_LOW, GPIO_PULL_NONE);
```

#### hal_gpio_write()
```c
void hal_gpio_write(void* port, uint8_t pin, bool value);
```

**Description**: Set GPIO pin high or low (atomic operation)

**Parameters**:
- `port`: GPIO port base address
- `pin`: Pin number
- `value`: `true` = high, `false` = low

**Example**:
```c
hal_gpio_write((void*)GPIOD_BASE, 12, true);   // LED on
hal_gpio_write((void*)GPIOD_BASE, 12, false);  // LED off
```

#### hal_gpio_read()
```c
bool hal_gpio_read(void* port, uint8_t pin);
```

**Description**: Read GPIO pin state

**Returns**: `true` if high, `false` if low

**Example**:
```c
bool button_pressed = hal_gpio_read((void*)GPIOA_BASE, 0);
```

#### hal_gpio_toggle()
```c
void hal_gpio_toggle(void* port, uint8_t pin);
```

**Description**: Toggle GPIO pin (atomic operation)

**Example**:
```c
// Blink LED
while (1) {
    hal_gpio_toggle((void*)GPIOD_BASE, 12);
    hal_timer_delay_ms(500);
}
```

---

### Timer (hal_timer.h)

#### hal_timer_init()
```c
status_t hal_timer_init(void);
```

**Description**: Initialize high-precision timer system

**Returns**: `STATUS_OK` on success

**Notes**: Must be called before using any timer functions

#### hal_timer_get_us()
```c
uint64_t hal_timer_get_us(void);
```

**Description**: Get current microsecond timestamp

**Returns**: Timestamp in microseconds since boot

**Precision**: ±1 µs

**Example**:
```c
uint64_t start = hal_timer_get_us();
// ... operation ...
uint64_t elapsed = hal_timer_get_us() - start;
printf("Took %llu us\n", elapsed);
```

#### hal_timer_delay_us()
```c
void hal_timer_delay_us(uint32_t us);
```

**Description**: Blocking delay in microseconds

**Parameters**:
- `us`: Delay duration in microseconds

**Notes**: Uses busy-wait loop, accurate but blocks CPU

**Example**:
```c
hal_timer_delay_us(100);  // Wait 100 µs
```

#### hal_timer_delay_ms()
```c
void hal_timer_delay_ms(uint32_t ms);
```

**Description**: Blocking delay in milliseconds

**Example**:
```c
hal_timer_delay_ms(1000);  // Wait 1 second
```

---

### DMA (hal_dma.h)

#### hal_dma_config()
```c
status_t hal_dma_config(dma_stream_t stream, dma_config_t* config);
```

**Description**: Configure DMA stream

**Parameters**:
- `stream`: DMA stream identifier
  - `DMA1_STREAM0` to `DMA1_STREAM7`
  - `DMA2_STREAM0` to `DMA2_STREAM7`
- `config`: DMA configuration structure
  ```c
  typedef struct {
      void* src_addr;           // Source address
      void* dst_addr;           // Destination address
      uint32_t data_length;     // Number of transfers
      dma_direction_t direction;// PERIPHERAL_TO_MEMORY, MEMORY_TO_PERIPHERAL, MEMORY_TO_MEMORY
      dma_mode_t mode;          // NORMAL, CIRCULAR
      dma_priority_t priority;  // LOW, MEDIUM, HIGH, VERY_HIGH
      uint8_t data_size;        // 1, 2, or 4 bytes
  } dma_config_t;
  ```

**Returns**: `STATUS_OK` on success

**Example**:
```c
dma_config_t config = {
    .src_addr = (void*)&SPI1->DR,
    .dst_addr = eeg_buffer,
    .data_length = 1024,
    .direction = PERIPHERAL_TO_MEMORY,
    .mode = CIRCULAR,
    .priority = VERY_HIGH,
    .data_size = 1
};
hal_dma_config(DMA2_STREAM0, &config);
```

#### hal_dma_start()
```c
status_t hal_dma_start(dma_stream_t stream);
```

**Description**: Start DMA transfer

**Example**:
```c
hal_dma_start(DMA2_STREAM0);
```

#### hal_dma_register_callback()
```c
void hal_dma_register_callback(dma_stream_t stream, dma_callback_t callback);
```

**Description**: Register callback for DMA events

**Parameters**:
- `callback`: Function pointer
  ```c
  typedef void (*dma_callback_t)(dma_event_t event);

  typedef enum {
      DMA_EVENT_HALF_TRANSFER,
      DMA_EVENT_TRANSFER_COMPLETE,
      DMA_EVENT_ERROR
  } dma_event_t;
  ```

**Example**:
```c
void dma_callback(dma_event_t event) {
    if (event == DMA_EVENT_TRANSFER_COMPLETE) {
        // Process buffer
    }
}

hal_dma_register_callback(DMA2_STREAM0, dma_callback);
```

---

### SPI (hal_spi.h)

#### hal_spi_init()
```c
status_t hal_spi_init(spi_instance_t spi, spi_config_t* config);
```

**Description**: Initialize SPI peripheral

**Parameters**:
- `spi`: SPI instance (`SPI1`, `SPI2`, `SPI3`)
- `config`: SPI configuration
  ```c
  typedef struct {
      spi_mode_t mode;          // MASTER, SLAVE
      uint32_t clock_speed;     // Hz (max 42 MHz)
      spi_cpol_t clock_polarity;// LOW, HIGH
      spi_cpha_t clock_phase;   // 1EDGE, 2EDGE
      spi_datasize_t data_size; // 8BIT, 16BIT
      bool lsb_first;           // false = MSB first
  } spi_config_t;
  ```

**Example**:
```c
spi_config_t config = {
    .mode = SPI_MODE_MASTER,
    .clock_speed = 4000000,     // 4 MHz
    .clock_polarity = SPI_CPOL_LOW,
    .clock_phase = SPI_CPHA_1EDGE,
    .data_size = SPI_DATASIZE_8BIT,
    .lsb_first = false
};
hal_spi_init(SPI1, &config);
```

#### hal_spi_transfer()
```c
status_t hal_spi_transfer(spi_instance_t spi,
                         uint8_t* tx_data, uint8_t* rx_data,
                         size_t length);
```

**Description**: Blocking SPI transfer

**Parameters**:
- `tx_data`: Data to send (or `NULL` for receive-only)
- `rx_data`: Buffer for received data (or `NULL` for send-only)
- `length`: Number of bytes

**Returns**: `STATUS_OK` on success

**Example**:
```c
uint8_t tx[4] = {0x01, 0x02, 0x03, 0x04};
uint8_t rx[4];
hal_spi_transfer(SPI1, tx, rx, 4);
```

---

## Layer 2: Drivers

### EEG Driver (eeg_driver.h)

#### eeg_driver_init()
```c
status_t eeg_driver_init(eeg_driver_t* driver, eeg_config_t* config);
```

**Description**: Initialize EEG acquisition system (ADS1299)

**Parameters**:
- `driver`: Driver instance (allocated by caller)
- `config`: EEG configuration (see Common Types)

**Returns**: `STATUS_OK` on success

**Example**:
```c
eeg_driver_t driver;
eeg_config_t config = {
    .sample_rate = 512,
    .channel_count = 19,
    .bit_depth = 24,
    .enable_filters = true,
    .enable_notch_50hz = true,
    .enable_notch_60hz = false
};

status_t result = eeg_driver_init(&driver, &config);
if (result != STATUS_OK) {
    printf("EEG init failed\n");
}
```

#### eeg_driver_start()
```c
status_t eeg_driver_start(eeg_driver_t* driver);
```

**Description**: Start EEG data acquisition

**Notes**:
- Driver must be initialized first
- Data will be written to `driver->rx_ring_buffer` (must be set by caller)

**Example**:
```c
driver.rx_ring_buffer = &g_eeg_rb;  // Set ring buffer
eeg_driver_start(&driver);
```

#### eeg_driver_stop()
```c
status_t eeg_driver_stop(eeg_driver_t* driver);
```

**Description**: Stop EEG acquisition

#### eeg_driver_get_stats()
```c
void eeg_driver_get_stats(eeg_driver_t* driver,
                         uint32_t* samples, uint32_t* overruns,
                         uint32_t* errors);
```

**Description**: Get acquisition statistics

**Parameters** (all output):
- `samples`: Total samples acquired
- `overruns`: Number of buffer overruns (data lost)
- `errors`: Number of communication errors

**Example**:
```c
uint32_t samples, overruns, errors;
eeg_driver_get_stats(&driver, &samples, &overruns, &errors);
printf("Samples: %u, Overruns: %u, Errors: %u\n",
       samples, overruns, errors);
```

---

### Audio Driver (audio_driver.h)

#### audio_driver_init()
```c
status_t audio_driver_init(audio_driver_t* driver, audio_config_t* config);
```

**Description**: Initialize audio codec (CS43L22)

**Example**:
```c
audio_driver_t driver;
audio_config_t config = {
    .sample_rate = 48000,
    .bit_depth = 24,
    .channels = 2
};
audio_driver_init(&driver, &config);
```

#### audio_driver_start_playback()
```c
status_t audio_driver_start_playback(audio_driver_t* driver);
```

**Description**: Start audio playback (output only)

#### audio_driver_start_full_duplex()
```c
status_t audio_driver_start_full_duplex(audio_driver_t* driver);
```

**Description**: Start full-duplex audio (input + output simultaneously)

**Example**:
```c
driver.rx_ring_buffer = &g_audio_rx_rb;
driver.tx_ring_buffer = &g_audio_tx_rb;
audio_driver_start_full_duplex(&driver);
```

#### audio_driver_set_volume()
```c
status_t audio_driver_set_volume(audio_driver_t* driver, uint8_t volume);
```

**Description**: Set output volume

**Parameters**:
- `volume`: 0-100 (0 = mute, 100 = maximum)

**Example**:
```c
audio_driver_set_volume(&driver, 75);  // 75% volume
```

---

## Layer 3: Data Structures

### Ring Buffer (ring_buffer.h)

#### ring_buffer_init()
```c
status_t ring_buffer_init(ring_buffer_t* rb, void* buffer,
                         size_t element_size, size_t capacity);
```

**Description**: Initialize ring buffer

**Parameters**:
- `rb`: Ring buffer structure (allocated by caller)
- `buffer`: Data buffer (must be capacity × element_size bytes)
- `element_size`: Size of each element in bytes
- `capacity`: Total number of elements (should be power of 2)

**Example**:
```c
ring_buffer_t rb;
eeg_packet_t buffer[2048];

ring_buffer_init(&rb, buffer, sizeof(eeg_packet_t), 2048);
```

#### ring_buffer_write()
```c
status_t ring_buffer_write(ring_buffer_t* rb, void* element);
```

**Description**: Write element to ring buffer (producer)

**Returns**:
- `STATUS_OK` on success
- `STATUS_BUFFER_FULL` if buffer is full

**Thread Safety**: Safe to call from ISR (SPSC only)

**Example**:
```c
eeg_packet_t packet;
// ... fill packet ...
status_t result = ring_buffer_write(&rb, &packet);
if (result == STATUS_BUFFER_FULL) {
    // Handle overflow
}
```

#### ring_buffer_read()
```c
status_t ring_buffer_read(ring_buffer_t* rb, void* element);
```

**Description**: Read element from ring buffer (consumer)

**Returns**:
- `STATUS_OK` on success
- `STATUS_BUFFER_EMPTY` if buffer is empty

**Example**:
```c
eeg_packet_t packet;
status_t result = ring_buffer_read(&rb, &packet);
if (result == STATUS_OK) {
    // Process packet
}
```

#### ring_buffer_available()
```c
size_t ring_buffer_available(ring_buffer_t* rb);
```

**Description**: Get number of available elements

**Returns**: Count of elements ready to read

**Example**:
```c
if (ring_buffer_available(&rb) >= 512) {
    // Process 512 samples
    for (int i = 0; i < 512; i++) {
        ring_buffer_read(&rb, &samples[i]);
    }
}
```

#### ring_buffer_usage_percent()
```c
uint8_t ring_buffer_usage_percent(ring_buffer_t* rb);
```

**Description**: Get buffer usage percentage

**Returns**: 0-100

**Example**:
```c
uint8_t usage = ring_buffer_usage_percent(&rb);
if (usage > 90) {
    printf("WARNING: Buffer nearly full (%d%%)\n", usage);
}
```

---

### Time Sync (time_sync.h)

#### time_sync_init()
```c
status_t time_sync_init(void);
```

**Description**: Initialize time synchronization system

**Returns**: `STATUS_OK` on success

#### time_sync_get_timestamp()
```c
uint64_t time_sync_get_timestamp(void);
```

**Description**: Get microsecond timestamp

**Returns**: Timestamp in µs since boot

**Example**:
```c
packet.timestamp_us = time_sync_get_timestamp();
```

#### time_sync_start_measure()
```c
void time_sync_start_measure(performance_marker_t* marker);
```

**Description**: Start performance measurement

**Example**:
```c
performance_marker_t marker;
time_sync_start_measure(&marker);
// ... code to measure ...
uint32_t elapsed = time_sync_end_measure(&marker);
```

---

## Layer 4: Signal Processing

### FFT Engine (fft_engine.h)

#### fft_init()
```c
status_t fft_init(fft_instance_t* fft, fft_config_t* config);
```

**Description**: Initialize FFT engine

**Parameters**:
- `config`: FFT configuration
  ```c
  typedef struct {
      uint16_t fft_size;          // 64, 128, 256, 512, 1024, 2048, 4096
      fft_window_t window_type;   // NONE, HANN, HAMMING, BLACKMAN
      float sample_rate;          // Hz
      bool use_overlap;           // 50% overlap
      float overlap_factor;       // 0.0-0.75
  } fft_config_t;
  ```

**Example**:
```c
fft_instance_t fft;
fft_config_t config = {
    .fft_size = 512,
    .window_type = FFT_WINDOW_HANN,
    .sample_rate = 512.0f,
    .use_overlap = false,
    .overlap_factor = 0.0f
};
fft_init(&fft, &config);
```

#### fft_forward()
```c
status_t fft_forward(fft_instance_t* fft, float* input, complex_t* output);
```

**Description**: Compute forward FFT

**Parameters**:
- `input`: Time-domain input (real, size = fft_size)
- `output`: Frequency-domain output (complex, size = fft_size/2)

**Example**:
```c
float signal[512];
complex_t spectrum[256];
fft_forward(&fft, signal, spectrum);
```

#### fft_calculate_magnitude()
```c
void fft_calculate_magnitude(complex_t* fft_output, float* magnitude, size_t length);
```

**Description**: Calculate magnitude spectrum

**Example**:
```c
float magnitude[256];
fft_calculate_magnitude(spectrum, magnitude, 256);
```

---

### EEG Processor (eeg_processor.h)

#### eeg_processor_init()
```c
status_t eeg_processor_init(eeg_processor_t* processor,
                            float sample_rate, uint8_t channel_count);
```

**Description**: Initialize EEG signal processor

**Example**:
```c
eeg_processor_t processor;
eeg_processor_init(&processor, 512.0f, 19);
```

#### eeg_processor_process_window()
```c
status_t eeg_processor_process_window(eeg_processor_t* processor,
                                      eeg_packet_t* window, size_t length,
                                      eeg_features_t* features);
```

**Description**: Process window of EEG data

**Parameters**:
- `window`: Array of EEG packets
- `length`: Window length (typically 512 for 1 second @ 512 Hz)
- `features`: Output features

**Example**:
```c
eeg_packet_t window[512];
eeg_features_t features;

// Read 512 samples from ring buffer
for (int i = 0; i < 512; i++) {
    ring_buffer_read(&eeg_rb, &window[i]);
}

// Process
eeg_processor_process_window(&processor, window, 512, &features);

// Use features
printf("Alpha power: %.2f\n", features.band_power.alpha);
```

#### eeg_processor_calculate_band_power()
```c
status_t eeg_processor_calculate_band_power(eeg_processor_t* processor,
                                            float* signal, size_t length,
                                            eeg_band_power_t* bands);
```

**Description**: Calculate band power from single-channel signal

**Example**:
```c
float channel_0[512];
eeg_band_power_t bands;
eeg_processor_calculate_band_power(&processor, channel_0, 512, &bands);
```

---

## Layer 5: Application

### Neurofeedback Engine (neurofeedback_engine.h)

#### neurofeedback_init()
```c
status_t neurofeedback_init(neurofeedback_engine_t* engine,
                            feedback_config_t* config,
                            audio_driver_t* audio_driver);
```

**Description**: Initialize neurofeedback engine

**Parameters**:
- `config`: Neurofeedback configuration
  ```c
  typedef struct {
      feedback_mode_t mode;       // ALPHA_TRAINING, FOCUS, RELAXATION, etc.
      float alpha_threshold;      // Threshold for alpha reward
      float focus_threshold;      // Threshold for focus score
      uint16_t ramp_time_ms;      // Modulation ramp time
      bool auto_calibrate;        // Automatic threshold adjustment
  } feedback_config_t;
  ```

**Example**:
```c
neurofeedback_engine_t engine;
feedback_config_t config;
neurofeedback_load_preset(FEEDBACK_MODE_ALPHA_TRAINING, &config);
neurofeedback_init(&engine, &config, &audio_driver);
```

#### neurofeedback_start()
```c
status_t neurofeedback_start(neurofeedback_engine_t* engine);
```

**Description**: Start neurofeedback session

#### neurofeedback_update()
```c
void neurofeedback_update(neurofeedback_engine_t* engine,
                         eeg_features_t* eeg_features,
                         audio_features_t* audio_features);
```

**Description**: Update neurofeedback (call in main loop)

**Example**:
```c
// Main loop
while (1) {
    if (ring_buffer_available(&eeg_rb) >= 512) {
        // Process EEG
        eeg_processor_process_window(&eeg_proc, eeg_window, 512, &eeg_features);

        // Process audio
        audio_processor_process_window(&audio_proc, audio_window, 2048, &audio_features);

        // Update neurofeedback
        neurofeedback_update(&engine, &eeg_features, &audio_features);
    }
}
```

#### neurofeedback_get_state()
```c
void neurofeedback_get_state(neurofeedback_engine_t* engine,
                             neurofeedback_state_t* state);
```

**Description**: Get current neurofeedback state

**Returns**: State structure containing:
- Current brain state
- Focus/relaxation scores
- Current modulation values
- Reward/penalty counts

---

## Usage Examples

### Complete Initialization

```c
int main(void) {
    // 1. Initialize HAL
    hal_timer_init();
    hal_gpio_set_output((void*)GPIOD_BASE, 12, GPIO_SPEED_LOW, GPIO_PULL_NONE);

    // 2. Initialize time sync
    time_sync_init();

    // 3. Initialize ring buffers
    ring_buffer_t eeg_rb, audio_rb;
    static eeg_packet_t eeg_buffer[2048];
    static audio_packet_t audio_buffer[8192];
    ring_buffer_init(&eeg_rb, eeg_buffer, sizeof(eeg_packet_t), 2048);
    ring_buffer_init(&audio_rb, audio_buffer, sizeof(audio_packet_t), 8192);

    // 4. Initialize drivers
    eeg_driver_t eeg_driver;
    audio_driver_t audio_driver;

    eeg_config_t eeg_config = {512, 19, 24, true, true, false};
    eeg_driver_init(&eeg_driver, &eeg_config);
    eeg_driver.rx_ring_buffer = &eeg_rb;

    audio_config_t audio_config = {48000, 24, 2};
    audio_driver_init(&audio_driver, &audio_config);
    audio_driver.rx_ring_buffer = &audio_rb;

    // 5. Initialize processors
    eeg_processor_t eeg_proc;
    audio_processor_t audio_proc;
    eeg_processor_init(&eeg_proc, 512.0f, 19);
    audio_processor_init(&audio_proc, 48000.0f);

    // 6. Initialize neurofeedback
    neurofeedback_engine_t nf_engine;
    feedback_config_t nf_config;
    neurofeedback_load_preset(FEEDBACK_MODE_ALPHA_TRAINING, &nf_config);
    neurofeedback_init(&nf_engine, &nf_config, &audio_driver);

    // 7. Start acquisition
    eeg_driver_start(&eeg_driver);
    audio_driver_start_full_duplex(&audio_driver);
    neurofeedback_start(&nf_engine);

    // 8. Main loop
    while (1) {
        // ... processing ...
    }
}
```

### Main Processing Loop

```c
while (1) {
    // Check if we have enough EEG data
    if (ring_buffer_available(&eeg_rb) >= 512) {
        // Read 512 EEG samples
        eeg_packet_t eeg_window[512];
        for (int i = 0; i < 512; i++) {
            ring_buffer_read(&eeg_rb, &eeg_window[i]);
        }

        // Process EEG
        eeg_features_t eeg_features;
        eeg_processor_process_window(&eeg_proc, eeg_window, 512, &eeg_features);

        // Check if we have enough audio data
        if (ring_buffer_available(&audio_rb) >= 2048) {
            // Read 2048 audio samples
            audio_packet_t audio_window[2048];
            for (int i = 0; i < 2048; i++) {
                ring_buffer_read(&audio_rb, &audio_window[i]);
            }

            // Process audio
            audio_features_t audio_features;
            audio_processor_process_window(&audio_proc, audio_window, 2048, &audio_features);

            // Update neurofeedback
            neurofeedback_update(&nf_engine, &eeg_features, &audio_features);
        }
    }

    // Small delay to prevent CPU hogging
    hal_timer_delay_us(1000);
}
```

### Performance Monitoring

```c
void monitor_performance(void) {
    performance_marker_t loop_marker;

    while (1) {
        time_sync_start_measure(&loop_marker);

        // ... main loop processing ...

        uint32_t loop_time = time_sync_end_measure(&loop_marker);

        if (loop_time > 50000) {  // 50ms warning
            printf("[WARNING] Loop took %u us\n", loop_time);
        }

        // Print statistics every second
        static uint32_t last_print = 0;
        uint32_t now = time_sync_get_timestamp() / 1000;
        if (now - last_print >= 1000) {
            last_print = now;

            printf("Loop timing: min=%u, max=%u, avg=%u us\n",
                   loop_marker.min_us, loop_marker.max_us,
                   loop_marker.avg_us);

            // Reset stats
            loop_marker.count = 0;
            loop_marker.min_us = UINT32_MAX;
            loop_marker.max_us = 0;
        }
    }
}
```

---

**Document Version**: 1.0
**Author**: NS Development Team
**Last Updated**: 2025-11-13
