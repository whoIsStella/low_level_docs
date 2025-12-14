# hal_gpio.c — Detailed reference & maintenance guide

Repository location:
- File: NS/src/layer1_hal/hal_gpio.c
- URL: https://github.com/whoIsStella/A_V/blob/main/NS/src/layer1_hal/hal_gpio.c

Purpose
-------
Implements the GPIO HAL declared in hal_gpio.h for STM32F4-like MCUs. This file provides:
- Clock enable logic for GPIO ports
- Register-level pin configuration (MODER, PUPDR, OSPEEDR, OTYPER, AFR)
- Atomic pin writes (via BSRR), reads (IDR), and toggle helpers

Implementation highlights
-------------------------
- RCC_AHB1ENR register manipulation:
  - Enables GPIO port clocks by setting the appropriate bit derived from port index.
- Port identification:
  - get_port_index computes port index from port base address assuming contiguous 0x400 spacing between ports (GPIOA 0x400, GPIOB +0x400, etc.)
- Pin configuration:
  - hal_gpio_init configures MODER, PUPDR, OSPEEDR, OTYPER and optionally AFRL/AFRH for alternate functions.
- Atomic set/reset:
  - hal_gpio_write uses BSRR register for atomic operations (safe in interrupts).
- Toggle uses ODR XOR (read-modify-write). For concurrency-safe toggle, replace by two atomic writes or use critical sections.

Assumptions & couplings
-----------------------
- Port base addresses (GPIOA_BASE..GPIOF_BASE) and RCC_AHB1ENR are declared and correct for the target MCU.
- get_port_index assumes base addresses are contiguous spaced by 0x400. This is true for many STM32 MCUs. If your MCU has different spacing, adjust computation.
- hal_gpio_init uses `for (volatile int i = 0; i < 10; i++);` as a short delay after enabling clock — sufficient on many MCUs, but a more robust method is to poll an RCC register or read-back the clock enable bit.

Behavioral notes & safety
-------------------------
- hal_gpio_init does not modify current output data (ODR) level — if you need a defined startup level, call hal_gpio_write after init.
- hal_gpio_toggle is not atomic. If called concurrently with other contexts that mutate ODR, use ENTER_CRITICAL/EXIT_CRITICAL macros or use alternate approach: read BSRR or track state in software.
- Alternate function configuration:
  - For pins <8 use AFRL; for >=8 use AFRH. Code handles pin indexing properly.

Extending and porting
---------------------
- Add checks to hal_gpio_init for reserved pins or pins that are not present on the specific MCU package.
- To support more ports (e.g., GPIOG..GPIOI), add their base addresses and ensure get_port_index calculation covers them.
- For safety-critical systems, add return codes or callbacks for clock enable failure.

Debugging tips
--------------
- If pin mode doesn't appear to change:
  - Ensure port clock is enabled: check RCC_AHB1ENR.
  - Confirm no other code later overwrites MODER/AFR (peripheral initialization often reconfigures pins).
- If alternate function doesn't route peripheral signals:
  - Verify chosen AF number is correct for that pin/peripheral in MCU datasheet.
  - Confirm peripheral clock is enabled and properly configured.

Examples
--------
Configure SPI SCK pin:
```c
gpio_config_t cfg = {
    .port = (void*)GPIOA_BASE,
    .pin = 5,
    .mode = GPIO_MODE_ALTERNATE,
    .pull = GPIO_PULL_NONE,
    .speed = GPIO_SPEED_VERY_HIGH,
    .alternate_function = 5
};
hal_gpio_init(&cfg);
```

Make a pin an output and set it:
```c
hal_gpio_set_output((void*)GPIOB_BASE, 3, GPIO_SPEED_HIGH, GPIO_PULL_NONE);
hal_gpio_write((void*)GPIOB_BASE, 3, true);
```

Maintenance checklist
---------------------
- If you add support for MCU families with different register layout, factor per-MCU offsets into a separate header `gpio_regs.h` or into hardware_config.h.
- Review all delays after enabling clocks for adequate stabilization on slow clock domains.
- If adding EXTI/IRQ attach behavior, ensure HAL exposes a safe API to map pin-to-exti and register callbacks.

Where to look next
------------------
- hal_gpio.h for API contract.
- hardware_config.h for port aliasing and macro definitions.
- startup and linker for early initializations that might affect GPIO usage before main().
