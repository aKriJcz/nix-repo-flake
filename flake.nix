{
  description = "Set of nixpkgs modifications to be shared in NixOS and dev envs";

  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.05";

  #inputs.flake-utils = {
  #  url = "github:numtide/flake-utils";
  #  inputs.nixpkgs.follows = "nixpkgs";
  #};

  outputs = { self, nixpkgs }:
    #flake-utils.lib.eachDefaultSystem (system: {
    #});
    let
      systems = [ "x86_64-linux" "aarch64-linux" ];
      forAllSystems = nixpkgs.lib.genAttrs systems;
    in
    {
      # ── 1. Individual packages ──────────────────────────────────────────
      # nix build github:you/nix-repo-flake#firebirds
      # nix build github:you/nix-repo-flake#perlnavigator
      packages = forAllSystems (system:
        let pkgs = nixpkgs.legacyPackages.${system};
        in {

          firebirds    = pkgs.callPackage ./pkgs/firebird {};

          perlnavigator = pkgs.callPackage ./pkgs/perlnavigator {};

          huestacean   = pkgs.libsForQt5.callPackage ./pkgs/huestacean {
            inherit (pkgs.xorg) libX11 libXext libXinerama libXfixes libXtst;
          };

        }
      );


      # ── 2. Custom Perl packages ─────────────────────────────────────────
      # Exposed so users can grab individual CPAN packages:
      #   perl = pkgs.perl.override {
      #     overrides = nix-repo-flake.lib.perlPackageOverrides pkgs;
      #   };
      #   perlPackages = perl.pkgs;
      # Then use perlPackages like:
      #   buildInputs = [
      #     (perlPackages.perl.withPackages (_: with perlPackages; [
      #       Minilla
      #       FFIPlatypusLangCPP
      #       ...
      #     ]))
      #   ];
      lib.perlPackageOverrides = pkgs:
        import ./pkgs/perl-packages {
          inherit (pkgs) lib fetchurl;
          icu = self.packages.${pkgs.system}.icu;
          firebird_5 = self.packages.${pkgs.system}.firebirds.firebird_5;
        };


      # ── 3. Overlay ──────────────────────────────────────────────────────
      # For NixOS: nixpkgs.overlays = [ inputs.my-repo.overlays.default ];
      overlays.default = self: super: {

        firebirds = self.callPackage ./pkgs/firebird {};

        perlnavigator = self.callPackage ./pkgs/perlnavigator {};

        huestacean = self.libsForQt5.callPackage ./pkgs/huestacean { inherit (self.xorg) libX11 libXext libXinerama libXfixes libXtst; };

        # https://github.com/NixOS/nixpkgs/blob/master/doc/languages-frameworks/python.section.md#how-to-override-a-python-package-for-all-python-versions-using-extensions-how-to-override-a-python-package-for-all-python-versions-using-extensions
        pythonPackagesExtensions = super.pythonPackagesExtensions ++ [
          (python-self: python-super: {
            mfusepy = python-self.callPackage ./pkgs/ratarmount/mfusepy.nix { };
            ratarmount = python-self.callPackage ./pkgs/ratarmount/ratarmount-pymodule.nix { };
            ratarmountcore = python-self.callPackage ./pkgs/ratarmount/ratarmountcore-pymodule.nix { inherit (super) zstd; };
          })
        ];

        ratarmount = with self.python3Packages; toPythonApplication ratarmount;

        perl = super.perl.override {
          overrides = import ./pkgs/perl-packages {
            inherit (self) lib fetchurl;
            icu = self.icu;
            firebird_5 = self.firebirds.firebird_5;
          };
        };

      };
    };
}
