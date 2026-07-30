# home/b-branch.nix
# home-manager module for B-branch. Requires nix-repo-flake.overlays.default in
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

    enableGitAlias = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = ''
        Write an explicit `bb` alias into the managed gitconfig.

        This is not required: the package ships a `git-bb` executable, and git
        resolves unknown subcommands to `git-<name>` on PATH, so `git bb` already
        works. Enable this only if you want the alias visible in
        `git config --get-regexp alias` or want it to survive the package leaving
        PATH. Requires `programs.git.enable`.
      '';
    };
  };

  config = lib.mkIf cfg.enable {
    assertions = [
      {
        assertion = cfg.enableGitAlias -> config.programs.git.enable;
        message = "programs.b-branch.enableGitAlias requires programs.git.enable.";
      }
    ];

    home.packages = [ cfg.package ];

    programs.git.aliases = lib.mkIf cfg.enableGitAlias {
      bb = "!${lib.getExe cfg.package}";
    };
  };
}
