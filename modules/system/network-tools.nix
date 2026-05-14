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
      # Host/port discovery
      nmap

      # Packet capture & analysis
      wireshark
      tcpdump

      # Connectivity & path tracing
      mtr          # combined ping + traceroute (TUI)
      traceroute
      inetutils    # ping, hostname, ifconfig, telnet

      # DNS
      bind         # dig, nslookup, host

      # Bandwidth & throughput
      iperf3       # point-to-point throughput testing
      nethogs      # per-process bandwidth (live)
      bandwhich    # per-process/connection bandwidth (TUI)

      # Port / socket utilities
      # Interface & link info
      ethtool      # NIC settings, link speed, wake-on-LAN

      # Domain info
      whois
    ];

    # Allow wireshark to capture packets without root
    programs.wireshark.enable = true;
    users.users.david.extraGroups = [ "wireshark" ];
  };
}
