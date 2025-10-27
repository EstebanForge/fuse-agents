# Consolidate Agents Plugin

A cross-shell plugin (Bash & Zsh) that automatically consolidates AI assistant configuration files (CLAUDE.md, GEMINI.md) into a unified AGENTS.md file with intelligent symlink management.

## Features

- 🔍 **Auto-detection**: Detects CLAUDE.md and GEMINI.md files when you `cd` into directories
- 🔄 **Auto-consolidation**: Automatically merges files using merge strategy (no prompts)
- 🔗 **Intelligent Symlink Management**: Creates CLAUDE.md → AGENTS.md symlinks; GEMINI.md is merged/renamed since it can read AGENTS.md directly; no GEMINI.md symlink is created if the file doesn't exist
- 📦 **Smart Merging**: Combines content from multiple AI assistant files
- 🎯 **Zero Configuration**: Works out of the box, no setup required

## Installation

### Option 1: Clone to Shell Plugins (Recommended)

```bash
# For Zsh users:
git clone https://github.com/EstebanForge/consolidate-agents.git ~/.zsh/plugins/consolidate-agents
echo 'source ~/.zsh/plugins/consolidate-agents/consolidate-agents.plugin.sh' >> ~/.zshrc
source ~/.zshrc

# For Bash users:
git clone https://github.com/EstebanForge/consolidate-agents.git ~/.bash/plugins/consolidate-agents
echo 'source ~/.bash/plugins/consolidate-agents/consolidate-agents.plugin.sh' >> ~/.bashrc
source ~/.bashrc
```

### Option 2: Manual Installation

```bash
# For Zsh users:
mkdir -p ~/.zsh/plugins/consolidate-agents
curl -o ~/.zsh/plugins/consolidate-agents/consolidate-agents.plugin.sh \
  https://raw.githubusercontent.com/EstebanForge/consolidate-agents/main/consolidate-agents.plugin.sh
echo 'source ~/.zsh/plugins/consolidate-agents/consolidate-agents.plugin.sh' >> ~/.zshrc
source ~/.zshrc

# For Bash users:
mkdir -p ~/.bash/plugins/consolidate-agents
curl -o ~/.bash/plugins/consolidate-agents/consolidate-agents.plugin.sh \
  https://raw.githubusercontent.com/EstebanForge/consolidate-agents/main/consolidate-agents.plugin.sh
echo 'source ~/.bash/plugins/consolidate-agents/consolidate-agents.plugin.sh' >> ~/.bashrc
source ~/.bashrc
```

### Option 3: Quick Install Script

```bash
# Run the installer
curl -fsSL https://raw.githubusercontent.com/EstebanForge/consolidate-agents/main/install.sh | bash
```

## Updating

To update the plugin to the latest version:

### Option 1: Git Repository Update

```bash
# Navigate to your plugin directory
cd ~/.zsh/plugins/consolidate-agents  # or ~/.bash/plugins/consolidate-agents

# Pull latest changes
git pull

# Re-run the installer (safe for updates)
./install.sh

# Restart your terminal or source config
source ~/.zshrc  # or source ~/.bashrc
```

### Option 2: Fresh Installation

```bash
# Simply re-run the installer
curl -fsSL https://raw.githubusercontent.com/EstebanForge/consolidate-agents/main/install.sh | bash

# Restart your terminal
```

**Note**: The installer is update-safe and will:
- Overwrite the old plugin files with new versions
- Preserve your existing shell configuration
- Not create duplicate sourcing lines in your config files

## Usage

### Automatic (Default Behavior)

The plugin works automatically when you change directories:

```bash
cd ~/project-with-claude-md
# 🔍 Detected CLAUDE.md (regular file(s))
# 🔄 Auto-consolidating using merge strategy...
# ✅ Created CLAUDE.md -> AGENTS.md symlink
# ✅ Processed 1 AI assistant file(s)
```

### Manual Commands

