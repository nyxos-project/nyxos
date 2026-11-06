{ config, theme, ... }:
let
  c = theme.colors;
in
{
  programs.zsh = {
    enable = true;
    # /etc/zshrc already ran compinit (modules/nixos/shell.nix).
    enableCompletion = false;
    autosuggestion = {
      enable = true;
      highlight = "fg=#${c.tertiaryText}";
    };
    syntaxHighlighting.enable = true;

    history = {
      path = "${config.xdg.stateHome}/zsh/history";
      size = 50000;
      save = 50000;
      extended = true;
      share = true;
      ignoreSpace = true;
      ignoreAllDups = true;
      expireDuplicatesFirst = true;
    };

    initContent = ''
      # The editor chosen in Settings → Default Apps.
      if [[ -r ''${XDG_CONFIG_HOME:-$HOME/.config}/nyx/editor ]]; then
        export EDITOR=$(<''${XDG_CONFIG_HOME:-$HOME/.config}/nyx/editor) VISUAL=$EDITOR
      fi
      NYX_PROMPT_DIR='#${c.text}'
      NYX_PROMPT_DIM='#${c.dimText}'
      NYX_PROMPT_GIT='#${theme.swatches.violet}'
      NYX_PROMPT_ACCENT='#${c.accent}'
      NYX_PROMPT_ERROR='#${c.danger}'
      ${builtins.readFile ./zsh/prompt.zsh}

      # The user's own lines; NyxOS never writes this file.
      if [[ -r ''${XDG_CONFIG_HOME:-$HOME/.config}/zsh/user.zsh ]]; then
        source ''${XDG_CONFIG_HOME:-$HOME/.config}/zsh/user.zsh
      fi
    '';
  };

  programs.fzf = {
    enable = true;
    enableZshIntegration = true;
  };

  programs.zoxide = {
    enable = true;
    enableZshIntegration = true;
  };
}
