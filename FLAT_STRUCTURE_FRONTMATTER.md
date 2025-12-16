# Front Matter Templates for Your Actual Structure

## Navigation Hierarchy Based on Your Files

### ROOT LEVEL FILES

#### index.md (Create this as your home page)
```yaml
---
layout: home
title: Home
nav_order: 1
---

# NeuroStereo Firmware Documentation

Low-level embedded system documentation for EEG-integrated audio neurofeedback.
```

#### README.md (If you want it in the nav)
```yaml
---
layout: default
title: README
nav_order: 2
---
```

---

### GETTING STARTED SECTION (nav_order: 10-19)

#### docs/getting_started.md
```yaml
---
layout: default
title: Getting Started
nav_order: 10
---
```

#### docs/ARCHITECTURE.md
```yaml
---
layout: default
title: System Architecture
nav_order: 11
---
```

#### docs/API_REFERENCE.md
```yaml
---
layout: default
title: API Reference
nav_order: 12
---
```

#### docs/DOCUMENTATION_INDEX.md
```yaml
---
layout: default
title: Documentation Index
nav_order: 13
---
```

---

### SYSTEM INTEGRATION (nav_order: 20-29)

Create a parent page: **docs/system-integration.md**
```yaml
---
layout: default
title: System Integration
nav_order: 20
has_children: true
---

# System Integration Guides

Resources for porting and integrating NeuroStereo on different platforms.
```

Then update existing files:

#### docs/cheatsheet_hal.md (or create new file with this name)
```yaml
---
layout: default
title: HAL Quick Reference
parent: System Integration
nav_order: 1
---
```

#### docs/cheatsheet_porting.md (or create new file with this name)
```yaml
---
layout: default
title: Platform Porting Guide
parent: System Integration
nav_order: 2
---
```

#### docs/hardware_config.h.documentation.md
```yaml
---
layout: default
title: Hardware Configuration
parent: System Integration
nav_order: 3
---
```

---

### HAL LAYER (nav_order: 30-39)

Create parent: **docs/hal-layer.md**
```yaml
---
layout: default
title: HAL Layer
nav_order: 30
has_children: true
---

# Hardware Abstraction Layer

Platform-independent hardware interfaces.
```

Then update HAL files:

#### docs/hal_dma.c.documentation.md
```yaml
---
layout: default
title: DMA HAL
parent: HAL Layer
nav_order: 1
---
```

#### docs/hal_dma.h.documentation.md
```yaml
---
layout: default
title: DMA HAL Header
parent: HAL Layer
nav_order: 2
---
```

#### docs/hal_gpio.c.documentation.md
```yaml
---
layout: default
title: GPIO HAL
parent: HAL Layer
nav_order: 3
---
```

#### docs/hal_gpio.h.documentation.md
```yaml
---
layout: default
title: GPIO HAL Header
parent: HAL Layer
nav_order: 4
---
```

#### docs/hal_i2s.c.documentation.md
```yaml
---
layout: default
title: I2S HAL
parent: HAL Layer
nav_order: 5
---
```

#### docs/hal_i2s.h.documentation.md
```yaml
---
layout: default
title: I2S HAL Header
parent: HAL Layer
nav_order: 6
---
```

#### docs/hal_spi.c.documentation.md
```yaml
---
layout: default
title: SPI HAL
parent: HAL Layer
nav_order: 7
---
```

#### docs/hal_spi.h.documentation.md
```yaml
---
layout: default
title: SPI HAL Header
parent: HAL Layer
nav_order: 8
---
```

#### docs/hal_timer.c.documentation.md
```yaml
---
layout: default
title: Timer HAL
parent: HAL Layer
nav_order: 9
---
```

#### docs/hal_timer.h.documentation.md
```yaml
---
layout: default
title: Timer HAL Header
parent: HAL Layer
nav_order: 10
---
```

---

### DRIVERS LAYER (nav_order: 40-49)

Create parent: **docs/drivers-layer.md**
```yaml
---
layout: default
title: Driver Layer
nav_order: 40
has_children: true
---

# Hardware Drivers

Device-specific driver implementations.
```

#### docs/audio_driver.c.documentation.md
```yaml
---
layout: default
title: Audio Driver
parent: Driver Layer
nav_order: 1
---
```

#### docs/audio_driver.h.documentation.md
```yaml
---
layout: default
title: Audio Driver Header
parent: Driver Layer
nav_order: 2
---
```

#### docs/eeg_driver.c.documentation.md
```yaml
---
layout: default
title: EEG Driver (ADS1299)
parent: Driver Layer
nav_order: 3
---
```

