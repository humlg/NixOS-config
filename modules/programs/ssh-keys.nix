{ ... }:

{
  programs.ssh = {
    enable = true;
    matchBlocks = {
      "github-huml-yg" = {
        hostname = "github.com";
        user = "git";
        identityFile = "/home/david/.ssh/github_huml_yg";
      };
    };
  };
}
