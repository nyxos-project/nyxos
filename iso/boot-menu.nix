# The live USB's boot menu, plain like an installed NyxOS's (modules/nixos/boot.nix): the
# boot theme's backdrop and text, "NyxOS" over the entries in Inter, three seconds, and
# none of the NixOS artwork. GRUB on UEFI, syslinux on BIOS; the options submenu and
# text mode ('t') stay for when something's wrong.
{
  lib,
  pkgs,
  inputs,
  ...
}:
let
  example = inputs.self.nixosConfigurations.example.config;
  c =
    (import ../themes {
      inherit lib;
      inherit (inputs.nyx-packages.inputs) nyx-design;
    } example.nyxos.theme.boot).colors;
  inter = "${pkgs.inter}/share/fonts/truetype/InterVariable.ttf";

  grubTheme =
    pkgs.runCommand "nyxos-grub-theme"
      {
        nativeBuildInputs = [ pkgs.buildPackages.grub2 ];
      }
      ''
        mkdir -p $out
        for size in 16 20 28; do
          grub-mkfont -n Inter -s $size -o $out/inter-$size.pf2 ${inter}
        done
        cat > $out/theme.txt <<'EOF'
        title-text: ""
        desktop-color: "#${c.backdrop}"
        terminal-font: "Inter Regular 16"

        + label {
          left = 0
          top = 22%
          width = 100%
          height = 40
          align = "center"
          text = "NyxOS"
          font = "Inter Regular 28"
          color = "#${c.text}"
        }

        + boot_menu {
          left = 36%
          top = 34%
          width = 28%
          height = 44%
          item_font = "Inter Regular 20"
          item_color = "#${c.dimText}"
          selected_item_font = "Inter Regular 20"
          selected_item_color = "#${c.accent}"
          item_height = 36
          item_padding = 0
          item_spacing = 6
          icon_width = 0
          icon_height = 0
          item_icon_space = 0
          scrollbar = false
        }

        + label {
          id = "__timeout__"
          left = 0
          top = 84%
          width = 100%
          align = "center"
          text = "Starting in %d s"
          font = "Inter Regular 16"
          color = "#${c.dimText}"
        }
        EOF
      '';

  # syslinux draws its menu over a picture: a plain one in the backdrop.
  biosBackdrop = pkgs.runCommand "nyxos-bios-backdrop.png" {
    nativeBuildInputs = [ pkgs.buildPackages.imagemagick ];
  } "magick -size 800x600 xc:#${c.backdrop} PNG24:$out";
in
{
  isoImage = {
    grubTheme = grubTheme;
    splashImage = biosBackdrop;
    efiSplashImage = biosBackdrop;
    prependToMenuLabel = "Install ";
    appendToMenuLabel = "";
    syslinuxTheme = ''
      MENU TITLE NyxOS
      MENU RESOLUTION 800 600
      MENU CLEAR
      MENU ROWS 6
      MENU CMDLINEROW -4
      MENU TIMEOUTROW -3
      MENU TABMSGROW  -2
      MENU HELPMSGROW -1
      MENU HELPMSGENDROW -1
      MENU MARGIN 0

      #                                FG:AARRGGBB  BG:AARRGGBB   shadow
      MENU COLOR BORDER       30;44      #00000000    #00000000   none
      MENU COLOR SCREEN       37;40      #FF${c.text}    #00000000   none
      MENU COLOR TABMSG       31;40      #FF${c.dimText}    #00000000   none
      MENU COLOR TIMEOUT      1;37;40    #FF${c.dimText}    #00000000   none
      MENU COLOR TIMEOUT_MSG  37;40      #FF${c.dimText}    #00000000   none
      MENU COLOR CMDMARK      1;36;40    #FF${c.accent}    #00000000   none
      MENU COLOR CMDLINE      37;40      #FF${c.text}    #00000000   none
      MENU COLOR TITLE        1;36;44    #FF${c.text}    #00000000   none
      MENU COLOR UNSEL        37;44      #FF${c.dimText}    #00000000   none
      MENU COLOR SEL          7;37;40    #FF${c.accent}    #FF${c.card}   std
    '';
  };
  boot.loader.timeout = lib.mkForce 3;
}
