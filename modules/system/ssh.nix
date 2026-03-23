{ config, ... }:

{
  services.openssh.enable = true;

  networking.hosts = {
    "192.168.4.133" = [ "sauron" ];
    "192.168.4.150" = [ "saruman" ];
  };
}
