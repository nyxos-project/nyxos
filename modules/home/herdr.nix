# Installed, not started: Foot opens a plain shell and Herdr runs on demand.
{ pkgs, inputs, ... }:
{
  home.packages = [ inputs.herdr.packages.${pkgs.stdenv.hostPlatform.system}.herdr ];
}
