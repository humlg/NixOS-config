final: prev:

# nixpkgs pins hyprlandPlugins.hypr-dynamic-cursors to commit f5ba36c7
# (2026-07-21), which predates our Hyprland (v0.57.0) and fails to compile
# against its render-pass API. Pin src to an upstream commit that supports it.
#
# See docs/maintenance.md #22. Drop this overlay once nixpkgs' plugin catches up to
# a commit that supports our Hyprland.

{
  hyprlandPlugins = prev.hyprlandPlugins // {
    hypr-dynamic-cursors = prev.hyprlandPlugins.hypr-dynamic-cursors.overrideAttrs (old: {
      version = "0-unstable-2026-10-05";
      src = final.fetchFromGitHub {
        owner = "VirtCode";
        repo = "hypr-dynamic-cursors";
        rev = "2a8d0b735328d874a78ca93b2f201649f712a74a";
        hash = "sha256-PSt/SRtemvsoGYNFJ7YLiXGxT8EJe3AhmGwt5Vt79aA=";
      };
    });
  };
}
