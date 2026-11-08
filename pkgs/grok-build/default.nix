# xAI's Grok Build, which nixpkgs doesn't have (its grok-cli is someone else's). The
# release is one static binary; it runs as `grok`, with its updater off.
{
  lib,
  stdenvNoCC,
  fetchurl,
  makeBinaryWrapper,
  pin,
}:
stdenvNoCC.mkDerivation {
  pname = "grok-build";
  inherit (pin) version;

  src = fetchurl { inherit (pin.srcs.${stdenvNoCC.hostPlatform.system}) url hash; };

  dontUnpack = true;
  nativeBuildInputs = [ makeBinaryWrapper ];
  dontConfigure = true;
  dontBuild = true;
  dontStrip = true;

  installPhase = ''
    runHook preInstall
    install -Dm755 $src $out/libexec/grok
    makeWrapper $out/libexec/grok $out/bin/grok --set GROK_DISABLE_AUTOUPDATER 1
    runHook postInstall
  '';

  meta = {
    description = "xAI's coding agent";
    homepage = "https://x.ai/cli";
    license = lib.licenses.unfree;
    sourceProvenance = [ lib.sourceTypes.binaryNativeCode ];
    platforms = [ "x86_64-linux" ];
    mainProgram = "grok";
  };
}
