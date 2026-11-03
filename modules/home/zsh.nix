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
      NYX_PROMPT_DIR='#${c.text}'
      NYX_PROMPT_DIM='#${c.dimText}'
      NYX_PROMPT_GIT='#${theme.swatches.violet}'
      NYX_PROMPT_ACCENT='#${c.accent}'
      NYX_PROMPT_ERROR='#${c.danger}'
      ${builtins.readFile ./zsh/prompt.zsh}
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
