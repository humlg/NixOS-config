# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Common Commands

```bash
# Rebuild and switch (on the current host)
sudo nixos-rebuild switch --flake .#sauron

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
flake.nix                          # Flake entrypoint — defines both nixosConfigurations
hosts/
  sauron/                          # Physical desktop (AMD Ryzen 7 5800X3D + RX 9060 XT, Hyprland, full package set)
    configuration.nix
    home.nix
    hardware-configuration.nix
    file-system.nix                # Extra data drives (/mnt/data1, /mnt/data2) + bind mounts for user dirs
  saruman/                         # Laptop (Lenovo IdeaPad 14ASP9, Hyprland, battery mgmt)
    configuration.nix
    home.nix
    hardware-configuration.nix
    file-system.nix                # On-demand NAS NFS mount at ~/nas (automount, soft, idle-timeout)
modules/                            # Full module map + what each file does: docs/architecture.md
  nixos/                             # NixOS modules, flat (system-/desktop-/bundle-/program-/service- prefix)
    system-common.nix … system-sddm.nix   # Base OS config, split into focused files, aggregated by system-common.nix
    desktop-hyprland.nix, desktop-noctalia.nix
    bundle-*.nix                      # 3d-printing, gaming, ham-radio, photography, wine, workstation, yg-work
    program-*.nix                     # mkrepo, mullvad, thunar, winboat, zen-browser, zsh
    service-*.nix                     # bluetooth, darkproject-keyboard, kvm, lid-undock-hibernate, ollama, sunshine, moonlight, tailscale, wireguard-saruman, wivrn
  home/                             # Home Manager modules, flat, imported only from hosts/*/home.nix
    common.nix                       # Pure HM boilerplate — unprefixed, stays at the home/ root
    ags-config/, noctalia-settings-seed.toml   # Flat sibling data owned by desktop-ags.nix / desktop-noctalia.nix
    desktop-hyprland-desktop.nix + desktop-hyprland-desktop/{hyprland-config,hyprland-config-lua}/   # Dual config trees — docs/architecture.md
    desktop-*.nix                     # ags, anyrun, cursor-theme, dark-theme, default-apps, hypr-dynamic-cursors, hypridle, hyprlock, noctalia, swaync, waybar
    bundle-*.nix                      # desktop-apps, general, workstation, yg-work
    program-*.nix                     # btop, cava, claude-code, fastfetch, git, jellyfin-media-player, kitty, neovim, ssh-keys, thunar(+vault), transmission, vim, webapps, yg-discover
    service-megacmd.nix               # orphaned
overlays/                           # Nixpkgs overrides, registered in flake.nix — docs/architecture.md
patches/                             # Kernel patches applied by modules/nixos/system-*.nix — docs/maintenance.md
secrets/
  secrets.nix                       # agenix recipient key map — full guide: docs/secrets.md
docs/
  architecture.md                   # Repo map, module categories, design decisions & gotchas
  maintenance.md                    # Log of temporary fixes/overlays/pins and their removal conditions — keep current (see Workflow Rules)
  secrets.md                        # Secret management guide
```

**Option rename (2026-10-05):** `custom.sunshine-moonlight.{enable,autoStart,enableMoonlight}` was split into `custom.sunshine.{enable,autoStart}` (streaming host) and `custom.moonlight.enable` (streaming client), matching the `service-sunshine.nix`/`service-moonlight.nix` file split above.

## Hardware Quick Reference

