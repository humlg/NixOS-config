{ config, lib, ... }:

let
  cfg = config.custom.amdgpu-hdmi-scdc-fix;
in
{
  options.custom.amdgpu-hdmi-scdc-fix = {
    enable = lib.mkEnableOption ''
      a local kernel patch that reverts the scdc_present gating added by
      upstream commit 3471b9a31ce3 ("drm/amd/display: Rework HDMI data channel
      reads", kernel 7.2). That commit makes amdgpu skip all SCDC caps reads
      and TMDS_CONFIG writes unless dc_edid_caps.scdc_present is set — but the
      commit that actually sets that flag ("drm/amd/display: Improve HDMI info
      retrieval") has not landed in this kernel, so it is stuck false for every
      sink and any HDMI link needing SCDC (>340 MHz TMDS: 4K/high-refresh, and
      DP->HDMI PCON via a USB-C dock) comes up misconfigured — connector reads
      "connected" but nothing is displayed. Physical HDMI on saruman
      (Radeon 880M, DCN 3.5) last worked on kernel 7.1.5 (generation 446),
      which predates the regression.

      Like custom.amdgpu-s2idle-patch, this forces the kernel to build locally
      on every version bump (~15-25 min). See
      patches/amdgpu-hdmi-scdc-gate-revert.patch and maintenance.md for the
      removal condition.
    '';
  };

  config = lib.mkIf cfg.enable {
    boot.kernelPatches = [{
      name  = "amdgpu-hdmi-scdc-gate-revert";
      patch = ../../patches/amdgpu-hdmi-scdc-gate-revert.patch;
    }];
  };
}
