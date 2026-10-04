{ config, lib, pkgs, inputs, ... }:

{
  imports = [
    ./hardware-configuration.nix
    ./file-system.nix
    ../../modules/nixos/system/common.nix
    ../../modules/nixos/system/locale.nix
    ../../modules/nixos/system/amd-gpu.nix
    ../../modules/nixos/system/sddm.nix
    ../../modules/nixos/desktop/hyprland.nix
    ../../modules/nixos/programs/zsh.nix
    ../../modules/nixos/services/bluetooth.nix
    ../../modules/nixos/bundles/photography.nix
    ../../modules/nixos/bundles/3d-printing.nix
    ../../modules/nixos/bundles/wine.nix
    ../../modules/nixos/bundles/gaming.nix
    ../../modules/nixos/bundles/ham-radio.nix
    ../../modules/nixos/system/secrets.nix
    ../../modules/nixos/programs/zen-browser.nix
    ../../modules/nixos/programs/mullvad.nix
    ../../modules/nixos/services/ollama.nix
    ../../modules/nixos/services/sunshine-moonlight.nix
    ../../modules/nixos/services/wivrn.nix
    ../../modules/nixos/services/tailscale.nix
    ../../modules/nixos/desktop/noctalia.nix
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
  custom.wivrn.enable = true;

  programs.zen-browser-custom.enable = true;
  programs.kdeconnect.enable = true;
  programs.coolercontrol.enable = true;
  custom.bluetooth.enable = true;
  custom.mullvad.enable = true;
  custom.tailscale.enable = true;
  # Noctalia desktop shell — full replacement of AGS/swaync/hyprlock/waypaper/
  # hypridle (all auto-gated off by useNoctalia in home.nix below). Unlike
  # saruman this skips the staged pilot: sauron has none of saruman's
  # sleep/idle-hang history that motivated going phase by phase. See
  # maintenance.md item 19.
  custom.noctalia.enable = true;
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
    openrgb
    usbutils
    bs-manager
  ];

  system.stateVersion = "25.11";
}
