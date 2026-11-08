# Claude Code from its pin, with nixpkgs' recipe: Anthropic's binary, wrapped with its
# updater off (DISABLE_AUTOUPDATER) and its tools on the PATH.
{
  claude-code,
  fetchurl,
  stdenvNoCC,
  pin,
}:
claude-code.overrideAttrs {
  inherit (pin) version;
  src = fetchurl { inherit (pin.srcs.${stdenvNoCC.hostPlatform.system}) url hash; };
}
