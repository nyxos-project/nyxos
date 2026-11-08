# OpenAI's Codex CLI from its pin: the package OpenAI releases (static binaries, with
# the ripgrep and bubblewrap it runs), rather than nixpkgs' build from source, so a new
# release needs only a new hash. Its startup update check is off.
{
  lib,
  stdenvNoCC,
  fetchurl,
  makeBinaryWrapper,
  pin,
}:
stdenvNoCC.mkDerivation {
  pname = "codex";
  inherit (pin) version;

  src = fetchurl { inherit (pin.srcs.${stdenvNoCC.hostPlatform.system}) url hash; };

  sourceRoot = ".";
  nativeBuildInputs = [ makeBinaryWrapper ];
  dontConfigure = true;
  dontBuild = true;
  dontStrip = true;
  dontPatchELF = true;

  # The package finds its resources beside bin/codex (codex-package.json), so it stays
  # together.
  installPhase = ''
    runHook preInstall
    mkdir -p $out/lib/codex
    cp -r bin codex-* $out/lib/codex/
    makeWrapper $out/lib/codex/bin/codex $out/bin/codex \
      --add-flags "-c check_for_update_on_startup=false"
    runHook postInstall
  '';

  meta = {
    description = "OpenAI's coding agent, in the terminal";
    homepage = "https://github.com/openai/codex";
    changelog = "https://github.com/openai/codex/releases/tag/rust-v${pin.version}";
    license = lib.licenses.asl20;
    sourceProvenance = [ lib.sourceTypes.binaryNativeCode ];
    platforms = [ "x86_64-linux" ];
    mainProgram = "codex";
  };
}
