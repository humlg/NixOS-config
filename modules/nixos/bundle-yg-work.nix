{ pkgs, lib, config, ... }:

# NixOS half of the yg-work bundle (HM half: modules/home/bundle-yg-work.nix) — docs/architecture.md.
let
  cfg = config.bundles.yg-work;
in
{
  options.bundles.yg-work = {
    enable = lib.mkEnableOption "Bundle of tools used for work in Yellow Grid (system-level: 1NCE cellular IoT VPN)";
  };

  config = lib.mkIf cfg.enable {
    # Native openvpn service, not NetworkManager's GUI/nmcli import path — NM's
    # nm-openvpn plugin fails to hand the long 1NCE JWT password to openvpn over
    # its management-interface socket (upstream bug, see docs/maintenance.md).
    services.openvpn.servers."1nce" = {
      config = "config /run/agenix/1nce-vpn-ovpn";
      autoStart = false;
    };

    age.secrets."1nce-vpn-ovpn" = {
      file = ../../secrets/1nce-vpn.ovpn.age;
      owner = "david";
      mode = "0400";
    };

    age.secrets."1nce-vpn-credentials" = {
      file = ../../secrets/1nce-vpn-credentials.age;
      owner = "david";
      mode = "0400";
    };

    # services.printing.enable is already on via desktop-hyprland.nix.
    hardware.printers.ensurePrinters = [{
      name = "Godex_G530";
      deviceUri = "socket://192.168.100.78:9100";
      model = "drv:///sample.drv/zebra.ppd";
      ppdOptions = { Resolution = "300dpi"; };
    }];
  };
}
