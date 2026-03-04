{ config, lib, pkgs, ... }:

let
  cfg = config.bundles.general;
in
{
  options.bundles.general = {
    enable = lib.mkEnableOption "General always-installed user packages bundle";
  };

  config = lib.mkIf cfg.enable {
    home.packages = with pkgs; [
      firefox
      thunderbird
      obsidian

      # Common daily drivers (adjust to taste)
      mpv
      vlc

      # Archives / utilities
      unzip
      p7zip
      ripgrep
      fd
      jq
      tree
    ];
  };
}
