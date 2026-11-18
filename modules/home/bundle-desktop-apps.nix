{ config, lib, pkgs, options, ... }:

let
  cfg = config.bundles.desktop-apps;
in
{
  options.bundles.desktop-apps = {
    enable = lib.mkEnableOption "Common desktop applications";
  };

  config = lib.mkIf cfg.enable (lib.mkMerge [
    {
      home.packages = with pkgs; [
        discord
        vscode
        kdePackages.kate
        chromium
        spotify
        megasync
        appimage-run
      ];
    }

    # Discord toggle mute on Scroll Lock via the GlobalShortcuts portal (`hyprctl globalshortcuts` lists the ID).
    # Both keysyms, since the Scroll Lock key may report as either. Only on hosts with the Hyprland module.
    (lib.optionalAttrs (options ? desktop.hyprland-desktop) {
      desktop.hyprland-desktop.extraLuaConfig = ''
        hl.bind("F15",         hl.dsp.global("discord:discord-toggle-mute"), { locked = true })
        hl.bind("Scroll_Lock", hl.dsp.global("discord:discord-toggle-mute"), { locked = true })
      '';
    })
  ]);
}
