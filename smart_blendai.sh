#!/bin/bash

# Smart BlendAI - AI-Powered 3D Model Generation Script
# This script can generate 3D models from text descriptions

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
NC='\033[0m'

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SMART_SCRIPT="${SCRIPT_DIR}/BlendAI_Smart.py"
DEFAULT_OUTPUT_DIR="/tmp/blendai_smart_output"
BLENDER_EXECUTABLE="blender"

print_header() {
    echo -e "${PURPLE}"
    echo "🤖================================================🤖"
    echo "    Smart BlendAI - AI 3D Model Generation"
    echo "🤖================================================🤖"
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

# Show what can be generated
show_examples() {
    echo -e "${PURPLE}🎯 What Smart BlendAI can generate:${NC}"
    echo
    echo -e "${GREEN}⚔️  WEAPONS (with reference photos):${NC}"
    echo "  • 'katana' + katana_reference.jpg → Curved Japanese sword"
    echo "  • 'medieval sword' + sword_ref.png → European longsword"
    echo "  • 'dagger' + dagger_photo.jpg → Short curved blade"
    echo "  • 'greatsword' + greatsword.png → Large two-handed sword"
    echo "  • 'battle axe with runes' + axe_reference.jpg"
    echo
    echo -e "${GREEN}👥 CHARACTERS (with reference photos):${NC}"
    echo "  • 'human warrior' + warrior_ref.jpg → Armored knight"
    echo "  • 'goblin rogue' + goblin_art.png → Small sneaky creature"
    echo "  • 'orc chieftain' + orc_reference.jpg → Large tribal leader"
    echo "  • 'elf mage character' + elf_concept.png"
    echo
    echo -e "${GREEN}🏰 BUILDINGS (with reference photos):${NC}"
    echo "  • 'medieval castle' + castle_photo.jpg → Stone fortress"
    echo "  • 'wooden tavern' + inn_reference.png → Rustic building"
    echo "  • 'wizard tower' + tower_art.jpg → Magical spire"
    echo
    echo -e "${YELLOW}💡 Pro Tips:${NC}"
    echo "  • Use clear reference images for better accuracy"
    echo "  • JPEG, PNG, and TIFF formats supported"
    echo "  • Higher resolution references = better results"
    echo "  • Side-view or 3/4 view references work best"
    echo
}

# Interactive generation mode
interactive_mode() {
    print_header
    show_examples
    echo
    echo -e "${BLUE}💡 Enter your description (or 'examples' to see more, 'quit' to exit):${NC}"
    
    while true; do
        echo -n "🤖 Generate: "
        read -r prompt
        
        case "$prompt" in
            "quit"|"exit"|"q")
                echo -e "${GREEN}Goodbye! Happy creating! 🎨${NC}"
                exit 0
                ;;
            "examples"|"help"|"h")
                show_examples
                continue
                ;;
            "")
                echo -e "${YELLOW}Please enter a description or 'quit' to exit${NC}"
                continue
                ;;
        esac
        
        echo -e "${BLUE}🎨 Generating: '$prompt'${NC}"
        
        # Optional reference image
        echo -n "📸 Reference image path (optional, press Enter to skip): "
        read -r reference_image
        
        # Optional style description
        echo -n "🎭 Style/material description (optional, press Enter to skip): "
        read -r description
        
        # Generate the model
        generate_model "$prompt" "$description" "" "$reference_image"
        
        echo
        echo -e "${BLUE}Ready for next generation! (or 'quit' to exit)${NC}"
    done
}

# Generate 3D model from text
generate_model() {
    local prompt="$1"
    local description="$2"
    local output_dir="${3:-$DEFAULT_OUTPUT_DIR}"
    local reference_image="$4"
    
    print_status "🚀 Starting AI model generation..."
    print_status "📝 Prompt: '$prompt'"
    if [ -n "$description" ]; then
        print_status "🎭 Style: '$description'"
    fi
    if [ -n "$reference_image" ] && [ -f "$reference_image" ]; then
        print_status "📸 Reference: '$reference_image'"
    fi
    print_status "📁 Output: $output_dir"
    
    # Validate reference image if provided
    if [ -n "$reference_image" ] && [ ! -f "$reference_image" ]; then
        print_warning "Reference image not found: $reference_image"
        print_status "Continuing without reference image..."
        reference_image=""
    fi
    
    # Create output directory
    mkdir -p "$output_dir"
    
    # Build command
    local cmd="$BLENDER_EXECUTABLE --background --python \"$SMART_SCRIPT\" -- --prompt \"$prompt\" --output \"$output_dir\""
    
    if [ -n "$description" ]; then
        cmd="$cmd --description \"$description\""
    fi
    
    if [ -n "$reference_image" ] && [ -f "$reference_image" ]; then
        cmd="$cmd --reference \"$reference_image\""
    fi
    
    echo -e "${BLUE}🔄 Running Blender AI generation...${NC}"
    
    # Execute with progress indication
    if eval "$cmd" 2>&1 | while IFS= read -r line; do
        case "$line" in
            *"Generating"*|*"Analyzing"*)
                echo -e "${YELLOW}⚙️  $line${NC}"
                ;;
            *"Successfully"*)
                echo -e "${GREEN}✅ $line${NC}"
                ;;
            *"ERROR"*|*"Failed"*)
                echo -e "${RED}❌ $line${NC}"
                ;;
            *"Creating"*|*"Adding"*|*"Reference"*)
                echo -e "${BLUE}🔨 $line${NC}"
                ;;
            *)
                echo "$line"
                ;;
        esac
    done; then
        print_success "🎉 Generation completed successfully!"
        
        # Show results
        if [ -d "$output_dir" ]; then
            print_status "📋 Generated files:"
            ls -la "$output_dir" | grep -E '\.(blend|fbx|png)$' | while read -r line; do
                filename=$(echo "$line" | awk '{print $9}')
                size=$(echo "$line" | awk '{print $5}')
                echo -e "  ${GREEN}📄 $filename${NC} (${size} bytes)"
            done
        fi
        
        return 0
    else
        print_error "💥 Generation failed!"
        return 1
    fi
}

