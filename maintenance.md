# Maintenance Notes

This file tracks every "temporary" fix, overlay, pin, and workaround currently
living in this repo, so they don't get forgotten. Each entry says **what**
was done, **why**, and **what it would take to remove it**. Review this file
periodically (see the [Suggested Procedures](#suggested-procedures) section
below) and delete entries once they're no longer needed.

Last full scan: 2026-07-16.

---

## Active workarounds & bodges

### 1. DaVinci Resolve pinned to v21.0b1 (beta), not the nixpkgs release
- **Where:** `overlays/davinci-resolve.nix`, `overlays/davinci-resolve-package.nix`
- **What:** Full local copy of nixpkgs' `davinci-resolve` package.nix, hand-modified
  to track the `21.0b1` beta instead of the `20.3.2` nixos-unstable currently ships.
- **Why:** Wanted the beta; upstream's `src` fetch script does a `jq` title-match
  against Blackmagic's downloads.json that fails for "21 Beta 1" (titled
  differently than the version string), so the download ID is hardcoded instead.
- **Loose ends:**
  - The **studio-variant** hash is `lib.fakeHash` (unverified) — fine since the
    studio variant isn't used here, but would break the build if ever enabled.
  - This is a beta release living in a stable config — worth checking periodically
    whether nixpkgs has caught up to a released 21.x so the overlay can be dropped.
  - `updateScript` in the package still points at the standard update-source-version
    flow; it wasn't adapted for the hardcoded downloadId, so `nix run` on the
    update script may not work as expected.
- **Removal condition:** nixpkgs ships DaVinci Resolve ≥ 21 stable.

### 2. RawTherapee overlay exists but the package is commented out
- **Where:** `overlays/rawtherapee-dev.nix` (defines the fix), `modules/bundles/photography.nix:29` (`#rawtherapee`, commented out)
- **What:** The overlay rebuilds RawTherapee from a specific dev commit + a pinned
  `fmt` 12.0.0 source, to fix a static-initialization-order crash on startup
  (see linked upstream PRs/bug in the overlay's comment).
- **Why:** nixpkgs' 5.12 release crashes on startup; the fix landed upstream but
  hasn't been released yet.
- **Inconsistency found:** The overlay is still registered in `flake.nix` and
  will patch `pkgs.rawtherapee` on every rebuild, but **nothing installs
  rawtherapee** — it's commented out in `photography.nix`. Either the overlay is
  dead weight right now, or the comment predates the fix and rawtherapee should
  be re-added. Worth a decision either way.
- **Removal condition:** nixpkgs updates past 5.12 with the fix included.

### 3. `patool` test suite disabled in the sandbox
- **Where:** `overlays/patool-no-check.nix`
- **What:** `doCheck = false` for `python3Packages.patool`.
- **Why:** patool's test suite (a transitive dep of `bottles` via `wine.nix`)
  can't find bzip2/xz/lzma helper binaries inside the Nix build sandbox, so 12
  unrelated tests fail.
- **Removal condition:** nixpkgs fixes patool's sandboxed test environment
  (upstream nixpkgs issue, not tracked with a link here — worth filing/finding one).

### 4. Sauron: NVIDIA module still in the repo but no longer used
- **Where:** `modules/system/nvidia.nix` (orphaned — not imported by any host)
- **What:** Sauron was rebuilt around a Ryzen 7 5800X3D + RX 9070 XT (AMD), per
  commit `52e662f "docs: update sauron hardware — Ryzen 7 5800X3D + RX 9070 XT,
  not NVIDIA"`. `hosts/sauron/configuration.nix` now imports `amd-gpu.nix`
  instead.
- **Stale doc:** `CLAUDE.md`'s repository-structure comment still describes
  `hosts/sauron/` as "Physical desktop (**NVIDIA**, Hyprland, full package set)".
  Should be corrected to AMD.
- **Cleanup:** Either delete `modules/system/nvidia.nix` (if no host will ever
  go back to NVIDIA) or leave it as a reference for a future NVIDIA box —
  your call, but it should stop being silently dead code either way.

### 5. Sauron's RDNA 4 GPU forces an unofficial ROCm GFX version
- **Where:** `modules/system/amd-gpu.nix`
- **What:** `HSA_OVERRIDE_GFX_VERSION = "12.0.0"` — tricks ROCm into treating the
  RX 9070 XT (RDNA 4) as the closest supported architecture.
- **Why:** RDNA 4 isn't officially supported by ROCm yet.
- **Note in code:** "Verify the right value once ROCm adds native RDNA 4 support" — no verification date recorded.
- **Removal condition:** ROCm adds native RDNA 4 support; re-test GPU compute
  (DaVinci Resolve, Ollama) without the override.

### 6. Saruman's iGPU (RDNA 3.5) also forces an unofficial ROCm GFX version
- **Where:** `hosts/saruman/configuration.nix:143`
- **What:** `HSA_OVERRIDE_GFX_VERSION = "11.0.0"` for the Radeon 880M/890M.
- **Why:** Same class of problem as #5 — RDNA 3.5 isn't officially supported.
- **Removal condition:** ROCm adds native RDNA 3.5 support.

### 7. Saruman: s2idle sleep/resume hang — mitigations in place, not fully solved
- **Where:** `hosts/saruman/configuration.nix:54-70`
- **What three separate workarounds are stacked here:**
  1. `pm_debug_messages` + `amd_pmc.enable_stb=1` kernel params — diagnostics only, no fix.
  2. `ucsi_acpi` blacklisted — it times out on resume and corrupts EC state,
     causing the *second* s2idle cycle to hang.
  3. `mt7921e disable_aspm=1` — the WiFi chip wedges the platform in deep ASPM states.
- **Also:** the reboot-hang half of this was independently fixed and documented
  as solved (commit `505cd04`, no `reboot=` override needed on BIOS PSCN23WW) —
  see project memory `saruman-sleep-hang.md`.
- **Status:** Reboot hang = solved. Sleep hang = mitigated, **not confirmed
  solved** — memory notes it "needs >10 min sleeps to test."
- **Action:** Run an actual >10 min sleep test and update `saruman-sleep-hang.md`
  memory + this entry once confirmed either way.

### 8. Hyprland: monitor-mirroring flicker workaround (upstream bug)
- **Where:** `hosts/saruman/home.nix:60-71`
- **What:** A Lua `monitor.added` hook that force-reloads Hyprland (`sleep 1 &&
  hyprctl reload`) whenever a non-`eDP-1` monitor connects.
- **Why:** Upstream Hyprland bug — mirroring outputs with different aspect
  ratios leaves stale scene data flickering in the pillarbox margin instead of
  clearing to black. Linked: https://github.com/hyprwm/Hyprland/discussions/11708
- **Removal condition:** Upstream fixes the discussion linked above. Check it
  occasionally.

### 9. SwayNC blur — namespace match was silently broken, now fixed but worth re-checking after Hyprland upgrades
- **Where:** `modules/desktop/hyprland-config-lua/appearance.nix:65-74` (and the
  legacy hyprlang version in `hyprland-config/appearance.nix:64-65`)
- **What:** A layer-rule that blurs SwayNC's notification/control-center layers.
- **History:** Originally matched `class = swaync`, which **never matched**
  anything (SwayNC's actual gtk-layer-shell namespaces are
  `swaync-notification-window` and `swaync-control-center`), so blur silently
  never applied. Fixed to match `namespace = "^swaync-"`.
- **Note:** This is fixed now, not currently broken — flagging it here because
  it's the exact kind of silent, easy-to-reintroduce regression (e.g. if SwayNC
  changes its namespace naming again) that's worth a periodic visual sanity
  check after upgrading SwayNC.

