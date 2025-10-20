#!/bin/bash

# BlendAI Ubuntu Server Automation Script
# This script automates the BlendAI process on Ubuntu server

set -e  # Exit on any error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BLENDAI_SCRIPT="${SCRIPT_DIR}/BlendAI_Ubuntu.py"
DEFAULT_OUTPUT_DIR="/tmp/blendai_output"
BLENDER_EXECUTABLE="blender"

# Function to print colored output
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

# Function to check if command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Function to install Blender if not present
install_blender() {
    print_status "Checking for Blender installation..."
    
    if command_exists blender; then
        print_success "Blender is already installed"
        blender --version
        return 0
    fi
    
    print_warning "Blender not found. Installing via snap..."
    
    # Check if snap is available
    if command_exists snap; then
        sudo snap install blender --classic
        if [ $? -eq 0 ]; then
            print_success "Blender installed successfully via snap"
            return 0
        fi
    fi
    
    # Try apt if snap fails
    print_warning "Snap failed, trying apt..."
    sudo apt update
    sudo apt install -y blender
    
    if command_exists blender; then
        print_success "Blender installed successfully via apt"
        return 0
    else
        print_error "Failed to install Blender"
        return 1
    fi
}

# Function to check system requirements
check_requirements() {
    print_status "Checking system requirements..."
    
    # Check if running on Ubuntu
    if [ ! -f /etc/lsb-release ]; then
        print_warning "Not running on Ubuntu, compatibility not guaranteed"
    else
        . /etc/lsb-release
        print_status "Running on $DISTRIB_DESCRIPTION"
    fi
    
    # Check Python version
    if command_exists python3; then
        PYTHON_VERSION=$(python3 --version 2>&1 | cut -d' ' -f2)
        print_success "Python 3 found: $PYTHON_VERSION"
    else
        print_error "Python 3 not found"
        return 1
    fi
    
    # Check available disk space
    AVAILABLE_SPACE=$(df /tmp --output=avail | tail -1)
    if [ "$AVAILABLE_SPACE" -lt 1048576 ]; then  # Less than 1GB
        print_warning "Less than 1GB available in /tmp"
    else
        print_success "Sufficient disk space available"
    fi
    
    return 0
}

# Function to validate input files
validate_files() {
    local model_file="$1"
    local reference_file="$2"
    
    print_status "Validating input files..."
    
    if [ ! -f "$model_file" ]; then
        print_error "Model file not found: $model_file"
        return 1
    fi
    
    if [ ! -f "$reference_file" ]; then
        print_error "Reference image not found: $reference_file"
        return 1
    fi
    
    # Check file extensions
    if [[ ! "$model_file" =~ \.(fbx|FBX)$ ]]; then
        print_warning "Model file doesn't have .fbx extension"
    fi
    
    if [[ ! "$reference_file" =~ \.(png|jpg|jpeg|PNG|JPG|JPEG)$ ]]; then
        print_warning "Reference file doesn't appear to be a common image format"
    fi
    
    print_success "Input files validated"
    return 0
}

# Function to run BlendAI
run_blendai() {
    local model_file="$1"
    local reference_file="$2"
    local output_dir="$3"
    local additional_args="$4"
    
    print_status "Starting BlendAI automation..."
    
    # Create output directory
    mkdir -p "$output_dir"
    
    # Convert to absolute paths
    model_file=$(realpath "$model_file")
    reference_file=$(realpath "$reference_file")
    output_dir=$(realpath "$output_dir")
    
    print_status "Model: $model_file"
    print_status "Reference: $reference_file"
    print_status "Output: $output_dir"
    
    # Run Blender in background mode with Python script
    print_status "Executing Blender with BlendAI script..."
    
    local cmd="$BLENDER_EXECUTABLE --background --python \"$BLENDAI_SCRIPT\" -- --model \"$model_file\" --reference \"$reference_file\" --output \"$output_dir\" $additional_args"
    
    echo "Command: $cmd"
    
    if eval "$cmd"; then
        print_success "BlendAI completed successfully!"
        print_status "Results saved to: $output_dir"
        
        # List output files
        if [ -d "$output_dir" ]; then
            print_status "Generated files:"
            ls -la "$output_dir"
        fi
        
        return 0
    else
        print_error "BlendAI failed!"
        return 1
    fi
}

