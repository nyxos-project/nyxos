# The system overrides layer: /etc/nyxos/overrides/system.json, written by the Nyx
# System Manager and taken by the flake as its `nyxos-overrides` input (the repository's
# empty overrides/ when it isn't passed). Its values win over the distribution's and the
# host's. Also the themes, and the distribution's defaults layer for every user's
# settings (/etc/nyxos/defaults).
{
  config,
  lib,
  pkgs,
  inputs,
  ...
}:
let
  file = "${inputs.nyxos-overrides}/system.json";
  o = if builtins.pathExists file then builtins.fromJSON (builtins.readFile file) else { };
  over = lib.mkOverride 90;
  set = name: lib.mkIf (o ? ${name}) (over o.${name});
  services = o.services or { };
  service = name: lib.mkIf (services ? ${name}) (over services.${name});
  themes = o.theme or { };
  firewall = o.firewall or { };
  power = o.power or { };
  # Unfree packages the administrator accepted, by package name.
  unfree = map (attr: lib.last (lib.splitString "." attr)) (o.unfree or [ ]);
  theme = name: lib.mkIf (themes ? ${name}) (over themes.${name});
  package =
    attr:
    let
      p = lib.attrByPath (lib.splitString "." attr) null pkgs;
    in
    if lib.isDerivation p then p else throw "nyxos-overrides: nixpkgs has no package ${attr}";
  themeOption =
    what:
    lib.mkOption {
      type = lib.types.strMatching "[A-Za-z0-9-]+";
      default = config.nyxos.theme.system;
      defaultText = lib.literalExpression "config.nyxos.theme.system";
      description = "The ${what} theme.";
    };
in
{
  options.nyxos.theme = {
    system = lib.mkOption {
      type = lib.types.strMatching "[A-Za-z0-9-]+";
      default = "nyx-dark";
      description = ''
        The system's Nyx theme: every user's default desktop and lock-screen theme, and
        the boot and login screens' unless those are set on their own.
      '';
    };
    boot = themeOption "boot screen's";
    login = themeOption "login screen's";
  };

  config = {
    networking.hostName = set "hostname";
    time.timeZone = set "timeZone";
    i18n.defaultLocale = set "locale";
    services.xserver.xkb.layout = set "keyboardLayout";
    console.useXkbConfig = lib.mkIf (o ? keyboardLayout) (over true);

    environment.systemPackages = map package (o.packages or [ ]);

    hardware.bluetooth.enable = service "bluetooth";
    services.printing.enable = service "printing";
    services.openssh.enable = service "ssh";
    services.flatpak.enable = service "flatpak";
    virtualisation.docker.enable = service "docker";
    services.tailscale.enable = service "tailscale";
    services.fwupd.enable = service "fwupd";
    services.avahi.enable = service "avahi";
    virtualisation.podman.enable = service "podman";
    virtualisation.incus.enable = service "incus";
    # Incus's firewall rules need nftables.
    networking.nftables.enable = lib.mkIf (services.incus or false) (over true);
    virtualisation.libvirtd.enable = service "libvirtd";
    services.ollama.enable = service "ollama";

    nixpkgs.config.allowUnfreePredicate = lib.mkIf (unfree != [ ]) (pkg: lib.elem (lib.getName pkg) unfree);

    # Nyx apps turned on or off; a name nyx-packages doesn't have fails the build.
    nyx = lib.mapAttrs (_: on: { enable = over on; }) (o.nyxApps or { });

    users.groups = lib.mapAttrs (_: users: { members = users; }) (o.groups or { });

    networking.firewall = {
      enable = lib.mkIf (firewall ? enabled) (over firewall.enabled);
      allowedTCPPorts = firewall.tcp or [ ];
      allowedUDPPorts = firewall.udp or [ ];
    };

    services.logind.settings.Login = lib.mapAttrs (_: over) (power.login or { });
    systemd.sleep.settings.Sleep.HibernateDelaySec = lib.mkIf (power ? hibernateDelay) (over power.hibernateDelay);

    nyxos.theme = {
      system = theme "system";
      boot = theme "boot";
      login = theme "login";
    };

    # Layer 1 for every user's settings; the overrides layer and the user's own win.
    environment.etc."nyxos/defaults/appearance.toml".text = ''
      theme = "${config.nyxos.theme.system}"
      lock-theme = "${config.nyxos.theme.system}"
    '';
  };
}
