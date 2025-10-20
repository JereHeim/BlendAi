#!/bin/bash

# BlendAI Ubuntu Server Setup Script
# Run this script to automatically install and configure BlendAI on Ubuntu Server

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

print_header() {
    echo -e "${BLUE}"
    echo "=================================="
    echo "     BlendAI Ubuntu Server Setup"
    echo "=================================="
    echo -e "${NC}"
}

print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check if running as root
check_root() {
    if [ "$EUID" -eq 0 ]; then
        print_error "Please don't run this script as root"
        exit 1
    fi
}

# Update system
update_system() {
    print_status "Updating system packages..."
    sudo apt update && sudo apt upgrade -y
    print_success "System updated"
}

# Install dependencies
install_dependencies() {
    print_status "Installing dependencies..."
    
    # Essential packages
    sudo apt install -y \
        python3 \
        python3-pip \
        wget \
        curl \
        git \
        unzip \
        software-properties-common \
        apt-transport-https \
        ca-certificates \
        gnupg \
        lsb-release \
        inotify-tools \
        imagemagick \
        ffmpeg
    
    # Install snap if not present
    if ! command -v snap >/dev/null 2>&1; then
        sudo apt install -y snapd
    fi
    
    print_success "Dependencies installed"
}

# Install Blender
install_blender() {
    print_status "Installing Blender..."
    
    # Try snap first (usually gets latest version)
    if command -v snap >/dev/null 2>&1; then
        print_status "Installing Blender via snap..."
        sudo snap install blender --classic
        if command -v blender >/dev/null 2>&1; then
            print_success "Blender installed via snap"
            blender --version
            return 0
        fi
    fi
    
    # Fallback to apt
    print_status "Installing Blender via apt..."
    sudo apt install -y blender
    
    if command -v blender >/dev/null 2>&1; then
        print_success "Blender installed via apt"
        blender --version
    else
        print_error "Failed to install Blender"
        return 1
    fi
}

# Setup directories
setup_directories() {
    print_status "Setting up directories..."
    
    # Create project directory
    BLENDAI_DIR="$HOME/blendai"
    mkdir -p "$BLENDAI_DIR"
    
    # Create working directories
    mkdir -p "$HOME/blendai_models"
    mkdir -p "$HOME/blendai_references"
    mkdir -p "$HOME/blendai_output"
    mkdir -p "$HOME/blendai_logs"
    
    print_success "Directories created:"
    print_status "  Project: $BLENDAI_DIR"
    print_status "  Models: $HOME/blendai_models"
    print_status "  References: $HOME/blendai_references"
    print_status "  Output: $HOME/blendai_output"
    print_status "  Logs: $HOME/blendai_logs"
}

# Copy and setup scripts
setup_scripts() {
    print_status "Setting up BlendAI scripts..."
    
    BLENDAI_DIR="$HOME/blendai"
    SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    
    # Copy all scripts
    cp "$SCRIPT_DIR/BlendAI_Ubuntu.py" "$BLENDAI_DIR/"
    cp "$SCRIPT_DIR/BlendAI_Smart.py" "$BLENDAI_DIR/"
    cp "$SCRIPT_DIR/run_blendai.sh" "$BLENDAI_DIR/"
    cp "$SCRIPT_DIR/smart_blendai.sh" "$BLENDAI_DIR/"
    cp "$SCRIPT_DIR/demo_smart.sh" "$BLENDAI_DIR/"
    cp "$SCRIPT_DIR/blendai.conf" "$BLENDAI_DIR/"
    
    # Make scripts executable
    chmod +x "$BLENDAI_DIR/run_blendai.sh"
    chmod +x "$BLENDAI_DIR/smart_blendai.sh"
    chmod +x "$BLENDAI_DIR/demo_smart.sh"
    
    # Update configuration with actual paths
    sed -i "s|/home/ubuntu/models|$HOME/blendai_models|g" "$BLENDAI_DIR/blendai.conf"
    sed -i "s|/home/ubuntu/references|$HOME/blendai_references|g" "$BLENDAI_DIR/blendai.conf"
    sed -i "s|/home/ubuntu/blendai_output|$HOME/blendai_output|g" "$BLENDAI_DIR/blendai.conf"
    
    print_success "Scripts installed to $BLENDAI_DIR"
    print_status "  📄 BlendAI_Ubuntu.py - Traditional processing"
    print_status "  🤖 BlendAI_Smart.py - AI generation"  
    print_status "  ⚙️  run_blendai.sh - Main automation script"
    print_status "  🧠 smart_blendai.sh - AI generation interface"
    print_status "  🎪 demo_smart.sh - Interactive demo"
}

# Create systemd service
create_service() {
    print_status "Creating systemd service..."
    
    BLENDAI_DIR="$HOME/blendai"
    
    # Create service file
    sudo tee /etc/systemd/system/blendai.service > /dev/null << EOF
[Unit]
Description=BlendAI Automatic Processing Service
After=network.target
Wants=network.target

[Service]
Type=simple
User=$USER
Group=$USER
WorkingDirectory=$BLENDAI_DIR
ExecStart=$BLENDAI_DIR/blendai_watcher.sh
Restart=always
RestartSec=10
Environment=HOME=$HOME
Environment=USER=$USER

[Install]
WantedBy=multi-user.target
EOF

    # Reload systemd and enable service
    sudo systemctl daemon-reload
    sudo systemctl enable blendai.service
    
    print_success "Systemd service created and enabled"
    print_status "Service will start automatically on boot"
    print_status "Use: sudo systemctl start blendai.service to start now"
}

