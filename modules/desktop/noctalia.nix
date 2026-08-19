{ config, lib, pkgs, inputs, ... }:

let
  cfg = config.desktop.hyprland-desktop;
in
{
  imports = [
    inputs.noctalia.homeModules.default
  ];

  # Pilot only — gated on useNoctalia so it can run alongside AGS/swaync/
  # hyprlock/waypaper without disabling any of them. See the Noctalia
  # migration plan (2026-08-19) for the staged cutover this is part of.
  config = lib.mkIf (cfg.enable && cfg.useNoctalia) {
    programs.noctalia = {
      enable = true;
      systemd.enable = true;
      package = inputs.noctalia.packages.${pkgs.stdenv.hostPlatform.system}.default;
      # Left at Noctalia's own defaults for the initial pilot — bar
      # layout/widgets, theme source, lock screen, etc. all use Noctalia's
      # out-of-the-box config until each piece is validated and settings get
      # tuned to match the existing setup.
      #
      # Noctalia has its own wallpaper-derived theme (matugen-style, not
      # wallust) for itself, but wallust still drives every other themed app
      # (hyprlock, hyprland core, rofi, btop, cava, vim). Since waypaper's
      # post_command hook (the previous wallust trigger) is disabled on this
      # host, wire Noctalia's own wallpaper_changed hook to the same
      # `wallust run -s ... && reload-desktop` sequence so those apps keep
      # re-theming when the wallpaper changes through Noctalia's own picker.
      # Noctalia's own colors will not match wallust's output — the two use
      # different palette generators — that divergence is a known, accepted
      # gap for this pilot (see maintenance.md item 19).
      settings.hooks.wallpaper_changed = ''wallust run -s "$NOCTALIA_WALLPAPER_PATH" && reload-desktop'';
    };
  };
}
