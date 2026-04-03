{ config, lib, pkgs, ... }:

{
  # Seed the custom pywal template for cava
  home.file.".config/wal/templates/colors-cava".text = ''
    [color]
    gradient = 0
    gradient_count = 0
    foreground = '{foreground}'
    color1 = '{color1}'
    color2 = '{color2}'
    color3 = '{color3}'
    color4 = '{color4}'
    color5 = '{color5}'
    color6 = '{color6}'
    color7 = '{color7}'
  '';

  # Symlink the generated output
  home.file.".config/cava/config".source =
    config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/.cache/wal/colors-cava";
}
