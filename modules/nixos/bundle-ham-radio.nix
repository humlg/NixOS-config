{ config, lib, pkgs, ... }:

let
  cfg = config.bundles.ham-radio;
in
{
  options.bundles.ham-radio = {
    enable = lib.mkEnableOption "Amateur (ham) radio bundle: SDR receiving and FT8/digital-mode software";
  };

  config = lib.mkIf cfg.enable {
    environment.systemPackages = with pkgs; [
      sdrpp   # SDR receiver GUI
      sdrangel
      wsjtx   # FT8/FT4/JT65 weak-signal digital modes
      hamlib  # rig-control (CAT) backend used by wsjtx and others
    ];

    services.udev.packages = [ pkgs.rtl-sdr ];  # non-root USB access to RTL-SDR dongles
    users.groups.plugdev = { };
    users.users.david.extraGroups = [ "plugdev" "dialout" ]; # RTL-SDR USB / CAT-control serial
  };
}
