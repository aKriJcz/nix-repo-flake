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

            TestDeepFuzzy = buildPerlModule {
              pname = "Test-Deep-Fuzzy";
              version = "0.01";
              src = fetchurl {
                url = "mirror://cpan/authors/id/K/KA/KARUPA/Test-Deep-Fuzzy-0.01.tar.gz";
                hash = "sha256-9clP3YNrDQcYfil1VphrCIjSzV0TYlGWLu1CdYA5Ta8=";
              };
              buildInputs = [ ModuleBuildTiny ];
              propagatedBuildInputs = [ MathRound TestDeep ];
              meta = {
                homepage = "https://github.com/karupanerura/Test-Deep-Fuzzy";
                description = "Fuzzy number comparison with Test::Deep";
                license = with lib.licenses; [ artistic1 gpl1Plus ];
              };
            };

            TOMLParser = buildPerlModule {
              pname = "TOML-Parser";
              version = "0.91";
              src = fetchurl {
                url = "mirror://cpan/authors/id/K/KA/KARUPA/TOML-Parser-0.91.tar.gz";
                hash = "sha256-KoUTuQTjd+DK5yaRC+Z29P+WvZYAAcNY3WbcfDeqmo4=";
              };
              buildInputs = [ ModuleBuildTiny TestDeep TestDeepFuzzy ];
              propagatedBuildInputs = [ TypesSerialiser ];
              meta = {
                homepage = "https://github.com/karupanerura/TOML-Parser";
                description = "Simple toml parser";
                license = with lib.licenses; [ artistic1 gpl1Plus ];
              };
            };

            TOML = buildPerlModule {
              pname = "TOML";
              version = "0.97";
              src = fetchurl {
                url = "mirror://cpan/authors/id/K/KA/KARUPA/TOML-0.97.tar.gz";
                hash = "sha256-f9XQIUDsDKKruhp+jQq8m+AlQE/HJRbw206h/i3VHDc=";
              };
              buildInputs = [ ModuleBuildTiny ];
              propagatedBuildInputs = [ TOMLParser ];
              meta = {
                homepage = "https://github.com/karupanerura/toml";
                description = "Parser for Tom's Obvious, Minimal Language";
                license = lib.licenses.gpl2Plus;
              };
            };

            Minilla = buildPerlModule {
              pname = "Minilla";
              version = "3.1.27";
              src = fetchurl {
                url = "mirror://cpan/authors/id/S/SY/SYOHEX/Minilla-v3.1.27.tar.gz";
                hash = "sha256-GENbTQ4V8/AUoML0Q7PzTVvx5mobHLPq1oJ9iS/A5KQ=";
              };
              buildInputs = [ FileCopyRecursive JSON ModuleBuildTiny TestOutput TestRequires ];
              propagatedBuildInputs = [ Appcpanminus DataSectionSimple FileWhich Filepushd ModuleCPANfile ModuleRuntime Moo PodMarkdown TOML TextMicroTemplate TryTiny URI ];
              meta = {
                homepage = "https://github.com/tokuhirom/Minilla";
                description = "CPAN module authoring tool";
                license = with lib.licenses; [ artistic1 gpl1Plus ];
              };
            };

            Timetimegm = buildPerlPackage {
              pname = "Time-timegm";
              version = "0.01";
              src = fetchurl {
                url = "mirror://cpan/authors/id/P/PE/PEVANS/Time-timegm-0.01.tar.gz";
                hash = "sha256-5yHN/aGDFGuJXgTO5xLhCrG8c8i60bvITASxnvEFLJg=";
              };
              buildInputs = [ ExtUtilsCChecker ];
              meta = {
                description = "A UTC version of C<mktime()>";
                license = with lib.licenses; [ artistic1 gpl1Plus ];
              };
            };

            AlgorithmCron = buildPerlPackage {
              pname = "Algorithm-Cron";
              version = "0.10";
              src = fetchurl {
                url = "mirror://cpan/authors/id/P/PE/PEVANS/Algorithm-Cron-0.10.tar.gz";
                hash = "sha256-rbyJ/7t1glno7RipuZMI7IU8rC+CinxlMM5jbRBW3js=";
              };
              buildInputs = [ TestFatal ];
              propagatedBuildInputs = [ Timetimegm ];
              meta = {
                description = "Abstract implementation of the F<cron(8)> scheduling";
                license = with lib.licenses; [ artistic1 gpl1Plus ];
              };
            };

          };
        };

        perlnavigator = self.callPackage ./pkgs/perlnavigator/default.nix {};

        huestacean = self.libsForQt5.callPackage ./pkgs/huestacean { inherit (self.xorg) libX11 libXext libXinerama libXfixes libXtst; };

      };
    };
}
