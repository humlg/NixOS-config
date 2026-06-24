{ config, ... }:

{
  age.secrets = {
    shell-env = {
      file = ../../secrets/shell-env.age;
      owner = "david";
      mode  = "0400";
    };
    
    github-huml-yg = {
      file  = ../../secrets/github-huml-yg.age;
      path  = "/home/david/.ssh/github_huml_yg";
      owner = "david";
      mode  = "0600";
    };
  };
}
