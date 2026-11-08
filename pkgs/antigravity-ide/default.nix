# Google's Antigravity IDE as released now (2.x), with nixpkgs' VS Code builder. nixpkgs'
# `antigravity` is still 1.x, from before the IDE got its own name and folder; this one
# runs as `antigravity-ide` beside it.
{
  lib,
  buildVscode,
  fetchurl,
  writeShellScript,
  stdenvNoCC,
  pin,
  commandLineArgs ? "",
}:
buildVscode {
  inherit commandLineArgs;
  inherit (pin) version vscodeVersion;
  pname = "antigravity-ide";

  executableName = "antigravity-ide";
  longName = "Antigravity IDE";
  shortName = "Antigravity IDE";
  libraryName = "antigravity-ide";
  iconName = "antigravity-ide";

  src = fetchurl { inherit (pin.srcs.${stdenvNoCC.hostPlatform.system}) url hash; };
  sourceRoot = "Antigravity IDE";

  tests = { };
  # Google has no release feed for it; its pin in pkgs/tools/sources.json is bumped by hand.
  updateScript = writeShellScript "antigravity-ide-update" ''
    echo "New releases: https://antigravity.google/download" >&2
  '';

  meta = {
    mainProgram = "antigravity-ide";
    description = "Google's agent-first IDE";
    homepage = "https://antigravity.google";
    downloadPage = "https://antigravity.google/download";
    license = lib.licenses.unfree;
    sourceProvenance = [ lib.sourceTypes.binaryNativeCode ];
    platforms = [ "x86_64-linux" ];
  };
}
