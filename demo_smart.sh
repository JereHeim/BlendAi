#!/bin/bash

# BlendAI Smart Demo - Showcase AI Generation Capabilities
# This script demonstrates what Smart BlendAI can create

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m'

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DEMO_OUTPUT="$HOME/blendai_demo_output"

print_banner() {
    echo -e "${PURPLE}"
    echo "🎪====================================================🎪"
    echo "        Smart BlendAI Demo - AI 3D Generation"
    echo "   See what artificial intelligence can create!"
    echo "🎪====================================================🎪"
    echo -e "${NC}"
}

print_section() {
    echo
    echo -e "${CYAN}$1${NC}"
    echo -e "${CYAN}$(printf '%.0s=' {1..50})${NC}"
}

print_demo() {
    echo -e "${YELLOW}🎯 $1${NC}"
    echo -e "${BLUE}   Command: $2${NC}"
}

create_demo_prompts() {
    local prompts_file="$DEMO_OUTPUT/demo_prompts.txt"
    
    cat > "$prompts_file" << 'EOF'
# Smart BlendAI Demo Prompts
# This file contains examples of what AI can generate

# === WEAPONS COLLECTION ===
medieval sword|sharp steel with leather-wrapped handle
battle axe with runes|ancient dwarven weapon with mystical engravings
magic staff|crystal-tipped staff with arcane energy
elven bow|elegant curved bow with silver inlays
war hammer|heavy iron hammer with spiked head

# === CHARACTER COLLECTION ===
human warrior|armored knight with battle-worn gear
goblin rogue|sneaky goblin with dark leather armor
orc chieftain|massive orc leader with tribal decorations
elf mage|graceful elf in flowing magical robes
dwarf blacksmith|stocky dwarf with work apron and tools

# === BUILDING COLLECTION ===
medieval castle|stone fortress with defensive towers
wooden tavern|rustic inn with warm welcoming atmosphere
wizard tower|tall spire crackling with magical energy
stone bridge|ancient bridge over mystical waters
guard tower|watchtower with defensive battlements

# === OBJECT COLLECTION ===
treasure chest|ornate chest filled with golden coins
ancient tree|gnarled oak with mystical aura
magic potion bottle|glowing elixir in crystal vessel
stone altar|sacrificial altar with carved runes
crystal formation|cluster of magical crystals
EOF

    echo "$prompts_file"
}

