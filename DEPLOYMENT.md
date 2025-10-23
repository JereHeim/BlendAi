# 🚀 BlendAI Server Deployment Guide

Complete step-by-step guide to deploy Smart BlendAI on your Ubuntu server.

## 📋 Prerequisites

### Server Requirements
- **OS:** Ubuntu 18.04 LTS or newer
- **RAM:** 4GB minimum (8GB+ recommended)
- **Storage:** 10GB+ free space
- **CPU:** Multi-core recommended for faster processing
- **Network:** Internet connection for initial setup

### What You'll Need
- SSH access to your server
- Git installed on server
- Your GitHub repository URL

## 🔄 Method 1: Direct Git Clone (Recommended)

### Step 1: Connect to Your Server
```bash
# From your local machine, connect to server
ssh your_username@your_server_ip

# Example:
ssh ubuntu@192.168.1.100
# or
ssh user@mydomain.com
```

### Step 2: Clone and Setup
```bash
# Clone your repository
git clone https://github.com/JereHeim/BlendAi.git
cd BlendAi

# Make setup script executable
chmod +x setup_ubuntu.sh

# Run the automated setup (this installs everything)
./setup_ubuntu.sh
```

### Step 3: Verify Installation
```bash
# Source the new aliases
source ~/.bashrc

# Test the installation
blendai --check
smart-blendai --examples

# Check if Blender is installed
blender --version
```

## 📦 Method 2: Manual File Transfer

### Step 1: Transfer Files to Server
```bash
# From your local machine (Windows)
# Option A: Using SCP
scp -r "C:\Users\joree\BlendAI" username@server_ip:/home/username/

# Option B: Using SFTP
sftp username@server_ip
put -r "C:\Users\joree\BlendAI" /home/username/
quit

# Option C: Using rsync (if available)
rsync -avz "C:\Users\joree\BlendAI/" username@server_ip:/home/username/BlendAI/
```

### Step 2: Setup on Server
```bash
# SSH into your server
ssh username@server_ip

# Navigate to the uploaded directory
cd BlendAI

# Make scripts executable
chmod +x *.sh

# Run setup
./setup_ubuntu.sh
```

## 🛠️ Method 3: Step-by-Step Manual Setup

If you prefer to set up manually:

### Step 1: Prepare Server
```bash
# Update system
sudo apt update && sudo apt upgrade -y

# Install dependencies
sudo apt install -y python3 python3-pip wget curl git unzip \
    software-properties-common apt-transport-https ca-certificates \
    gnupg lsb-release inotify-tools imagemagick ffmpeg

# Install Blender
sudo snap install blender --classic
```

### Step 2: Setup BlendAI
```bash
# Create directories
mkdir -p ~/blendai ~/blendai_models ~/blendai_references ~/blendai_output

# Upload your files to ~/blendai/
# Then make scripts executable
cd ~/blendai
chmod +x *.sh

# Create aliases
echo '
# BlendAI aliases
alias blendai="$HOME/blendai/run_blendai.sh"
alias smart-blendai="$HOME/blendai/smart_blendai.sh"
alias blendai-demo="$HOME/blendai/demo_smart.sh"
alias blendai-status="sudo systemctl status blendai.service"
alias blendai-logs="sudo journalctl -u blendai.service -f"
alias blendai-start="sudo systemctl start blendai.service"
alias blendai-stop="sudo systemctl stop blendai.service"
alias blendai-restart="sudo systemctl restart blendai.service"
' >> ~/.bashrc

source ~/.bashrc
```

## 🎯 Getting It to Work

### Step 1: Test Basic Generation
```bash
# Test AI generation
smart-blendai "medieval sword" -o ~/test_output

# Test with reference image (upload a sword image first)
smart-blendai "katana" -r ~/sword_reference.jpg -o ~/test_output

# Try interactive mode
smart-blendai -i
```

### Step 2: Setup Automatic Processing (Optional)
```bash
# Create systemd service for background processing
sudo systemctl enable blendai.service
sudo systemctl start blendai.service

# Check if it's running
blendai-status
```

### Step 3: Test File Watching
```bash
# Copy test files to watch directories
cp your_model.fbx ~/blendai_models/
cp your_reference.png ~/blendai_references/

# The system should automatically process them
# Check logs to see activity
blendai-logs
```

