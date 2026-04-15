#!/bin/bash
# cc-switch Skill Installation Script
# Installs the skill to Claude Code's skills directory

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
REPO_URL="https://github.com/stcatz/cc-switch-skill.git"
SKILL_DIR="$HOME/.claude/skills"
INSTALL_DIR="$SKILL_DIR/cc-switch"
TEMP_DIR=$(mktemp -d)

echo -e "${BLUE}"
echo "======================================"
echo "   cc-switch Skill Installer   "
echo "======================================"
echo -e "${NC}"
echo ""

# Function to print step
print_step() {
    echo -e "${BLUE}[$1/$2]${NC} $3"
}

# Step 1: Check Claude Code skills directory
print_step "1" "5" "Checking Claude Code skills directory..."

if [ ! -d "$SKILL_DIR" ]; then
    echo -e "${YELLOW}Creating $SKILL_DIR...${NC}"
    mkdir -p "$SKILL_DIR"
fi
echo -e "${GREEN}✓ Skills directory exists${NC}"
echo ""

# Step 2: Backup existing installation if present
if [ -d "$INSTALL_DIR" ]; then
    print_step "2" "5" "Backing up existing installation..."
    BACKUP_DIR="$INSTALL_DIR.backup.$(date +%Y%m%d%H%M%S)"
    cp -r "$INSTALL_DIR" "$BACKUP_DIR"
    echo -e "${GREEN}✓ Backup saved to: $BACKUP_DIR${NC}"
    echo -e "${YELLOW}  (Use: rm -rf '$INSTALL_DIR' && mv '$BACKUP_DIR' '$INSTALL_DIR' to restore)${NC}"
    echo ""
else
    print_step "2" "5" "Checking for existing installation..."
    echo -e "${GREEN}✓ No existing installation found${NC}"
    echo ""
fi

# Step 3: Download the skill
print_step "3" "5" "Downloading cc-switch skill..."

if command -v git &>/dev/null; then
    echo "Using git clone..."
    git clone --depth 1 "$REPO_URL" "$TEMP_DIR/cc-switch"
else
    echo -e "${YELLOW}Git not found. Using curl...${NC}"

    # Get latest release tag
    LATEST_URL="https://api.github.com/repos/stcatz/cc-switch-skill/releases/latest"
    if command -v curl &>/dev/null; then
        LATEST_TAG=$(curl -s "$LATEST_URL" | grep '"tag_name"' | cut -d'"' -f4)
        if [ -n "$LATEST_TAG" ]; then
            echo "Latest version: $LATEST_TAG"
            DOWNLOAD_URL="https://github.com/stcatz/cc-switch-skill/archive/refs/tags/$LATEST_TAG.tar.gz"
            curl -sL "$DOWNLOAD_URL" | tar -xz -C "$TEMP_DIR" --strip-components=1
        else
            echo -e "${RED}Could not determine latest version. Using main branch.${NC}"
            curl -sL "$REPO_URL/archive/refs/heads/main.tar.gz" | tar -xz -C "$TEMP_DIR" --strip-components=1
        fi
    else
        echo -e "${RED}Error: Neither git nor curl is available${NC}"
        exit 1
    fi
fi
echo -e "${GREEN}✓ Download complete${NC}"
echo ""

# Step 4: Install to skills directory
print_step "4" "5" "Installing to $INSTALL_DIR..."

rm -rf "$INSTALL_DIR"
cp -r "$TEMP_DIR/cc-switch" "$INSTALL_DIR"
echo -e "${GREEN}✓ Installed${NC}"
echo ""

# Step 5: Make scripts executable
print_step "5" "5" "Making scripts executable..."

chmod +x "$INSTALL_DIR/scripts/"*.sh 2>/dev/null || true
echo -e "${GREEN}✓ Scripts are executable${NC}"
echo ""

# Cleanup
rm -rf "$TEMP_DIR"

# Summary
echo -e "${GREEN}"
echo "======================================"
echo "   Installation Complete!      "
echo "======================================"
echo -e "${NC}"
echo ""
echo "The cc-switch skill has been installed to:"
echo -e "${BLUE}  $INSTALL_DIR${NC}"
echo ""
echo "To use the skill:"
echo "  1. Restart Claude Code"
echo "  2. Use natural language commands like:"
echo "     - 'List all providers'"
echo "     - 'Switch to MiniMax'"
echo "     - 'Test connectivity of MiniMax'"
echo ""
echo "Documentation:"
echo -e "${BLUE}  https://github.com/stcatz/cc-switch-skill${NC}"
echo ""
