# HAL Quick Reference Cheat Sheet

## GPIO (hal_gpio.h/c)
```c
// Initialize pin
gpio_config_t cfg = {
    .mode = GPIO_MODE_OUTPUT,
    .pull = GPIO_PULL_NONE,
    .speed = GPIO_SPEED_HIGH
};
hal_gpio_init(GPIOA, PIN_5, &cfg);

// Digital I/O
hal_gpio_write(GPIOA, PIN_5, true);
bool state = hal_gpio_read(GPIOA, PIN_5);
hal_gpio_toggle(GPIOA, PIN_5);
```

## DMA (hal_dma.h/c)
```c
// Initialize DMA
dma_handle_t dma = {
    .dma_base = (void*)DMA2_BASE,
    .stream = 0,
    .channel = 3,
    .direction = DMA_DIR_PERIPHERAL_TO_MEMORY,
    .mode = DMA_MODE_CIRCULAR,
    .double_buffer = true,
    .transfer_complete_callback = my_callback
};
hal_dma_init(&dma);

// Start transfer
hal_dma_start(&dma, (uint32_t)&SPI1->DR, 
              (uint32_t)buffer, 512);
```

## SPI (hal_spi.h/c)
```c
// Initialize SPI
spi_config_t cfg = {
    .mode = SPI_MODE_0,
    .baudrate = 10000000,  // 10 MHz
    .data_size = SPI_DATASIZE_8BIT,
    .enable_dma = true
};
hal_spi_init((void*)SPI1_BASE, &cfg);

// Blocking transfer
uint8_t rx = hal_spi_transfer_byte((void*)SPI1_BASE, 0xFF);

// DMA transfer
hal_spi_transfer_dma((void*)SPI1_BASE, tx_buf, rx_buf, 256);
```

## I2S (hal_i2s.h)
```c
// Initialize I2S
i2s_config_t cfg = {
    .mode = I2S_MODE_MASTER_TX,
    .standard = I2S_STANDARD_PHILIPS,
    .data_format = I2S_DATAFORMAT_24B,
    .audio_freq = I2S_AUDIOFREQ_48K,
    .enable_dma = true
};
hal_i2s_init((void*)SPI2_BASE, &cfg);

// Start audio
hal_i2s_transmit_dma((void*)SPI2_BASE, audio_buffer, 512);
```

## Timer (hal_timer.h)
```c
// Get timestamps
uint64_t us = hal_timer_get_us();
uint64_t ms = hal_timer_get_ms();

// Delays
hal_timer_delay_us(100);
hal_timer_delay_ms(10);

// Performance measurement
performance_marker_t marker;
hal_timer_start_measure(&marker);
// ... code to measure ...
uint32_t duration = hal_timer_end_measure(&marker);
```

## Common Patterns

### GPIO for SPI Chip Select
```c
// Manual CS control
hal_gpio_write(GPIOA, CS_PIN, 0);  // Assert CS
hal_spi_transfer(SPI1_BASE, tx, rx, len);
hal_gpio_write(GPIOA, CS_PIN, 1);  // Release CS
```

### DMA Double-Buffering
```c
// Set up two buffers
hal_dma_set_double_buffer(&dma, (uint32_t)buf0, (uint32_t)buf1);

// In callback:
void dma_callback(void) {
    uint8_t active = hal_dma_get_current_buffer(&dma);
    // Process inactive buffer (1 - active)
    process_buffer(active == 0 ? buf1 : buf0);
}
```

### Interrupt Priorities (Lower = Higher Priority)
```c
#define IRQ_PRIORITY_EEG_DMA    0  // Highest
#define IRQ_PRIORITY_AUDIO_DMA  1
#define IRQ_PRIORITY_TIMER      2
#define IRQ_PRIORITY_UART       3  // Lowest
```

## Error Handling
```c
status_t result = hal_spi_init(SPI1_BASE, &cfg);
if (result != STATUS_OK) {
    // Handle error
    switch(result) {
        case STATUS_INVALID_PARAM: // Bad config
        case STATUS_TIMEOUT:       // Init timeout
        case STATUS_HARDWARE_ERROR:// HW failure
        default:                   // Unknown
    }
}
```

