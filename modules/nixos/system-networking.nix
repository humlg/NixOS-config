{ ... }:

{
  networking.networkmanager.enable = true;

  networking.firewall.allowedTCPPorts = [ 46687 ];
}
