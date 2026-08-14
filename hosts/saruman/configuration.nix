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
    ../../modules/services/darkproject-keyboard.nix
    ../../modules/services/lid-undock-hibernate.nix
    ../../modules/bundles/photography.nix
    ../../modules/bundles/3d-printing.nix
    ../../modules/bundles/wine.nix
    ../../modules/programs/mullvad.nix
    ../../modules/services/ollama.nix
    ../../modules/bundles/gaming.nix
    ../../modules/bundles/yg-work-system.nix
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

  # Hibernate support: resume from the LUKS swap partition above (unlocked in
  # initrd, same as root). Needed because lid-close now hibernates instead of
  # suspending — see the s2idle sleep-hang note below and maintenance.md item 7.
  boot.resumeDevice = "/dev/mapper/luks-01b4b8c5-f250-4434-b00a-86d91e74ce05";

  # Plymouth boot splash (shows * for LUKS password entry)
  boot.initrd.systemd.enable = true;
  # pm_debug_messages + amd_pmc.enable_stb=1: capture PM/S0ix diagnostics for
  # the recurring s2idle wake hang (logging only, no behavior change).
  # No reboot= override: the kernel's default reset chain works on BIOS
  # PSCN23WW, while forcing reboot=acpi (old-BIOS workaround) or reboot=efi
  # hangs at the firmware reset step.
  # amdgpu.dcdebugmask=0x800 (DC_DISABLE_IPS): disables Idle Power States on
  # the iGPU. Targeted kernel bugzilla #219445 (this exact laptop model),
  # bisected to commit f6098641d3e1e4 ("drm/amd/display: fix s2idle entry for
  # DCN3.5+"). Confirmed 2026-07-22 NOT to fix the sleep hang on its own
  # (hang recurred after a real reboot with this param active) — kept as a
  # harmless secondary mitigation. Lid-close now hibernates instead of
  # suspending (see boot.resumeDevice above), sidestepping s2idle entirely;
  # see maintenance.md item 7.
  # pcie_ports=compat: forces ACPI-based PCIe hotplug instead of native
  # hotplug/AER, to work around a shutdown/reboot hang that occurs only when
  # a USB-C dock (monitor with built-in dock, connected via the AMD USB4/
  # Thunderbolt controller) is plugged in — confirmed by testing docked vs.
  # unplugged. EXPERIMENTAL, not yet confirmed to fix it (see maintenance.md).
  boot.kernelParams = [ "quiet" "amd_pstate=active" "pm_debug_messages" "amd_pmc.enable_stb=1" "amdgpu.dcdebugmask=0x800" "pcie_ports=compat" ];
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

  # Power button hibernates instead of powering off. Deliberately NOT "suspend":
  # every s2idle entry on this machine risks the wedge described below, and the
  # power key is just as much a path into it as the lid is.
  services.logind.settings.Login.HandlePowerKey = "hibernate";

  # Lid close: hibernate, restored 2026-08-14 after the s2idle retest FAILED.
  # The 2026-08-02 revert to plain "suspend" (retesting whether a nixpkgs/kernel
  # update had fixed upstream bugzilla #219445) ran on kernel 7.1.5 for 12 days
  # and reproduced the hang 8 times out of ~36 suspends (~22%): the journal ends
  # dead on "PM: suspend entry (s2idle)" with no matching "PM: suspend exit",
  # requiring a hard power-off and losing unsaved work. By contrast the
  # 2026-07-24..08-02 hibernate window logged 9 lid-close cycles with a
  # hibernation entry/exit pair every time and zero hangs (one of them a 7-day
  # hibernation). Do not revert this to "suspend" again without a concrete
  # upstream fix to point at — see maintenance.md item 7.
  services.logind.settings.Login.HandleLidSwitch = "hibernate";
  services.logind.settings.Login.HandleLidSwitchExternalPower = "hibernate";

  # Lid close *with an external monitor attached*: keep running, so the laptop
  # can be used lid-shut on the Iiyama. This was already the effective
  # behaviour (logind defaults HandleLidSwitchDocked to "ignore" whenever it
  # sees an external display) but was never stated — pinning it explicitly so
  # it can't drift, and so the pairing with lid-undock-hibernate below is
  # obvious. Note logind evaluates this *only* at the moment the lid event
  # fires; it never re-checks afterwards, which is exactly the gap the module
  # below closes.
  services.logind.settings.Login.HandleLidSwitchDocked = "ignore";

  # ...and once that external monitor is unplugged while the lid is still
  # shut, hibernate — otherwise the machine stays awake in a bag.
  custom.lid-undock-hibernate.enable = true;

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

  # Saruman mainly connects out to other machines — no need to run the
  # Sunshine server here, just the Moonlight client.
  custom.sunshine-moonlight.enableMoonlight = true;

  programs.kdeconnect.enable = true;
  custom.bluetooth.enable = true;
  custom.darkproject-keyboard.enable = true;
  custom.mullvad.enable = true;
  bundles.photography.enable = true;
  bundles."3d-printing".enable = true;
  bundles.wine.enable = true;
  bundles.gaming.enable = true;
  bundles.yg-work.enable = true;

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
    openttd
  ];

  programs.zen-browser-custom.enable = true;

  system.stateVersion = "25.11";
}
