# Google Antigravity (2.0), the desktop app for running agents: not the IDE and not the
# CLI. Google's own AppImage, run in the FHS environment appimageTools makes; it runs as
# `antigravity-app` so it never shadows the IDE's `antigravity`.
{
  lib,
  appimageTools,
  fetchurl,
}:
let
  pname = "antigravity-app";
  version = "2.29.0";
  src = fetchurl {
    url = "https://storage.googleapis.com/antigravity-public/antigravity-hub/2.29.0-5723181030440960/linux-x64/Antigravity.AppImage";
    hash = "sha512-D8NY3sxLGAfFgl8Y2Rk1IarFXFlcD/A3omEcAM7hTUOtAAvLKE9c9QxaVSQvxg65w3MPUr8Uhy0dXsHJcUSYyQ==";
  };
  contents = appimageTools.extractType2 { inherit pname version src; };
in
appimageTools.wrapType2 {
  inherit pname version src;

  extraInstallCommands = ''
    install -Dm644 ${contents}/antigravity.png $out/share/icons/hicolor/512x512/apps/antigravity-app.png
    install -Dm644 ${contents}/antigravity.desktop $out/share/applications/antigravity-app.desktop
    substituteInPlace $out/share/applications/antigravity-app.desktop \
      --replace-fail 'Exec=AppRun --no-sandbox %U' 'Exec=antigravity-app %U' \
      --replace-fail 'Icon=antigravity' 'Icon=antigravity-app'
  '';

  meta = {
    description = "Google Antigravity, the desktop app for working with agents";
    homepage = "https://antigravity.google/product/antigravity-2/";
    downloadPage = "https://antigravity.google/download";
    license = lib.licenses.unfree;
    sourceProvenance = [ lib.sourceTypes.binaryNativeCode ];
    platforms = [ "x86_64-linux" ];
    mainProgram = "antigravity-app";
  };
}
