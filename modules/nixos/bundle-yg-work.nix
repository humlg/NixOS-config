{ pkgs, lib, config, ... }:

# System-level (NixOS) half of the yg-work bundle — the Home Manager half
# (packages) lives in yg-work.nix, imported separately into home.nix. Both
# share the bundles.yg-work.enable option name by convention, but since
# NixOS and Home Manager are separate module trees, each must be toggled
# on its own host file.
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
