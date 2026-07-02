{ config, lib, pkgs, inputs, ... }:

{
  imports = [
    ./hardware-configuration.nix
    ../../modules/system/common.nix
    ../../modules/system/locale.nix
    ../../modules/system/sddm.nix
    ../../modules/desktop/hyprland-system.nix
    ../../modules/programs/zsh.nix
    ../../modules/services/bluetooth.nix
    ../../modules/services/kvm.nix
    ../../modules/bundles/photography.nix
    ../../modules/bundles/3d-printing.nix
    ../../modules/bundles/wine.nix
    ../../modules/programs/mullvad.nix
    ../../modules/services/ollama.nix
    ../../modules/bundles/gaming.nix
    ../../modules/programs/zen-browser.nix
    ../../modules/system/secrets.nix
    ../../modules/services/sunshine-moonlight.nix
  ];

  networking.hostName = "saruman";

  # LUKS encryption (swap partition)
  boot.initrd.luks.devices."luks-01b4b8c5-f250-4434-b00a-86d91e74ce05".device = "/dev/disk/by-uuid/01b4b8c5-f250-4434-b00a-86d91e74ce05";

  # Plymouth boot splash (shows * for LUKS password entry)
  boot.initrd.systemd.enable = true;
  boot.kernelParams = [ "quiet" "amd_pstate=active" "reboot=acpi" ];
  # ucsi_acpi times out on resume (ETIMEDOUT) and corrupts EC state,
  # causing the second s2idle cycle to hang indefinitely.
  boot.blacklistedKernelModules = [ "ucsi_acpi" ];
  boot.plymouth = {
    enable = true;
    theme = "motion";
    themePackages = [
      (pkgs.adi1090x-plymouth-themes.override { selected_themes = [ "motion" ]; })
    ];
  };

  services.colord.enable = true;

  # Firmware updates via LVFS (fwupdmgr refresh && fwupdmgr update)
  services.fwupd.enable = true;

  # Power management
  services.tlp = {
    enable = true;
    settings = {
      PLATFORM_PROFILE_ON_AC = "balanced";
      CPU_ENERGY_PERF_POLICY_ON_AC = "balance_performance";
      PLATFORM_PROFILE_ON_BAT = "low-power";
      CPU_ENERGY_PERF_POLICY_ON_BAT = "balance_power";
    };
  };

  # Power button suspends instead of powering off
  services.logind.settings.Login.HandlePowerKey = "suspend";

  # Battery charge limit for Lenovo IdeaPad 14ASP9
  # Conservation mode caps charge at ~80% via ideapad_laptop kernel module
  boot.kernelModules = [ "ideapad_laptop" ];
  systemd.services.ideapad-conservation-mode = {
    description = "Enable Lenovo IdeaPad conservation mode";
    wantedBy = [ "multi-user.target" ];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
      ExecStart = "${pkgs.bash}/bin/bash -c 'echo 1 > /sys/bus/platform/devices/VPC*/conservation_mode'";
      ExecStop = "${pkgs.bash}/bin/bash -c 'echo 0 > /sys/bus/platform/devices/VPC*/conservation_mode'";
    };
  };

  custom.sunshine-moonlight.enable = true;

  programs.kdeconnect.enable = true;
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

  # AMD GPU: ROCm OpenCL for DaVinci Resolve and other GPU-accelerated apps.
  # libglvnd provides libGL.so.1 (the GL dispatch library), which the Steam
  # Linux Runtime's pressure-vessel container needs but Mesa does not include.
  hardware.graphics.extraPackages = with pkgs; [
    rocmPackages.clr.icd
    libglvnd
  ];

  # RDNA 3.5 (Radeon 880M/890M) is not yet officially supported by ROCm.
  # Override the GFX version so ROCm treats it as gfx1100 (RDNA 3).
  environment.variables.HSA_OVERRIDE_GFX_VERSION = "11.0.0";

  environment.systemPackages = with pkgs; [
    gtk3
    codex
    clinfo
  ];

  programs.zen-browser-custom.enable = true;

  system.stateVersion = "25.11";
}
