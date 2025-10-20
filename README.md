# BlendAI Ubuntu Server Automation

🤖 **AI-Powered 3D Model Generation and Processing for Ubuntu Server**

BlendAI is now **SMART** - it can generate 3D models from text descriptions AND use reference images for accuracy! Create swords, humans, goblins, castles and more using natural language with photo references.

## 🧠 Smart AI Capabilities

**✨ Generate from Text + Reference Photos:**
- `"katana" + katana_photo.jpg` → Creates accurate curved Japanese sword
- `"medieval sword" + sword_reference.png` → European longsword with proper proportions  
- `"dagger" + dagger_image.jpg` → Short blade matching reference style
- `"greatsword" + greatsword_ref.png` → Large two-handed sword with correct scale

**🎨 Smart Reference Analysis:**
- Analyzes reference images for proportions and style
- Extracts weapon types (katana, dagger, greatsword, etc.)
- Adjusts blade length, handle size, and guard proportions
- Applies style-specific modifications (curves, edges, details)

**📸 Supported Reference Types:**
- **Weapons:** Swords, axes, bows, staffs, daggers, katanas, greatswords
- **Characters:** Humans, goblins, orcs, elves, creatures with pose references
- **Buildings:** Castles, towers, houses, fortresses with architectural photos
- **Objects:** Any object with clear reference images

**🎯 What It Can Create:**
- **Weapons:** Katanas, daggers, greatswords, battle axes, magic staffs
- **Characters:** Humans, goblins, orcs, elves, creatures
- **Buildings:** Castles, towers, houses, fortresses  
- **Objects:** Trees, chests, bottles, furniture

## 🚀 Quick Start

### 1. One-Command Setup
```bash
curl -sSL https://raw.githubusercontent.com/your-repo/BlendAI/main/setup_ubuntu.sh | bash
```

Or download and run manually:
```bash
wget https://github.com/your-repo/BlendAI/archive/main.zip
unzip main.zip
cd BlendAI-main
chmod +x setup_ubuntu.sh
./setup_ubuntu.sh
```

### 2. Smart AI Generation
```bash
# Interactive mode - describe what you want + add reference photos!
./smart_blendai.sh -i

# Generate with reference images
./smart_blendai.sh "katana" -r katana_reference.jpg
./smart_blendai.sh "medieval sword" -r sword_photo.png -d "steel with leather grip"
./smart_blendai.sh "dagger" -r dagger_ref.jpg -o /my/output/dir

# Generate without reference (procedural only)
./smart_blendai.sh "goblin warrior" -d "dark armor and weapons"
./smart_blendai.sh "castle with towers"

# Batch generation with references
./smart_blendai.sh -b my_prompts_with_refs.txt

# See examples of what you can create
./smart_blendai.sh --examples
```

### 3. Traditional Processing (with existing models)
After setup, restart your terminal or run:
```bash
source ~/.bashrc
```

Then process your files:
```bash
# Copy files to the directories
cp your_model.fbx ~/blendai_models/
cp your_reference.png ~/blendai_references/

# Process manually
blendai your_model.fbx your_reference.png

# Or with full paths
blendai /path/to/model.fbx /path/to/reference.png /custom/output/dir
```

## 📁 Directory Structure

After setup, you'll have:
```
~/blendai/                 # Main scripts and config
~/blendai_models/          # Place your .fbx files here
~/blendai_references/      # Place your reference images here
~/blendai_output/          # Processed results appear here
~/blendai_logs/           # Log files
```

## 🔧 Available Commands

### Smart AI Generation
| Command | Description |
|---------|-------------|
| `smart_blendai.sh -i` | Interactive AI generation mode |
| `smart_blendai.sh "prompt"` | Generate model from text |
| `smart_blendai.sh -b file.txt` | Batch generate from prompts file |
| `smart_blendai.sh --examples` | Show generation examples |

### Traditional Processing  
| Command | Description |
|---------|-------------|
| `blendai model.fbx ref.png` | Process existing files |
| `blendai-status` | Check service status |
| `blendai-logs` | View real-time logs |
| `blendai-start` | Start automatic processing |
| `blendai-stop` | Stop automatic processing |
| `blendai-restart` | Restart the service |

## ⚙️ Configuration

Edit `~/blendai/blendai.conf` to customize:

```bash
# Default paths
DEFAULT_MODEL_PATH="/home/ubuntu/blendai_models"
DEFAULT_REFERENCE_PATH="/home/ubuntu/blendai_references"  
DEFAULT_OUTPUT_PATH="/home/ubuntu/blendai_output"

# Processing options
AUTO_SAVE_BLEND=true
AUTO_EXPORT_FBX=true
AUTO_RENDER_PREVIEW=true

# File watching (automatic processing)
WATCH_ENABLED=false
WATCH_MODEL_EXTENSIONS="fbx,obj,dae"
WATCH_REFERENCE_EXTENSIONS="png,jpg,jpeg"
```

## 🤖 Automatic Processing

Enable automatic processing when files are added:

```bash
# Start the watcher service
sudo systemctl start blendai.service

# Enable auto-start on boot
sudo systemctl enable blendai.service

# Check status
blendai-status
```

When enabled, the system will automatically process new `.fbx` files when matching reference images are found.

## 🎯 Smart Generation Examples

