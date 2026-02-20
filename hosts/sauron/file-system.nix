{ config, lib, ... }:

{
  services.udisks2.enable = true;

  fileSystems = {
    "/mnt/data1" = {
      device = "/dev/disk/by-uuid/c424be95-313a-4251-b702-587ff795c7f9";
      fsType = "ext4";
      options = [ "nofail" "x-systemd.automatic" ];
    };

    "/home/david/Documents" = {
      device = "/mnt/data1/Documents";
      options = [ "bind" ];
    };

    "/home/david/Downloads" = {
      device = "/mnt/data1/Downloads";
      options = [ "bind" ];
    };

    "/home/david/Pictures" = {
      device = "/mnt/data1/Pictures";
      options = [ "bind" ];
    };

    "/home/david/Music" = {
      device = "/mnt/data1/Music";
      options = [ "bind" ];
    };

    "/home/david/Videos" = {
      device = "/mnt/data1/Videos";
      options = [ "bind" ];
    };

    "/mnt/data2" = {
      device = "/dev/disk/by-uuid/085a2044-a0fe-4b57-9beb-2fa4f747e416";
      fsType = "ext4";
      options = [ "nofail" "x-systemd.automatic" ];
    };
  };
}