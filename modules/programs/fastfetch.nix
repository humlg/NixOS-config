{ ... }:

let
  flakeRepo = "/home/david/repos/nixos-config";

  # Fixed display width every value is right-justified into (via printf)
  # before the row's border char is appended literally. Because the value
  # arrives already padded to this exact width, the border always lands in
  # the same column regardless of the value's real length (IP/date/kernel
  # version, ...) — no cursor-position escape trickery needed.
  valueWidth = 28;

  # Must exceed the longest "│ <Label>" key text plus display.separator,
  # or fastfetch's key-width alignment jump lands *inside* the label
  # instead of after it, corrupting the text. Longest key is
  # "│ Generation" (12 chars) + 2-char separator = 14, so this needs to
  # stay above 15.
  keyWidth = 16;

  # Wrap a shell snippet that prints a value on stdout so the value is
  # captured, then right-justified into valueWidth via printf.
  padded = cmd: ''
    v="$(${cmd})"
    printf "%${toString valueWidth}s" "$v"
  '';

  frameWidth = keyWidth + valueWidth - 2;
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
        # Printed above the frame (not beside it) so the frame's own width
        # — not the logo's — is what has to fit in a narrow terminal.
        position = "top";
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
          right = 0;
        };
      };

      display = {
        separator = "  ";
        color = {
          keys = "magenta";
          title = "red";
        };
        key = {
          width = keyWidth;
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
          # Color codes must wrap the already-padded string, not sit inside
          # the printf width argument — otherwise their invisible bytes eat
          # into the width budget and this row falls short of the others.
          text = ''printf "\033[1;31m%${toString valueWidth}s\033[0m" "$(hostname)"'';
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
          key = "│ Public IP";
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
          key = "│ Flake Pin";
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
