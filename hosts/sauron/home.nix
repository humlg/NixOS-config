{ ... }:

{
  imports = [
    ../../modules/home/common.nix
    ../../modules/home/bundle-general.nix
    ../../modules/home/desktop-hyprland-desktop.nix
    ../../modules/home/program-cava.nix
    ../../modules/home/bundle-workstation.nix
  ];

  bundles.general.enable = true;
  bundles.workstation.enable = true;

  desktop.hyprland-desktop = {
    enable = true;

    useNoctalia = true;  # full replacement here (see custom.noctalia.enable) — docs/maintenance.md #19

    monitors = ''
      monitor = DP-2, 2560x1440@165.08, 1920x0, 1
      monitor = HDMI-A-1, 1920x1080@75, 0x0, 1
      monitor = , preferred, auto, 1
    '';
    monitorsLua = ''
      hl.monitor({ output = "DP-2",     mode = "2560x1440@165.08", position = "1920x0", scale = 1 })
      hl.monitor({ output = "HDMI-A-1", mode = "1920x1080@75",     position = "0x0",    scale = 1 })
      hl.monitor({ output = "",         mode = "preferred",          position = "auto",   scale = 1 })
    '';

    # FreeSync/VRR, fullscreen-only — avoids compositor tearing while still benefiting games.
    extraConfig = ''
      misc {
        vrr = 2
      }
    '';
    extraLuaConfig = ''
      hl.config({ misc = { vrr = 2 } })
    '';
  };
}
