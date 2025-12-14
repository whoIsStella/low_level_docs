# hal_gpio.h — Detailed reference & maintenance guide

Repository location:
- File: NS/include/layer1_hal/hal_gpio.h
- URL: https://github.com/whoIsStella/A_V/blob/main/NS/include/layer1_hal/hal_gpio.h

Purpose
-------
This header declares a minimal HAL for GPIO control on an STM32-like MCU. The goal is to provide a small safe API for:
- Pin initialization (mode, pull, speed, alternate function)
- Atomic write operations (via BSRR)
- Read and toggle helpers
- Short convenience APIs for setting pins as input/output

Design notes
------------
- The API uses `void* port` arguments (raw base addresses such as GPIOA) rather than strongly typed peripheral pointers. This keeps the header generic and small but requires the caller to pass the correct base constant from hardware_config.h or board definitions.
- The majority of register manipulation is in hal_gpio.c; this header describes the types and function signatures only.
- All functions return status_t when they perform configuration; read/write/toggle operations are void/bool to optimize ISR usage.

Types and fields
----------------
- gpio_mode_t: input, output, alternate, analog — maps to MODER register fields.
- gpio_pull_t: no pull, up, down — maps to PUPDR fields.
- gpio_speed_t: speed options. For STM32F4 these map to OSPEEDR.
- gpio_config_t:
  - port: base address pointer (e.g., (void*)GPIOA_BASE)
  - pin: 0..15
  - mode: from gpio_mode_t
  - pull, speed, alternate_function: used when mode == ALTERNATE

API semantics
-------------
- hal_gpio_init(const gpio_config_t* config)
  - Enables the port clock and programs MODER, PUPDR, OSPEEDR, OTYPER, AFR registers.
  - Returns STATUS_INVALID_PARAM if config is null or pin out of range.
  - Does not change output level (use hal_gpio_write to set an initial level).
- hal_gpio_write(void* port, uint8_t pin, bool value)
  - Uses BSRR to set or reset a pin atomically (safe in ISR contexts).
- hal_gpio_read(...)
  - Reads IDR and returns boolean.
- hal_gpio_toggle(...)
  - Toggles ODR (non-atomic read-modify-write). This is fine in single-threaded/bare-metal code but if multiple contexts may toggle concurrently, replace with atomic operations (BSRR).
- hal_gpio_set_output / hal_gpio_set_input convenience wrappers create a config and call hal_gpio_init().

Hardware couplings
------------------
- hal_gpio.c assumes RCC_AHB1ENR register exists at RCC_BASE + 0x30. For a different MCU or RCC layout, modify the offset or use CMSIS-provided macros.
- Port base addresses (GPIOA_BASE etc.) in hal_gpio.c must match the MCU. If you change MCU in hardware_config.h, update these addresses.
- Alternate function mapping is done by writing into AFRL/AFRH; ensure pin index math matches MCU's AFR layout.

Usage patterns & examples
-------------------------
Set a pin as output and toggle it:
```c
hal_gpio_set_output((void*)GPIOB_BASE, 3, GPIO_SPEED_MEDIUM, GPIO_PULL_NONE);
hal_gpio_write((void*)GPIOB_BASE, 3, true);
hal_gpio_toggle((void*)GPIOB_BASE, 3);
```

Configure a pin for SPI alternate function:
```c
gpio_config_t spi_sck = {
    .port = (void*)GPIOA_BASE,
    .pin = 5,
    .mode = GPIO_MODE_ALTERNATE,
    .pull = GPIO_PULL_NONE,
    .speed = GPIO_SPEED_VERY_HIGH,
    .alternate_function = 5 // AF5 for SPI1 on many STM32s
};
hal_gpio_init(&spi_sck);
```

Thread-safety and IRQ considerations
-----------------------------------
- hal_gpio_write uses BSRR to ensure atomic set/reset — safe to call from ISRs.
- hal_gpio_toggle reads-modifies-writes ODR; avoid using toggle in concurrent contexts unless protected by ENTER_CRITICAL()/EXIT_CRITICAL().
- hal_gpio_init should not be performed in ISR context.

Extending the API
-----------------
- Add an interrupt attach/detach API to configure EXTI lines and NVIC priorities.
- Provide fast inline macros for direct register access when performance-critical.

Debugging tips
--------------
- If a pin doesn't respond as expected:
  - Confirm clock enable for the port (RCC AHB1ENR).
  - Verify alternate function number for the chosen pin — misconfigured AF silently misroutes peripheral signals.
  - Ensure OTYPER and OSPEEDR are appropriate for the intended electrical behavior.

Maintenance checklist
---------------------
- If port base addresses or RCC layout change, update hal_gpio.c constants.
- If you need stronger type safety, replace void* port with a struct pointer typedef generated from device headers or a simple enum-to-base mapping.
- If supporting multiple MCUs, factor out per-MCU constants into hardware_config.h or a MCU-specific header.

Where to look next
------------------
- hal_gpio.c: implementation details and register offsets.
- hardware_config.h: port base aliases used by application code.
- linker_script.ld & startup.c: if you plan to use GPIO in early boot (before SystemInit() completes), check that peripheral clocks and necessary initializers are in place.
```