let
  # David's personal SSH key — allows editing secrets from any machine with this key
  david = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIGRbAt9056fnf0+EQPpUId4rx43GOTX5wUI8mVKwjt41 david@saruman";

  # SSH host keys — used for automatic decryption at activation time
  saruman = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIKD2w9ZltrW/1bjsq30vLt/hnuiFCa8WNwriOe6XHaki root@saruman";
  sauron  = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIA870ubTokXb4ENXyp6zVALdaUnFyRqKeJOWD9/7xahN root@sauron";

  desktops = [ sauron saruman david ];
in
{
  "shell-env.age".publicKeys = desktops;
  "github-huml-yg.age".publicKeys = desktops;
}
