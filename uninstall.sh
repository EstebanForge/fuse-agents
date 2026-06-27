#!/usr/bin/env bash

# fuse-agents plugin uninstaller.
# Reverses install.sh: removes the source block from the shell rc file and
# deletes the plugin directory. Safe to run even if install never happened.

set -euo pipefail

# Colors (mirrors install.sh / manage.sh)
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

log_info()    { echo -e "${BLUE}[INFO]${NC} $1"; }
log_success() { echo -e "${GREEN}[SUCCESS]${NC} $1"; }
log_warning() { echo -e "${YELLOW}[WARNING]${NC} $1"; }
log_error()   { echo -e "${RED}[ERROR]${NC} $1"; }

# Detect current shell the same way install.sh does.
if [[ -n "${ZSH_VERSION:-}" ]] || [[ "${SHELL:-}" == *"zsh"* ]]; then
    CONFIG_FILE="${HOME}/.zshrc"
    SHELL_PLUGINS_DIR="${HOME}/.zsh/plugins"
elif [[ -n "${BASH_VERSION:-}" ]] || [[ "${SHELL:-}" == *"bash"* ]]; then
    CONFIG_FILE="${HOME}/.bashrc"
    SHELL_PLUGINS_DIR="${HOME}/.bash/plugins"
else
    CONFIG_FILE="${HOME}/.profile"
    SHELL_PLUGINS_DIR="${HOME}/.local/plugins"
fi

PLUGIN_DIR="${SHELL_PLUGINS_DIR}/fuse-agents"
removed_anything=0

# 1. Remove the source block from the rc file.
#    The block install.sh writes is the '# Load Fuse Agents plugin' marker
#    plus the following if/source/fi lines. Strip exactly that region.
if [[ -f "${CONFIG_FILE}" ]] && grep -q "fuse-agents" "${CONFIG_FILE}"; then
    log_info "Removing fuse-agents block from ${CONFIG_FILE}"
    local_tmp="$(mktemp)"
    # awk: print every line, but toggle a skip flag around the '# Load Fuse Agents'
    # marker through the closing 'fi' that ends the source block.
    awk '
        /^# Load Fuse Agents plugin$/ { skip=1; next }
        skip && /^fi$/                { skip=0; next }
        skip                          { next }
        { print }
    ' "${CONFIG_FILE}" > "${local_tmp}"
    mv "${local_tmp}" "${CONFIG_FILE}"
    log_success "Removed source block from ${CONFIG_FILE}"
    removed_anything=1
else
    log_info "No fuse-agents reference found in ${CONFIG_FILE}"
fi

# 2. Remove the installed plugin directory.
if [[ -d "${PLUGIN_DIR}" ]]; then
    log_info "Removing plugin directory: ${PLUGIN_DIR}"
    rm -rf "${PLUGIN_DIR}"
    log_success "Removed ${PLUGIN_DIR}"
    removed_anything=1
else
    log_info "Plugin directory not present: ${PLUGIN_DIR}"
fi

# 3. Best-effort cleanup of empty plugins parent (do not remove ~/.zsh or ~/.bash).
parent="$(dirname "${PLUGIN_DIR}")"
if [[ -d "${parent}" && "$(ls -A "${parent}" 2>/dev/null)" == "" && "${parent}" != "${HOME}" ]]; then
    rmdir "${parent}" 2>/dev/null && log_info "Removed empty parent: ${parent}" || true
fi

if [[ "${removed_anything}" == "1" ]]; then
    log_success "fuse-agents uninstalled. Restart your shell to clear loaded functions."
else
    log_warning "Nothing to remove; fuse-agents was not installed."
fi
