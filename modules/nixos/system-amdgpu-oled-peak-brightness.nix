{ config, lib, ... }:

let
  cfg = config.custom.amdgpu-oled-peak-brightness;
in
{
  options.custom.amdgpu-oled-peak-brightness = {
    enable = lib.mkEnableOption ''
      a local kernel patch that makes 100% eDP backlight the panel's EDID peak
      luminance (MaxCLL) instead of its max frame-average (MaxFALL). Compiles
      the kernel locally on every version bump. Full rationale and removal
      condition: docs/maintenance.md #34.
    '';
  };

  config = lib.mkIf cfg.enable {
    boot.kernelPatches = [{
      name  = "amdgpu-oled-peak-brightness";
      patch = ../../patches/amdgpu-oled-peak-brightness.patch;
    }];
  };
}
