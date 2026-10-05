{ config, lib, pkgs, ... }:

let
  cfg = config.custom.bluetooth;
in
{
  options.custom.bluetooth = {
    enable = lib.mkEnableOption "Bluetooth support with blueman";
  };

  config = lib.mkIf cfg.enable {
    hardware.bluetooth.enable = true;
    hardware.bluetooth.powerOnBoot = true;
    services.blueman.enable = true;
    hardware.bluetooth.settings = {
      General = {
        Enable = "Source,Sink,Mediam,Socket";
        Experimental = true;
      };
    };
  };
}
