{ config, lib, pkgs, ... }:

let
  cfg = config.services.megacmd;

  # Build the sync-setup script from declared sync pairs
  syncScript = pkgs.writeShellScript "mega-sync-setup" ''
    # Exit gracefully if not logged in
    if ! ${pkgs.megacmd}/bin/mega-whoami &>/dev/null; then
      echo "MEGAcmd: not logged in — skipping sync setup"
      exit 0
    fi

    # Get currently configured syncs
    existing=$(${pkgs.megacmd}/bin/mega-sync 2>/dev/null || true)

    ${lib.concatStringsSep "\n" (lib.mapAttrsToList (local: remote: ''
      if echo "$existing" | grep -q "${local}"; then
        echo "MEGAcmd: sync already exists for ${local} — skipping"
      else
        echo "MEGAcmd: adding sync ${local} -> ${remote}"
        ${pkgs.megacmd}/bin/mega-sync "${local}" "${remote}"
      fi
    '') cfg.syncs)}
  '';

  megaLogin = pkgs.writeShellScriptBin "mega-login" ''
    if [ -z "$1" ]; then
      echo "Usage: mega-login <email>"
      echo ""
      echo "Logs into MEGA.nz via MEGAcmd. You only need to do this once"
      echo "per machine — the session is persisted in ~/.megaCmd/."
      echo ""
      echo "After login, restart the sync setup service:"
      echo "  systemctl --user restart mega-sync-setup"
      exit 1
    fi
    ${pkgs.megacmd}/bin/mega-login "$@"
  '';
in
{
  options.services.megacmd = {
    enable = lib.mkEnableOption "MEGAcmd cloud sync daemon";

    syncs = lib.mkOption {
      type = lib.types.attrsOf lib.types.str;
      default = { };
      example = {
        "/home/david/Documents" = "/Documents";
        "/home/david/Pictures" = "/Pictures";
      };
      description = "Mapping of local paths to MEGA remote paths to sync.";
    };
  };

  config = lib.mkIf cfg.enable {
    home.packages = [
      pkgs.megacmd
      megaLogin
    ];

    # Long-running MEGAcmd server daemon
    systemd.user.services.mega-cmd-server = {
      Unit = {
        Description = "MEGAcmd server daemon";
        After = [ "default.target" ];
      };
      Service = {
        Type = "simple";
        ExecStart = "${pkgs.megacmd}/bin/mega-cmd-server";
        Restart = "on-failure";
        RestartSec = 5;
      };
      Install.WantedBy = [ "default.target" ];
    };

    # Oneshot service to configure declared sync pairs
    systemd.user.services.mega-sync-setup = {
      Unit = {
        Description = "Configure MEGAcmd sync pairs";
        After = [ "mega-cmd-server.service" ];
        Requires = [ "mega-cmd-server.service" ];
      };
      Service = {
        Type = "oneshot";
        ExecStartPre = "${pkgs.coreutils}/bin/sleep 3";
        ExecStart = "${syncScript}";
        RemainAfterExit = true;
      };
      Install.WantedBy = [ "default.target" ];
    };
  };
}
