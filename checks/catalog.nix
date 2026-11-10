# The software catalog against NyxOS itself: every package exists, builds for this
# platform and is marked unfree exactly when nixpkgs says so; a per-user item's packages
# are in what profiles install from (the flake's legacyPackages, its unfree ones allowed)
# and a system item's Nyx apps are options nyx-packages has; and the base tier is what a
# NyxOS install really ships.
{
  pkgs,
  lib,
  catalog,
  nixos,
  userPkgs,
}:
let
  sysPkgs = nixos.pkgs;
  cfg = nixos.config;
  installed = map lib.getName cfg.environment.systemPackages;
  # Item.scope in nyx-catalog.
  scope =
    item:
    item.scope or (
      if item.tier == "base" || (item.services or [ ]) != [ ] || (item.groups or [ ]) != [ ] then
        "system"
      else
        "user"
    );
  problems = lib.concatMap (
    item:
    let
      user = scope item == "user";
      from = if user then userPkgs else sysPkgs;
    in
    lib.concatMap (
      attr:
      let
        p = lib.attrByPath (lib.splitString "." attr) null from;
        # Unfree itself, or something it pulls in is (Lutris: Steam's runtime): nixpkgs
        # without unfree packages can't evaluate it.
        plain = lib.attrByPath (lib.splitString "." attr) null pkgs;
        unfree = p.meta.unfree or false || (plain != null && !(builtins.tryEval plain.drvPath).success);
      in
      if !(lib.isDerivation p) then
        [ "${item.id}: ${if user then "the profile packages have" else "nixpkgs has"} no package ${attr}" ]
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
          user && !(builtins.tryEval p.drvPath).success
        ) "${item.id}: ${attr} can't be installed per user (an unfree license the profile packages don't allow?)"
        ++ lib.optional (
          item.tier == "base" && !(lib.elem (lib.getName p) installed)
        ) "${item.id}: base, but NyxOS doesn't install ${attr}"
    ) (item.packages or [ ])
    ++ lib.concatMap (
      app:
      if user then
        lib.optional (!(userPkgs ? "nyx-${app}")) "${item.id}: the profile packages have no nyx-${app}"
      else if !(nixos.options.nyx ? ${app}) then
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
