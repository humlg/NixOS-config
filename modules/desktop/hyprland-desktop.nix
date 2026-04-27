{ config, lib, pkgs, ... }:

let
  cfg = config.desktop.hyprland-desktop;
  home = config.home.homeDirectory;

  reloadDesktop = pkgs.writeShellScriptBin "reload-desktop" ''
    hyprctl reload
    (ags quit -i bar 2>/dev/null; ags run) &
    systemctl --user restart swaync.service
    kitty @ set-colors --all ~/.cache/wallust/colors-kitty.conf 2>/dev/null || true
    pywalfox update
  '';

  # Import Hyprland config fragments
  args = { inherit cfg home pkgs reloadDesktop; };
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
      awww
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
      wallust
      pywalfox-native
      albert
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

        # ── Wallust colours (runtime-generated) ────────────────────────
        source = ${home}/.cache/wallust/colors-hyprland.conf
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
      theme = "${home}/.cache/wallust/colors-rofi-dark.rasi";
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
backend = awww
fill = stretch
sort = name
color = #ffffff
subfolders = True
all_subfolders = False
show_hidden = False
show_gifs_only = False
zen_mode = False
post_command = wallust run "$wallpaper" && reload-desktop
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

    # ── Wallust restore (login) ──────────────────────────────────────
    systemd.user.services.wallust-restore = {
      Unit = {
        Description = "Restore wallust colors from swww cache";
        PartOf = [ "graphical-session.target" ];
        After = [ "graphical-session.target" ];
      };
      Service = {
        Type = "oneshot";
        ExecStart = toString (pkgs.writeShellScript "wallust-restore" ''
          # swww stores per-output cache files in ~/.cache/swww/
          for f in "$HOME"/.cache/swww/*; do
            [ -f "$f" ] || continue
            wallpaper="$(cat "$f")"
            if [ -f "$wallpaper" ]; then
              ${pkgs.wallust}/bin/wallust run -s "$wallpaper"
              exit 0
            fi
          done
        '');
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

    # ── Wallust config & templates ─────────────────────────────────

    home.file.".config/wallust/wallust.toml".text = ''
      backend = "kmeans"
      palette = "dark16"
      threshold = 11

      [templates]
      colors-hyprland.template = "colors-hyprland.conf"
      colors-hyprland.target = "~/.cache/wallust/colors-hyprland.conf"

      colors-kitty.template = "colors-kitty.conf"
      colors-kitty.target = "~/.cache/wallust/colors-kitty.conf"

      colors-waybar.template = "colors-waybar.css"
      colors-waybar.target = "~/.cache/wallust/colors-waybar.css"

      colors-rofi.template = "colors-rofi-dark.rasi"
      colors-rofi.target = "~/.cache/wallust/colors-rofi-dark.rasi"

      colors-json.template = "colors.json"
      colors-json.target = "~/.cache/wallust/colors.json"

      pywal-json.template = "colors.json"
      pywal-json.target = "~/.cache/wal/colors.json"

      colors-cava.template = "colors-cava"
      colors-cava.target = "~/.cache/wallust/colors-cava"

      colors-btop.template = "colors-btop"
      colors-btop.target = "~/.cache/wallust/colors-btop"

      colors-vim.template = "colors-wal.vim"
      colors-vim.target = "~/.cache/wallust/colors-wal.vim"

      colors-albert.template = "colors-albert.ini"
      colors-albert.target = "~/.local/share/albert/widgetsboxmodel/themes/Wallust.ini"
    '';

    home.file.".config/wallust/templates/colors-hyprland.conf".text = ''
      $background = rgb({{ background | replace("#", "") }})
      $foreground = rgb({{ foreground | replace("#", "") }})
      $color0 = rgb({{ color0 | replace("#", "") }})
      $color1 = rgb({{ color1 | replace("#", "") }})
      $color2 = rgb({{ color2 | replace("#", "") }})
      $color3 = rgb({{ color3 | replace("#", "") }})
      $color4 = rgb({{ color4 | replace("#", "") }})
      $color5 = rgb({{ color5 | replace("#", "") }})
      $color6 = rgb({{ color6 | replace("#", "") }})
      $color7 = rgb({{ color7 | replace("#", "") }})
      $color8 = rgb({{ color8 | replace("#", "") }})
      $color9 = rgb({{ color9 | replace("#", "") }})
      $color10 = rgb({{ color10 | replace("#", "") }})
      $color11 = rgb({{ color11 | replace("#", "") }})
      $color12 = rgb({{ color12 | replace("#", "") }})
      $color13 = rgb({{ color13 | replace("#", "") }})
      $color14 = rgb({{ color14 | replace("#", "") }})
      $color15 = rgb({{ color15 | replace("#", "") }})
      $wallpaper = {{ wallpaper }}
    '';

    home.file.".config/wallust/templates/colors-kitty.conf".text = ''
      foreground {{ foreground }}
      background {{ background }}
      cursor     {{ foreground }}
      color0  {{ color0 }}
      color1  {{ color1 }}
      color2  {{ color2 }}
      color3  {{ color3 }}
      color4  {{ color4 }}
      color5  {{ color5 }}
      color6  {{ color6 }}
      color7  {{ color7 }}
      color8  {{ color8 }}
      color9  {{ color9 }}
      color10 {{ color10 }}
      color11 {{ color11 }}
      color12 {{ color12 }}
      color13 {{ color13 }}
      color14 {{ color14 }}
      color15 {{ color15 }}
    '';

    home.file.".config/wallust/templates/colors-waybar.css".text = ''
      @define-color background {{ background }};
      @define-color foreground {{ foreground }};
      @define-color color0  {{ color0 }};
      @define-color color1  {{ color1 }};
      @define-color color2  {{ color2 }};
      @define-color color3  {{ color3 }};
      @define-color color4  {{ color4 }};
      @define-color color5  {{ color5 }};
      @define-color color6  {{ color6 }};
      @define-color color7  {{ color7 }};
      @define-color color8  {{ color8 }};
      @define-color color9  {{ color9 }};
      @define-color color10 {{ color10 }};
      @define-color color11 {{ color11 }};
      @define-color color12 {{ color12 }};
      @define-color color13 {{ color13 }};
      @define-color color14 {{ color14 }};
      @define-color color15 {{ color15 }};
    '';

    home.file.".config/wallust/templates/colors-rofi-dark.rasi".text = ''
      * {
          background:     {{ background }};
          foreground:     {{ foreground }};
          active-bg:      {{ color2 }};
          urgent-bg:      {{ color1 }};
          selected-bg:    {{ color2 }};
          selected-fg:    {{ foreground }};
      }
    '';

    home.file.".config/wallust/templates/colors.json".text = ''
      {
        "wallpaper": "{{ wallpaper }}",
        "special": {
          "background": "{{ background }}",
          "foreground": "{{ foreground }}",
          "cursor": "{{ foreground }}"
        },
        "colors": {
          "color0": "{{ color0 }}",
          "color1": "{{ color1 }}",
          "color2": "{{ color2 }}",
          "color3": "{{ color3 }}",
          "color4": "{{ color4 }}",
          "color5": "{{ color5 }}",
          "color6": "{{ color6 }}",
          "color7": "{{ color7 }}",
          "color8": "{{ color8 }}",
          "color9": "{{ color9 }}",
          "color10": "{{ color10 }}",
          "color11": "{{ color11 }}",
          "color12": "{{ color12 }}",
          "color13": "{{ color13 }}",
          "color14": "{{ color14 }}",
          "color15": "{{ color15 }}"
        }
      }
    '';

    home.file.".config/wallust/templates/colors-cava".text = ''
      [color]
      gradient = 0
      gradient_count = 0
      foreground = '{{ foreground }}'
      color1 = '{{ color1 }}'
      color2 = '{{ color2 }}'
      color3 = '{{ color3 }}'
      color4 = '{{ color4 }}'
      color5 = '{{ color5 }}'
      color6 = '{{ color6 }}'
      color7 = '{{ color7 }}'
    '';

    home.file.".config/wallust/templates/colors-btop".text = ''
      theme[main_bg]="{{ background }}"
      theme[main_fg]="{{ foreground }}"
      theme[title]="{{ foreground }}"
      theme[hi_fg]="{{ color2 }}"
      theme[selected_bg]="{{ color1 }}"
      theme[selected_fg]="{{ foreground }}"
      theme[inactive_fg]="{{ color8 }}"
      theme[proc_misc]="{{ color6 }}"
      theme[cpu_box]="{{ color2 }}"
      theme[mem_box]="{{ color3 }}"
      theme[net_box]="{{ color4 }}"
      theme[proc_box]="{{ color5 }}"
      theme[div_line]="{{ color8 }}"
      theme[temp_start]="{{ color2 }}"
      theme[temp_mid]="{{ color3 }}"
      theme[temp_end]="{{ color1 }}"
      theme[cpu_start]="{{ color2 }}"
      theme[cpu_mid]="{{ color4 }}"
      theme[cpu_end]="{{ color1 }}"
      theme[free_start]="{{ color2 }}"
      theme[free_mid]="{{ color4 }}"
      theme[free_end]="{{ color6 }}"
      theme[cached_start]="{{ color6 }}"
      theme[cached_mid]="{{ color4 }}"
      theme[cached_end]="{{ color2 }}"
      theme[available_start]="{{ color3 }}"
      theme[available_mid]="{{ color2 }}"
      theme[available_end]="{{ color6 }}"
      theme[used_start]="{{ color1 }}"
      theme[used_mid]="{{ color3 }}"
      theme[used_end]="{{ color2 }}"
      theme[download_start]="{{ color4 }}"
      theme[download_mid]="{{ color2 }}"
      theme[download_end]="{{ color6 }}"
      theme[upload_start]="{{ color1 }}"
      theme[upload_mid]="{{ color3 }}"
      theme[upload_end]="{{ color2 }}"
    '';

    home.file.".config/wallust/templates/colors-albert.ini".text = ''
      ;
      ; Wallust Dynamic Theme
      ;

      accent={{ color2 }}
      accent_semi=#80{{ color2 | replace("#", "") }}

      [palette]
      base={{ background }}
      text={{ foreground }}

      window={{ color0 }}
      window_text={{ foreground }}

      button={{ color8 }}
      button_text={{ foreground }}

      highlight={{ color2 }}
      highlight_text={{ background }}

      placeholder_text={{ color8 }}

      link={{ color4 }}
      link_visited={{ color5 }}

      [window]
      window_border_brush=transparent
      input_trigger_color=$accent
      input_hint_color=$palette/placeholder_text
      result_item_selection_background_brush=$accent_semi
      result_item_selection_border_brush=transparent
      result_item_selection_text_color=$palette/button_text
      result_item_selection_subtext_color=$palette/placeholder_text
      result_item_text_color=$palette/window_text
      result_item_subtext_color=$palette/placeholder_text
    '';

    home.file.".config/wallust/templates/colors-wal.vim".text = ''
      highlight Normal     ctermbg=NONE guibg={{ background }} guifg={{ foreground }}
      highlight Comment    guifg={{ color8 }}
      highlight Constant   guifg={{ color3 }}
      highlight Identifier guifg={{ color4 }}
      highlight Statement  guifg={{ color1 }}
      highlight PreProc    guifg={{ color5 }}
      highlight Type       guifg={{ color6 }}
      highlight Special    guifg={{ color2 }}
      highlight Underlined guifg={{ color4 }} gui=underline
      highlight Error      guifg={{ color1 }} guibg={{ background }}
      highlight Todo       guifg={{ color3 }} guibg={{ background }} gui=bold
      highlight LineNr     guifg={{ color8 }}
      highlight CursorLine guibg={{ color0 }}
      highlight StatusLine guibg={{ color1 }} guifg={{ foreground }}
      highlight Pmenu      guibg={{ color0 }} guifg={{ foreground }}
      highlight PmenuSel   guibg={{ color2 }} guifg={{ background }}
      set background=dark
    '';
  };
}
