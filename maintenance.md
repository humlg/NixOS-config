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

### 7. Saruman: s2idle sleep/resume hang — kernel patch (2026-08-16) never showed a clear win over ~5 weeks; disabled 2026-09-09, retesting stock kernel
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
     touched the code path at all. **Removed 2026-09-09** (bullet 11) —
     it was only being kept as a soak-test control variable for the kernel
     patch in bullet 6, which is now also disabled, so there was no reason
     left to carry a proven no-op param.
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
  8. **Third plain-suspend retest (2026-08-19), user-requested.** Direct
     hibernate (bullet 6's decision) is reverted on all four paths back to
     plain `systemctl suspend` — `HandlePowerKey`, `HandleLidSwitch`,
     `HandleLidSwitchExternalPower` in `hosts/saruman/configuration.nix`,
     `custom.lid-undock-hibernate.sleepCommand`, and
     `desktop.hyprland-desktop.sleepCommand` in `hosts/saruman/home.nix`. This
     is the same configuration bullet 5 tried (22% hang rate over ~36
     attempts) and that failed again post-patch in bullet 6 (2/2 unattended
     overnight hangs) — going in with that history explicit rather than
     re-discovering it. The kernel patch
     (`custom.amdgpu-s2idle-patch.enable`) stays on since it may still lower
     the hang rate even though it didn't eliminate it; compression is
     irrelevant now since nothing hibernates automatically.
     **Not yet soaked** — watch for the `PM: suspend entry (s2idle)`-with-no-
     `exit` signature, especially on unattended/overnight sleeps, since that's
     exactly where both prior attempts failed while short watched cycles
     looked clean. If it recurs, revert bullet 8's four settings back to
     hibernate (the exact values are in bullet 6's decision above) and record
     the outcome here.
  9. **First unattended overnight sleep survived (2026-08-20).** Under
     bullet 8's plain-suspend policy, saruman went to sleep overnight
     unattended and woke cleanly the next morning — the first unattended
     overnight cycle since the third retest started that did *not* hit the
     `PM: suspend entry (s2idle)`-with-no-`exit` hang. Battery dropped ~15%
     over the sleep (exact `energy_now` before/after not captured this time —
     still needed for a precise Wh/hr drain figure per the Action item
     below). One clean night is not a trend yet — bullet 5's original attempt
     also had clean-looking stretches before failing at a 22% rate over ~36
     suspends, so keep treating this as encouraging but not conclusive. If
     drain stays around this level on repeat, it's workable but on the high
     side for s2idle; worth comparing against sauron/typical s2idle drain
     once more data points exist.
  10. **Failure-rate audit across the third retest, 2026-08-19 → 08-26
      (journalctl, all boots since bullet 8's revert).** Counted every
      `PM: suspend entry (s2idle)` vs `PM: suspend exit` pair per boot:
      | boot start | attempts | clean | hang (last cycle unresolved) |
      |---|---|---|---|
      | Aug 19 18:02 → Aug 20 00:05 | 2 | 2 | 0 |
      | Aug 20 00:05 → Aug 20 20:34 | 5 | 4 | 1 (20:34:48) |
      | Aug 20 21:24 → Aug 22 12:55 | 5 | 4 | 1 (Aug 22 12:55:11) |
      | Aug 22 14:44 → Aug 24 15:22 | 7 | 6 | 1 (Aug 24 15:22:05) |
      | Aug 24 15:24 → Aug 26 13:32 | 6 | 6 | 0 |
      **Total: 25 attempts, 22 clean, 3 hangs ≈ 12%** — roughly half the
      pre-patch rate (22% over ~36 attempts, bullet 5), though still not
      zero. All three hangs happened early (Aug 20 evening, Aug 22 midday,
      Aug 24 midday), each confirmed via the same signature used throughout
      this item (last journal line of the boot is the bare
      `PM: suspend entry (s2idle)`, systemd's own freeze/sleep-actions lines
      immediately above it, nothing after — i.e. it never returned within
      that boot). Recovery gaps to the next boot were short (50 min, 1h49m,
      2 min), consistent with the user hard-power-cycling shortly after
      noticing. **The most recent boot (Aug 24 15:24 → Aug 26 13:32, the
      current state as of 2026-08-26) ran 6/6 clean**, including two long
      unattended sleeps — Aug 24 18:59 → Aug 25 10:08 (~15h) and Aug 25
      18:04 → Aug 26 11:41 (~17h40m) — both clean, which is what prompted
      the user to describe recent hanging as "pretty minimal."
      **Drain figure (closes the outstanding measurement from bullet 9):**
      no `energy_now` snapshot was taken manually, but upower keeps its own
      percentage log (`/var/lib/upower/history-charge-*.dat`, world-
      readable, epoch/percent/state columns) with samples close enough to
      both long sleeps above to estimate drain without a kernel-log gap:
      ~79%→51% over the ~15h sleep (≈1.85%/hr) and ~75%→39% over the
      ~17h40m sleep (≈2.0%/hr). At the pack's current reported
      `energy-full` of 66.37 Wh (was 65.85 Wh when last recorded — battery
      capacity estimates drift with calibration, not a discrepancy worth
      chasing) that's **≈1.2–1.4 W average draw during s2idle**, i.e. ~15–17%
      over a typical 8h night — matching the user's earlier eyeballed ~15%
      almost exactly. Workable, on the higher side of what's typical for
      s2idle (expected given this machine can't reach its deepest hardware
      idle state — see bullet 6), but not alarming.
      **Read on where this leaves things:** the patch (bullet 6) is doing
      real work — hang rate roughly halved vs. no patch — but "12% overall,
      0% for the last 2 days" is still too small an n to call it fixed, and
      the last time a stretch looked clean (bullet 6's original 2026-08-16
      validation, ~1.5h watched) it was followed immediately by 2/2
      unattended overnight hangs. The difference this time: this is now 6
      consecutive clean *unattended* cycles including two full overnight
      sleeps, not just a short watched soak — a materially stronger signal
      than what preceded either past reversal. Still recommend more runway
      before revisiting bullet 2's dcdebugmask removal or calling this item
      closed.
  11. **Follow-up audit, 2026-08-26 → 2026-09-09: the streak didn't hold,
      kernel patch disabled, retesting stock.** User reported the hang
      recurring ("sometimes when the laptop sleeps it refuses to wake up ...
      usually happens when it sleeps on timeout with lid open"). Re-ran
      bullet 10's `journalctl` audit across all boots from Aug 26 13:48
      onward:
      | window | attempts | clean | hangs |
      |---|---|---|---|
      | Aug 26 → Sep 9 | 48 | 40 | 8 (≈17%) |
      One boot (Sep 2 11:05 → Sep 8 12:57) had a very good stretch — several
      clean overnight/multi-day sleeps up to ~28h residency — bracketed by
      hangs at both ends, so it isn't that the machine got reliably better
      and then regressed; the rate is just noisy around 15–20% regardless of
      the patch. Combined with bullet 10's 12%, there is no convincing
      downward trend across ~5 weeks of real use — this settles the "is the
      patch actually working" question raised at the end of bullet 10: not
      clearly. The kernel log doesn't record which path (lid-close,
      idle-timeout, power key) triggered a given suspend, so the user's
      "mostly happens on idle-timeout with lid open" observation couldn't be
      confirmed or ruled out directly — but Noctalia's idle service (GUI-
      owned `~/.local/state/noctalia/settings.toml`, `[idle.behavior.
      lock-and-suspend]`, 900s timeout) calls the same plain `systemctl
      suspend` → s2idle path as lid-close and the power key, so it's exposed
      to the identical bug either way.
      **Decision (user-requested): disable the kernel patch entirely
      (`custom.amdgpu-s2idle-patch.enable = false` in
      `hosts/saruman/configuration.nix`) and retest stock (unpatched) plain
      suspend.** This also dropped the now-provably-inert
      `amdgpu.dcdebugmask=0x800` kernel param (bullet 2), which was only
      being kept as a soak-test control variable for the patch. Net effect:
      saruman is back on nixpkgs' stock kernel (no local build on version
      bumps) with `services.logind` still on plain suspend on every path.
      **If this recurs at a similar or worse rate**, the recommended next
      step is hibernate, not re-enabling the patch — hibernate was never
      actually soaked under the current LZO-pinned settings (bullet 8
      reverted it for a policy retest, not because it failed; see bullet 6
      for the last time it ran, 9/9 clean, plus the separate TTM crash
      caveat in bullet 7), and it would also eliminate the standby-drain
      cost (bullet 10: ~1.2–1.4W measured on the patched kernel, a direct
      consequence of giving up the iGPU's deepest idle state) that this
      whole patch approach was trading against. Re-enabling the patch is a
      weaker option now — it's the thing that just failed to show a clear
      benefit over ~5 weeks.
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
- **Sleep policy as of 2026-09-09:** all four paths are still plain s2idle
  `suspend` — `HandlePowerKey`, `HandleLidSwitch` and
  `HandleLidSwitchExternalPower` in `hosts/saruman/configuration.nix`,
  Noctalia's own idle service (GUI-owned, not Nix-managed — hypridle is
  gated off under `useNoctalia`) for the idle-timeout path, and the undock
  path via `custom.lid-undock-hibernate.sleepCommand`. What changed
  2026-09-09 (bullet 11) is the kernel: `custom.amdgpu-s2idle-patch.enable`
  is now `false`, so saruman runs nixpkgs' stock kernel again (no local
  build on version bumps), and `amdgpu.dcdebugmask=0x800` is removed from
  `boot.kernelParams` as dead weight. `boot.resumeDevice` and the LUKS swap
  are kept so a manual `systemctl hibernate` still works and the hibernate
  backstop can be restored without an initrd change. `sleepCommand` still
  defaults to `systemctl suspend` (hyprland-desktop) and `systemctl
  --no-block hibernate` (lid-undock-hibernate), so sauron is unaffected
  either way — it has swap but no `boot.resumeDevice`, so hibernating there
  would lose the session. `HandleLidSwitchDocked` stays `"ignore"`,
  explicitly set, paired with `custom.lid-undock-hibernate.enable` as
  described in item 4 above. Note the module's file and option name still
  say "hibernate"; it is the historical name and the action is whatever
  `sleepCommand` says.
