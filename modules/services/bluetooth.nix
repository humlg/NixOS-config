{ config, lib, pkgs, ... }:

{
  #hardware.enableRedistributedFirmware = true;
  hardware.bluetooth.enable = true;
  hardware.bluetooth.powerOnBoot = true;
  services.blueman.enable = true;
  hardware.bluetooth.settings = {
    General = {
      Enable = "Source,Sink,Mediam,Socket";
      Experimental = true;
    };
  };
}