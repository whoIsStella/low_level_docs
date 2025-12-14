# test_all.c — Detailed reference & maintenance guide

Repository location:
- File: NS/tests/test_all.c

Purpose
-------
Main test suite runner executing all unit and integration tests for the NS system.

Test organization
-----------------
- Groups tests by module (ring buffer, EEG driver, audio driver, processors)
- Runs tests in dependency order (low-level HAL before high-level drivers)
- Reports aggregate results (total passed/failed)
- Optionally runs performance benchmarks

Test modules
------------
- HAL tests: GPIO, DMA, SPI, I2S basic functionality
- Data structure tests: Ring buffer, time sync
- Driver tests: EEG driver register access, audio driver init
- Processing tests: FFT correctness, band power extraction
- Integration tests: End-to-end data flow validation

Running tests
-------------
- Build with 'make test' target
- Flash to target hardware
- Connect serial console for test output
- Automated pass/fail determination

Where to look next
------------------
- Individual test files for specific modules
- Makefile: Test build configuration
- test_framework.h: Assertion macros