- **Status:** Reboot hang (undocked) = solved. Sleep hang = **still open,
  kernel patch retired.** Full journal audits: bullet 10 (Aug 19 → 26) found
  25 attempts/3 hangs (≈12%); bullet 11 (Aug 26 → Sep 9) found 48
  attempts/8 hangs (≈17%), including a very clean multi-day stretch
  bracketed by hangs on both sides — no convincing downward trend across
  ~5 weeks on the patched kernel, against a 22% pre-patch baseline (bullet
  5). Standby drain on the patched kernel measured ≈1.2–1.4 W (≈15–17%
  overnight, bullet 10) — a direct cost of the patch giving up the iGPU's
  deepest idle state. Since the patch wasn't clearly reducing hangs *and*
  was costing drain, it's disabled as of 2026-09-09 and saruman is
  retesting stock (unpatched) plain suspend. Hibernate resume still has its
  own unresolved TTM crash (bullet 7) under the one combination that
  triggered it (suspend-then-hibernate + LZ4); direct hibernate + LZO ran
  9/9 clean pre-patch and was never actually invalidated, just deprioritized
  for a policy retest (bullet 8) — the leading candidate if stock suspend
  doesn't hold up either.
- **Action:** Keep counting hangs vs. attempts under the stock-kernel retest
  — rerun the bullet-10/11-style journalctl audit periodically rather than
  re-deriving it from scratch each time. If the stock-kernel hang rate is
  similar to or worse than the patched kernel's, move to hibernate next
  (see bullet 11) rather than re-enabling the patch, which just spent ~5
  weeks failing to show a clear benefit. Capture an STB trace
  (`amd_pmc.enable_stb=1` is still on) if a hang recurs. `energy-full` read
  66.37 Wh as of 2026-08-26 (was 65.85 Wh when last recorded — normal
  calibration drift, not worth chasing) — worth a fresh drain comparison
  once enough stock-kernel sleep data exists, since giving up the patch
  should also restore the iGPU's deepest idle state and lower standby draw.
