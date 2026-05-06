# lib/perl.nix
# Pure library — no dependency on nixpkgs here, takes it as argument.
{ lib }:

rec {
  # Apply a list of extension functions to a perl interpreter.
  # Each extension :: (final: prev: attrset)
  # where final/prev are perlPackages attrsets.
  applyPerlExtensions = perl: extensions:
    let
      base = perl.pkgs;
      folded = builtins.foldl'
        (prev: ext:
          let final = prev // ext final prev;
          in  final)
        base
        extensions;
    in
      # perl.override does not accept an `overrides` parameter, so we
      # directly replace the passthru attributes on the perl attrset.
      perl // {
        pkgs = folded;
        withPackages = f: perl.withPackages (_: f folded);
      };

  # Build enhanced perl and surface perlPackages as a top-level attr.
  mkPerlWithExtensions = perl: extensions:
    let p = applyPerlExtensions perl extensions;
    in  p // { perlPackages = p.pkgs; };

  # Merge extensions from multiple flakes/sources into one list.
  # Each input is expected to expose a `perlPackagesExtensions` list.
  mergeExtensions = inputs:
    lib.concatLists (map (i: i.perlPackagesExtensions or []) inputs);
}
