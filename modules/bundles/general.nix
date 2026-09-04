{ config, lib, pkgs, inputs, ... }:

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
      inputs.agenix.packages.${pkgs.stdenv.hostPlatform.system}.default
      firefox
      thunderbird
      obsidian
      whatsapp-electron
      telegram-desktop

      # Common daily drivers (adjust to taste)
      mpv
      vlc
      feh
      kdePackages.gwenview
      kdePackages.okular
      mc

      # Archives / utilities
      unzip
      zip
      p7zip
      ripgrep
      fd
      jq
      tree
      fzf
      qdirstat
      kdePackages.ark
      gnome-disk-utility

      # AppImage management
      gearlever

      ffmpeg
      lazygit

      python315
      wev
      powertop
    ];
  };
}
