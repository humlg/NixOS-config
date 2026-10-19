{ config, lib, pkgs, ... }:

let
  cfg = config.custom.backlight-permissions;
in
{
  options.custom.backlight-permissions = {
    enable = lib.mkEnableOption "udev rules giving the `video` group write access to `/sys/class/backlight/*/brightness`, so brightness control works without a resolvable logind session — docs/maintenance.md #29";
  };

  config = lib.mkIf cfg.enable {
    # Same rules brightnessctl ships, which never reach /etc/udev because
    # brightnessctl is a home.packages entry — docs/architecture.md.
    services.udev.packages = [
      (pkgs.writeTextDir "lib/udev/rules.d/90-backlight.rules" ''
        ACTION=="add", SUBSYSTEM=="backlight", RUN+="${pkgs.coreutils}/bin/chgrp video /sys/class/backlight/%k/brightness"
        ACTION=="add", SUBSYSTEM=="backlight", RUN+="${pkgs.coreutils}/bin/chmod g+w /sys/class/backlight/%k/brightness"
      '')
    ];
  };
}
