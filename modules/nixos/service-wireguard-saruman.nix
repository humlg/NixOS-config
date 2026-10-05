{ lib, config, ... }:

# Personal WireGuard VPN tunnel for saruman, via NetworkManager rather than
# wg-quick — rationale and private-key handling: docs/architecture.md.
let
  cfg = config.custom.wireguard-saruman;
  privateKeyEnvFile = "/run/wg-homelab-nm.env";
in
{
  options.custom.wireguard-saruman = {
    enable = lib.mkEnableOption "Personal WireGuard VPN tunnel (wg-homelab), managed via NetworkManager";
  };

  config = lib.mkIf cfg.enable {
    age.secrets.wg-homelab = {
      file = ../../secrets/wg-homelab.age;
      owner = "root";
      mode = "0400";
    };

    systemd.services.wg-homelab-nm-env = {
      description = "Extract wg-homelab's private key for NetworkManager's declarative profile";
      before = [ "NetworkManager-ensure-profiles.service" ];
      wantedBy = [ "multi-user.target" ];
      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
        UMask = "0177";
      };
      script = ''
        key=$(sed -n 's/^[Pp]rivate[Kk]ey[[:space:]]*=[[:space:]]*//p' ${config.age.secrets.wg-homelab.path} | head -n1)
        printf 'WG_HOMELAB_PRIVATE_KEY=%s\n' "$key" > ${privateKeyEnvFile}
        chmod 600 ${privateKeyEnvFile}
      '';
    };

    systemd.services.NetworkManager-ensure-profiles = {
      after = [ "wg-homelab-nm-env.service" ];
      wants = [ "wg-homelab-nm-env.service" ];
    };

    networking.networkmanager.ensureProfiles = {
      environmentFiles = [ privateKeyEnvFile ];

      profiles.wg-homelab = {
        connection = {
          id = "wg-homelab";
          type = "wireguard";
          interface-name = "wg-homelab";
          autoconnect = "false";
        };
        wireguard = {
          private-key = "$WG_HOMELAB_PRIVATE_KEY";
        };
        "wireguard-peer.ku9U71kJ7J6lEyF/WyPgn8mWzUQb7SSXcTtQdoJawCM=" = {
          endpoint = "78.80.162.80:51820";
          allowed-ips = "0.0.0.0/0;::/0;";
          persistent-keepalive = "25";
        };
        ipv4 = {
          method = "manual";
          address1 = "10.100.0.3/24";
          dns = "1.1.1.1;";
        };
        ipv6 = {
          method = "disabled";
        };
      };
    };
  };
}
