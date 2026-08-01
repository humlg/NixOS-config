{ ... }:

let
  flakeRepo = "/home/david/repos/nixos-config";
in
{
  programs.fastfetch = {
    enable = true;
    settings = {
      "$schema" = "https://github.com/fastfetch-cli/fastfetch/raw/master/doc/json_schema.json";

      logo = {
        type = "builtin";
        source = "NixOS_small";
        padding = {
          top = 0;
          left = 0;
          right = 3;
        };
      };

      display = {
        separator = "  ";
        color = {
          keys = "magenta";
          title = "red";
        };
        key = {
          width = 15;
          type = "string";
        };
      };

      modules = [
        {
          type = "title";
          format = "{host-name-colored}";
        }
        "separator"
        "kernel"
        "uptime"
        {
          type = "localip";
          key = "Local IP";
          showPrefixLen = false;
        }
        {
          type = "publicip";
          key = "External IP";
          timeout = 2000;
          format = "{ip}";
        }
        "break"
        {
          type = "command";
          key = "Generations";
          text = "ls -d /nix/var/nix/profiles/system-*-link 2>/dev/null | wc -l";
        }
        {
          type = "command";
          key = "Last Flake Pin";
          text = "git -C ${flakeRepo} log -1 --format='%as (%ar)' -- flake.lock";
        }
      ];
    };
  };
}
