{ config, lib, pkgs, ... }:

{
  hardware.nvidia = {
    modesetting.enable = true;
    powerManagement.enable = true;
    open = false; # proprietary driver
    nvidiaSettings = true;
  };

  boot.kernelParams = ["nvidia_drm.modeset=1" "nvidia_drm.fbdev=1"];
  services.xserver.videoDrivers = ["nvidia"];
}