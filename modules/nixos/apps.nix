# Base tier: Nyx components every NyxOS install ships. Options come from nyx-packages.
{ lib, ... }:
{
  nyx = {
    icons.enable = lib.mkDefault true;
    accounts.enable = lib.mkDefault true;
    notepad.enable = lib.mkDefault true;
    calculator.enable = lib.mkDefault true;
    archive.enable = lib.mkDefault true;
  };
}
