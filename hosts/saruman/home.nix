{ config, pkgs, ... }:

{
  imports = [
    ../../modules/desktop/dark-theme.nix
    ../../modules/bundles/general.nix
    ../../modules/desktop/hyprland-desktop.nix
    ../../modules/bundles/yg-work.nix
    ../../modules/programs/mullvad.nix
  ];

  nixpkgs.config.allowUnfree = true;

  bundles.general.enable = true;
  bundles.yg-work.enable = true;

  desktop.hyprland-desktop = {
    enable = true;

    monitors = ''
      monitor = eDP-1,2880x1800@120,0x0,2,bitdepth,10,cm,wide
      monitor = desc:Iiyama North America PL2797H 12497503A1590,1920x1080@100,1440x0,1
      monitor = ,preferred,auto,1,mirror,eDP-1
    '';

    extraConfig = ''
      general {
          col.active_border = $color1
          col.inactive_border = rgba(595959aa)
      }
    '';

    screenshotDir = "/home/david/Pictures/Screenshots";
    lockScreen    = "hyprlock";
    terminal      = "kitty";
    fileManager   = "thunar";
  };

  home.username = "david";
  home.homeDirectory = "/home/david";

  home.stateVersion = "25.11";

  home.packages  = [
    pkgs.helvum
    pkgs.qemu
    pkgs.cameractrls-gtk4
  ];

  home.file = {};

  home.sessionVariables = {
    EDITOR = "vim";
    XCURSOR_THEME = "volantes_cursors";
    XCURSOR_SIZE = 24;
  };

  home.pointerCursor = {
    name = "volantes_cursors";
    size = 24;
    package = pkgs.volantes-cursors;
    gtk.enable = true;
    x11.enable = true;
  };

  gtk.cursorTheme = {
    name = "volantes_cursors";
    size = 24;
    package = pkgs.volantes-cursors;
  };

  xresources.properties = {
    "Xft.dpi" = 96;
  };

  programs.zsh.enable = true;
  programs.home-manager.enable = true;
}
