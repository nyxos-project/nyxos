{ pkgs, ... }:
{
  environment.systemPackages = with pkgs; [
    bat
    btop
    curl
    eza
    fd
    file
    git
    helix
    jq
    pciutils
    ripgrep
    rsync
    unzip
    usbutils
    wget

    grim
    wl-clipboard
  ];
}
