{ pkgs, ... }:

{
  environment.systemPackages = [
    pkgs.gh
    pkgs.git
  ];

  programs.zsh.interactiveShellInit = ''
    mkrepo() {
      local visibility=private
      case "$1" in
        --public)      visibility=public ;;
        --private|"")  visibility=private ;;
        *) echo "usage: mkrepo [--public|--private]" >&2; return 1 ;;
      esac

      git init -b main && \
        git add -A && \
        git commit -m "Initial commit" && \
        gh repo create "$(basename "$PWD")" --"$visibility" --source=. --remote=origin --push
    }
  '';
}
