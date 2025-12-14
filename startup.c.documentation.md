# startup.c — Detailed reference & maintenance guide

Repository location:
- File: NS/src/layer0_baremetal/startup.c
- URL: https://github.com/whoIsStella/A_V/blob/main/NS/src/layer0_baremetal/startup.c

Purpose
-------
Low-level startup code executed before main(). Initializes C runtime, handles reset, defines interrupt vector table, and provides default interrupt handlers.

Why this file matters
---------------------
- First code executed after power-on or reset
- Sets up C runtime environment (data/bss sections)
- Defines interrupt vector table (critical for all interrupts)
- Incorrect implementation prevents system boot

Typical structure
----------------
1. Vector table:
   - Located at address 0x00000000 (or 0x08000000 for Flash)
   - First entry: Initial stack pointer (from linker script)
   - Second entry: Reset handler address
   - Subsequent entries: Exception and interrupt handlers
   - Must match MCU's expected layout (STM32F4: 98+ vectors)

2. Reset_Handler:
   - Copy .data section from Flash to RAM
   - Zero-initialize .bss section
   - Call SystemInit() (clock configuration)
   - Call __libc_init_array() (C++ constructors, if used)
   - Call main()
   - Enter infinite loop if main returns (should never happen)

3. Default interrupt handlers:
   - Weak definitions for all interrupts
   - Default: Infinite loop (while(1))
   - Can be overridden by defining same symbol elsewhere
   - Catch unexpected interrupts during development

4. Exception handlers:
   - HardFault_Handler: Serious errors (memory access, illegal instruction)
   - MemManage_Handler: Memory protection violations
   - BusFault_Handler: Bus errors
   - UsageFault_Handler: Undefined instructions, div by zero

Critical sections
----------------
.data initialization:
- Source: Flash (LMA - Load Memory Address)
- Destination: RAM (VMA - Virtual Memory Address)
- Size: From linker script symbols

.bss initialization:
- Set all static/global uninitialized variables to zero
- Required by C standard

SystemInit():
- Configures PLL for desired system clock
- Enables FPU if using floating point
- Sets flash wait states for clock speed
- Typically provided by CMSIS startup files

Integration with linker script
------------------------------
- Linker provides symbols: _sidata, _sdata, _edata, _sbss, _ebss
- Stack pointer: _estack (top of RAM)
- Heap location: _end to _estack - STACK_SIZE

Common pitfalls
---------------
- Wrong vector table alignment: Must be 512-byte aligned on Cortex-M4
- Missing .data copy: Initialized globals have wrong values
- Missing .bss zero: Static variables not zero
- Stack overflow: Stack collides with heap/data
- Wrong reset handler address: System doesn't boot

Vector table relocation:
- Can relocate vector table to RAM for dynamic handler update
- Use SCB->VTOR register
- Useful for bootloaders

Debugging tips
-------------
- If system doesn't boot: Check reset handler is called
- If crashes immediately: Check stack pointer validity
- If global variables wrong: Check .data copy
- If random crashes: Likely stack overflow
- Use debugger to step through Reset_Handler

Where to look next
------------------
- Linker script (.ld file) for memory layout
- STM32F4 reference manual for vector table layout
- main.c for application entry point
- CMSIS core documentation for Cortex-M details
- Initializes C runtime environment (copy .data, zero .bss)
- Defines interrupt vector table
- Provides default exception handlers
- Critical for system stability and debugging

Key components
--------------
- **Vector table**: Array of function pointers at address 0x08000000 (flash) or 0x20000000 (RAM boot)
- **Reset_Handler**: Entry point, calls SystemInit, copies .data, zeros .bss, calls main()
- **Default_Handler**: Infinite loop for unhandled interrupts
- **Stack pointer**: Initial SP from linker script _estack symbol

Exception handlers
------------------
- Hard fault, bus fault, usage fault handlers for debugging
- SysTick handler for timing (if using HAL tick or RTOS)
- DMA stream handlers: DMA1_Stream0_IRQHandler through DMA2_Stream7_IRQHandler
- SPI/I2S handlers: SPI1_IRQHandler, SPI2_IRQHandler, etc.
- EXTI handlers for GPIO interrupts

Customization
-------------
- Weak attribute allows application to override default handlers
- Add specific ISR implementations for peripherals in use
- Ensure all enabled interrupts have handlers defined

Where to look next
------------------
- Linker script: Memory layout and section placement
- system_stm32f4xx.c: SystemInit implementation
- main.c: Application entry point
- STM32F407 datasheet: Vector table addresses and interrupt numbers