### 10. SDDM greeter keyboard layout — systemd-localed seeding
- **Where:** `modules/system/sddm.nix:36-50`
- **What:** A oneshot systemd service (`seed-x11-locale1`) that runs
  `localectl set-x11-keymap` before the display manager starts.
- **Why:** SDDM's kwin greeter reads the keyboard layout from
  systemd-localed's D-Bus state (because it's started with `--locale1`), and
  nothing else on NixOS ever populates that state declaratively — so on every
  fresh boot it silently fell back to "us" instead of the configured `cz` layout.
- **Status:** Working fix, but it's a workaround for kwin-greeter's non-standard
  lookup path rather than a NixOS-native mechanism — could regress if the
  greeter's behavior changes upstream.

### 11. Steam pressure-vessel needs a fake `/usr/sbin/ldconfig`
- **Where:** `modules/bundles/gaming.nix` — `system.activationScripts.steamLdconfig`
- **What:** Symlinks a real ldconfig to `/usr/sbin/ldconfig` at system activation.
- **Why:** Inside Steam's Linux Runtime container, NixOS's ldconfig stub chain
  loops back on itself, so pressure-vessel can't set `LD_LIBRARY_PATH`, breaking
  `LD_PRELOAD`'d overlays (MangoHud, Steam overlay). This is a known
  NixOS/pressure-vessel interaction, not specific to this config, but there's no
  clean upstream fix to point at.
- **Removal condition:** Steam Linux Runtime or nixpkgs changes how ldconfig
  resolution works inside the container.

