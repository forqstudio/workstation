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
sudo apt upgrade -y
sudo apt install -y tmux neovim git curl wget age zsh

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

# .NET SDKs
# dotnet-sdk-10.0 is installed via apt (Microsoft feed).
# dotnet-sdk-8.0 and 9.0 are installed via dotnet-install.sh because Ubuntu's
# versioned dotnet-host-X.0 packages conflict with each other when installed together.
wget "https://packages.microsoft.com/config/ubuntu/$(lsb_release -rs)/packages-microsoft-prod.deb" \
  -O /tmp/packages-microsoft-prod.deb
sudo dpkg -i /tmp/packages-microsoft-prod.deb
rm /tmp/packages-microsoft-prod.deb

sudo add-apt-repository ppa:dotnet/backports # Ubuntu 24.04 (WSL2)

sudo apt-get update
sudo apt-get install -y dotnet-sdk-10.0

DOTNET_INSTALL="$(mktemp)"
curl -fsSL https://dot.net/v1/dotnet-install.sh -o "$DOTNET_INSTALL"
chmod +x "$DOTNET_INSTALL"
"$DOTNET_INSTALL" --channel 8.0
"$DOTNET_INSTALL" --channel 9.0
rm "$DOTNET_INSTALL"

# Oh My Zsh
if [ ! -d "$HOME/.oh-my-zsh" ]; then
  sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" \
    "" --unattended
  chsh -s "$(which zsh)" "$USER"
fi

# NVM
if [ ! -d "$HOME/.nvm" ]; then
  curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.0/install.sh | bash
fi
