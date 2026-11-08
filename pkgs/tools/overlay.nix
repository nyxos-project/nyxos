# The tools NyxOS packages from pins (pins.nix), under the names the catalog uses. Where
# nixpkgs' recipe already fits (a vendor binary), only its version and source change.
{ pins }:
final: prev: {
  antigravity-app = final.callPackage ../antigravity-app { pin = pins.antigravity-app; };
  antigravity-cli = final.callPackage ../antigravity-cli { pin = pins.antigravity-cli; };
  antigravity-ide = final.callPackage ../antigravity-ide { pin = pins.antigravity-ide; };
  chatgpt-desktop = final.callPackage ../chatgpt-desktop { pin = pins.chatgpt-desktop; };
  claude-code = final.callPackage ../claude-code {
    pin = pins.claude-code;
    inherit (prev) claude-code;
  };
  codex = final.callPackage ../codex { pin = pins.codex; };
  crush = final.callPackage ../crush { pin = pins.crush; };
  cursor-cli = final.callPackage ../cursor-cli {
    pin = pins.cursor-cli;
    inherit (prev) cursor-cli;
  };
  grok-build = final.callPackage ../grok-build { pin = pins.grok-build; };
  herdr-app = final.callPackage ../herdr-app { pin = pins.herdr-app; };
  opencode = final.callPackage ../opencode { pin = pins.opencode; };
}
