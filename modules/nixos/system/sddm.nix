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

  # SDDM's kwin greeter is started with `--locale1`, which makes it fetch the
  # keyboard layout from systemd-localed's D-Bus state instead of the static
  # /etc/X11/xorg.conf.d/00-keyboard.conf file. That D-Bus property is empty
  # on every fresh boot (nothing else on NixOS ever populates it declaratively),
  # so the greeter silently falls back to "us". Seed it from the same xkb
  # settings used everywhere else before display-manager starts.
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