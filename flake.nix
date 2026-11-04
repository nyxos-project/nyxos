{
  description = "NyxOS: a NixOS distribution built around the Nyx desktop";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-26.05";

    home-manager = {
      url = "github:nix-community/home-manager/release-26.05";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Herdr pins its own nixpkgs and Rust toolchain; don't make it follow ours.
    herdr.url = "github:herdrdev/herdr/v0.9.5";

    nyx-packages = {
      url = "github:nyxos-project/nyx-packages";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # The system overrides layer (/etc/nyxos/overrides on a system, passed by the Nyx
    # System Manager); this folder is empty.
    nyxos-overrides = {
      url = "path:./overrides";
      flake = false;
    };
  };

  outputs =
    {
      self,
      nixpkgs,
      ...
    }@inputs:
    let
      system = "x86_64-linux";
      pkgs = nixpkgs.legacyPackages.${system};
    in
    {
      packages.${system}.nyx-cli = pkgs.callPackage ./pkgs/nyx-cli { };

      nixosModules = {
        nyxos = ./modules/nixos;
        home = ./modules/home;
      };

      nixosConfigurations.incus-dev = nixpkgs.lib.nixosSystem {
        specialArgs = { inherit inputs; };
        modules = [ ./hosts/incus-dev ];
      };

      checks.${system} = {
        incus-dev = self.nixosConfigurations.incus-dev.config.system.build.toplevel;
        inherit (self.packages.${system}) nyx-cli;
      };

      formatter.${system} = pkgs.nixfmt;
    };
}
