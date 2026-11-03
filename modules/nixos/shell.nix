# Zsh is the login and interactive shell; Bash stays for scripts, root and recovery.
{ config, pkgs, ... }:
{
  programs.zsh = {
    enable = true;
    # /etc/zshrc runs compinit once for every user; Home Manager doesn't repeat it.
    enableCompletion = true;
    promptInit = "";
  };

  users.users.${config.nyxos.user.name}.shell = pkgs.zsh;

  environment.pathsToLink = [ "/share/zsh" ];

  environment.variables = {
    EDITOR = "hx";
    VISUAL = "hx";
  };
}
