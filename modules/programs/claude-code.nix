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
      hooks = {
        Notification = [
          {
            hooks = [
              {
                type = "command";
                command = "pw-play /run/current-system/sw/share/sounds/freedesktop/stereo/bell.oga 2>/dev/null || true";
                async = true;
              }
            ];
          }
        ];
        Stop = [
          {
            hooks = [
              {
                type = "command";
                command = "pw-play /run/current-system/sw/share/sounds/freedesktop/stereo/complete.oga 2>/dev/null || true";
                async = true;
              }
            ];
          }
        ];
      };
    };
  };
}
