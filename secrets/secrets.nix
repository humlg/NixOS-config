let
  # David's personal SSH key — allows editing secrets from any machine with this key
  david = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIGRbAt9056fnf0+EQPpUId4rx43GOTX5wUI8mVKwjt41 david@saruman";

  # SSH host keys — used for automatic decryption at activation time
  saruman = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIKD2w9ZltrW/1bjsq30vLt/hnuiFCa8WNwriOe6XHaki root@saruman";
  # sauron = "ssh-ed25519 AAAA... root@sauron";  # TODO: fill in when sauron is reachable

  # Secrets available on all desktops
  # Update this list when sauron's host key is added
  desktops = [ saruman david ];
  # desktops = [ sauron saruman david ];  # use this once sauron's key is added
in
{
  "shell-env.age".publicKeys = desktops;

  # Add one entry per SSH private key you want to manage:
  # "ssh_myserver.age".publicKeys = desktops;
}
