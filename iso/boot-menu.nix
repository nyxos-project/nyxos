# The live USB's boot menu, in Limine as on an installed NyxOS (modules/nixos/boot.nix):
# "Install NyxOS" over the lock screen's stacked NYX in the boot theme, three seconds,
# no other words. Troubleshooting stays one entry away: safe graphics, and a start
# that shows the kernel's and systemd's messages.
{
  config,
  lib,
  pkgs,
  inputs,
  ...
}:
let
  example = inputs.self.nixosConfigurations.example.config;
  bootTheme = example.nyxos.theme.boot;
  theme = import ../themes {
    inherit lib;
    inherit (inputs.nyx-packages.inputs) nyx-design;
  } bootTheme;
  c = theme.colors;
  s = theme.swatches;
  nyxPkgs = inputs.nyx-packages.packages.${pkgs.stdenv.hostPlatform.system};
  wallpaper =
    nyxPkgs.nyx-wallpapers.passthru.locks.${bootTheme}
      or nyxPkgs.nyx-wallpapers.passthru.locks.nyx-dark;
  init = "init=${config.system.build.toplevel}/init";
  params = config.boot.kernelParams;
  # What hides the start: without these the kernel and systemd say what they do.
  quiet = [
    "quiet"
    "splash"
    "rd.udev.log_level=3"
    "udev.log_priority=3"
    "rd.systemd.show_status=auto"
  ];
  loud = lib.filter (p: !(lib.elem p quiet) && !(lib.hasPrefix "loglevel=" p)) params;
  entry = cmdline: ''
    protocol: linux
    kernel_path: boot():/boot/bzImage
    module_path: boot():/boot/initrd
    cmdline: ${lib.concatStringsSep " " ([ init ] ++ cmdline)}
  '';
in
{
  nyxos.liveImage.contents = [
    {
      source = wallpaper;
      target = "boot/limine/wallpaper.png";
    }
  ];
  nyxos.liveImage.limineConfig = ''
    timeout: 3
    graphics: yes
    wallpaper: boot():/boot/limine/wallpaper.png
    wallpaper_style: stretched
    backdrop: ${c.backdrop}
    interface_branding:
    interface_help_hidden: yes
    interface_help_colour: ${c.dimText}
    interface_help_colour_bright: ${c.accent}
    term_font_scale: 2x2
    term_margin: 0
    term_margin_gradient: 0
    term_palette: ${
      lib.concatStringsSep ";" [
        c.backdrop
        s.red
        s.green
        s.amber
        s.blue
        s.violet
        s.teal
        c.dimText
      ]
    }
    term_foreground: ${c.text}
    # TT = ff: the text has no background of its own, so the wallpaper shows.
    term_background: ff${c.backdrop}

    /Install NyxOS
    ${entry params}
    /Troubleshooting
    //Install NyxOS with safe graphics
    ${entry (params ++ [ "nomodeset" ])}
    //Install NyxOS showing messages
    ${entry (loud ++ [ "plymouth.enable=0" ])}
  '';
}
