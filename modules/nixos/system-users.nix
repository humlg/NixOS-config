{ pkgs, ... }:

{
  users.users.david = {
    isNormalUser = true;
    extraGroups = [ "networkmanager" "wheel" "video" "render" ];
    shell = pkgs.zsh;
  };
  users.users.root.shell = pkgs.zsh;
}
