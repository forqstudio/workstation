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

> **Note:** The repo is private, and your SSH key is encrypted inside it — so bootstrapping requires a temporary key. See [Known limitations](#known-limitations) below.

### 1. Install prerequisites

```bash
sudo apt-get install -y git age
sudo snap install chezmoi --classic
```

**Or without snap** (downloads a binary directly):

```bash
sudo apt-get install -y git age
sh -c "$(curl -fsLS get.chezmoi.io)" -- -b ~/.local/bin
```

This places the `chezmoi` binary in `~/.local/bin`. Make sure that directory is in your `$PATH`.

### 2. Install 1Password desktop

Download and install the [1Password desktop app](https://1password.com/downloads/linux/) manually (`.deb` package). Sign in with your email, password, and YubiKey.

> The 1Password CLI (`op`) does not support YubiKey 2FA in the terminal. The desktop app must be installed first to access your secrets.

### 3. Restore the age key

Open 1Password desktop, find the **Chezmoi Age Key** secure note, and copy its contents:

```bash
mkdir -p ~/.config/chezmoi
nano ~/.config/chezmoi/key.txt   # paste the key, save and exit
chmod 600 ~/.config/chezmoi/key.txt
```

The key looks like:
```
# created: ...
# public key: age1...
AGE-SECRET-KEY-1...
```

### 4. Create a temporary SSH key for GitHub

Your real SSH key is age-encrypted in the repo (safe to store in git, but requires the age key to decrypt). Until chezmoi has applied it, you need a throwaway key just to clone:

```bash
ssh-keygen -t ed25519 -f ~/.ssh/id_ed25519_tmp -N "" -C "bootstrap-tmp"
cat ~/.ssh/id_ed25519_tmp.pub
```

Go to **GitHub → Settings → SSH and GPG keys → New SSH key**, paste the public key, and save.

### 5. Clone and apply dotfiles

```bash
GIT_SSH_COMMAND="ssh -i ~/.ssh/id_ed25519_tmp" chezmoi init --apply git@github.com:USER/REPO.git
```

This will:
1. Clone this repo to `~/.local/share/chezmoi/`
2. Decrypt and restore your real SSH key to `~/.ssh/id_ed25519`
3. Apply all dotfiles to your home directory
4. Run the install script (installs all tools listed above)

### 6. Remove the temporary SSH key

Delete the throwaway key from GitHub (**Settings → SSH and GPG keys**) and locally:

```bash
rm ~/.ssh/id_ed25519_tmp ~/.ssh/id_ed25519_tmp.pub
```

### 7. Post-setup

Log out and back in (or run `newgrp docker`) for Docker group membership to take effect.

---

## Known limitations

The current setup has a bootstrap dependency problem:

- The repo is **private** → requires SSH auth to clone
- Your **SSH key is inside the repo** (age-encrypted) → can't use it before cloning
- The **age key lives in 1Password** → requires 1Password desktop installed first
- The **1Password CLI can't sign in** with a YubiKey in the terminal → desktop app must be installed manually

This creates a chain of manual steps every time a new machine is set up. A future improvement would be a bootstrap script that automates steps 1–6 using `op` CLI (connected to the signed-in desktop app) and GitHub CLI for HTTPS-based cloning.

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
