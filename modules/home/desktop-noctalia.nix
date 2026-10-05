{ config, lib, pkgs, inputs, ... }:

let
  cfg = config.desktop.hyprland-desktop;
in
{
  imports = [
    inputs.noctalia.homeModules.default
  ];

  # Gated on useNoctalia — runs alongside AGS/swaync/hyprlock/waypaper, disables none of them.
  config = lib.mkIf (cfg.enable && cfg.useNoctalia) {
    programs.noctalia = {
      enable = true;
      systemd.enable = true;
      package = inputs.noctalia.packages.${pkgs.stdenv.hostPlatform.system}.default;
      # Wallust still drives every other themed app; Noctalia gets its own
      # wallpaper-derived palette (won't match wallust's exactly) — docs/architecture.md.
      settings.hooks.wallpaper_changed = ''wallust run -s "$NOCTALIA_WALLPAPER_PATH" && reload-desktop'';
    };

    # Binary Noctalia's screen_recorder plugin shells out to — plugin itself enabled via settings.toml.
    home.packages = [ pkgs.gpu-screen-recorder ];

    # Seed-once, not Nix-managed after that — docs/architecture.md.
    home.activation.seedNoctaliaSettings = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      if [[ ! -f "$HOME/.local/state/noctalia/settings.toml" ]]; then
        $DRY_RUN_CMD mkdir -p "$HOME/.local/state/noctalia"
        $DRY_RUN_CMD cp ${./noctalia-settings-seed.toml} "$HOME/.local/state/noctalia/settings.toml"
        $DRY_RUN_CMD touch "$HOME/.local/state/noctalia/.setup-complete"
      fi
    '';

    # force = true breaks a backup/clobber loop with Noctalia's own live GTK4 theming — docs/architecture.md.
    xdg.configFile."gtk-4.0/gtk.css" = {
      force = true;
      text = ''@import url("noctalia.css");'';
    };
  };
}
