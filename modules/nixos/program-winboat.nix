{pkgs,config,...}:{
  environment.systemPackages =[
    pkgs.winboat
  ];
  
  #virtualisation.docker.daemon.enable = true;  # orphaned module, Docker wiring incomplete — docs/maintenance.md #13

  users.extraGroups.docker.members = [ "david" ];
}
