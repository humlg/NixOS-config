{ ... }:

{
  programs.fastfetch = {
    enable = true;
    settings = {
      "$schema" = "https://github.com/fastfetch-cli/fastfetch/raw/master/doc/json_schema.json";

      logo = {
        type = "auto";
        source = "auto";
        width = 1;
        height = 1;
        padding = {
          top = 0;
          left = 0;
          right = 3;
        };
        color = {};
      };

      display = {
        separator = "  ";
        color = {
          keys = "magenta";
          title = "red";
        };
        key = {
          width = 4;
          type = "icon";
        };
        bar = {
          width = 10;
          char = {
            elapsed = "■";
            total = "-";
          };
        };
        percent = {
          type = 9;
          color = {
            green = "green";
            yellow = "light_yellow";
            red = "light_red";
          };
        };
      };

      modules = [
        "os"
        "kernel"
        "uptime"
        "packages"
        "de"
        "wm"
        "cpu"
        "gpu"
        "memory"
        "swap"
        "disk"
        "localip"
        "break"
        "colors"
      ];
    };
  };
}
