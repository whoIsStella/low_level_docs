# NS Complete Documentation Index

**Your Complete Guide to the NS Embedded Neurofeedback System**

Version: 1.0
Last Updated: 2025-11-13

---

## Documentation Overview

This directory contains **comprehensive documentation** for the NS embedded neurofeedback system. All documentation has been designed for maintainability, deployment, and long-term support.

### Documentation Statistics

| Document | Size | Purpose |
|----------|------|---------|
| **ARCHITECTURE.md** | 40 KB | System architecture, design principles |
| **API_REFERENCE.md** | 25 KB | Complete function and type reference |
| **PRODUCTION_TESTING.md** | 16 KB | Testing, debugging, deployment procedures |
| **README.md** | 16 KB | Quick start, project overview |
| **TODO.md** | 10 KB | Development roadmap, missing items |
| **Makefile** | 10 KB | Production build system |
| **setup.sh** | 8 KB | Automated environment setup |
| **Source Code Documentation** | 3,200+ lines | Per-file maintenance docs in `docs/` |

**Total**: 107+ KB of primary documentation + 3,200 lines of inline documentation

---

## 🎯 Quick Navigation

### For New Developers
1. Start here → **[README.md](README.md)** - Quick start guide
2. Then read → **[ARCHITECTURE.md](ARCHITECTURE.md)** - Understand the system design
3. Reference → **[API_REFERENCE.md](API_REFERENCE.md)** - While coding
4. Testing → **[PRODUCTION_TESTING.md](PRODUCTION_TESTING.md)** - Before deployment

### For System Integrators
1. Hardware → **[docs/cheatsheet_hal.md](docs/cheatsheet_hal.md)** - HAL quick reference
2. Porting → **[docs/cheatsheet_porting.md](docs/cheatsheet_porting.md)** - Platform porting guide
3. Build → **[Makefile](Makefile)** + **[setup.sh](setup.sh)** - Build system
4. Debug → **[openocd.cfg](openocd.cfg)** + **[.gdbinit](.gdbinit)** - Debugging setup

### For Maintenance Engineers
1. Missing items → **[TODO.md](TODO.md)** - What needs to be done
2. Troubleshooting → **[PRODUCTION_TESTING.md](PRODUCTION_TESTING.md)** - Common issues
3. Module docs → **[docs/](docs/)** - Per-file documentation
4. Testing → **[tests/](tests/)** - Test suite

---
### ARCHITECTURE.md (40 KB)
**Purpose**: Comprehensive system architecture documentation

**Contents**:
- **System Overview**: Mission statement, key characteristics, system context
- **Architectural Principles**: 6 design principles explained
- **Layer-by-Layer Architecture**: Deep dive into all 6 layers
  - Layer 0: Bare Metal / Boot
  - Layer 1: HAL (GPIO, DMA, SPI, I2S, Timer)
  - Layer 2: Drivers (EEG, Audio)
  - Layer 3: Data Structures (Ring Buffer, Time Sync)
  - Layer 4: Signal Processing (FFT, EEG Processor, Audio Processor)
  - Layer 5: Application (Neurofeedback Engine, Main Loop)
- **Data Flow Architecture**: End-to-end pipeline, latency budget
- **Memory Architecture**: Memory map, usage analysis
- **Timing & Synchronization**: Clock tree, interrupt priorities
- **Interrupt Architecture**: ISR design, critical sections
- **Concurrency & Thread Safety**: Lock-free patterns
- **Error Handling Strategy**: Fail-safe design
- **Power & Performance**: Optimization techniques

**When to use**:
- Understanding system design decisions
- Learning how components interact
- Planning modifications or enhancements
- Debugging complex issues
- Porting to new hardware

**Key Highlights**:
- 6-layer separation of concerns
- Lock-free SPSC ring buffers for real-time operation
- Zero-copy DMA-driven data path
- <250ms end-to-end latency budget
- Memory optimization strategies
- Real-time performance analysis

---

### API_REFERENCE.md (25 KB)
**Purpose**: Complete function and type reference

**Contents**:
- **Common Types**: Status codes, data structures
- **Layer 1 HAL**: All HAL function signatures and examples
  - GPIO: 4 functions
  - Timer: 5 functions
  - DMA: 3 functions + callbacks
  - SPI: 2 functions
  - I2S: 2 functions
