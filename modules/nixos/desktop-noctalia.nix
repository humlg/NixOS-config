{ config, lib, pkgs, inputs, ... }:

let
  cfg = config.custom.noctalia;
in
{
  imports = [
    inputs.noctalia.nixosModules.default
  ];

  # Separate NixOS-tree option from desktop.hyprland-desktop.useNoctalia (home tree) — paired by convention, toggled independently.
  options.custom.noctalia.enable = lib.mkEnableOption "Noctalia desktop shell system services";

  config = lib.mkIf cfg.enable {
    programs.noctalia = {
      enable = true;
      systemd.enable = true;
      package = pkgs.noctalia-patched;  # perceptual backlight, docs/maintenance.md #35
      recommendedServices.enable = true;
    };

    # recommendedServices.enable default-enables power-profiles-daemon (docs/maintenance.md #20).
  };
}
