{ config, ... }:

{
  age.secrets = {
    shell-env = {
      file = ../../secrets/shell-env.age;
      owner = "david";
      mode  = "0400";
    };

    # SSH private key example — uncomment and adapt per key:
    # ssh_myserver = {
    #   file = ../../secrets/ssh_myserver.age;
    #   path = "/home/david/.ssh/myserver";
    #   owner = "david";
    #   mode  = "0600";
    # };
  };
}