# Batch generation from file
batch_generate() {
    local input_file="$1"
    local output_dir="${2:-$DEFAULT_OUTPUT_DIR}"
    
    if [ ! -f "$input_file" ]; then
        print_error "Input file not found: $input_file"
        return 1
    fi
    
    print_status "📦 Starting batch generation from: $input_file"
    
    local count=0
    local success=0
    
    while IFS='|' read -r prompt description || [ -n "$prompt" ]; do
        # Skip empty lines and comments
        [[ -z "$prompt" || "$prompt" =~ ^#.*$ ]] && continue
        
        count=$((count + 1))
        echo
        print_status "🔄 Processing item $count: '$prompt'"
        
        if generate_model "$prompt" "$description" "$output_dir"; then
            success=$((success + 1))
        fi
        
    done < "$input_file"
    
    echo
    print_success "📊 Batch complete: $success/$count successful generations"
}

# Create example prompts file
create_examples_file() {
    local examples_file="$1"
    
    cat > "$examples_file" << 'EOF'
# Smart BlendAI Example Prompts
# Format: prompt|description (description is optional)
# Lines starting with # are comments

# Weapons
medieval sword|sharp steel with leather grip
battle axe with runes|ancient dwarven craftsmanship
magic staff|crystal tip with mystical glow
elven bow|curved wood with silver details

# Characters  
human warrior|armored knight with battle scars
goblin rogue|sneaky with dark leather armor
orc chieftain|massive with tribal decorations
elf mage|elegant robes with magical accessories

# Buildings
medieval castle|stone walls with weathered texture
wooden tavern|rustic wood with warm lighting
wizard tower|tall spire with magical elements
stone fortress|defensive walls with iron details

# Objects
treasure chest|ornate gold with gem inlays
ancient tree|gnarled bark with mystical aura
magic potion bottle|glowing liquid in glass vessel
stone altar|carved runes with mystical energy
EOF

    print_success "📝 Example prompts created: $examples_file"
}

# Show usage
show_usage() {
    echo "Usage: $0 [OPTIONS] [PROMPT]"
    echo
    echo "Generate 3D models from text descriptions using AI"
    echo
    echo "Options:"
    echo "  -h, --help              Show this help"
    echo "  -i, --interactive       Interactive generation mode"
    echo "  -b, --batch FILE        Batch generate from file"
    echo "  -o, --output DIR        Output directory"
    echo "  -d, --description TEXT  Style/material description"
    echo "  -r, --reference IMAGE   Reference image for accuracy"
    echo "  --examples              Show generation examples"
    echo "  --create-examples FILE  Create example prompts file"
    echo
    echo "Examples:"
    echo "  $0 'katana'                                    # Generate katana"
    echo "  $0 'medieval sword' -r sword_ref.jpg          # Use reference image"
    echo "  $0 'goblin warrior' -d 'dark armor' -r ref.png # With style & reference"
    echo "  $0 -i                                          # Interactive mode"
    echo "  $0 -b prompts.txt                              # Batch from file"
    echo "  $0 --examples                                  # Show what can be generated"
    echo
    echo "Reference Image Tips:"
    echo "  • Use clear, high-resolution images"
    echo "  • Side-view or 3/4 view works best"  
    echo "  • JPEG, PNG, TIFF formats supported"
    echo "  • Images help with proportions and style"
}

# Main function
main() {
    local interactive=false
    local batch_file=""
    local prompt=""
    local description=""
    local reference_image=""
    local output_dir="$DEFAULT_OUTPUT_DIR"
    
    # Parse arguments
    while [[ $# -gt 0 ]]; do
        case $1 in
            -h|--help)
                show_usage
                exit 0
                ;;
            -i|--interactive)
                interactive=true
                shift
                ;;
            -b|--batch)
                batch_file="$2"
                shift 2
                ;;
            -o|--output)
                output_dir="$2"
                shift 2
                ;;
            -d|--description)
                description="$2"
                shift 2
                ;;
            -r|--reference)
                reference_image="$2"
                shift 2
                ;;
            --examples)
                show_examples
                exit 0
                ;;
            --create-examples)
                create_examples_file "$2"
                exit 0
                ;;
            *)
                if [ -z "$prompt" ]; then
                    prompt="$1"
                fi
                shift
                ;;
        esac
    done
    
    # Check if smart script exists
    if [ ! -f "$SMART_SCRIPT" ]; then
        print_error "Smart BlendAI script not found: $SMART_SCRIPT"
        exit 1
    fi
    
    # Check Blender installation
    if ! command -v "$BLENDER_EXECUTABLE" >/dev/null 2>&1; then
        print_error "Blender not found. Please install Blender first."
        print_status "Try: sudo snap install blender --classic"
        exit 1
    fi
    
    # Handle different modes
    if [ "$interactive" = true ]; then
        interactive_mode
    elif [ -n "$batch_file" ]; then
        batch_generate "$batch_file" "$output_dir"
    elif [ -n "$prompt" ]; then
        generate_model "$prompt" "$description" "$output_dir" "$reference_image"
    else
        print_error "No prompt provided. Use -i for interactive mode or provide a prompt."
        echo
        show_usage
        exit 1
    fi
}

# Run main function
main "$@"