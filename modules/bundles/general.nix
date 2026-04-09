{ config, lib, pkgs, ... }:

let
  cfg = config.bundles.general;
in
{
  imports = [
    ../programs/git.nix
    ../programs/kitty.nix
    ../programs/vim.nix
    ../programs/btop.nix
    ../programs/claude-code.nix
    ../desktop/default-apps.nix
  ];
  options.bundles.general = {
    enable = lib.mkEnableOption "General always-installed user packages bundle";
  };

  config = lib.mkIf cfg.enable {
    services.udiskie.enable = true;
    programs.git.enable = true;
    programs.kitty.enable = true;
    programs.vim.enable = true;
    programs.btop.enable = true;
    programs.claude-code.enable = true;

    home.packages = with pkgs; [
      firefox
      thunderbird
      obsidian

      # Common daily drivers (adjust to taste)
      mpv
      vlc
      feh
      kdePackages.gwenview
      mc

      # Archives / utilities
      unzip
      p7zip
      ripgrep
      fd
      jq
      tree
      fzf
      qdirstat

      # AppImage management
      gearlever

      ffmpeg
      lazygit

      python315
      wev
    ];
  };
}
