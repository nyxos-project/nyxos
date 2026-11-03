# The `nyx` command on NyxOS.
{ writeShellApplication }:
writeShellApplication {
  name = "nyx";
  text = builtins.readFile ./nyx.sh;
  meta.description = "Short commands for the Nix package manager on NyxOS";
}
