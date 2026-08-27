# dwarfs vendors a frozen folly + fbthrift snapshot (via git submodule) that
# hasn't kept pace with two things this nixpkgs update (2026-08-27) bumped:
#
# 1. GCC 15 (now nixos-unstable's default compiler) tightened libstdc++
#    header hygiene: <cstring>'s std::memcpy/std::memset are no longer pulled
#    in transitively by other standard headers. The vendored
#    folly/lang/Exception.h relies on that old transitive include without
#    including <cstring> itself, so dwarfs_folly_lite fails to build
#    (error: 'memcpy' is not a member of 'std').
#
# 2. fmt bumped from 12.1.0 to 12.2.0 (nixpkgs' default `fmt`/`fmt_12`), which
#    broke API the vendored fbthrift whisker compiler
#    (thrift/compiler/whisker/{token,print_ast}.cc) relies on ('format' is
#    not a member of 'fmt', plus an fmt::join deprecation note). fmt 12.1.0
#    still built fine, but nixpkgs doesn't expose that exact point release as
#    a named package — fmt_11 (11.2.0) does, and is old enough to predate
#    whatever broke, so dwarfs is built against that instead of the default.
#
# gearlever (AppImage manager) depends on dwarfs for AppImage extraction,
# which is what pulled this in via `nix flake update`.
#
# TODO: Remove once nixpkgs bumps dwarfs to a release whose vendored
# folly/fbthrift no longer choke on GCC 15 / fmt 12.2.0.
final: prev:
{
  dwarfs = (prev.dwarfs.override { fmt = prev.fmt_11; }).overrideAttrs (old: {
    postPatch = (old.postPatch or "") + ''
      sed -i '1i #include <cstring>' folly/folly/lang/Exception.h
    '';
  });
}
