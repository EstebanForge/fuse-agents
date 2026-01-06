#!/usr/bin/env bash

# Fuse Agents Plugin
# Compatible with both Bash and Zsh
# Automatically fuses AI assistant files (CLAUDE.md, GEMINI.md) into AGENTS.md

# =============================================================================
# SHELL DETECTION AND SETUP
# =============================================================================

# Detect current shell
if [[ -n "$ZSH_VERSION" ]]; then
    SHELL_TYPE="zsh"
    # Enable zsh-specific features
    setopt SH_WORD_SPLIT 2>/dev/null || true
elif [[ -n "$BASH_VERSION" ]]; then
    SHELL_TYPE="bash"
else
    SHELL_TYPE="unknown"
fi

# =============================================================================
# UTILITY FUNCTIONS
# =============================================================================

# Cross-shell echo with colors
log_info() {
    if command -v tput >/dev/null 2>&1 && [[ -t 1 ]]; then
        echo "$(tput setaf 2)[INFO]$(tput sgr0) $1"
    else
        echo "[INFO] $1"
    fi
}

log_warn() {
    if command -v tput >/dev/null 2>&1 && [[ -t 1 ]]; then
        echo "$(tput setaf 3)[WARN]$(tput sgr0) $1"
    else
        echo "[WARN] $1"
    fi
}

log_error() {
    if command -v tput >/dev/null 2>&1 && [[ -t 1 ]]; then
        echo "$(tput setaf 1)[ERROR]$(tput sgr0) $1"
    else
        echo "[ERROR] $1"
    fi
}

