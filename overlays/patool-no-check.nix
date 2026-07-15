# patool's test suite fails in the nix build sandbox — it can't find the
# bzip2/xz/lzma helper binaries there, causing 12 unrelated test failures.
# patool is a transitive dep of bottles (via wine.nix).
# TODO: Remove this overlay once nixpkgs fixes patool's sandboxed test env.
final: prev:
{
  python3Packages = prev.python3Packages.overrideScope (pyFinal: pyPrev: {
    patool = pyPrev.patool.overridePythonAttrs (old: {
      doCheck = false;
    });
  });
}
