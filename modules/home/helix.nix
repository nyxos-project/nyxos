{
  programs.helix = {
    enable = true;
    defaultEditor = true;
    settings = {
      # Uses the terminal's palette, so Foot's Nyx colours carry over.
      theme = "base16_terminal";
      editor = {
        cursorline = true;
        color-modes = true;
        bufferline = "multiple";
        indent-guides.render = true;
        cursor-shape = {
          insert = "bar";
          normal = "block";
          select = "underline";
        };
      };
    };
  };
}
