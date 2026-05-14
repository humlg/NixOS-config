{ config, lib, pkgs, inputs, ... }:

{
  imports = [
    ./hardware-configuration.nix
    ./file-system.nix
    ../../modules/system/common.nix
    ../../modules/system/locale.nix
    ../../modules/system/nvidia.nix
    ../../modules/system/sddm.nix
    ../../modules/desktop/hyprland-system.nix
    ../../modules/programs/zsh.nix
    ../../modules/services/bluetooth.nix
    ../../modules/bundles/photography.nix
    ../../modules/bundles/3d-printing.nix
    ../../modules/bundles/wine.nix
    ../../modules/bundles/gaming.nix
    ../../modules/system/secrets.nix
  ];

  networking.hostName = "sauron";

  hardware.graphics = {
    enable = true;
    enable32Bit = true;
  };

  boot.kernelModules = [ "nct6775" ];

  # HiDPI: larger font for TTY console and boot menu
  boot.loader.systemd-boot.consoleMode = "max";
  #console.packages = [ pkgs.terminus_font ];
  #console.font = "ter-132b";

  services.colord.enable = true;

  programs.kdeconnect.enable = true;
  programs.coolercontrol.enable = true;
  custom.bluetooth.enable = true;
  bundles.photography.enable = true;
  bundles."3d-printing".enable = true;
  bundles.wine.enable = true;
  bundles.gaming.enable = true;

  home-manager = {
    backupFileExtension = "hm-bak";
    extraSpecialArgs = { inherit inputs; nur = inputs.nur; };
    users = {
      "david" = import ./home.nix;
    };
  };

  environment.systemPackages = with pkgs; [
    gtk3
    xterm
    alacritty
    wofi
    spice-vdagent
    quickshell
    lm_sensors
    stress
    cava
    openrgb
    usbutils
  ];

  system.stateVersion = "25.11";
}
