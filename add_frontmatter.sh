#!/bin/bash
# Script to add front matter to existing documentation files
# WARNING: This modifies files in place. Commit your changes first!

set -e

# Color output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${YELLOW}NeuroStereo Documentation Front Matter Injector${NC}"
echo "================================================"
echo ""
echo -e "${RED}WARNING: This will modify files in place!${NC}"
echo "Make sure you have committed or backed up your files."
echo ""
read -p "Continue? (y/n) " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]
then
    echo "Aborted."
    exit 1
fi

DOCS_DIR="docs"

# Function to add front matter if not already present
add_frontmatter() {
    local file=$1
    local title=$2
    local nav_order=$3
    local parent=$4
    
    # Check if file already has front matter
    if head -n 1 "$file" | grep -q "^---$"; then
        echo -e "${YELLOW}Skipping${NC} $file (already has front matter)"
        return
    fi
    
    # Create temp file with front matter
    local temp_file=$(mktemp)
    
    echo "---" > "$temp_file"
    echo "layout: default" >> "$temp_file"
    echo "title: $title" >> "$temp_file"
    
    if [ -n "$parent" ]; then
        echo "parent: $parent" >> "$temp_file"
    fi
    
    echo "nav_order: $nav_order" >> "$temp_file"
    echo "---" >> "$temp_file"
    echo "" >> "$temp_file"
    
    # Append original content
    cat "$file" >> "$temp_file"
    
    # Replace original file
    mv "$temp_file" "$file"
    
    echo -e "${GREEN}✓${NC} Added front matter to $file"
}

# Create parent pages
echo ""
echo "Creating parent pages..."

cat > "$DOCS_DIR/system-integration.md" << 'EOF'
---
layout: default
title: System Integration
nav_order: 20
has_children: true
---

# System Integration Guides

Resources for porting and integrating NeuroStereo on different platforms.
EOF
echo -e "${GREEN}✓${NC} Created $DOCS_DIR/system-integration.md"

cat > "$DOCS_DIR/hal-layer.md" << 'EOF'
---
layout: default
title: HAL Layer
nav_order: 30
has_children: true
---

# Hardware Abstraction Layer

Platform-independent hardware interfaces.
EOF
echo -e "${GREEN}✓${NC} Created $DOCS_DIR/hal-layer.md"

cat > "$DOCS_DIR/drivers-layer.md" << 'EOF'
---
layout: default
title: Driver Layer
nav_order: 40
has_children: true
---

# Hardware Drivers

Device-specific driver implementations.
EOF
echo -e "${GREEN}✓${NC} Created $DOCS_DIR/drivers-layer.md"

cat > "$DOCS_DIR/processing-layer.md" << 'EOF'
---
layout: default
title: Processing Layer
nav_order: 50
has_children: true
---

# Signal Processing

DSP and real-time processing components.
EOF
echo -e "${GREEN}✓${NC} Created $DOCS_DIR/processing-layer.md"

cat > "$DOCS_DIR/application-layer.md" << 'EOF'
---
layout: default
title: Application Layer
nav_order: 60
has_children: true
---

# Application Components

High-level neurofeedback application logic.
EOF
echo -e "${GREEN}✓${NC} Created $DOCS_DIR/application-layer.md"

cat > "$DOCS_DIR/utilities.md" << 'EOF'
---
layout: default
title: Utilities
nav_order: 70
has_children: true
---

# Utility Components

Common utilities and buffer management.
EOF
echo -e "${GREEN}✓${NC} Created $DOCS_DIR/utilities.md"

cat > "$DOCS_DIR/low-level.md" << 'EOF'
---
layout: default
title: Low-Level System
nav_order: 80
has_children: true
---

# Low-Level System Code

Startup, synchronization, and system initialization.
EOF
echo -e "${GREEN}✓${NC} Created $DOCS_DIR/low-level.md"

# Add front matter to existing files
echo ""
echo "Adding front matter to existing files..."

# Getting Started section
add_frontmatter "$DOCS_DIR/getting_started.md" "Getting Started" 10 ""
add_frontmatter "$DOCS_DIR/ARCHITECTURE.md" "System Architecture" 11 ""
add_frontmatter "$DOCS_DIR/API_REFERENCE.md" "API Reference" 12 ""
add_frontmatter "$DOCS_DIR/DOCUMENTATION_INDEX.md" "Documentation Index" 13 ""

