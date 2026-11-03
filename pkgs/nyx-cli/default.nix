# The `nyx` command on NyxOS. `packaged` lists the apps nyx-packages builds.
{
  lib,
  writeShellApplication,
  packaged,
}:
writeShellApplication {
  name = "nyx";
  text = lib.replaceStrings [ "@packaged@" ] [ (lib.concatStringsSep " " packaged) ] (
    builtins.readFile ./nyx.sh
  );
  meta.description = "The Nyx command line on NyxOS";
}
