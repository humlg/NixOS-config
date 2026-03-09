{ config, lib, ... }:

let
  cfg = config.programs.git;
in
{
  config = lib.mkIf cfg.enable {
    programs.git = {
      userName = "David Huml";
      userEmail = "david.huml@email.cz";
    };
  };
}
