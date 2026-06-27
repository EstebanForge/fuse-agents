#!/usr/bin/env bash

# Fuse Agents Plugin Installer
# Installs the fuse-agents plugin (Bash & Zsh compatible)

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

log_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

log_step() {
    echo -e "${BLUE}[STEP]${NC} $1"
}

# Get script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PLUGIN_FILE="$SCRIPT_DIR/fuse-agents.plugin.sh"

# Check if plugin file exists
if [[ ! -f "$PLUGIN_FILE" ]]; then
    log_error "Plugin file not found: $PLUGIN_FILE"
    exit 1
fi

# Detect current shell and determine directories
if [[ -n "${ZSH_VERSION:-}" ]] || [[ "$SHELL" == *"zsh"* ]]; then
    CURRENT_SHELL="zsh"
    CONFIG_FILE="$HOME/.zshrc"
    SHELL_PLUGINS_DIR="$HOME/.zsh/plugins"
elif [[ -n "${BASH_VERSION:-}" ]] || [[ "$SHELL" == *"bash"* ]]; then
    CURRENT_SHELL="bash"
    CONFIG_FILE="$HOME/.bashrc"
    SHELL_PLUGINS_DIR="$HOME/.bash/plugins"
else
    CURRENT_SHELL="unknown"
    CONFIG_FILE="$HOME/.profile"
    SHELL_PLUGINS_DIR="$HOME/.local/plugins"
    log_warn "Unknown shell detected, using ~/.local/plugins"
fi

log_info "Detected shell: $CURRENT_SHELL"
log_info "Plugins directory: $SHELL_PLUGINS_DIR"

# Create plugins directory if it doesn't exist
if [[ ! -d "$SHELL_PLUGINS_DIR" ]]; then
    log_step "Creating plugins directory: $SHELL_PLUGINS_DIR"
    mkdir -p "$SHELL_PLUGINS_DIR"
fi

# Create fuse-agents subdirectory
PLUGIN_DIR="$SHELL_PLUGINS_DIR/fuse-agents"
if [[ ! -d "$PLUGIN_DIR" ]]; then
    log_step "Creating plugin directory: $PLUGIN_DIR"
    mkdir -p "$PLUGIN_DIR"
fi

# Copy plugin file
log_step "Installing plugin to: $PLUGIN_DIR"
cp "$PLUGIN_FILE" "$PLUGIN_DIR/"

# Copy additional files
if [[ -f "$SCRIPT_DIR/README.md" ]]; then
    cp "$SCRIPT_DIR/README.md" "$PLUGIN_DIR/"
fi

if [[ -f "$SCRIPT_DIR/LICENSE" ]]; then
    cp "$SCRIPT_DIR/LICENSE" "$PLUGIN_DIR/"
fi

# Check if plugin is already sourced in shell config
if [[ -f "$CONFIG_FILE" ]]; then
    if grep -q "fuse-agents" "$CONFIG_FILE"; then
        log_warn "Plugin already referenced in $CONFIG_FILE"
    else
        log_step "Adding plugin to $CONFIG_FILE"

        # Add plugin loading code
        cat >> "$CONFIG_FILE" << EOF

# Load Fuse Agents plugin
if [[ -f $SHELL_PLUGINS_DIR/fuse-agents/fuse-agents.plugin.sh ]]; then
    source $SHELL_PLUGINS_DIR/fuse-agents/fuse-agents.plugin.sh
fi
EOF
        log_info "Added plugin loading to $CONFIG_FILE"
    fi
else
    # Fresh machines have no rc file yet. Create one so the plugin actually loads
    # after the first shell restart; never silently skip wiring the source line.
    log_step "Creating $CONFIG_FILE (did not exist)"
    touch "$CONFIG_FILE"
    cat >> "$CONFIG_FILE" << EOF

# Load Fuse Agents plugin
if [[ -f $SHELL_PLUGINS_DIR/fuse-agents/fuse-agents.plugin.sh ]]; then
    source $SHELL_PLUGINS_DIR/fuse-agents/fuse-agents.plugin.sh
fi
EOF
    log_info "Created $CONFIG_FILE and added plugin loading"
fi

# Check for gum (optional dependency)
if command -v gum >/dev/null 2>&1; then
    log_info "gum is installed for enhanced UI"
else
    log_warn "gum not found. Install for enhanced UI: brew install gum"
fi

log_info "Installation complete!"
echo ""
echo "Next steps:"
echo "1. Restart your terminal or run: source $CONFIG_FILE"
echo "2. Test with: fuse-agents --help (in a directory with AI files)"
echo ""
echo "The plugin will automatically detect and fuse CLAUDE.md and GEMINI.md files."
echo "Compatible with both Bash and Zsh shells."