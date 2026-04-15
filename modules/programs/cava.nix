{ config, lib, pkgs, ... }:

{
  # Symlink the wallust-generated cava config
  home.file.".config/cava/config".source =
    config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/.cache/wallust/colors-cava";
}
