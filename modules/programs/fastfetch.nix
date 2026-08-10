{ ... }:

let
  flakeRepo = "/home/david/repos/nixos-config";

  # Raw ANSI escape (ESC, 0x1b) — used to build cursor save/restore/move
  # sequences so the frame's right border lands in a fixed column no matter
  # how long a value (IP, date, kernel version, ...) turns out to be:
  # save the cursor right where the value starts, print the value, restore
  # to that saved point, then step a fixed distance right before drawing
  # the border. This is immune to value-length changes since it never
  # depends on an absolute column — only on a fixed offset from the save
  # point, which fastfetch itself always places consistently thanks to
  # display.key.width.
  esc = "";
  valueBudget = 28;
  save = "${esc}[s";
  restoreAndBorder = "${esc}[u${esc}[${toString valueBudget}C│";
  framed = value: "${save}${value}${restoreAndBorder}";

  frameWidth = 41;
  hbar = builtins.concatStringsSep "" (builtins.genList (_: "─") frameWidth);
  topBorder = "╭${hbar}╮";
  midBorder = "├${hbar}┤";
  bottomBorder = "╰${hbar}╯";
in
{
  programs.fastfetch = {
    enable = true;
    settings = {
      "$schema" = "https://github.com/fastfetch-cli/fastfetch/raw/master/doc/json_schema.json";

      logo = {
        type = "data";
        source = ''
          $1                ___   __
                   /¯\    \  \ /  ;
                   \  \    \  v  /
                /¯¯¯   ¯¯¯¯\\   /  /\
               ’————————————·\  \ /  ;
                    /¯¯;      \ //  /_
              _____/  /        ‘/     \
              \      /,        /  /¯¯¯¯
               ¯¯/  // \      /__/
                .  / \  \·————————————.
                 \/  /   \\_____   ___/
                    /  ,  \     \  \
                    \_/ \__\     \_/            '';
        color = {
          "1" = "blue";
        };
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
          type = "custom";
          key = topBorder;
        }
        {
          type = "title";
          key = "│ ";
          format = framed "{host-name-colored}";
        }
        {
          type = "custom";
          key = midBorder;
        }
        {
          type = "kernel";
          key = "│ Kernel";
          format = framed "{sysname} {release}";
        }
        {
          type = "uptime";
          key = "│ Uptime";
          format = framed "{formatted}";
        }
        {
          type = "localip";
          key = "│ Local IP";
          showPrefixLen = false;
          format = framed "{ipv4}";
        }
        {
          type = "publicip";
          key = "│ External IP";
          timeout = 2000;
          format = framed "{ip}";
        }
        {
          type = "custom";
          key = midBorder;
        }
        {
          type = "command";
          key = "│ Generation";
          text = "ls /nix/var/nix/profiles/system-*-link 2>/dev/null | grep -oP 'system-\\K[0-9]+' | sort -n | tail -1";
          format = framed "{}";
        }
        {
          type = "command";
          key = "│ Last Flake Pin";
          text = "git -C ${flakeRepo} log -1 --format='%as (%ar)' -- flake.lock";
          format = framed "{}";
        }
        {
          type = "custom";
          key = bottomBorder;
        }
      ];
    };
  };
}
