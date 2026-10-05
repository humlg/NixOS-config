{ config, lib, pkgs, ... }:

let
  cfg = config.bundles.gaming;
in
{
  options.bundles.gaming = {
    enable = lib.mkEnableOption "Gaming bundle (Steam, frame generation, overlays)";
  };

  config = lib.mkIf cfg.enable {
    programs.steam = {
      enable = true;
      gamescopeSession.enable = true;
    };
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

    # Steam pressure-vessel ldconfig loop fix — docs/maintenance.md #11.
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
