# The software catalog against NyxOS itself: every nixpkgs package exists, builds for
# this platform and is marked unfree exactly when nixpkgs says so; every Nyx app is one
# nyx-packages has; and the base tier is what a NyxOS install really ships.
{
  pkgs,
  lib,
  catalog,
  nixos,
}:
let
  sysPkgs = nixos.pkgs;
  cfg = nixos.config;
  installed = map lib.getName cfg.environment.systemPackages;
  problems = lib.concatMap (
    item:
    lib.concatMap (
      attr:
      let
        p = lib.attrByPath (lib.splitString "." attr) null sysPkgs;
        unfree = p.meta.unfree or false;
      in
      if !(lib.isDerivation p) then
        [ "${item.id}: nixpkgs has no package ${attr}" ]
      else
        lib.optional (
          !(lib.meta.availableOn sysPkgs.stdenv.hostPlatform p)
        ) "${item.id}: ${attr} isn't available on x86_64-linux"
        ++
          lib.optional (unfree != (item.unfree or false))
            "${item.id}: ${attr} is ${
              if unfree then "unfree" else "free"
            } in nixpkgs, but the catalog says otherwise"
        ++ lib.optional (
          item.tier == "base" && !(lib.elem (lib.getName p) installed)
        ) "${item.id}: base, but NyxOS doesn't install ${attr}"
    ) (item.packages or [ ])
    ++ lib.concatMap (
      app:
      if !(nixos.options.nyx ? ${app}) then
        [ "${item.id}: nyx-packages has no Nyx app ${app}" ]
      else
        lib.optional (
          item.tier == "base" && !cfg.nyx.${app}.enable
        ) "${item.id}: base, but NyxOS doesn't turn on nyx.${app}"
    ) (item.nyx or [ ])
  ) catalog.item;
in
if problems == [ ] then
  pkgs.runCommand "nyxos-catalog-check" { }
    "echo ${toString (lib.length catalog.item)} items checked > $out"
else
  throw ("The software catalog doesn't match NyxOS:\n" + lib.concatLines problems)
