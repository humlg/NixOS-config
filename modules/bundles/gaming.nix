{ config, lib, pkgs, ... }:

let
  cfg = config.bundles.gaming;
in
{
  options.bundles.gaming = {
    enable = lib.mkEnableOption "Gaming bundle (Steam, frame generation, overlays)";
  };

  config = lib.mkIf cfg.enable {
    programs.steam.enable = true;
    programs.gamemode = {
      enable = true;
      settings = {
        general.renice = 10;
        gpu = {
          apply_gpu_optimisations = "accept-responsibility";
          gpu_device = 0;
          amd_performance_level = "high";
        };
      };
    };

    # Fix for Steam Linux Runtime (pressure-vessel) on NixOS:
    # Inside the container, /sbin/ldconfig is a symlink chain that ultimately
    # resolves to the NixOS sbin-ldconfig stub, which points to /bin/ldconfig
    # (an absolute path). Inside the container /bin/ldconfig -> /sbin/ldconfig,
    # creating a loop. Pressure-vessel then fails to set LD_LIBRARY_PATH,
    # so LD_PRELOAD'd libraries (gameoverlayrenderer.so) can't find libGL.so.1.
    # Fix: put a real ldconfig at /usr/sbin/ldconfig so the chain terminates.
    system.activationScripts.steamLdconfig = {
      text = ''
        mkdir -p /usr/sbin
        ln -sfn ${pkgs.glibc.bin}/bin/ldconfig /usr/sbin/ldconfig
      '';
      deps = [];
    };

    hardware.graphics.enable = true;
    hardware.graphics.enable32Bit = true;

    environment.systemPackages = with pkgs; [
      gamescope
      mangohud
      lsfg-vk
      lsfg-vk-ui

      prismlauncher # Minecraft Java launcher
    ];
  };
}