#### docs/eeg_driver.h.documentation.md
```yaml
---
layout: default
title: EEG Driver Header
parent: Driver Layer
nav_order: 4
---
```

---

### PROCESSING LAYER (nav_order: 50-59)

Create parent: **docs/processing-layer.md**
```yaml
---
layout: default
title: Processing Layer
nav_order: 50
has_children: true
---

# Signal Processing

DSP and real-time processing components.
```

#### docs/audio_processor.h.documentation.md
```yaml
---
layout: default
title: Audio Processor
parent: Processing Layer
nav_order: 1
---
```

#### docs/eeg_processor.h.documentation.md
```yaml
---
layout: default
title: EEG Processor
parent: Processing Layer
nav_order: 2
---
```

#### docs/fft_engine.h.documentation.md
```yaml
---
layout: default
title: FFT Engine
parent: Processing Layer
nav_order: 3
---
```

---

### APPLICATION LAYER (nav_order: 60-69)

Create parent: **docs/application-layer.md**
```yaml
---
layout: default
title: Application Layer
nav_order: 60
has_children: true
---

# Application Components

High-level neurofeedback application logic.
```

#### docs/neurofeedback_engine.h.documentation.md
```yaml
---
layout: default
title: Neurofeedback Engine
parent: Application Layer
nav_order: 1
---
```

#### docs/main.c.documentation.md
```yaml
---
layout: default
title: Main Application
parent: Application Layer
nav_order: 2
---
```

---

### UTILITIES & BUFFERS (nav_order: 70-79)

Create parent: **docs/utilities.md**
```yaml
---
layout: default
title: Utilities
nav_order: 70
has_children: true
---

# Utility Components

Common utilities and buffer management.
```

#### docs/ring_buffer.c.documentation.md
```yaml
---
layout: default
title: Ring Buffer Implementation
parent: Utilities
nav_order: 1
---
```

#### docs/ring_buffer.h.documentation.md
```yaml
---
layout: default
title: Ring Buffer Header
parent: Utilities
nav_order: 2
---
```

#### docs/common_types.h.documentation.md
```yaml
---
layout: default
title: Common Types
parent: Utilities
nav_order: 3
---
```

---

### LOW-LEVEL / STARTUP (nav_order: 80-89)

Create parent: **docs/low-level.md**
```yaml
---
layout: default
title: Low-Level System
nav_order: 80
has_children: true
---

# Low-Level System Code

Startup, synchronization, and system initialization.
```

#### docs/startup.c.documentation.md
```yaml
---
layout: default
title: Startup Code
parent: Low-Level System
nav_order: 1
---
```

#### docs/time_sync.h.documentation.md
```yaml
---
layout: default
title: Time Synchronization
parent: Low-Level System
nav_order: 2
---
```

---

### GUIDES (nav_order: 90-99)

Create parent pages for different audiences:

#### docs/for-developers.md (Create new)
```yaml
---
layout: default
title: For Developers
nav_order: 90
---

# For New Developers

1. Start with [Getting Started](getting_started.md)
2. Review [System Architecture](ARCHITECTURE.md)
3. Reference [API Documentation](API_REFERENCE.md)
4. See [Documentation Index](DOCUMENTATION_INDEX.md)
```

#### docs/for-integrators.md (Create new)
```yaml
---
layout: default
title: For Integrators
nav_order: 91
---

# For System Integrators

Platform porting and hardware integration guides.
```

#### docs/maintenance.md
```yaml
---
layout: default
title: Maintenance
nav_order: 92
---
```

---

## Quick Application Steps:

1. **Copy the front matter** for each file
2. **Create the parent pages** (system-integration.md, hal-layer.md, etc.)
3. **Paste at the top** of each existing .md file
4. **Adjust nav_order** if you want different ordering

## Navigation will look like:

```
├── Home
├── README
├── Getting Started
├── System Architecture
├── API Reference
├── Documentation Index
├── System Integration
│   ├── HAL Quick Reference
│   ├── Platform Porting Guide
│   └── Hardware Configuration
├── HAL Layer
│   ├── DMA HAL
│   ├── GPIO HAL
│   ├── I2S HAL
│   ├── SPI HAL
│   └── Timer HAL
├── Driver Layer
│   ├── Audio Driver
│   └── EEG Driver
├── Processing Layer
│   ├── Audio Processor
│   ├── EEG Processor
│   └── FFT Engine
├── Application Layer
│   ├── Neurofeedback Engine
│   └── Main Application
├── Utilities
│   ├── Ring Buffer
│   └── Common Types
├── Low-Level System
│   ├── Startup Code
│   └── Time Synchronization
└── For Developers/Integrators/Maintenance
```
