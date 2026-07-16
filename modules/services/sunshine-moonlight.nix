{ config, lib, pkgs, ... }:

let
  cfg = config.custom.sunshine-moonlight;
in
{
  options.custom.sunshine-moonlight = {
    enable = lib.mkEnableOption "Sunshine game streaming server (host side — lets other machines stream from this one)";
    enableMoonlight = lib.mkEnableOption "Moonlight streaming client (connect to other machines running Sunshine)";
  };

  config = lib.mkMerge [
    (lib.mkIf cfg.enable {
      services.sunshine = {
        enable = true;
        openFirewall = true;
        # CAP_SYS_ADMIN is required for KMS display capture (reads /dev/dri directly,
        # works without an active compositor session — necessary for unattended access).
        capSysAdmin = true;
        settings = {
          sunshine_name = config.networking.hostName;
        };
      };

      # KMS capture accesses /dev/dri/* devices
      users.users.david.extraGroups = [ "video" "render" ];
    })

    (lib.mkIf cfg.enableMoonlight {
      environment.systemPackages = with pkgs; [
        moonlight-qt
      ];
    })
  ];
}
