#!/bin/bash
#
# Install numpy into Blender's Python environment
# This script installs numpy for Blender's bundled Python
#

set -e

echo "========================================="
echo "Installing numpy for Blender Python"
echo "========================================="

# Get Blender's Python path
BLENDER_PYTHON=$(blender --background --python-expr "import sys; print(sys.executable)" 2>/dev/null | grep -E '^/' | head -1)

if [ -z "$BLENDER_PYTHON" ]; then
    echo "❌ Error: Could not find Blender's Python executable"
    exit 1
fi

echo "✓ Found Blender Python at: $BLENDER_PYTHON"

# Get the pip module path (Blender might have pip as a module)
echo "Installing numpy..."

# Try using Blender's Python with -m pip
if "$BLENDER_PYTHON" -m pip --version &>/dev/null; then
    echo "Using pip module..."
    "$BLENDER_PYTHON" -m pip install --upgrade pip --break-system-packages
    "$BLENDER_PYTHON" -m pip install numpy --break-system-packages
else
    # Try installing pip first
    echo "Installing pip first..."
    curl -sS https://bootstrap.pypa.io/get-pip.py | "$BLENDER_PYTHON"
    "$BLENDER_PYTHON" -m pip install numpy --break-system-packages
fi

echo ""
echo "========================================="
echo "✅ Numpy installed successfully!"
echo "========================================="
echo ""
echo "Verifying installation..."
blender --background --python-expr "import numpy; print(f'numpy version: {numpy.__version__}')" 2>/dev/null | grep -E 'numpy version'

echo ""
echo "You can now use BlendAI with FBX export support!"
