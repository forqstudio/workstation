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
- neovim, tmux, git, curl, wget, age, zsh, mc, btop, ripgrep
- VS Code (via Microsoft apt repo)
- Docker (via official get.docker.com script)
- .NET SDK (latest LTS, installed to `~/.dotnet` via dotnet-install.sh)
- Oh My Zsh
- NVM (latest release, fetched dynamically from GitHub)
- 1Password CLI (`op`, via official apt repo) and desktop app (skipped on WSL2)

Each tool is installed only if not already present — the script is safe to re-run.

---

## Setting up a new machine

### 1. Install prerequisites

```bash
sudo apt-get install -y git
sudo snap install chezmoi --classic
```

**Or without snap** (downloads a binary directly):

```bash
sudo apt-get install -y git
sh -c "$(curl -fsLS get.chezmoi.io)" -- -b ~/.local/bin
```

This places the `chezmoi` binary in `~/.local/bin`. Make sure that directory is in your `$PATH`.

### 2. Clone and apply dotfiles

```bash
chezmoi init --apply https://github.com/forqstudio/workstation.git
```

Chezmoi will prompt for your name and email — these are written to `~/.config/chezmoi/chezmoi.toml` locally and injected into `~/.gitconfig`.

This will:
1. Clone this repo to `~/.local/share/chezmoi/`
2. Apply all dotfiles to your home directory
3. Run the install script (installs all tools listed above)

### 3. Restore your SSH key

Open 1Password, find your **SSH private key**, and restore it:

```bash
install -m 600 /dev/null ~/.ssh/id_ed25519
nano ~/.ssh/id_ed25519   # paste the private key, save and exit
```

Add the corresponding public key to GitHub (**Settings → SSH and GPG keys**).

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

- SSH keys are **not stored in this repo** — restore them from 1Password after applying dotfiles.
- `.chezmoiignore` blocks accidental addition of secrets (`.claude.json`, gnupg, NVM, etc.).
- Personal info (name, email) is injected via chezmoi templates and stored in the local, untracked `~/.config/chezmoi/chezmoi.toml`.