```bash
# Consolidate current directory
consolidate-agents

# Consolidate specific directories
consolidate-agents ~/project1 ~/project2

# Auto-detect and consolidate current directory
consolidate-agents-auto

# Recursively consolidate all directories with AI files
consolidate-agents-recursive ~/dev-projects
```

## How It Works

1. **Detection**: When you `cd` into a directory, the plugin checks for:
   - `CLAUDE.md` (regular file, not symlink)
   - `GEMINI.md` (regular file, not symlink, only if AGENTS.md doesn't exist)

2. **Consolidation**: If files are detected:
   - Creates merged `AGENTS.md` with content from all AI files
   - Backs up original files with timestamps
   - Creates symlinks: `CLAUDE.md → AGENTS.md`
   - `GEMINI.md` is renamed to `AGENTS.md` or merged (no symlink) since GEMINI can read AGENTS.md directly
   - If `GEMINI.md` doesn't exist, no symlink is created for it (GEMINI can read `AGENTS.md` directly)

3. **Merge Strategy**: The merged file structure:
   ```markdown
   # Merged from GEMINI.md and AGENTS.md - 2025-10-21
   
   ## From AGENTS.md:
   [original AGENTS.md content]
   
   ## From GEMINI.md:
   [original GEMINI.md content]
   ```

## File Structure Example

**Before:**
```
project/
├── GEMINI.md          # AI instructions for Gemini
├── CLAUDE.md          # AI instructions for Claude
└── AGENTS.md          # Existing agent instructions
```

**After:**
```
project/
├── AGENTS.md          # Merged content from all files
├── CLAUDE.md → AGENTS.md  # Symlink (Claude needs symlink)
├── CLAUDE.md.backup.20251021_143022  # Original backup
└── GEMINI.md.backup.20251021_143022  # Original backup (if GEMINI.md existed)
```

*Note: `GEMINI.md` is not symlinked since GEMINI can read `AGENTS.md` directly. If `GEMINI.md` doesn't exist in the original directory, no symlink will be created.*

## Configuration

While the plugin works automatically, you can configure behavior:

```bash
# Disable auto-consolidation (manual only)
unset CONSOLIDATE_AGENTS_AUTO

# The plugin uses these files:
# - CLAUDE.md
# - GEMINI.md  
# - AGENTS.md (target)
```

## Requirements

- **Bash (4.0+)** or **Zsh (5.0+)**
- `gum` (optional, for enhanced UI in manual mode)
- Standard Unix tools: `find`, `ln`, `mv`, `cat`

## Dependencies

### Optional: Gum for Enhanced UI

Install `gum` for better visual prompts in manual mode:

```bash
# macOS
brew install gum

# Other platforms
# See: https://github.com/charmbracelet/gum
```

If `gum` is not available, the plugin falls back to basic terminal prompts.

## Troubleshooting

### Plugin Not Loading

1. Ensure the plugin file is sourced in `~/.zshrc`
2. Check file permissions: `chmod 644 consolidate-agents.plugin.zsh`
3. Restart your terminal or run `source ~/.zshrc`

### Infinite Loop

If you encounter an infinite loop (rare):
1. Press `Ctrl+C` to break
2. Run: `unset _CONSOLIDATE_AGENTS_RUNNING`
3. Start a new terminal session

### Files Not Being Detected

1. Ensure files are regular files (not symlinks): `ls -la CLAUDE.md GEMINI.md`
2. Check you're in an interactive Zsh session: `echo $- | grep i`
3. Verify the plugin is loaded: `type _consolidate-agents`

## License

MIT License - see [LICENSE](LICENSE) file for details.

## Support

- 🐛 Report issues: [GitHub Issues](https://github.com/EstebanForge/consolidate-agents/issues)
- 💬 Discussions: [GitHub Discussions](https://github.com/EstebanForge/consolidate-agents/discussions)

---

**Made with ❤️ for developers. And with 💩 for A. for not adopting standards **