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

    # Seed settings.json once — Claude Code manages it from then on
    home.activation.claude-code-settings = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      if [ ! -f "$HOME/.claude/settings.json" ]; then
        mkdir -p "$HOME/.claude"
        cat > "$HOME/.claude/settings.json" << 'SETTINGS'
${settingsJson}
SETTINGS
      fi
    '';
  };
}