# Cross-shell array handling
array_join() {
    local delimiter="$1"
    shift
    if [[ "$SHELL_TYPE" == "zsh" ]]; then
        echo "${(j:$delimiter:)@}"
    else
        local first="$1"
        shift
        printf "%s" "$first"
        [[ $# -gt 0 ]] && printf "%s" "${@/#/$delimiter}"
    fi
}

# =============================================================================
# CORE CONSOLIDATION FUNCTIONS
# =============================================================================

# Function to handle individual AI assistant file
_handle_ai_file() {
    local ai_file="$1"
    local ai_name="$2"
    local create_symlink="${3:-true}"
    local agents_file="AGENTS.md"
    
    # Handle existing AI file
    if [[ -f "$ai_file" ]]; then
        if [[ -L "$ai_file" ]]; then
            # Already a symlink, check if it points to AGENTS.md
            local target=$(readlink "$ai_file" 2>/dev/null || echo "")
            if [[ "$target" == "$agents_file" ]]; then
                log_info "$ai_name.md already points to AGENTS.md"
                return 0
            else
                log_warn "$ai_name.md exists as symlink to '$target', replacing..."
                rm "$ai_file"
            fi
        else
            # Regular file, check if AGENTS.md also exists
            if [[ -f "$agents_file" ]]; then
                # Both files exist - use gum for interactive selection
                if command -v gum >/dev/null 2>&1; then
                    local choice=$(gum choose \
                        "Keep AGENTS.md (backup $ai_name.md)" \
                        "Keep $ai_name.md, backup AGENTS.md, rename and symlink" \
                        "Merge both files and symlink" \
                        "Skip (resolve manually)" \
                        --header="⚠️  Both $ai_name.md and AGENTS.md exist as regular files" \
                        --selected="Merge both files and symlink")
                    
                    case "$choice" in
                        "Keep AGENTS.md (backup $ai_name.md)")
                            local backup="${ai_file}.backup.$(date +%Y%m%d_%H%M%S)"
                            log_info "Backing up $ai_name.md to '$backup'"
                            mv "$ai_file" "$backup"
                            ;;
                        "Keep $ai_name.md, backup AGENTS.md, rename and symlink")
                            local backup="${agents_file}.backup.$(date +%Y%m%d_%H%M%S)"
                            log_info "Backing up AGENTS.md to '$backup'"
                            mv "$agents_file" "$backup"
                            mv "$ai_file" "$agents_file"
                            ;;
                        "Merge both files and symlink")
                            log_info "Merging files..."
                            local temp_merged="${agents_file}.merged.$(date +%Y%m%d_%H%M%S)"
                            {
                                echo "# Merged from $ai_name.md and AGENTS.md - $(date)"
                                echo ""
                                echo "## From AGENTS.md:"
                                cat "$agents_file"
                                echo ""
                                echo "## From $ai_name.md:"
                                cat "$ai_file"
                            } > "$temp_merged"
                            
                            local backup_agents="${agents_file}.backup.$(date +%Y%m%d_%H%M%S)"
                            local backup_ai="${ai_file}.backup.$(date +%Y%m%d_%H%M%S)"
                            mv "$agents_file" "$backup_agents"
                            mv "$ai_file" "$backup_ai"
                            mv "$temp_merged" "$agents_file"
                            log_info "Created merged AGENTS.md, originals backed up"
                            ;;
                        "Skip (resolve manually)"|*)
                            log_warn "Skipping $ai_name.md - please resolve manually"
                            return 1
                            ;;
                    esac
                else
                    # Fallback to basic prompt if gum not available
                    log_warn "Both $ai_name.md and AGENTS.md exist as regular files"
                    echo "Install gum for better UI: brew install gum"
                    echo "Choose which file to keep as the master:"
                    echo "  1) Keep AGENTS.md (backup $ai_name.md)"
                    echo "  2) Keep $ai_name.md (replace AGENTS.md)"
                    echo "  3) Merge both files and symlink [default]"
                    echo "  4) Skip (resolve manually)"
                    echo -n "Choice [1/2/3/4, default=3]: "
                    
                    read -r choice
                    case "${choice:-3}" in
                        1)
                            local backup="${ai_file}.backup.$(date +%Y%m%d_%H%M%S)"
                            log_info "Backing up $ai_name.md to '$backup'"
                            mv "$ai_file" "$backup"
                            ;;
                        2)
                            local backup="${agents_file}.backup.$(date +%Y%m%d_%H%M%S)"
                            log_info "Backing up AGENTS.md to '$backup'"
                            mv "$agents_file" "$backup"
                            mv "$ai_file" "$agents_file"
                            ;;
                        3)
                            log_info "Merging files..."
                            local temp_merged="${agents_file}.merged.$(date +%Y%m%d_%H%M%S)"
                            {
                                echo "# Merged from $ai_name.md and AGENTS.md - $(date)"
                                echo ""
                                echo "## From AGENTS.md:"
                                cat "$agents_file"
                                echo ""
                                echo "## From $ai_name.md:"
                                cat "$ai_file"
                            } > "$temp_merged"
                            
                            local backup_agents="${agents_file}.backup.$(date +%Y%m%d_%H%M%S)"
                            local backup_ai="${ai_file}.backup.$(date +%Y%m%d_%H%M%S)"
                            mv "$agents_file" "$backup_agents"
                            mv "$ai_file" "$backup_ai"
                            mv "$temp_merged" "$agents_file"
                            log_info "Created merged AGENTS.md, originals backed up"
                            ;;
                        4|*)
                            log_warn "Skipping $ai_name.md - please resolve manually"
                            return 1
                            ;;
                    esac
                fi
            else
                # Only AI file exists, rename it to AGENTS.md
                log_info "Renaming $ai_name.md to AGENTS.md..."
                mv "$ai_file" "$agents_file"
            fi
        fi
    fi
    
    # Create symlink only if requested and file existed before
    if [[ "$create_symlink" == "true" ]]; then
        ln -s "$agents_file" "$ai_file"
        log_info "Created $ai_name.md -> AGENTS.md symlink"
    fi
    return 0
}

