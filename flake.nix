{
  description = "Set of nixpkgs modifications to be shared in NixOS and dev envs";

  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.05";

  outputs = { self, nixpkgs }:
    let
      systems = [ "x86_64-linux" "aarch64-linux" ];
      forAllSystems = nixpkgs.lib.genAttrs systems;

      # ── Perl lib (system-independent) ──────────────────────────────
      perlLib = import ./lib/perl.nix { lib = nixpkgs.lib; };

      # ── Our Perl extension factories: pkgs -> pFinal -> pPrev -> {...} ──
      # Add a new entry in all.nix whenever you add a new .nix file.
      myPerlExtensions = import ./pkgs/perl-packages/all.nix;

      # ── pkgs with our overlay applied, for a given system ──────────
      pkgsFor = system: import nixpkgs {
        inherit system;
        overlays = [ self.overlays.default ];
      };
    in
    {
      # ── Library — re-exported for downstream flakes ─────────────────
      # Usage in a downstream flake's overlay:
      #   perlPackagesExtensions = (prev.perlPackagesExtensions or []) ++ [
      #     (import ./my-extension.nix { pkgs = final; })
      #   ];
      lib = perlLib // {
        inherit (nixpkgs) lib;
      };

      # ── Extension factories — composable by downstream flakes ───────
      # Each element: pkgs -> pFinal: pPrev: { ... }
      # Bind pkgs before appending to your overlay's perlPackagesExtensions:
      #   (map (ext: ext self) inputs.nix-repo-flake.perlPackagesExtensions)
      perlPackagesExtensions = myPerlExtensions;


      # ── Individual packages ──────────────────────────────────────────
      # nix build .#firebirds
      # nix build .#perlnavigator
      packages = forAllSystems (system:
        let pkgs = pkgsFor system; in
        {
          inherit (pkgs) perl firebirds perlnavigator ratarmount;
          huestacean = pkgs.huestacean;
        }
      );


      # ── NixOS module ────────────────────────────────────────────────
      # Consumers add to their flake inputs and then:
      #   imports = [ inputs.nix-repo-flake.nixosModules.default ];
      #   perlPackagesExtensions = [ myExtension ];
      # Requires nix-repo-flake.overlays.default in nixpkgs.overlays for
      # the perl rebuild to take effect.
      nixosModules.default = { imports = [ ./nixos/perl-extensions.nix ]; };


      # ── Default overlay ─────────────────────────────────────────────
      # For NixOS: nixpkgs.overlays = [ inputs.nix-repo-flake.overlays.default ];
      #
      # This overlay is the single place that rebuilds pkgs.perl.
      # Other overlays that add Perl packages must ONLY append to
      # perlPackagesExtensions — never redefine perl — so that the
      # fixed-point picks up all extensions from all overlays.
      overlays.default = self: super: {

        firebirds    = self.callPackage ./pkgs/firebird {};

        perlnavigator = self.callPackage ./pkgs/perlnavigator {};

        huestacean = self.libsForQt5.callPackage ./pkgs/huestacean {
          inherit (self.xorg) libX11 libXext libXinerama libXfixes libXtst;
        };

        # https://github.com/NixOS/nixpkgs/blob/master/doc/languages-frameworks/python.section.md#how-to-override-a-python-package-for-all-python-versions-using-extensions-how-to-override-a-python-package-for-all-python-versions-using-extensions
        pythonPackagesExtensions = super.pythonPackagesExtensions ++ [
          (python-self: python-super: {
            mfusepy = python-self.callPackage ./pkgs/ratarmount/mfusepy.nix { };
            ratarmount = python-self.callPackage ./pkgs/ratarmount/ratarmount-pymodule.nix { };
            ratarmountcore = python-self.callPackage ./pkgs/ratarmount/ratarmountcore-pymodule.nix { inherit (super) zstd; };
          })
        ];

        ratarmount = with self.python3Packages; toPythonApplication ratarmount;

        # ── Perl extension system (mirrors pythonPackagesExtensions) ────
        # Bind each factory to self (pkgs) and accumulate with any
        # extensions already registered by earlier overlays.
        perlPackagesExtensions =
          (super.perlPackagesExtensions or []) ++
          (map (ext: ext self) myPerlExtensions);

        # Rebuild perl using the final merged list. Because self is the
        # fixed-point of all overlays, self.perlPackagesExtensions already
        # includes extensions added by later overlays (e.g. mediainfo).
        perl = perlLib.applyPerlExtensions super.perl self.perlPackagesExtensions;
      };


      # ── Legacy alias ────────────────────────────────────────────────
      # For consumers that prefer a named perl attribute instead of
      # touching pkgs.perl:
      #   nixpkgs.overlays = [ inputs.nix-repo-flake.overlays.perl ];
      #   pkgs.perlWithExtensions.withPackages (p: [ p.Minilla ... ])
      overlays.perl = self: prev: {
        perlWithExtensions =
          perlLib.mkPerlWithExtensions prev.perl (map (ext: ext self) myPerlExtensions);

        myPerlPackages =
          (perlLib.applyPerlExtensions prev.perl (map (ext: ext self) myPerlExtensions)).pkgs;
      };
    };
}
