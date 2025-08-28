#!/bin/bash

# Installation script for CLI Assistant
# This script sets up the configuration directory and copies files

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_DIR="$HOME/.cli-assistant"

echo "🚀 Installing CLI Assistant..."

# Check if jq is installed
if ! command -v jq &> /dev/null; then
    echo "❌ Error: jq is required but not installed."
    echo "Please install jq first:"
    echo "  Ubuntu/Debian: sudo apt install jq"
    echo "  macOS: brew install jq"
    echo "  CentOS/RHEL: sudo yum install jq"
    exit 1
fi

# Create config directory
echo "📁 Creating config directory: $CONFIG_DIR"
mkdir -p "$CONFIG_DIR"

# Copy the main script
echo "📋 Copying script files..."
cp "$SCRIPT_DIR/cli-assistant.sh" "$CONFIG_DIR/"
chmod +x "$CONFIG_DIR/cli-assistant.sh"

# Copy example config if config doesn't exist
if [[ ! -f "$CONFIG_DIR/config.json" ]]; then
    echo "⚙️  Creating example configuration..."
    cp "$SCRIPT_DIR/config.example.json" "$CONFIG_DIR/config.json"
    echo "📝 Please edit $CONFIG_DIR/config.json with your actual API keys"
else
    echo "⚠️  Configuration file already exists at $CONFIG_DIR/config.json"
    echo "   Keeping existing configuration."
fi

# Add to shell configuration
SHELL_CONFIG=""
if [[ -f "$HOME/.bashrc" ]]; then
    SHELL_CONFIG="$HOME/.bashrc"
elif [[ -f "$HOME/.zshrc" ]]; then
    SHELL_CONFIG="$HOME/.zshrc"
fi

if [[ -n "$SHELL_CONFIG" ]]; then
    # Check if already added
    if ! grep -q "cli-assistant.sh" "$SHELL_CONFIG"; then
        echo "🔧 Adding to shell configuration ($SHELL_CONFIG)..."
        echo "" >> "$SHELL_CONFIG"
        echo "# CLI Assistant" >> "$SHELL_CONFIG"
        echo "source $CONFIG_DIR/cli-assistant.sh" >> "$SHELL_CONFIG"
        echo "✅ Added to $SHELL_CONFIG"
    else
        echo "⚠️  Already added to $SHELL_CONFIG"
    fi
fi

echo ""
echo "✅ Installation complete!"
echo ""
echo "Next steps:"
echo "1. Edit your configuration: $CONFIG_DIR/config.json"
echo "2. Add your actual API keys to replace the placeholder values"
echo "3. Reload your shell: source $SHELL_CONFIG"
echo "4. Test with: clia \"hello world\""
echo ""
echo "For more information, see README.md"
