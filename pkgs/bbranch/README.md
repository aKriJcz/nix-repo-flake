# B-branch

Nix packaging for [B-branch](https://github.com/SimonNyvall/B-branch) — a richer
replacement for `git branch` (last commit date, ahead/behind counts, branch
description, pager). Upstream source is pinned by commit hash in `default.nix`;
there is no submodule to init.

The build uses **Native AOT**, so there is no .NET runtime in the closure and
startup stays instant.

No `install.sh` and no gitconfig alias needed: the package ships both `bb` and a
`git-bb` executable, and git resolves any unknown subcommand to `git-<name>` on
`PATH`, so **`git bb` works as soon as the package is installed**.

## Usage from this flake

```sh
nix build .#b-branch
nix run .#b-branch -- --quiet
```

In a NixOS config — the module defaults to `pkgs.b-branch`, so
`overlays.default` must be in `nixpkgs.overlays`:

```nix
{
  nixpkgs.overlays = [ inputs.nix-repo-flake.overlays.default ];

  imports = [ inputs.nix-repo-flake.nixosModules.b-branch ];
  programs.b-branch.enable = true;
}
```

Or with home-manager:

```nix
{
  imports = [ inputs.nix-repo-flake.homeModules.b-branch ];
  programs.b-branch.enable = true;

  # Optional. `git bb` already works via git-bb on PATH; set this only if you want
  # the alias to appear in `git config --get-regexp alias`.
  # programs.b-branch.enableGitAlias = true;
}
```

`programs.b-branch.enable` does nothing more than put the package on `PATH`, so
plain `environment.systemPackages = [ pkgs.b-branch ]` (or `home.packages`)
works just as well.

## Bumping to a newer upstream commit

1. Set the new `rev` in `default.nix` and blank the `hash` to `lib.fakeHash`,
   then run `nix build .#b-branch` and paste the `got:` hash back.
2. Update `version` to `<tag>-unstable-<commit date>` (or just `<tag>` on a
   release).
3. Regenerate the NuGet lock file if any `PackageReference` changed upstream — it
   is restored offline at build time, so a stale lock fails the build rather than
   silently drifting:

```sh
$(nix build --no-link --print-out-paths .#b-branch.fetch-deps) pkgs/bbranch/deps.json
```
