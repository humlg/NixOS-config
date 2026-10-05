{ config, lib, pkgs, ... }:

let
  cfg = config.bundles.workstation;
in
{
  imports = [
    ./program-zen-browser.nix
    ./program-mullvad.nix
    ./service-ollama.nix
    ./service-sunshine.nix
    ./service-moonlight.nix
  ];

  options.bundles.workstation = {
    enable = lib.mkEnableOption "Desktop workstation extras shared by sauron and saruman";
  };

  config = lib.mkIf cfg.enable {
    services.colord.enable = true;

    # Also carries the local Dark Project Bushido 87 controller on saruman — see
    # overlays/openrgb-darkproject-bushido.nix and docs/maintenance.md.
    services.udev.packages = [ pkgs.openrgb ];

    programs.zen-browser-custom.enable = true;
    programs.kdeconnect.enable = true;
    custom.mullvad.enable = true;
    custom.moonlight.enable = true;
    custom.sunshine.enable = true;
    custom.sunshine.autoStart = lib.mkDefault true;

    environment.systemPackages = [ pkgs.openrgb ];
  };
}
