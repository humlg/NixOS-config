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
  sauron/                          # Physical desktop (AMD Ryzen 7 5800X3D + RX 9070 XT, Hyprland, full package set)
    configuration.nix
    home.nix
    hardware-configuration.nix
    file-system.nix                # Extra data drives (/mnt/data1, /mnt/data2) + bind mounts for user dirs
  saruman/                         # Laptop (Lenovo IdeaPad 14ASP9, Hyprland, battery mgmt)
    configuration.nix
    home.nix
    hardware-configuration.nix
    file-system.nix                # On-demand NAS NFS mount at ~/nas (automount, soft, idle-timeout)
  nixosvm/                         # NixOS VM (SPICE agent, SSH, minimal packages)
    configuration.nix
    home.nix
    hardware-configuration.nix
modules/
  home/
    common.nix                     # Shared home-manager boilerplate (username, stateVersion, etc.)
  desktop/
    hyprland-desktop.nix           # Main Hyprland HM module (options, packages, services)
    hyprland-config/               # Legacy hyprlang config fragments — kept in sync by hand with hyprland-config-lua/ below (see maintenance.md #16)
      variables.nix                #   $terminal, $fileManager, $menu, etc.
      autostart.nix                #   exec-once entries
      input.nix                    #   Input, gestures, per-device overrides
      appearance.nix               #   General, decoration, animations, layerrules
      window-rules.nix             #   Window rules
      keybinds.nix                 #   All keybinds (core, workspaces, media, etc.)
      layouts.nix                  #   Dwindle, master, misc, workspace rules
    hyprland-config-lua/           # Active Lua config fragments — all three hosts set useLuaConfig = true
      variables.nix
      autostart.nix
      input.nix
      appearance.nix
      window-rules.nix
      keybinds.nix
      layouts.nix
    hyprland-system.nix            # NixOS-level Hyprland (programs.hyprland, portals, pipewire)
    waybar.nix                     # Waybar config — orphaned, kept intentionally as an AGS fallback (see maintenance.md)
    ags.nix                        # AGS v2 (Astal/TypeScript) status bar HM module — the active bar; config in ags-config/*.tsx
    anyrun.nix                     # Anyrun launcher (applications/websearch/rink plugins)
    hyprlock.nix                   # Hyprlock config (lock screen)
    hypridle.nix                   # Hypridle config (idle timers)
    swaync.nix                     # SwayNC notification center
    dark-theme.nix                 # GTK/Qt dark theming (Home Manager module)
    default-apps.nix               # xdg-mime default application associations
  bundles/
    general.nix                    # Always-installed user packages (firefox, kitty, git, etc.)
    desktop-apps.nix               # Common desktop apps (discord, vscode, kate, chromium, etc.)
    photography.nix                # Photography tools (gimp, inkscape, darktable, gphoto2, DaVinci Resolve)
    3d-printing.nix                # 3D printing/CAD (prusa-slicer)
    gaming.nix                     # Gaming (Steam, gamemode, mangohud, lsfg-vk)
    wine.nix                       # Wine support
    yg-work.nix                    # Work-specific packages (Slack, Teams, Todoist, MQTT tools) — saruman only
  programs/
    zsh.nix                        # Zsh shell config (oh-my-zsh, autosuggestions)
    git.nix                        # Git identity + defaults (rebase pulls, zdiff3, rerere)
    vim.nix                        # Vim settings + wallust color sourcing
    kitty.nix                      # Kitty terminal settings + static "Darkside" theme (deliberately not wallust-driven — wallpaper colors were inconsistently readable)
    thunar.nix                     # Thunar file manager + thumbnailer backends
    btop.nix                       # btop with wallust-generated theme
    cava.nix                       # cava audio visualizer with wallust-generated theme
    fastfetch.nix                  # fastfetch system-info banner
    claude-code.nix                # Claude Code settings (permissions, hooks, notification sounds)
    ssh-keys.nix                   # SSH client config (github-huml-yg host alias)
    mullvad.nix                    # Mullvad VPN (GUI app, CLI, system daemon) — opt-in via custom.mullvad.enable; used by sauron + saruman
    transmission.nix               # Transmission (Qt) wrapped (symlinkJoin + makeWrapper) so its bin/transmission-qt binds all peer sockets to Mullvad's wg0-mullvad tunnel IP on every launch and refuses to start if the tunnel is down — opt-in via custom.transmission-vpn.enable; used by sauron + saruman
    webapps.nix                    # Chromium-based webapp launchers (YT Music, Claude, ChatGPT)
    zen-browser.nix                # Zen Browser + DuckDuckGo default search policy
    winboat.nix                    # Windows-in-a-box via winboat — orphaned, Docker wiring incomplete (see maintenance.md #13)
  services/
    bluetooth.nix                  # Bluetooth + blueman
    kvm.nix                        # libvirtd/QEMU + virt-manager (KVM virtualization)
    darkproject-keyboard.nix       # udev rules for Dark Project keyboards (WebHID/WebUSB access for their web configurator) — used by saruman
    megacmd.nix                    # MEGA sync daemon — orphaned, not imported by any host (see maintenance.md #14)
    ollama.nix                     # Ollama (ROCm build) + oterm TUI
    sunshine-moonlight.nix         # Sunshine (streaming host) / Moonlight (streaming client) toggle
  system/
    common.nix                     # Shared NixOS base (bootloader, kernel, CLI tools, fonts)
    locale.nix                     # Timezone, locale (en_US/cs_CZ), keymap (cz)
    nvidia.nix                     # Proprietary NVIDIA driver config — orphaned, no host imports it (see maintenance.md #4)
    amd-gpu.nix                    # AMD GPU config (amdgpu, ROCm) — used by sauron
    sddm.nix                       # SDDM (Qt6, astronaut theme, Wayland)
    secrets.nix                    # agenix age.secrets declarations
    ssh.nix                        # sshd + MOTD banner + /etc/hosts entries for sauron/saruman
    network-tools.nix              # Network troubleshooting tools bundle (nmap, wireshark, mtr, etc.)
    generation-cleanup.nix         # Scheduled NixOS generation pruning + bootloader entry limit
