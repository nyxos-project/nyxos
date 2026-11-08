# Cursor Agent from its pin, with nixpkgs' recipe. Its background updater would install
# new versions into the home folder, so the command always runs with it off.
{
  cursor-cli,
  fetchurl,
  makeBinaryWrapper,
  stdenvNoCC,
  pin,
}:
cursor-cli.overrideAttrs (old: {
  inherit (pin) version;
  src = fetchurl { inherit (pin.srcs.${stdenvNoCC.hostPlatform.system}) url hash; };
  nativeBuildInputs = old.nativeBuildInputs ++ [ makeBinaryWrapper ];
  postInstall = (old.postInstall or "") + ''
    rm $out/bin/cursor-agent
    makeWrapper $out/share/cursor-agent/cursor-agent $out/bin/cursor-agent \
      --add-flag --disable-auto-update
  '';
})
