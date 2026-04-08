{ config, lib, ... }:

let
  cfg = config.programs.claude-code;
in
{
  config = lib.mkIf cfg.enable {
    programs.claude-code.settings = {
      permissions = {
        allow = [
          "Bash(git add:*)"
          "Bash(git commit:*)"
          "WebFetch(domain:github.com)"
        ];
        defaultMode = "default";
      };
      attribution = {
        commit = "";
        pr = "";
      };
    };
  };
}
