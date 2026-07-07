{ ... }:

{
  programs.ssh = {
    enable = true;
    enableDefaultConfig = false;
    settings = {
      "Host github-huml-yg" = {
        Hostname = "github.com";
        User = "git";
        IdentityFile = "/home/david/.ssh/github_huml_yg";
      };
    };
  };
}