## 🔍 Troubleshooting Common Issues

### Issue 1: Blender Not Found
```bash
# Check if Blender is installed
which blender

# If not found, install manually
sudo snap install blender --classic
# OR
sudo apt install blender

# Add to PATH if needed
echo 'export PATH="/snap/bin:$PATH"' >> ~/.bashrc
source ~/.bashrc
```

### Issue 2: Permission Errors
```bash
# Fix ownership of BlendAI files
sudo chown -R $USER:$USER ~/blendai*

# Make scripts executable
chmod +x ~/blendai/*.sh

# Fix log directory permissions
sudo mkdir -p /tmp/blendai_logs
sudo chown $USER:$USER /tmp/blendai_logs
```

### Issue 3: Python Dependencies
```bash
# Install Python packages if needed
pip3 install pillow requests

# Check Python version
python3 --version
```

### Issue 4: Service Won't Start
```bash
# Check service status
sudo systemctl status blendai.service

# View detailed logs
sudo journalctl -u blendai.service -n 50

# Restart service
sudo systemctl daemon-reload
sudo systemctl restart blendai.service
```

## 📊 Verification Commands

Run these to verify everything is working:

```bash
# Check all components
echo "=== System Check ==="
blender --version
python3 --version
which git

echo "=== BlendAI Check ==="
ls -la ~/blendai/
smart-blendai --examples

echo "=== Service Check ==="
blendai-status

echo "=== Directory Check ==="
ls -la ~/blendai_*

echo "=== Test Generation ==="
smart-blendai "test cube" -o ~/verification_test
ls -la ~/verification_test/
```

## 🎮 Usage Examples on Server

### Basic AI Generation
```bash
# Generate a katana with reference
smart-blendai "katana" -r ~/my_katana_ref.jpg

# Generate multiple weapons
smart-blendai -i
# Then enter: dagger, greatsword, battle axe, etc.

# Batch processing
echo "katana|curved Japanese sword
dagger|short blade
greatsword|large two-handed sword" > ~/weapon_batch.txt

smart-blendai -b ~/weapon_batch.txt
```

### Server Management
```bash
# Start background processing
blendai-start

# Monitor activity
blendai-logs

# Check what's running
blendai-status

# Stop processing
blendai-stop
```

### File Management
```bash
# Upload reference images
scp my_references/*.jpg username@server:/home/username/blendai_references/

# Download generated models
scp -r username@server:/home/username/blendai_output/* ./downloaded_models/

# Clean up old files
rm -rf ~/blendai_output/old_*
```

## 🔒 Security Considerations

### Firewall Setup (if needed)
```bash
# Allow SSH
sudo ufw allow ssh

# Allow custom ports if you expose BlendAI web interface (future feature)
# sudo ufw allow 8080

# Enable firewall
sudo ufw enable
```

### User Permissions
```bash
# Create dedicated user for BlendAI (optional)
sudo useradd -m -s /bin/bash blendai_user
sudo usermod -aG sudo blendai_user

# Switch to BlendAI user
sudo su - blendai_user
```

## 📈 Performance Optimization

### For Better Performance
```bash
# Increase Blender memory limit in scripts
export BLENDER_USER_CONFIG=/tmp/blender_config

# Use faster storage for output
mkdir -p /tmp/fast_output
smart-blendai "sword" -o /tmp/fast_output

# Monitor resource usage
htop
# or
top
```

### Batch Processing Tips
```bash
# Process multiple models efficiently
smart-blendai -b large_batch.txt -o /fast/storage/output

# Use background processing for large jobs
nohup smart-blendai -b huge_batch.txt > processing.log 2>&1 &
```

## 🎯 Success Indicators

You'll know it's working when:
- ✅ `blender --version` shows Blender is installed
- ✅ `smart-blendai --examples` shows available options
- ✅ `smart-blendai "test"` generates a 3D model
- ✅ Files appear in `~/blendai_output/`
- ✅ `blendai-status` shows service is active
- ✅ You can generate models with reference images

## 🆘 Getting Help

If you encounter issues:
1. Check logs: `blendai-logs`
2. Verify installation: Run verification commands above
3. Test manually: `smart-blendai "simple cube"`
4. Check permissions: `ls -la ~/blendai/`
5. Restart services: `blendai-restart`

Your BlendAI system should now be fully operational on your server! 🚀