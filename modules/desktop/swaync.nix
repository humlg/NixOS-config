{ config, lib, pkgs, ... }:

let
  home = config.home.homeDirectory;

  sleepInhibitToggle = pkgs.writeShellScript "sleep-inhibit-toggle" ''
    if systemctl --user is-active --quiet hypridle.service; then
      systemctl --user stop hypridle.service
      ${pkgs.libnotify}/bin/notify-send "󰒳 Sleep inhibition: ON"
    else
      systemctl --user start hypridle.service
      ${pkgs.libnotify}/bin/notify-send "󰒳 Sleep inhibition: OFF"
    fi
  '';

  sleepInhibitCheck = pkgs.writeShellScript "sleep-inhibit-check" ''
    if systemctl --user is-active --quiet hypridle.service; then
      echo false
    else
      echo true
    fi
  '';

  nightLightToggle = pkgs.writeShellScript "night-light-toggle" ''
    if systemctl --user is-active --quiet hyprsunset.service; then
      systemctl --user stop hyprsunset.service
      ${pkgs.libnotify}/bin/notify-send "󰖚 Blue light filter: OFF"
    else
      systemctl --user start hyprsunset.service
      ${pkgs.libnotify}/bin/notify-send "󰖚 Blue light filter: ON"
    fi
  '';

  nightLightCheck = pkgs.writeShellScript "night-light-check" ''
    if systemctl --user is-active --quiet hyprsunset.service; then
      echo true
    else
      echo false
    fi
  '';
