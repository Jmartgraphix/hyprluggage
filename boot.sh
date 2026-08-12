#!/bin/bash
#|---/ /+---------------------+---/ /|#
#|--/ /-| Hyprluggage         |--/ /-|#
#|-/ /--| Bootstrap Script    |-/ /--|#
#|/ /---+---------------------+/ /---|#

set -e

# Colors
MAGENTA='\033[0;35m'
GREEN='\033[0;32m'
DIM='\033[2m'
RESET='\033[0m'

clear
echo -e "${MAGENTA}"
cat << 'EOF'

                                                                   
   ▄▄▄  ▄▄▄                 ▄▄                                     
  █▀██  ██                   ██                                    
    ██  ██              ▄    ██          ▄▄    ▄▄          ▄▄      
    ██████  ██ ██ ████▄ ████▄██ ██ ██ ▄████ ▄████ ▄▀▀█▄ ▄████ ▄█▀█▄
    ██  ██  ██▄██ ██ ██ ██   ██ ██ ██ ██ ██ ██ ██ ▄█▀██ ██ ██ ██▄█▀
  ▀██▀  ▀██▄▄▀██▀▄████▀▄█▀  ▄██▄▀██▀█▄▀████▄▀████▄▀█▄██▄▀████▄▀█▄▄▄
              ██  ██                     ██    ██          ██      
            ▀▀▀   ▀                    ▀▀▀   ▀▀▀         ▀▀▀       

EOF
echo -e "${RESET}"

REPO="${HYPRLUGGAGE_REPO:-Jmartgraphix/hyprluggage}"
BRANCH="${HYPRLUGGAGE_BRANCH:-master}"
DEST="${HYPRLUGGAGE_DEST:-$HOME/hyprluggage}"

# Bootstrap dependencies
echo -e "\n${DIM}:: Preparing system${RESET}"
sudo pacman -Syu --noconfirm --needed git stow gum

# Clone or update
echo
if [[ -d "$DEST/.git" ]]; then
    echo -e "${DIM}  Updating hyprluggage...${RESET}"
    git -C "$DEST" pull --ff-only || true
else
    echo -e "${DIM}  Cloning from github.com/${REPO}...${RESET}"
    rm -rf "$DEST"
    git clone "https://github.com/${REPO}.git" "$DEST"
fi

# Switch branch if needed (default remote branch is master)
if [[ "$BRANCH" != "master" ]]; then
    git -C "$DEST" fetch origin "$BRANCH"
    git -C "$DEST" checkout "$BRANCH"
fi

# Verify clone worked
if [[ ! -f "$DEST/install.sh" ]]; then
    echo -e "\n${MAGENTA}  ✗${RESET} Clone failed - install.sh not found"
    exit 1
fi

echo -e "${GREEN}  ✓${RESET} Repository ready"
echo

cd "$DEST"
source ./install.sh
