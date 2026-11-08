# Each tool NyxOS packages from a pin (pkgs/tools): it builds; a command-line tool starts
# with an empty home folder and no network (the build sandbox), says its pinned version
# and prints its help; and it leaves nothing in that home folder that could run, which is
# what an updater installing itself would do. Desktop apps are checked for their command
# and launcher. Every tool needs license metadata. One check per tool, `tool-NAME`, so CI
# can validate a single tool's update.
{
  pkgs,
  lib,
  pins,
}:
let
  # Command-line tools and their commands.
  commands = {
    antigravity-cli = "agy";
    claude-code = "claude";
    codex = "codex";
    crush = "crush";
    cursor-cli = "cursor-agent";
    grok-build = "grok";
    opencode = "opencode";
  };

  check =
    name: pin:
    let
      p = pkgs.${name};
      license =
        assert lib.assertMsg (p.meta ? license) "${name} has no license metadata";
        true;
    in
    assert license;
    pkgs.runCommand "tool-${name}-check" { } (
      if commands ? ${name} then
        ''
          export HOME=$(mktemp -d)
          export XDG_CONFIG_HOME=$HOME/.config XDG_DATA_HOME=$HOME/.local/share XDG_CACHE_HOME=$HOME/.cache
          # There's no network here; OpenCode would otherwise wait for its model list.
          export OPENCODE_DISABLE_MODELS_FETCH=1
          cd "$HOME"
          bin=${lib.getExe' p commands.${name}}
          if ! timeout 120 "$bin" --version </dev/null >version.txt 2>&1; then
            cat version.txt
            echo "${name}: --version failed"
            exit 1
          fi
          if ! grep -qF ${lib.escapeShellArg pin.version} version.txt; then
            cat version.txt
            echo "${name}: --version doesn't say ${pin.version}, the pinned version"
            exit 1
          fi
          if ! timeout 120 "$bin" --help </dev/null >help.txt 2>&1; then
            cat help.txt
            echo "${name}: --help failed"
            exit 1
          fi
          rm version.txt help.txt
          found=$(find "$HOME" -type f \( -perm -u+x -o -name '*.AppImage' -o -name '*.tar.gz' \))
          if [ -n "$found" ]; then
            echo "${name} put programs in its home folder, the way an updater would:"
            echo "$found"
            exit 1
          fi
          echo "${name} ${pin.version}: starts, no updater" > $out
        ''
      else
        ''
          test -x ${lib.getExe p}
          ls ${p}/share/applications/*.desktop
          echo "${name} ${pin.version}: builds" > $out
        ''
    );
in
lib.mapAttrs' (name: pin: lib.nameValuePair "tool-${name}" (check name pin)) pins
