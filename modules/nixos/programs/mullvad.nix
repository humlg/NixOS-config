{ pkgs, lib, config, ... }:

let
  cfg = config.custom.mullvad;
in
{
  options.custom.mullvad = {
    enable = lib.mkEnableOption "Mullvad VPN (GUI app + CLI + system daemon)";
  };

  config = lib.mkIf cfg.enable {
    environment.systemPackages = [
      pkgs.mullvad-vpn
      pkgs.mullvad
    ];

    services.mullvad-vpn = {
      enable = true;
    };
  };
}
