default:
    @just --list

# Validate shell syntax and run shellcheck
check:
    bash -n fuse-agents.plugin.sh install.sh uninstall.sh
    shellcheck install.sh uninstall.sh

# Run install script
install:
    ./install.sh

# Run uninstall script
uninstall:
    ./uninstall.sh

# Local CI verification gate
ci: check
