# 🖥️ Quick Server Connection & Setup Guide

## 🎯 Three Easy Ways to Deploy BlendAI

### 🚀 Method 1: One-Command Deploy (Easiest)

**Step 1:** Connect to your server
```bash
ssh your_username@your_server_ip
```

**Step 2:** Run the auto-deploy script
```bash
curl -sSL https://raw.githubusercontent.com/JereHeim/BlendAi/main/deploy_server.sh | bash
```

**That's it!** The script will automatically:
- Install all dependencies
- Install Blender
- Clone your repository
- Set up everything
- Run tests

---

### 🔧 Method 2: Manual Git Clone

**Step 1:** Connect to your server
```bash
ssh your_username@your_server_ip
```

**Step 2:** Clone and setup
```bash
git clone https://github.com/JereHeim/BlendAi.git
cd BlendAi
chmod +x setup_ubuntu.sh
./setup_ubuntu.sh
```

**Step 3:** Test it works
```bash
source ~/.bashrc
smart-blendai --examples
```

---

### 📁 Method 3: File Transfer from Windows

**Step 1:** Transfer files using SCP/SFTP
```bash
# Using SCP (from Windows PowerShell)
scp -r "C:\Users\joree\BlendAI" username@server_ip:/home/username/

# Using SFTP
sftp username@server_ip
put -r "C:\Users\joree\BlendAI" /home/username/
quit
```

**Step 2:** Setup on server
```bash
ssh username@server_ip
cd BlendAI
chmod +x *.sh
./setup_ubuntu.sh
```

---

## 🎮 Testing Your Deployment

Once deployed, test with these commands:

```bash
# Source aliases
source ~/.bashrc

# Test basic functionality
smart-blendai --examples

# Generate a test model
smart-blendai "medieval sword"

# Try interactive mode
smart-blendai -i

# Run the demo
blendai-demo
```

## 📊 Success Indicators

You'll know it's working when:
- ✅ `blender --version` shows Blender installed
- ✅ `smart-blendai --examples` shows options
- ✅ Files appear in `~/blendai_output/` after generation
- ✅ No errors when running commands

## 🆘 Common Connection Issues

### Can't connect to server?
```bash
# Check if server is reachable
ping your_server_ip

# Try different SSH port
ssh -p 2222 username@server_ip

# Check SSH service on server
sudo systemctl status ssh
```

### Permission denied?
```bash
# Check SSH key permissions on Windows
icacls "C:\Users\yourusername\.ssh\id_rsa"

# Use password authentication if keys don't work
ssh -o PasswordAuthentication=yes username@server_ip
```

### Git clone fails?
```bash
# Check internet connection on server
ping github.com

# Use HTTPS instead of SSH
git clone https://github.com/JereHeim/BlendAi.git
```

## 🔑 Server Access Examples

Replace these with your actual server details:

```bash
# Example: DigitalOcean/AWS/VPS
ssh root@123.45.67.89
ssh ubuntu@123.45.67.89
ssh user@mydomain.com

# Example: Home server
ssh user@192.168.1.100
ssh user@homeserver.local

# Example: With specific SSH key
ssh -i ~/.ssh/my_server_key user@server_ip

# Example: With different port
ssh -p 2222 user@server_ip
```

## 🎯 Next Steps After Deployment

1. **Test Generation:**
   ```bash
   smart-blendai "katana" -o ~/test_output
   ```

2. **Upload Reference Images:**
   ```bash
   scp my_references/*.jpg user@server:~/blendai_references/
   ```

3. **Start Background Processing:**
   ```bash
   blendai-start
   blendai-status
   ```

4. **Monitor Activity:**
   ```bash
   blendai-logs
   ```

5. **Download Generated Models:**
   ```bash
   scp -r user@server:~/blendai_output/* ./my_generated_models/
   ```

Your BlendAI system will be ready for production use! 🚀