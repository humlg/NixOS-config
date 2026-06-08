{ config, lib, pkgs, ... }:

{
  hardware.nvidia = {
    modesetting.enable = true;
    powerManagement.enable = true;
    open = false; # proprietary driver
    nvidiaSettings = true;
    #package = config.boot.kernelPackages.nvidiaPackages.new_feature;
    package = config.boot.kernelPackages.nvidiaPackages.stable;
  };

  boot.kernelParams = ["nvidia_drm.modeset=1" "nvidia_drm.fbdev=1"];
  services.xserver.videoDrivers = ["nvidia"];
}
