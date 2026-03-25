#!/bin/bash
set -e

# NOTE: chezmoi must already be installed before this script runs.
# Bootstrap a new machine with:
#   sudo apt-get install -y git
#   sudo snap install chezmoi --classic
#   mkdir -p ~/.config/chezmoi && nano ~/.config/chezmoi/key.txt  # paste age key
#   chezmoi init --apply <your-git-repo-url>

# Base packages
sudo apt update
sudo apt install -y tmux neovim git curl wget age zsh mc btop ripgrep fd

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