### Using Reference Images for Accurate Weapons
```bash
# Katana with reference photo
./smart_blendai.sh "katana" -r my_katana_reference.jpg
🤖 Generate: katana
📸 Reference image path: my_katana_reference.jpg
🎭 Style: curved blade with long handle
✅ Analyzing reference image for proportions...
✅ Creating reference-guided sword: curved
✅ Generation completed successfully!

# Dagger with reference and style
./smart_blendai.sh "dagger" -r dagger_photo.png -d "ornate silver blade"

# Greatsword with reference
./smart_blendai.sh "greatsword" -r greatsword_ref.jpg -d "massive two-handed weapon"
```

### Interactive Mode with References
```bash
./smart_blendai.sh -i

🤖 Generate: medieval sword
📸 Reference image path: /home/user/sword_reference.jpg
🎭 Style/material description: steel with leather wrapping
✅ Generating...
✅ Generation completed successfully!
```

### Batch Generation with References
Create a `weapon_prompts.txt` file:
```
# Format: prompt|description|reference_image_path
katana|curved Japanese blade|/refs/katana1.jpg
dagger|short stabbing weapon|/refs/dagger1.png  
greatsword|large two-handed sword|/refs/greatsword1.jpg
battle axe|heavy chopping weapon|/refs/axe1.jpg
```

Then run: `./smart_blendai.sh -b weapon_prompts.txt`

## 📊 Output Files

Each processing run creates:
- `smart_*.blend` - Blender project file with generated model
- `generated_*.fbx` - AI-generated FBX export  
- `smart_*_preview.png` - Rendered preview image
- Processing logs and material data

For traditional processing:
- `*.blend` - Blender project file
- `*_Export.fbx` - Processed FBX export
- `*_Preview.png` - Rendered preview image
- Processing logs

## 🧠 How Smart Generation Works

1. **Text Analysis:** Analyzes your prompt for keywords (sword, human, castle, etc.)
2. **Procedural Modeling:** Creates 3D geometry using Blender's procedural tools
3. **Smart Materials:** Applies appropriate materials based on object type
4. **Intelligent Positioning:** Positions cameras and lighting automatically  
5. **Export Pipeline:** Saves in multiple formats for game engines

### Generation Methods
- **Procedural Generation:** Creates geometry using mathematical algorithms
- **Template-based:** Uses base templates modified by parameters
- **Keyword Analysis:** Understands context from natural language
- **Material Intelligence:** Applies realistic materials automatically

## 🔍 Advanced Usage

### Manual Processing Options
```bash
# Skip saving .blend file
blendai --no-save model.fbx reference.png

# Skip FBX export
blendai --no-export model.fbx reference.png

# Skip preview render
blendai --no-render model.fbx reference.png

# Custom output directory
blendai model.fbx reference.png /custom/output/path
```

### System Administration
```bash
# Check system requirements
blendai --check

# Install Blender manually
blendai --install

# Setup automatic file watching
blendai --setup-auto /watch/models /watch/refs
```

### Service Management
```bash
# View detailed logs
sudo journalctl -u blendai.service -f

# Check service configuration
sudo systemctl cat blendai.service

# Restart with new configuration
sudo systemctl daemon-reload
sudo systemctl restart blendai.service
```

## 🛠️ Troubleshooting

### Common Issues

**Blender not found:**
```bash
# Install manually
sudo snap install blender --classic
# OR
sudo apt install blender
```

**Permission errors:**
```bash
# Fix ownership
sudo chown -R $USER:$USER ~/blendai*
chmod +x ~/blendai/run_blendai.sh
```

**Service won't start:**
```bash
# Check logs
sudo journalctl -u blendai.service -n 50

# Check configuration
sudo systemctl status blendai.service

# Restart service
sudo systemctl restart blendai.service
```

**Missing files:**
```bash
# Re-run setup
./setup_ubuntu.sh

# Or copy files manually
cp BlendAI_Ubuntu.py ~/blendai/
cp run_blendai.sh ~/blendai/
chmod +x ~/blendai/run_blendai.sh
```

### Log Locations
- Application logs: `~/blendai_logs/`
- System logs: `sudo journalctl -u blendai.service`
- Blender logs: `/tmp/blendai.log`

## 📋 System Requirements

- Ubuntu 18.04 LTS or newer
- Python 3.6+
- 4GB+ RAM (8GB recommended)
- 2GB+ disk space
- Blender 2.8+ (automatically installed)

## 🔒 Security Notes

- Script runs as non-root user
- Files processed in user directory
- No external network access required after setup
- Service runs with minimal privileges

## 🎯 What It Does

1. **Validates** input files (.fbx models and reference images)
2. **Imports** FBX models into Blender
3. **Positions** reference images automatically
4. **Applies** advanced procedural materials (rust/metal effects)
5. **Exports** processed FBX files
6. **Renders** preview images
7. **Saves** complete Blender projects
8. **Logs** all operations for debugging

## 🔄 Updating

To update BlendAI:
```bash
cd ~/blendai
wget https://raw.githubusercontent.com/your-repo/BlendAI/main/BlendAI_Ubuntu.py
wget https://raw.githubusercontent.com/your-repo/BlendAI/main/run_blendai.sh
chmod +x run_blendai.sh
sudo systemctl restart blendai.service
```

## 🆘 Support

For issues or questions:
1. Check the logs: `blendai-logs`
2. Verify status: `blendai-status`  
3. Test manually: `blendai --check`
4. Re-run setup if needed: `./setup_ubuntu.sh`

## 📝 License

This project is licensed under the MIT License - see the LICENSE file for details.