### 12. DaVinci Resolve forced to XCB (X11) instead of native Wayland
- **Where:** `modules/bundles/photography.nix:6-16`
- **What:** `davinci-resolve-xcb` wraps the package with `QT_QPA_PLATFORM=xcb`.
- **Why:** DaVinci Resolve bundles Qt5, which under `WAYLAND_DISPLAY` (i.e. on
  Hyprland) defaults to the Wayland platform, which DR doesn't support.
- **Removal condition:** Blackmagic ships a Wayland-native Qt build (unlikely
  soon — low priority to revisit).

### 13. `winboat` module is orphaned and its Docker dependency is not wired up
- **Where:** `modules/programs/winboat.nix`
- **What:** Installs `pkgs.winboat` and adds `david` to the `docker` group, but
  `virtualisation.docker.daemon.enable = true;` is **commented out**, and
  `virtualisation.docker.enable` isn't set anywhere in the repo at all.
- **Status: this module is not imported by any host** — it's fully dead code
  right now, so the incomplete Docker wiring has no live effect. But if it's
  ever wired into a host config, winboat will not actually work (no Docker
  daemon) until that line is uncommented (and using the correct option name —
  `virtualisation.docker.enable`, not `.daemon.enable`).
- **Action:** Either finish wiring this up (fix the option, import the module
  in a host) or delete it if winboat isn't wanted anymore.

### 14. `megacmd.nix` service module is fully built but orphaned
- **Where:** `modules/services/megacmd.nix`
- **What:** A complete MEGAcmd sync-daemon service module (declared sync pairs,
  systemd service/timer). **Not imported by any host.**
- **Action:** Confirm whether this is still wanted; either import it somewhere
  or delete it. Dead modules like this are exactly what erodes confidence in
  "what's actually running."

### 15. `waybar.nix` kept as a deliberate fallback, not actively maintained
- **Where:** `modules/desktop/waybar.nix` (orphaned — not imported by any host)
- **What:** Full Waybar config, superseded by the AGS bar (`modules/desktop/ags.nix`
  + `ags-config/`).
- **Status:** This one is *intentionally* kept per prior guidance — not a bug,
  just tech debt with a known reason. Listed here so it doesn't get "rediscovered"
  as dead code and deleted by accident, or conversely doesn't quietly bit-rot
  into an unusable fallback if AGS ever needs to be abandoned in a hurry.

### 16. Two parallel Hyprland config formats coexist
- **Where:** `modules/desktop/hyprland-config/` (hyprlang, legacy) vs.
  `modules/desktop/hyprland-config-lua/` (Lua, active)
- **What:** Both directories are fully built out and kept in sync by hand. All
  three hosts actually run the Lua config (`useLuaConfig = true` in each
  `home.nix`).
