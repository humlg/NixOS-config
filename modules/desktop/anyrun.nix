{ config, lib, pkgs, inputs, ... }:

let
  cfg    = config.desktop.hyprland-desktop;
  system = pkgs.stdenv.hostPlatform.system;
in
{
  imports = [
    inputs.anyrun.homeManagerModules.anyrun
  ];

  config = lib.mkIf cfg.enable {
    programs.anyrun = {
      enable = true;

      config = {
        plugins = with inputs.anyrun.packages.${system}; [
          applications
          websearch
          rink
        ];

        x           = { fraction = 0.5; };
        y           = { fraction = 0.0; };
        width       = { fraction = 0.35; };
        hideIcons              = false;
        ignoreExclusiveZones   = false;
        layer                  = "overlay";
        hidePluginInfo         = true;
        closeOnClickOutside    = true;
        showResultsImmediately = false;
        maxEntries             = null;
      };

      extraConfigFiles."applications.ron".text = ''
        Config(
          desktop_actions: false,
          max_entries: 5,
        )
      '';

      extraConfigFiles."websearch.ron".text = ''
        Config(
          prefix: "?",
          engines: [Google],
        )
      '';

      extraConfigFiles."rink.ron".text = ''
        Config(
          prefix: "=",
          show_exact_value: false,
        )
      '';
    };
  };
}
