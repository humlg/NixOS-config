{ config, lib, pkgs, ... }:

let
  cfg = config.desktop.hyprland;
in
{
  options.desktop.hyprland = {
    enable = lib.mkEnableOption "Hyprland desktop";

    withUWSM = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Enable UWSM integration for Hyprland.";
    };

    xwayland = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Enable XWayland support.";
    };

    sddm = {
      enable = lib.mkOption {
        type = lib.types.bool;
        default = true;
        description = "Enable SDDM display manager for Hyprland sessions.";
      };

      theme = lib.mkOption {
        type = lib.types.nullOr lib.types.str;
        default = "sugar-dark";
        description = "SDDM theme (null to leave unset).";
      };
    };

    polkitAgent = lib.mkOption {
      type = lib.types.package;
      default = pkgs.lxqt.lxqt-policykit;
      description = "Polkit agent package providing lxqt-policykit-agent.";
    };

    sessionVariables = lib.mkOption {
      type = lib.types.attrsOf lib.types.str;
      default = {
        WLR_NO_HARDWARE_CURSORS = "1";
        NIXOS_OZONE_WL = "1";
        XCURSOR_THEME = "volantes_cursors";
        XCURSOR_SIZE = "48";
        KITTY_DISABLE_WAYLAND = "1";
      };
      description = "Session variables for the Hyprland session.";
    };
  };

  config = lib.mkIf cfg.enable {
    programs.hyprland = {
      enable = true;
      withUWSM = cfg.withUWSM;
      xwayland.enable = cfg.xwayland;
    };

    services.displayManager.sddm = lib.mkIf cfg.sddm.enable {
      enable = true;
      wayland.enable = true;
    };

    services.displayManager.sddm.theme = lib.mkIf (cfg.sddm.enable && cfg.sddm.theme != null) cfg.sddm.theme;

    security.polkit.enable = true;

    systemd.user.services.polkit-agent = {
      description = "Polkit Authentication Agent";
      wantedBy = [ "default.target" ];
      serviceConfig = {
        ExecStart = "${cfg.polkitAgent}/bin/lxqt-policykit-agent";
        Restart = "on-failure";
      };
    };

    xdg.portal = {
      enable = true;
      extraPortals = [ pkgs.xdg-desktop-portal-hyprland ];
    };

    environment.sessionVariables = cfg.sessionVariables;
  };
}
