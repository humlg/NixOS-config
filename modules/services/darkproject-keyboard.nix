{ config, lib, pkgs, ... }:

let
  cfg = config.custom.darkproject-keyboard;
in
{
  options.custom.darkproject-keyboard = {
    enable = lib.mkEnableOption "udev rules for Dark Project keyboards (e.g. Bushido/KD87A), granting browser (WebHID/WebUSB) access to the config interface without root — used by Dark Project's web-based configurator at https://demo.jukaie.com. Equivalent to the rules installed by their upstream install script (addRules.sh), applied declaratively instead of curl | sudo bash";
  };

  config = lib.mkIf cfg.enable {
    services.udev.extraRules = ''
      SUBSYSTEM=="hidraw", ATTRS{idVendor}=="342d", ATTRS{idProduct}=="e40f", TAG+="uaccess"
      SUBSYSTEM=="usb", ATTRS{idVendor}=="342d", ATTRS{idProduct}=="e40f", TAG+="uaccess"
      SUBSYSTEM=="hidraw", ATTRS{idVendor}=="2442", ATTRS{idProduct}=="b071", TAG+="uaccess"
      SUBSYSTEM=="hidraw", ATTRS{idVendor}=="342d", ATTRS{idProduct}=="e410", TAG+="uaccess"
      SUBSYSTEM=="usb", ATTRS{idVendor}=="342d", ATTRS{idProduct}=="e410", TAG+="uaccess"
    '';
  };
}
