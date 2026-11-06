# Google's Antigravity IDE as released now (2.x), with nixpkgs' VS Code builder. nixpkgs'
# `antigravity` is still 1.x, from before the IDE got its own name and folder; this one
# runs as `antigravity-ide` beside it.
{
  lib,
  buildVscode,
  fetchurl,
  writeShellScript,
  commandLineArgs ? "",
}:
buildVscode {
  inherit commandLineArgs;
  version = "2.6.0";
  vscodeVersion = "1.107.0";
  pname = "antigravity-ide";

  executableName = "antigravity-ide";
  longName = "Antigravity IDE";
  shortName = "Antigravity IDE";
  libraryName = "antigravity-ide";
  iconName = "antigravity-ide";

  src = fetchurl {
    url = "https://edgedl.me.gvt1.com/edgedl/release2/j0qc3/antigravity/stable/2.6.0-5526304964083712/linux-x64/Antigravity%20IDE.tar.gz";
    sha256 = "b060a7c7679103b2b619752f8ee7a3088dd241a7d207d4311974b56ea6f94356";
  };
  sourceRoot = "Antigravity IDE";

  tests = { };
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
