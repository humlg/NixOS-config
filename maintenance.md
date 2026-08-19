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

### 7. Saruman: s2idle sleep/resume hang — kernel patch (2026-08-16) reduces but doesn't fix it; direct hibernate restored on every sleep path (2026-08-18)
- **Where:** `patches/amdgpu-no-idle-opt-on-s2idle.patch`,
  `modules/system/amdgpu-s2idle-patch.nix`, and `hosts/saruman/configuration.nix`
  (`boot.resumeDevice`, `custom.amdgpu-s2idle-patch.enable`, the three
  `services.logind.settings.Login.Handle*` values).
- **What workarounds are stacked here:**
  1. `pm_debug_messages` + `amd_pmc.enable_stb=1` kernel params — diagnostics only, no fix.
  2. `amdgpu.dcdebugmask=0x800` (`DC_DISABLE_IPS`) — **confirmed 2026-07-22 to
     NOT fix the hang**, and as of 2026-08-16 we know why it never could. The
     offending call in `dm_suspend()` is guarded by `dc->caps.ips_support`, a
     *hardware capability* bit, whereas `DC_DISABLE_IPS` sets the unrelated
     `dc->config.disable_ips` mode field (a `dmub_ips_disable_type`). The
     parameter was aimed at the right commit but the wrong field, so it never
     touched the code path at all. Kept only until the patched kernel in bullet 6
     below has a clean validation week — then drop it, it is pure noise.
  3. `mt7921e disable_aspm=1` — secondary/unconfirmed theory, kept since it's harmless (the WiFi chip *may* also wedge the platform in deep ASPM states).
  4. **Hibernate on lid close (2026-07-22 → 2026-08-16, superseded by bullet 6)** —
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
     Superseded on 2026-08-16 — see bullet 6.
  6. **Local kernel patch (2026-08-16, active fix)** —
     `patches/amdgpu-no-idle-opt-on-s2idle.patch`, applied via
     `boot.kernelPatches` from `modules/system/amdgpu-s2idle-patch.nix`
     (`custom.amdgpu-s2idle-patch.enable`). It deletes the two lines that
     `f6098641d3e1e4` added to `dm_suspend()`:
     `if (dm->dc->caps.ips_support && adev->in_s0ix) dc_allow_idle_optimizations(dm->dc, true);`
     Confirmed still present in the running kernel before writing the patch, by
     disassembling the *shipped* `amdgpu.ko` (7.1.5) rather than trusting
     upstream source: `dm_suspend` relocates a call to
     `dc_allow_idle_optimizations_internal` sitting between
     `hpd_rx_irq_work_suspend` and `dc_dmub_srv_set_power_state`.
     Corroboration that deleting it is the right remedy comes from the amd-gfx
     thread *"[REGRESSION] drm/amd/display: Radeon 840M/860M: bisected suspend
     crash"* — same commit, same symptom, same DCN3.5 display block (Ryzen AI 7
     350 / AI 5 340), where the reporter confirmed removing these lines fixes
     it. AMD's Mario Limonciello declined it upstream because it "blocks
     hardware sleep" and redirected to
     [drm/amd#4344](https://gitlab.freedesktop.org/drm/amd/-/issues/4344),
     which has produced no fix — so there is nothing to wait for.
     **Costs, both accepted deliberately:** every kernel version bump now
     compiles the kernel locally (~15–25 min on this 10-core/20-thread part);
     and the part no longer reaches its deepest hardware sleep, so idle drain
     while suspended is higher than stock. The second was meant to be bounded by
     suspend-then-hibernate; that backstop had to be withdrawn a day later (see
     bullet 7), so higher standby drain is now unbounded and is the one open
     cost of this arrangement. The module also flips
     `CONFIG_HIBERNATION_COMP_LZ4` on and sets `hibernate.compressor=lz4`,
     which stock nixpkgs kernels ship as `n` — free to do while building from
     source anyway. It is left enabled but is **untrusted**: it is one of the two
     unresolved suspects for the crash in bullet 7, and nothing takes the
     hibernate path automatically any more. Note only
     `CONFIG_HIBERNATION_DEF_COMP` changed — `CONFIG_CRYPTO_LZO=y` survives, so
     `hibernate.compressor=lzo` is still selectable at runtime with no rebuild.
     **Validation result (2026-08-16, boot -1):** three s2idle cycles at 7 s,
     22 min and 60 min residency, every `PM: suspend entry (s2idle)` matched by a
     `PM: suspend exit`. Looked like the hang was gone.
     **Recurrence (2026-08-17, boot -1):** hung again — `18:21:50 kernel: PM:
     suspend entry (s2idle)` is the literal last line of that boot, no matching
     exit, next boot didn't start until ~15h later (2026-08-18 09:06), consistent
     with an overnight hang requiring a hard power-off. This boot was running the
     patched kernel (patch landed in commit `32e854b`, well before this boot
     started). As before, the fatal cycle logged nothing beyond the entry line —
     `pm_debug_messages`/`amd_pmc.enable_stb=1` did not capture a cause. Same
     boot session, two earlier suspend/resume cycles on 2026-08-18 (boot 0) went
     clean, so this wasn't a total regression by itself.
     **Second recurrence, same night (2026-08-18, boot -2 = the boot *before*
     the one above):** re-checking history turned up an earlier hang the user
     hadn't yet mentioned — boot -2 (Aug 16 20:45 → Aug 17 00:45, i.e. the
     night right after the "validated" boot -3) had exactly **one** suspend
     attempt, at 00:45:50, and it hung too — same signature, dead until the
     next boot ~9.5h later. So the two most recent *unattended* sleep attempts
     both hung (2 for 2), right after a controlled 3-cycle test (done awake,
     watched, over ~1.5h) had looked clean. Conclusion: the patch does not
     eliminate the hang; it may or may not even reduce the historical ~22%
     rate — three short watched cycles was never enough sample size to tell,
     and the real-world failures were both long unattended sleeps.
     **Decision (2026-08-18): direct hibernate restored on every sleep path**
     (`HandlePowerKey`/`HandleLidSwitch`/`HandleLidSwitchExternalPower` back to
     `"hibernate"`, `custom.lid-undock-hibernate.sleepCommand` back to its
     `systemctl --no-block hibernate` default, hypridle's
     `desktop.hyprland-desktop.sleepCommand` back to `systemctl hibernate`).
     Critically this is **direct** hibernate, never suspend-then-hibernate —
     see bullet 7 for why that distinction is load-bearing, given the one
     known hibernate-resume crash happened specifically via the delayed-
     conversion path. `custom.amdgpu-s2idle-patch.fasterHibernateCompression`
     was also flipped to `false`, dropping back to LZO — it's the other named
     suspect for that crash and was never exercised during the 9/9 proven-good
     direct-hibernate window (2026-07-24 → 08-02, pre-dates this option). The
     kernel patch itself (`custom.amdgpu-s2idle-patch.enable`) is left on: it
     isn't implicated in either open bug and may still help on the rare path
     that ends up in plain s2idle.
     **Not yet soaked** — this reinstates almost exactly the 2026-08-14
     configuration (bullet 4) but building on the patched kernel for the first
     time with LZ4 removed, so watch for the TTM crash from bullet 7
     specifically (it was seen exactly once, via suspend-then-hibernate with
     LZ4 — this arrangement changes both of those, but "changes both
     variables" is not the same as "proven safe," it just removes the two
     leads we have). If it recurs even via direct hibernate, LZ4 and the
     delayed-conversion path are both cleared as suspects and the crash is
     TTM/hibernate-resume-on-this-kernel in general — at that point hibernate
     needs to come off every automatic path again and the battery-drain
     trade-off of plain s2idle has to be accepted instead.
     **Removal condition (for the kernel patch and dcdebugmask):** drm/amd#4344
     (or bugzilla #219445) landing a real fix in the running kernel, or the
     call gaining a guard this hardware fails. If a kernel bump makes the
     patch fail to apply, that is the intended tripwire — re-read
     `dm_suspend()` before regenerating it.
  7. **Hibernate resume crashes in TTM (found 2026-08-16, unfixed — root cause
     of the LZO/direct-hibernate-only constraints above).** The very first
     hibernation on the patched kernel restored its image successfully and
     then died ~350 ms later, in the first GPU submission after resume:
     ```
     list_add corruption. prev->next should be next (…ee28), but was 0000000000000000.
     kernel BUG at lib/list_debug.c:32!
     CPU: 12 … Comm: gjs            ← the AGS bar
       ttm_bo_populate+0x83 [ttm]   ← inlined ttm_resource_add_bulk_move()
       ttm_bo_handle_move_mem → ttm_bo_validate → amdgpu_cs_bo_validate → amdgpu_cs_ioctl
     ```
     `hyprlock:cs0` then spun in `ttm_resource_manager_usage` until softlockup.
     Symptom from the user's side: hyprlock draws exactly one frame (clock
     updates from the sleep time to the current time), then the session freezes
     completely — no VT switch, CapsLock still toggling because the kernel is
     otherwise alive. Only a hard power-off recovers it.
     The corrupted structure is TTM's bulk-move range
     (`struct ttm_resource.lru.link`, the `kmalloc-96` object at offset 64 in the
     log). That branch of `ttm_bo_populate()`
     (`drivers/gpu/drm/ttm/ttm_bo.c:1275`) runs only for a BO that *was swapped
     out and just came back*, and the only thing that swaps BOs out here is
     `ttm_device_prepare_hibernation()`, which `amdgpu_device_evict_resources()`
     (`drivers/gpu/drm/amd/amdgpu/amdgpu_device.c:4336`) calls **only when
     `adev->in_s4`**. So it is hibernate-specific and lives in kernel code this
     repo does not patch.
     **Two suspects, neither eliminated** (n=1 failure): LZ4 image compression,
     and hibernating out of a *resumed s2idle* — the transition also logged
     `amd_pmc: failed to talk to SMU` / `resume failed: -110` seconds earlier.
     The stock kernel hibernated and restored cleanly twice the same afternoon
     (boot -2), so this is new. Not bisected, because with s2idle working
     hibernation has no job left on this machine.
     **Consequence:** `suspend-then-hibernate` lasted one day (2026-08-16 →
     2026-08-17). All automatic sleep is plain s2idle now; see the sleep-policy
     bullet below.
     **Removal condition / how to pick it back up** if standby drain turns out to
     need a hibernate backstop after all — first two steps need no kernel rebuild:
     (a) plain `systemctl hibernate` from a running desktop ×3, which separates
     "hibernate is broken" from "hibernating out of a resumed s2idle is broken";
     (b) `hibernate.compressor=lzo` in `boot.kernelParams` (`CONFIG_CRYPTO_LZO=y`
     is still built in), which clears or convicts LZ4 for the price of a reboot;
     (c) boot the pre-`32e854b` generation and hibernate, for a stock-kernel
     comparison. Candidate targeted fix if plain hibernate is implicated: a
     second patch in `custom.amdgpu-s2idle-patch` skipping the
     `ttm_device_prepare_hibernation()` call — it is the sole producer of swapped
     TTM objects here and so of the crashing path, it exists to shrink
     hibernation images on multi-TB-VRAM servers, and it buys an iGPU laptop
     essentially nothing. Cost would be a slightly larger image.
