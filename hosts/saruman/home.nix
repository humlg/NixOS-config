{ pkgs, ... }:

let
  # Native/Full HD toggle for TV mirroring (SUPER+A). `hyprctl eval`, not `keyword` — Lua config.
  resolutionToggle = pkgs.writeShellScriptBin "resolution-toggle" ''
    width=$(hyprctl monitors -j | ${pkgs.jq}/bin/jq -r '.[] | select(.name=="eDP-1") | .width')
    if [ "$width" = "1920" ]; then
      hyprctl eval 'hl.monitor({ output = "eDP-1", mode = "2880x1800@120", position = "0x0", scale = 2, bitdepth = 10, cm = "wide" })'
      ${pkgs.libnotify}/bin/notify-send -t 1500 "Resolution" "Native (2880x1800)" || true
    else
      hyprctl eval 'hl.monitor({ output = "eDP-1", mode = "1920x1080@120", position = "0x0", scale = 1 })'
      ${pkgs.libnotify}/bin/notify-send -t 1500 "Resolution" "Full HD (1920x1080)" || true
    fi
  '';
in
{
  imports = [
    ../../modules/home/common.nix
    ../../modules/home/bundle-general.nix
    ../../modules/home/desktop-hyprland-desktop.nix
    ../../modules/home/bundle-yg-work.nix
    ../../modules/home/program-webapps.nix
    ../../modules/home/program-yg-discover.nix
    ../../modules/home/program-lightcraft.nix
    ../../modules/home/bundle-workstation.nix
  ];

  bundles.general.enable = true;
  bundles.workstation.enable = true;
  bundles.yg-work.enable = true;
  programs.yg-discover.enable = true;
  programs.yg-discover.netio.enable = true;
  programs.lightcraft.enable = true;

  desktop.hyprland-desktop = {
    enable = true;

    useNoctalia = true;  # pilot, runs alongside AGS/swaync/hyprlock/waypaper — docs/maintenance.md #19

    monitors = ''
      monitor = eDP-1,2880x1800@120,0x0,2,bitdepth,10,cm,wide
      monitor = desc:iiyama Corporation PL2797H 12497503A1590,1920x1080@100,1440x-258,1
      monitor = ,preferred,auto,1,mirror,eDP-1
    '';
    monitorsLua = ''
      hl.monitor({ output = "eDP-1", mode = "2880x1800@120",  position = "0x0",    scale = 2, bitdepth = 10, cm = "wide" })
      hl.monitor({ output = "desc:iiyama Corporation PL2797H 12497503A1590", mode = "1920x1080@100", position = "1440x-258", scale = 1 })
      hl.monitor({ output = "",      mode = "preferred",       position = "auto",   scale = 1, mirror = "eDP-1" })
    '';

    # Inert while useNoctalia=true (desktop-hypridle.nix disabled, docs/maintenance.md #19) — left
    # set so it's correct the moment Noctalia flips off. Matches configuration.nix's logind paths.
    sleepCommand  = "systemctl suspend";

    extraConfig = ''
      xwayland {
          force_zero_scaling = false
      }
    '';
    extraLuaConfig = ''
      hl.config({ xwayland = { force_zero_scaling = false } })

      -- Monitor-mirroring flicker workaround — docs/maintenance.md #8.
      hl.on("monitor.added", function(monitor)
        if monitor.name ~= "eDP-1" then
          hl.exec_cmd("sleep 1 && hyprctl keyword monitor " .. monitor.name .. ",disable && sleep 0.3 && hyprctl reload")
        end
      end)

      -- Toggle eDP-1 native/Full HD resolution (for TV mirroring)
      hl.bind(mainMod .. " + A", hl.dsp.exec_cmd("resolution-toggle"))
    '';
  };

  home.packages  = [
    pkgs.crosspipe
    pkgs.qemu
    pkgs.cameractrls-gtk4
    pkgs.remmina
    pkgs.kdePackages.k3b
    pkgs.kdePackages.kdenlive
    resolutionToggle
  ];

  programs.webapps = {
    enable = true;
    apps = {
      Youtube-music = {
        url = "https://music.youtube.com";
        icon = "youtube-music";
        categories = [ "Audio" "Music" ];
      };
      Claude = {
        url = "https://claude.ai";
        categories = [ "Network" ];
      };
      Chatgpt = {
        url = "https://chat.openai.com";
      };
    };
  };

  programs.zsh.enable = true;
}
