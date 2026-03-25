# dotfiles

Personal dotfiles managed with [chezmoi](https://www.chezmoi.io/).

---

## What's managed

| File | Description |
|------|-------------|
| `~/.zshrc` | Zsh config (Oh My Zsh, robbyrussell theme) |
| `~/.bashrc` | Bash config (NVM, standard aliases) |
| `~/.profile` | Login shell init |
| `~/.bash_logout` | Bash logout script |
| `~/.gitconfig` | Git user name and email (injected via chezmoi template) |
| `~/.config/git/ignore` | Global gitignore |
| `~/.config/Code/User/keybindings.json` | VS Code keybindings |
| `~/.config/btop/btop.conf` | btop system monitor config |

The `run_once_install-packages.sh` script runs automatically on first `chezmoi apply` and installs:

| Package | Description | Reference |
|---------|-------------|-----------|
| [git](https://git-scm.com) | Distributed version control system | [docs](https://git-scm.com/doc) |
| [curl](https://curl.se) | Command-line tool for transferring data via URLs | [manual](https://curl.se/docs/manpage.html) |
| [wget](https://www.gnu.org/software/wget/) | Non-interactive network downloader | [manual](https://www.gnu.org/software/wget/manual/) |
| [zsh](https://www.zsh.org) | Extended Bourne shell with improvements | [docs](https://zsh.sourceforge.io/Doc/) |
| [Oh My Zsh](https://ohmyz.sh) | Framework for managing Zsh configuration | [repo](https://github.com/ohmyzsh/ohmyzsh) |
| [tmux](https://github.com/tmux/tmux) | Terminal multiplexer — split panes, persistent sessions | [wiki](https://github.com/tmux/tmux/wiki) |
| [mc](https://midnight-commander.org) | Midnight Commander — visual file manager | [manual](https://midnight-commander.org/wiki/doc) |
| [btop](https://github.com/aristocratos/btop) | Resource monitor — modern top/htop alternative | [repo](https://github.com/aristocratos/btop) |
| [neovim](https://neovim.io) | Hyperextensible Vim-based text editor | [docs](https://neovim.io/doc/) |
| [ripgrep](https://github.com/BurntSushi/ripgrep) | Fast line-oriented search tool (grep replacement) | [repo](https://github.com/BurntSushi/ripgrep) |
| [age](https://age-encryption.org) | Simple, modern file encryption tool | [repo](https://github.com/FiloSottile/age) |
| [1Password CLI](https://developer.1password.com/docs/cli) | `op` command-line interface for 1Password (via apt repo) | [docs](https://developer.1password.com/docs/cli) |
| [1Password](https://1password.com) | Password manager desktop app (skipped on WSL2) | [downloads](https://1password.com/downloads/linux/) |
| [NVM](https://github.com/nvm-sh/nvm) | Node Version Manager — installs and switches Node versions | [repo](https://github.com/nvm-sh/nvm) |
| [Node.js LTS](https://nodejs.org) | JavaScript runtime (installed via NVM) | [docs](https://nodejs.org/en/docs) |
| [.NET SDK](https://dotnet.microsoft.com) | Cross-platform .NET (Core) SDK, latest LTS, installed to `~/.dotnet` | [docs](https://learn.microsoft.com/en-us/dotnet/) |
| [VS Code](https://code.visualstudio.com) | Source code editor by Microsoft (via apt repo) | [docs](https://code.visualstudio.com/docs) |
| [Docker](https://www.docker.com) | Container platform (via get.docker.com) | [docs](https://docs.docker.com) |
| [socat](http://www.dest-unreach.org/socat/) | Multipurpose relay — used to bridge Windows SSH agent into WSL2 (WSL2 only) | [docs](http://www.dest-unreach.org/socat/doc/socat.html) |

Each tool is installed only if not already present — the script is safe to re-run.

---

## SSH agent support

The `.zshrc` automatically sets `SSH_AUTH_SOCK` to the 1Password agent socket if it is running. If 1Password is not installed or not running, this is a no-op — any existing SSH agent (OpenSSH, GNOME keyring, etc.) continues to work as normal.

| Setup | Linux | WSL2 |
|---|---|---|
| 1Password SSH agent | Auto-configured by `.zshrc` | Auto-started by `.zshrc` (requires `npiperelay.exe`) |
| Windows OpenSSH agent | N/A | Same auto-start (requires `npiperelay.exe`) |
| Linux system agent (OpenSSH, GNOME keyring) | Unchanged | Unchanged |

---

## Setting up a new machine

### 1. Install prerequisites

```bash
sudo apt-get install -y git
sh -c "$(curl -fsLS get.chezmoi.io)" -- -b ~/.local/bin
```

This places the `chezmoi` binary in `~/.local/bin`. Make sure that directory is in your `$PATH`.

### 2. Set up SSH access to GitHub

GitHub requires SSH (or a personal access token) — password authentication is not supported.

#### Option A — 1Password SSH agent (zero key-file setup)

1. Install 1Password desktop → sign in
2. Enable the SSH agent: **Settings → Developer → Use the SSH agent**
3. Your GitHub SSH key is already stored in 1Password from a previous machine
4. Export the socket for the first clone:
   ```bash
   export SSH_AUTH_SOCK=~/.1password/agent.sock
   ```
5. Proceed to Step 3 — no key file restoration needed

#### Option B — OpenSSH / new key

```bash
ssh-keygen -t ed25519 -C "you@example.com"
cat ~/.ssh/id_ed25519.pub   # copy this output
```

Then add the public key to GitHub: **Settings → SSH and GPG keys → New SSH key**.

#### WSL2 — relay Windows SSH agent into WSL2

Both 1Password for Windows and the Windows built-in OpenSSH agent expose the same named pipe. Use `socat` + `npiperelay.exe` to forward it into WSL2:

```bash
# Prerequisites:
#   - socat in WSL2 (installed automatically by run_once_install-packages.sh)
#   - npiperelay.exe on Windows PATH accessible from WSL2
mkdir -p ~/.1password
socat UNIX-LISTEN:~/.1password/agent.sock,fork \
  EXEC:"npiperelay.exe -ei -s //./pipe/openssh-ssh-agent",nofork &
export SSH_AUTH_SOCK=~/.1password/agent.sock
```

After `chezmoi apply`, the relay starts automatically on every new shell via `.zshrc` — no manual startup script needed.

### 3. Clone and apply dotfiles

```bash
chezmoi init --apply git@github.com:forqstudio/workstation.git
```

Chezmoi will prompt for your name and email — these are written to `~/.config/chezmoi/chezmoi.toml` locally and injected into `~/.gitconfig`.

This will:
1. Clone this repo to `~/.local/share/chezmoi/`
2. Apply all dotfiles to your home directory
3. Run the install script (installs all tools listed above)

### 4. Post-setup

Log out and back in (or run `newgrp docker`) for Docker group membership to take effect.

---

## Known limitations

The 1Password CLI (`op`) does not support YubiKey 2FA in the terminal. If you need to access secrets via `op` during bootstrap, install the 1Password desktop app first (`.deb` from [1password.com/downloads/linux](https://1password.com/downloads/linux/)) and sign in — this unlocks the CLI.

---

## Day-to-day usage

### Editing dotfiles

```bash
# Edit a tracked dotfile (opens in $EDITOR, applies on save)
chezmoi edit ~/.zshrc

# Edit and immediately apply
chezmoi edit --apply ~/.zshrc

# Open the source directory directly
chezmoi cd
```

### Applying changes

```bash
# Preview what would change (dry run)
chezmoi diff

# Apply all pending changes from source to home
chezmoi apply

# Apply a single file
chezmoi apply ~/.zshrc
```

### Adding files

```bash
# Track a new file
chezmoi add ~/.config/some/file

# Track a new file with age encryption (for secrets/keys)
chezmoi add --encrypt ~/.some-secret-file

# Re-add after editing the destination directly
chezmoi re-add ~/.zshrc
```

### Syncing

```bash
# Pull latest changes from git and apply
chezmoi update

# Check what the last-applied state looks like
chezmoi status
```

### Committing

```bash
# Stage and commit from within the source directory
chezmoi cd && git add -A && git commit -m "..."

# Or with the full path
cd ~/.local/share/chezmoi && git add -A && git commit -m "..."
```

---

## Security

- SSH keys are **not stored in this repo** — 1Password acts as an SSH agent only; private key material never touches the filesystem.
- `.chezmoiignore` blocks accidental addition of secrets (`.claude.json`, gnupg, NVM, 1Password socket dir, etc.).
- Personal info (name, email) is injected via chezmoi templates and stored in the local, untracked `~/.config/chezmoi/chezmoi.toml`.
