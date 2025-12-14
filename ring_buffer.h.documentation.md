# ring_buffer.h — Detailed reference & maintenance guide

Repository location:
- File: NS/include/layer3_datastructs/ring_buffer.h
- URL: https://github.com/whoIsStella/A_V/blob/main/NS/include/layer3_datastructs/ring_buffer.h

Purpose
-------
Defines a lock-free circular buffer (ring buffer) for efficient FIFO data streaming between producers and consumers. Essential for real-time audio and EEG data pipelines.

Why this file matters
---------------------
- Core data structure for streaming EEG and audio data
- Lock-free design ensures ISR-safe operation without disabling interrupts
- Power-of-2 sizing enables fast modulo operations using bit masking
- Single producer/single consumer pattern perfect for DMA → application data flow
- Statistics tracking helps diagnose buffer sizing and performance issues

Type definitions
---------------

ring_buffer_t structure:
- buffer: Pointer to actual data storage (allocated by caller)
- element_size: Size of each element in bytes (e.g., sizeof(eeg_packet_t))
- capacity: Total number of elements (must be power of 2)
- mask: (capacity - 1), used for fast modulo: index & mask == index % capacity
- write_index: Producer's current write position (volatile)
- read_index: Consumer's current read position (volatile)
- overrun_count: Number of times buffer was full during write
- underrun_count: Number of times buffer was empty during read
- peak_usage: Maximum number of elements ever present

Lock-free guarantees
-------------------
- Single producer, single consumer (SPSC) is lock-free and ISR-safe
- Producer only modifies write_index
- Consumer only modifies read_index
- No mutual exclusion required
- Volatile indices ensure visibility across threads/ISRs
- Works without atomic operations on Cortex-M (single-core)

Public API
----------

1. ring_buffer_init(rb, buffer, element_size, capacity)
   - Initializes ring buffer structure
   - buffer: Pre-allocated memory (must remain valid for buffer lifetime)
   - capacity: Must be power of 2 (checked with IS_POWER_OF_2 macro)
   - Returns STATUS_OK or STATUS_INVALID_PARAM

2. ring_buffer_write(rb, element)
   - Writes single element to buffer
   - Returns STATUS_OK or STATUS_BUFFER_FULL
   - ISR-safe for single producer
   - Increments overrun_count if full

3. ring_buffer_read(rb, element)
   - Reads single element from buffer
   - Returns STATUS_OK or STATUS_BUFFER_EMPTY
   - ISR-safe for single consumer
   - Increments underrun_count if empty

4. ring_buffer_peek(rb, element)
   - Reads next element without removing it
   - Useful for inspecting data before committing to read

5. Query functions:
   - ring_buffer_available(): Number of elements ready to read
   - ring_buffer_free(): Number of free slots for writing
   - ring_buffer_is_empty(): true if no data available
   - ring_buffer_is_full(): true if no space for writing
   - ring_buffer_capacity(): Total capacity
   - ring_buffer_usage_percent(): 0-100% fill level

6. Bulk operations:
   - ring_buffer_write_bulk(rb, elements, count): Write multiple elements
   - ring_buffer_read_bulk(rb, elements, count): Read multiple elements
   - Return actual number of elements transferred (may be less than requested)

7. Management:
   - ring_buffer_clear(): Reset to empty (sets read_index = write_index)
   - ring_buffer_get_stats(): Retrieve overrun/underrun/peak statistics
   - ring_buffer_reset_stats(): Clear statistics counters

Utility macros
-------------

1. IS_POWER_OF_2(x)
   - Checks if x is a power of 2
   - Used to validate capacity during initialization

2. RING_BUFFER_DECLARE(name, type, size)
   - Convenience macro for static buffer declaration
   - Allocates storage and initializes structure
   - Example: RING_BUFFER_DECLARE(my_buffer, eeg_packet_t, 1024);

Usage patterns
-------------

Static allocation with macro:
```c
RING_BUFFER_DECLARE(eeg_buffer, eeg_packet_t, 512);
// Ready to use, no init needed
```

Dynamic allocation:
```c
eeg_packet_t* storage = malloc(512 * sizeof(eeg_packet_t));
ring_buffer_t rb;
ring_buffer_init(&rb, storage, sizeof(eeg_packet_t), 512);
```

Producer (e.g., DMA ISR):
```c
void dma_complete_callback() {
    eeg_packet_t packet = read_from_adc();
    if (ring_buffer_write(&eeg_buffer, &packet) != STATUS_OK) {
        // Buffer full - overrun detected
    }
}
```

