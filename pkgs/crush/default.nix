# Charm's Crush from its pin: the binary Charm releases (some releases link glibc, so
# it's patched to run here). It has no updater of its own (only its list of model
# providers refreshes).
{
  lib,
  stdenvNoCC,
  fetchurl,
  autoPatchelfHook,
  installShellFiles,
  pin,
}:
stdenvNoCC.mkDerivation {
  pname = "crush";
  inherit (pin) version;

  src = fetchurl { inherit (pin.srcs.${stdenvNoCC.hostPlatform.system}) url hash; };

  sourceRoot = ".";
  nativeBuildInputs = [
    autoPatchelfHook
    installShellFiles
  ];
  dontConfigure = true;
  dontBuild = true;
  dontStrip = true;

  installPhase = ''
    runHook preInstall
    install -Dm755 crush_*/crush $out/bin/crush
    # Patched now rather than after install, so it runs to write its completions.
    autoPatchelf $out/bin
    export HOME=$TMPDIR
    installShellCompletion --cmd crush \
      --bash <($out/bin/crush completion bash) \
      --fish <($out/bin/crush completion fish) \
      --zsh <($out/bin/crush completion zsh)
    runHook postInstall
  '';

  meta = {
    description = "Charm's coding agent for any model";
    homepage = "https://github.com/charmbracelet/crush";
    changelog = "https://github.com/charmbracelet/crush/releases/tag/v${pin.version}";
    license = lib.licenses.fsl11Mit;
    sourceProvenance = [ lib.sourceTypes.binaryNativeCode ];
    platforms = [ "x86_64-linux" ];
    mainProgram = "crush";
  };
}
