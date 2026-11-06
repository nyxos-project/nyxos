{ pkgs, ... }:
{
  # Packages the catalog offers that nixpkgs doesn't have, under the names it uses.
  nixpkgs.overlays = [
    (final: _: {
      antigravity-cli = final.callPackage ../../pkgs/antigravity-cli { };
      antigravity-ide = final.callPackage ../../pkgs/antigravity-ide { };
      antigravity-app = final.callPackage ../../pkgs/antigravity-app { };
      chatgpt-desktop = final.callPackage ../../pkgs/chatgpt-desktop { };
      herdr-app = final.callPackage ../../pkgs/herdr-app { };
    })
  ];

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
