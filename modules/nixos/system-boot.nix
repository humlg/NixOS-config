{ pkgs, ... }:

{
  # Bootloader
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  # Use latest kernel
  boot.kernelPackages = pkgs.linuxPackages_latest;

  # Prevent inotify watch exhaustion (VS Code, MEGAcmd, etc. consume many watches)
  boot.kernel.sysctl."fs.inotify.max_user_watches" = 524288;
}
