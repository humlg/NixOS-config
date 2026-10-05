{ config, lib, pkgs, ... }:

let
  cfg = config.system.network-tools;
in
{
  options.system.network-tools = {
    enable = lib.mkEnableOption "Network troubleshooting tools";
  };

  config = lib.mkIf cfg.enable {
    environment.systemPackages = with pkgs; [
      nmap
      wireshark
      tcpdump
      mtr          # combined ping + traceroute (TUI)
      traceroute
      inetutils    # ping, hostname, ifconfig, telnet
      bind         # dig, nslookup, host
      iperf3
      nethogs      # per-process bandwidth (live)
      bandwhich    # per-process/connection bandwidth (TUI)
      ethtool
      wakeonlan
      whois
    ];

    programs.wireshark.enable = true;
    programs.wireshark.usbmon.enable = true;  # capture USB HID traffic (e.g. keyboard protocol work)
    users.users.david.extraGroups = [ "wireshark" ];
  };
}
