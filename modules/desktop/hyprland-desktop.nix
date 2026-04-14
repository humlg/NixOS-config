{ config, lib, pkgs, ... }:

let
  cfg = config.desktop.hyprland-desktop;
  home = config.home.homeDirectory;

  reloadDesktop = pkgs.writeShellScriptBin "reload-desktop" ''
    hyprctl reload
    ags quit -i bar && ags run &
    pkill swaync; swaync &
    kitty @ set-colors --all ~/.cache/wal/colors-kitty.conf 2>/dev/null || true
  '';

  toggleNotes = pkgs.writeShellScript "toggle-notes" ''
    hyprctl clients -j | grep -q '"class": "obsidian"' || hyprctl dispatch exec obsidian
    hyprctl dispatch togglespecialworkspace notes
  '';

  # Import Hyprland config fragments
  args = { inherit cfg home pkgs reloadDesktop toggleNotes; };
  hyprVars      = import ./hyprland-config/variables.nix args;
  hyprAutostart = import ./hyprland-config/autostart.nix args;
  hyprInput     = import ./hyprland-config/input.nix args;
  hyprAppear    = import ./hyprland-config/appearance.nix args;
  hyprRules     = import ./hyprland-config/window-rules.nix args;
  hyprKeybinds  = import ./hyprland-config/keybinds.nix args;
  hyprLayouts   = import ./hyprland-config/layouts.nix args;
in
{
  imports = [
    ./swaync.nix
    ./ags.nix
    ./hyprlock.nix
    ./hypridle.nix
  ];

  options.desktop.hyprland-desktop = {
    enable = lib.mkEnableOption "Hyprland desktop home-manager environment";

    monitors = lib.mkOption {
      type    = lib.types.lines;
      default = "monitor = ,preferred,auto,1";
      description = "Raw Hyprland monitor configuration lines (machine-specific).";
    };

    lockScreen = lib.mkOption {
      type    = lib.types.str;
      default = "hyprlock";
      description = "Command used to lock the screen.";
    };

    screenshotDir = lib.mkOption {
      type    = lib.types.str;
      default = "${home}/Pictures/Screenshots";
      description = "Directory where hyprshot saves screenshots.";
    };

    terminal = lib.mkOption {
      type    = lib.types.str;
      default = "kitty";
      description = "Default terminal emulator command.";
    };

    fileManager = lib.mkOption {
      type    = lib.types.str;
      default = "thunar";
      description = "Default file manager command.";
    };

    extraConfig = lib.mkOption {
      type    = lib.types.lines;
      default = "";
      description = "Extra Hyprland config lines appended at the end (per-host overrides).";
    };
  };

  config = lib.mkIf cfg.enable {

    # ── Packages ────────────────────────────────────────────────────
    home.packages = [
      reloadDesktop
    ] ++ (with pkgs; [
      hyprshot
      hyprpicker
      swww
      waypaper
      rofi
      cliphist
      wl-clipboard
      networkmanagerapplet
      blueman
      brightnessctl
      playerctl
      gnome-calculator
      pavucontrol
      lxqt.lxqt-policykit
      kdePackages.kwallet
      qt6Packages.qt6ct
      pywal16
      pywalfox-native
    ]);

    # ── Session variables ───────────────────────────────────────────
    # NOTE: Do NOT put secrets (API tokens, etc.) here!!!
    home.sessionVariables = {
      XCURSOR_SIZE                 = 24;
      HYPRCURSOR_SIZE              = 24;
      QT_QPA_PLATFORMTHEME         = "qt6ct";
      OZONE_PLATFORM               = "wayland";
      MOZ_ENABLE_WAYLAND           = "1";
      QT_QPA_PLATFORM              = "wayland";
      ELECTRON_OZONE_PLATFORM_HINT = "wayland";
      HYPRSHOT_DIR                 = cfg.screenshotDir;
    };

    # ── Hyprland ────────────────────────────────────────────────────
    wayland.windowManager.hyprland = {
      enable          = true;
      xwayland.enable = true;
      systemd.enable  = false;

      extraConfig = ''
        # ── Per-machine: monitors & scaling ─────────────────────────────
        ${cfg.monitors}

        # ── Pywal colours (runtime-generated) ───────────────────────────
        source = ${home}/.cache/wal/colors-hyprland.conf
        ${hyprVars}
        ${hyprAutostart}
        ${hyprInput}
        ${hyprAppear}
        ${hyprRules}
        ${hyprLayouts}
        ${hyprKeybinds}

        # ── Per-machine overrides ───────────────────────────────────────
        ${cfg.extraConfig}
      '';
    };

    # ── Rofi ────────────────────────────────────────────────────────
    programs.rofi = {
      enable = true;
      theme = "${home}/.cache/wal/colors-rofi-dark.rasi";
    };

    # ── Waypaper seed config ────────────────────────────────────────
    home.activation.seedWaypaperConfig = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      config_dir="${home}/.config/waypaper"
      config_file="$config_dir/config.ini"
      if [ ! -f "$config_file" ]; then
        run mkdir -p "$config_dir"
        cat > "$config_file" << 'WAYPAPEREOF'
[Settings]
language = en
folder = ~/Pictures/Wallpapers
monitors = All
wallpaper = ~/Pictures/Wallpapers/default.jpg
show_path_in_tooltip = True
backend = swww
fill = stretch
sort = name
color = #ffffff
subfolders = True
all_subfolders = False
show_hidden = False
show_gifs_only = False
zen_mode = False
post_command = wal -i "$wallpaper" && reload-desktop
number_of_columns = 3
swww_transition_type = center
swww_transition_step = 63
swww_transition_angle = 0
swww_transition_duration = 2
swww_transition_fps = 60
mpvpaper_sound = False
mpvpaper_options =
use_xdg_state = False
WAYPAPEREOF
      fi
    '';

    # ── Pywal restore (login) ───────────────────────────────────────
    systemd.user.services.pywal-restore = {
      Unit = {
        Description = "Restore pywal colors from cache";
        PartOf = [ "graphical-session.target" ];
        After = [ "graphical-session.target" ];
      };
      Service = {
        Type = "oneshot";
        ExecStart = "${pkgs.pywal16}/bin/wal -R";
      };
      Install.WantedBy = [ "graphical-session.target" ];
    };

    # ── Hyprsunset (night light) ────────────────────────────────────
    systemd.user.services.hyprsunset = {
      Unit = {
        Description = "Hyprsunset blue light filter";
        PartOf = [ "graphical-session.target" ];
        After = [ "graphical-session.target" ];
      };
      Service = {
        ExecStart = "${pkgs.hyprsunset}/bin/hyprsunset --temperature 3500";
        Restart = "on-failure";
      };
    };

    # ── Polkit agent ────────────────────────────────────────────────
    systemd.user.services.polkit-agent = {
      Unit = {
        Description = "Polkit Authentication Agent";
        After       = "graphical-session.target";
        PartOf      = "graphical-session.target";
      };
      Install.WantedBy = [ "graphical-session.target" ];
      Service = {
        ExecStart = "${pkgs.lxqt.lxqt-policykit}/bin/lxqt-policykit-agent";
        Restart   = "on-failure";
      };
    };
  };
}
