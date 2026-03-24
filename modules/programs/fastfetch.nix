{ config, lib, pkgs, ... }:

{
  environment.systemPackages = [ pkgs.fastfetch ];

  # Place a system-wide config file for fastfetch
  environment.etc."fastfetch/config.jsonc".text = builtins.toJSON {
    "$schema" = "https://github.com/fastfetch-cli/fastfetch/raw/dev/doc/json_schema.json";
    logo = {
      type = "small";
    };
    modules = [
      "title"
      "separator"
      "os"
      "host"
      "kernel"
      "uptime"
      "packages"
      "shell"
      "display"
      "wm"
      "theme"
      "icons"
      "cursor"
      "terminal"
      "cpu"
      "gpu"
      "memory"
      "swap"
      "disk"
      "localip"
      "battery"
      "locale"
      "break"
      "colors"
    ];
  };
}
