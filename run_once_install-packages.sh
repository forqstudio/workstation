#!/bin/bash
set -euo pipefail

LOG_FILE="${LOG_FILE:-/tmp/install-packages.log}"

log() {
  local level="$1"
  shift
  local msg="$*"
  local timestamp
  timestamp=$(date '+%Y-%m-%d %H:%M:%S')
  echo "[$timestamp] [$level] $msg" | tee -a "$LOG_FILE" || true
}

log_info() { log "INFO" "$@"; }
log_error() { log "ERROR" "$@"; }
log_success() { log "SUCCESS" "$@"; }

GREEN='\033[0;32m'
YELLOW='\033[0;33m'
RESET='\033[0m'

cleanup() {
  local exit_code=$?
  if [[ $exit_code -ne 0 && $exit_code -ne 141 ]]; then
    log_error "Script failed with exit code $exit_code. Check $LOG_FILE for details."
  fi
  exit "$exit_code"
}

trap cleanup EXIT

is_wsl() {
  grep -qi microsoft /proc/version 2>/dev/null
}

is_installed() {
  command -v "$1" &>/dev/null
}

add_apt_repo() {
  local name="$1"
  local key_url="$2"
  local list_file="$3"
  shift 3
  local components=("$@")

  sudo mkdir -p /etc/apt/keyrings
  sudo mkdir -p /etc/apt/sources.list.d

  local keyring="/etc/apt/keyrings/${name}.gpg"
  if [[ "$key_url" == /* ]]; then
    sudo cp "$key_url" "$keyring"
  else
    curl -fsSL "$key_url" | sudo gpg --dearmor --yes -o "$keyring"
  fi

  local arch=$(dpkg --print-architecture)
  echo "deb [arch=$arch signed-by=$keyring] ${components[*]}" | sudo tee "/etc/apt/sources.list.d/${list_file}" >/dev/null
}

install_apt() {
  sudo apt install -y "$@"
}

install_script() {
  local name="$1"
  local url="$2"
  local args="$3"

  curl -fsSL "$url" | bash -s "$args"
}

setup_repos() {
  log_info "Setting up apt repositories..."
  add_apt_repo 1password https://downloads.1password.com/linux/keys/1password.asc \
    1password.list "https://downloads.1password.com/linux/debian/$(dpkg --print-architecture) stable main"

  if ! is_installed code; then
    add_apt_repo microsoft https://packages.microsoft.com/keys/microsoft.asc \
      microsoft.list "https://packages.microsoft.com/repos/code stable main"
  fi
  log_success "Repositories configured"
}

install_base_tools() {
  log_info "Installing base tools..."
  sudo apt update
  sudo apt install -y software-properties-common
  sudo add-apt-repository -y universe
  sudo apt update

  install_apt \
    apt-utils \
    apt-transport-https \
    bash-completion \
    bat \
    build-essential \
    ca-certificates \
    clang \
    cmake \
    curl \
    dnsutils \
    fd-find \
    file \
    fzf \
    gdb \
    git \
    git-lfs \
    gnupg \
    htop \
    iproute2 \
    iputils-ping \
    jq \
    less \
    libbz2-dev \
    libclang-dev \
    libffi-dev \
    libgdbm-dev \
    liblzma-dev \
    libncurses5-dev \
    libncursesw5-dev \
    libreadline-dev \
    libsqlite3-dev \
    libssl-dev \
    libxml2-dev \
    libxmlsec1-dev \
    libyaml-dev \
    lld \
    locales \
    llvm \
    man-db \
    manpages \
    nano \
    neovim \
    net-tools \
    ninja-build \
    openssh-client \
    openssh-server \
    pipx \
    pkg-config \
    procps \
    psmisc \
    python-is-python3 \
    python3 \
    python3-dev \
    python3-pip \
    python3-setuptools \
    python3-venv \
    python3-wheel \
    ripgrep \
    rsync \
    shellcheck \
    sqlite3 \
    strace \
    sudo \
    tmux \
    tree \
    unzip \
    vim \
    wget \
    xz-utils \
    zip \
    zsh \
    age \
    mc \
    btop

  sudo update-alternatives --install /usr/bin/bat bat /usr/bin/batcat 100
  sudo update-alternatives --install /usr/bin/fd fdfind /usr/bin/fdfind 100
  log_success "Base tools installed"
}

install_vscode() {
  if ! is_installed code; then
    log_info "Installing VS Code..."
    install_apt code
    log_success "VS Code installed"
  fi
}

install_1password_cli() {
  if ! is_installed op; then
    log_info "Installing 1Password CLI..."
    install_apt 1password-cli
    log_success "1Password CLI installed"
  fi
}

install_1password_desktop() {
  if ! is_wsl && ! is_installed 1password; then
    log_info "Installing 1Password Desktop..."
    install_apt 1password
    log_success "1Password Desktop installed"
  fi
}

install_docker() {
  if ! is_wsl && ! is_installed docker; then
    log_info "Installing Docker..."
    curl -fsSL https://get.docker.com | sudo sh
    sudo usermod -aG docker "$USER"
    log_success "Docker installed"
  fi
}

install_dotnet() {
  if ! is_installed dotnet; then
    log_info "Installing .NET SDK..."
    local installer
    installer=$(mktemp)
    curl -fsSL https://dot.net/v1/dotnet-install.sh -o "$installer"
    chmod +x "$installer"
    "$installer" --channel LTS
    rm -f "$installer"

    local dotnet_path="$HOME/.dotnet"
    if [[ ":$PATH:" != *":$dotnet_path:"* ]]; then
      log_info "Adding .NET to PATH in shell config..."
      for rc_file in "$HOME/.bashrc" "$HOME/.zshrc"; do
        if [[ -f "$rc_file" ]]; then
          if ! grep -q "$dotnet_path" "$rc_file" 2>/dev/null; then
            echo "export PATH=\"$dotnet_path:\$PATH\"" >> "$rc_file"
          fi
        fi
      done
      export PATH="$dotnet_path:$PATH"
    fi
    log_success ".NET SDK installed"
  fi
}

install_oh_my_zsh() {
  if [ ! -d "$HOME/.oh-my-zsh" ]; then
    log_info "Installing Oh My Zsh..."
    KEEP_ZSHRC=yes sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
    chsh -s "$(which zsh)" "$USER"
    log_success "Oh My Zsh installed"
  fi
}

install_nvm() {
  if [ ! -d "$HOME/.nvm" ]; then
    log_info "Installing NVM..."
    local version
    version=$(curl -fsSL https://api.github.com/repos/nvm-sh/nvm/releases/latest | grep '"tag_name"' | sed 's/.*"tag_name": *"\(.*\)".*/\1/')
    curl -fsSL "https://raw.githubusercontent.com/nvm-sh/nvm/${version}/install.sh" | bash

    export NVM_DIR="$HOME/.nvm"
    # shellcheck disable=SC1091
    [ -s "$NVM_DIR/nvm.sh" ] && source "$NVM_DIR/nvm.sh"
  fi

  export NVM_DIR="$HOME/.nvm"
  # shellcheck disable=SC1091
  [ -s "$NVM_DIR/nvm.sh" ] && source "$NVM_DIR/nvm.sh"

  if command -v nvm &>/dev/null; then
    log_info "Installing Node LTS via NVM..."
    nvm install --lts
    log_success "Node LTS installed"
  fi
}

install_bun() {
  if ! is_installed bun; then
    log_info "Installing Bun..."
    curl -fsSL https://bun.sh/install | bash
    log_success "Bun installed"
  fi
}

install_claude_code() {
  if ! is_installed claude; then
    log_info "Installing Claude Code..."
    npm install -g @anthropic-ai/claude-code
    log_success "Claude Code installed"
  fi
}

install_opencode() {
  if ! is_installed opencode; then
    log_info "Installing OpenCode..."
    curl -fsSL https://opencode.ai/install | bash
    log_success "OpenCode installed"
  fi
}

install_zed() {
  if ! is_installed zed; then
    log_info "Installing Zed..."
    curl -fsSL https://zed.dev/install.sh | sh
    log_success "Zed installed"
  fi
}

install_azure_cli() {
  if ! is_installed az; then
    log_info "Installing Azure CLI..."
    curl -sL https://aka.ms/InstallAzureCLIDeb | sudo bash
    log_success "Azure CLI installed"
  fi
}

show_versions() {
  local row
  row() {
    local name=$1
    shift
    local ver
    if is_installed "$name"; then
      ver=$("$@" 2>&1 | head -1) || true
    else
      ver="not found"
    fi
    printf "${GREEN}  %-12s${RESET} %s\n" "$name" "$ver"
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
  row bat       bat --version
  row clang     clang --version
  row cmake     cmake --version
  row fd        fd --version
  row fzf       fzf --version
  row gdb       gdb --version
  row jq        jq --version
  row less      less --version
  row nano      nano --version
  row python3   python3 --version
  row rsync     rsync --version
  row shellcheck shellcheck --version
  row sqlite3   sqlite3 --version
  row strace    strace -V
  row tree      tree --version
  row vim       vim --version
  row zip       zip -v
  row xz        xz --version
  row file      file --version
  row gpg       gpg --version
  row htop      htop --version
  row ninja-build ninja --version
  row pipx      pipx --version
  row pkg-config pkg-config --version
  row procps    ps --version
  row sudo      sudo -V
  row lld       lld --version
  row llvm      llvm-config --version
  row git-lfs  git-lfs --version
  row code      code --version --no-sandbox
  row docker    docker --version
  row dotnet    dotnet --version
  row node      node --version
  row nvm       nvm --version 2>&1 || echo "nvm installed"
  row claude    claude --version
  row opencode  opencode --version
  row bun       bun --version
  row zed       zed --version
  row az        az --version
  row op        op --version
  row 1password 1password --version --no-sandbox

  if dpkg -s warp-terminal &>/dev/null 2>&1; then
    printf "${GREEN}  %-12s${RESET} %s\n" "warp" "$(dpkg-query -W -f='${Version}' warp-terminal)"
  else
    printf "${GREEN}  %-12s${RESET} %s\n" "warp" "not found"
  fi
}

main() {
  export PATH="$HOME/.bun/bin:$HOME/.local/bin:$HOME/.dotnet:$PATH"

  setup_repos

  install_base_tools

  install_vscode
  install_zed
  install_1password_cli
  install_1password_desktop
  install_docker
  install_dotnet
  install_oh_my_zsh
  install_nvm
  install_bun
  install_claude_code
  install_opencode

  install_azure_cli
  show_versions
}

main "$@"