# Create command aliases
create_aliases() {
    print_status "Creating command aliases..."
    
    BLENDAI_DIR="$HOME/blendai"
    
    # Add aliases to .bashrc if not already present
    if ! grep -q "# BlendAI aliases" "$HOME/.bashrc"; then
        cat >> "$HOME/.bashrc" << EOF

# BlendAI aliases
alias blendai='$BLENDAI_DIR/run_blendai.sh'
alias smart-blendai='$BLENDAI_DIR/smart_blendai.sh'
alias blendai-demo='$BLENDAI_DIR/demo_smart.sh'
alias blendai-status='sudo systemctl status blendai.service'
alias blendai-logs='sudo journalctl -u blendai.service -f'
alias blendai-start='sudo systemctl start blendai.service'
alias blendai-stop='sudo systemctl stop blendai.service'
alias blendai-restart='sudo systemctl restart blendai.service'
EOF
        print_success "Aliases added to .bashrc"
        print_status "Run 'source ~/.bashrc' or restart your terminal to use them"
    else
        print_warning "Aliases already exist in .bashrc"
    fi
}

# Test installation
test_installation() {
    print_status "Testing installation..."
    
    BLENDAI_DIR="$HOME/blendai"
    
    # Test Blender
    if command -v blender >/dev/null 2>&1; then
        print_success "✓ Blender is available"
    else
        print_error "✗ Blender not found"
        return 1
    fi
    
    # Test Python script
    if [ -f "$BLENDAI_DIR/BlendAI_Ubuntu.py" ]; then
        print_success "✓ BlendAI Python script is present"
    else
        print_error "✗ BlendAI Python script missing"
        return 1
    fi
    
    # Test smart generation script
    if [ -x "$BLENDAI_DIR/smart_blendai.sh" ]; then
        print_success "✓ Smart BlendAI script is executable"
    else
        print_error "✗ Smart BlendAI script not executable"
        return 1
    fi
    
    # Test demo script
    if [ -x "$BLENDAI_DIR/demo_smart.sh" ]; then
        print_success "✓ Demo script is executable"
    else
        print_error "✗ Demo script not executable"
        return 1
    fi
    
    # Test directories
    for dir in "$HOME/blendai_models" "$HOME/blendai_references" "$HOME/blendai_output"; do
        if [ -d "$dir" ]; then
            print_success "✓ Directory exists: $dir"
        else
            print_error "✗ Directory missing: $dir"
            return 1
        fi
    done
    
    print_success "All tests passed!"
}

# Print usage instructions
print_usage_instructions() {
    BLENDAI_DIR="$HOME/blendai"
    
    echo -e "${GREEN}"
    echo "=================================="
    echo "   BlendAI Setup Complete!"
    echo "=================================="
    echo -e "${NC}"
    echo
    echo "🤖 Smart AI Generation:"
    echo "  smart-blendai 'medieval sword'            # Generate a sword"
    echo "  smart-blendai 'goblin warrior' -d 'armor' # Goblin with style"
    echo "  smart-blendai -i                          # Interactive mode"
    echo "  blendai-demo                              # Try the demo!"
    echo
    echo "📋 Traditional Processing:"
    echo "  1. Copy your .fbx models to: $HOME/blendai_models/"
    echo "  2. Copy your reference images to: $HOME/blendai_references/"
    echo "  3. Run: blendai model.fbx reference.png"
    echo
    echo "Or process a specific file:"
    echo "  blendai /path/to/model.fbx /path/to/reference.png"
    echo
    echo "Available commands:"
    echo "  smart-blendai    - AI model generation"
    echo "  blendai-demo     - Interactive demo" 
    echo "  blendai          - Process existing files"
    echo "  blendai-status   - Check service status"
    echo "  blendai-logs     - View service logs"
    echo "  blendai-start    - Start automatic processing"
    echo "  blendai-stop     - Stop automatic processing"
    echo "  blendai-restart  - Restart service"
    echo
    echo "Configuration file: $BLENDAI_DIR/blendai.conf"
    echo "Output directory: $HOME/blendai_output/"
    echo
    echo "To enable automatic processing when files are added:"
    echo "  sudo systemctl start blendai.service"
    echo
    echo -e "${YELLOW}Remember to restart your terminal or run 'source ~/.bashrc' to use the aliases!${NC}"
}

# Main installation function
main() {
    print_header
    
    check_root
    update_system
    install_dependencies
    install_blender
    setup_directories
    setup_scripts
    create_service
    create_aliases
    
    if test_installation; then
        print_usage_instructions
        echo
        print_success "Setup completed successfully!"
        exit 0
    else
        print_error "Setup failed during testing"
        exit 1
    fi
}

# Run main function
main "$@"