{
  description = "Set of nixpkgs modifications to be shared in NixOS and dev envs";

  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.05";

  #inputs.flake-utils = {
  #  url = "github:numtide/flake-utils";
  #  inputs.nixpkgs.follows = "nixpkgs";
  #};

  outputs = { ... }:
    #flake-utils.lib.eachDefaultSystem (system: {
    #});
    {
      overlays.default = self: super: {

        firebirds = self.callPackage ./pkgs/firebird/default.nix {};

        perl = super.perl.override {
          overrides = perlPackages: with perlPackages; let
            inherit (self) lib fetchurl;
          in {
            # Packages generated with nix-generate-from-cpan goes here

            DBDFirebird = buildPerlPackage {
              pname = "DBD-Firebird";
              version = "1.39";
              src = fetchurl {
                url = "mirror://cpan/authors/id/D/DA/DAM/DBD-Firebird-1.39.tar.gz";
                hash = "sha256-I1s2uB2QNoeepk17HS9fgbDClwE9bcBxTCVj2r0KAhQ=";
              };
              buildInputs = [ FileWhich TestCheckDeps TestDeep TestException self.firebirds.firebird_5 ];
              propagatedBuildInputs = [ DBI ];
              # Embedded mode needs to find icu lib
              LD_LIBRARY_PATH = lib.makeLibraryPath [ self.icu ];
              #preConfigure = "export LD_LIBRARY_PATH=${self.firebird}/lib";
              #makeMakerFlags = "EMBEDDED=0";
              meta = {
                description = "DBD::Firebird is a DBI driver for Firebird, written using Firebird C API";
                license = with lib.licenses; [ artistic1 gpl1Plus ];
              };
            };

            ParseANSIColorTiny = buildPerlPackage {
              pname = "Parse-ANSIColor-Tiny";
              version = "0.700";
              src = fetchurl {
                url = "mirror://cpan/authors/id/R/RW/RWSTAUNER/Parse-ANSIColor-Tiny-0.700.tar.gz";
                hash = "sha256-zhtQMHv5vaEur/Hf2NAJGIFaahMC+BURDWufiq8+SdA=";
              };
              buildInputs = [ TestDifferences TestRequires ];
              meta = {
                homepage = "https://github.com/rwstauner/Parse-ANSIColor-Tiny";
                description = "Determine attributes of ANSI-Colored string";
                license = with lib.licenses; [ artistic1 gpl1Plus ];
              };
            };

          };
        };

      };
    };
}
