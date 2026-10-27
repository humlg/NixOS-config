{ pkgs, lib, config, ... }:

let
  cfg = config.custom.solidcraft;
  appId = "ai.storyteller.solidcraft";
in
{
  options.custom.solidcraft = {
    enable = lib.mkEnableOption "SolidCraft parametric CAD (Flatpak from the upstream SolidCraft remote)";
  };

  config = lib.mkIf cfg.enable {
    services.flatpak.enable = true;

    # Not in nixpkgs — installed imperatively as a system Flatpak, once. Updates: `flatpak update`.
    systemd.services.solidcraft-flatpak-install = {
      description = "Install SolidCraft Flatpak";
      wantedBy = [ "multi-user.target" ];
      wants = [ "network-online.target" ];
      after = [ "network-online.target" ];
      path = [ pkgs.flatpak ];
      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
        # Offline at boot (laptop) — keep retrying instead of waiting for the next boot.
        Restart = "on-failure";
        RestartSec = "5min";
      };
      script = ''
        flatpak remote-add --system --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo
        flatpak remote-add --system --if-not-exists solidcraft https://docs.solidcraft.io/flatpak/solidcraft.flatpakrepo
        if ! flatpak info --system ${appId} >/dev/null 2>&1; then
          flatpak install --system --noninteractive solidcraft ${appId}
        fi
      '';
    };
  };
}
