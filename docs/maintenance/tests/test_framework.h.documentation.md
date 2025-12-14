# test_framework.h — Detailed reference & maintenance guide

Repository location:
- File: NS/tests/test_framework.h

Purpose
-------
Declares lightweight testing framework for bare-metal embedded testing without external dependencies.

Why this file matters
---------------------
- Enables unit and integration testing on target hardware
- No heap allocation or OS required
- Minimal overhead suitable for resource-constrained devices
- Provides assertions and test result reporting

API overview
------------
- TEST_INIT: Initialize test framework
- TEST_START(name): Begin a test case
- TEST_ASSERT(condition): Assert condition is true
- TEST_ASSERT_EQ(a, b): Assert equality
- TEST_ASSERT_NEQ, TEST_ASSERT_GT, TEST_ASSERT_LT: Comparison assertions
- TEST_END: Mark test case complete
- TEST_REPORT: Print summary of passed/failed tests

Usage pattern
-------------
```c
#include "test_framework.h"

void test_ring_buffer_basic(void) {
    TEST_START("ring_buffer_basic");
    
    ring_buffer_t rb;
    uint8_t buffer[16];
    TEST_ASSERT(ring_buffer_init(&rb, buffer, 1, 16) == STATUS_OK);
    TEST_ASSERT(ring_buffer_is_empty(&rb));
    
    uint8_t data = 42;
    TEST_ASSERT(ring_buffer_write(&rb, &data) == STATUS_OK);
    TEST_ASSERT(!ring_buffer_is_empty(&rb));
    
    TEST_END();
}

int main(void) {
    TEST_INIT();
    test_ring_buffer_basic();
    TEST_REPORT();
}
```

Where to look next
------------------
- test_all.c: Test suite runner
- Individual test files: test_ring_buffer.c, etc.