# System Integration (if these exist, otherwise skip)
[ -f "$DOCS_DIR/cheatsheet_hal.md" ] && add_frontmatter "$DOCS_DIR/cheatsheet_hal.md" "HAL Quick Reference" 1 "System Integration"
[ -f "$DOCS_DIR/cheatsheet_porting.md" ] && add_frontmatter "$DOCS_DIR/cheatsheet_porting.md" "Platform Porting Guide" 2 "System Integration"
[ -f "$DOCS_DIR/hardware_config.h.documentation.md" ] && add_frontmatter "$DOCS_DIR/hardware_config.h.documentation.md" "Hardware Configuration" 3 "System Integration"

# HAL Layer
add_frontmatter "$DOCS_DIR/hal_dma.c.documentation.md" "DMA HAL" 1 "HAL Layer"
add_frontmatter "$DOCS_DIR/hal_dma.h.documentation.md" "DMA HAL Header" 2 "HAL Layer"
add_frontmatter "$DOCS_DIR/hal_gpio.c.documentation.md" "GPIO HAL" 3 "HAL Layer"
add_frontmatter "$DOCS_DIR/hal_gpio.h.documentation.md" "GPIO HAL Header" 4 "HAL Layer"
add_frontmatter "$DOCS_DIR/hal_i2s.c.documentation.md" "I2S HAL" 5 "HAL Layer"
add_frontmatter "$DOCS_DIR/hal_i2s.h.documentation.md" "I2S HAL Header" 6 "HAL Layer"
add_frontmatter "$DOCS_DIR/hal_spi.c.documentation.md" "SPI HAL" 7 "HAL Layer"
add_frontmatter "$DOCS_DIR/hal_spi.h.documentation.md" "SPI HAL Header" 8 "HAL Layer"
add_frontmatter "$DOCS_DIR/hal_timer.c.documentation.md" "Timer HAL" 9 "HAL Layer"
add_frontmatter "$DOCS_DIR/hal_timer.h.documentation.md" "Timer HAL Header" 10 "HAL Layer"

# Driver Layer
add_frontmatter "$DOCS_DIR/audio_driver.c.documentation.md" "Audio Driver" 1 "Driver Layer"
add_frontmatter "$DOCS_DIR/audio_driver.h.documentation.md" "Audio Driver Header" 2 "Driver Layer"
add_frontmatter "$DOCS_DIR/eeg_driver.c.documentation.md" "EEG Driver (ADS1299)" 3 "Driver Layer"
add_frontmatter "$DOCS_DIR/eeg_driver.h.documentation.md" "EEG Driver Header" 4 "Driver Layer"

# Processing Layer
add_frontmatter "$DOCS_DIR/audio_processor.h.documentation.md" "Audio Processor" 1 "Processing Layer"
add_frontmatter "$DOCS_DIR/eeg_processor.h.documentation.md" "EEG Processor" 2 "Processing Layer"
add_frontmatter "$DOCS_DIR/fft_engine.h.documentation.md" "FFT Engine" 3 "Processing Layer"

# Application Layer
add_frontmatter "$DOCS_DIR/neurofeedback_engine.h.documentation.md" "Neurofeedback Engine" 1 "Application Layer"
add_frontmatter "$DOCS_DIR/main.c.documentation.md" "Main Application" 2 "Application Layer"

# Utilities
add_frontmatter "$DOCS_DIR/ring_buffer.c.documentation.md" "Ring Buffer Implementation" 1 "Utilities"
add_frontmatter "$DOCS_DIR/ring_buffer.h.documentation.md" "Ring Buffer Header" 2 "Utilities"
add_frontmatter "$DOCS_DIR/common_types.h.documentation.md" "Common Types" 3 "Utilities"

# Low-Level System
add_frontmatter "$DOCS_DIR/startup.c.documentation.md" "Startup Code" 1 "Low-Level System"
add_frontmatter "$DOCS_DIR/time_sync.h.documentation.md" "Time Synchronization" 2 "Low-Level System"

# Maintenance (if exists)
[ -f "$DOCS_DIR/maintenance.md" ] && add_frontmatter "$DOCS_DIR/maintenance.md" "Maintenance" 92 ""

echo ""
echo -e "${GREEN}Done!${NC}"
echo ""
echo "Next steps:"
echo "1. Review the changes: git diff"
echo "2. Commit: git add docs/ && git commit -m 'Add front matter for GitHub Pages'"
echo "3. Copy _config.yml to repo root"
echo "4. Enable GitHub Pages in repo Settings"