- **Root-cause lead (2026-07-21, unconfirmed as sole cause):** Upstream kernel
  bugzilla [#219445](https://bugzilla.kernel.org/show_bug.cgi?id=219445) is
  filed against this *exact* laptop model (Lenovo Yoga Pro 7 14ASP9) for the
  identical symptom (EC/keyboard-backlight alive, system otherwise wedged,
  unresponsive to keyboard/power button, hard power-off required). A reporter
  on that bug bisected it to commit `f6098641d3e1e4` ("drm/amd/display: fix
  s2idle entry for DCN3.5+", merged ~6.10→6.11, backported to stable): kernel
  6.10 resumes fine, 6.11+ hangs. That commit forces DCN3.5+ display hardware
  (saruman's Radeon 880M iGPU, RDNA 3.5 = DCN 3.5) into IPS (Idle Power
  States) before D3cold on s2idle entry. **Confirmed as the cause on
  2026-08-16** — the bisect was right all along; only the chosen mitigation was
  wrong. `amdgpu.dcdebugmask=0x800` sets a different field than the one guarding
  the call (see bullet 2 above), so it never disabled that path despite
  appearing to. Removing the call outright (item 6) is what actually addresses
  it. No second contributing bug needs to be postulated.
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
- **Sleep policy as of 2026-08-17:** all four paths are plain s2idle
  `suspend` — `HandlePowerKey`, `HandleLidSwitch` and
  `HandleLidSwitchExternalPower` in `hosts/saruman/configuration.nix`,
  hypridle's 30-min idle timeout via `desktop.hyprland-desktop.sleepCommand` in
  `hosts/saruman/home.nix`, and the undock path via
  `custom.lid-undock-hibernate.sleepCommand`. Nothing hibernates automatically;
  `boot.resumeDevice` and the LUKS swap are kept so a manual `systemctl
  hibernate` still works and so the backstop can be restored without an initrd
  change. `sleepCommand` still defaults to `systemctl suspend`
  (hyprland-desktop) and `systemctl --no-block hibernate`
  (lid-undock-hibernate), so sauron is unaffected either way — it has swap but
  no `boot.resumeDevice`, so hibernating there would lose the session.
  `HandleLidSwitchDocked` stays `"ignore"`, explicitly set, paired with
  `custom.lid-undock-hibernate.enable` as described in item 4 above. Note the
  module's file and option name still say "hibernate"; it is the historical name
  and the action is whatever `sleepCommand` says.
- **Status:** Reboot hang (undocked) = solved. Sleep hang = **fixed and
  validated** by the kernel patch in bullet 6 (three cycles up to 60 min
  residency, all clean), replacing the 2026-07-22 hibernate-everything
  workaround that made every lid close cost a full boot and a LUKS passphrase.
  Open: hibernate *resume* now crashes (bullet 7), so there is no backstop
  against a flat battery on a long unattended absence, and the patched kernel
  draws more in standby than stock by design.
- **Action:** Measure standby drain — that is the one number that decides
  whether the current no-hibernate arrangement is livable. Note
  `/sys/class/power_supply/BAT0/energy_now` before and after a ≥60-min lid-shut
  suspend on battery (`energy_full` is 65.85 Wh; the 67.6 Wh figure quoted here
  earlier was the design capacity). Under ~1.5 W is several days of standby and
  fine as-is; over ~3 W is under a day, and chasing bullet 7's bisect becomes
  worth it. Then soak a week of real lid-close-and-walk cycles including an
  overnight. Also drop `amdgpu.dcdebugmask=0x800` (bullet 2) once that week is
  clean — it is now known to be inert. If the s2idle hang ever recurs, the
  fallback is *not* hibernate any more; capture an STB trace
  (`amd_pmc.enable_stb=1` is already on) before changing anything.
- **Removal condition:** see bullets 6 and 7 above.

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

### 16. Two parallel Hyprland config formats coexist (hyprlang tree now frozen)
- **Where:** `modules/desktop/hyprland-config/` (hyprlang, legacy) vs.
  `modules/desktop/hyprland-config-lua/` (Lua, active)
- **What:** Both directories are fully built out. All three hosts actually run
  the Lua config (`useLuaConfig = true` in each `home.nix`).
- **Status (2026-08-19):** No longer kept in sync — David confirmed the
  hyprlang tree is deprecated; all new config work (keybinds, autostart,
  appearance, window-rules) goes into `hyprland-config-lua/` only going
  forward. The two directories were already drifting before this was
  clarified (see item #9, where a namespace fix landed in both independently)
  and will now drift further by design, not by accident.
- **Action:** Since the hyprlang tree is confirmed unused and no longer
  maintained, it's now a candidate for outright deletion rather than a
  fallback worth preserving — flag for a decision next time it's touched
  (per CLAUDE.md's "flag orphaned modules, don't silently delete" rule) rather
  than deleting it unprompted.

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

### 19. Noctalia desktop shell — pilot on saruman, not yet replacing AGS/swaync/hyprlock/waypaper
- **Where:** `modules/desktop/noctalia.nix` (HM, `desktop.hyprland-desktop.useNoctalia`),
  `modules/desktop/noctalia-system.nix` (NixOS, `custom.noctalia.enable`), new
  `noctalia` flake input in `flake.nix`. Enabled on saruman only
  (`hosts/saruman/configuration.nix`, `hosts/saruman/home.nix`).
- **What:** Trialing Noctalia (v5, Beta — `github:noctalia-dev/noctalia-shell`)
  as a possible replacement for the AGS bar + swaync notifications + hyprlock
  lock screen + waypaper wallpaper picker, per the staged migration plan from
  2026-08-19.
  `programs.noctalia.recommendedServices.enable` wants
  `services.power-profiles-daemon.enable`, but saruman (and every host using
  this module) already runs TLP for power management, and NixOS's TLP module
  asserts the two are never both enabled — `noctalia-system.nix` forces
  `power-profiles-daemon.enable = false` to avoid that build failure.
  Noctalia does not read wallust output; it generates its own palette
  (`[theme] source = "wallpaper"`, matugen-style) independently, so its colors
  currently won't match the rest of the wallust-themed desktop. To keep
  wallust-driven apps (hyprlock, hyprland core, rofi, btop, cava, vim) in
  sync, `noctalia.nix` wires Noctalia's `wallpaper_changed` hook to
  `wallust run -s "$NOCTALIA_WALLPAPER_PATH" && reload-desktop` — the same
  role waypaper's old `post_command` played.
- **Status:** Phase A/B done and confirmed working on real hardware (bar,
  notifications, wallpaper, lock, tested 2026-08-19). Phase C done the same
  day: AGS (`ags.nix`) and swaync (`swaync.nix`) are now gated
  `cfg.enable && !cfg.useNoctalia`; waypaper's package/config-seed are gated
  `!cfg.useNoctalia`; `reloadDesktop` skips the ags/swaync restart under
  Noctalia; `SUPER+W`/`SUPER+N` map to `noctalia msg panel-toggle
  wallpaper`/`control-center` on saruman (Lua config tree only — see item #16).
  All three are therefore fully inert on saruman now, present only as
  `!cfg.useNoctalia`-gated code for other hosts / a fallback if the pilot is
  abandoned.

  **Phase D done (code) 2026-08-19. Rebuilt and manual SUPER+L lock/unlock
  confirmed working the same day. Watched suspend/resume and an unattended
  overnight sleep are still outstanding before this is trusted — see below.**
  `hypridle.nix`'s `lock_cmd` and the `SUPER+L` keybind now both branch on
  `cfg.useNoctalia`: on saruman they call `noctalia msg session lock`
  (Noctalia's documented IPC lock command) instead of spawning hyprlock, so
  hyprlock is never invoked automatically or by keybind on this host anymore
  — avoids a race for the session-lock surface, since Noctalia's docs say
  `loginctl lock-session` already routes to whichever client implements the
  session-lock protocol, and running both risked exactly that race.
  `before_sleep_cmd` (`loginctl lock-session`) is unchanged — it's just the
  trigger, `lock_cmd` decides which client actually locks.
  **`hyprlock.nix` itself is deliberately left enabled/untouched on saruman**
  so rollback (flip the two `useNoctalia` branches, or just set
  `useNoctalia = false`) is a one-line revert, not a re-install, if Noctalia's
  lock proves unreliable.
  **This is the highest-blast-radius step in the whole migration** — saruman
  has a documented history (item #7) of a mitigation looking solved after a
  short watched soak and then failing on the very next unattended overnight
  sleep. Do not trust this after one clean cycle: validate with (1) a manual
  `SUPER+L` lock/unlock while awake — **done, confirmed working
  2026-08-19** — (2) a real watched lid-close/suspend/resume cycle, and only
  then (3) at least one unattended overnight sleep, before considering it
  reliable. (2) and (3) are still outstanding.
- **`gtk-4.0/gtk.css` fights home-manager's backup mechanism (found/fixed
  2026-08-19):** Noctalia's own GTK4 live-theming (`assets/templates/gtk/
  apply.sh` in the noctalia-shell source, run by its theming daemon on every
  start/theme change) detects that dark-theme.nix's home-manager-managed
  `gtk-4.0/gtk.css` is a read-only Nix-store symlink, deletes it, and
  replaces it with a plain file carrying its own `@import
  url("noctalia.css");` line appended. The next activation then finds a real
  file where it expects its symlink, backs it up to `gtk.css.hm-bak`, and
  re-symlinks — Noctalia immediately reconverts it again — so every *other*
  activation finds a leftover `.hm-bak` already in place and aborts with
  "existing file ... would be clobbered by backing up ...". Fixed by setting
  `xdg.configFile."gtk-4.0/gtk.css".force = true;` in `noctalia.nix` (gated
  under the same `useNoctalia` block), which makes home-manager skip the
  backup step and just overwrite unconditionally — Noctalia re-patches its
  import back in within moments of its service restarting, so this doesn't
  lose the live theming, just the doomed backup dance. `gtk-3.0/gtk.css`
  isn't affected the same way: home-manager doesn't manage a `gtk-3.0/
  gtk.css` file at all (GTK3 theme selection goes through `settings.ini`
  instead), so Noctalia creating one fresh there has nothing to collide
  with.
- **Known gap from Phase C:** Disabling swaync also removed its buttons-grid,
  which was the only UI for the sleep-inhibit toggle (see CLAUDE.md's
  "sleep inhibit gates idle timeouts only" rule) -- `hypridle.nix`'s flag-file
  mechanism itself (`$XDG_RUNTIME_DIR/hypridle-idle-inhibited`) is untouched
  and still gates the idle-timeout listeners correctly, but there is
  currently no way to flip that flag on saruman. Noctalia has a built-in
  `caffeine` bar widget (`noctalia msg caffeine-toggle`), but it uses the
  standard `zwp_idle_inhibit_manager_v1` Wayland protocol, not this repo's
  flag file -- whether Hyprland's idle-notify (which hypridle listens to)
  already suppresses itself for idle-inhibit protocol holders, making
  `caffeine` a drop-in replacement, or whether it's a no-op for our
  guarded listeners, is unconfirmed and needs testing before relying on it.
- **Removal condition:** Either the migration completes (AGS/swaync/hyprlock/
  waypaper get disabled per-host via `!cfg.useNoctalia` guards, `ags`/`astal`
  flake inputs removed, this entry closed out) or the pilot is abandoned
  (`useNoctalia`/`custom.noctalia.enable` flipped back off, the `noctalia`
  flake input and both new modules removed).

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
