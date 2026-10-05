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

  # Seeds systemd-localed's keyboard layout before the greeter starts — docs/maintenance.md #10.
  systemd.services.seed-x11-locale1 = {
    description = "Seed systemd-localed X11 keymap for the SDDM greeter";
    wantedBy = [ "multi-user.target" ];
    before = [ "display-manager.service" ];
    serviceConfig.Type = "oneshot";
    script =
      with config.services.xserver.xkb;
      "${pkgs.systemd}/bin/localectl set-x11-keymap --no-convert '${layout}' '${model}' '${variant}' '${options}'";
  };

  environment.systemPackages = with pkgs; [
    sddm-astronaut
    volantes-cursors
  ];
}