# nixos/b-branch.nix
# NixOS module for B-branch. Requires nix-repo-flake.overlays.default in
# nixpkgs.overlays, which is where pkgs.b-branch comes from.
{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.programs.b-branch;
in
{
  options.programs.b-branch = {
    enable = lib.mkEnableOption "B-branch, a richer replacement for `git branch`";

    package = lib.mkOption {
      type = lib.types.package;
      default = pkgs.b-branch;
      defaultText = lib.literalExpression "pkgs.b-branch";
      description = "The b-branch package to use.";
    };
  };

  config = lib.mkIf cfg.enable {
    # The package ships `git-bb` alongside `bb`, so putting it on PATH is enough for
    # `git bb` to work - git resolves unknown subcommands to `git-<name>` on PATH.
    environment.systemPackages = [ cfg.package ];
  };
}
