{ pkgs, ... }:

{
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  boot.kernelPackages = pkgs.linuxPackages_latest;

  boot.kernel.sysctl."fs.inotify.max_user_watches" = 524288;  # VS Code, MEGAcmd, etc. consume many watches
}
