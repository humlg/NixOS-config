{ config, lib, pkgs, ... }: # HM

let
  cfg = config.desktop.hyprland-desktop;
  home = config.home.homeDirectory;

  reloadDesktop = pkgs.writeShellScriptBin "reload-desktop" ''
    hyprctl reload
    (ags quit -i bar 2>/dev/null; ags run) &
    systemctl --user restart swaync.service
    pywalfox update
  '';

  # On/off toggle for Darkroom mode (no rebuild needed).
  # The Lua config parser rejects `hyprctl keyword`, so use `hyprctl eval`.
  darkroomToggle = pkgs.writeShellScriptBin "darkroom-toggle" ''
    shader="$HOME/.config/hypr/shaders/darkroom.frag"
    current=$(hyprctl getoption decoration:screen_shader | sed -n 's/^str: //p')
    case "$current" in
      *darkroom.frag)
        hyprctl eval 'hl.config({ decoration = { screen_shader = "" } })'
        ${pkgs.libnotify}/bin/notify-send -t 1500 "Darkroom mode" "off" || true ;;
      *)
        hyprctl eval "hl.config({ decoration = { screen_shader = \"$shader\" } })"
        ${pkgs.libnotify}/bin/notify-send -t 1500 "Darkroom mode" "on" || true ;;
    esac
  '';

  # `wallust run -s` (skip-sequences): without -s, wallust also pushes OSC color
  # escape sequences straight to every already-open terminal pty on each wallpaper
  # change, live-repainting kitty's static theme in running windows (newly spawned
  # windows were unaffected, since they read kitty.conf, not a live sequence).
  waypaperDefaultConfig = pkgs.writeText "waypaper-default-config.ini" ''
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
    post_command = wallust run -s "$wallpaper" && reload-desktop
    number_of_columns = 3
    awww_transition_type = center
    awww_transition_step = 63
    awww_transition_angle = 0
    awww_transition_duration = 2
    awww_transition_fps = 60
    mpvpaper_sound = False
    mpvpaper_options =
    use_xdg_state = False
  '';

  # Import Hyprland config fragments (hyprlang)
  args = { inherit cfg home pkgs reloadDesktop; };
  hyprVars      = import ./hyprland-config/variables.nix args;
  hyprAutostart = import ./hyprland-config/autostart.nix args;
  hyprInput     = import ./hyprland-config/input.nix args;
  hyprAppear    = import ./hyprland-config/appearance.nix args;
  hyprRules     = import ./hyprland-config/window-rules.nix args;
  hyprKeybinds  = import ./hyprland-config/keybinds.nix args;
  hyprLayouts   = import ./hyprland-config/layouts.nix args;

  # Import Hyprland config fragments (Lua — Hyprland 0.55+)
  luaArgs        = { inherit cfg home pkgs reloadDesktop; };
  luaVars        = import ./hyprland-config-lua/variables.nix luaArgs;
  luaAutostart   = import ./hyprland-config-lua/autostart.nix luaArgs;
  luaInput       = import ./hyprland-config-lua/input.nix luaArgs;
  luaAppear      = import ./hyprland-config-lua/appearance.nix luaArgs;
  luaRules       = import ./hyprland-config-lua/window-rules.nix luaArgs;
  luaKeybinds    = import ./hyprland-config-lua/keybinds.nix luaArgs;
  luaLayouts     = import ./hyprland-config-lua/layouts.nix luaArgs;
