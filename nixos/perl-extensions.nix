# nixos/perl-extensions.nix
# NixOS module — lets any NixOS config append bound perlPackages extensions
# (pFinal: pPrev: { ... }) and have them merged into pkgs.perl automatically.
#
# Requires nix-repo-flake.overlays.default to be in nixpkgs.overlays;
# that overlay is the single place that rebuilds pkgs.perl using the
# accumulated perlPackagesExtensions list.
{ lib, config, ... }:

let
  cfg = config.perlPackagesExtensions;
in
{
  options.perlPackagesExtensions = lib.mkOption {
    type    = with lib.types; listOf (functionTo (functionTo attrs));
    default = [];
    description = lib.mdDoc ''
      List of bound perlPackages extension functions (`pFinal: pPrev: { ... }`).
      All entries are appended to `pkgs.perlPackagesExtensions` via a
      nixpkgs overlay, and `pkgs.perl` is rebuilt with the full merged list
      by `nix-repo-flake.overlays.default` (which must be in
      `nixpkgs.overlays`).
    '';
  };

  config = lib.mkIf (cfg != []) {
    nixpkgs.overlays = [
      (_: prev: {
        perlPackagesExtensions = (prev.perlPackagesExtensions or []) ++ cfg;
      })
    ];
  };
}
