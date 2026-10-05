{ config, lib, pkgs, ... }: # HM

# "Shake to find" cursor (KDE/macOS style) via hypr-dynamic-cursors, shake-only
# (mode = "none"). Install via nixpkgs, not hyprpm — ABI must match pkgs.hyprland.

let
  cfg  = config.desktop.hyprland-desktop;
  dcfg = cfg.dynamicCursors;
in
{
  options.desktop.hyprland-desktop.dynamicCursors = {
    enable = (lib.mkEnableOption ''
      hypr-dynamic-cursors "shake to find": the mouse cursor grows when you
      wiggle it (KDE / macOS style). Runs shake-only — the plugin's cursor
      tilt/rotate/stretch effects are left off (mode = "none")
    '') // { default = true; };

    threshold = lib.mkOption {
      type    = lib.types.float;
      default = 6.0;
      description = "Shake-detection sensitivity. Lower = triggers on a gentler wiggle.";
    };

    base = lib.mkOption {
      type    = lib.types.float;
      default = 4.0;
      description = "Magnification factor applied the moment a shake is detected.";
    };

    speed = lib.mkOption {
      type    = lib.types.float;
      default = 4.0;
      description = "Extra magnification added per second while the shake continues.";
    };

    limit = lib.mkOption {
      type    = lib.types.float;
      default = 0.0;
      description = "Maximum magnification factor. Anything below 1 means uncapped.";
    };

    timeout = lib.mkOption {
      type    = lib.types.int;
      default = 2000;
      description = "Milliseconds the cursor stays enlarged after the shake stops.";
    };
  };

  config = lib.mkIf (cfg.enable && dcfg.enable) {
    assertions = [{
      assertion = cfg.useLuaConfig;
      message = ''
        desktop.hyprland-desktop.dynamicCursors requires useLuaConfig = true —
        this module only emits the Lua-format plugin config.
      '';
    }];

    wayland.windowManager.hyprland.plugins = [
      pkgs.hyprlandPlugins.hypr-dynamic-cursors
    ];

    # mkAfter: plugin must already be loaded (top of hyprland.lua) when this guard runs.
    wayland.windowManager.hyprland.extraConfig = lib.mkAfter ''

      -- ── hypr-dynamic-cursors: shake-to-find only ───────────────────
      if hl.plugin.dynamic_cursors then
        hl.config({ plugin = { dynamic_cursors = {
          enabled = true,
          mode    = "none",
          shake = {
            enabled   = true,
            threshold = ${toString dcfg.threshold},
            base      = ${toString dcfg.base},
            speed     = ${toString dcfg.speed},
            influence = 0.0,
            limit     = ${toString dcfg.limit},
            timeout   = ${toString dcfg.timeout},
            effects   = false,
            ipc       = false,
          },
        } } })
      end
    '';
  };
}