Consumer (e.g., main loop):
```c
while (ring_buffer_available(&eeg_buffer) > 0) {
    eeg_packet_t packet;
    ring_buffer_read(&eeg_buffer, &packet);
    process_eeg_packet(&packet);
}
```

Sizing considerations
--------------------
- Capacity must balance memory vs. latency tolerance
- Too small: Frequent overruns, data loss
- Too large: Wastes memory, increases latency
- Rule of thumb: 2-10× peak production rate during worst-case processing delay
- Example: EEG at 512 Hz, 50ms processing time → 512 × 0.05 = 26 samples minimum
- Add headroom: Use 64 or 128 (next power of 2)

Performance characteristics
--------------------------
- Write/read operation: O(1), ~10-20 CPU cycles
- No memory allocation after init
- No dynamic allocation overhead
- Cache-friendly for sequential access
- Modulo via bit mask: 1 cycle vs. ~20 for division

Common pitfalls
---------------
- Capacity not power of 2: Causes incorrect behavior
- Buffer storage freed while in use: Leads to corruption
- Multiple producers or consumers: Not lock-free, requires synchronization
- Ignoring STATUS_BUFFER_FULL: Silent data loss
- Not monitoring statistics: Miss overruns and sizing issues

Integration notes
----------------
- Used by audio_driver.c for audio sample streaming
- Used by eeg_driver.c for EEG packet buffering
- Compatible with DMA double-buffering pattern
- Statistics help tune buffer sizes during development

Where to look next
------------------
- ring_buffer.c for implementation details
- audio_driver.c and eeg_driver.c for usage examples
- time_sync.h for synchronization between multiple ring buffers
This header declares a lock-free, circular FIFO buffer optimized for single-producer/single-consumer (SPSC) scenarios. Provides:
- Efficient streaming data buffering between producers (DMA ISRs) and consumers (processing tasks)
- ISR-safe operations without locks or atomics
- Generic implementation supporting any data type
- Power-of-2 sizing for fast modulo operations
- Statistics tracking (overruns, underruns, peak usage)
- Bulk read/write operations

Why this file matters
---------------------
- Ring buffers are critical for decoupling high-frequency data acquisition (EEG at 512Hz, audio at 48kHz) from processing.
- Lock-free design enables safe usage in ISR contexts without disabling interrupts.
- Capacity must be sized correctly: too small causes overruns, too large wastes precious RAM.
- Performance depends on power-of-2 sizing (uses bitwise AND instead of modulo).

API semantics
-------------

### Data structure (ring_buffer_t)
- **buffer**: Pointer to user-allocated array. Caller owns memory.
- **element_size**: Size of each element in bytes. Supports any data type.
- **capacity**: Total number of elements. Must be power of 2.
- **mask**: (capacity - 1). Used for fast index wrapping: index & mask ≡ index % capacity.
- **write_index**: Volatile producer index. Modified by writer only.
- **read_index**: Volatile consumer index. Modified by reader only.
- **Statistics**: overrun_count, underrun_count, peak_usage for diagnostics.

### Initialization
- **ring_buffer_init**: Initializes ring buffer with user-provided memory. Validates capacity is power of 2. Returns STATUS_INVALID_PARAM if not.

### Basic operations
- **ring_buffer_write**: Insert one element. Returns STATUS_BUFFER_FULL if no space. Copies element data using memcpy.
- **ring_buffer_read**: Extract one element. Returns STATUS_BUFFER_EMPTY if nothing available. Copies data out.
- **ring_buffer_peek**: Look at next element without removing. Non-destructive read.

### Query functions
- **ring_buffer_available**: Number of elements readable.
- **ring_buffer_free**: Number of elements writable.
- **ring_buffer_is_empty**: Returns true if read_index == write_index.
- **ring_buffer_is_full**: Returns true if available == capacity - 1. (One slot always left empty to distinguish empty from full.)
- **ring_buffer_capacity**: Returns total capacity.
- **ring_buffer_usage_percent**: Returns 0-100 percentage.

### Management
- **ring_buffer_clear**: Reset indices to empty state. Does not zero memory.
- **ring_buffer_get_stats**: Retrieve diagnostic counters.
- **ring_buffer_reset_stats**: Zero diagnostic counters.

### Bulk operations
- **ring_buffer_write_bulk**: Write up to count elements, returns actual count written. More efficient than repeated single writes.
- **ring_buffer_read_bulk**: Read up to count elements, returns actual count read.

### Utility macro
- **RING_BUFFER_DECLARE**: Declares and initializes a static ring buffer with storage in single statement.