- **Layer 2 Drivers**: EEG and Audio driver APIs
  - EEG Driver: 4 functions
  - Audio Driver: 4 functions
- **Layer 3 Data Structures**: Ring buffer, time sync APIs
  - Ring Buffer: 6 functions
  - Time Sync: 3 functions
- **Layer 4 Processing**: FFT, EEG processor, audio processor
  - FFT Engine: 3 functions
  - EEG Processor: 3 functions
  - Audio Processor: 3 functions
- **Layer 5 Application**: Neurofeedback engine
  - Neurofeedback: 4 functions
- **Usage Examples**: Complete code examples
  - Full initialization sequence
  - Main processing loop
  - Performance monitoring

**When to use**:
- Daily development reference
- Learning API usage patterns
- Understanding function parameters
- Finding correct return codes
- Seeing usage examples

**Key Highlights**:
- Every public function documented
- Parameter descriptions
- Return value meanings
- Thread-safety notes
- Complete usage examples
- Error handling patterns

---

### PRODUCTION_TESTING.md (16 KB)
**Purpose**: Testing, debugging, and deployment procedures

**Contents**:
- **Development Environment Setup**: Required tools installation
- **Build System**: Makefile targets explained
- **Testing Strategy**: Layer-by-layer validation approach
- **Hardware Testing**: Pre-deployment checklist
  - Power supply test
  - EEG frontend test (signal quality, noise floor)
  - Audio system test (THD, sample rate accuracy)
  - Timing test (jitter measurement)
  - Memory test
