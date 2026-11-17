# The Herdr TUI (herdrdev/herdr) from its pin: the static binary Herdr releases, rather
# than its flake, which builds it with a nixpkgs of its own (a second nixpkgs in NyxOS's
# lock and closure).
{
  lib,
  stdenvNoCC,
  fetchurl,
  pin,
}:
stdenvNoCC.mkDerivation {
  pname = "herdr";
  inherit (pin) version;

  src = fetchurl { inherit (pin.srcs.${stdenvNoCC.hostPlatform.system}) url hash; };

  dontUnpack = true;
  dontConfigure = true;
  dontBuild = true;
  dontStrip = true;

  installPhase = ''
    runHook preInstall
    install -Dm755 $src $out/bin/herdr
    runHook postInstall
  '';

  meta = {
    description = "Herdr's terminal workspace for coding agents";
    homepage = "https://github.com/herdrdev/herdr";
    sourceProvenance = [ lib.sourceTypes.binaryNativeCode ];
    license = lib.licenses.asl20;
    mainProgram = "herdr";
    platforms = [ "x86_64-linux" ];
  };
}
