{ pkgs, ... }:

{
  environment.systemPackages = [
    pkgs.gh
    pkgs.git
  ];

  programs.zsh.interactiveShellInit = ''
    mkrepo() {
      local visibility=private
      local business=0
      for arg in "$@"; do
        case "$arg" in
          --public)   visibility=public ;;
          --private)  visibility=private ;;
          --business) business=1 ;;
          *) echo "usage: mkrepo [--public|--private] [--business]" >&2; return 1 ;;
        esac
      done

      local account=humlg
      local sshhost=github-humlg
      if [[ $business -eq 1 ]]; then
        account=Huml-YG
        sshhost=github-huml-yg
      fi

      # gh repo create acts on whichever account is "active" in `gh auth switch`,
      # which is independent of the SSH key actually used to push — so pin both.
      gh auth switch --hostname github.com --user "$account" || return 1

      git init -b main && \
        git add -A && \
        git commit --allow-empty -m "Initial commit" && \
        gh repo create "$(basename "$PWD")" --"$visibility" --source=. --remote=origin && \
        git remote set-url origin "$(git remote get-url origin | sed "s/github\.com/$sshhost/")" && \
        git push -u origin main
    }
  '';
}
