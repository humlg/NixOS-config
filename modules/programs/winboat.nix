{pkgs,config,...}:{
  environment.systemPackages =[
    pkgs.winboat
  ];
  
  virtualisation.docker.daemon.enable = true;

  users.extraGroups.docker.members = [ "david" ];
}
