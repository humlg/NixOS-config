{ config, lib, pkgs, inputs, ... }:

{
  imports = [
    ./hardware-configuration.nix
    ./file-system.nix
    ../../modules/system/common.nix
    ../../modules/system/locale.nix
    ../../modules/system/amd-gpu.nix
    ../../modules/system/sddm.nix
    ../../modules/desktop/hyprland-system.nix
    ../../modules/programs/zsh.nix
    ../../modules/services/bluetooth.nix
    ../../modules/bundles/photography.nix
    ../../modules/bundles/3d-printing.nix
    ../../modules/bundles/wine.nix
    ../../modules/bundles/gaming.nix
    ../../modules/system/secrets.nix
    ../../modules/programs/zen-browser.nix
    ../../modules/programs/mullvad.nix
    ../../modules/services/ollama.nix
    ../../modules/services/sunshine-moonlight.nix
  ];

  networking.hostName = "sauron";

  # Wake-on-LAN: keep WoL enabled across reboots (kernel resets it otherwise).
  # Requires BIOS "Wake on LAN" / "PCI-E Power On" enabled, and ErP/EuP disabled.
  networking.interfaces.enp9s0.wakeOnLan.enable = true;

  hardware.graphics = {
    enable = true;
    enable32Bit = true;
  };

  boot.kernelModules = [ "nct6775" "i2c-dev" ];
  boot.kernelParams = [ "amd_pstate=passive" ];

  powerManagement.cpuFreqGovernor = "performance";

  # HiDPI: larger font for TTY console and boot menu
  boot.loader.systemd-boot.consoleMode = "max";
  #console.packages = [ pkgs.terminus_font ];
  #console.font = "ter-132b";

  services.colord.enable = true;
  services.udev.packages = [ pkgs.openrgb ];

  custom.sunshine-moonlight.enable = true;
  custom.sunshine-moonlight.enableMoonlight = true;

  programs.zen-browser-custom.enable = true;
  programs.kdeconnect.enable = true;
  programs.coolercontrol.enable = true;
  custom.bluetooth.enable = true;
  custom.mullvad.enable = true;
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
