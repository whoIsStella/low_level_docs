# ring_buffer.c — Detailed reference & maintenance guide

Repository location:
- File: NS/src/layer3_datastructs/ring_buffer.c
- URL: https://github.com/whoIsStella/A_V/blob/main/NS/src/layer3_datastructs/ring_buffer.c

Purpose
-------
Implements a lock-free circular buffer (ring buffer) optimized for single-producer, single-consumer scenarios. Critical for real-time streaming of EEG and audio data.

Why this file matters
---------------------
- Core data pipeline infrastructure for the entire neurofeedback system
- Lock-free design enables ISR-safe operation without disabling interrupts
- Efficient modulo operations via bit masking (power-of-2 sizing requirement)
- Provides statistics for debugging buffer sizing and overrun issues

Implementation details
---------------------

1. Private helper functions

calculate_available(rb):
- Computes number of elements ready to read
- Uses: (write_index - read_index) & mask
- Bit masking handles wraparound correctly
- Returns 0 when empty, capacity-1 when full (one slot reserved)

calculate_free(rb):
- Computes free space for writing
- Returns: capacity - available - 1
- Reserves one slot to distinguish full from empty state
- Critical: full when (write_index + 1) % capacity == read_index

get_element_ptr(rb, index):
- Calculates pointer to element at given index
- offset = (index & mask) * element_size
- Returns: buffer_base + offset
- Bit mask ensures index stays within bounds

update_peak_usage(rb):
- Tracks maximum buffer occupancy
- Called after each write
- Useful for tuning buffer sizes

2. ring_buffer_init()
- Validates parameters (non-null, non-zero, power-of-2 capacity)
- Initializes structure fields
- Sets mask = capacity - 1 (for fast modulo)
- Clears statistics
- Returns STATUS_INVALID_PARAM if capacity not power of 2

3. ring_buffer_write()
- Checks if buffer full: (write_index + 1) & mask == read_index & mask
- If full: Increments overrun_count, returns STATUS_BUFFER_FULL
- Copies element using memcpy (handles arbitrary element sizes)
- Updates write_index atomically (size_t write is atomic on Cortex-M)
- Updates peak usage statistics

4. ring_buffer_read()
- Checks if buffer empty: write_index == read_index
- If empty: Increments underrun_count, returns STATUS_BUFFER_EMPTY
- Copies element using memcpy
- Updates read_index atomically
- Returns STATUS_OK

5. ring_buffer_peek()
- Similar to read but doesn't update read_index
- Allows inspection without consumption
- Useful for look-ahead processing

6. Query functions
- ring_buffer_available(): Returns calculate_available()
- ring_buffer_free(): Returns calculate_free()
- ring_buffer_is_empty(): write_index == read_index
- ring_buffer_is_full(): (write_index + 1) & mask == read_index & mask
- ring_buffer_capacity(): Returns capacity
- ring_buffer_usage_percent(): (available * 100) / capacity

7. ring_buffer_clear()
- Sets read_index = write_index
- Effectively empties buffer without clearing memory
- Fast operation (no memset needed)

8. ring_buffer_get_stats() / ring_buffer_reset_stats()
- Retrieves or resets overrun/underrun/peak statistics
- Essential for runtime monitoring

9. Bulk operations
- ring_buffer_write_bulk(): Writes multiple elements in loop
- ring_buffer_read_bulk(): Reads multiple elements in loop
- Returns actual count (may be less than requested if buffer full/empty)
- More efficient than multiple single-element calls

Lock-free algorithm details
---------------------------

Single producer, single consumer (SPSC) guarantees:
- Producer only modifies write_index
- Consumer only modifies read_index
- No data races on indices
- Volatile ensures visibility across threads/ISRs
- Size_t reads/writes are atomic on Cortex-M (32-bit architecture)

Why one slot is reserved:
- Full condition: (write + 1) % capacity == read
- Empty condition: write == read
- Without reservation, full and empty are indistinguishable
- Alternative: Use separate count variable (adds overhead)

Why power-of-2 sizing:
- Modulo via bit mask: index & (capacity - 1)
- Single AND instruction vs. expensive division
- Typical modulo: 20-30 cycles, bit mask: 1 cycle

Performance characteristics
--------------------------
- Write/read: O(1), ~15-25 CPU cycles
- No dynamic allocation
- No mutex/semaphore overhead
- ISR-safe without disabling interrupts
- Cache-friendly for sequential access
- memcpy overhead: ~element_size cycles

Usage examples
-------------

EEG data producer (ISR):
```c
void eeg_dma_callback(void) {
    eeg_packet_t packet;
    read_eeg_data(&packet);
    if (ring_buffer_write(&eeg_buffer, &packet) != STATUS_OK) {
        eeg_overrun_count++;  // Track errors
    }
}
```

EEG data consumer (main loop):
```c
while (ring_buffer_available(&eeg_buffer) >= 32) {
    eeg_packet_t packets[32];
    size_t count = ring_buffer_read_bulk(&eeg_buffer, packets, 32);
    process_eeg_batch(packets, count);
}
```

Common pitfalls
---------------
- Capacity not power of 2: Causes incorrect wraparound
- Using with multiple producers/consumers: Not lock-free, requires synchronization
- Ignoring STATUS_BUFFER_FULL: Silent data loss
- Buffer too small: Frequent overruns
- Not monitoring statistics: Miss sizing issues during development
- Assuming atomic access on non-Cortex-M: May need memory barriers

