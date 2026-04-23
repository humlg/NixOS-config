{ ... }:

{
  xdg.mimeApps = {
    enable = true;
    defaultApplications = {
      # Images — Gwenview
      "image/png" = "org.kde.gwenview.desktop";
      "image/jpeg" = "org.kde.gwenview.desktop";
      "image/gif" = "org.kde.gwenview.desktop";
      "image/webp" = "org.kde.gwenview.desktop";
      "image/bmp" = "org.kde.gwenview.desktop";
      "image/svg+xml" = "org.kde.gwenview.desktop";
      "image/tiff" = "org.kde.gwenview.desktop";

      # Web browser — LibreWolf
      "x-scheme-handler/http" = "librewolf.desktop";
      "x-scheme-handler/https" = "librewolf.desktop";
      "x-scheme-handler/about" = "librewolf.desktop";
      "x-scheme-handler/unknown" = "librewolf.desktop";
      "text/html" = "librewolf.desktop";
      "application/xhtml+xml" = "librewolf.desktop";

      # Teams meetings
      "x-scheme-handler/msteams" = "teams-for-linux.desktop";
    };
  };
}