- **Removal condition:** see bullets 6, 7, 8, 10 and 11 above.

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
- **2026-09-21 update — disabled for testing, suspected of a second
  regression:** After a flake update, the Iiyama dock's top USB-C port
  stopped carrying DP altmode video entirely (bottom port kept working;
  hyprctl never lists a monitor on the dead port; the dock's USB hub/keyboard
  still works through it). Initially assumed to be a kernel regression
  (7.2.2 → 7.2.6), but the top port failed identically when test-booting back
  to 7.2.2 — however, that only reaches back to 2026-09-11 (oldest surviving
  generation; `generation-cleanup.nix` prunes further history), and this
  param has been in place since 2026-07-16, so kernel testing couldn't rule
  it out. Since it was never confirmed to fix the shutdown hang either, and
  forcing ACPI-based PCIe hotplug is a plausible way to break one port's
  PCIe-tunneled video while leaving the other alone, disabled it
  (`boot.kernelParams` in `hosts/saruman/configuration.nix`) to test whether
  the top port comes back. This reopens the original unconfirmed
  shutdown/reboot hang risk while testing — watch docked shutdowns/reboots
  for it. Outcome not yet recorded — update this entry (and the Hardware
  Quick Reference row in `CLAUDE.md`) once both the top-port video and the
  shutdown-hang risk have been retested.

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

