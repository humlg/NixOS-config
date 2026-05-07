{ config, lib, pkgs, ... }:

let
  cfg = config.programs.webapps;

  iconDir = "${config.home.homeDirectory}/.local/share/icons/hicolor/128x128/apps";

  getDomain = url:
    let m = builtins.match "https?://([^/]+).*" url;
    in if m != null then builtins.head m else null;

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

  # Webapps that need auto-fetched icons (no explicit icon set)
  autoIconApps = lib.filterAttrs (_: app: app.icon == null) cfg.apps;

  mkWebapp = key: app:
    let
      launchScript = pkgs.writeShellScript "webapp-${key}" ''
        exec ${pkgs.chromium}/bin/chromium \
          --app=${lib.escapeShellArg app.url} \
          --class=${lib.escapeShellArg "webapp-${app.name}"} \
          --user-data-dir="$HOME/.local/share/webapps/${app.name}" \
          ${lib.escapeShellArgs app.extraArgs} "$@"
      '';
      # Use a theme icon name so GTK (and AGS) can find it by name.
      # Auto-fetched icons are installed into the hicolor theme as webapp-<key>.
      effectiveIcon =
        if app.icon != null then app.icon
        else "webapp-${lib.toLower key}";
    in
    {
      name       = app.name;
      exec       = toString launchScript;
      icon       = effectiveIcon;
      terminal   = false;
      type       = "Application";
      categories = app.categories;
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

    home.activation.fetchWebappIcons = lib.mkIf (autoIconApps != {}) (
      lib.hm.dag.entryAfter [ "writeBoundary" ] ''
        mkdir -p "${iconDir}"
        ${lib.concatStringsSep "\n" (lib.mapAttrsToList (key: app:
          let
            domain   = getDomain app.url;
            iconName = "webapp-${lib.toLower key}";
          in lib.optionalString (domain != null) ''
            if [ ! -f "${iconDir}/${iconName}.png" ]; then
              ${pkgs.curl}/bin/curl -fsSL -o "${iconDir}/${iconName}.png" \
                "https://www.google.com/s2/favicons?domain=${domain}&sz=128" 2>/dev/null || true
            fi
          ''
        ) autoIconApps)}
        ${pkgs.gtk3}/bin/gtk-update-icon-cache -f -t \
          "${config.home.homeDirectory}/.local/share/icons/hicolor" 2>/dev/null || true
      ''
    );
  };
}