## Register Access (When HAL Not Sufficient)
```c
// Direct register manipulation
#define SPI1_CR1  (*(volatile uint32_t*)(SPI1_BASE + 0x00))
#define SPI_CR1_SPE  (1 << 6)  // SPI Enable bit

SPI1_CR1 |= SPI_CR1_SPE;   // Enable SPI
SPI1_CR1 &= ~SPI_CR1_SPE;  // Disable SPI
```

## Critical Sections
```c
ENTER_CRITICAL();  // Disable interrupts
// Atomic operation
shared_counter++;
EXIT_CRITICAL();   // Re-enable interrupts
```

## Common Constants
- **Clock Frequencies**: Defined in hardware_config.h
  - SYSTEM_CLOCK_HZ: 168000000 (168 MHz typical)
  - APB1_CLOCK_HZ: 42000000 (42 MHz)
  - APB2_CLOCK_HZ: 84000000 (84 MHz)

- **DMA Controllers**: DMA1_BASE, DMA2_BASE
- **SPI Peripherals**: SPI1_BASE (APB2), SPI2_BASE/SPI3_BASE (APB1)
- **GPIO Ports**: GPIOA_BASE through GPIOI_BASE

## Quick Debugging
```c
// Toggle LED for visual debug
hal_gpio_toggle(GPIOA, LED_PIN);

// Timing measurement
uint32_t start = hal_timer_get_us();
function_to_profile();
uint32_t duration = hal_timer_get_us() - start;

// Check DMA transfer count
uint32_t remaining = hal_dma_get_remaining(&dma_handle);
```

## Memory Alignment
```c
// Align buffers for DMA
__attribute__((aligned(4))) uint8_t dma_buffer[512];

// Check alignment
assert(IS_ALIGNED_4(dma_buffer));
```

## Typical Initialization Order
1. `hal_timer_init()` - Enable timing
2. `hal_gpio_init()` - Configure pins
3. `hal_dma_init()` - Set up DMA
4. `hal_spi_init()` or `hal_i2s_init()` - Peripherals
5. Start DMA transfers
6. Enable interrupts (NVIC)
# HAL Quick Reference for Implementers

## Critical Configuration Macros

### Clock & Timing
```c
SYSTEM_CLOCK_HZ     168000000   // Core clock
APB1_CLOCK_HZ       42000000    // SPI2/3, I2S2/3, TIM2-7
APB2_CLOCK_HZ       84000000    // SPI1, TIM1, TIM8-11
```

### DMA Priorities (0=low, 3=very high)
```c
EEG_DMA_PRIORITY    3  // Highest - 512Hz critical timing
AUDIO_DMA_PRIORITY  2  // High - 48kHz real-time
DISPLAY_DMA_PRIORITY 0 // Low - non-critical
```

### IRQ Priorities (lower number = higher priority)
```c
IRQ_PRIORITY_EEG    0  // Highest
IRQ_PRIORITY_AUDIO  1
IRQ_PRIORITY_TIMER  2
IRQ_PRIORITY_USB    5
```

## Common DMA Patterns

### Circular Mode with Double-Buffer
```c
dma_handle_t dma_cfg = {
    .dma_base = (void*)DMA2_BASE,
    .stream = 0,
    .channel = 3,
    .direction = DMA_PERIPH_TO_MEM,
    .mode = DMA_MODE_CIRCULAR,
    .double_buffer = true,
    .memory_increment = true,
    .peripheral_increment = false,
    .memory_size = DMA_SIZE_WORD,
    .peripheral_size = DMA_SIZE_WORD,
    .priority = DMA_PRIORITY_VERY_HIGH
};
hal_dma_init(&dma_cfg);
hal_dma_configure_transfer(&dma_cfg, periph_addr, mem0_addr, mem1_addr, count);
hal_dma_start(&dma_cfg);
```

### ISR Callback Pattern
```c
void DMA2_Stream0_IRQHandler(void) {
    hal_dma_irq_handler(&eeg_dma_handle);
}

void eeg_dma_complete_callback(void) {
    uint8_t active = hal_dma_get_current_target(&eeg_dma_handle);
    // Process inactive buffer while DMA fills active
    process_buffer(buffer[1 - active]);
}
```

## SPI Configuration Cheat

### EEG ADC (ADS1299)
```c
SPI Mode: 1 (CPOL=0, CPHA=1)
Max Speed: 20MHz (use 8MHz for safety)
Data Size: 8-bit
CS: Manual GPIO control
```

