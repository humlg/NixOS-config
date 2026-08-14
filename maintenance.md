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

### 7. Saruman: s2idle sleep/resume hang — worked around by hibernating on lid close
- **Where:** `hosts/saruman/configuration.nix` (`boot.resumeDevice`,
  `services.logind.settings.Login.HandleLidSwitch`/
  `HandleLidSwitchExternalPower`).
- **What workarounds are stacked here:**
  1. `pm_debug_messages` + `amd_pmc.enable_stb=1` kernel params — diagnostics only, no fix.
  2. `amdgpu.dcdebugmask=0x800` (`DC_DISABLE_IPS`) — kernel-level mitigation,
     **confirmed 2026-07-22 to NOT fix the hang on its own** (rebooted onto
     it, hang recurred). Kept as a harmless secondary mitigation.
  3. `mt7921e disable_aspm=1` — secondary/unconfirmed theory, kept since it's harmless (the WiFi chip *may* also wedge the platform in deep ASPM states).
  4. **Hibernate on lid close (2026-07-22, active fix)** —
     `services.logind.settings.Login.HandleLidSwitch = "hibernate"` (also
     `HandleLidSwitchExternalPower`) in `configuration.nix`. This sidesteps
     s2idle entirely for the lid-close path instead of trying to fix the
     buggy deep-idle code path. Needs `boot.resumeDevice` pointing at the
     LUKS swap partition (`luks-01b4b8c5-...`, 29.9GB, already unlocked in
     initrd) — 27GiB RAM fits comfortably.
     **First attempt was wrong and is worth recording**: initially added a
     `desktop.hyprland-desktop.lidSwitchCmd` option and set the Hyprland
     `switch:on:Lid Switch` compositor keybind to `systemctl hibernate`,
     leaving `services.logind`'s own native lid-switch handler at its
     default (`HandleLidSwitch = "suspend"`, never explicitly set before).
     logind listens to the lid-switch evdev event independently of the
     compositor, so **both fired on every lid close** — this had always been
     true, just invisible before because both sides called `systemctl
     suspend`. Once only the compositor side changed, the two raced and
     logind's suspend consistently won, so the laptop suspended (s2idle)
     instead of hibernating — confirmed via
     `journalctl -b -2`: `systemd-logind: Lid closed. Suspending...` fired
     immediately after Hyprland's own `hibernate requested from client PID
     ... ('systemctl')`, and the kernel log showed `PM: suspend entry
     (s2idle)`, not hibernate. On the next boot,
     `systemd-hibernate-resume.service` correctly found the swap device but
     no valid hibernation image (`Unable to resume from device ... offset 0,
     continuing boot process`), so it booted fresh with no error — which is
     why it looked like nothing had happened at all. Fixed by reverting the
     compositor-level bind and `lidSwitchCmd` option entirely and setting
     `HandleLidSwitch` at the systemd-logind level instead, where the actual
     race was happening. Lesson: on this repo's Hyprland setup, lid-switch
     handling must live in `services.logind`, not a compositor keybind —
     logind reacts to lid events on its own regardless of what the
     compositor does.
     **Extended to the other two s2idle paths on 2026-08-14**: hypridle's
     30-min idle-timeout listener (`modules/desktop/hypridle.nix`) now runs
     `desktop.hyprland-desktop.sleepCommand`, set to `systemctl hibernate`
     in `hosts/saruman/home.nix`; and `HandlePowerKey` went from `"suspend"`
     to `"hibernate"` too. The option defaults to `systemctl suspend` so
     sauron is unaffected — it has a swap device but no `boot.resumeDevice`,
     so hibernate there would power off and lose the session.
     The fourth path — lid closed *while docked* — is deliberately left as
     `HandleLidSwitchDocked = "ignore"` (now set explicitly rather than
     relying on the logind default) so the laptop stays usable lid-shut on
     an external monitor. logind evaluates that choice only at the instant
     the lid event fires and never re-checks, so unplugging the monitor
     afterwards would strand the machine awake in a bag. `modules/services/
     lid-undock-hibernate.nix` closes that: a udev rule on DRM hotplug runs
     a unit that hibernates when the last external display disappears with
     the lid shut. It edge-triggers on a 1→0 external-display transition
     (state cached in `/run`, which survives hibernation) specifically so
     powering the machine back on with the lid still shut and no monitor
     attached does not immediately re-hibernate it. Note this module is a
     workaround for a *design* gap in logind, not for an upstream bug, so
     it does not disappear when #219445 is fixed — but it also becomes
     much less important then, since the fallback would be a working
     suspend rather than a wedge.
  5. **2026-08-02 → 2026-08-14 retest on plain `suspend`: FAILED, reverted.**
     Lid close was temporarily set back to `"suspend"` to check whether a
     nixpkgs/kernel update had fixed the underlying bug. It had not. On
     kernel 7.1.5 over 12 days the hang reproduced **8 times in ~36 suspend
     attempts (~22%)** — boots -12, -11, -9, -8, -6, -5, -4 and -1 each end
     with `PM: suspend entry (s2idle)` as the literal last journal line and
     no matching `PM: suspend exit`, i.e. the machine never came back and
     was hard-powered-off. For contrast, the 2026-07-24..08-02 hibernate
     window logged 9 lid-close cycles, every one a clean `hibernation
     entry` → `hibernation exit` pair, zero hangs, including a 7-day
     hibernation (Jul 25 → Aug 1). Restored to `"hibernate"` on 2026-08-14.
     **Removal condition for the whole workaround:** a specific upstream fix
     for bugzilla #219445 landing in the running kernel. Don't retest by
     flipping back to `"suspend"` on spec — the cost of a failed retest is
     the user's unsaved work, and it has now failed once that way.
- **Root-cause lead (2026-07-21, unconfirmed as sole cause):** Upstream kernel
  bugzilla [#219445](https://bugzilla.kernel.org/show_bug.cgi?id=219445) is
  filed against this *exact* laptop model (Lenovo Yoga Pro 7 14ASP9) for the
  identical symptom (EC/keyboard-backlight alive, system otherwise wedged,
  unresponsive to keyboard/power button, hard power-off required). A reporter
  on that bug bisected it to commit `f6098641d3e1e4` ("drm/amd/display: fix
  s2idle entry for DCN3.5+", merged ~6.10→6.11, backported to stable): kernel
  6.10 resumes fine, 6.11+ hangs. That commit forces DCN3.5+ display hardware
  (saruman's Radeon 880M/890M iGPU, RDNA 3.5 = DCN 3.5) into IPS (Idle Power
  States) before D3cold on s2idle entry. `amdgpu.dcdebugmask=0x800` disables
  that path but did **not** stop the hang on its own — either the bisected
  commit isn't the (whole) cause, or there's a second contributing bug.
- **Also:** the reboot-hang half of this was independently fixed and documented
  as solved (commit `505cd04`, no `reboot=` override needed on BIOS PSCN23WW) —
  see project memory `saruman-sleep-hang.md`. That testing was done **undocked**
  — see item #7b below for a related hang that only shows up docked.
- **Removed:** `ucsi_acpi` blacklist (was theorized to fix a resume ETIMEDOUT/EC
  corruption causing the *second* s2idle cycle to hang) — confirmed by the user
  that the sleep hang persisted with it blacklisted, so it wasn't the cause.
  Re-enabled since it was pure downside: with it blacklisted, saruman had no
  `typec`/UCSI subsystem at all, so USB-C PD contract negotiation (e.g. with a
  power bank) couldn't happen — charging fell back to basic detection only.
- **Status:** Reboot hang (undocked) = solved. Sleep hang was worked around
  via hibernate-on-lid-close (2026-07-22); **temporarily reverted to plain
  `"suspend"` on 2026-08-02** (`HandleLidSwitch`/`HandleLidSwitchExternalPower`
  back to `"suspend"` in `hosts/saruman/configuration.nix`) to retest whether
  a recent nixpkgs/kernel bump (flake update 2026-08-01, commit `24dbc01`)
  fixed the underlying s2idle wedge upstream. `boot.resumeDevice` and the
  `amdgpu.dcdebugmask=0x800`/`mt7921e disable_aspm=1` mitigations were left in
  place. Separately: `HandleLidSwitchDocked` (not currently set, defaults to
  `"ignore"`) takes priority over both `HandleLidSwitch` settings whenever
  logind sees more than one display connected — since saruman is routinely
  used with an external monitor, closing the lid while docked may do *nothing
  at all* regardless of the suspend/hibernate choice above. Not yet addressed;
  worth revisiting if lid-close appears to silently no-op while an external
  display is attached.
- **Action:** Use saruman normally for a few days/weeks with plain suspend. If
  the s2idle hang recurs, revert `HandleLidSwitch`/`HandleLidSwitchExternalPower`
  to `"hibernate"`. If it holds up over real-world use, the hibernate
  workaround (and eventually `amdgpu.dcdebugmask=0x800`) can be dropped for
  good. Idle-timeout suspend (30 min, no lid activity, `modules/desktop/hypridle.nix`)
  still calls plain `systemctl suspend` either way — same s2idle exposure as
  lid-close, watch it too.
- **Removal condition:** Upstream fixes the s2idle wedge for this hardware
  (watch bug #219445) in a shipped kernel and it's confirmed stable over
  real-world use — then `lidSwitchCmd` can revert to `"systemctl suspend"`
  and `amdgpu.dcdebugmask=0x800` can be dropped and re-tested without it.

### 7b. Saruman: shutdown/reboot hangs (black screen, hard power-off required) when docked via USB-C
- **Where:** `hosts/saruman/configuration.nix` — `pcie_ports=compat` in `boot.kernelParams`.
- **What:** Adds `pcie_ports=compat`, forcing ACPI-based PCIe hotplug instead
  of native PCIe hotplug/AER handling.
- **Why:** User's monitor has a built-in USB-C dock (single-cable, DP-altmode +
  hub), which connects through saruman's AMD USB4/Thunderbolt controller
  (`64:00.5`, PCI id `1022:151c`). Shutdown/reboot reliably hangs (black
  screen, no recovery, requires a hard power-off) **only** when that cable is
  plugged in — confirmed by testing docked vs. unplugged before shutting down.
  Likely the same class of USB-C/EC fragility as item #7 (this laptop already
  has `ucsi_acpi` blacklisted for a related but distinct sleep-resume bug),
  surfacing here as a hang tearing down the PCIe/USB4 tunnel to the dock
  during shutdown. No kernel log capture was possible — `systemd-journald` is
  already dead by the point the kernel hangs, so this is a documented,
  reasoned-out candidate fix, **not yet confirmed** to work.
- **Action:** Test docked shutdown *and* docked reboot with `pcie_ports=compat`
  in place (via `nixos-rebuild test`, then confirm across a real `switch` +
  a few real-world docked shutdowns before trusting it). If it doesn't fix
  the hang, next step is `netconsole` to another LAN machine to capture the
  actual hang point before trying further blind fixes.
- **Removal condition:** Confirmed fixed and stable for a while → keep
  permanently (update status to solved, drop "EXPERIMENTAL" language in the
  code comment). Confirmed *not* fixed → revert the kernel param and pursue
  netconsole-based diagnosis instead.

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
