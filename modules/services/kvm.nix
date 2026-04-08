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
}
