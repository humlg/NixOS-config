{ config, lib, pkgs, inputs, ... }:

{
  imports = [
    ./hardware-configuration.nix
    ./file-system.nix
    ../../modules/nixos/system-common.nix
    ../../modules/nixos/system-locale.nix
    ../../modules/nixos/system-amd-gpu.nix
    ../../modules/nixos/system-sddm.nix
    ../../modules/nixos/desktop-hyprland.nix
    ../../modules/nixos/program-zsh.nix
    ../../modules/nixos/program-mkrepo.nix
    ../../modules/nixos/service-bluetooth.nix
    ../../modules/nixos/bundle-photography.nix
    ../../modules/nixos/bundle-3d-printing.nix
    ../../modules/nixos/bundle-wine.nix
    ../../modules/nixos/bundle-gaming.nix
    ../../modules/nixos/bundle-ham-radio.nix
    ../../modules/nixos/system-secrets.nix
    ../../modules/nixos/program-zen-browser.nix
    ../../modules/nixos/program-mullvad.nix
    ../../modules/nixos/service-ollama.nix
    ../../modules/nixos/service-sunshine.nix
    ../../modules/nixos/service-moonlight.nix
    ../../modules/nixos/service-wivrn.nix
    ../../modules/nixos/service-tailscale.nix
    ../../modules/nixos/desktop-noctalia.nix
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

  custom.sunshine.enable = true;
  custom.moonlight.enable = true;
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
  # docs/maintenance.md item 19.
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
