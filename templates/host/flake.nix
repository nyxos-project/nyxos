{
  description = "This computer's NyxOS";

  inputs = {
    # The release channel: stable, or testing for what's next.
    nyxos.url = "github:nyxos-project/nyxos/stable";

    # The system settings Settings, Welcome and the Store change (the Nyx System Manager
    # and NyxOS Recovery pass it to each rebuild).
    nyxos-overrides = {
      url = "path:/etc/nyxos/overrides";
      flake = false;
    };
    nyxos.inputs.nyxos-overrides.follows = "nyxos-overrides";
  };

  outputs =
    {
      self,
      nyxos,
      nyxos-overrides,
      ...
    }:
    {
      nixosConfigurations.HOSTNAME = nyxos.lib.mkSystem {
        inherit self;
        overrides = nyxos-overrides;
        modules = [
          ./hardware-configuration.nix
          ./host.nix
        ];
      };
    };
}
