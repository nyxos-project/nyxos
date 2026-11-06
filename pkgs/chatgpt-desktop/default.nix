# OpenAI's ChatGPT desktop app (with Codex), from OpenAI's own Debian repository, the
# source Omarchy uses too; nixpkgs' `chatgpt` is the macOS app. It bundles Chromium, Node
# modules and Codex's own binaries, so it runs unchanged in an FHS environment instead of
# being patched file by file.
{
  lib,
  stdenvNoCC,
  fetchurl,
  dpkg,
  buildFHSEnv,
  writeShellScript,
}:
let
  version = "26.1103.31037";
  unwrapped = stdenvNoCC.mkDerivation {
    pname = "chatgpt-desktop-unwrapped";
    inherit version;
    src = fetchurl {
      url = "https://persistent.oaistatic.com/codex-app-prod/linux/deb/pool/main/c/chatgpt/chatgpt_${version}_amd64.deb";
      sha256 = "32fed80ad3f8caf666e5860022361e9709d64aa318cfb19f548e8b458d4f6793";
    };
    nativeBuildInputs = [ dpkg ];
    unpackPhase = "dpkg-deb -x $src .";
    dontConfigure = true;
    dontBuild = true;
    dontFixup = true;
    installPhase = ''
      runHook preInstall
      mkdir -p $out
      cp -a usr/lib $out/lib
      install -Dm644 usr/share/pixmaps/chatgpt.png $out/share/icons/hicolor/512x512/apps/chatgpt.png
      runHook postInstall
    '';
  };

  # Chromium's own Wayland detection falls back to XWayland often enough to blur the
  # window on scaled displays, so ask for Wayland unless a platform is given.
  launch = writeShellScript "chatgpt-desktop" ''
    flags=()
    if [[ -n ''${WAYLAND_DISPLAY:-} ]]; then
      flags=(--ozone-platform=wayland)
      for a in "$@"; do
        case $a in --ozone-platform=* | --ozone-platform-hint=*) flags=() ;; esac
      done
    fi
    exec ${unwrapped}/lib/chatgpt/ChatGPT "''${flags[@]}" "$@"
  '';
in
buildFHSEnv {
  pname = "chatgpt-desktop";
  inherit version;

  targetPkgs =
    pkgs: with pkgs; [
      alsa-lib
      at-spi2-atk
      at-spi2-core
      cairo
      cups
      dbus
      expat
      gdk-pixbuf
      glib
      gtk3
      libdrm
      libgbm
      libGL
      libnotify
      libpulseaudio
      libsecret
      libusb1
      libx11
      libxcb
      libxcomposite
      libxdamage
      libxext
      libxfixes
      libxkbcommon
      libxrandr
      libxshmfence
      nspr
      nss
      openssl
      pango
      systemd
      tpm2-tss
      vulkan-loader
      wayland
      xdg-utils
      xz
      zlib
      stdenv.cc.cc.lib
    ];

  runScript = launch;

  extraInstallCommands = ''
    mkdir -p $out/share/applications
    cp -r ${unwrapped}/share/icons $out/share/icons
    cat > $out/share/applications/chatgpt-desktop.desktop <<EOF
    [Desktop Entry]
    Name=ChatGPT
    Comment=ChatGPT and Codex by OpenAI
    GenericName=AI assistant
    Exec=chatgpt-desktop %U
    Icon=chatgpt
    Type=Application
    StartupNotify=true
    StartupWMClass=ChatGPT
    Categories=Utility;Development;
    MimeType=x-scheme-handler/codex;
    EOF
  '';

  meta = {
    description = "OpenAI's ChatGPT desktop app, with Codex";
    homepage = "https://chatgpt.com/codex/";
    license = lib.licenses.unfree;
    sourceProvenance = [ lib.sourceTypes.binaryNativeCode ];
    platforms = [ "x86_64-linux" ];
    mainProgram = "chatgpt-desktop";
  };
}
