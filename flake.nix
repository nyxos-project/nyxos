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
      packages.${system} = {
        nyx-cli = pkgs.callPackage ./pkgs/nyx-cli { };
        iso = self.nixosConfigurations.iso.config.system.build.isoImage;
      };

      nixosModules = {
        nyxos = ./modules/nixos;
        home = ./modules/home;
      };

      # An installed machine: NyxOS's modules and its own (hardware-configuration.nix,
      # host.nix), from its flake in /etc/nyxos/flake (templates/host). `self` is that
      # flake (each generation keeps its flake.lock, as inputs.machine); `overrides`, the
      # settings layer.
      lib.mkSystem =
        {
          self ? inputs.self,
          overrides ? inputs.nyxos-overrides,
          modules,
        }:
        nixpkgs.lib.nixosSystem {
          specialArgs.inputs = inputs // {
            machine = self;
            nyxos-overrides = overrides;
          };
          modules = [ ./modules/nixos ] ++ modules;
        };

      templates.host = {
        path = ./templates/host;
        description = "An installed NyxOS machine's flake (the installer fills it in)";
      };

      # An installed machine, as the installer writes one (the live USB carries it).
      nixosConfigurations.example = self.lib.mkSystem {
        modules = [
          ./templates/host/example-hardware.nix
          ./templates/host/example-host.nix
        ];
      };

      # The live USB: nix build .#iso
      nixosConfigurations.iso = nixpkgs.lib.nixosSystem {
        specialArgs = { inherit inputs; };
        modules = [ ./iso ];
      };

      nixosConfigurations.incus-dev = nixpkgs.lib.nixosSystem {
        specialArgs = { inherit inputs; };
        modules = [ ./hosts/incus-dev ];
      };

      checks.${system} = {
        incus-dev = self.nixosConfigurations.incus-dev.config.system.build.toplevel;
        catalog = import ./checks/catalog.nix {
          inherit pkgs;
          inherit (nixpkgs) lib;
          catalog = inputs.nyx-packages.lib.catalog;
          nixos = self.nixosConfigurations.incus-dev;
        };
        inherit (self.packages.${system}) nyx-cli;
        # An installed machine, as the installer writes one.
        installed = self.nixosConfigurations.example.config.system.build.toplevel;
      };

      formatter.${system} = pkgs.nixfmt;
    };
}
