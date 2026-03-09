{ config, lib, ... }:

let
  cfg = config.programs.kitty;
in
{
  config = lib.mkIf cfg.enable {
    programs.kitty.settings = {
      confirm_os_window_close = 0;
    };
  };
}
