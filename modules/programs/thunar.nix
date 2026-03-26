{ config, lib, pkgs, ... }:

{
  programs.thunar = {
    enable = true;
    plugins = with pkgs.xfce; [
      thunar-volman
      thunar-archive-plugin
    ];
  };

  services.gvfs.enable = true;

  # Thumbnail generation
  services.tumbler.enable = true;
  environment.systemPackages = with pkgs; [
    xfce.tumbler      # thumbnail backend
    ffmpegthumbnailer  # video
    libgsf             # ODF
    poppler            # PDF
    freetype           # fonts
  ];
}
