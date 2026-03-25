# dotfiles

Personal dotfiles managed with [chezmoi](https://www.chezmoi.io/).

> **This repo is private.** It contains your email address and encrypted SSH keys.

---

## What's managed

| File | Description |
|------|-------------|
| `~/.zshrc` | Zsh config (Oh My Zsh, robbyrussell theme) |
| `~/.bashrc` | Bash config (NVM, standard aliases) |
| `~/.profile` | Login shell init |
| `~/.bash_logout` | Bash logout script |
| `~/.gitconfig` | Git user name and email |
| `~/.config/git/ignore` | Global gitignore |
| `~/.config/Code/User/keybindings.json` | VS Code keybindings |
| `~/.config/btop/btop.conf` | btop system monitor config |
| `~/.ssh/id_ed25519` | SSH private key (age-encrypted with chezmoi `--encrypt`) |
| `~/.ssh/id_ed25519.pub` | SSH public key (plaintext) |

The `run_once_install-packages.sh` script runs automatically on first `chezmoi apply` and installs:
- neovim, tmux, git, curl, wget, age, zsh
- VS Code (via Microsoft apt repo)
- Docker (via official get.docker.com script)
- .NET SDK (latest LTS, installed to `~/.dotnet` via dotnet-install.sh)
- Oh My Zsh
- NVM (latest release, fetched dynamically from GitHub)
- 1Password CLI (`op`, via official apt repo) and desktop app (skipped on WSL2)

Each tool is installed only if not already present — the script is safe to re-run.

---

## Setting up a new machine

### 1. Prerequisites

```bash
sudo apt-get install -y git
sudo snap install chezmoi --classic
```

### 2. Restore the age key

The age key is required to decrypt the SSH private key. Copy it from your password manager:

```bash
mkdir -p ~/.config/chezmoi
nano ~/.config/chezmoi/key.txt   # paste the key, save
chmod 600 ~/.config/chezmoi/key.txt
```

The key looks like:
```
# created: ...
# public key: age1...
AGE-SECRET-KEY-1...
```

### 3. Apply dotfiles

```bash
chezmoi init --apply <your-git-repo-url>
```

This will:
1. Clone this repo to `~/.local/share/chezmoi/`
2. Apply all dotfiles to your home directory
3. Decrypt and restore your SSH key
4. Run the install script (installs all tools listed above)

### 4. Post-setup

After the install script runs, log out and back in (or `newgrp docker`) for Docker group membership to take effect.

---

## Day-to-day usage

```bash
# Edit a tracked dotfile
chezmoi edit ~/.zshrc

# See what would change
chezmoi diff

# Apply changes from source to home
chezmoi apply

# Add a new file to track
chezmoi add ~/.config/some/file

# Add a file with encryption (for secrets)
chezmoi add --encrypt ~/.some-secret-file

# Commit changes
cd ~/.local/share/chezmoi && git add -A && git commit -m "..."
```

---

## SSH key storage

The SSH files live in `private_dot_ssh/` in this repo:

| Source file | Destination | Notes |
|---|---|---|
| `private_dot_ssh/id_ed25519.pub` | `~/.ssh/id_ed25519.pub` | Plaintext — safe to commit |
| `private_dot_ssh/encrypted_private_id_ed25519.age` | `~/.ssh/id_ed25519` | Encrypted with age before committing |

The `private_` prefix tells chezmoi to apply `chmod 600` to the destination files (required for SSH to accept the private key).

On `chezmoi apply`, the `.age` file is decrypted using `~/.config/chezmoi/key.txt` and written to `~/.ssh/id_ed25519`.

To re-add your SSH keys after rotating them:

```bash
chezmoi add ~/.ssh/id_ed25519.pub
chezmoi add --encrypt ~/.ssh/id_ed25519
```

---

## Security

- The **age private key** (`~/.config/chezmoi/key.txt`) is **never tracked** in this repo. Back it up in a password manager. Without it, the encrypted SSH key cannot be recovered.
- `.chezmoiignore` blocks accidental addition of secrets (`.claude.json`, gnupg, NVM, etc.).
- Keep this repository **private** — it contains your email and public SSH key.
