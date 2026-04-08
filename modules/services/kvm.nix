{ config, lib, pkgs, ... }:

{
  virtualisation.libvirtd = {
    enable = true;
    qemu = {
      package = pkgs.qemu_kvm;
      runAsRoot = true;
      swtpm.enable = true; # TPM emulation (required for Windows 11)
    };
  };

  virtualisation.spiceUSBRedirection.enable = true;

  users.users.david.extraGroups = [ "libvirtd" ];

  # dconf is needed for virt-manager to persist settings
  programs.dconf.enable = true;

  environment.systemPackages = with pkgs; [
    virt-manager
    virt-viewer
    virtiofsd # shared filesystem between host and guest
  ];

  # Ensure the default NAT network is active for VMs
  systemd.services.libvirt-default-network = {
    description = "Start libvirt default network";
    after = [ "libvirtd.service" ];
    requires = [ "libvirtd.service" ];
    wantedBy = [ "multi-user.target" ];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
      ExecStart = "${pkgs.bash}/bin/bash -c '${pkgs.libvirt}/bin/virsh net-start default || true'";
    };
  };
}
