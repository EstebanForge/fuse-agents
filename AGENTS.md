# Project Overview

This is a cross-shell plugin (Bash & Zsh) that automatically fuses AI assistant configuration files (CLAUDE.md, GEMINI.md) into a unified AGENTS.md file with intelligent symlink management. The plugin provides automatic detection, smart merging, and different handling for different AI assistants.

## Key Architecture

### Shell Compatibility Layer
The plugin detects the current shell (Bash/Zsh/unknown) and adapts behavior:
- `SHELL_TYPE` variable determines shell-specific features
- `array_join()` function handles cross-shell array operations
- Different hook mechanisms: Zsh uses `chpwd`, Bash uses `PROMPT_COMMAND`

### Core Processing Pipeline
1. **Detection**: `_fuse_auto_detect()` triggers on directory changes
2. **Processing**: `_fuse-agents()` handles individual directories
3. **File Handling**: `_handle_ai_file()` manages individual AI assistant files
4. **Conflict Resolution**: Interactive prompts using `gum` (if available) or fallback text prompts

### Critical Design Decisions
- **CLAUDE.md**: Always symlinked to AGENTS.md (Claude requires symlink)
- **GEMINI.md**: Never symlinked (Gemini can read AGENTS.md directly)
- **Auto-detection**: Only triggers for CLAUDE.md, not GEMINI.md files
- **Merge Strategy**: Creates timestamped backups and structured merges
- **Conditional Symlinks**: Symlinks are only created for files that existed originally; if GEMINI.md doesn't exist, no symlink is created

## Common Development Tasks

### Testing Plugin Functionality

```bash
# Test basic fusing
mkdir -p /tmp/test-fuse
cd /tmp/test-fuse
echo "# Claude instructions" > CLAUDE.md
echo "# Gemini instructions" > GEMINI.md
source /path/to/fuse-agents.plugin.sh
fuse-agents-auto

# Test recursive processing
mkdir -p ~/test-projects/{proj1,proj2}
echo "# Claude proj1" > ~/test-projects/proj1/CLAUDE.md
echo "# Gemini proj2" > ~/test-projects/proj2/GEMINI.md
fuse-agents-recursive ~/test-projects
```

### Installation Testing

```bash
# Test installer script
./install.sh

# Verify installation
type fuse-agents
fuse-agents --help

# Test auto-hooks by changing directories
cd ~/project-with-CLAUDE.md
```

### Debugging Common Issues

```bash
# Check if plugin is loaded
type _fuse-agents
type _fuse_auto_detect

# Check shell detection
echo $SHELL_TYPE

# Test auto-detection manually
_fuse_auto_detect

# Disable auto-fusing
export FUSE_AGENTS_AUTO=false

# Clear infinite loop protection
unset _FUSE_AGENTS_RUNNING
```

## File Structure and Important Components

- **`fuse-agents.plugin.sh`**: Main plugin file with all functionality
- **`install.sh`**: Automated installer that detects shell and sets up plugin
- **`.gitignore`**: Excludes backup files (`*.backup.*`, `*.merged.*`) and test directories

### Key Functions
- `fuse-agents()`: Main command function with help text
- `fuse-agents-auto()`: Manual auto-detection trigger
- `fuse-agents-recursive()`: Batch processing of directories
- `_fuse-agents()`: Core fusing logic
- `_handle_ai_file()`: Individual file processing with conditional symlink creation
- `_fuse_auto_detect()`: Automatic detection on directory changes
- `_setup_shell_hooks()`: Configures shell-specific triggers

### Critical Variables
- `_FUSE_AGENTS_RUNNING`: Prevents recursive calls
- `FUSE_AGENTS_AUTO`: Set to 'false' to disable auto-fusing
- `SHELL_TYPE`: Detected shell (bash/zsh/unknown)
- Backup files use pattern: `FILENAME.backup.YYYYMMDD_HHMMSS`

## Shell Integration Points

### Zsh Integration
```bash
add-zsh-hook chpwd _fuse_auto_detect
```

### Bash Integration
```bash
PROMPT_COMMAND="$PROMPT_COMMAND; _fuse_auto_detect"
```

## Dependencies and Requirements

- **Required**: Bash 4.0+ or Zsh 5.0+, standard Unix tools (`find`, `ln`, `mv`, `cat`)
- **Optional**: `gum` for enhanced UI prompts
- **Shell Config**: Plugin must be sourced in shell configuration file

## Testing Behavior

When testing fusing, expect these behaviors:
- CLAUDE.md becomes a symlink pointing to AGENTS.md
- GEMINI.md is merged into AGENTS.md (no symlink created)
- If GEMINI.md doesn't exist, no symlink is created for it (GEMINI can read AGENTS.md directly)
- Original files are backed up with timestamps
- Merge structure includes clear section headers
- Auto-detection only triggers for CLAUDE.md files

## Development Notes

- The plugin uses cross-shell compatible syntax throughout
- All user-facing messages go through logging functions (`log_info`, `log_warn`, `log_error`)
- Interactive prompts have both `gum`-enhanced and fallback text versions
- Shell-specific features are conditionally enabled based on `SHELL_TYPE`
- Recursive processing uses `find` with null delimiters for safety
- The `_handle_ai_file()` function accepts a third parameter to control symlink creation
- Conditional symlink creation prevents unnecessary files from being created