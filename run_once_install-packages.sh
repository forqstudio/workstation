#!/bin/bash
set -e

# Base packages
sudo apt update
# universe repo may not be enabled by default on WSL2 Ubuntu 22.04
sudo apt install -y software-properties-common
sudo add-apt-repository -y universe
sudo apt update

sudo apt install -y tmux neovim git curl wget age zsh mc btop

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

# Docker (via official apt repo — snap version has bind-mount and rootless limitations)
if ! command -v docker &>/dev/null; then
  curl -fsSL https://get.docker.com | sh
  sudo usermod -aG docker "$USER"
fi

# .NET SDK (latest LTS)
if ! command -v dotnet &>/dev/null; then
  DOTNET_INSTALL="$(mktemp)"
  curl -fsSL https://dot.net/v1/dotnet-install.sh -o "$DOTNET_INSTALL"
  chmod +x "$DOTNET_INSTALL"
  "$DOTNET_INSTALL" --channel LTS
  rm "$DOTNET_INSTALL"
fi

# Oh My Zsh
if [ ! -d "$HOME/.oh-my-zsh" ]; then
  sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" \
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

# Load dotnet into PATH without requiring a shell restart
export PATH="$HOME/.dotnet:$PATH"

# Installed versions
echo "=== Installed versions ==="
tmux -V
nvim --version | head -1
git --version
curl --version | head -1
wget --version | head -1
age --version
zsh --version
mc --version | head -1
btop --version
rg --version | head -1
code --version | head -1
docker --version
dotnet --version
node --version
nvm --version