SPSC semantics
--------------
- **Single Producer**: Only one context writes (e.g., DMA ISR).
- **Single Consumer**: Only one context reads (e.g., processing task in main loop).
- **No locks required**: Volatile indices ensure visibility across contexts. Compiler won't cache values.
- **Memory ordering**: On Cortex-M, load/store are sequentially consistent. No explicit barriers needed for SPSC.
- **Limitations**: Multi-producer or multi-consumer requires additional synchronization (mutexes, atomics, or lock-free MPMC algorithms).

Usage patterns
--------------

**EEG data buffering:**
```c
// In global scope
static eeg_packet_t eeg_storage[1024];  // Must be power of 2
static ring_buffer_t eeg_ring;

// In initialization
ring_buffer_init(&eeg_ring, eeg_storage, sizeof(eeg_packet_t), 1024);

// In DMA ISR (producer)
void DMA_EEG_IRQHandler(void) {
    eeg_packet_t packet;
    read_eeg_dma_buffer(&packet);
    if (ring_buffer_write(&eeg_ring, &packet) != STATUS_OK) {
        // Overrun: consumer too slow or buffer too small
        error_count++;
    }
}

// In main loop (consumer)
void process_eeg(void) {
    eeg_packet_t packet;
    while (ring_buffer_read(&eeg_ring, &packet) == STATUS_OK) {
        // Process packet
        run_eeg_analysis(&packet);
    }
}
```

**Using RING_BUFFER_DECLARE macro:**
```c
RING_BUFFER_DECLARE(audio_rb, audio_sample_t, 2048);
// Expands to static audio_sample_t audio_rb_data[2048] and static ring_buffer_t audio_rb = {...}
```

Memory and alignment
--------------------
- Buffer memory must remain valid for lifetime of ring buffer. Use static or heap allocation, not stack.
- Element size must match actual data type size. Mismatched sizes cause corruption.
- No alignment requirements for the ring_buffer_t structure itself, but element data may need alignment (e.g., DMA buffers).

Threading & ISR considerations
-------------------------------
- Safe for SPSC without additional synchronization.
- Producer (write) typically in high-priority ISR (DMA, timer).
- Consumer (read) typically in main loop or lower-priority task.
- Do not call write from multiple ISRs or multiple contexts.
- Do not call read from multiple tasks.
- If multi-producer or multi-consumer needed, wrap with critical sections or use atomic operations.

Debugging tips
--------------
- **Overruns**: Check overrun_count. If nonzero, either consumer is too slow or buffer too small. Increase capacity or optimize processing.
- **Underruns**: Indicate consumer reading faster than producer (rare in streaming scenarios, but possible during startup).
- **Peak usage near capacity**: System operating close to limit. Consider increasing buffer size.
- **Hangs**: If write never succeeds, consumer may have stopped. Check read path. If read never succeeds, producer may have stopped.
- Use ring_buffer_usage_percent to monitor buffer health during runtime.

Common pitfalls
---------------
- **Non-power-of-2 capacity**: Causes STATUS_INVALID_PARAM in init. Always use 64, 128, 256, 512, 1024, 2048, etc.
- **Stack-allocated buffer**: Goes out of scope, causes dangling pointer. Use static or malloc.
- **Wrong element_size**: Passing sizeof(pointer) instead of sizeof(data_type) causes memory corruption.
- **Multi-producer/multi-consumer without locks**: Causes race conditions and data corruption.
- **Ignoring return status from write**: Overruns go unnoticed, leading to data loss.
- **Reading in ISR and main loop**: Violates SPSC assumption. Reserve read for one context only.

Performance considerations
--------------------------
- Power-of-2 sizing allows compiler to optimize (index & mask) to single AND instruction vs. expensive modulo.
- Memcpy overhead: For large elements, consider pointer-based ring buffer (store pointers to elements instead of copying).
- Cache effects: On Cortex-M with cache, volatile alone may not be sufficient; consider memory barriers or cache management.

Maintenance checklist
---------------------
- [ ] Verify all ring buffer capacities in system_config.h are powers of 2.
- [ ] Test overrun and underrun scenarios with artificial delays.
- [ ] Monitor peak_usage statistics during stress testing.
- [ ] Validate ISR safety with interrupts at various priorities.
- [ ] Test with different element sizes (1 byte, 4 bytes, large structures).

Where to look next
------------------
- ring_buffer.c: Implementation details.
- eeg_driver.c, audio_driver.c: Users of ring buffers for data streaming.
- system_config.h: Buffer size configurations.
- common_types.h: ring_buffer_t definition (also declared here).
