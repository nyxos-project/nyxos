# A built-in Nyx theme, as the theme engine resolves it (nyx-design's
# builtin-themes.json), for what NixOS builds: the boot menu in the boot theme, and the
# session's defaults in the system theme until nyx-themed writes each person's own.
# Colours are hex without "#". An id that isn't built in gives Catppuccin Mocha.
{ lib, nyx-design }:
id:
let
  all = builtins.fromJSON (
    builtins.readFile "${nyx-design}/crates/nyx-theme-core/builtin-themes.json"
  );
  t = all.${id} or all."catppuccin-mocha";
  hex = c: lib.substring 1 6 c;
  token = name: hex t.colors.${name};
in
{
  inherit (t) name radius;
  light = t.appearance == "light";
  colors = {
    bg = token "surface.primary";
    # Behind the NyxOS wordmark on the wallpapers and the boot splash (nyx-wallpapers,
    # nyx-plymouth): the theme's background, but Mocha's mantle for Mocha.
    backdrop = if id == "catppuccin-mocha" then "181825" else token "surface.primary";
    panel = token "surface.secondary";
    card = token "surface.tertiary";
    surface = token "surface.alternate";
    raised = token "surface.elevated";
    border = token "border.default";
    text = token "text.primary";
    dimText = token "text.secondary";
    tertiaryText = token "text.tertiary";
    accent = token "accent.primary";
    danger = token "status.error";
    warning = token "status.warning";
    success = token "status.success";
  };
  swatches = lib.mapAttrs (_: hex) t.swatches;
  # The terminal's font stays the Nerd Font NyxOS installs, for its symbols.
  font.mono = "JetBrainsMono Nerd Font";
}
