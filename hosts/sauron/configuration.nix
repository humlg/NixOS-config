{ config, lib, pkgs, inputs, ... }:

{
  imports = [
    ./hardware-configuration.nix
    ./file-system.nix
    ../../modules/nixos/system-common.nix
    ../../modules/nixos/system-amd-gpu.nix
    ../../modules/nixos/bundle-photography.nix
    ../../modules/nixos/bundle-3d-printing.nix
    ../../modules/nixos/bundle-wine.nix
    ../../modules/nixos/bundle-gaming.nix
    ../../modules/nixos/bundle-ham-radio.nix
    ../../modules/nixos/bundle-workstation.nix
    ../../modules/nixos/service-wivrn.nix
  ];

  networking.hostName = "sauron";

  # Kernel resets WoL on every boot otherwise; also requires BIOS WoL/PCI-E Power On enabled.
  networking.interfaces.enp9s0.wakeOnLan.enable = true;

  hardware.graphics = {
    enable = true;
    enable32Bit = true;
  };

  boot.kernelModules = [ "nct6775" "i2c-dev" ];
  boot.kernelParams = [ "amd_pstate=passive" ];

  powerManagement.cpuFreqGovernor = "performance";

  boot.loader.systemd-boot.consoleMode = "max";  # HiDPI: larger TTY console/boot-menu font
  #console.packages = [ pkgs.terminus_font ];    # fallback if consoleMode=max isn't enough
  #console.font = "ter-132b";

  custom.wivrn.enable = true;

  programs.coolercontrol.enable = true;
  bundles.workstation.enable = true;
  custom.noctalia.enable = true;  # full replacement here, unlike saruman's staged pilot — docs/maintenance.md #19
  bundles.photography.enable = true;
  bundles."3d-printing".enable = true;
  bundles.wine.enable = true;
  bundles.gaming.enable = true;
  bundles.ham-radio.enable = true;

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
    usbutils
    bs-manager
  ];

  system.stateVersion = "25.11";
}
