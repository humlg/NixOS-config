{ ... }:

{
  imports = [
    ../programs/fastfetch.nix
    ./thunar.nix
  ];

  home.username = "david";
  home.homeDirectory = "/home/david";
  home.stateVersion = "25.11";
  nixpkgs.config.allowUnfree = true;
  programs.home-manager.enable = true;
  home.sessionVariables.EDITOR = "vim";
}
