{ config, lib, pkgs, ... }: # HM

# "Shake to find" for the Hyprland cursor — wiggle the mouse and the pointer
# briefly grows, like KDE Plasma's Shake Cursor effect (and macOS).
#
# Backed by the hypr-dynamic-cursors plugin (VirtCode). That plugin's main
# feature is realistic cursor tilt/rotate/stretch; this module deliberately
# runs it shake-only (`mode = "none"`), so the pointer keeps its normal shape
# and the *only* behaviour added is the grow-on-shake.
#
# The plugin comes from nixpkgs (`pkgs.hyprlandPlugins.*`), which builds it
# against the same `pkgs.hyprland` Home Manager loads — so the ABI always
# matches. Do NOT install it via hyprpm (that builds against a git Hyprland
# and will fight the Nix-managed compositor).

let
  cfg  = config.desktop.hyprland-desktop;
  dcfg = cfg.dynamicCursors;
in
{
  options.desktop.hyprland-desktop.dynamicCursors = {
    enable = lib.mkEnableOption ''
      hypr-dynamic-cursors "shake to find": the mouse cursor grows when you
      wiggle it (KDE / macOS style). Runs shake-only — the plugin's cursor
      tilt/rotate/stretch effects are left off (mode = "none")
    '';

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

    # Appended after the main Lua config (mkAfter). Home Manager emits the
    # hl.plugin.load(...) call at the top of hyprland.lua, so by the time this
    # runs the plugin is loaded and the `hl.plugin.dynamic_cursors` guard is
    # true. The guard keeps the config from erroring if the plugin ever fails
    # to load.
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