# Function to setup automatic execution
setup_automation() {
    local model_dir="$1"
    local reference_dir="$2"
    local output_dir="$3"
    
    print_status "Setting up automatic execution..."
    
    # Create a watcher script for automatic processing
    cat > "${SCRIPT_DIR}/blendai_watcher.sh" << EOF
#!/bin/bash
# BlendAI Automatic Watcher Script

WATCH_DIR_MODELS="$model_dir"
WATCH_DIR_REFS="$reference_dir"
OUTPUT_DIR="$output_dir"
SCRIPT_PATH="$SCRIPT_DIR/run_blendai.sh"

# Install inotify-tools if not present
if ! command -v inotifywait >/dev/null 2>&1; then
    echo "Installing inotify-tools..."
    sudo apt update && sudo apt install -y inotify-tools
fi

echo "Watching \$WATCH_DIR_MODELS for new .fbx files..."
echo "Watching \$WATCH_DIR_REFS for new image files..."

# Watch for new files
inotifywait -m -e create -e moved_to "\$WATCH_DIR_MODELS" "\$WATCH_DIR_REFS" --format '%w%f %e' | while read file event; do
    if [[ "\$file" =~ \.(fbx|FBX)$ ]]; then
        echo "New model detected: \$file"
        # Look for corresponding reference image
        model_basename=\$(basename "\$file" .fbx)
        for ref_file in "\$WATCH_DIR_REFS"/"\$model_basename".{png,jpg,jpeg,PNG,JPG,JPEG}; do
            if [ -f "\$ref_file" ]; then
                echo "Found reference: \$ref_file"
                echo "Processing automatically..."
                "\$SCRIPT_PATH" "\$file" "\$ref_file" "\$OUTPUT_DIR"
                break
            fi
        done
    fi
done
EOF

    chmod +x "${SCRIPT_DIR}/blendai_watcher.sh"
    print_success "Automation script created: ${SCRIPT_DIR}/blendai_watcher.sh"
    
    # Create systemd service for automatic startup
    cat > /tmp/blendai.service << EOF
[Unit]
Description=BlendAI Automatic Processing Service
After=network.target

[Service]
Type=simple
User=$USER
WorkingDirectory=$SCRIPT_DIR
ExecStart=${SCRIPT_DIR}/blendai_watcher.sh
Restart=always
RestartSec=10

[Install]
WantedBy=multi-user.target
EOF

    print_status "Systemd service file created. To install:"
    print_status "sudo cp /tmp/blendai.service /etc/systemd/system/"
    print_status "sudo systemctl enable blendai"
    print_status "sudo systemctl start blendai"
}

# Function to show usage
show_usage() {
    echo "Usage: $0 [OPTIONS] <model_file> <reference_image> [output_dir]"
    echo ""
    echo "Options:"
    echo "  -h, --help              Show this help message"
    echo "  --install               Install Blender and dependencies"
    echo "  --setup-auto DIR1 DIR2  Setup automatic processing (model_dir ref_dir)"
    echo "  --no-save               Skip saving .blend file"
    echo "  --no-export             Skip FBX export"
    echo "  --no-render             Skip preview render"
    echo "  --check                 Check system requirements only"
    echo ""
    echo "Examples:"
    echo "  $0 model.fbx reference.png"
    echo "  $0 --install"
    echo "  $0 --setup-auto /watch/models /watch/refs"
    echo "  $0 --check"
}

# Main script logic
main() {
    local install_mode=false
    local check_mode=false
    local setup_auto=false
    local model_file=""
    local reference_file=""
    local output_dir="$DEFAULT_OUTPUT_DIR"
    local additional_args=""
    
    # Parse command line arguments
    while [[ $# -gt 0 ]]; do
        case $1 in
            -h|--help)
                show_usage
                exit 0
                ;;
            --install)
                install_mode=true
                shift
                ;;
            --check)
                check_mode=true
                shift
                ;;
            --setup-auto)
                setup_auto=true
                setup_model_dir="$2"
                setup_ref_dir="$3"
                shift 3
                ;;
            --no-save)
                additional_args="$additional_args --no-save"
                shift
                ;;
            --no-export)
                additional_args="$additional_args --no-export"
                shift
                ;;
            --no-render)
                additional_args="$additional_args --no-render"
                shift
                ;;
            *)
                if [ -z "$model_file" ]; then
                    model_file="$1"
                elif [ -z "$reference_file" ]; then
                    reference_file="$1"
                elif [ -z "$output_dir" ] || [ "$output_dir" = "$DEFAULT_OUTPUT_DIR" ]; then
                    output_dir="$1"
                fi
                shift
                ;;
        esac
    done
    
    # Check if BlendAI script exists
    if [ ! -f "$BLENDAI_SCRIPT" ]; then
        print_error "BlendAI script not found: $BLENDAI_SCRIPT"
        exit 1
    fi
    
    # Handle different modes
    if [ "$install_mode" = true ]; then
        print_status "Installing Blender and dependencies..."
        install_blender
        exit $?
    fi
    
    if [ "$check_mode" = true ]; then
        check_requirements
        exit $?
    fi
    
    if [ "$setup_auto" = true ]; then
        if [ -z "$setup_model_dir" ] || [ -z "$setup_ref_dir" ]; then
            print_error "Setup mode requires model directory and reference directory"
            show_usage
            exit 1
        fi
        setup_automation "$setup_model_dir" "$setup_ref_dir" "$output_dir"
        exit 0
    fi
    
    # Normal processing mode
    if [ -z "$model_file" ] || [ -z "$reference_file" ]; then
        print_error "Model file and reference image are required"
        show_usage
        exit 1
    fi
    
    # Run the full process
    check_requirements || exit 1
    install_blender || exit 1
    validate_files "$model_file" "$reference_file" || exit 1
    run_blendai "$model_file" "$reference_file" "$output_dir" "$additional_args"
}

# Run main function with all arguments
main "$@"