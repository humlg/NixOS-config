{ config, lib, pkgs, ... }:

let
  cfg = config.programs.jellyfin-media-player;
in
{
  options.programs.jellyfin-media-player = {
    enable = lib.mkEnableOption "Jellyfin Media Player (native Qt/mpv desktop client)";
  };

  config = lib.mkIf cfg.enable {
    home.packages = [ pkgs.jellyfin-media-player ];
  };
}
