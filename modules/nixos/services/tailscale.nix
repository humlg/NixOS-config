{ config, lib, pkgs, ... }:

let
  cfg = config.custom.tailscale;
in
{
  options.custom.tailscale = {
    enable = lib.mkEnableOption "Tailscale VPN mesh networking";
  };

  config = lib.mkIf cfg.enable {
    services.tailscale.enable = true;
    networking.firewall.trustedInterfaces = [ "tailscale0" ];
    # Tailscale routes traffic that bypasses the normal reverse-path check
    # (e.g. subnet routers, exit nodes) — loosen it so the firewall doesn't
    # drop legitimate tailscale0 traffic.
    networking.firewall.checkReversePath = "loose";
  };
}