in
{
  # GIO TLS support — without this, swaync cannot download album art over HTTPS
  home.sessionVariables.GIO_EXTRA_MODULES = "${pkgs.glib-networking}/lib/gio/modules";

  services.swaync = {
    enable = true;

    settings = {
      "$schema" = "/etc/xdg/swaync/configSchema.json";
      positionX = "right";
      positionY = "top";
      cssPriority = "user";

      control-center-width = 380;
      control-center-height = 860;
      control-center-margin-top = 2;
      control-center-margin-bottom = 2;
      control-center-margin-right = 1;
      control-center-margin-left = 0;

      notification-window-width = 400;
      notification-icon-size = 48;
      notification-body-image-height = 160;
      notification-body-image-width = 200;

      timeout = 4;
      timeout-low = 2;
      timeout-critical = 6;

      fit-to-screen = false;
      keyboard-shortcuts = true;
      image-visibility = "when-available";
      transition-time = 200;
      hide-on-clear = false;
      hide-on-action = false;
      script-fail-notify = true;

      scripts = {
        example-script = {
          exec = "echo 'Do something...'";
          urgency = "Normal";
        };
      };

      notification-visibility = {
        example-name = {
          state = "muted";
          urgency = "Low";
          app-name = "Spotify";
        };
      };

      widgets = [
        "label"
        "buttons-grid"
        "mpris"
        "title"
        "dnd"
        "notifications"
      ];

      widget-config = {
        title = {
          text = "Notifications";
          clear-all-button = true;
          button-text = " 󰎟 ";
        };
        dnd = {
          text = "Do not disturb";
        };
        label = {
          max-lines = 1;
          text = " ";
        };
        mpris = {
          image-size = 96;
          image-radius = 12;
          show-album-art = "always";
        };
        volume = {
          label = "󰕾";
          show-per-app = true;
        };
        buttons-grid = {
          actions = [
            {
              label = "󰕾 ";
              command = "amixer set Master toggle";
            }
            {
              label = "󰍬";
              command = "amixer set Capture toggle";
            }
            {
              label = "󰖩 ";
              command = "nm-connection-editor";
            }
            {
              label = "󰂯";
              command = "blueman-manager";
            }
            {
              label = "󰖚";
              type = "toggle";
              command = "${nightLightToggle}";
              update-command = "${nightLightCheck}";
            }
            {
              label = "󰒳";
              type = "toggle";
              command = "${sleepInhibitToggle}";
              update-command = "${sleepInhibitCheck}";
            }
          ];
        };
      };
    };

    style = ''
      @import url("${home}/.cache/wallust/colors-waybar.css");

      /* ── Notification color aliases ─────────────────────────────────────── */
      @define-color text            @foreground;
      @define-color background-alt  @color1;
      @define-color selected        @color3;
      @define-color hover           @color5;
      @define-color urgent          @color2;

      * {
        color: @text;
        all: unset;
        font-size: 14px;
        font-family: "JetBrains Mono Nerd Font 10";
        transition: 200ms;
      }

      .notification-row {
        outline: none;
        margin: 0;
        padding: 0px;
      }

      .floating-notifications.background .notification-row .notification-background {
        background: alpha(@background, .55);
        box-shadow: 0 0 8px 0 rgba(0,0,0,.6);
        border: 1px solid @selected;
        border-radius: 24px;
        margin: 16px;
        padding: 0;
      }

      .floating-notifications.background .notification-row .notification-background .notification {
        padding: 6px;
        border-radius: 12px;
      }

      .floating-notifications.background .notification-row .notification-background .notification.critical {
        border: 2px solid @urgent;
      }

      .floating-notifications.background .notification-row .notification-background .notification .notification-content {
        margin: 14px;
      }

      .floating-notifications.background .notification-row .notification-background .notification > *:last-child > * {
        min-height: 3.4em;
      }

      .floating-notifications.background .notification-row .notification-background .notification > *:last-child > * .notification-action {
        border-radius: 8px;
        background-color: @background-alt;
        margin: 6px;
        border: 1px solid transparent;
      }

      .floating-notifications.background .notification-row .notification-background .notification > *:last-child > * .notification-action:hover {
        background-color: @hover;
        border: 1px solid @selected;
      }

      .floating-notifications.background .notification-row .notification-background .notification > *:last-child > * .notification-action:active {
        background-color: @selected;
        color: @background;
      }

      .image {
        margin: 10px 20px 10px 0px;
      }

      .summary {
        font-weight: 800;
        font-size: 1rem;
      }

      .body {
        font-size: 0.8rem;
      }

      .floating-notifications.background .notification-row .notification-background .close-button {
        margin: 6px;
        padding: 2px;
        border-radius: 6px;
        background-color: transparent;
        border: 1px solid transparent;
      }

      .floating-notifications.background .notification-row .notification-background .close-button:hover {
        background-color: @selected;
      }

      .floating-notifications.background .notification-row .notification-background .close-button:active {
        background-color: @selected;
        color: @background;
      }

      .notification.critical progress {
        background-color: @selected;
      }

      .notification.low progress,
      .notification.normal progress {
        background-color: @selected;
      }

      /* ── Control center color aliases ───────────────────────────────────── */

      @define-color background-alt  alpha(@color1, .4);
      @define-color selected        @color2;
      @define-color hover           alpha(@selected, .4);
      @define-color urgent          @color6;

      .blank-window {
        background: transparent;
      }

      /* CONTROL CENTER ───────────────────────────────────────────────────── */

      .control-center {
        background: alpha(@background, .55);
        border-radius: 10px;
        border: 1px solid @color1;
        box-shadow: 0 0 10px 0 rgba(0,0,0,.6);
        margin: 18px;
        padding: 12px;
      }

      /* Notifications */
      .control-center .notification-row .notification-background,
      .control-center .notification-row .notification-background .notification.critical {
        background-color: @background-alt;
        border-radius: 16px;
        margin: 4px 0px;
        padding: 4px;
      }

      .control-center .notification-row .notification-background .notification.critical {
        color: @urgent;
      }

      .control-center .notification-row .notification-background .notification .notification-content {
        margin: 6px;
        padding: 8px 6px 2px 2px;
      }

      .control-center .notification-row .notification-background .notification > *:last-child > * {
        min-height: 3.4em;
      }

      .control-center .notification-row .notification-background .notification > *:last-child > * .notification-action {
        background: alpha(@selected, .6);
        color: @text;
        border-radius: 12px;
        margin: 6px;
      }

      .control-center .notification-row .notification-background .notification > *:last-child > * .notification-action:hover {
        background: @selected;
      }

      .control-center .notification-row .notification-background .notification > *:last-child > * .notification-action:active {
        background-color: @selected;
      }

      /* Buttons */
      .control-center .notification-row .notification-background .close-button {
        background: transparent;
        border-radius: 6px;
        color: @text;
        margin: 0px;
        padding: 4px;
      }

      .control-center .notification-row .notification-background .close-button:hover {
        background-color: @selected;
      }

      .control-center .notification-row .notification-background .close-button:active {
        background-color: @selected;
      }

      progressbar,
      progress,
      trough {
        border-radius: 12px;
      }

      progressbar {
        background-color: rgba(255,255,255,.1);
      }

      /* Notifications expanded-group */
      .notification-group {
        margin: 2px 8px 2px 8px;
      }

      .notification-group-headers {
        font-weight: bold;
        font-size: 1.25rem;
        color: @text;
        letter-spacing: 2px;
      }

      .notification-group-icon {
        color: @text;
      }

      .notification-group-collapse-button,
      .notification-group-close-all-button {
        background: transparent;
        color: @text;
        margin: 4px;
        border-radius: 6px;
        padding: 4px;
      }

      .notification-group-collapse-button:hover,
      .notification-group-close-all-button:hover {
        background: @hover;
      }

      /* WIDGETS ─────────────────────────────────────────────────────────── */

      /* Notification clear button */
      .widget-title {
        font-size: 1.2em;
        margin: 6px;
      }

      .widget-title button {
        background: @background-alt;
        border-radius: 6px;
        padding: 4px 16px;
      }

      .widget-title button:hover {
        background-color: @hover;
      }

      .widget-title button:active {
        background-color: @selected;
      }

      /* Do not disturb */
      .widget-dnd {
        margin: 6px;
        font-size: 1.2rem;
      }

      .widget-dnd > switch {
        background: @background-alt;
        font-size: initial;
        border-radius: 8px;
        box-shadow: none;
        padding: 2px;
      }

      .widget-dnd > switch:hover {
        background: @hover;
      }

      .widget-dnd > switch:checked {
        background: @selected;
      }

      .widget-dnd > switch:checked:hover {
        background: @hover;
      }

      .widget-dnd > switch slider {
        background: @text;
        border-radius: 6px;
      }

      /* Buttons menu */
      .widget-buttons-grid {
        font-size: x-large;
        padding: 6px 2px;
        margin: 6px;
        border-radius: 12px;
        background: @background-alt;
      }

      .widget-buttons-grid>flowbox>flowboxchild>button {
        margin: 4px 10px;
        padding: 6px 12px;
        background: transparent;
        border-radius: 8px;
      }

      .widget-buttons-grid>flowbox>flowboxchild>button:hover {
        background: @hover;
      }

      .widget-buttons-grid>flowbox>flowboxchild>button:checked {
        background: @selected;
      }

      /* Music player */
      .widget-mpris {
        background: @background-alt;
        border-radius: 16px;
        color: @text;
        margin: 20px 6px;
        --mpris-album-art-icon-size: 96px;
      }

      .widget-mpris-player {
        background-color: @background-alt;
        border-radius: 22px;
        padding: 6px 14px;
        margin: 6px;
      }

      .mpris-background {
        opacity: 0;
      }

      .widget-mpris > box > button {
        color: @text;
        border-radius: 20px;
      }

      .widget-mpris button {
        color: alpha(@text, .6);
      }

      .widget-mpris button:hover {
        color: @text;
      }

      .widget-mpris-album-art {
        -gtk-icon-size: var(--mpris-album-art-icon-size);
        border-radius: 12px;
        box-shadow: 0px 0px 10px rgba(0, 0, 0, 0.75);
      }

      .widget-mpris-title {
        font-weight: 700;
        font-size: 1rem;
      }

      .widget-mpris-subtitle {
        font-weight: 500;
        font-size: 0.8rem;
      }

      /* Volume */
      .widget-volume {
        background: @background-sec;
        color: @background;
        padding: 4px;
        margin: 6px;
        border-radius: 6px;
      }

    '';
  };
}
