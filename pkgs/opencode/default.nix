# OpenCode from its pin: the binary its developers release (Bun-compiled, so it isn't
# stripped), with its updater off and ripgrep on the PATH.
{
  lib,
  stdenvNoCC,
  fetchurl,
  autoPatchelfHook,
  makeBinaryWrapper,
  ripgrep,
  pin,
}:
stdenvNoCC.mkDerivation {
  pname = "opencode";
  inherit (pin) version;

  src = fetchurl { inherit (pin.srcs.${stdenvNoCC.hostPlatform.system}) url hash; };

  sourceRoot = ".";
  nativeBuildInputs = [
    autoPatchelfHook
    makeBinaryWrapper
  ];
  dontConfigure = true;
  dontBuild = true;
  dontStrip = true;

  installPhase = ''
    runHook preInstall
    install -Dm755 opencode $out/libexec/opencode
    makeWrapper $out/libexec/opencode $out/bin/opencode \
      --set OPENCODE_DISABLE_AUTOUPDATE 1 \
      --prefix PATH : ${lib.makeBinPath [ ripgrep ]}
    runHook postInstall
  '';

  meta = {
    description = "An open-source coding agent for any model";
    homepage = "https://github.com/anomalyco/opencode";
    changelog = "https://github.com/anomalyco/opencode/releases/tag/v${pin.version}";
    license = lib.licenses.mit;
    sourceProvenance = [ lib.sourceTypes.binaryNativeCode ];
    platforms = [ "x86_64-linux" ];
    mainProgram = "opencode";
  };
}