# Main function to fuse AI assistant files
_fuse-agents() {
    local target_dir="${1:-.}"
    
    if [[ ! -d "$target_dir" ]]; then
        log_error "Directory '$target_dir' does not exist"
        return 1
    fi
    
    # Save current directory
    local original_dir="$PWD"
    
    # Change to target directory
    cd "$target_dir" || return 1
    
    # Check if AGENTS.md exists or can be created
    if [[ ! -f "AGENTS.md" && ! -f "CLAUDE.md" && ! -f "GEMINI.md" ]]; then
        cd "$original_dir"
        return 0  # Silent return for no files
    fi
    
    local processed=0
    
    # Handle CLAUDE.md
    if [[ -f "CLAUDE.md" || -f "AGENTS.md" ]]; then
        if _handle_ai_file "CLAUDE.md" "CLAUDE" "true"; then
            ((processed++))
        fi
    fi
    
    # Handle GEMINI.md - skip symlinking since GEMINI can read AGENTS.md directly
    if [[ -f "GEMINI.md" && ! -f "AGENTS.md" ]]; then
        # Only process GEMINI.md if AGENTS.md doesn't exist
        log_info "Renaming GEMINI.md to AGENTS.md (GEMINI can read AGENTS.md directly)..."
        mv "GEMINI.md" "AGENTS.md"
        ((processed++))
    elif [[ -f "GEMINI.md" && -f "AGENTS.md" ]]; then
        # Both files exist - handle the conflict
        if command -v gum >/dev/null 2>&1; then
            local choice=$(gum choose \
                "Keep AGENTS.md (remove GEMINI.md)" \
                "Keep GEMINI.md, replace AGENTS.md" \
                "Merge both files into AGENTS.md" \
                "Skip (resolve manually)" \
                --header="⚠️  Both GEMINI.md and AGENTS.md exist - GEMINI can read AGENTS.md directly" \
                --selected="Keep AGENTS.md (remove GEMINI.md)")

            case "$choice" in
                "Keep AGENTS.md (remove GEMINI.md)")
                    local backup="GEMINI.md.backup.$(date +%Y%m%d_%H%M%S)"
                    log_info "Backing up GEMINI.md to '$backup' (GEMINI can read AGENTS.md directly)"
                    mv "GEMINI.md" "$backup"
                    ((processed++))
                    ;;
                "Keep GEMINI.md, replace AGENTS.md")
                    local backup="AGENTS.md.backup.$(date +%Y%m%d_%H%M%S)"
                    log_info "Backing up AGENTS.md to '$backup'"
                    mv "AGENTS.md" "$backup"
                    mv "GEMINI.md" "AGENTS.md"
                    ((processed++))
                    ;;
                "Merge both files into AGENTS.md")
                    log_info "Merging files..."
                    local temp_merged="AGENTS.md.merged.$(date +%Y%m%d_%H%M%S)"
                    {
                        echo "# Merged from GEMINI.md and AGENTS.md - $(date)"
                        echo ""
                        echo "## From AGENTS.md:"
                        cat "AGENTS.md"
                        echo ""
                        echo "## From GEMINI.md:"
                        cat "GEMINI.md"
                    } > "$temp_merged"

                    local backup_agents="AGENTS.md.backup.$(date +%Y%m%d_%H%M%S)"
                    local backup_gemini="GEMINI.md.backup.$(date +%Y%m%d_%H%M%S)"
                    mv "AGENTS.md" "$backup_agents"
                    mv "GEMINI.md" "$backup_gemini"
                    mv "$temp_merged" "AGENTS.md"
                    log_info "Created merged AGENTS.md, originals backed up"
                    ((processed++))
                    ;;
                "Skip (resolve manually)"|*)
                    log_warn "Skipping GEMINI.md - please resolve manually"
                    ;;
            esac
        else
            # Fallback to basic prompt if gum not available
            log_warn "Both GEMINI.md and AGENTS.md exist - GEMINI can read AGENTS.md directly"
            echo "Choose which file to keep as AGENTS.md:"
            echo "  1) Keep AGENTS.md (remove GEMINI.md) [default]"
            echo "  2) Keep GEMINI.md (replace AGENTS.md)"
            echo "  3) Merge both files into AGENTS.md"
            echo "  4) Skip (resolve manually)"
            echo -n "Choice [1/2/3/4, default=1]: "

            read -r choice
            case "${choice:-1}" in
                1)
                    local backup="GEMINI.md.backup.$(date +%Y%m%d_%H%M%S)"
                    log_info "Backing up GEMINI.md to '$backup' (GEMINI can read AGENTS.md directly)"
                    mv "GEMINI.md" "$backup"
                    ((processed++))
                    ;;
                2)
                    local backup="AGENTS.md.backup.$(date +%Y%m%d_%H%M%S)"
                    log_info "Backing up AGENTS.md to '$backup'"
                    mv "AGENTS.md" "$backup"
                    mv "GEMINI.md" "AGENTS.md"
                    ((processed++))
                    ;;
                3)
                    log_info "Merging files..."
                    local temp_merged="AGENTS.md.merged.$(date +%Y%m%d_%H%M%S)"
                    {
                        echo "# Merged from GEMINI.md and AGENTS.md - $(date)"
                        echo ""
                        echo "## From AGENTS.md:"
                        cat "AGENTS.md"
                        echo ""
                        echo "## From GEMINI.md:"
                        cat "GEMINI.md"
                    } > "$temp_merged"

                    local backup_agents="AGENTS.md.backup.$(date +%Y%m%d_%H%M%S)"
                    local backup_gemini="GEMINI.md.backup.$(date +%Y%m%d_%H%M%S)"
                    mv "AGENTS.md" "$backup_agents"
                    mv "GEMINI.md" "$backup_gemini"
                    mv "$temp_merged" "AGENTS.md"
                    log_info "Created merged AGENTS.md, originals backed up"
                    ((processed++))
                    ;;
                4|*)
                    log_warn "Skipping GEMINI.md - please resolve manually"
                    ;;
            esac
        fi
    fi
    
    # Return to original directory
    cd "$original_dir"
    
    if [[ $processed -gt 0 ]]; then
        log_info "Processed $processed AI assistant file(s) in '$target_dir'"
    fi
}

