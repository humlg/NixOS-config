# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Common Commands

```bash
# Rebuild and switch (on the current host)
sudo nixos-rebuild switch --flake .#sauron
sudo nixos-rebuild switch --flake .#nixosvm

# Test a build without switching
sudo nixos-rebuild test --flake .#sauron

# Dry-run to check what would change
sudo nixos-rebuild dry-activate --flake .#sauron

# Update flake inputs
nix flake update

# Check flake for errors
nix flake check

# Search for packages
nix search nixpkgs <package-name>
```

## Repository Structure

```
flake.nix                          # Flake entrypoint — defines all three nixosConfigurations
hosts/
  sauron/                          # Physical desktop (NVIDIA, Hyprland, full package set)
    configuration.nix
    home.nix
    hardware-configuration.nix
    file-system.nix                # Extra data drives + bind mounts for user dirs
  saruman/                         # Laptop (Lenovo IdeaPad, Hyprland, battery mgmt)
    configuration.nix
    home.nix
    hardware-configuration.nix
  nixosvm/                         # NixOS VM (SPICE agent, SSH, minimal packages)
    configuration.nix
    home.nix
    hardware-configuration.nix
modules/
  home/
    common.nix                     # Shared home-manager boilerplate (username, stateVersion, etc.)
  desktop/
    hyprland-desktop.nix           # Main Hyprland HM module (options, packages, services)
    hyprland-config/               # Hyprland config fragments (imported by hyprland-desktop.nix)
      variables.nix                #   $terminal, $fileManager, $menu, etc.
      autostart.nix                #   exec-once entries
      input.nix                    #   Input, gestures, per-device overrides
      appearance.nix               #   General, decoration, animations, layerrules
      window-rules.nix             #   Window rules
      keybinds.nix                 #   All keybinds (core, workspaces, media, etc.)
      layouts.nix                  #   Dwindle, master, misc, workspace rules
    waybar.nix                     # Waybar config (settings + CSS style)
    hyprlock.nix                   # Hyprlock config (lock screen)
    hypridle.nix                   # Hypridle config (idle timers)
    swaync.nix                     # SwayNC notification center
    hyprland-system.nix            # NixOS-level Hyprland (programs.hyprland, portals, pipewire)
    dark-theme.nix                 # GTK/Qt dark theming (Home Manager module)
  bundles/
    general.nix                    # Always-installed user packages (firefox, kitty, git, etc.)
    desktop-apps.nix               # Common desktop apps (discord, vscode, kate, chromium, etc.)
    photography.nix                # Photography tools (gimp, inkscape, darktable, gphoto2)
    3d-printing.nix                # 3D printing/CAD (prusa-slicer, freecad)
    gaming.nix                     # Gaming (Steam, etc.)
    wine.nix                       # Wine support
  programs/
    zsh.nix                        # Zsh shell config (oh-my-zsh, autosuggestions)
  services/
    bluetooth.nix                  # Bluetooth + blueman
  system/
    common.nix                     # Shared NixOS base (bootloader, kernel, CLI tools, fonts)
    locale.nix                     # Timezone, locale (en_US/cs_CZ), keymap (cz)
    nvidia.nix                     # Proprietary NVIDIA driver config
    sddm.nix                      # SDDM (Qt6, astronaut theme, Wayland)
```

## Architecture

- **Flake-based**: `flake.nix` defines three hosts under `nixosConfigurations`. Home Manager is included as a NixOS module (not standalone), so `home-manager` config lives inside each host's `configuration.nix` via `home-manager.users.david = import ./home.nix`.
- **Shared modules** in `modules/` are imported explicitly in each host's `configuration.nix` (NixOS modules) or `home.nix` (Home Manager modules) — there is no auto-import mechanism.
- **Common boilerplate** is in `modules/home/common.nix` (imported by all `home.nix` files) and `modules/system/common.nix` (imported by all `configuration.nix` files).
- **`specialArgs = { inherit inputs; }`** is passed to both NixOS and Home Manager to allow modules to access flake inputs.
- `nixpkgs` tracks `nixos-unstable`. `system.stateVersion` and `home.stateVersion` are both `"25.11"` and must not be changed.
- **Module pattern**: Most modules use `mkEnableOption` / `mkIf` for explicit opt-in. Bundle and service modules are imported in the relevant host config and activated with `enable = true`.

## Secret Management (agenix)

