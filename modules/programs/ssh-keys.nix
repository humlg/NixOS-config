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

      "Host homelab" = {
        Hostname = "192.168.5.1";
        User = "david";
        IdentityFile = "/home/david/.ssh/homelab";
      };
    };
  };
}
