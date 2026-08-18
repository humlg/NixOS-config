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
    ../../modules/bundles/ham-radio.nix
    ../../modules/programs/zen-browser.nix
    ../../modules/system/secrets.nix
    ../../modules/services/sunshine-moonlight.nix
    ../../modules/system/amdgpu-s2idle-patch.nix
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
  # initrd, same as root). All sleep paths hibernate directly again as of
  # 2026-08-18 — see the logind block below. See maintenance.md item 7.
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
  # DCN3.5+"). Confirmed 2026-07-22 NOT to fix the sleep hang, and we now know
  # why it never could: the offending call in dm_suspend() is guarded by
  # dc->caps.ips_support (a hardware capability bit), while DC_DISABLE_IPS sets
  # the separate dc->config.disable_ips mode field. The actual fix is the kernel
  # patch enabled via custom.amdgpu-s2idle-patch below. Kept for now only so the
  # s2idle validation soak changes one variable at a time — drop it once the
  # patched kernel has a clean week. See maintenance.md item 7.
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

  # All sleep paths hibernate directly again as of 2026-08-18. Plain s2idle
  # (2026-08-17 -> 2026-08-18) did NOT hold: the amdgpu kernel patch was
  # "validated" on 2026-08-16 with 3 clean cycles (7 s / 22 min / 60 min, all
  # watched, awake), but the next two *unattended* overnight sleeps both hung
  # the exact same way (journal ends dead on "PM: suspend entry (s2idle)" with
  # no matching "PM: suspend exit") -- 2 for 2, not an isolated fluke. The
  # patch may still help (baseline was ~22% of ~36 suspends before it), but it
  # clearly does not eliminate the hang, and an unattended hang costs a whole
  # night. See maintenance.md item 7.
  #
  # This is a *direct* hibernate, never suspend-then-hibernate. That
  # distinction matters: the one hibernate-resume crash seen on this machine
  # (TTM "list_add corruption" in ttm_bo_populate, wedging the GPU, hard
  # power-off needed) happened specifically via suspend-then-hibernate --
  # s2idle first, then a 60-min HibernateDelaySec silently resumed it
  # internally before converting to hibernate. Direct hibernate (straight from
  # a fully awake state, no intervening s2idle resume) is exactly what ran
  # clean for 9/9 cycles including a 7-day hibernation during 2026-07-24 ->
  # 08-02, before this kernel patch even existed -- so never route sleep
  # through suspend-then-hibernate here. hibernate.compressor is pinned to
  # lzo (see custom.amdgpu-s2idle-patch.fasterHibernateCompression below) to
  # also remove LZ4 as a variable, since it's the other named suspect for that
  # crash and was never exercised during the proven-good window.
  services.logind.settings.Login.HandlePowerKey = "hibernate";
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
  # shut, sleep — otherwise the machine stays awake in a bag. Direct hibernate
  # (the module's default), matching the lid/power-key paths above.
  custom.lid-undock-hibernate.enable = true;

  # Reduces the s2idle hang rate (see the logind block above for why it's no
  # longer trusted as the sole fix) and is kept in case anything still ends up
  # going through plain suspend. fasterHibernateCompression is off: LZ4 is one
  # of the two named suspects for the hibernate-resume TTM crash in
  # maintenance.md item 7 and was never exercised during the proven-good
  # direct-hibernate window, so pin back to LZO (the option this repo used
  # before LZ4 existed) rather than carry an unproven variable into the
  # backstop this is meant to protect.
  custom.amdgpu-s2idle-patch.enable = true;
  custom.amdgpu-s2idle-patch.fasterHibernateCompression = false;

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
  bundles.ham-radio.enable = true;

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
