#!/bin/bash
set -e

# 1Password CLI apt repo (written unconditionally so apt update always succeeds)
curl -fsSL https://downloads.1password.com/linux/keys/1password.asc \
  | sudo gpg --yes --dearmor --output /usr/share/keyrings/1password-archive-keyring.gpg
echo "deb [signed-by=/usr/share/keyrings/1password-archive-keyring.gpg] \
  https://downloads.1password.com/linux/debian/$(dpkg --print-architecture) stable main" \
  | sudo tee /etc/apt/sources.list.d/1password.list

# Base packages
sudo apt update
# universe repo may not be enabled by default on WSL2 Ubuntu 22.04
sudo apt install -y software-properties-common
sudo add-apt-repository -y universe
sudo apt update

sudo apt install -y tmux neovim git curl wget age zsh mc btop ripgrep

# VS Code (via official Microsoft apt repo)
if ! command -v code &>/dev/null; then
  wget -qO- https://packages.microsoft.com/keys/microsoft.asc \
    | gpg --dearmor > /tmp/packages.microsoft.gpg
  sudo install -D -o root -g root -m 644 \
    /tmp/packages.microsoft.gpg \
    /etc/apt/keyrings/packages.microsoft.gpg
  echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/packages.microsoft.gpg] \
    https://packages.microsoft.com/repos/code stable main" \
    | sudo tee /etc/apt/sources.list.d/vscode.list
  sudo apt update
  sudo apt install -y code
fi

# 1Password CLI (repo set up at top of script; install only if missing)
if ! command -v op &>/dev/null; then
  sudo apt install -y 1password-cli
fi

# 1Password desktop — skip on WSL2 (run Windows app instead)
if ! grep -qi microsoft /proc/version 2>/dev/null; then
  if ! command -v 1password &>/dev/null; then
    sudo apt install -y 1password
  fi
fi

# Docker — skip on WSL2 where Docker Desktop provides the daemon via integration
if ! grep -qi microsoft /proc/version 2>/dev/null; then
  if ! command -v docker &>/dev/null; then
    curl -fsSL https://get.docker.com | sh
    sudo usermod -aG docker "$USER"
  fi
fi

# .NET SDK (latest LTS)
if ! command -v dotnet &>/dev/null; then
  DOTNET_INSTALL="$(mktemp)"
  curl -fsSL https://dot.net/v1/dotnet-install.sh -o "$DOTNET_INSTALL"
  chmod +x "$DOTNET_INSTALL"
  "$DOTNET_INSTALL" --channel LTS
  rm "$DOTNET_INSTALL"
fi

# Load dotnet into PATH without requiring a shell restart
export PATH="$HOME/.dotnet:$PATH"

# Oh My Zsh
if [ ! -d "$HOME/.oh-my-zsh" ]; then
  # KEEP_ZSHRC=yes prevents the installer from overwriting chezmoi-managed ~/.zshrc
  KEEP_ZSHRC=yes sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" \
    "" --unattended
  chsh -s "$(which zsh)" "$USER"
fi

# NVM
if [ ! -d "$HOME/.nvm" ]; then
  NVM_VERSION=$(curl -fsSL https://api.github.com/repos/nvm-sh/nvm/releases/latest \
    | grep '"tag_name"' | sed 's/.*"tag_name": *"\(.*\)".*/\1/')
  curl -o- "https://raw.githubusercontent.com/nvm-sh/nvm/${NVM_VERSION}/install.sh" | bash
fi

export NVM_DIR="$HOME/.nvm"
# shellcheck disable=SC1091
[ -s "$NVM_DIR/nvm.sh" ] && source "$NVM_DIR/nvm.sh"
nvm install --lts

# Bun
if ! command -v bun &>/dev/null; then
  curl -fsSL https://bun.sh/install | bash
fi

# Claude Code
if ! command -v claude &>/dev/null; then
  npm install -g @anthropic-ai/claude-code
fi

# OpenCode
if ! command -v opencode &>/dev/null; then
  curl -fsSL https://opencode.ai/install | bash
fi

# Azure CLI
if ! command -v az &>/dev/null; then
  curl -sL https://aka.ms/InstallAzureCLIDeb | sudo bash
fi

# Print installed versions
GREEN='\033[0;32m'
RESET='\033[0m'
row() {
  local name="$1"; shift
  local version
  if command -v "$1" &>/dev/null; then
    version=$("$@" 2>&1 | head -1)
  else
    version="not found"
  fi
  printf "${GREEN}  %-12s${RESET} %s\n" "$name" "$version"
}

echo ""
echo "=== Installed versions ==="
row tmux      tmux -V
row nvim      nvim --version
row git       git --version
row curl      curl --version
row wget      wget --version
row age       age --version
row zsh       zsh --version
row mc        mc --version
row btop      btop --version
row rg        rg --version
row code      code --version
row docker    docker --version
row dotnet    dotnet --version
row node      node --version
row nvm       nvm --version
row claude    claude --version
row opencode  opencode --version
row bun       bun --version
row az        az --version
row op        op --version
row 1password 1password --version
