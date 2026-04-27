# Override davinci-resolve to v21.0b1 (Beta 1).
# nixos-unstable still ships 20.3.2; this overlay replaces it with the beta
# using a local copy of the nixpkgs package.nix (see davinci-resolve-package.nix).
#
# The upstream src fetch script uses a jq title-match that can't find
# "21 Beta 1" entries (titled "DaVinci Resolve 21 Beta 1", not "DaVinci Resolve 21.0b1"),
# so the local copy hardcodes the downloadId instead.
final: prev:
{
  davinci-resolve = final.callPackage ./davinci-resolve-package.nix { };
}
