{ config, lib, pkgs, ... }:

let
  cfg = config.bundles.general;
in
{
  imports = [
    ../programs/git.nix
    ../programs/kitty.nix
  ];
  options.bundles.general = {
    enable = lib.mkEnableOption "General always-installed user packages bundle";
  };

  config = lib.mkIf cfg.enable {
    services.udiskie.enable = true;
    programs.git.enable = true;
    programs.kitty.enable = true;

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

      # Claude code for troubleshooting
      claude-code
    ];
  };
}
