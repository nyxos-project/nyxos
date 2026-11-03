{ theme, ... }:
let
  c = theme.colors;
  s = theme.swatches;
in
{
  programs.foot = {
    enable = true;
    settings = {
      main = {
        font = "${theme.font.mono}:size=11";
        pad = "12x12";
      };
      scrollback.lines = 10000;
      mouse.hide-when-typing = "yes";
      colors-dark = {
        background = c.bg;
        foreground = c.text;
        selection-background = c.border;
        selection-foreground = c.text;
        cursor = "${c.bg} ${c.accent}";

        regular0 = c.surface;
        regular1 = s.red;
        regular2 = s.green;
        regular3 = s.amber;
        regular4 = s.blue;
        regular5 = s.violet;
        regular6 = s.teal;
        regular7 = s.graphite;

        bright0 = c.tertiaryText;
        bright1 = s.coral;
        bright2 = s.green;
        bright3 = s.amber;
        bright4 = s.blue;
        bright5 = s.pink;
        bright6 = s.teal;
        bright7 = c.text;
      };
    };
  };
}
