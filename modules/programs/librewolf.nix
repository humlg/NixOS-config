{ config, lib, pkgs, nur, ... }:

let
  cfg = config.programs.librewolf-custom;
  addons = nur.legacyPackages.${pkgs.system}.repos.rycee.firefox-addons;
in
{
  options.programs.librewolf-custom = {
    enable = lib.mkEnableOption "LibreWolf browser with extensions and settings";
  };

  config = lib.mkIf cfg.enable {
    programs.librewolf = {
      enable = true;

      profiles.default = {
        isDefault = true;

        extensions.packages = with addons; [
          ublock-origin
          pywalfox
          bitwarden
          consent-o-matic
        ];

        search = {
          default = "ddg";
          force = true;
        };

        settings = {
          # Dark browser UI theme
          "extensions.activeThemeID" = "firefox-compact-dark@mozilla.org";
          # Force dark color scheme for web content (1 = dark, 2 = follow system)
          "layout.css.prefers-color-scheme.content-override" = 1;
          # Disable first-run page
          "browser.startup.homepage_override.mstone" = "ignore";
          # Pywalfox native messaging
          "extensions.autoDisableScopes" = 0;
        };
      };
    };
  };
}
