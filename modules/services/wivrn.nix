{ config, lib, pkgs, ... }:

let
  cfg = config.custom.wivrn;
in
{
  options.custom.wivrn = {
    enable = lib.mkEnableOption "WiVRn wireless VR streaming server (Meta Quest 2 and other standalone headsets)";
  };

  config = lib.mkIf cfg.enable {
    services.wivrn = {
      enable = true;
      openFirewall = true;
      autoStart = true;
      # CAP_SYS_NICE wrapper for asynchronous reprojection — reduces perceived latency.
      highPriority = true;
    };

    # WiVRn advertises itself over mDNS so the headset can auto-discover it;
    # the wivrn module enables avahi but doesn't open the firewall for it.
    services.avahi.openFirewall = true;
  };
}
