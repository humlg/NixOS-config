{ ... }:

{
  nix.settings.experimental-features = [ "nix-command" "flakes" ];

  # Automatic store optimization + garbage collection
  nix.optimise.automatic = true;
  nix.gc = {
    automatic = true;
    dates = "weekly";
    options = "--delete-older-than 30d";
  };
}
