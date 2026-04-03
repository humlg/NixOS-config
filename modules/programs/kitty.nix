{ config, lib, ... }:

let
  cfg = config.programs.kitty;
in
{
  config = lib.mkIf cfg.enable {
    programs.kitty.settings = {
      confirm_os_window_close = 0;
      background_opacity = "0.8";
      allow_remote_control = "yes";
    };

    programs.kitty.extraConfig = ''
      include ${config.home.homeDirectory}/.cache/wal/colors-kitty.conf
      background_opacity 0.8
    '';
  };
}
