# Google's Antigravity CLI, which nixpkgs doesn't have (its `antigravity` is the IDE).
# The release is one static binary; it runs as `agy`, so it never shadows the IDE.
{
  lib,
  stdenvNoCC,
  fetchurl,
}:
stdenvNoCC.mkDerivation (finalAttrs: {
  pname = "antigravity-cli";
  version = "1.5.1";

  src = fetchurl {
    url = "https://github.com/google-antigravity/antigravity-cli/releases/download/${finalAttrs.version}/agy_cli_linux_x64_musl.tar.gz";
    hash = "sha256-6nSuWn1vVNkfc+QA1r8h9K1EGNQQq4lK1Q7mP7DmRL4=";
  };

  sourceRoot = ".";
  dontConfigure = true;
  dontBuild = true;
  dontStrip = true;

  installPhase = ''
    runHook preInstall
    install -Dm755 antigravity $out/bin/agy
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
})
