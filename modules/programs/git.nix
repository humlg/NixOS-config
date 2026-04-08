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
      init.defaultBranch = "main";
      pull.rebase = true;
      push.autoSetupRemote = true;
      merge.conflictstyle = "zdiff3";
      diff.algorithm = "histogram";
      rerere.enabled = true;
    };
  };
}
