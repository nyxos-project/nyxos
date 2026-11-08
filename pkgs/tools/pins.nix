# The tool pins a system builds: the channel's (sources.json), except where the overrides
# layer's tools.json has a newer pin for the same recipe. `nyx update NAME` puts one there
# to update a single tool without the rest of the channel; a pin the channel has caught up
# with, or one written for another recipe, is left out.
{
  lib,
  overrides ? null,
}:
let
  channel = lib.importJSON ./sources.json;
  file = "${overrides}/tools.json";
  local = if overrides != null && builtins.pathExists file then lib.importJSON file else { };
  # Herdr's core can move without the app: it counts too.
  release = pin: "${pin.version or ""}-${pin.coreVersion or "0"}";
  newer =
    name: pin:
    channel ? ${name}
    && (pin.recipe or null) == channel.${name}.recipe
    && lib.versionOlder (release channel.${name}) (release pin);
in
channel // lib.filterAttrs newer local
