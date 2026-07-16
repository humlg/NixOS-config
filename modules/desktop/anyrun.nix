{ config, lib, pkgs, inputs, ... }:

let
  cfg    = config.desktop.hyprland-desktop;
  system = pkgs.stdenv.hostPlatform.system;
in
{
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
        y           = { fraction = 0.35; };
        width       = { fraction = 0.35; };
        hideIcons              = false;
        ignoreExclusiveZones   = false;
        layer                  = "overlay";
        hidePluginInfo         = true;
        closeOnClick           = true;
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

    # Wallust appends two lines to [templates] (last section, so TOML stays valid)
    home.file.".config/wallust/wallust.toml".text = lib.mkAfter ''
      colors-anyrun.template = "colors-anyrun.css"
      colors-anyrun.target = "~/.config/anyrun/style.css"
    '';

    home.file.".config/wallust/templates/colors-anyrun.css".text = ''
      @define-color bg      {{ background }};
      @define-color fg      {{ foreground }};
      @define-color accent  {{ color12 }};
      @define-color muted   {{ color8 }};
      @define-color surface {{ color0 }};

      window {
        background: transparent;
      }

      box.main {
        padding: 6px;
        margin: 12px;
        border-radius: 12px;
        border: 2px solid @accent;
        background-color: alpha(@bg, 0.75);
        box-shadow: 0 2px 16px rgba(0,0,0,0.6);
      }

      text {
        min-height: 32px;
        padding: 6px 10px;
        border-radius: 6px;
        color: @fg;
        caret-color: @accent;
      }

      .matches {
        background-color: transparent;
        border-radius: 8px;
      }

      box.plugin:first-child {
        margin-top: 5px;
      }

      box.plugin.info {
        min-width: 200px;
      }

      list.plugin {
        background-color: transparent;
      }

      label.match {
        color: @fg;
      }

      label.match.description {
        font-size: 10px;
        color: @muted;
      }

      label.plugin.info {
        font-size: 13px;
        color: @muted;
      }

      .match {
        background: transparent;
        border-radius: 6px;
        padding: 2px 4px;
      }

      .match:selected {
        border-left: 3px solid @accent;
        background-color: @surface;
        animation: fade 0.1s linear;
      }

      @keyframes fade {
        0%   { opacity: 0; }
        100% { opacity: 1; }
      }
    '';
  };
}
