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
      package = inputs.noctalia.packages.${pkgs.stdenv.hostPlatform.system}.default;
      recommendedServices.enable = true;
    };

    # recommendedServices.enable default-enables power-profiles-daemon (docs/maintenance.md #20).
  };
}
