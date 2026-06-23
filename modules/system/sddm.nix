{ config, lib, pkgs, ... }:

{
  services.displayManager.sddm  = {
    package = pkgs.kdePackages.sddm;
    extraPackages = with pkgs; [
      sddm-astronaut
      kdePackages.qt5compat

      kdePackages.qtmultimedia
      kdePackages.qtdeclarative
      kdePackages.qtsvg

      volantes-cursors
    ];
    enable = true;
    wayland.enable = true;
    wayland.compositor = "kwin";
    autoNumlock = true;
    theme = "sddm-astronaut-theme";
    enableHidpi = true;
    settings = {
      General = {
        DisplayServer = "wayland";
      };
      Theme = {
        CursorTheme = "volantes_cursors";
        CursorSize = 24;
      };
    };
  };

  security.pam.services.sddm.enableGnomeKeyring = true;
  services.gnome.gnome-keyring.enable = true;

  environment.systemPackages = with pkgs; [
    sddm-astronaut
    volantes-cursors
  ];
}