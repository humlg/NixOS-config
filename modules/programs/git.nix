{ config, lib, ... }:

let
  cfg = config.programs.git;
in
{
  config = lib.mkIf cfg.enable {
    programs.git.settings = {
      user = {
        name = "David Huml";
        email = "david.huml@email.cz";
      };
      pull.rebase = true;
    };
  };
}
