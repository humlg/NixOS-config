{ config, lib, pkgs, inputs, ... }:

let
  cfg = config.programs.zen-browser-custom;
in
{
  options.programs.zen-browser-custom = {
    enable = lib.mkEnableOption "Zen Browser with DuckDuckGo as default search engine";
  };

  config = lib.mkIf cfg.enable {
    environment.systemPackages = [
      inputs.zen-browser.packages.${pkgs.stdenv.hostPlatform.system}.default
    ];

    # Zen reads system-wide policies from /etc/zen/policies/policies.json
    environment.etc."zen/policies/policies.json".text = builtins.toJSON {
      policies = {
        DisableAppUpdate = true;
        SearchEngines = {
          Default = "DuckDuckGo";
          PreventInstalls = false;
        };
      };
    };
  };
}
