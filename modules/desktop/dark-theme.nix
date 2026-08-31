{ config, lib, pkgs, ... }:

let
  gtkThemeName = "WhiteSur-Dark-solid-purple";

  # Orchis-Purple-Dark-Compact was removed from nixpkgs 2026-07-22 along with
  # gtk-engine-murrine (unmaintained, GTK2-only). WhiteSur is a pure-CSS
  # GTK3/4 theme with no murrine dependency, so it won't rot the same way.
  gtkTheme = pkgs.whitesur-gtk-theme.override {
    colorVariants = [ "dark" ];
    themeVariants = [ "purple" ];
    opacityVariants = [ "solid" ];
  };

  papirus-purple = pkgs.runCommand "papirus-icon-theme-purple" {
    nativeBuildInputs = [ pkgs.gtk3 ];
  } ''
    mkdir -p $out/share/icons
    cp -r --no-preserve=mode ${pkgs.papirus-icon-theme}/share/icons/* $out/share/icons/
    export HOME=$(mktemp -d)
    export USER_HOME=$HOME
    ${pkgs.papirus-folders}/bin/papirus-folders -o -t $out/share/icons/Papirus-Dark -C violet
  '';
in
{
  home.packages = with pkgs; [
    gtkTheme
    papirus-purple

    qt6Packages.qt6ct
    libsForQt5.qt5ct
    qt6Packages.qtstyleplugin-kvantum
    libsForQt5.qtstyleplugin-kvantum
  ];

  gtk = {
    enable = true;

    theme = {
      name = gtkThemeName;
      package = gtkTheme;
    };

    iconTheme = {
      name = "Papirus-Dark";
      package = papirus-purple;
    };

    gtk3.extraConfig = {
      gtk-application-prefer-dark-theme = 1;
    };

    # Deliberately gtk4.theme = null. WhiteSur ships no real GTK4 stylesheet —
    # its share/themes/*/gtk-4.0/gtk.css is a symlink to the GTK3 resource
    # stub (`@import url("resource:///org/gnome/theme/gtk.css")`), which only
    # resolves when GTK loads the theme by name via its gresource, never when
    # home-manager @imports that file from ~/.config/gtk-4.0/gtk.css. The
    # failed import left every libadwaita app unstyled — transparent window,
    # white text, no rendered UI (diagnosed 2026-08-31). GTK4/libadwaita apps
    # now fall back to their bundled Adwaita stylesheet, dark via the
    # color-scheme dconf setting below; under Noctalia, noctalia.nix layers
    # the wallpaper palette on top via ~/.config/gtk-4.0/noctalia.css.
    #
    # Explicit null, not just an omitted attr: home.stateVersion is "25.11"
    # (< "26.05"), so home-manager's legacy default for gtk4.theme is still
    # config.gtk.theme — the option has to be set to null to actually drop it.
    gtk4 = {
      theme = null;
      extraConfig = {
        gtk-application-prefer-dark-theme = 1;
      };
    };
  };

  dconf.settings = {
    "org/gnome/desktop/interface" = {
      color-scheme = "prefer-dark";
      gtk-theme = gtkThemeName;
      icon-theme = "Papirus-Dark";
    };
  };

  qt = {
    enable = true;
    platformTheme.name = "qt6ct";
    style.name = "kvantum";
  };

  home.sessionVariables = {
    # No GTK_THEME here. It force-loads the named theme for *every* GTK
    # toolkit version, bypassing settings.ini, and for GTK4 that means
    # pulling in WhiteSur's gtk-4.0/gtk.css — the GTK3 resource stub
    # (`@import url("resource:///org/gnome/theme/gtk.css")`) that only
    # resolves when GTK loads the theme's gresource itself, which doesn't
    # happen for an env-var override. The failed import leaves libadwaita
    # apps unstyled (transparent window, white text). GTK3 apps still get
    # WhiteSur via ~/.config/gtk-3.0/settings.ini; GTK4/libadwaita apps use
    # Adwaita (dark via the color-scheme dconf key) plus, under Noctalia, the
    # palette from ~/.config/gtk-4.0/noctalia.css.
    QT_QPA_PLATFORMTHEME_QT5 = "qt5ct";
    QT_STYLE_OVERRIDE = "kvantum";
  };
}
