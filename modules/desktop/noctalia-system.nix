{ config, lib, pkgs, inputs, ... }:

let
  cfg = config.custom.noctalia;
in
{
  imports = [
    inputs.noctalia.nixosModules.default
  ];

  # Shares the "noctalia" name with desktop.hyprland-desktop.useNoctalia in
  # noctalia.nix by convention (same pairing as bundles.yg-work /
  # yg-work-system.nix) but is a separate NixOS-tree option, toggled
  # independently per host.
  options.custom.noctalia.enable = lib.mkEnableOption "Noctalia desktop shell system services";

  config = lib.mkIf cfg.enable {
    programs.noctalia = {
      enable = true;
      systemd.enable = true;
      package = inputs.noctalia.packages.${pkgs.stdenv.hostPlatform.system}.default;
      recommendedServices.enable = true;
    };

    # recommendedServices.enable above default-enables power-profiles-daemon
    # (needed for Noctalia's power-profile widget/panel — see maintenance.md
    # item 20) and lets it apply with no override now that saruman runs it
    # instead of TLP.
  };
}
