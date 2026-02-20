{ config, lib, pkgs, ... }:

{
  hardware.nvidia = {
    modesetting.enable = true;
    powerManagement.enable = false;
    open = false; # proprietary driver
    nvidiaSettings = true;
  };

  #boot.kernelParams = ["nvidia_drm.modeset=1"];
  services.xserver.videoDrivers = ["nvidia"];
}