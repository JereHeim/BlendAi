#!/bin/bash

# 🚀 BlendAI Server Quick Deploy Script
# Run this script on your Ubuntu server to deploy BlendAI

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
NC='\033[0m'

# Configuration
REPO_URL="https://github.com/JereHeim/BlendAi.git"
INSTALL_DIR="$HOME/blendai"
LOG_FILE="/tmp/blendai_deploy.log"

print_banner() {
    echo -e "${PURPLE}"
    echo "🚀================================================🚀"
    echo "        BlendAI Server Deployment Script"
    echo "   Automated setup for Ubuntu Server"
    echo "🚀================================================🚀"
    echo -e "${NC}"
}

print_status() {
    echo -e "${BLUE}[INFO]${NC} $1" | tee -a "$LOG_FILE"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1" | tee -a "$LOG_FILE"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1" | tee -a "$LOG_FILE"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1" | tee -a "$LOG_FILE"
}

check_requirements() {
    print_status "Checking system requirements..."
    
    # Check if running on Ubuntu
    if [ -f /etc/lsb-release ]; then
        . /etc/lsb-release
        print_success "Running on $DISTRIB_DESCRIPTION"
    else
        print_warning "Not running on Ubuntu - compatibility not guaranteed"
    fi
    
    # Check internet connection
    if ping -c 1 google.com &> /dev/null; then
        print_success "Internet connection available"
    else
        print_error "No internet connection - deployment will fail"
        exit 1
    fi
    
    # Check if running as root
    if [ "$EUID" -eq 0 ]; then
        print_error "Please don't run this script as root"
        exit 1
    fi
    
    # Check available space
    AVAILABLE_SPACE=$(df $HOME --output=avail | tail -1)
    if [ "$AVAILABLE_SPACE" -lt 2097152 ]; then  # Less than 2GB
        print_warning "Less than 2GB available in home directory"
    else
        print_success "Sufficient disk space available"
    fi
}

install_dependencies() {
    print_status "Installing system dependencies..."
    
    # Update package list
    sudo apt update >> "$LOG_FILE" 2>&1
    
    # Install essential packages
    sudo apt install -y \
        git \
        python3 \
        python3-pip \
        wget \
        curl \
        unzip \
        software-properties-common \
        apt-transport-https \
        ca-certificates \
        gnupg \
        lsb-release \
        inotify-tools \
        imagemagick \
        ffmpeg \
        >> "$LOG_FILE" 2>&1
    
    print_success "Dependencies installed"
}

install_blender() {
    print_status "Installing Blender..."
    
    if command -v blender >/dev/null 2>&1; then
        print_success "Blender already installed"
        blender --version | head -1
        return 0
    fi
    
    # Try snap first
    if command -v snap >/dev/null 2>&1; then
        print_status "Installing Blender via snap..."
        sudo snap install blender --classic >> "$LOG_FILE" 2>&1
        if command -v blender >/dev/null 2>&1; then
            print_success "Blender installed via snap"
            return 0
        fi
    fi
    
    # Fallback to apt
    print_status "Installing Blender via apt..."
    sudo apt install -y blender >> "$LOG_FILE" 2>&1
    
    if command -v blender >/dev/null 2>&1; then
        print_success "Blender installed via apt"
    else
        print_error "Failed to install Blender"
        return 1
    fi
}

clone_repository() {
    print_status "Cloning BlendAI repository..."
    
    # Remove existing directory if it exists
    if [ -d "$INSTALL_DIR" ]; then
        print_warning "Existing BlendAI directory found, backing up..."
        mv "$INSTALL_DIR" "${INSTALL_DIR}_backup_$(date +%Y%m%d_%H%M%S)"
    fi
    
    # Clone repository
    git clone "$REPO_URL" "$INSTALL_DIR" >> "$LOG_FILE" 2>&1
    
    if [ -d "$INSTALL_DIR" ]; then
        print_success "Repository cloned successfully"
    else
        print_error "Failed to clone repository"
        exit 1
    fi
}

setup_blendai() {
    print_status "Setting up BlendAI..."
    
    cd "$INSTALL_DIR"
    
    # Make scripts executable
    chmod +x *.sh
    
    # Run the main setup script
    if [ -f "setup_ubuntu.sh" ]; then
        print_status "Running BlendAI setup..."
        ./setup_ubuntu.sh >> "$LOG_FILE" 2>&1
        print_success "BlendAI setup completed"
    else
        print_error "setup_ubuntu.sh not found"
        exit 1
    fi
}

