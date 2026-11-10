# Each tool NyxOS packages from a pin (pkgs/tools): it builds; a command-line tool starts
# with an empty home folder and no network (the build sandbox), says its pinned version
# and prints its help; and it leaves nothing in that home folder that could run, which is
# what an updater installing itself would do (starting also shows its libraries resolve).
# Desktop apps are checked for their command and launcher. Every tool needs license
# metadata. One check per tool, `tool-NAME`, so CI can validate a single tool's update.
{
  pkgs,
  lib,
  pins,
}:
let
  # How each command-line tool is started: its command, the arguments that print its
  # version and its help (not every tool takes the same ones), and what it needs in the
  # environment to start with no network. A tool joins here when it gets a pin.
  smoke = {
    antigravity-cli.command = "agy";
    claude-code.command = "claude";
    codex.command = "codex";
    crush.command = "crush";
    cursor-cli.command = "cursor-agent";
    grok-build.command = "grok";
    opencode = {
      command = "opencode";
      # Otherwise it waits for its model list.
      env.OPENCODE_DISABLE_MODELS_FETCH = "1";
    };
  };
  defaults = {
    version = [ "--version" ];
    help = [ "--help" ];
    env = { };
  };

  check =
    name: pin:
    let
      p = pkgs.${name};
      license =
        assert lib.assertMsg (p.meta ? license) "${name} has no license metadata";
        true;
      s = defaults // smoke.${name};
      run = args: lib.escapeShellArgs args;
    in
    assert license;
    pkgs.runCommand "tool-${name}-check" { } (
      if smoke ? ${name} then
        ''
          export HOME=$(mktemp -d)
          export XDG_CONFIG_HOME=$HOME/.config XDG_DATA_HOME=$HOME/.local/share XDG_CACHE_HOME=$HOME/.cache
          ${lib.concatStrings (lib.mapAttrsToList (k: v: "export ${k}=${lib.escapeShellArg v}\n") s.env)}
          cd "$HOME"
          bin=${lib.getExe' p s.command}
          if ! timeout 120 "$bin" ${run s.version} </dev/null >version.txt 2>&1; then
            cat version.txt
            echo "${name}: ${toString s.version} failed"
            exit 1
          fi
          if ! grep -qF ${lib.escapeShellArg pin.version} version.txt; then
            cat version.txt
            echo "${name}: ${toString s.version} doesn't say ${pin.version}, the pinned version"
            exit 1
          fi
          if ! timeout 120 "$bin" ${run s.help} </dev/null >help.txt 2>&1; then
            cat help.txt
            echo "${name}: ${toString s.help} failed"
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
