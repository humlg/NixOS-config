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
    hyprland-desktop.nix           # Main Hyprland HM module (keybinds, window rules, autostart)
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

## Workflow Rules

- **Always `git add` new files** after creating them. Nix flakes only see git-tracked files, so new files must be staged immediately or the build will fail with "path does not exist".
- **Always commit changes** after making them. Do **not** push unless explicitly told to.
- **Save learned lessons to this file.** When the user teaches you a workflow rule or preference, add it to this `CLAUDE.md` so it persists across all hosts and sessions.
- **Show the commit message** at the end of every response that results in a git commit, so the user knows a commit was made and what it says.
