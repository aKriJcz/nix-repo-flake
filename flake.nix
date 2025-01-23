{
  description = "Set of nixpkgs modifications to be shared in NixOS and dev envs";

  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-24.11";

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
              version = "1.38";
              src = fetchurl {
                url = "mirror://cpan/authors/id/D/DA/DAM/DBD-Firebird-1.38.tar.gz";
                hash = "sha256-SwJ5lrnJzVs9tVLNBf+8zClb/Mu5uWQODFXPxzm7Liw=";
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
          };
        };

      };
    };
}