verify_installation() {
    print_status "Verifying installation..."
    
    # Source bashrc to get aliases
    source ~/.bashrc 2>/dev/null || true
    
    # Test Blender
    if command -v blender >/dev/null 2>&1; then
        print_success "✓ Blender is available"
    else
        print_error "✗ Blender not found"
        return 1
    fi
    
    # Test BlendAI scripts
    if [ -f "$INSTALL_DIR/smart_blendai.sh" ] && [ -x "$INSTALL_DIR/smart_blendai.sh" ]; then
        print_success "✓ Smart BlendAI script is ready"
    else
        print_error "✗ Smart BlendAI script not found or not executable"
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
    
    print_success "All verification tests passed!"
}

run_test() {
    print_status "Running test generation..."
    
    cd "$INSTALL_DIR"
    
    # Test basic generation
    print_status "Testing basic cube generation..."
    if ./smart_blendai.sh "test cube" -o "$HOME/blendai_test" >> "$LOG_FILE" 2>&1; then
        print_success "✓ Test generation successful"
        
        # Check if files were created
        if [ -d "$HOME/blendai_test" ] && [ "$(ls -A $HOME/blendai_test)" ]; then
            print_success "✓ Output files created"
            ls -la "$HOME/blendai_test/"
        else
            print_warning "⚠ No output files found"
        fi
    else
        print_warning "⚠ Test generation failed (this might be normal in headless mode)"
    fi
}

show_usage_instructions() {
    echo
    echo -e "${GREEN}🎉 BlendAI Deployment Complete!${NC}"
    echo -e "${GREEN}================================${NC}"
    echo
    echo -e "${BLUE}📁 Installation Location:${NC} $INSTALL_DIR"
    echo -e "${BLUE}📋 Log File:${NC} $LOG_FILE"
    echo
    echo -e "${YELLOW}🚀 Quick Start Commands:${NC}"
    echo -e "  ${GREEN}# Source the new aliases${NC}"
    echo -e "  source ~/.bashrc"
    echo
    echo -e "  ${GREEN}# Test the installation${NC}"
    echo -e "  smart-blendai --examples"
    echo
    echo -e "  ${GREEN}# Generate your first model${NC}"
    echo -e "  smart-blendai 'medieval sword'"
    echo
    echo -e "  ${GREEN}# Try interactive mode${NC}"
    echo -e "  smart-blendai -i"
    echo
    echo -e "  ${GREEN}# Run the demo${NC}"
    echo -e "  blendai-demo"
    echo
    echo -e "${YELLOW}📖 Available Commands:${NC}"
    echo -e "  smart-blendai     - AI model generation"
    echo -e "  blendai-demo      - Interactive demo"
    echo -e "  blendai           - Process existing files"
    echo -e "  blendai-start     - Start background service"
    echo -e "  blendai-status    - Check service status"
    echo -e "  blendai-logs      - View service logs"
    echo
    echo -e "${YELLOW}📚 Documentation:${NC}"
    echo -e "  README.md         - Complete feature guide"
    echo -e "  DEPLOYMENT.md     - Detailed deployment guide"
    echo
    echo -e "${BLUE}💡 Next Steps:${NC}"
    echo -e "  1. Restart your terminal or run: source ~/.bashrc"
    echo -e "  2. Try: smart-blendai --examples"
    echo -e "  3. Generate your first model!"
    echo -e "  4. Upload reference images to: ~/blendai_references/"
    echo -e "  5. Check output in: ~/blendai_output/"
    echo
}

cleanup() {
    # Clean up test files
    rm -rf "$HOME/blendai_test" 2>/dev/null || true
    
    print_status "Deployment log saved to: $LOG_FILE"
}

main() {
    print_banner
    
    echo "This script will:"
    echo "  ✓ Install all dependencies"
    echo "  ✓ Install Blender"
    echo "  ✓ Clone BlendAI repository"
    echo "  ✓ Setup and configure everything"
    echo "  ✓ Run verification tests"
    echo
    read -p "Continue with deployment? (y/N): " -n 1 -r
    echo
    
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo "Deployment cancelled."
        exit 0
    fi
    
    echo "Starting deployment..." > "$LOG_FILE"
    
    check_requirements
    install_dependencies
    install_blender
    clone_repository
    setup_blendai
    
    if verify_installation; then
        run_test
        show_usage_instructions
        cleanup
        print_success "🎉 BlendAI deployment completed successfully!"
        exit 0
    else
        print_error "💥 Deployment failed during verification"
        print_status "Check the log file: $LOG_FILE"
        exit 1
    fi
}

# Handle Ctrl+C
trap 'echo -e "\n${RED}Deployment interrupted by user${NC}"; exit 1' INT

# Run main function
main "$@"