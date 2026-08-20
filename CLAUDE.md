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
    hyprland-config/               # Legacy hyprlang config fragments — frozen/unmaintained as of 2026-08-19; no longer kept in sync with hyprland-config-lua/ below. New config work goes into hyprland-config-lua/ only (see maintenance.md #16)
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
    hypridle.nix                   # Hypridle config (idle timers). Dispatchers here must use the external-Lua form (`hyprctl dispatch 'hl.dsp.dpms({ action = "on" })'`) — under the Lua config hyprctl feeds its argument to Lua, so the bare hyprlang spelling fails to parse and hypridle never notices. Gated `cfg.enable && !cfg.useNoctalia` — fully inert on saruman as of 2026-08-19, Noctalia's own idle service (configured outside Nix) now owns dim/lock/dpms/sleep there (see maintenance.md item 19, Phase E)
    swaync.nix                     # SwayNC notification center
    noctalia.nix                   # Noctalia desktop shell HM module — pilot only (desktop.hyprland-desktop.useNoctalia, saruman-only as of 2026-08-19); AGS/swaync/hypridle are now gated off under it (Phase C/E) and waypaper's config-seed too, hyprlock stays enabled as a one-line rollback; imports inputs.noctalia.homeModules.default. Noctalia's own idle service (its settings UI, not Nix-managed) now owns dim/lock/dpms/sleep on saruman instead of hypridle
    noctalia-system.nix            # NixOS-level counterpart (custom.noctalia.enable) — imports inputs.noctalia.nixosModules.default, sets programs.noctalia.recommendedServices.enable (which default-enables power-profiles-daemon, needed for Noctalia's power-profile widget) — saruman runs power-profiles-daemon instead of TLP as of 2026-08-19, see maintenance.md item 20
    dark-theme.nix                 # GTK/Qt dark theming (Home Manager module)
    default-apps.nix               # xdg-mime default application associations
  bundles/
    general.nix                    # Always-installed user packages (firefox, kitty, git, etc.)
    desktop-apps.nix               # Common desktop apps (discord, vscode, kate, chromium, etc.)
    photography.nix                # Photography tools (gimp, inkscape, darktable, gphoto2, DaVinci Resolve)
    3d-printing.nix                # 3D printing/CAD (prusa-slicer)
    gaming.nix                     # Gaming (Steam, gamemode, mangohud, lsfg-vk)
    ham-radio.nix                  # Amateur radio: sdrpp, wsjtx, hamlib + RTL-SDR udev rules (plugdev/dialout groups) — saruman only
    wine.nix                       # Wine support
    yg-work.nix                    # Work-specific packages (Slack, Teams, Todoist, MQTT tools) — Home Manager half of the yg-work bundle — saruman only
    yg-work-system.nix             # System (NixOS) half of the yg-work bundle: NetworkManager-openvpn plugin + agenix secrets for the 1NCE cellular IoT VPN — shares the bundles.yg-work.enable option name with yg-work.nix by convention but is a separate NixOS-tree option, toggled independently in configuration.nix — saruman only
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
    lid-undock-hibernate.nix       # Sleeps when the last external display is unplugged while the lid is already shut — closes the gap left by HandleLidSwitchDocked = "ignore" (logind only evaluates the lid action at the instant the lid event fires, never re-checks on undock) — opt-in via custom.lid-undock-hibernate.enable; the action is the sleepCommand option (defaults to hibernate, set to plain suspend on saruman — the "hibernate" in the file/option name is historical) — saruman only
    megacmd.nix                    # MEGA sync daemon — orphaned, not imported by any host (see maintenance.md #14)
    ollama.nix                     # Ollama (ROCm build) + oterm TUI
    sunshine-moonlight.nix         # Sunshine (streaming host) / Moonlight (streaming client) toggle
    wivrn.nix                      # WiVRn wireless VR streaming server (Meta Quest 2), custom.wivrn.enable — used by sauron
  system/
    amdgpu-s2idle-patch.nix        # Builds a locally-patched kernel dropping amdgpu's DCN3.5+ "IPS before D3cold" s2idle step (the actual fix for the saruman resume hang) + optional LZ4 hibernate compression — opt-in via custom.amdgpu-s2idle-patch.enable — saruman only (see maintenance.md #7)
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
patches/
  amdgpu-no-idle-opt-on-s2idle.patch # Kernel patch removing the two lines f6098641d3e1e4 added to amdgpu's dm_suspend() — applied by modules/system/amdgpu-s2idle-patch.nix (see maintenance.md #7)
