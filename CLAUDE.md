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
flake.nix                        # Flake entrypoint — defines both nixosConfigurations
hosts/
  sauron/                        # Physical desktop (NVIDIA, Hyprland, full package set)
    configuration.nix
    home.nix                     # Home Manager config (cursor, dark theme, session vars)
    hardware-configuration.nix
    file-system.nix              # Extra data drives + bind mounts for user dirs
  nixosvm/                       # NixOS VM (SPICE agent, SSH, minimal packages)
    configuration.nix
    home.nix
    hardware-configuration.nix
modules/
  desktop/
    dark-theme.nix               # GTK/Qt dark theming (Home Manager module)
    hyprland.nix                 # Custom Hyprland NixOS module (unused/commented out)
  services/
    bluetooth.nix                # Bluetooth + blueman
  system/
    locale.nix                   # Timezone, locale (en_US/cs_CZ), keymap (cz)
    nvidia.nix                   # Proprietary NVIDIA driver config
    sddm.nix                     # SDDM (Qt6, astronaut theme, Wayland)
```

## Architecture

- **Flake-based**: `flake.nix` defines both hosts under `nixosConfigurations`. Home Manager is included as a NixOS module (not standalone), so `home-manager` config lives inside each host's `configuration.nix` via `home-manager.users.david = import ./home.nix`.
- **Shared modules** in `modules/` are imported explicitly in each host's `configuration.nix` — there is no auto-import mechanism.
- **`specialArgs = { inherit inputs; }`** is passed to both NixOS and Home Manager to allow modules to access flake inputs.
- `nixpkgs` tracks `nixos-unstable`. `system.stateVersion` and `home.stateVersion` are both `"25.11"` and must not be changed.
- The `hyprland.nix` module in `modules/desktop/` is not currently used — Hyprland is configured directly in each host's `configuration.nix`.