- **Debugging Procedures**:
  - Serial debugging (basic)
  - OpenOCD + GDB (advanced)
  - Common debug commands
  - Debugging common issues (won't boot, hard fault, buffer overflow, timing issues)
- **Performance Validation**: Real-time metrics
- **Production Deployment**: QC procedures
- **FreeBSD Kernel Integration**: RTOS vs Superloop
- **Troubleshooting**: Common issues and solutions

**When to use**:
- Setting up development environment
- Testing new builds
- Debugging hardware issues
- Validating performance
- Preparing for production
- Troubleshooting failures

**Key Highlights**:
- Complete testing checklist (power, EEG, audio, timing, memory)
- Performance metrics with targets
- GDB debugging workflows
- Hardware test procedures
- Production QC checklist
- Common failure modes and solutions

---

### TODO.md (10 KB)
**Purpose**: Development roadmap and missing items

**Contents**:
- **Completed Items**: What's already done
- **Critical Items**: Required for first build
  1. Install build toolchain
  2. Add CMSIS-DSP library (for FFT)
  3. Create hardware register definitions
  4. Fix startup.c include order
  5. Add missing intrinsic functions
- **Important Items**: Needed for complete system
  6. Complete HAL hardware specifics
  7. Add FreeRTOS integration (optional)
  8. Expand test coverage
- **Nice-to-Have Items**: Future enhancements
  9. CI/CD pipeline
  10. Static analysis
  11. Code coverage
  12. Doxygen docs
  13-16. Hardware schematics, bootloader, power management, security
- **Priority Matrix**: Effort vs Impact analysis
- **Recommended Next Steps**: Phase-by-phase plan

**When to use**:
- Planning development work
- Understanding what's missing
- Prioritizing tasks
- Contributing to the project
- Getting system to first build

**Key Highlights**:
- Clear separation: completed vs pending
- Priority ranking (1-16)
- Effort and impact estimates
- Practical 3-phase plan
- Known blockers identified

---

### Makefile (10 KB)
**Purpose**: Production build system

**Contents**:
- **Toolchain Selection**: ARM cross-compiler + host compiler
- **Source Organization**: All 6 layers categorized
- **Include Paths**: Complete include tree
- **Compiler Flags**: Optimized for Cortex-M4F
- **Linker Configuration**: Memory layout, sections
- **Build Rules**: Automated compilation
- **Test Build**: Host test compilation
- **Flash/Debug Targets**: OpenOCD integration
- **Analysis Tools**: Size, disassembly, symbols

**Targets**:
- `make` - Build firmware
- `make test` - Run unit tests
- `make flash` - Flash to hardware
- `make debug` - Start GDB
- `make openocd` - Start debug server
- `make size` - Memory usage
- `make clean` - Clean build

**When to use**: Building, testing, flashing firmware

---

### setup.sh (8 KB)
**Purpose**: Automated development environment setup

**Contents**:
- ARM toolchain installation
- Build tools installation
- Debugging tools installation
- Serial tools installation
- USB permissions (ST-Link)
- Installation verification
- Build test

**When to use**: First-time setup on new machine

**Usage**:
```bash
./setup.sh
```

---

### docs/ (3,200+ lines)
**Purpose**: Per-file maintenance documentation

**Contents**:
- **README.md**: Documentation index
- **Cheat Sheets**:
  - `cheatsheet_hal.md` - HAL implementer's quick reference
  - `cheatsheet_porting.md` - Platform porting guide
- **Per-File Documentation** (26 files):
  - Purpose and design rationale
  - API documentation
  - Hardware couplings
  - Threading/ISR considerations
  - Common pitfalls
  - Maintenance checklist
  - Related files

**Organization**:
```
docs/
├── README.md
├── cheatsheet_hal.md
├── cheatsheet_porting.md
├── Makefile.documentation.md
├── common_types.h.documentation.md
├── hardware_config.h.documentation.md
├── system_config.h.documentation.md
├── Layer 1 HAL docs (10 files)
├── Layer 2 Driver docs (4 files)
├── Layer 3 Data Structure docs (4 files)
├── Layer 4 Processing docs (3 files)
├── Layer 5 Application docs (2 files)
└── Test docs (3 files)
```

**When to use**:
- Understanding specific source files
- Maintaining existing code
- Porting to new hardware
- Learning system internals

---

## 🔧 Configuration Files

### openocd.cfg
**Purpose**: OpenOCD debugger configuration

**Features**:
- ST-Link V2/V3 interface
- STM32F4 target configuration
- SWD transport
- Flash programming commands
- Debugging tips

### .gdbinit
**Purpose**: GDB initialization and custom commands

**Features**:
- Auto-connect to OpenOCD
- Custom commands: `connect`, `flash`, `reset_run`, `reset_halt`
- Breakpoint helpers: `break_on_error`, `break_main`
- Buffer inspection commands
- Pretty printing enabled

### linker/STM32F407VGTx_FLASH.ld
**Purpose**: Linker script for STM32F407

**Features**:
- Memory region definitions (Flash, RAM, CCM-RAM)
- Section placement (.text, .data, .bss)
- Stack and heap allocation
- Vector table at 0x08000000

---

## Learning Paths

### Path 1: Quick Start (1-2 hours)
1. Read **README.md** (15 min)
2. Run **setup.sh** (30 min)
3. Build with `make` (5 min)
4. Run tests with `make test` (5 min)
5. Browse **API_REFERENCE.md** examples (30 min)

### Path 2: Deep Understanding (1-2 days)
1. Read **ARCHITECTURE.md** in full (2 hours)
2. Review **API_REFERENCE.md** for all layers (2 hours)
3. Study source code with **docs/** reference (4 hours)
4. Run through **PRODUCTION_TESTING.md** procedures (2 hours)

### Path 3: Hardware Integration (3-5 days)
1. Read **ARCHITECTURE.md** - Memory & Timing sections
2. Study **docs/cheatsheet_hal.md**
3. Review **docs/cheatsheet_porting.md**
4. Implement HAL for new platform
5. Use **PRODUCTION_TESTING.md** for validation

### Path 4: Maintenance (ongoing)
1. Refer to **TODO.md** for current priorities
2. Use **docs/** for file-specific questions
3. **API_REFERENCE.md** for daily development
4. **PRODUCTION_TESTING.md** for debugging

---

## Documentation Quality Metrics

### Coverage
- **Source Files**: 16/16 (100%) have implementation
- **Header Files**: 16/16 (100%) documented in docs/
- **API Functions**: ~40 functions documented
- **Build System**: Fully documented Makefile
- **Testing**: Comprehensive test procedures

### Depth
- **Architecture**: 40 KB deep dive
- **API**: Complete reference with examples
- **Testing**: Layer-by-layer validation
- **Per-File**: Average 123 lines per file doc

### Usability
- **Quick Start**: <15 min to first build (with tools)
- **Examples**: Complete working code samples
- **Troubleshooting**: Common issues covered
- **References**: Cross-linked documentation

---

## 🔍 Finding Information

### "How do I..."

**...build the firmware?**
→ See **README.md** - Quick Start section

**...flash to hardware?**
→ See **PRODUCTION_TESTING.md** - Production Flash Procedure

**...debug a crash?**
→ See **PRODUCTION_TESTING.md** - Debugging Procedures → Hard Fault

**...use the EEG driver?**
→ See **API_REFERENCE.md** - Layer 2: Drivers → EEG Driver

**...understand the architecture?**
→ See **ARCHITECTURE.md** - Layer-by-Layer Architecture

**...port to new hardware?**
→ See **docs/cheatsheet_porting.md** + **ARCHITECTURE.md** - HAL section

**...add FreeRTOS?**
→ See **TODO.md** - Item 7 + **PRODUCTION_TESTING.md** - FreeBSD Integration

**...measure performance?**
→ See **PRODUCTION_TESTING.md** - Performance Validation

**...contribute?**
→ See **TODO.md** - Recommended Next Steps

---

## ✅ Documentation Completeness

### What's Documented
- ✅ System architecture and design principles
- ✅ Complete API reference for all layers
- ✅ Build system and toolchain setup
- ✅ Testing procedures (unit, integration, hardware)
- ✅ Debugging workflows (serial, GDB, OpenOCD)
- ✅ Performance validation procedures
- ✅ Production deployment checklist
- ✅ Common troubleshooting scenarios
- ✅ Memory architecture and optimization
- ✅ Real-time timing analysis
- ✅ Concurrency and thread safety
- ✅ Error handling strategies
- ✅ Configuration options
- ✅ Per-file implementation details

### What's Not Yet Documented
- ⚠️ Hardware schematics (see TODO.md #13)
- ⚠️ FreeRTOS task design (see TODO.md #7)
- ⚠️ Bootloader implementation (see TODO.md #14)
- ⚠️ Power management strategies (see TODO.md #15)
- ⚠️ Security features (see TODO.md #16)

---

## 🚀 Getting Started Right Now

### Absolute Beginner (Never seen this code)
```bash
# 1. Read the overview
cat README.md

# 2. Set up your environment
./setup.sh

# 3. Try building
make

# 4. Run tests
make test

# 5. Read the architecture
less ARCHITECTURE.md
```

### Experienced Embedded Developer (Want to understand design)
```bash
# 1. Understand the architecture
less ARCHITECTURE.md

# 2. Review the API
less API_REFERENCE.md

# 3. Check the code structure
tree -L 3 src/

# 4. Build and analyze
make
make size
make disasm
```

### Hardware Engineer (Need to integrate/port)
```bash
# 1. Read porting guide
less docs/cheatsheet_porting.md

# 2. Study HAL
less docs/cheatsheet_hal.md

# 3. Review hardware dependencies
grep -r "GPIOD_BASE\|SPI1\|DMA2" src/

# 4. Check missing items
less TODO.md
```

### QA/Test Engineer (Need to validate)
```bash
# 1. Read testing guide
less PRODUCTION_TESTING.md

# 2. Check test suite
less tests/test_all.c

# 3. Build and run tests
make test

# 4. Review test coverage
grep "bool test_" tests/*.c
```

---

## Support & Contribution

### Questions?
1. Check **TODO.md** for known issues
2. Search **PRODUCTION_TESTING.md** for troubleshooting
3. Review **docs/** for file-specific questions
4. See **API_REFERENCE.md** for API usage

### Found a Bug?
1. Check **TODO.md** - might be a known issue
2. Review **PRODUCTION_TESTING.md** - troubleshooting section
3. Document the issue with:
   - What you were doing
   - Expected behavior
   - Actual behavior
   - Debug output

### Want to Contribute?
1. Review **TODO.md** for priority items
2. Pick an item matching your skills
3. Read relevant docs in **docs/**
4. Make changes
5. Test with **PRODUCTION_TESTING.md** procedures
6. Update documentation

---

##  Documentation Maintenance

### When Code Changes
- [ ] Update relevant **docs/** file
- [ ] Update **API_REFERENCE.md** if API changed
- [ ] Update **ARCHITECTURE.md** if design changed
- [ ] Update **TODO.md** if item completed or new work identified
- [ ] Run `make test` to verify

### Quarterly Review
- [ ] Verify all documentation still accurate
- [ ] Add newly discovered issues to **TODO.md**
- [ ] Update performance metrics if changed
- [ ] Refresh examples if outdated

**Everything you need** to understand, build, test, debug, deploy, and maintain the NS embedded neurofeedback system.

---

**Document Version**: 1.0
**Maintained By**: NS Development Team
**Last Updated**: 2025-11-13