secrets/
  secrets.nix                       # agenix recipient key map
maintenance.md                      # Log of temporary fixes/overlays/pins and their removal conditions — keep current (see Workflow Rules)
```

## Hardware Quick Reference

| Host | CPU | GPU | WiFi | Notable quirks |
|------|-----|-----|------|-----------------|
| sauron | AMD Ryzen 7 5800X3D | AMD RX 9070 XT (RDNA4, `amdgpu`) | — (wired, `enp9s0`, WoL enabled) | RDNA4 not yet officially supported by ROCm — `HSA_OVERRIDE_GFX_VERSION=12.0.0` in `amd-gpu.nix`. NVMe has slow init — root device timeout raised to 300s, `nvme` forced in initrd. Previously NVIDIA; swapped to AMD (see `maintenance.md` item 4). |
| saruman | AMD Ryzen AI 9 365 (Strix Point, 10C/20T), Lenovo IdeaPad 14ASP9 / Yoga Pro 7 14ASP9 | AMD Radeon 880M iGPU (RDNA 3.5, DCN 3.5) | MediaTek MT7922 (`mt7921e`) | RDNA 3.5 not yet officially supported by ROCm — `HSA_OVERRIDE_GFX_VERSION=11.0.0`. **s2idle sleep/resume hang — mitigated 2026-08-16 by a local kernel patch (rate reduced, not eliminated); third plain-suspend retest underway 2026-08-19, after a 2026-08-18 direct-hibernate interlude.** Upstream kernel bug [#219445](https://bugzilla.kernel.org/show_bug.cgi?id=219445) (exact same laptop model) bisected it to `f6098641d3e1e4` ("drm/amd/display: fix s2idle entry for DCN3.5+"), which makes `dm_suspend()` force the display block into IPS before D3cold. The bisect was right; the original mitigation was aimed at the wrong field. `amdgpu.dcdebugmask=0x800` (`DC_DISABLE_IPS`) sets `dc->config.disable_ips`, while the offending call is guarded by `dc->caps.ips_support` — a hardware capability bit — so the parameter never touched that code path, which is why it **failed to fix the hang on 2026-07-22**. The fix is `patches/amdgpu-no-idle-opt-on-s2idle.patch` (applied via `custom.amdgpu-s2idle-patch.enable`, `modules/system/amdgpu-s2idle-patch.nix`), deleting those two lines — the same removal independently confirmed to fix identical hangs on Ryzen AI 7 350 / AI 5 340 (same DCN3.5 block) in the amd-gfx "Radeon 840M/860M bisected suspend crash" thread. Trade-off, accepted: kernel builds locally on every version bump (~15–25 min), and the part no longer reaches its deepest hardware sleep, so suspended drain is higher. Hang signature for future reference: journal's last line is `PM: suspend entry (s2idle)` with no `PM: suspend exit`; it needs >10 min of sleep residency, so short `rtcwake` cycles never reproduce it. **Looked validated 2026-08-16** — 7 s, 22 min and 60 min s2idle cycles all resumed cleanly, done awake and watched over ~1.5h — **but the next two unattended overnight sleeps (2026-08-17) both hung** the same way: `PM: suspend entry (s2idle)` as the last journal line, no exit, machine dead until the next hard-boot, 2 for 2. So the patch reduces the hang rate (previously ~22% of ~36 suspends) but does not eliminate it, and a short watched soak isn't a reliable predictor of unattended behavior. **A second, separate bug also affects hibernation on this machine:** hibernate *resume* can die in TTM — `list_add corruption` → `ttm_bo_populate` → `ttm_resource_add_bulk_move`, wedging the GPU (hyprlock draws one frame, then no VT switch, hard power-off needed) — seen exactly once, via `suspend-then-hibernate` with LZ4 compression: the 60-min `HibernateDelaySec` silently resumed the machine from s2idle internally before converting to hibernate, and *that* resumed-then-hibernated sequence is what crashed on the next restore. Direct hibernate (straight from a fully awake state, never going through s2idle first) ran clean for 9/9 cycles including a 7-day hibernation during 2026-07-24 → 08-02, before this crash was ever seen. **Decision (2026-08-18): direct hibernate restored on every sleep path**, then **reverted 2026-08-19 back to plain suspend on every path, user-requested, for a third data-gathering pass.** This is the same policy that already failed twice — a 22% hang rate over ~36 attempts pre-patch (2026-08-02 → 08-14), then 2/2 unattended overnight hangs even with the kernel patch applied (2026-08-17 → 08-18) — so treat a recurrence as expected-until-proven-otherwise, not a surprise. `HandlePowerKey`, `HandleLidSwitch`, `HandleLidSwitchExternalPower` (`hosts/saruman/configuration.nix`), `desktop.hyprland-desktop.sleepCommand` (`hosts/saruman/home.nix`), and `custom.lid-undock-hibernate.sleepCommand` all call plain `systemctl suspend` again. The amdgpu kernel patch stays enabled since it may still reduce the hang rate even though it doesn't eliminate it; `boot.resumeDevice` and the LUKS swap are kept so hibernate can be restored without an initrd change. **Not yet soaked** — watch especially for unattended/overnight hangs, since that's exactly where the prior two attempts failed despite short watched cycles looking clean; if it recurs, revert to the 2026-08-18 direct-hibernate settings (see `maintenance.md` item 7, bullet 8, for the exact values and open questions). **First unattended overnight sleep under this retest woke cleanly (2026-08-20)** — ~15% battery drain (eyeballed, not a measured `energy_now` delta yet), one data point and not yet a trend given both prior attempts also had clean-looking stretches before failing (see `maintenance.md` item 7, bullet 9). `boot.resumeDevice` points at the LUKS swap partition for the resume-from-hibernate path. Lid-switch handling must be set via `services.logind`, never a Hyprland compositor keybind — logind's own native lid handler fires independently and races any compositor-level bind. Lid close **with an external monitor attached** is `HandleLidSwitchDocked = "ignore"` so the laptop stays usable lid-shut on the Iiyama — paired with `custom.lid-undock-hibernate.enable`, since logind evaluates the lid action only at the instant the lid event fires and never re-checks on undock. `mt7921e disable_aspm=1` kept as a harmless secondary mitigation (see `maintenance.md` item 7). `ucsi_acpi` blacklist tried and removed — confirmed not the cause of the sleep hang, and it disabled USB-C PD negotiation entirely, so it's loaded again. LUKS-encrypted swap (29.9GB, exceeds 27GiB RAM); `CONFIG_CRYPTO_LZO=y` is what the hibernate image now uses (`hibernate.compressor=lzo`, the kernel's own default). TPM 2.0 present but unused — LUKS unlock is passphrase-only by choice. BIOS PSCN23WW. |
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
| `secrets/1nce-vpn.ovpn.age` | 1NCE cellular IoT OpenVPN client profile (embedded CA/cert/key) — saruman only |
| `secrets/1nce-vpn-credentials.age` | 1NCE VPN auth-user-pass file (username + token) — saruman only |
| `modules/system/secrets.nix` | NixOS declarations for secrets shared/common across hosts |
| `/run/agenix/` | Runtime location of decrypted secrets (tmpfs) |

Not all `age.secrets` live in `modules/system/secrets.nix` — a host- or bundle-specific secret (like the 1NCE VPN's) can be declared directly inside its own opt-in module (see `modules/bundles/yg-work-system.nix`) so it's only decrypted on hosts that enable that module.

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
- **The "sleep inhibit" toggle gates idle timeouts only — never lid close.** The swaync toggle (`modules/desktop/swaync.nix`) creates `$XDG_RUNTIME_DIR/hypridle-idle-inhibited`, and the *only* thing that may consult it is hypridle's idle-timeout listeners (dim/lock/dpms/sleep). Closing the lid is an explicit "I am done" signal and must always sleep regardless of the toggle — that's also how logind itself behaves (`LidSwitchIgnoreInhibited` defaults to `yes`). Don't add an inhibit check to any lid-driven sleep path, including `modules/services/lid-undock-hibernate.nix`.
- **Save learned lessons to this file.** When the user teaches you a workflow rule or preference, add it to this `CLAUDE.md` so it persists across all hosts and sessions.
- **Show the commit message** at the end of every response that results in a git commit, so the user knows a commit was made and what it says.