run_demo() {
    print_banner
    
    echo -e "${GREEN}Welcome to the Smart BlendAI Demo!${NC}"
    echo "This demo will show you what AI can generate from simple text descriptions."
    echo
    echo -e "${YELLOW}📁 Demo output will be saved to: $DEMO_OUTPUT${NC}"
    mkdir -p "$DEMO_OUTPUT"
    
    # Create demo prompts file
    prompts_file=$(create_demo_prompts)
    echo -e "${GREEN}✅ Created demo prompts file: $prompts_file${NC}"
    
    print_section "🗡️  WEAPON GENERATION EXAMPLES"
    
    print_demo "Medieval Sword" "./smart_blendai.sh 'medieval sword' -d 'sharp steel blade'"
    print_demo "Magic Staff" "./smart_blendai.sh 'magic staff' -d 'crystal tip with mystical glow'"
    print_demo "Battle Axe" "./smart_blendai.sh 'battle axe with runes' -d 'dwarven craftsmanship'"
    
    print_section "👥 CHARACTER GENERATION EXAMPLES"
    
    print_demo "Human Warrior" "./smart_blendai.sh 'human warrior' -d 'plate armor and sword'"
    print_demo "Goblin Rogue" "./smart_blendai.sh 'goblin rogue' -d 'dark leather armor'"
    print_demo "Orc Chieftain" "./smart_blendai.sh 'orc chieftain' -d 'massive with tribal gear'"
    
    print_section "🏰 BUILDING GENERATION EXAMPLES"
    
    print_demo "Medieval Castle" "./smart_blendai.sh 'medieval castle' -d 'stone walls with towers'"
    print_demo "Wizard Tower" "./smart_blendai.sh 'wizard tower' -d 'tall spire with magic'"
    print_demo "Wooden Tavern" "./smart_blendai.sh 'wooden tavern' -d 'rustic inn atmosphere'"
    
    print_section "💎 OBJECT GENERATION EXAMPLES"
    
    print_demo "Treasure Chest" "./smart_blendai.sh 'treasure chest' -d 'ornate gold with gems'"
    print_demo "Magic Potion" "./smart_blendai.sh 'magic potion bottle' -d 'glowing liquid'"
    print_demo "Ancient Tree" "./smart_blendai.sh 'ancient tree' -d 'gnarled bark with moss'"
    
    echo
    echo -e "${PURPLE}🎮 INTERACTIVE DEMO OPTIONS:${NC}"
    echo
    echo "1. 🎯 Generate a single model"
    echo "2. 🎪 Run full weapon demo (5 models)"
    echo "3. 👥 Run character demo (3 models)"  
    echo "4. 🏰 Run building demo (3 models)"
    echo "5. 📦 Run complete demo (all categories)"
    echo "6. 🎨 Interactive generation mode"
    echo "7. 📝 View/edit demo prompts file"
    echo "8. 🚪 Exit demo"
    
    echo
    echo -n "Choose an option (1-8): "
    read -r choice
    
    case "$choice" in
        1)
            single_generation_demo
            ;;
        2)  
            weapons_demo
            ;;
        3)
            characters_demo
            ;;
        4)
            buildings_demo
            ;;
        5)
            complete_demo
            ;;
        6)
            interactive_demo
            ;;
        7)
            view_prompts "$prompts_file"
            ;;
        8)
            echo -e "${GREEN}Thanks for trying Smart BlendAI! 🎨${NC}"
            exit 0
            ;;
        *)
            echo -e "${RED}Invalid option. Please choose 1-8.${NC}"
            run_demo
            ;;
    esac
}

single_generation_demo() {
    echo
    echo -e "${BLUE}🎯 Single Model Generation Demo${NC}"
    echo -n "What would you like to generate? "
    read -r prompt
    
    if [ -n "$prompt" ]; then
        echo -n "Any style/material description? (optional): "
        read -r description
        
        echo -e "${YELLOW}🚀 Generating: '$prompt'${NC}"
        
        if [ -n "$description" ]; then
            ./smart_blendai.sh "$prompt" -d "$description" -o "$DEMO_OUTPUT"
        else
            ./smart_blendai.sh "$prompt" -o "$DEMO_OUTPUT"
        fi
    else
        echo -e "${RED}No prompt provided.${NC}"
    fi
    
    demo_continue
}

weapons_demo() {
    echo
    echo -e "${BLUE}⚔️  Running Weapons Demo...${NC}"
    
    local weapons=(
        "medieval sword|sharp steel blade"
        "battle axe with runes|dwarven craftsmanship"
        "magic staff|crystal tip with glow"
        "elven bow|silver and wood"
        "war hammer|heavy iron with spikes"
    )
    
    for weapon_data in "${weapons[@]}"; do
        IFS='|' read -r weapon description <<< "$weapon_data"
        echo -e "${YELLOW}🔨 Generating: $weapon${NC}"
        ./smart_blendai.sh "$weapon" -d "$description" -o "$DEMO_OUTPUT" || echo -e "${RED}Failed to generate $weapon${NC}"
    done
    
    echo -e "${GREEN}✅ Weapons demo complete!${NC}"
    demo_continue
}

