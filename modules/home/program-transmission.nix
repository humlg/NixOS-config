{ config, lib, pkgs, ... }:

let
  cfg = config.custom.transmission-vpn;

  # Patches bind-address-ipv4 to Mullvad's tunnel IP on every launch — docs/architecture.md.
  vpnWrapper = pkgs.writeShellScript "transmission-qt-vpn-wrapper" ''
    set -euo pipefail

    vpn_iface="wg0-mullvad"
    config_dir="''${TRANSMISSION_HOME:-$HOME/.config/transmission}"
    settings="$config_dir/settings.json"

    vpn_ip=$(ip -4 -o addr show "$vpn_iface" 2>/dev/null | awk '{print $4}' | cut -d/ -f1 || true)

    if [ -z "$vpn_ip" ]; then
      notify-send -u critical "Transmission" "Mullvad VPN ($vpn_iface) is not connected — refusing to start Transmission." || true
      exit 1
    fi

    mkdir -p "$config_dir"
    if [ -f "$settings" ]; then
      tmp=$(mktemp "$config_dir/settings.json.XXXXXX")
      jq --arg ip "$vpn_ip" '."bind-address-ipv4" = $ip' "$settings" > "$tmp"
      mv "$tmp" "$settings"
    else
      jq -n --arg ip "$vpn_ip" --arg dl "$HOME/Downloads" \
        '{"bind-address-ipv4": $ip, "download-dir": $dl}' > "$settings"
    fi

    exec "$REAL_TRANSMISSION_QT" "$@"
  '';

  transmissionQtVpn = pkgs.symlinkJoin {
    name = "transmission-qt-vpn";
    paths = [ pkgs.transmission_4-qt ];
    nativeBuildInputs = [ pkgs.makeWrapper ];
    postBuild = ''
      rm $out/bin/transmission-qt
      makeWrapper ${vpnWrapper} $out/bin/transmission-qt \
        --set REAL_TRANSMISSION_QT ${pkgs.transmission_4-qt}/bin/transmission-qt \
        --prefix PATH : ${lib.makeBinPath [ pkgs.jq pkgs.iproute2 pkgs.libnotify ]}
    '';
  };
in
{
  options.custom.transmission-vpn = {
    enable = lib.mkEnableOption "Transmission (Qt) wrapped to bind all peer traffic to the Mullvad VPN tunnel, refusing to start if it's down";
  };

  config = lib.mkIf cfg.enable {
    home.packages = [ transmissionQtVpn ];
  };
}