### 19. Noctalia desktop shell — pilot on saruman, full replacement on sauron
- **Where:** `modules/desktop/noctalia.nix` (HM, `desktop.hyprland-desktop.useNoctalia`),
  `modules/desktop/noctalia-system.nix` (NixOS, `custom.noctalia.enable`), new
  `noctalia` flake input in `flake.nix`. Enabled on saruman
  (`hosts/saruman/configuration.nix`, `hosts/saruman/home.nix`) and, as of
  2026-08-21, on sauron too (`hosts/sauron/configuration.nix`,
  `hosts/sauron/home.nix`) — sauron skipped the staged pilot and went
  straight to full replacement in one pass, since none of the phase-by-phase
  caution below was ever about Noctalia itself, it was about not stacking a
  new variable on top of saruman's unresolved sleep hang (item #7). Sauron
  has no such history, so AGS/swaync/hyprlock/waypaper/hypridle are inert
  there from the first rebuild (all already gated `!cfg.useNoctalia`
  generically, not saruman-specific).
- **Runtime settings seeded, not migrated live:** Noctalia's actual tuned
  look-and-feel (bar layout, theme, lockscreen widgets, plugin list, idle
  behavior) lives in `~/.local/state/noctalia/settings.toml`, which its own
  settings GUI rewrites at runtime — not a Nix-managed file, same category as
  the `gtk.css` clobbering problem below. `modules/desktop/
  noctalia-settings-seed.toml` is a snapshot of saruman's live settings.toml
  captured 2026-08-21; `noctalia.nix`'s `seedNoctaliaSettings` activation
  script copies it to `~/.local/state/noctalia/settings.toml` once, only if
  that file doesn't already exist (same "seed if absent" pattern as
  `seedWaypaperConfig` in `hyprland-desktop.nix`). This is how sauron got an
  identical starting look-and-feel to saruman in one rebuild. Once seeded,
  this repo never touches the file again — Noctalia owns it, and further
  tuning on either host diverges independently unless the seed file is
  manually refreshed and re-copied (deleting the target file first, since the
  guard only fires when it's absent). Referenced plugins
  (`gustav0ar/drive-health`, `yocraft/battery-widget`, `kenn/
  keybind-cheatsheet`) and the `Rosey AMOLED` community palette are fetched
  by Noctalia's own marketplace mechanism on first run, not copied by the
  seed — confirmed present under `~/.local/state/noctalia/plugins/` and
  `community-palettes/` with `.catalog` metadata suggesting an online
  catalog, but the actual auto-fetch-on-sauron behavior is unconfirmed until
  tested there.
- **What:** Trialing Noctalia (v5, Beta — `github:noctalia-dev/noctalia-shell`)
  as a possible replacement for the AGS bar + swaync notifications + hyprlock
  lock screen + waypaper wallpaper picker, per the staged migration plan from
  2026-08-19.
  `programs.noctalia.recommendedServices.enable` wants
  `services.power-profiles-daemon.enable`, since Noctalia's power-profile
  widget/panel only speaks that DBus interface. Originally worked around by
  forcing `power-profiles-daemon.enable = false` since saruman ran TLP, which
  NixOS's TLP module refuses to run alongside power-profiles-daemon; saruman
  switched from TLP to power-profiles-daemon outright on 2026-08-19 instead
  (item 20), so that override is gone and the widget is now functional.
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

  **Phase E (2026-08-19): hypridle disabled entirely on saruman.** User
  configured Noctalia's own idle service (outside Nix — Noctalia's settings
  UI, not this repo) to handle dim/lock/dpms/sleep itself and confirmed by
  testing that it locks before suspend on lid-close/power-key, not just via
  manual `SUPER+L`. `modules/desktop/hypridle.nix` is now gated
  `cfg.enable && !cfg.useNoctalia`, the same pattern Phase C already used for
  `ags.nix`/`swaync.nix`, making hypridle fully inert on saruman — no dim,
  lock, DPMS-off, or sleep-timeout listeners run there any more, and
  `desktop.hyprland-desktop.sleepCommand` (`hosts/saruman/home.nix`) is
  correspondingly unused there (kept set so it's correct again if
  `useNoctalia` ever flips back off). Rationale: running both hypridle's
  idle-timeout listeners and Noctalia's own idle service at once would have
  raced the same way the compositor and logind once raced over lid-switch
  sleep (item #7's first attempt, before the fix of moving lid handling to
  `services.logind` alone) — two independent daemons both listening for the
  same idle events. **Not gated on any hardware validation of its own** — the
  underlying sleep hang (item #7) is a kernel/amdgpu issue, orthogonal to
  which daemon requests the sleep, so this phase doesn't need its own
  overnight soak the way Phase D did. `custom.lid-undock-hibernate` is
  unaffected — it fires from an independent udev-triggered systemd unit, not
  through hypridle.
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

  **Update 2026-08-31 — `gtk-4.0/gtk.css` ownership moved from dark-theme.nix
  to noctalia.nix, and its WhiteSur import dropped.** `dark-theme.nix` used
  to write this file via `gtk.gtk4.theme = config.gtk.theme` (home-manager's
  legacy pre-26.05 default, still active since `home.stateVersion` is
  "25.11"), which emitted `@import url("file://…/WhiteSur-Dark-solid-purple/
  gtk-4.0/gtk.css")`. That target is a **symlink to the GTK3 resource stub**
  (`@import url("resource:///org/gnome/theme/gtk.css")`) — the nixpkgs
  `whitesur-gtk-theme` build produces no standalone GTK4 stylesheet. That
  `resource://` path is only registered when GTK loads the theme *by name*
  via its `gtk.gresource`, never when home-manager `@import`s the CSS file
  from `~/.config/gtk-4.0/gtk.css`, so the import failed with `Failed to
  import: The resource at "/org/gnome/theme/gtk.css" does not exist` and left
  **every libadwaita app unstyled** — transparent window, white text, no
  rendered UI (reported for NewsFlash). Fix: `dark-theme.nix` now sets
  `gtk.gtk4.theme = null` explicitly (an omitted attr keeps the legacy
  default at this stateVersion), so it no longer writes `gtk-4.0/gtk.css` at
  all; `noctalia.nix` now owns that file (`force = true` kept for the dance
  above) with `text = ''@import url("noctalia.css");''` so libadwaita apps
  get the wallpaper palette on top of the bundled Adwaita stylesheet (dark
  via the `color-scheme` dconf key). On a non-Noctalia host the file simply
  isn't created and libadwaita apps fall back to plain Adwaita dark. GTK3
  apps still get full WhiteSur (unchanged, via `settings.ini`
  `gtk-theme-name`); non-libadwaita pure-GTK4 apps lose WhiteSur and use
  Adwaita — accepted, the user runs essentially none. A stale
  `~/.config/gtk-4.0/gtk.css.hm-bak` left by the old dance is harmless and
  can be deleted by hand.

  **Second half of the same fix (also 2026-08-31):** the gtk.css change alone
  wasn't enough — `dark-theme.nix` also exported `GTK_THEME =
  "WhiteSur-Dark-solid-purple"` via `home.sessionVariables`, and that env var
  force-loads the named theme for *every* GTK toolkit version, bypassing
  `settings.ini` entirely. For GTK4 that re-introduced the exact same broken
  `gtk-4.0/gtk.css` stub → the `Failed to import: The resource at
  "/org/gnome/theme/gtk.css" does not exist` warning kept firing (confirmed
  from NewsFlash's own stderr) and libadwaita apps stayed unstyled. `GTK_THEME`
  is removed from `home.sessionVariables` — GTK3 apps don't need it
  (`~/.config/gtk-3.0/settings.ini` already selects WhiteSur). **Note:**
  `home.sessionVariables` only applies to sessions started after the rebuild,
  so a full logout/login (or `unset GTK_THEME` in the running session) is
  needed before already-running or terminal-launched apps pick up the fix. **Removal condition:** revisit only if nixpkgs'
  `whitesur-gtk-theme` gains a real libadwaita/GTK4 stylesheet or the desktop
  moves off WhiteSur entirely.
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

### 20. Saruman: TLP replaced with power-profiles-daemon (2026-08-19)
- **Where:** `hosts/saruman/configuration.nix` (`services.power-profiles-daemon.enable`
  replaces the old `services.tlp` block), `modules/desktop/noctalia-system.nix`
  (the `power-profiles-daemon.enable = lib.mkForce false` workaround from
  item 19 is gone).
- **Why:** Noctalia's power-profile bar widget/control-center panel only
  speaks `org.freedesktop.UPower.PowerProfiles` over DBus (confirmed by
  reading `src/dbus/power/power_profiles_service.cpp` in the noctalia-shell
  source) — nothing provided that interface while saruman ran TLP, since
  NixOS's TLP module refuses to enable TLP and power-profiles-daemon (PPD)
  together.
- **Road not taken:** TLP ships its own upstream-recommended DBus bridge for
  exactly this interface (`services.tlp.pd.enable`, package `tlp-pd`, built
  from TLP's own source tree — nixpkgs' TLP module assertion literally says
  "upstream does not recommend using tlp together with power-profiles-daemon"
  and points at `tlp.pd` instead). That would have kept TLP as the one thing
  managing power without any real conflict. The user chose a full switch to
  PPD instead, partly hoping it would also help saruman's s2idle sleep/resume
  hang (item 7). Worth being explicit that this is unlikely — item 7's hang
  is bisected to a specific amdgpu DCN3.5+ kernel commit unrelated to which
  power daemon runs — but it's a cheap variable to have changed in case
  behavior shifts; note it if the hang recurs or stops.
- **Accepted gap:** the repo's TLP config was only 4 explicit settings
  (`PLATFORM_PROFILE_ON_AC/BAT`, `CPU_ENERGY_PERF_POLICY_ON_AC/BAT`) — every
  other TLP behavior (USB autosuspend, SATA/PCIe link power management,
  disk/sound power saving, radio power saving on battery) came from TLP's
  compiled-in defaults with no explicit override here, and has **no
  replacement** now that TLP is gone: PPD only covers CPU governor/EPP +
  `platform_profile`. Deliberately not replicated with manual
  `powerManagement`/udev rules for now — accepted regression, revisit if
  battery life measurably worsens.
- **Behavior change:** power profile is now purely user-selected (via
  Noctalia's widget/panel or `noctalia msg power-set`/`power-cycle`) with no
  automatic AC/battery switching — TLP's old `PLATFORM_PROFILE_ON_AC/BAT`
  auto-switching is gone by design, not an oversight.
- **Removal condition:** N/A — this is a deliberate architecture choice, not
  a temporary bodge. Revisit only if the accepted power-saving gap turns out
  to matter in practice (worth trying `services.tlp.pd` instead at that
  point, now that it's a known option), or if PPD's `platform_profile`
  driver turns out to fight the amdgpu s2idle patch (`custom.amdgpu-s2idle-
  patch`, item 7) in some way TLP didn't.

### 22. `hypr-dynamic-cursors` plugin + src-pin overlay for Hyprland 0.56.2 (2026-08-31)
- **Where:** `modules/desktop/hypr-dynamic-cursors.nix`
  (`desktop.hyprland-desktop.dynamicCursors.enable`), enabled on sauron +
  saruman. Loads `pkgs.hyprlandPlugins.hypr-dynamic-cursors`, with its `src`
  bumped by `overlays/hypr-dynamic-cursors-hl-pin.nix` (registered in
  `flake.nix`).
- **What:** "Shake to find" — enlarges the mouse cursor when wiggled, like KDE
  Plasma's Shake Cursor effect. Runs the plugin shake-only (`mode = "none"`);
  none of its cursor tilt/rotate/stretch behaviour is used.
- **Why the overlay is needed:** nixpkgs pins the plugin to commit `f5ba36c7`
  (2026-07-21), whose `hyprpm.toml` only lists Hyprland up to v0.56.1. Our
  Hyprland is v0.56.2 (released 2026-08-05, *after* that plugin commit). The
  compositor/client hashes still matched (nixpkgs builds the plugin against
  our exact `pkgs.hyprland`), so it wasn't the usual ABI check that tripped —
  the old plugin *source* fails to hook 0.56.2's cursor-rendering path at
  init (`[dynamic-cursors] could not hook, hooking failed`), so `PLUGIN_INIT`
  throws and Hyprland pops a "failed to load plugin dynamic-cursors"
  notification; the shake effect never activates. Upstream's `hyprpm.toml`
  maps Hyprland v0.56.2 (`efb50993…`) to plugin commit
  `5a224284872208b5324759d535d65061043725de`; the overlay points `src` there.
- **Watch for:** after a `nix flake update`, a `hyprctl plugin list` that
  doesn't show `dynamic-cursors`, or a "failed to load plugin" notification /
  `[dynamic-cursors]` error in the Hyprland log. If the flake update bumps
  `pkgs.hyprland` past 0.56.2, check upstream `hyprpm.toml` for the plugin
  commit paired with the new Hyprland hash and update the overlay's `rev` +
  `hash` (or drop the overlay if nixpkgs has caught up — compare
  `pkgs.hyprlandPlugins.hypr-dynamic-cursors.src.rev` against the pin).
- **Removal condition:** either nixpkgs' plugin catches up to a commit that
  supports our Hyprland (then delete the overlay), or Hyprland gains a native
  shake-to-find / cursor-zoom option (then drop the plugin entirely and use
  the built-in `cursor:` setting).

### 23. Saruman: kernel patch reverting the HDMI SCDC `scdc_present` gate (2026-09-01, disabled 2026-09-09 — removal condition met)
- **Where:** `patches/amdgpu-hdmi-scdc-gate-revert.patch`,
  `modules/system/amdgpu-hdmi-scdc-fix.nix`
  (`custom.amdgpu-hdmi-scdc-fix.enable`, set in `hosts/saruman/configuration.nix`).
- **What:** Reverts the two guard hunks upstream commit `3471b9a31ce3`
  ("drm/amd/display: Rework HDMI data channel reads") added to
  `read_scdc_caps()` (`link_detection.c`) and `write_scdc_data()`
  (`link_ddc.c`) — both now bail out early unless
  `dc_edid_caps.scdc_present` is set. The `scdc_present` struct field is left
  alone; only the behavioural guards are removed, restoring the unconditional
  pre-7.2 behaviour (always read SCDC caps / write SCDC data on HDMI signals).
- **Why:** `3471b9a31ce3` landed in kernel 7.2 (v6.18). The companion commit
  that populates the flag — "drm/amd/display: Improve HDMI info retrieval",
  which adds `populate_hdmi_info_from_connector()` and does
  `edid_caps->scdc_present = hdmi->scdc.supported;` in
  `dm_helpers_parse_edid_caps()` — is a *separate later patch* not yet in
  nixpkgs' kernel. So `scdc_present` is stuck `false` for every sink, SCDC
  scrambling / `TMDS_CONFIG` is never programmed, and any HDMI link needing it
  (>340 MHz TMDS character rate: 4K / high-refresh, plus DP→HDMI PCON through
  the USB-C dock) comes up misconfigured: the DRM connector reports
  `connected`, HPD fires, but nothing is ever displayed and the compositor
  never gets a usable output. No error is logged — silent misconfiguration.
- **How it was found:** `nix flake update` (commit `c57fc41`, 2026-09-01)
  bumped `pkgs.linuxPackages_latest` 7.1.5 → 7.2.0. Physical HDMI worked on
  generation 446 (last 7.1.5), dead on every generation since. `hyprctl
  monitors` doesn't list the HDMI output at all; the dock's DP→HDMI output
  regressed the same way once exercised. Matches the LKML regression thread
  ["Black screen on HDMI power-cycle after commit 3471b9a31ce3 (7900XTX + LG
  C3)"](https://lkml.org/lkml/2025/12/8/285).
- **Cost:** same as item 7 — the kernel builds locally on every version bump
  (both patches feed `boot.kernelPatches`, so this adds nothing on top of what
  item 7 already forces).
- **Removal condition:** nixpkgs' kernel picks up the "Improve HDMI info
  retrieval" commit (check with
  `grep -rn 'edid_caps->scdc_present =' <kernel-source>` — once that
  assignment exists, delete the patch, the module, and the
  `custom.amdgpu-hdmi-scdc-fix` lines in `hosts/saruman/configuration.nix`).
  If HDMI is *still* broken after this patch, the fallback is pinning
  `boot.kernelPackages = lib.mkForce pkgs.linuxPackages_7_1` on saruman until
  upstream is sorted.
- **UPDATE (2026-09-09): condition confirmed met — disabled, not yet
  physically tested.** While investigating why saruman's kernel was still
  compiling locally after item 7's patch was disabled, went to verify this
  item's removal condition directly instead of assuming it still held.
  Extracted the *actual* kernel tarball nixpkgs fetches for this build
  (`nix build nixpkgs#linuxPackages_latest.kernel.src`, currently
  `linux-7.2.2.tar.xz`) and grepped it — `amdgpu_dm_helpers.c` line 1136,
  inside `populate_hdmi_info_from_connector()`, already reads
  `edid_caps->scdc_present = hdmi->scdc.supported;`. Cross-checked against
  GitHub's `torvalds/linux` mirror: the fix commit
  (`c78e31bcf586f1c910a2636650840f5ce1cb1c63`, "drm/amd/display: Improve HDMI
  info retrieval", authored by Ivan Lipski, merged into mainline alongside
  the regressing commit in the same Dec 2025 `drm-next` pull) is an ancestor
  of the `v7.2` tag itself — confirmed present even at `v7.2` (before any
  `.1`/`.2` stable point release), so **this host's kernel was never
  actually missing the setter** the way the 2026-09-01 diagnosis (right
  above, "Why") assumed. That diagnosis wasn't backed by the same kind of
  direct empirical check used for item 7's kernel patch (disassembling the
  shipped `.ko`) — it looks like it was reasoned from checking mainline
  source at some point without re-verifying against the specific tarball
  nixpkgs actually pins, and the assumption was never revisited. Disabled
  `custom.amdgpu-hdmi-scdc-fix.enable` (`hosts/saruman/configuration.nix`).
  **Not yet physically tested** — the patch's guard-removal is likely
  harmless/redundant now that `scdc_present` is genuinely populated upstream,
  but this needs a real rebuild + reboot + HDMI/dock-DP→HDMI check before
  calling it closed. If either regresses, re-enable the module (one line)
  and investigate further — the setter being present doesn't guarantee
  `hdmi->scdc.supported` itself evaluates true for this exact sink/dock in
  every case.

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
- **`dwarfs` GCC 15 / fmt 12.2.0 overlay (was item #21).** `nix flake update`
  on 2026-08-27 bumped nixpkgs to GCC 15 + fmt 12.2.0, and the then-current
  `dwarfs` v0.14.0 vendored a folly/fbthrift snapshot that broke against both
  (`memcpy is not a member of std`; `format is not a member of fmt`).
  `overlays/dwarfs-nixpkgs-update-fix.nix` worked around it with a `postPatch`
  `#include <cstring>` and `.override { fmt = fmt_11; }`. The 2026-09-01
  `nix flake update` moved nixpkgs to `dwarfs` v0.15.7, whose source tree no
  longer ships the offending vendored folly (the `sed` target
  `folly/folly/lang/Exception.h` doesn't exist) and builds against system
  `fmt` with no `postPatch` — so the overlay's `sed` hard-failed. Overlay
  deleted and unregistered from `flake.nix`; plain `pkgs.dwarfs` builds (it's
  even in cache.nixos.org). This is also what prompted the
  `home-manager.sharedModules` overlay-propagation fix in `flake.nix`'s
  `overlayModule` — that stays (the other overlays still need it), along with
  the note to double-check `patool` via `bottles`/`wine.nix` now that its
  overlay actually reaches home-manager packages.

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
