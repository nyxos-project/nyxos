# Overrides

The flake's `nyxos-overrides` input. On a NyxOS system it is `/etc/nyxos/overrides`,
passed with `--override-input nyxos-overrides path:/etc/nyxos/overrides` by the Nyx
System Manager, which writes `system.json` there. This empty folder is what the flake
reads when nothing is passed.
