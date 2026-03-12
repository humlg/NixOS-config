# Override rawtherapee to use latest dev branch which fixes
# static initialization order fiasco crash on startup.
# See: https://github.com/RawTherapee/RawTherapee/pull/7451
#      https://github.com/RawTherapee/RawTherapee/pull/7491
#      https://bugs.gentoo.org/960309
# TODO: Remove this overlay once nixpkgs updates rawtherapee past 5.12.
final: prev:
let
  fmt_src = prev.fetchFromGitHub {
    owner = "fmtlib";
    repo = "fmt";
    rev = "e424e3f2e607da02742f73db84873b8084fc714c"; # 12.0.0
    hash = "sha256-AZDmIeU1HbadC+K0TIAGogvVnxt0oE9U6ocpawIgl6g=";
  };
in
{
  rawtherapee = prev.rawtherapee.overrideAttrs (old: {
    version = "5.12-unstable-2026-03-07";
    src = prev.fetchFromGitHub {
      owner = "RawTherapee";
      repo = "RawTherapee";
      rev = "0acfdd578a375d6e41a1ade7c8492e808ad2db55";
      hash = "sha256-WruerPWJDnvviWlFAD8z3ngG52DLlCwUe68Z93dDQEE=";
    };
    buildInputs = (old.buildInputs or []) ++ [ prev.fmt ];
    cmakeFlags = (old.cmakeFlags or []) ++ [
      "-DFETCHCONTENT_FULLY_DISCONNECTED=ON"
      "-DFETCHCONTENT_SOURCE_DIR_FMT=${fmt_src}"
    ];
  });
}
