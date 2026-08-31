final: prev:

# nixpkgs pins hyprlandPlugins.hypr-dynamic-cursors to commit f5ba36c7
# (2026-07-21), which only supports Hyprland up to v0.56.1. Our Hyprland is
# v0.56.2, and that plugin build fails to hook the compositor's cursor
# rendering path at init ("[dynamic-cursors] could not hook, hooking failed"),
# so Hyprland shows a "failed to load plugin" notification and the shake
# effect never activates.
#
# Upstream's hyprpm.toml maps Hyprland v0.56.2
# (efb50993780079460b0cbed1363e2166a2de1d9f) to plugin commit
# 5a224284872208b5324759d535d65061043725de — bump src to that.
#
# See maintenance.md #22. Drop this overlay once nixpkgs' plugin catches up to
# a commit that supports our Hyprland.

{
  hyprlandPlugins = prev.hyprlandPlugins // {
    hypr-dynamic-cursors = prev.hyprlandPlugins.hypr-dynamic-cursors.overrideAttrs (old: {
      version = "0-unstable-2026-08-06";
      src = final.fetchFromGitHub {
        owner = "VirtCode";
        repo = "hypr-dynamic-cursors";
        rev = "5a224284872208b5324759d535d65061043725de";
        hash = "sha256-BQjuQplkQFA30/7evDxmEAvr2ArIG09JffEBQhuzo80=";
      };
    });
  };
}