| Host | CPU | GPU | WiFi | Notable quirks |
|------|-----|-----|------|-----------------|
| sauron | AMD Ryzen 7 5800X3D | RX 9060 XT (RDNA4, Navi 44) | wired, WoL | ROCm GFX override (`12.0.0`). Slow NVMe init → 300s timeout. Ex-NVIDIA; GPU corrected 2026-10-11 from a misidentified 9070 XT (`docs/maintenance.md` #4). |
| saruman | AMD Ryzen AI 9 365 (Strix Point), Lenovo IdeaPad 14ASP9 | Radeon 880M iGPU (RDNA3.5) | MT7922 (`mt7921e`) | ROCm GFX override (`11.0.0`). TPM present but unused (passphrase-only LUKS). s2idle sleep hang, open (`docs/maintenance.md` #7). HDMI SCDC fix, re-enabled 2026-10-16 and confirmed fixed (#23). Top USB-C port carries no DP video, still open (#24). Backlight curve fix (#25). |
| nixosvm | virtualized (SPICE guest) | virtualized | — | Minimal package set, SPICE agent only — not a physical host. |

Keep this table current: whenever you discover or change a hardware fact (a chip model, a quirk, a workaround tied to specific silicon) while working on a host, update its row here in the same commit. Full history and diagnosis for each quirk lives in `docs/maintenance.md`, linked by item number — don't duplicate the narrative here, just the fact and the pointer.

## Architecture

- **Flake-based**: `flake.nix` defines two hosts under `nixosConfigurations`. Home Manager is included as a NixOS module (not standalone), so `home-manager` config lives inside each host's `configuration.nix` via `home-manager.users.david = import ./home.nix`.
- **Shared modules** in `modules/` are split at the top level by module system — `modules/nixos/` (imported only from `hosts/*/configuration.nix`) and `modules/home/` (imported only from `hosts/*/home.nix`). Both are flat; the topic lives in the filename prefix (`system-`, `desktop-`, `bundle-`, `program-`, `service-`), not a subfolder. Location alone tells you whether a module is NixOS or Home Manager; there is no auto-import mechanism, so each host file still lists what it needs explicitly. Full module map: `docs/architecture.md`.
- **Common boilerplate** is in `modules/home/common.nix` (imported by all `home.nix` files) and `modules/nixos/system-common.nix` (imported by all `configuration.nix` files).
- **`specialArgs = { inherit inputs; }`** is passed to both NixOS and Home Manager to allow modules to access flake inputs.
- `nixpkgs` tracks `nixos-unstable`. `system.stateVersion` and `home.stateVersion` are both `"25.11"` and must not be changed.
- **Module pattern**: Most modules use `mkEnableOption` / `mkIf` for explicit opt-in. Bundle and service modules are imported in the relevant host config and activated with `enable = true`.

## Secret Management (agenix)

Secrets are encrypted with [age](https://age-encryption.org/) via [agenix](https://github.com/ryantm/agenix); decryption happens automatically at NixOS activation, using the host's SSH host private key. Full guide (adding/editing/removing a secret, wiring up a new host, the ssh-ed25519-vs-X25519 manual-encryption gotcha): **`docs/secrets.md`**.

Quick reference:
```bash
agenix -e secrets/<name>.age          # create or edit a secret
# declare it in modules/nixos/system-secrets.nix, then:
sudo nixos-rebuild switch --flake .#<host>
```

## Workflow Rules

- **Never run `sudo` commands directly** (including `nixos-rebuild switch/test`). Ask the user what to run and whether you need the output — this is their real system, not a sandbox.
- **Never use `hyprctl` (or similar) to move, close, or otherwise manipulate windows on the user's live desktop session** for testing purposes. It's their actual running session, not a disposable test environment.
- **Test before `switch`, not after.** Before recommending or describing a `nixos-rebuild switch`, prefer walking through `nixos-rebuild dry-activate` (or `test`, if the user runs it themselves) first, and mention what it would change. Don't jump straight to `switch` as the first suggested step.
- **Warn before suggesting a rebuild that triggers a local kernel compile.** Before suggesting any `nixos-rebuild` command, run `nixos-rebuild dry-build --flake .#<host>` (no `sudo` needed) and check its "these N derivations will be built" list (nothing printed at all means everything is cached). Look specifically for a bare `linux-<version>.drv` — the full kernel build. Ignore `linux-<version>-modules-shrunk.drv`, `initrd-linux-<version>.drv`, and the always-present system-closure derivations (`etc.drv`, `activate.drv`, `boot.json.drv`, `nixos-system-*.drv`) — those are fast (seconds), not a real compile. If the bare kernel derivation shows up, prepend the suggested command with `⚠️ WARNING — local compilation on system rebuild (estimated ~15–25 min on saruman's Ryzen AI 9 365; scale for other hosts)`. This matters most on battery or anywhere the build can't run to completion (e.g. on a train). As of 2026-09-09 this only happens on saruman when a `custom.*` kernel-patch option (`amdgpu-s2idle-patch`, `amdgpu-hdmi-scdc-fix`) is enabled — see `docs/maintenance.md` items 7 and 23 — but re-run the check rather than assuming; other overlays that build from source (item 2, item 22, etc.) are much cheaper and don't need the same warning.
- **A build-time estimate request means give a number, don't run the build.** When asked how long a build/rebuild will take, answer from reasoning (derivation count and kind from `dry-build`/`dry-run`, comparable past builds, CPU) — never kick off the real build to time it. The question is almost always asked *to decide whether there's time to let it finish* (e.g. on a train, on battery); actually running it to get a precise answer defeats that purpose by spending the time/power the user was trying to avoid committing yet.
- **Flag orphaned modules, don't silently delete them.** If you find a module under `modules/` that no host imports, say so and ask whether to wire it up, keep it as intentional (e.g. `desktop-waybar.nix` — kept on purpose as an AGS fallback, see `docs/maintenance.md`), or delete it. Don't assume unused means safe to remove.
- **Keep docs in sync with the changes you make, in the same commit.** Documentation must never fall behind the repo it describes. Concretely, whenever you:
  - **add, remove, rename, or move a `.nix` file (or move a module between imported/orphaned status)** — update `docs/architecture.md`'s module tables, and this file's Repository Structure summary if the top-level shape changed.
  - **discover or change a hardware fact for a host** (a chip model, a quirk, a workaround tied to specific silicon) — update its row in the Hardware Quick Reference table (terse fact only — full diagnosis goes in `docs/maintenance.md`, see below).
  - **add, resolve, or remove a temporary fix, overlay, pin, or workaround** — update `docs/maintenance.md` (see the rule below).
  - **make a non-obvious, evergreen architecture decision** (not a temporary bodge) — add it to `docs/architecture.md`'s "Design decisions & gotchas" section rather than a long inline comment.
  - **change how secrets are managed, added, or structured** — update `docs/secrets.md`.
  - **learn a new durable workflow rule or preference from the user** — add it under Workflow Rules (see below).

  If you're not sure whether a change is "structural" enough to warrant a doc update, err on the side of updating it — a stale doc (like the NVIDIA/AMD drift that prompted this rule) is worse than a slightly over-eager edit. Do this proactively, without waiting to be asked.
- **Document new bodges in `docs/maintenance.md`.** Whenever you add a temporary fix, overlay, version pin, upstream-bug workaround, or anything else that should eventually be removed once some external condition changes (a nixpkgs update, an upstream fix landing, hardware support maturing, etc.), add an entry to `docs/maintenance.md` in the same commit: what it does, why it's needed, and the condition under which it can be removed. If a change you make resolves or removes an existing bodge, update or delete its entry there too — don't let it go stale like the old "Sauron TODO" did.
- **Keep inline comments brief; put the real explanation in `docs/`.** A short comment on a non-obvious line is fine. A multi-sentence or multi-paragraph comment — dated history, hardware diagnosis, design rationale — belongs in `docs/maintenance.md` (temporary bodges) or `docs/architecture.md` (evergreen design decisions) instead, with a terse one-line pointer left in the code (e.g. `# see docs/maintenance.md #7`). Don't let comment bulk creep back in.
- **Always `git add` new files** after creating them. Nix flakes only see git-tracked files, so new files must be staged immediately or the build will fail with "path does not exist".
- **Always commit changes** after making them. Do **not** push unless explicitly told to.
- **The "sleep inhibit" toggle gates idle timeouts only — never lid close.** The swaync toggle (`modules/home/desktop-swaync.nix`) creates `$XDG_RUNTIME_DIR/hypridle-idle-inhibited`, and the *only* thing that may consult it is hypridle's idle-timeout listeners (dim/lock/dpms/sleep). Closing the lid is an explicit "I am done" signal and must always sleep regardless of the toggle — that's also how logind itself behaves (`LidSwitchIgnoreInhibited` defaults to `yes`). Don't add an inhibit check to any lid-driven sleep path, including `modules/nixos/service-lid-undock-hibernate.nix`.
- **Save learned lessons to this file.** When the user teaches you a workflow rule or preference, add it to this `CLAUDE.md` so it persists across all hosts and sessions.
- **Show the commit message** at the end of every response that results in a git commit, so the user knows a commit was made and what it says.
