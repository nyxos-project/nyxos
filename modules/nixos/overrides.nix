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
  mounts = o.mounts or { };
  hw = o.hardware or { };
  networkTypes = [
    "cifs"
    "nfs"
    "nfs4"
  ];
  # Unfree packages the administrator accepted, by package name.
  unfree = map (attr: lib.last (lib.splitString "." attr)) (o.unfree or [ ]);
  theme = name: lib.mkIf (themes ? ${name}) (over themes.${name});
  # The logo file's kind, by its extension (`svg` or `png`).
  logoKind =
    if config.nyxos.logo == null then
      null
    else
      lib.last (lib.splitString "." (baseNameOf config.nyxos.logo));
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
  options.nyxos.logo = lib.mkOption {
    type = lib.types.nullOr lib.types.path;
    default = null;
    description = ''
      The system logo, an SVG or PNG file, in place of the Nyx mark: /etc/nyx/logo.svg or
      .png (every Nyx app and the shell), the sign-in screen and the boot splash. An
      SVG's `currentColor` parts take each theme's logo colour; a PNG is shown as it is.
      Settings sets it under Boot & Sign-in.
    '';
  };

  options.nyxos.theme = {
    system = lib.mkOption {
      type = lib.types.strMatching "[A-Za-z0-9-]+";
      default = "catppuccin-mocha";
      description = ''
        The system's Nyx theme: every user's default desktop and lock-screen theme
        (Theme Engine 2.0's default, built into every Nyx app), and the boot and login
        screens' unless those are set on their own.
      '';
    };
    boot = themeOption "boot screen's";
    login = themeOption "login screen's";
  };

  options.nyxos.signinStyle = lib.mkOption {
    type = lib.types.enum [
      "circular"
      "cyberpunk"
      "minimal"
      "edge"
    ];
    default = "circular";
    description = ''
      The sign-in animation for a fingerprint, a face or a security key: the login
      screen's, and every user's lock screen's until they choose their own.
    '';
  };

  # Every user's starting idle times; each user's own win (Settings' Lock Screen).
  options.nyxos.idle =
    lib.mapAttrs
      (
        _: d:
        lib.mkOption {
          type = lib.types.ints.unsigned;
          default = d.default;
          description = "Seconds idle before ${d.what}; 0 is never.";
        }
      )
      {
        lock = {
          default = 600;
          what = "the screen locks";
        };
        screenOff = {
          default = 660;
          what = "the screen turns off";
        };
        suspend = {
          default = 0;
          what = "the computer sleeps";
        };
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

    nyxos.unfree = unfree;

    # What the System Manager detected, and the driver choices made for it.
    nyxos.hardware = lib.mkIf (hw != { }) {
      gpus = over (hw.gpus or [ ]);
      cpu = over (hw.cpu or null);
      battery = over (hw.battery or false);
      bluetooth = over (hw.bluetooth or false);
      virtualMachine = over (hw.virtualMachine or null);
      nvidia.proprietary = over (hw.nvidiaProprietary or false);
    };

    # Nyx apps turned on or off; a name nyx-packages doesn't have fails the build.
    nyx = lib.mapAttrs (_: on: { enable = over on; }) (o.nyxApps or { });

    users.groups = lib.mapAttrs (_: users: { members = users; }) (o.groups or { });

    # Accounts NyxOS made (their passwords are set apart, never in the configuration),
    # and full names for accounts declared elsewhere.
    # Drives and shares mounted at startup; a share's login is kept apart, root only.
    fileSystems = lib.mapAttrs' (
      id: m:
      lib.nameValuePair m.dir {
        device = if lib.elem m.fsType networkTypes then m.what else "/dev/disk/by-uuid/${m.what}";
        inherit (m) fsType;
        options =
          (m.options or [ ]) ++ lib.optional (m.login or false) "credentials=/etc/nyxos/secrets/mounts/${id}";
      }
    ) mounts;
    boot.supportedFilesystems = lib.genAttrs (lib.unique (
      map (m: if m.fsType == "nfs4" then "nfs" else m.fsType) (lib.attrValues mounts)
    )) (_: true);

    users.users = lib.mkMerge [
      (lib.mapAttrs (_: p: {
        isNormalUser = true;
        description = p.fullName;
        extraGroups = lib.optional (p.admin or false) "wheel";
      }) (o.people or { }))
      (lib.mapAttrs (_: name: { description = over name; }) (o.fullNames or { }))
    ];

    networking.firewall = {
      enable = lib.mkIf (firewall ? enabled) (over firewall.enabled);
      allowedTCPPorts = firewall.tcp or [ ];
      allowedUDPPorts = firewall.udp or [ ];
    };

    services.logind.settings.Login = lib.mapAttrs (_: over) (power.login or { });
    systemd.sleep.settings.Sleep.HibernateDelaySec = lib.mkIf (power ? hibernateDelay) (
      over power.hibernateDelay
    );

    nyxos.theme = {
      system = theme "system";
      boot = theme "boot";
      login = theme "login";
    };

    # The System Manager keeps the logo in system.json: an SVG's text, a PNG in base64.
    nyxos.logo = lib.mkIf (o ? logo) (
      over (
        if o.logo.format == "png" then
          pkgs.runCommand "nyx-logo.png" {
            data = o.logo.data;
            passAsFile = [ "data" ];
          } ''base64 -d "$dataPath" > $out''
        else
          pkgs.writeText "nyx-logo.svg" o.logo.data
      )
    );
    environment.etc."nyx/logo.svg" = lib.mkIf (logoKind == "svg") { source = config.nyxos.logo; };
    environment.etc."nyx/logo.png" = lib.mkIf (logoKind == "png") { source = config.nyxos.logo; };

    # Layer 1 for every user's settings; the overrides layer and the user's own win.
    environment.etc."nyxos/defaults/appearance.toml".text = ''
      theme = "${config.nyxos.theme.system}"
      lock-theme = "${config.nyxos.theme.system}"
      lock-style = "${config.nyxos.signinStyle}"
    '';
    environment.etc."nyxos/defaults/idle.toml".text = ''
      lock = ${toString config.nyxos.idle.lock}
      screen-off = ${toString config.nyxos.idle.screenOff}
      suspend = ${toString config.nyxos.idle.suspend}
    '';
    # The shell's and Hyprland's defaults, from the repository's defaults/ (the reference
    # desktop, docs/audit/desktop-defaults.md). Hyprland's is rendered into hyprland.lua
    # by modules/home/hyprland.nix; the copy here is what Settings shows a reset going
    # back to.
    environment.etc."nyxos/defaults/hyprland.toml".source = ../../defaults/hyprland.toml;
    environment.etc."nyxos/defaults/dock.toml".source = ../../defaults/dock.toml;
    environment.etc."nyxos/defaults/bar.toml".source = ../../defaults/bar.toml;
    environment.etc."nyxos/defaults/control-center.toml".source = ../../defaults/control-center.toml;
    environment.etc."nyxos/defaults/notifications.toml".source = ../../defaults/notifications.toml;
  };
}
