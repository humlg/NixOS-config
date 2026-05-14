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
    '';
  };
}