characters_demo() {
    echo
    echo -e "${BLUE}👥 Running Characters Demo...${NC}"
    
    local characters=(
        "human warrior|plate armor with sword"
        "goblin rogue|dark leather armor"
        "orc chieftain|massive tribal leader"
    )
    
    for char_data in "${characters[@]}"; do
        IFS='|' read -r character description <<< "$char_data"
        echo -e "${YELLOW}👤 Generating: $character${NC}"
        ./smart_blendai.sh "$character" -d "$description" -o "$DEMO_OUTPUT" || echo -e "${RED}Failed to generate $character${NC}"
    done
    
    echo -e "${GREEN}✅ Characters demo complete!${NC}"
    demo_continue
}

buildings_demo() {
    echo
    echo -e "${BLUE}🏰 Running Buildings Demo...${NC}"
    
    local buildings=(
        "medieval castle|stone fortress with towers"
        "wizard tower|tall magical spire"
        "wooden tavern|rustic inn atmosphere"
    )
    
    for building_data in "${buildings[@]}"; do
        IFS='|' read -r building description <<< "$building_data"
        echo -e "${YELLOW}🏗️  Generating: $building${NC}"
        ./smart_blendai.sh "$building" -d "$description" -o "$DEMO_OUTPUT" || echo -e "${RED}Failed to generate $building${NC}"
    done
    
    echo -e "${GREEN}✅ Buildings demo complete!${NC}"
    demo_continue
}

complete_demo() {
    echo
    echo -e "${BLUE}📦 Running Complete Demo (This may take a while)...${NC}"
    
    prompts_file="$DEMO_OUTPUT/demo_prompts.txt"
    ./smart_blendai.sh -b "$prompts_file" -o "$DEMO_OUTPUT"
    
    echo -e "${GREEN}✅ Complete demo finished!${NC}"
    show_results
    demo_continue
}

interactive_demo() {
    echo
    echo -e "${BLUE}🎨 Starting Interactive Generation Mode...${NC}"
    ./smart_blendai.sh -i
    demo_continue
}

view_prompts() {
    local prompts_file="$1"
    echo
    echo -e "${BLUE}📝 Demo Prompts File:${NC}"
    echo -e "${CYAN}$prompts_file${NC}"
    echo
    cat "$prompts_file"
    echo
    echo -n "Press Enter to continue..."
    read -r
    run_demo
}

show_results() {
    echo
    echo -e "${GREEN}📋 Generated Files:${NC}"
    if [ -d "$DEMO_OUTPUT" ]; then
        find "$DEMO_OUTPUT" -name "*.blend" -o -name "*.fbx" -o -name "*.png" | sort | while read -r file; do
            basename_file=$(basename "$file")
            filesize=$(du -h "$file" | cut -f1)
            echo -e "  ${GREEN}📄 $basename_file${NC} ($filesize)"
        done
    else
        echo -e "${YELLOW}No output directory found.${NC}"
    fi
}

demo_continue() {
    echo
    show_results
    echo
    echo -n "Continue demo? (y/n): "
    read -r continue_choice
    
    case "$continue_choice" in
        y|Y|yes|YES)
            run_demo
            ;;
        *)
            echo -e "${GREEN}Thanks for trying Smart BlendAI! 🎨${NC}"
            echo -e "${BLUE}Your generated models are in: $DEMO_OUTPUT${NC}"
            exit 0
            ;;
    esac
}

# Check requirements
check_requirements() {
    if [ ! -f "$SCRIPT_DIR/smart_blendai.sh" ]; then
        echo -e "${RED}❌ smart_blendai.sh not found in $SCRIPT_DIR${NC}"
        echo -e "${YELLOW}Please make sure you're running this from the BlendAI directory.${NC}"
        exit 1
    fi
    
    if ! command -v blender >/dev/null 2>&1; then
        echo -e "${RED}❌ Blender not found. Please install Blender first.${NC}"
        echo -e "${YELLOW}Try: sudo snap install blender --classic${NC}"
        exit 1
    fi
    
    # Make smart_blendai.sh executable
    chmod +x "$SCRIPT_DIR/smart_blendai.sh"
}

# Main execution
main() {
    cd "$SCRIPT_DIR"
    check_requirements
    run_demo
}

main "$@"