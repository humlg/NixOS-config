{ config, lib, pkgs, inputs, ... }:

{
  imports = [
    ./hardware-configuration.nix
    ./file-system.nix
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

  # K3B needs direct (non-ACL/session) access to the optical writer
  users.users.david.extraGroups = [ "cdrom" ];

  # K3B is a home-manager (user) package, so its system D-Bus service file
  # (org.kde.k3b, the root-privileged burn helper) isn't picked up by the
  # system dbus daemon unless registered here explicitly.
  services.dbus.packages = [ pkgs.kdePackages.k3b ];

  # cdrecord issues raw SCSI commands (e.g. REZERO_UNIT) via /dev/sr0. The
  # kernel blocks "unsafe" SG_IO commands on block devices without
  # CAP_SYS_RAWIO, even with cdrom-group rw access — only /dev/sg* char
  # devices are exempt. Grant the capability directly rather than routing
  # through /dev/sg (K3B/cdrecord choose the device node themselves).
  security.wrappers.cdrecord = {
    owner = "root";
    group = "root";
    capabilities = "cap_sys_rawio+ep";
    source = "${pkgs.cdrtools}/bin/cdrecord";
  };

  boot.supportedFilesystems = [ "nfs" ];

  # LUKS encryption (swap partition)
  boot.initrd.luks.devices."luks-01b4b8c5-f250-4434-b00a-86d91e74ce05".device = "/dev/disk/by-uuid/01b4b8c5-f250-4434-b00a-86d91e74ce05";

  # Plymouth boot splash (shows * for LUKS password entry)
  boot.initrd.systemd.enable = true;
  # pm_debug_messages + amd_pmc.enable_stb=1: capture PM/S0ix diagnostics for
  # the recurring s2idle wake hang (logging only, no behavior change).
  # No reboot= override: the kernel's default reset chain works on BIOS
  # PSCN23WW, while forcing reboot=acpi (old-BIOS workaround) or reboot=efi
  # hangs at the firmware reset step.
  # pm_debug_messages + amd_pmc.enable_stb=1: capture PM/S0ix diagnostics for
  # the s2idle wake hang (logging only, no behavior change).
  boot.kernelParams = [ "quiet" "amd_pstate=active" "pm_debug_messages" "amd_pmc.enable_stb=1" ];
  # ucsi_acpi times out on resume (ETIMEDOUT) and corrupts EC state,
  # causing the second s2idle cycle to hang indefinitely.
  boot.blacklistedKernelModules = [ "ucsi_acpi" ];
  # MT7922 (mt7921e) firmware wedges the platform when the link sits in deep
  # ASPM states: hangs on s2idle resume after long sleeps and at the final
  # step of reboot. Keeping the link out of ASPM avoids both.
  boot.extraModprobeConfig = ''
    options mt7921e disable_aspm=1
  '';
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
  # sg (SCSI generic) isn't autoloaded for the USB CD/DVD burner, but
  # Brasero/libburn need it to send burn commands (not just read via /dev/sr0)
  boot.kernelModules = [ "ideapad_laptop" "sg" ];
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
