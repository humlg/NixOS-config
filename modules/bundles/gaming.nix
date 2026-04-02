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
    programs.gamemode.enable = true;

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
