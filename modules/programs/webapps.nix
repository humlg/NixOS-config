{ config, lib, pkgs, ... }:

let
  cfg = config.programs.webapps;

  webappType = lib.types.submodule ({ name, ... }: {
    options = {
      url = lib.mkOption {
        type        = lib.types.str;
        description = "The URL to open.";
      };

      name = lib.mkOption {
        type        = lib.types.str;
        default     = name;
        description = "Human-readable app name (defaults to the attribute name).";
      };

      icon = lib.mkOption {
        type        = lib.types.nullOr (lib.types.either lib.types.str lib.types.path);
        default     = null;
        description = "Icon name from the current theme, or path to a .png/.svg file.";
      };

      categories = lib.mkOption {
        type        = lib.types.listOf lib.types.str;
        default     = [ "Network" ];
        description = "XDG desktop categories.";
      };

      extraArgs = lib.mkOption {
        type        = lib.types.listOf lib.types.str;
        default     = [];
        description = "Additional Chromium command-line flags.";
      };
    };
  });

  mkWebapp = key: app:
    let
      launchScript = pkgs.writeShellScript "webapp-${key}" ''
        exec ${pkgs.chromium}/bin/chromium \
          --app=${lib.escapeShellArg app.url} \
          --class=${lib.escapeShellArg "webapp-${app.name}"} \
          --user-data-dir="$HOME/.local/share/webapps/${app.name}" \
          ${lib.escapeShellArgs app.extraArgs} "$@"
      '';
    in
    {
      name       = app.name;
      exec       = toString launchScript;
      terminal   = false;
      type       = "Application";
      categories = app.categories;
    } // lib.optionalAttrs (app.icon != null) {
      icon = app.icon;
    };
in
{
  options.programs.webapps = {
    enable = lib.mkEnableOption "Chromium-based web application shortcuts";

    apps = lib.mkOption {
      type        = lib.types.attrsOf webappType;
      default     = {};
      description = "Set of web applications to create desktop entries for.";
    };
  };

  config = lib.mkIf cfg.enable {
    xdg.desktopEntries = lib.mapAttrs mkWebapp cfg.apps;
  };
}