overlays/
  davinci-resolve.nix               # Overrides pkgs.davinci-resolve to the v21.0b1 beta (see maintenance.md #1)
  davinci-resolve-package.nix       # Local davinci-resolve package.nix backing the overlay above
  patool-no-check.nix               # Disables patool's sandboxed test suite (see maintenance.md #3)
  rawtherapee-dev.nix               # Rebuilds rawtherapee from a dev commit to fix a startup crash (see maintenance.md #2)
secrets/
  secrets.nix                       # agenix recipient key map
maintenance.md                      # Log of temporary fixes/overlays/pins and their removal conditions — keep current (see Workflow Rules)
```

## Hardware Quick Reference

| Host | CPU | GPU | WiFi | Notable quirks |
|------|-----|-----|------|-----------------|
| sauron | AMD Ryzen 7 5800X3D | AMD RX 9070 XT (RDNA4, `amdgpu`) | — (wired, `enp9s0`, WoL enabled) | RDNA4 not yet officially supported by ROCm — `HSA_OVERRIDE_GFX_VERSION=12.0.0` in `amd-gpu.nix`. NVMe has slow init — root device timeout raised to 300s, `nvme` forced in initrd. Previously NVIDIA; swapped to AMD (see `maintenance.md` item 4). |
| saruman | AMD Ryzen (mobile), Lenovo IdeaPad 14ASP9 / Yoga Pro 7 14ASP9 | AMD Radeon 880M/890M iGPU (RDNA 3.5, DCN 3.5) | MediaTek MT7922 (`mt7921e`) | RDNA 3.5 not yet officially supported by ROCm — `HSA_OVERRIDE_GFX_VERSION=11.0.0`. s2idle sleep/resume hang: upstream kernel bug [#219445](https://bugzilla.kernel.org/show_bug.cgi?id=219445) (exact same laptop model), bisected to a DCN3.5+ IPS-before-D3cold regression; `amdgpu.dcdebugmask=0x800` (`DC_DISABLE_IPS`) targets it but **confirmed 2026-07-22 not to fix the hang alone**. Worked around by hibernating on lid close (`services.logind.settings.Login.HandleLidSwitch`/`HandleLidSwitchExternalPower`, `boot.resumeDevice` set to the LUKS swap partition) rather than fixing s2idle itself — must be set via `services.logind`, not a Hyprland compositor keybind, since logind's own native lid handler fires independently and races any compositor-level bind. **Temporarily reverted to plain `"suspend"` on 2026-08-02** to retest whether a recent nixpkgs/kernel update fixed the underlying s2idle hang — revert back to `"hibernate"` if it recurs. `mt7921e disable_aspm=1` kept as a harmless secondary mitigation (see `maintenance.md` item 7). `ucsi_acpi` blacklist tried and removed — confirmed not the cause of the sleep hang, and it disabled USB-C PD negotiation entirely, so it's loaded again. LUKS-encrypted swap (29.9GB, exceeds 27GiB RAM). BIOS PSCN23WW. |
| nixosvm | virtualized (SPICE guest) | virtualized | — | Minimal package set, SPICE agent only — not a physical host. |

Keep this table current: whenever you discover or change a hardware fact (a chip model, a quirk, a workaround tied to specific silicon) while working on a host, update its row here in the same commit — don't let it drift the way the sauron NVIDIA→AMD description did.

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

## Workflow Rules

- **Never run `sudo` commands directly** (including `nixos-rebuild switch/test`). Ask the user what to run and whether you need the output — this is their real system, not a sandbox.
- **Never use `hyprctl` (or similar) to move, close, or otherwise manipulate windows on the user's live desktop session** for testing purposes. It's their actual running session, not a disposable test environment.
- **Test before `switch`, not after.** Before recommending or describing a `nixos-rebuild switch`, prefer walking through `nixos-rebuild dry-activate` (or `test`, if the user runs it themselves) first, and mention what it would change. Don't jump straight to `switch` as the first suggested step.
- **Flag orphaned modules, don't silently delete them.** If you find a module under `modules/` that no host imports, say so and ask whether to wire it up, keep it as intentional (e.g. `waybar.nix` — kept on purpose as an AGS fallback, see `maintenance.md`), or delete it. Don't assume unused means safe to remove.
- **Keep this file in sync with the changes you make, in the same commit.** CLAUDE.md is documentation, not a snapshot — it must never fall behind the repo it describes. Concretely, whenever you:
  - **add, remove, rename, or move a `.nix` file (or move a module between imported/orphaned status)** — update the Repository Structure tree.
  - **discover or change a hardware fact for a host** (a chip model, a quirk, a workaround tied to specific silicon) — update its row in the Hardware Quick Reference table.
  - **add, resolve, or remove a temporary fix, overlay, pin, or workaround** — update `maintenance.md` (see the rule below).
  - **change how secrets are managed, added, or structured** — update the Secret Management section.
  - **learn a new durable workflow rule or preference from the user** — add it under Workflow Rules (see below).

  If you're not sure whether a change is "structural" enough to warrant a doc update, err on the side of updating it — a stale tree (like the NVIDIA/AMD drift that prompted this rule) is worse than a slightly over-eager edit. Do this proactively, without waiting to be asked.
- **Document new bodges in `maintenance.md`.** Whenever you add a temporary fix, overlay, version pin, upstream-bug workaround, or anything else that should eventually be removed once some external condition changes (a nixpkgs update, an upstream fix landing, hardware support maturing, etc.), add an entry to `maintenance.md` in the same commit: what it does, why it's needed, and the condition under which it can be removed. If a change you make resolves or removes an existing bodge, update or delete its entry there too — don't let it go stale like the old "Sauron TODO" did.
- **Always `git add` new files** after creating them. Nix flakes only see git-tracked files, so new files must be staged immediately or the build will fail with "path does not exist".
- **Always commit changes** after making them. Do **not** push unless explicitly told to.
- **Save learned lessons to this file.** When the user teaches you a workflow rule or preference, add it to this `CLAUDE.md` so it persists across all hosts and sessions.
- **Show the commit message** at the end of every response that results in a git commit, so the user knows a commit was made and what it says.
