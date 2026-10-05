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
    networking.networkmanager.plugins = [ pkgs.networkmanager-openvpn ];

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
  };
}
