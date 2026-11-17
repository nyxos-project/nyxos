# Installed, not started: Foot opens a plain shell and Herdr runs on demand.
{ pkgs, ... }:
{
  home.packages = [ pkgs.herdr ];
}
