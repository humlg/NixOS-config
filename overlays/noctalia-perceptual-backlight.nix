# Noctalia with the backlight slider/OSD/IPC steps in perceived lightness (CIE L*)
# instead of linear raw/max — docs/maintenance.md #35.
# Takes flake inputs because Noctalia comes from its own flake, not nixpkgs.
inputs: final: prev:
{
  noctalia-patched =
    inputs.noctalia.packages.${final.stdenv.hostPlatform.system}.default.overrideAttrs (old: {
      patches = (old.patches or [ ]) ++ [ ../patches/noctalia-perceptual-backlight.patch ];
    });
}
