{ config, lib, pkgs, inputs, ... }:

{
  imports = [
    ./hardware-configuration.nix
    ./file-system.nix
    ../../modules/nixos/system-common.nix
    ../../modules/nixos/service-kvm.nix
    ../../modules/nixos/service-darkproject-keyboard.nix
    ../../modules/nixos/service-backlight-permissions.nix
    ../../modules/nixos/service-lid-undock-hibernate.nix
    ../../modules/nixos/bundle-photography.nix
    ../../modules/nixos/bundle-3d-printing.nix
    ../../modules/nixos/bundle-wine.nix
    ../../modules/nixos/bundle-gaming.nix
    ../../modules/nixos/bundle-yg-work.nix
    ../../modules/nixos/bundle-ham-radio.nix
    ../../modules/nixos/bundle-workstation.nix
    ../../modules/nixos/service-wireguard-saruman.nix
    ../../modules/nixos/system-amdgpu-s2idle-patch.nix
    ../../modules/nixos/system-amdgpu-hdmi-scdc-fix.nix
    ../../modules/nixos/system-tui-askpass.nix
  ];

  networking.hostName = "saruman";

  services.displayManager.defaultSession = "hyprland-uwsm";

  # K3B needs direct (non-ACL/session) access to the optical writer
  users.users.david.extraGroups = [ "cdrom" ];

  # K3B's system D-Bus burn-helper service file needs explicit registration (it's an HM package).
  services.dbus.packages = [ pkgs.kdePackages.k3b ];

  # cdrecord needs CAP_SYS_RAWIO for raw SCSI via /dev/sr0 — cdrom-group access alone isn't enough.
  security.wrappers.cdrecord = {
    owner = "root";
    group = "root";
    capabilities = "cap_sys_rawio+ep";
    source = "${pkgs.cdrtools}/bin/cdrecord";
  };

  boot.supportedFilesystems = [ "nfs" ];

  boot.initrd.luks.devices."luks-01b4b8c5-f250-4434-b00a-86d91e74ce05".device = "/dev/disk/by-uuid/01b4b8c5-f250-4434-b00a-86d91e74ce05";

  # Kept so manual `systemctl hibernate` works even though sleep paths use plain suspend — docs/maintenance.md #7.
  boot.resumeDevice = "/dev/mapper/luks-01b4b8c5-f250-4434-b00a-86d91e74ce05";

  boot.initrd.systemd.enable = true;  # required for LUKS unlock + system-tui-askpass.nix
  custom.tuiAskpass.enable = true;
  # pm_debug_messages/amd_pmc.enable_stb: s2idle diagnostics. dcdebugmask=0x40000: backlight curve
  # fix. Full history: docs/maintenance.md #7, #25.
  boot.kernelParams = [ "amd_pstate=active" "pm_debug_messages" "amd_pmc.enable_stb=1" "amdgpu.dcdebugmask=0x40000" ];
  boot.extraModprobeConfig = ''
    options mt7921e disable_aspm=1
  '';  # avoids a sleep/reboot wedge — docs/maintenance.md #7
  boot.plymouth.enable = false;  # off in favor of custom.tuiAskpass (system-tui-askpass.nix)

  services.fwupd.enable = true;

  services.power-profiles-daemon.enable = true;  # not TLP — docs/maintenance.md #20

  # Plain suspend on every sleep path — docs/maintenance.md #7 for the full history.
  services.logind.settings.Login.HandlePowerKey = "suspend";
  services.logind.settings.Login.HandleLidSwitch = "suspend";
  services.logind.settings.Login.HandleLidSwitchExternalPower = "suspend";

  # Pairs with custom.lid-undock-hibernate below — docs/architecture.md.
  services.logind.settings.Login.HandleLidSwitchDocked = "ignore";

  custom.lid-undock-hibernate.enable = true;
  custom.lid-undock-hibernate.sleepCommand = "systemctl --no-block suspend";

  # Disabled 2026-09-09, stock-kernel retest — docs/maintenance.md #7.
  custom.amdgpu-s2idle-patch.enable = false;
  custom.amdgpu-s2idle-patch.fasterHibernateCompression = false;

  # Re-enabled 2026-10-16, confirmed fixes a live HDMI-A-1 "connected but
  # disabled" repro (-22 vendor-infoframe failure) — docs/maintenance.md #23/#24.
  custom.amdgpu-hdmi-scdc-fix.enable = true;

  # ideapad_laptop: ~80% battery charge conservation mode. sg: needed by Brasero/libburn to burn (not just read).
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

  # Not auto-started — mainly connects out to other machines, Sunshine host is occasional.
  custom.sunshine.autoStart = false;

  custom.darkproject-keyboard.enable = true;
  custom.backlight-permissions.enable = true;  # docs/maintenance.md #29
  custom.wireguard-saruman.enable = true;
  bundles.workstation.enable = true;
  custom.noctalia.enable = true;  # pairs with desktop.hyprland-desktop.useNoctalia in home.nix
  bundles.photography.enable = true;
  bundles."3d-printing".enable = true;
  bundles.wine.enable = true;
  bundles.gaming.enable = true;
  bundles.yg-work.enable = true;
  bundles.ham-radio.enable = true;

  # YG/Netio Discover's UDP discovery replies arrive as broadcast, not unicast, so
  # stateful firewall tracking never matches them — needs an explicit allow.
  networking.firewall.allowedUDPPorts = [ 62386 ];

  home-manager = {
    backupFileExtension = "hm-bak";
    extraSpecialArgs = { inherit inputs; nur = inputs.nur; };
    users = {
      "david" = import ./home.nix;
    };
  };

  # libglvnd: libGL.so.1 for Steam's pressure-vessel container (Mesa doesn't include it).
  hardware.graphics.extraPackages = with pkgs; [
    rocmPackages.clr.icd
    libglvnd
  ];

  environment.variables.HSA_OVERRIDE_GFX_VERSION = "11.0.0";  # RDNA3.5 unsupported by ROCm — docs/maintenance.md #6

  environment.systemPackages = with pkgs; [
    gtk3
    codex
    clinfo
    openttd
    krita
    obs-studio
  ];

  system.stateVersion = "25.11";
}