- **Risk:** Any future edit to keybinds/appearance/window-rules must be applied
  to **both** directories or they silently drift (see item #9 above, where the
  namespace fix landed in both but they're edited independently). If the
  hyprlang path is truly unused, consider deleting it; if it's a deliberate
  fallback, document the sync obligation more visibly (e.g. a comment at the
  top of each file pointing at its twin).

### 17. Commented-out packages with no explanation
- **Where:**
  - `modules/bundles/3d-printing.nix:15` — `#bambu-studio`
  - `modules/bundles/photography.nix:29` — `#rawtherapee` (see item #2 — this one has an explanation, just disconnected from its overlay)
  - `modules/system/nvidia.nix:9` — `#package = ...nvidiaPackages.new_feature;`
- **Action:** `bambu-studio` in particular has no comment explaining why it's
  disabled (broken build? license issue? just unused?). Worth a one-line note
  or removing it outright.

### 18. Stale TODO in CLAUDE.md (already resolved)
- **Where:** `CLAUDE.md` → "Sauron TODO" section
- **What:** Says sauron's SSH host key still needs to be added to
  `secrets/secrets.nix`. This was actually done in commit `60c3629 "secrets:
  add sauron as recipient, rekey all secrets"`. The current `secrets/secrets.nix`
  already lists sauron's key and all secrets have been rekeyed.
- **Action:** Delete the stale "Sauron TODO" section from `CLAUDE.md`.

---

## Historical bodges (already resolved — kept here for context only)

These aren't live tech debt, but they explain *why* some code looks the way it
does, so nobody "fixes" a fix:

- **AGS v1 → v2 migration.** An earlier commit (`735641e`) pinned AGS to v1.8.2
  (GJS API) because v2's Astal/TypeScript rewrite was incompatible with the
  existing bar config. The repo has since fully migrated to AGS v2
  (`programs.ags` + `ags-config/*.tsx`, see `modules/desktop/ags.nix`) — no
  pin remains. If the bar ever breaks after an AGS update, this migration is
  the relevant history.
- **hyprscrolling plugin.** Tried and reverted (`f6e69db`) — broken against
  Hyprland 0.54.x. Fully removed, no trace left in current config.
- **wl-mirror toggle on saruman.** Tried, then reverted (`e209cc6`) in favor of
  the simpler `mirror = eDP-1` fallback + the reload-on-connect workaround
  (item #8 above). Captured in memory `feedback_saruman-display-mirror.md` —
  don't reintroduce it.
- **Sauron NVIDIA → AMD GPU swap.** See item #4.

---

## Suggested Procedures

Beyond bodge-tracking, here's what a system admin would normally have in
place for a box like this that currently doesn't seem to exist in the repo:

1. **A recurring "review this file" habit.** `maintenance.md` is only useful if
   revisited. Suggest a quarterly pass (or whenever a `nix flake update`
   pulls in a major version bump for something referenced above) to check
   whether any overlay/pin can be dropped.

2. **Automated flake input updates + testing, not ad hoc `nix flake update`.**
   There's no CI, no scheduled update job, and no `flake.lock` diff review
   process visible in the repo. Even a simple local habit — `nix flake update
   --commit-lock-file` on a schedule, then `nixos-rebuild test` before
   `switch` — would catch breakage earlier than "it broke, now what changed."

3. **Backups.** Nothing in this repo configures backups (no restic/borgbackup/
   etc. modules). Given LUKS-encrypted disks and non-trivial per-host state
   (SSH keys, secrets, dotfiles via home-manager), a system-level backup for
   at least `/home` and `/etc/nixos`-equivalent state (this repo itself,
   which is presumably backed up via git remote — confirm there *is* a remote
   and it's pushed to regularly) is worth adding if not already handled
   elsewhere.

4. **`nix flake check` / basic CI.** No GitHub Actions or other CI config
   exists in the repo. Even a minimal workflow that runs `nix flake check`
   and `nixos-rebuild dry-build` for each host on push would catch syntax
   errors and eval failures before they surface at `switch` time on real
   hardware.

5. **Secrets hygiene.** `secrets/secrets.nix` recipients look correct today,
   but there's no process documented for *rotating* the `david` personal key
   (e.g. if a laptop with that key is lost/stolen) or for periodically
   confirming decrypted secrets in `/run/agenix/` have the expected
   permissions. Worth a periodic `ls -la /run/agenix/` check on each host.

6. **Firewall / open-ports audit.** `networking.firewall` rules are scattered
   (e.g. commit `501c2ff "feat(firewall): open TCP port 46687"`,
   `sunshine.openFirewall = true`, SSH always on). Worth periodically running
   `sudo nixos-firewall-tool` equivalent or just `ss -tulpn` on each host and
   diffing against what's declared, to catch drift or forgotten ports (e.g.
   the sunshine game-streaming port is open on sauron — fine if intentional,
   worth confirming it's still wanted).

7. **Unattended `nix-collect-garbage` disk pressure check.** `generation-cleanup.nix`
   is solid (keeps N generations + a rollback anchor, runs weekly), but there's
   no disk-space *alerting* — if `/nix/store` fills up between weekly runs,
   nothing notices. A simple `systemd` timer that warns (notify-send or a log
   line) when `/` crosses e.g. 85% would close that gap.

8. **SMART / disk health monitoring.** No `smartd`/`smartmontools` service
   found in the repo for any host. Worth adding `services.smartd.enable = true`
   with notifications, especially on sauron given the "increase root device
   timeout to 300s for slow NVMe init" history (commit `a329f41`) — that's the
   kind of symptom that often precedes a failing drive.

9. **Orphaned-module audit.** This scan found four modules (`nvidia.nix`,
   `megacmd.nix`, `winboat.nix`, `waybar.nix`) that exist in `modules/` but are
   imported by zero hosts. Worth a periodic `grep`-based sweep (or just
   re-running this scan) to catch drift between "modules that exist" and
   "modules actually in use" before the count grows further.

10. **Update `CLAUDE.md`'s host descriptions when hardware changes.** The
    stale "NVIDIA" description for sauron (item #4) shows the repo-structure
    doc block in `CLAUDE.md` isn't updated in lockstep with hardware swaps.
    Small thing, but it's the first thing read for context on every future
    session — worth a habit of touching it whenever a host's core hardware
    (GPU, disks) changes.

11. **Kernel/firmware update cadence.** `boot.kernelPackages` isn't pinned
    anywhere (good — tracks nixpkgs default), but there's no explicit note on
    how often `services.fwupd` (enabled on saruman only) is actually run.
    Worth running `fwupdmgr refresh && fwupdmgr update` on a schedule on both
    physical hosts, not just saruman.
