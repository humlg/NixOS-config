{ config, pkgs, ... }:

{
  # Graphics and photography applications bundle
  environment.systemPackages = with pkgs; [
    gimp          # GNU Image Manipulation Program
    inkscape      # Vector graphics editor
    darktable     # Photography workflow and RAW developer
    rawtherapee
    gphoto2
  ];
}
