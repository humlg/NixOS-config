{ config, lib, pkgs, ... }:

{
  programs.hyprland = {
    enable = true;
    withUWSM = true;
    xwayland.enable = true;
  };

  security.polkit.enable = true;

  xdg.portal = {
    enable = true;
    extraPortals = [ pkgs.xdg-desktop-portal-hyprland ];
  };

  services.xserver.xkb.layout = "cz";

  environment.sessionVariables = {
    WLR_NO_HARDWARE_CURSORS = "1";
    NIXOS_OZONE_WL          = "1";
  };

  services.libinput.enable = true;

  services.pipewire = {
    enable = true;
    pulse.enable = true;
  };

  services.printing.enable = true;

  programs.firefox.enable = true;
  programs.thunar.enable = true;
}
