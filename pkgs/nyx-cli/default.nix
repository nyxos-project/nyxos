# The `nyx` command on NyxOS.
{ writeShellApplication, jq }:
writeShellApplication {
  name = "nyx";
  runtimeInputs = [ jq ];
  text = builtins.readFile ./nyx.sh;
  meta.description = "Short commands for the Nix package manager on NyxOS";
}
