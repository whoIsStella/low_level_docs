# hal_dma.h — Detailed reference & maintenance guide

Repository location:
- File: NS/include/layer1_hal/hal_dma.h
- URL: https://github.com/whoIsStella/A_V/blob/main/NS/include/layer1_hal/hal_dma.h

Purpose
-------
This header declares the HAL (Hardware Abstraction Layer) API and types for DMA (Direct Memory Access). DMA is used for high-throughput, low-CPU-overhead transfers — critical for EEG acquisition and audio streaming in this project.

It defines:
- DMA configuration enums (direction, data size, priority, mode)
- Callback typedefs and the dma_handle_t structure
- The HAL public API prototypes for init/start/stop/status/double-buffer control and IRQ handler.

Important design decisions
--------------------------
- dma_handle_t is an in-memory configuration struct. It stores both user configuration (direction, sizes, stream/channel, callbacks) and internal state flags (initialized, enabled). The HAL implementation (hal_dma.c) expects this structure to be populated before calling hal_dma_init().
- The API uses numeric addresses for peripheral and memory endpoints when starting transfers. This keeps the API direct and avoids ownership assumptions about peripheral register wrappers.
- Callbacks are simple function pointers (no context pointer). If you need per-transfer context, extend dma_callback_t to accept a void* context and add a context field to dma_handle_t.

Key types & fields
------------------
- dma_direction_t: direction of the transfer. Match to hardware encoding in hal_dma.c.
- dma_data_size_t: width of transfers for peripheral and memory; must map to hardware PSIZE/MSIZE fields.
- dma_priority_t: used to select stream priority bits.
- dma_mode_t: normal or circular. Circular is used for continuous acquisition.
- dma_callback_t: signature: void (*)(void). Called from ISR context (interrupt disabled briefly). Callbacks must be short and non-blocking.
- dma_handle_t:
  - dma_base: base address for DMA controller (ex: (void*)DMA1_BASE or DMA2_BASE)
  - stream, channel: hardware indices 0..7
  - peripheral_increment, memory_increment: whether addresses advance after each beat
  - double_buffer: whether DBM is used; when true, hal_dma_set_double_buffer() must be used
  - transfer_complete_callback / half_transfer_callback / transfer_error_callback: ISR callbacks
  - initialized / enabled: HAL-managed state flags

Public API behavior
-------------------
- hal_dma_init(handle)
  - Enabled DMA controller clock and configures the stream's control register.
  - Leaves the stream disabled (enabled flag=false) until hal_dma_start is called.
  - Validates stream/channel ranges and returns STATUS_INVALID_PARAM on invalid values.
  - Configures NVIC for the corresponding IRQ and sets priority based on handle->priority and hardware_config.h IRQ_PRIORITY_* macros.

- hal_dma_start(handle, peripheral_addr, memory_addr, data_length)
  - Expects handle->initialized == true.
  - Writes PAR (peripheral address), M0AR (memory 0) and NDTR (number of data items).
  - Enables stream (sets EN bit). Returns STATUS_TIMEOUT on enable/disable waiting timeouts.

- hal_dma_stop(handle)
  - Disables the stream and waits for the EN bit to clear.

- hal_dma_is_complete(handle)
  - Checks the Transfer Complete (TCIF) flag in ISR registers.

- hal_dma_get_remaining(handle)
  - Returns NDTR value for the stream (number of remaining items).

- hal_dma_set_double_buffer(handle, buffer0_addr, buffer1_addr)
  - Programs M0AR and M1AR for double-buffer operation. Only valid if handle->double_buffer == true.

- hal_dma_get_current_buffer(handle)
  - Reads the CT bit in SxCR to determine which memory target is active.

- hal_dma_irq_handler(handle)
  - Called from the IRQ vector (the IRQ for the stream) with the handle for that stream.
  - Reads status bits, invokes callbacks, clears the flags.
  - Important: called in interrupt context — keep callbacks short.

Threading, reentrancy and ISR context
-------------------------------------
- All public APIs are not thread-safe; caller must ensure single-threaded access or use critical sections.
- Callbacks run in IRQ context. Do not call blocking APIs from callbacks. If you need to pass data to another context, use an event/queue protected by or signaled from an ISR-safe mechanism.

Hardware couplings and mapping rules
-----------------------------------
- hal_dma.c maps the enums to SxCR bitfields. If running on a different MCU (or different DMA controllers), update hal_dma.c register offsets, bit positions, and base addresses accordingly.
- dma_handle_t->dma_base must match the DMA controller base used in hal_dma.c (DMA1_BASE or DMA2_BASE). On other MCUs these addresses change.
- The NVIC IRQ mapping used in hal_dma.c assumes contiguous DMA stream IRQn values (e.g., DMA1_Stream0_IRQn + stream). If that's not valid on your MCU, adjust the IRQn selection logic.

Extending the API safely
------------------------
- Add a context pointer to callbacks:
  - Modify typedef to `typedef void (*dma_callback_t)(void* context);`
  - Add `void* callback_context;` to dma_handle_t for each callback or one generic `void* user_context;`.
  - Update hal_dma.c to pass the context when invoking callbacks.

- Support scatter-gather or linked-list DMA:
  - This API is intentionally simple. For scatter-gather, implement a higher-level scheduler that programs NDTR/PAR/MxAR and chains transfers using callbacks.

Debugging tips
--------------
- If transfers never complete:
  - Confirm NVIC is enabled for the matching IRQ.
  - Confirm DMA clocks are enabled (see hardware_config.h and RCC register writes).
  - Use hal_dma_get_remaining() to confirm NDTR is being decremented.
  - Add a temporary debug callback that toggles a GPIO in IRQ to confirm whether IRQ fired.

- If transfer length exceeds hardware limit:
  - NDTR is often limited to 16-bit on STM32F4 (max 65535 beats). The HAL checks for >65535 and rejects it. For longer transfers, split into chunks in software or use hardware features for memory-to-memory if available.

Examples
--------
Init and start a simple peripheral->memory transfer:
```c
dma_handle_t eeg_dma = {
    .dma_base = (void*)DMA2_BASE,
    .stream = 0,
    .channel = 3,
    .direction = DMA_DIR_PERIPHERAL_TO_MEMORY,
    .peripheral_size = DMA_SIZE_WORD,
    .memory_size = DMA_SIZE_WORD,
    .priority = DMA_PRIORITY_VERY_HIGH,
    .mode = DMA_MODE_CIRCULAR,
    .peripheral_increment = false,
    .memory_increment = true,
    .double_buffer = false,
    .transfer_complete_callback = eeg_dma_tc_cb,
    .half_transfer_callback = eeg_dma_ht_cb,
    .transfer_error_callback = eeg_dma_te_cb,
};
hal_dma_init(&eeg_dma);
hal_dma_start(&eeg_dma, EEG_SPI_DR_REG_ADDR, (uint32_t)eeg_buffer, EEG_DMA_TRANSFER_LEN);
```

Maintenance checklist
---------------------
- If changing stream/channel mapping or bitfields, update hal_dma.c register definitions and ensure flag offsets computed in get_flag_offset() are correct.
- If you add more IRQs or change NVIC mapping, update the IRQn resolution in hal_dma_init.
- If adding a callback context pointer, update all call sites.

Where to look next
------------------
- hal_dma.c: concrete register-level implementation and assumptions.
- hardware_config.h: priorities, base DMA stream selection macros, and clock settings.
- linker_script.ld / startup.c: for vector table and ISR binding; ensure that DMA IRQ entries appear in the correct index in vector_table.
