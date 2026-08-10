{ ... }:

let
  flakeRepo = "/home/david/repos/nixos-config";

  # Fixed display width every value is right-justified into (via printf)
  # before the row's border char is appended literally. Because the value
  # arrives already padded to this exact width, the border always lands in
  # the same column regardless of the value's real length (IP/date/kernel
  # version, ...) — no cursor-position escape trickery needed.
  valueWidth = 28;

  # Wrap a shell snippet that prints a value on stdout so the value is
  # captured, then right-justified into valueWidth via printf.
  padded = cmd: ''
    v="$(${cmd})"
    printf "%${toString valueWidth}s" "$v"
  '';

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
          right = 1;
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
          type = "command";
          key = "│ ";
          text = padded ''printf "\033[1;31m%s\033[0m" "$(hostname)"'';
          format = "{}│";
        }
        {
          type = "custom";
          key = midBorder;
        }
        {
          type = "command";
          key = "│ Kernel";
          text = padded "fastfetch --logo none -s kernel --pipe true 2>/dev/null | sed -E 's/^Kernel[[:space:]]*//; s/\\x1b\\[[0-9;]*[A-Za-z]//g'";
          format = "{}│";
        }
        {
          type = "command";
          key = "│ Uptime";
          text = padded "fastfetch --logo none -s uptime --pipe true 2>/dev/null | sed -E 's/^Uptime[[:space:]]*//; s/\\x1b\\[[0-9;]*[A-Za-z]//g'";
          format = "{}│";
        }
        {
          type = "command";
          key = "│ Local IP";
          text = padded "fastfetch --logo none -s localip --pipe true 2>/dev/null | grep -oE '([0-9]{1,3}\\.){3}[0-9]{1,3}' | head -1";
          format = "{}│";
        }
        {
          type = "command";
          key = "│ External IP";
          text = padded "timeout 2 fastfetch --logo none -s publicip --pipe true 2>/dev/null | grep -oE '([0-9]{1,3}\\.){3}[0-9]{1,3}' | head -1";
          format = "{}│";
        }
        {
          type = "custom";
          key = midBorder;
        }
        {
          type = "command";
          key = "│ Generation";
          text = padded "ls /nix/var/nix/profiles/system-*-link 2>/dev/null | grep -oP 'system-\\K[0-9]+' | sort -n | tail -1";
          format = "{}│";
        }
        {
          type = "command";
          key = "│ Last Flake Pin";
          text = padded "git -C ${flakeRepo} log -1 --format='%as (%ar)' -- flake.lock";
          format = "{}│";
        }
        {
          type = "custom";
          key = bottomBorder;
        }
      ];
    };
  };
}