Optimization notes
-----------------
- memcpy typically optimized by compiler for small element_size
- For very small elements (1-4 bytes), direct assignment may be faster
- Consider separate implementation for common sizes (optimization)
- Compiler may inline small functions (calculate_available, etc.)

Porting considerations
---------------------
- Atomic size_t assumption: Valid for single-core Cortex-M
- For multi-core: Need memory barriers (DMB instructions)
- For x86/ARM64: May need atomic operations or memory fences
- memcpy: Standard C library, portable

Where to look next
------------------
- ring_buffer.h for API documentation
- audio_driver.c and eeg_driver.c for usage examples
- ARM Cortex-M documentation for memory ordering guarantees
Implements the lock-free circular FIFO buffer declared in ring_buffer.h. Provides efficient, ISR-safe data buffering for SPSC (single-producer single-consumer) scenarios without locks or atomics.

Implementation details
----------------------
- Uses volatile read/write indices visible across ISR and main contexts.
- Capacity must be power of 2, enabling fast modulo via bitwise AND (index & mask).
- Maintains one empty slot to distinguish full from empty (write_index == read_index).
- Copies element data using memcpy for generic type support.
- Tracks statistics (overruns, underruns, peak usage) for diagnostics.

Key functions
-------------

**ring_buffer_init**:
- Validates capacity is power of 2 using IS_POWER_OF_2 macro.
- Stores buffer pointer, element size, capacity.
- Computes mask = capacity - 1.
- Initializes indices to 0 (empty state).
- Zeros statistics.

**ring_buffer_write**:
- Calculates available space: capacity - available - 1 (reserve one slot).
- If full, increments overrun_count and returns STATUS_BUFFER_FULL.
- Computes write offset: (write_index & mask) * element_size.
- Copies element data to buffer + offset using memcpy.
- Increments write_index (volatile write ensures visibility).
- Updates peak_usage if current usage exceeds previous peak.
- Returns STATUS_OK.

**ring_buffer_read**:
- Checks if read_index == write_index (empty).
- If empty, increments underrun_count and returns STATUS_BUFFER_EMPTY.
- Computes read offset: (read_index & mask) * element_size.
- Copies data from buffer + offset to output using memcpy.
- Increments read_index.
- Returns STATUS_OK.

**ring_buffer_peek**:
- Same as read but doesn't increment read_index.
- Non-destructive inspection of next element.

**ring_buffer_available**:
- Returns write_index - read_index.
- Due to unsigned arithmetic, wrapping is handled correctly.

**ring_buffer_free**:
- Returns capacity - available - 1.
- The -1 accounts for reserved empty slot.

**ring_buffer_is_empty/is_full**:
- is_empty: read_index == write_index.
- is_full: available == capacity - 1.

**ring_buffer_clear**:
- Sets read_index = write_index (logically empty).
- Doesn't zero buffer memory (unnecessary and expensive).

**ring_buffer_write_bulk/read_bulk**:
- Optimized for batch operations.
- Limits actual count to available space/data.
- Loops calling single-element write/read.
- Returns actual count transferred.
- More efficient than repeated single calls due to reduced function call overhead.

SPSC correctness
----------------
- **Memory model**: Cortex-M provides sequential consistency for volatile accesses.
- **Visibility**: Volatile ensures compiler doesn't cache indices in registers.
- **Atomicity**: Size_t reads/writes are atomic on 32-bit ARM.
- **No ABA problem**: Single producer and single consumer prevent race conditions.
- **Ordering**: Producer writes data before updating write_index. Consumer reads write_index before reading data. Natural program order ensures correctness.

Performance characteristics
---------------------------
- Constant-time operations: O(1) for write, read, available, free.
- Bulk operations: O(n) where n = element count, but reduced function overhead.
- Memcpy overhead: Proportional to element_size. For large elements, consider pointer-based design.
- Power-of-2 modulo: Single AND instruction vs. division/modulo (20+ cycles).

Debugging tips
--------------
- Add assertions (if in debug build) to verify capacity is power of 2.
- Log overrun/underrun events with timestamps to identify patterns.
- Periodically dump peak_usage to see worst-case buffer fill level.
- Use debugger to inspect read_index, write_index, and buffer contents.
- Test with intentionally slow consumer to force overruns, verify graceful handling.

Common pitfalls
---------------
- Assuming thread-safe for multi-producer or multi-consumer (requires additional locking).
- Not checking return status from write (silent data loss on overrun).
- Using non-power-of-2 capacity (initialization fails).
- Buffer pointer becomes invalid (stack allocation, dangling pointer after free).
- Element size mismatch (corruption or alignment faults).

Maintenance checklist
---------------------
- [ ] Validate SPSC assumptions in all call sites.
- [ ] Test wraparound scenarios (indices exceeding SIZE_MAX).
- [ ] Verify statistics accuracy under high load.
- [ ] Performance test with different element sizes.
- [ ] Test on target hardware (not just x86 host).

Where to look next
------------------
- ring_buffer.h: API documentation and usage patterns.
- eeg_driver.c, audio_driver.c: Real-world usage examples.
- common_types.h: ring_buffer_t structure definition.
