{ config, lib, ... }:

let
  cfg = config.bundles.workstation;
in
{
  imports = [
    ./program-ssh-keys.nix
    ./program-transmission.nix
    ./program-jellyfin-media-player.nix
    ./bundle-desktop-apps.nix
  ];

  options.bundles.workstation = {
    enable = lib.mkEnableOption "Desktop workstation extras shared by sauron and saruman";
  };

  config = lib.mkIf cfg.enable {
    bundles.desktop-apps.enable = true;
    custom.transmission-vpn.enable = true;
    programs.jellyfin-media-player.enable = true;
  };
}
