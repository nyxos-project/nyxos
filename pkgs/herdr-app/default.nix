# Herdr, the desktop app for terminals and coding agents (herdrdev/herdr-app), and the
# herdr-core service it runs them in (`herdr-core`, `hc`). Not the Herdr TUI, which NyxOS
# already ships; the two don't share sessions. Herdr's own releases; its icon isn't kept
# beside the binary, which is how the app tells it shouldn't update itself.
{
  lib,
  stdenv,
  fetchurl,
  autoPatchelfHook,
  makeWrapper,
  libxcb,
  libxkbcommon,
  vulkan-loader,
  wayland,
  libGL,
  fontconfig,
  freetype,
  libx11,
  libxcursor,
  libxi,
  alsa-lib,
  libpulseaudio,
  pin,
}:
let
  system = stdenv.hostPlatform.system;
  core = fetchurl { inherit (pin.srcs."core-${system}") url hash; };
  # The app opens these at run time.
  runtime = [
    vulkan-loader
    wayland
    libxkbcommon
    libGL
    fontconfig
    freetype
    libx11
    libxcb
    libxcursor
    libxi
    alsa-lib
    libpulseaudio
  ];
in
stdenv.mkDerivation {
  pname = "herdr-app";
  inherit (pin) version;

  src = fetchurl { inherit (pin.srcs.${system}) url hash; };

  nativeBuildInputs = [
    autoPatchelfHook
    makeWrapper
  ];
  buildInputs = [
    stdenv.cc.cc.lib
    libxcb
    libxkbcommon
  ];

  installPhase = ''
    runHook preInstall
    install -Dm755 herdr-app $out/lib/herdr-app/herdr-app
    install -Dm644 herdr-app.svg $out/share/icons/hicolor/scalable/apps/herdr-app.svg
    mkdir -p core && tar -xzf ${core} -C core
    install -Dm755 core/herdr-core $out/bin/herdr-core
    ln -s herdr-core $out/bin/hc
    makeWrapper $out/lib/herdr-app/herdr-app $out/bin/herdr-app \
      --prefix LD_LIBRARY_PATH : ${lib.makeLibraryPath runtime} \
      --prefix PATH : $out/bin
    mkdir -p $out/share/applications
    cat > $out/share/applications/herdr-app.desktop <<EOF
    [Desktop Entry]
    Name=Herdr
    Comment=Terminals and coding agents
    Exec=herdr-app %U
    Icon=herdr-app
    Type=Application
    Terminal=false
    StartupWMClass=herdr-app
    Categories=Development;
    EOF
    runHook postInstall
  '';

  meta = {
    description = "Herdr, the desktop app for terminals and coding agents";
    homepage = "https://herdr.dev";
    license = lib.licenses.asl20;
    sourceProvenance = [ lib.sourceTypes.binaryNativeCode ];
    platforms = [ "x86_64-linux" ];
    mainProgram = "herdr-app";
  };
}