Secrets are encrypted with [age](https://age-encryption.org/) via [agenix](https://github.com/ryantm/agenix). Encrypted `.age` files are committed to the repo — they are safe to be public. Decryption happens automatically at NixOS activation using the host's SSH host private key. Decrypted secrets live in `/run/agenix/` (tmpfs, never written to disk).

### How it works

- `secrets/secrets.nix` — maps each `.age` file to its recipient SSH public keys (host keys + david's user key)
- `secrets/*.age` — encrypted secret files committed to the repo
- `modules/system/secrets.nix` — NixOS module declaring where each secret is placed and with what permissions
- **Shell env vars**: `shell-env.age` decrypts to `/run/agenix/shell-env` and is sourced by zsh at shell start
- **SSH private keys**: declared with a `path =` in `age.secrets` so they land directly at `~/.ssh/<name>`

### Adding a new secret (env var or file)

```bash
# 1. Add an entry to secrets/secrets.nix (choose recipients)
#    "my-token.age".publicKeys = desktops;

# 2. Create (or edit) the encrypted file — opens $EDITOR with plaintext
agenix -e secrets/my-token.age

# 3. Declare it in modules/system/secrets.nix:
#    age.secrets.my-token = {
#      file  = ../../secrets/my-token.age;
#      owner = "david";
#      mode  = "0400";
#      # path = "/home/david/.ssh/myserver";  # only needed for SSH keys / custom paths
#    };

# 4. Stage, commit, rebuild
git add secrets/my-token.age
git commit -m "secrets: add my-token"
sudo nixos-rebuild switch --flake .#<host>
```

For **shell env vars**, put the content in `shell-env.age` (one `export VAR="value"` per line) — they are automatically available in every new shell. For **SSH private keys**, use a dedicated `.age` file with `path = "/home/david/.ssh/..."` and `mode = "0600"`.

### Editing an existing secret

```bash
agenix -e secrets/shell-env.age   # opens decrypted content in $EDITOR, re-encrypts on save
git add secrets/shell-env.age
git commit -m "secrets: update shell-env"
sudo nixos-rebuild switch --flake .#<host>
```

### Removing a secret

```bash
# 1. Remove the age.secrets block from modules/system/secrets.nix
# 2. Delete the .age file
git rm secrets/my-token.age
# 3. Remove the entry from secrets/secrets.nix
git commit -m "secrets: remove my-token"
sudo nixos-rebuild switch --flake .#<host>
```

### Adding secrets to a new host

```bash
# 1. Get the new host's SSH host public key (run on the new host, or via ssh):
cat /etc/ssh/ssh_host_ed25519_key.pub

# 2. Add it to secrets/secrets.nix:
#    newhost = "ssh-ed25519 AAAA... root@newhost";
#    desktops = [ sauron saruman newhost david ];

# 3. Re-encrypt all existing secrets to include the new host as a recipient:
agenix -r secrets/shell-env.age
agenix -r secrets/ssh_myserver.age   # repeat for each .age file

# 4. Add agenix.nixosModules.default to the new host in flake.nix
# 5. Import modules/system/secrets.nix in the new host's configuration.nix
# 6. Stage, commit, rebuild on the new host
git add secrets/
git commit -m "secrets: add newhost as recipient, import secrets module"
sudo nixos-rebuild switch --flake .#newhost
```

### Key locations

| File | Purpose |
|------|---------|
| `secrets/secrets.nix` | Recipient key map — edit when adding/removing hosts |
| `secrets/shell-env.age` | Shell environment variables (API tokens, etc.) |
| `modules/system/secrets.nix` | NixOS declarations for all secrets |
| `/run/agenix/` | Runtime location of decrypted secrets (tmpfs) |

### Sauron TODO

Sauron's SSH host key is not yet in `secrets/secrets.nix` (machine was offline during setup). Once reachable:
```bash
ssh sauron 'cat /etc/ssh/ssh_host_ed25519_key.pub'
# Add the key to secrets/secrets.nix, then:
agenix -r secrets/shell-env.age   # re-encrypt to include sauron
git add secrets/ && git commit -m "secrets: add sauron as recipient"
```

## Workflow Rules

- **Always `git add` new files** after creating them. Nix flakes only see git-tracked files, so new files must be staged immediately or the build will fail with "path does not exist".
- **Always commit changes** after making them. Do **not** push unless explicitly told to.
- **Save learned lessons to this file.** When the user teaches you a workflow rule or preference, add it to this `CLAUDE.md` so it persists across all hosts and sessions.
- **Show the commit message** at the end of every response that results in a git commit, so the user knows a commit was made and what it says.
