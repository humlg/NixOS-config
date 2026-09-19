{ lib, config, ... }:

# Personal WireGuard VPN tunnel for saruman, provisioned from a full
# wg-quick config file (encrypted whole, since it's already in exactly the
# format wg-quick wants — no need to split it into individual NixOS
# networking.wireguard options). Manual-only: this tunnel's AllowedIPs is
# 0.0.0.0/0, ::/0 (full-tunnel), so it does not autostart at boot — bring it
# up with `sudo wg-quick up wg-saruman`, down with `sudo wg-quick down
# wg-saruman`.
let
  cfg = config.custom.wireguard-saruman;
in
{
  options.custom.wireguard-saruman = {
    enable = lib.mkEnableOption "Personal WireGuard VPN tunnel (wg-saruman)";
  };

  config = lib.mkIf cfg.enable {
    age.secrets.wg-saruman = {
      file = ../../secrets/wg-saruman.age;
      owner = "root";
      mode = "0400";
    };

    networking.wg-quick.interfaces.wg-saruman = {
      autostart = false;
      configFile = config.age.secrets.wg-saruman.path;
    };
  };
}