# =============================================================================
# AUTO-DETECTION FUNCTIONS
# =============================================================================

# Auto-detection and auto-fusing function
_fuse_auto_detect() {
    # Check if auto-fusing is disabled
    if [[ -n "$FUSE_AGENTS_AUTO" && "$FUSE_AGENTS_AUTO" == "false" ]]; then
        return
    fi

    # Only run if we're in an interactive shell
    if [[ "$SHELL_TYPE" == "bash" ]]; then
        [[ $- == *i* ]] || return
    elif [[ "$SHELL_TYPE" == "zsh" ]]; then
        [[ $- == *i* ]] || return
    fi
    
    # Prevent recursive calls
    if [[ -n "$_FUSE_AGENTS_RUNNING" ]]; then
        return
    fi
    
    local detected_files=()
    
    # Check for AI assistant files that need processing
    if [[ -f "CLAUDE.md" && ! -L "CLAUDE.md" ]]; then
        detected_files+=("CLAUDE.md")
    fi
    
    # Skip GEMINI.md auto-detection since it can read AGENTS.md directly
    # No need to auto-fuse GEMINI.md symlinks
    
    if [[ ${#detected_files[@]} -gt 0 ]]; then
        local files_list=$(array_join ", " "${detected_files[@]}")
        log_info "Detected ${files_list} (regular file(s))"
        log_info "Auto-fusing using merge strategy..."
        
        # Set flag to prevent recursive calls
        export _FUSE_AGENTS_RUNNING=1
        
        # Auto-fuse using merge strategy
        _fuse-agents "."
        
        # Clear flag
        unset _FUSE_AGENTS_RUNNING
    fi
}

# =============================================================================
# COMMAND FUNCTIONS
# =============================================================================

# Main command
fuse-agents() {
    case "${1:-}" in
        -h|--help|help)
            cat << 'EOF'
Fuse Agents - AI Assistant File Management

USAGE:
    fuse-agents [directory]     # Fuse files in directory (default: current)
    fuse-agents-auto            # Auto-detect and fuse current directory
    fuse-agents-recursive [dir] # Recursively fuse all directories with AI files

DESCRIPTION:
    Automatically fuses CLAUDE.md and GEMINI.md files into AGENTS.md
    with symlink management and smart merging. GEMINI.md is not symlinked
    since GEMINI can read AGENTS.md directly. If GEMINI.md doesn't exist,
    no symlink will be created for it.

EXAMPLES:
    fuse-agents                 # Process current directory
    fuse-agents ~/project       # Process specific directory
    fuse-agents-auto            # Auto-detect and process current directory
    fuse-agents-recursive ~/dev # Process all projects in dev directory

FILES:
    CLAUDE.md  → AGENTS.md (symlink)
    GEMINI.md  → AGENTS.md (merged/renamed, no symlink)
    AGENTS.md  (merged content)

OPTIONS:
    -h, --help    Show this help message
EOF
            ;;
        *)
            _fuse-agents "$@"
            ;;
    esac
}

# Auto-detect command
fuse-agents-auto() {
    if [[ -f "AGENTS.md" || -f "CLAUDE.md" || -f "GEMINI.md" ]]; then
        _fuse-agents "."
    fi
}

# Recursive command
fuse-agents-recursive() {
    local base_dir="${1:-.}"
    local found=0
    
    log_info "Searching for AI assistant files in '$base_dir'..."
    
    # Find directories with any of the target files
    while IFS= read -r -d '' dir; do
        if [[ -n "$dir" ]]; then
            _fuse-agents "$dir"
            ((found++))
        fi
    done < <(find "$base_dir" \( -name "AGENTS.md" -o -name "CLAUDE.md" -o -name "GEMINI.md" \) -type f -printf "%h\0" 2>/dev/null | sort -uz 2>/dev/null)
    
    if [[ $found -eq 0 ]]; then
        log_info "No AI assistant files found"
    else
        log_info "Processed $found director(y/ies)"
    fi
}

# =============================================================================
# SHELL-SPECIFIC HOOKS
# =============================================================================

# Setup shell-specific hooks
_setup_shell_hooks() {
    if [[ "$SHELL_TYPE" == "zsh" ]]; then
        # Zsh: use chpwd hook
        if command -v add-zsh-hook >/dev/null 2>&1; then
            add-zsh-hook chpwd _fuse_auto_detect
        fi
    elif [[ "$SHELL_TYPE" == "bash" ]]; then
        # Bash: use PROMPT_COMMAND
        if [[ -z "$PROMPT_COMMAND" ]]; then
            PROMPT_COMMAND="_fuse_auto_detect"
        else
            # Append to existing PROMPT_COMMAND
            if [[ "$PROMPT_COMMAND" != *"_fuse_auto_detect"* ]]; then
                PROMPT_COMMAND="$PROMPT_COMMAND; _fuse_auto_detect"
            fi
        fi
    fi
}

# =============================================================================
# INITIALIZATION
# =============================================================================

# Setup hooks and run initial detection
_setup_shell_hooks

# Run on initial shell startup
_fuse_auto_detect

# Export functions for use in subshells (only in Bash)
if [[ "$SHELL_TYPE" == "bash" ]]; then
    export -f _fuse-agents 2>/dev/null || true
    export -f _handle_ai_file 2>/dev/null || true
    export -f _fuse_auto_detect 2>/dev/null || true
    export -f fuse-agents 2>/dev/null || true
    export -f fuse-agents-auto 2>/dev/null || true
    export -f fuse-agents-recursive 2>/dev/null || true
fi