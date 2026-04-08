{ config, lib, pkgs, ... }:

let
  cfg = config.programs.claude-code;

  settingsJson = builtins.toJSON {
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
in
{
  options.programs.claude-code = {
    enable = lib.mkEnableOption "Claude Code CLI configuration";
  };

  config = lib.mkIf cfg.enable {
    home.packages = [ pkgs.claude-code ];

    home.file.".claude/settings.json".text = settingsJson;
  };
}
