# Google's Antigravity CLI, which nixpkgs doesn't have (its `antigravity` is the IDE).
# The release is one static binary; it runs as `agy`, so it never shadows the IDE, with
# its updater off.
{
  lib,
  stdenvNoCC,
  fetchurl,
  makeBinaryWrapper,
  pin,
}:
stdenvNoCC.mkDerivation {
  pname = "antigravity-cli";
  inherit (pin) version;

  src = fetchurl { inherit (pin.srcs.${stdenvNoCC.hostPlatform.system}) url hash; };

  sourceRoot = ".";
  nativeBuildInputs = [ makeBinaryWrapper ];
  dontConfigure = true;
  dontBuild = true;
  dontStrip = true;

  installPhase = ''
    runHook preInstall
    install -Dm755 antigravity $out/libexec/agy
    makeWrapper $out/libexec/agy $out/bin/agy --set AGY_CLI_DISABLE_AUTO_UPDATE 1
    runHook postInstall
  '';

  meta = {
    description = "Google's Antigravity coding agent, in the terminal";
    homepage = "https://github.com/google-antigravity/antigravity-cli";
    license = lib.licenses.unfree;
    sourceProvenance = [ lib.sourceTypes.binaryNativeCode ];
    platforms = [ "x86_64-linux" ];
    mainProgram = "agy";
  };
}