### Display (ILI9341)
```c
SPI Mode: 0 or 3
Max Speed: 10-40MHz
Data Size: 8-bit
CS: Hardware or manual
```

## I2S Configuration Cheat

### Audio Codec (CS43L22/PCM5102)
```c
Standard: I2S_STANDARD_PHILIPS
Sample Rate: 48kHz
Data Format: I2S_DATAFORMAT_24B  // 24-bit on 32-bit frame
MCLK: Enabled (256 × Fs = 12.288MHz)
Mode: Master Full-Duplex
```

## Memory Alignment Rules

### DMA Requirements
```c
Byte transfers:    No alignment required
Halfword (16-bit): 2-byte alignment (address & 0x1 == 0)
Word (32-bit):     4-byte alignment (address & 0x3 == 0)
```

### Validation
```c
if (!IS_ALIGNED_4(buffer)) return STATUS_INVALID_PARAM;
```

### Alignment Macro
```c
uint8_t buffer[SIZE] __attribute__((aligned(4)));
```

## Sample Size & NDTR Calculation

### NDTR = Number of Data items to Transfer
```c
// EEG: 24-bit samples, 8 channels + 3 status bytes = 27 bytes/packet
// Transfer as bytes
NDTR = 27;  data_size = DMA_SIZE_BYTE

// Or as words (must be word-aligned)
NDTR = 7;  data_size = DMA_SIZE_WORD  // 27 bytes / 4 = 6.75, round up
```

### Audio I2S
```c
// 2 channels (stereo), 24-bit in 32-bit frame
// NDTR counts samples (L+R pairs), not bytes
NDTR = 1024;  // For 1024 stereo frames
```

## Common Error Codes & Recovery

### STATUS_DMA_ERROR
**Causes:** Bus error, address error, FIFO overrun  
**Recovery:**
1. Stop DMA: `hal_dma_stop(handle)`
2. Clear flags: `hal_dma_abort(handle)`
3. Check addresses, alignment, peripheral config
4. Restart: `hal_dma_start(handle)`

### STATUS_TIMEOUT
**Causes:** Peripheral not ready, clock not enabled, wrong config  
**Recovery:**
1. Verify peripheral clock enabled (RCC)
2. Check peripheral enable bit (SPE, I2SE)
3. Verify DMA request enable in peripheral
4. Increase timeout value if timing is tight

### STATUS_BUFFER_FULL/EMPTY
**Causes:** Consumer too slow / producer too slow  
**Recovery:**
1. Check ring buffer size (increase if needed)
2. Optimize processing in callbacks
3. Monitor with `ring_buffer_usage_percent()`
4. Use bulk operations for efficiency

## GPIO Quick Setup

```c
// SPI pins (AF5 for SPI1/2, AF6 for SPI3)
gpio_config_t spi_pin = {
    .port = GPIOA,
    .pin = 5,  // SCK
    .mode = GPIO_MODE_ALTERNATE,
    .speed = GPIO_SPEED_HIGH,
    .pull = GPIO_PULL_NONE,
    .alternate_function = 5  // AF5 for SPI1
};
hal_gpio_init(&spi_pin);
```

## ISR Callback Rules

1. **Keep it SHORT** (<10µs for high-priority ISRs)
2. **No blocking** (no while loops, delays, or polling)
3. **Set flags, don't process** (defer to main loop)
4. **Volatile shared variables** (for ISR ↔ main communication)
5. **NVIC priority < 5** for critical paths (EEG, audio)
6. **Check for errors** (OVR, TE, FE flags)

## Debug Quick Checks

**No DMA transfer:**
- [ ] DMA clock enabled? (RCC_AHB1ENR)
- [ ] Stream/channel correct for peripheral?
- [ ] Peripheral DMA enable bit set? (DMAEN in peripheral CR)
- [ ] NDTR > 0?
- [ ] Addresses valid and aligned?

**Data corruption:**
- [ ] Buffer alignment correct?
- [ ] NDTR matches buffer size?
- [ ] No CPU access during DMA transfer?
- [ ] Circular mode properly configured?

**IRQ not firing:**
- [ ] NVIC interrupt enabled?
- [ ] Interrupt enable in DMA CR? (TCIE, HTIE, TEIE)
- [ ] Handler function name matches vector table?
- [ ] Flags cleared in handler?
