{ config, lib, pkgs, ... }:

{
  programs.zsh = {
    enable = true;
    autosuggestions.enable = true;
    syntaxHighlighting.enable = true;
    ohMyZsh = {
      enable = true;
      plugins = [ "git" ];
      theme = "agnoster";
    };
    interactiveShellInit = ''
      if command -v fastfetch >/dev/null 2>&1; then
        fastfetch
      fi
      [ -f /run/agenix/shell-env ] && source /run/agenix/shell-env

      # kitten ssh relies on kitty's terminal protocol — only alias it inside a kitty window.
      [ -n "$KITTY_WINDOW_ID" ] && alias ssh="kitten ssh"
    '';

    shellAliases = {
      rebuild      = "sudo nixos-rebuild switch --flake /home/david/repos/nixos-config#$(hostname)";
      rebuild-test = "sudo nixos-rebuild test --flake /home/david/repos/nixos-config#$(hostname)";
    };
  };
}
