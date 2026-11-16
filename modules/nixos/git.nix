# Git and SSH sign-in without a terminal (NYX-APP-GIT-001). Nyx Git, editors and other
# apps run git with terminal prompts off, so a fresh account needs somewhere to keep
# passwords and tokens and a window to ask for them:
# - HTTPS: git's libsecret helper keeps what was typed in the Secret Service (GNOME
#   Keyring), so it's asked for once.
# - Prompts: SSH_ASKPASS, which git also uses for its own username and password
#   prompts, opens a small window with git's or ssh's question.
# - SSH keys: GNOME Keyring's agent (gcr-ssh-agent) holds them and asks for a key's
#   passphrase in its own window.
{
  lib,
  pkgs,
  ...
}:
let
  # Only the helper, from git's own source: gitFull would bring Subversion and Perl.
  credentialHelper = pkgs.stdenv.mkDerivation {
    pname = "git-credential-libsecret";
    inherit (pkgs.git) version src;
    nativeBuildInputs = [ pkgs.pkg-config ];
    buildInputs = [
      pkgs.libsecret
      pkgs.glib
    ];
    dontConfigure = true;
    buildPhase = ''
      runHook preBuild
      $CC -O2 -o git-credential-libsecret contrib/credential/libsecret/git-credential-libsecret.c \
        $(pkg-config --cflags --libs libsecret-1 glib-2.0)
      runHook postBuild
    '';
    installPhase = ''
      runHook preInstall
      install -Dm755 git-credential-libsecret $out/bin/git-credential-libsecret
      runHook postInstall
    '';
    meta.mainProgram = "git-credential-libsecret";
  };

  # ssh-askpass's contract: the question is the first argument; print the answer and
  # exit 0, or exit non-zero to cancel. SSH_ASKPASS_PROMPT=confirm asks yes or no by
  # exit status, `none` only informs.
  askpass = pkgs.writeShellApplication {
    name = "nyx-askpass";
    runtimeInputs = [ pkgs.zenity ];
    text = ''
      prompt=''${1:-Password:}
      title="Sign in"
      # GL as the Nyx apps use (Vulkan in a VM fills stderr); the answer goes to stdout
      # and anything else would end up in git's error message.
      export GSK_RENDERER=gl
      exec 2>/dev/null
      case ''${SSH_ASKPASS_PROMPT:-} in
        confirm) exec zenity --question --title="$title" --text="$prompt" ;;
        none) exec zenity --info --title="$title" --text="$prompt" ;;
      esac
      case $prompt in
        # Usernames and ssh's "continue connecting (yes/no/[fingerprint])?" are shown.
        [Uu]sername* | *"(yes/no"*) exec zenity --entry --title="$title" --text="$prompt" ;;
        *) exec zenity --entry --hide-text --title="$title" --text="$prompt" ;;
      esac
    '';
  };
in
{
  programs.git = {
    enable = lib.mkDefault true;
    config.credential.helper = lib.mkDefault (lib.getExe credentialHelper);
  };
  # The Secret Service the helper keeps passwords in, and the SSH agent.
  services.gnome.gnome-keyring.enable = lib.mkDefault true;

  programs.ssh = {
    enableAskPassword = lib.mkDefault true;
    askPassword = lib.mkDefault (lib.getExe askpass);
  };
}