in
{
  imports = [
    ./swaync.nix
    ./ags.nix
    ./anyrun.nix
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
      description = "Extra Hyprland config lines appended at the end (per-host overrides, hyprlang format).";
    };

    useLuaConfig = lib.mkOption {
      type    = lib.types.bool;
      default = false;
      description = "Switch to Lua config format (Hyprland 0.55+). When true, hyprland.lua is used instead of hyprland.conf.";
    };

    monitorsLua = lib.mkOption {
      type    = lib.types.lines;
      default = ''hl.monitor({ name = "", mode = "preferred", position = "auto", scale = 1 })'';
      description = "Lua Hyprland monitor configuration lines. Used only when useLuaConfig = true.";
    };

    extraLuaConfig = lib.mkOption {
      type    = lib.types.lines;
      default = "";
      description = "Extra Lua lines appended at the end (per-host overrides, Lua format). Used only when useLuaConfig = true.";
    };

    sleepCommand = lib.mkOption {
      type    = lib.types.str;
      default = "systemctl suspend";
      description = ''
        Command hypridle runs when the final idle timeout fires. Defaults to
        plain suspend; hosts whose firmware wedges on s2idle can set this to
        "systemctl hibernate" (saruman does — see maintenance.md item 7).
        Only set hibernate on a host that has boot.resumeDevice configured,
        otherwise the machine powers off and loses the session.
      '';
    };
  };

  config = lib.mkIf cfg.enable {

    # ── Packages ────────────────────────────────────────────────────
    home.packages = [
      reloadDesktop
      darkroomToggle
    ] ++ (with pkgs; [
      hyprshot
      hyprpicker
      awww
      waypaper
      rofi
      rofimoji
      cliphist
      wl-clipboard
      networkmanagerapplet
      blueman
      brightnessctl
      playerctl
      gnome-calculator
      pavucontrol
      lxqt.lxqt-policykit
      qt6Packages.qt6ct
      wallust
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

      configType = if cfg.useLuaConfig then "lua" else "hyprlang";

      extraConfig = if cfg.useLuaConfig then ''
        -- ── Per-machine: monitors & scaling ─────────────────────────────
        ${cfg.monitorsLua}

        -- ── Wallust colours (runtime-generated, loaded as Lua table) ────
        local wc = dofile(os.getenv("HOME") .. "/.cache/wallust/colors-hyprland.lua")

        ${luaVars}
        ${luaAutostart}
        ${luaInput}
        ${luaAppear}
        ${luaRules}
        ${luaLayouts}
        ${luaKeybinds}

        -- ── Per-machine overrides ───────────────────────────────────────
        ${cfg.extraLuaConfig}
      '' else ''
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

    # ── Screen shaders ──────────────────────────────────────────────
    # Applied via `decoration:screen_shader`. Off by default; toggled at
    # runtime with `hyprctl eval` (the Lua parser rejects `hyprctl keyword`).
    # Static GLES3 shader (no `time` uniform), so it re-applies on every
    # screen damage without forcing extra re-renders.
    # Darkroom mode: grayscale mapped to the red channel only. Red light barely
    # stimulates rod cells, so this preserves dark adaptation in a dark room.
    # Toggled with SUPER+G (darkroom-toggle).
    home.file.".config/hypr/shaders/darkroom.frag".text = ''
      #version 300 es
      precision highp float;

      in  vec2      v_texcoord;
      out vec4      fragColor;
      uniform sampler2D tex;

      const float brightness = 1.0;  // lower this (e.g. 0.7) to dim further

      void main() {
          vec3  c   = texture(tex, v_texcoord).rgb;
          float lum = dot(c, vec3(0.299, 0.587, 0.114));
          float r   = pow(lum, 0.9) * brightness;  // luminance → red only
          fragColor = vec4(r, 0.0, 0.0, 1.0);
      }
    '';

    # ── Rofi ────────────────────────────────────────────────────────
    programs.rofi = {
      enable = true;
      theme = "${home}/.cache/wallust/colors-rofi-dark.rasi";
    };

    # ── Waypaper seed config ────────────────────────────────────────
    home.activation.seedWaypaperConfig = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      if [[ ! -f "$HOME/.config/waypaper/config.ini" ]]; then
        $DRY_RUN_CMD mkdir -p "$HOME/.config/waypaper"
        $DRY_RUN_CMD cp ${waypaperDefaultConfig} "$HOME/.config/waypaper/config.ini"
      fi
    '';

    # ── Wallust restore (login) ──────────────────────────────────────
    systemd.user.services.wallust-restore = {
      Unit = {
        Description = "Restore wallust colors from awww cache";
        PartOf = [ "graphical-session.target" ];
        After = [ "graphical-session.target" ];
      };
      Service = {
        Type = "oneshot";
        TimeoutStartSec = 30;
        ExecStart = toString (pkgs.writeShellScript "wallust-restore" ''
          # Bail out cleanly if awww daemon is not running (e.g. during nixos-rebuild).
          # wallust run would otherwise hang waiting for the awww socket.
          pgrep -x awww-daemon > /dev/null || exit 0

          # awww stores per-output cache files in ~/.cache/awww/
          # Use tr to strip null bytes — awww cache files may be binary and bash 5.3
          # crashes with SEGV when command substitution receives a string with null bytes.
          for f in "$HOME"/.cache/awww/*; do
            [ -f "$f" ] || continue
            wallpaper="$(tr -d '\0' < "$f")"
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
      check_constrast = true
      saturation = 65

      [templates]
      colors-hyprland.template = "colors-hyprland.conf"
      colors-hyprland.target = "~/.cache/wallust/colors-hyprland.conf"

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

      colors-hyprland-lua.template = "colors-hyprland.lua"
      colors-hyprland-lua.target = "~/.cache/wallust/colors-hyprland.lua"
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

    home.file.".config/wallust/templates/colors-hyprland.lua".text = ''
      return {
        background = "{{ background | replace("#", "") }}",
        foreground = "{{ foreground | replace("#", "") }}",
        color0  = "{{ color0  | replace("#", "") }}",
        color1  = "{{ color1  | replace("#", "") }}",
        color2  = "{{ color2  | replace("#", "") }}",
        color3  = "{{ color3  | replace("#", "") }}",
        color4  = "{{ color4  | replace("#", "") }}",
        color5  = "{{ color5  | replace("#", "") }}",
        color6  = "{{ color6  | replace("#", "") }}",
        color7  = "{{ color7  | replace("#", "") }}",
        color8  = "{{ color8  | replace("#", "") }}",
        color9  = "{{ color9  | replace("#", "") }}",
        color10 = "{{ color10 | replace("#", "") }}",
        color11 = "{{ color11 | replace("#", "") }}",
        color12 = "{{ color12 | replace("#", "") }}",
        color13 = "{{ color13 | replace("#", "") }}",
        color14 = "{{ color14 | replace("#", "") }}",
        color15 = "{{ color15 | replace("#", "") }}",
      }
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
