{ config, lib, pkgs, ... }:

let
  cfg = config.custom.darkproject-keyboard;
in
{
  options.custom.darkproject-keyboard = {
    enable = lib.mkEnableOption "udev rules for Dark Project keyboards (e.g. Bushido/KD87A), granting browser (WebHID/WebUSB) access to the config interface without root — used by Dark Project's web-based configurator at https://demo.jukaie.com. Equivalent to the rules installed by their upstream install script (addRules.sh), applied declaratively instead of curl | sudo bash";
  };

  config = lib.mkIf cfg.enable {
    # Must ship as a udev *package* (preserves filename/priority), not services.udev.extraRules
    # (always written to 99-local.rules). systemd's 73-seat-late.rules is what actually turns
    # TAG+="uaccess" into a real ACL, via `TAG=="uaccess", RUN{builtin}+="uaccess"` — but that
    # match is evaluated in the same single-pass scan, so a uaccess tag added by a 99- rule is
    # still unset when 73- checks for it, and the ACL builtin never runs. The hidraw nodes end
    # up correctly TAG+="uaccess" (visible in `udevadm info`) but stay mode 600 root:root with
    # no ACL entry, so the browser's WebHID request silently can't open the device. Naming this
    # rules file 71- (anything <73) puts the tag in place before 73-seat-late.rules checks it.
    services.udev.packages = [
      (pkgs.writeTextDir "lib/udev/rules.d/71-darkproject-keyboard.rules" ''
        SUBSYSTEM=="hidraw", ATTRS{idVendor}=="342d", ATTRS{idProduct}=="e40f", TAG+="uaccess"
        SUBSYSTEM=="usb", ATTRS{idVendor}=="342d", ATTRS{idProduct}=="e40f", TAG+="uaccess"
        SUBSYSTEM=="hidraw", ATTRS{idVendor}=="2442", ATTRS{idProduct}=="b071", TAG+="uaccess"
        SUBSYSTEM=="hidraw", ATTRS{idVendor}=="342d", ATTRS{idProduct}=="e410", TAG+="uaccess"
        SUBSYSTEM=="usb", ATTRS{idVendor}=="342d", ATTRS{idProduct}=="e410", TAG+="uaccess"
      '')
    ];
  };
}
