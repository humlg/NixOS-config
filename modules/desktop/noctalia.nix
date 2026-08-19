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
      # Left at Noctalia's own defaults for the initial pilot (Phase B) —
      # bar layout/widgets, theme source, wallpaper handling, lock screen,
      # etc. all use Noctalia's out-of-the-box config until each piece is
      # validated and settings get tuned to match the existing setup.
    };
  };
}
