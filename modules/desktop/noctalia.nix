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

    # Noctalia's own GTK4 live-theming (assets/templates/gtk/apply.sh in the
    # noctalia-shell source, run by its theming daemon on every start/theme
    # change) detects that dark-theme.nix's home-manager-managed gtk-4.0/
    # gtk.css is a read-only Nix-store symlink, deletes it, and replaces it
    # with a plain file carrying its own `@import url("noctalia.css");`
    # line. The next activation then finds a real file where it expects its
    # symlink, backs it up to gtk.css.hm-bak, and re-symlinks — which then
    # collects a stale .hm-bak that blocks the activation *after* that with
    # "existing file ... would be clobbered", since nothing ever removes it.
    # `force = true` makes home-manager skip the backup step and just
    # overwrite unconditionally, breaking that cycle; Noctalia re-patches its
    # import back in within moments of the service restarting, so this
    # doesn't lose the live theming, just the doomed backup dance. See
    # maintenance.md item 19.
    xdg.configFile."gtk-4.0/gtk.css".force = true;
  };
}
