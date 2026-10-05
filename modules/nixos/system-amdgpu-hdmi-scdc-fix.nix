{ config, lib, ... }:

let
  cfg = config.custom.amdgpu-hdmi-scdc-fix;
in
{
  options.custom.amdgpu-hdmi-scdc-fix = {
    enable = lib.mkEnableOption ''
      a local kernel patch reverting the HDMI SCDC scdc_present gate that
      broke HDMI/DP->HDMI output on saruman. Compiles the kernel locally on
      every version bump. Full rationale and removal condition: docs/maintenance.md #23.
    '';
  };

  config = lib.mkIf cfg.enable {
    boot.kernelPatches = [{
      name  = "amdgpu-hdmi-scdc-gate-revert";
      patch = ../../patches/amdgpu-hdmi-scdc-gate-revert.patch;
    }];
  };
}
