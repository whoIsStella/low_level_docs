# main.c — Detailed reference & maintenance guide

Repository location:
- File: NS/src/layer5_application/main.c
- URL: https://github.com/whoIsStella/A_V/blob/main/NS/src/layer5_application/main.c

Purpose
-------
Application entry point and system orchestration. Initializes all subsystems, manages main loop, and coordinates neurofeedback operation.

Why this file matters
---------------------
- Single point of system initialization
- Main event loop driving real-time operation
- Error handling and system state management
- Integration point for all software layers

Typical structure
----------------
1. System initialization sequence:
   - Clock configuration (SystemClock_Config)
   - HAL initialization (timers, GPIO, DMA, SPI, I2S)
   - Driver initialization (EEG, audio)
   - Processing initialization (FFT, EEG processor, audio processor)
   - Neurofeedback engine initialization
   - Start data acquisition

2. Main loop:
   - Process EEG data from ring buffer
   - Update neurofeedback engine
   - Process audio output
   - Handle user input/display updates
   - Monitor system health
   - Sleep/wait for interrupts (if using RTOS or WFI)

3. Error handling:
   - Check return codes from all init functions
   - Monitor buffer overruns/underruns
   - Handle hardware errors
   - Provide diagnostic output

Performance considerations
-------------------------
- Main loop should process faster than data arrival rate
- EEG at 512 Hz: Must process within 1953 µs per sample
- Audio at 48 kHz: Process blocks of 128-512 samples
- Use WFI (Wait For Interrupt) to save power between events

Integration notes
----------------
- Calls all layer initialization functions in correct order
- Manages system_state_t transitions
- Logs to debug UART if enabled
- May include USB or Bluetooth communication setup

Common structure:
```c
int main(void) {
    // System init
    system_init();
    
    // Hardware init
    hal_timer_init();
    hal_gpio_init();
    hal_spi_init();
    hal_i2s_init();
    
    // Driver init
    eeg_driver_init();
    audio_driver_init();
    
    // Processing init
    eeg_processor_init();
    audio_processor_init();
    neurofeedback_init();
    
    // Start acquisition
    eeg_driver_start();
    audio_driver_start();
    
    // Main loop
    while (1) {
        process_eeg();
        process_audio();
        neurofeedback_update();
        
        __WFI();  // Sleep until interrupt
    }
}
```

Where to look next
------------------
- startup.c for boot sequence before main()
- neurofeedback_engine.h for main control logic
- system_config.h for feature flags

Purpose
-------
Application entry point orchestrating system initialization, configuration, and main processing loop for the neurofeedback system.

Why this file matters
---------------------
- Coordinates all subsystem initialization
- Implements main processing loop with proper scheduling
- Manages system state transitions
- Handles error conditions and recovery
- Entry point for understanding system behavior

Initialization sequence
-----------------------
1. System clock configuration (168MHz via PLL)
2. HAL initialization (GPIO, DMA, SPI, I2S, timers)
3. Driver initialization (EEG, audio)
4. Data structure initialization (ring buffers)
5. Processing module initialization (FFT, processors)
6. Neurofeedback engine initialization
7. Start data acquisition

Main loop structure
-------------------
```c
while(1) {
    // Process EEG data from ring buffer
    if (eeg_data_available) {
        process_eeg_features();
    }
    
    // Update neurofeedback engine
    neurofeedback_update();
    
    // Process audio (if not in ISR callback)
    if (audio_buffer_ready) {
        process_audio_block();
    }
    
    // Update display/UI
    update_display();
    
    // Background tasks (logging, diagnostics)
    handle_background_tasks();
}
```

Timing and scheduling
---------------------
- EEG: 512 Hz sample rate, processed in batches
- Audio: 48kHz, processed in 512-1024 sample blocks (~10-20ms)
- Neurofeedback update: 4 Hz (250ms target latency)
- Display update: 10-30 Hz

Error handling
--------------
- Watchdog timer for hang detection
- Buffer overflow/underflow monitoring
- DMA error recovery
- System state machine with error state

Where to look next
------------------
- startup.c: Entry before main()
- neurofeedback_engine.c: Main control logic
- All driver .h files: Subsystem APIs
- system_config.h: Configuration constants
