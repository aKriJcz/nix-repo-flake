{ lib, stdenv, fetchFromGitHub, libedit, autoreconfHook, zlib, unzip, libtommath, libtomcrypt, icu, cmake, superServer ? false }:

let base = {
  pname = "firebird";

  meta = with lib; {
    description = "SQL relational database management system";
    downloadPage = "https://github.com/FirebirdSQL/firebird/";
    homepage = "https://firebirdsql.org/";
    changelog = "https://github.com/FirebirdSQL/firebird/blob/master/CHANGELOG.md";
    license = [ "IDPL" "Interbase-1.0" ];
    platforms = platforms.linux;
    maintainers = with maintainers; [ marcweber ];
  };

  nativeBuildInputs = [ autoreconfHook ];

  buildInputs = [ libedit icu ];

  LD_LIBRARY_PATH = lib.makeLibraryPath [ icu ];

  configureFlags = [
    "--with-system-editline"
  ] ++ (lib.optional superServer "--enable-superserver");

  installPhase = ''
    runHook preInstall
    mkdir -p $out
    cp -r gen/Release/firebird/* $out
    chmod a+x $out/bin/fb_config
    runHook postInstall
  '';

}; in rec {

  firebird_5 = stdenv.mkDerivation (base // rec {
    version = "5.0.1";

    src = fetchFromGitHub {
      owner = "FirebirdSQL";
      repo = "firebird";
      rev = "v${version}";
      sha256 = "sha256-6hjR4izBtHZ7G0fuy6hNF24O2KYRMAOosfA8sYVbDms=";
    };

    buildInputs = base.buildInputs ++ [ zlib unzip libtommath libtomcrypt ];

    nativeBuildInputs = base.nativeBuildInputs ++ [ cmake ];

    dontUseCmakeConfigure = true;


    # https://discourse.nixos.org/t/thankful-for-autopatchelfhook-for-library-dependency-tweaks/36029
    # https://discourse.nixos.org/t/set-ld-library-path-globally-configuration-nix/22281/5

      #patchelf \
      #  --add-needed ${libX11}/lib/libX11.so \
      #  $out/bin/mc

      # wrapProgram ... --prefix LD_LIBRARY_PATH
    postFixup = lib.optionalString (!stdenv.isDarwin) ''
      cd $out/bin
      for file in *; do
        if ! file "$file" | grep -i elf >&/dev/null; then continue; fi
        patchelf \
          --add-rpath ${icu}/lib \
          $out/bin/$file
      done

      patchelf \
        --add-rpath ${icu}/lib \
        $out/lib/libfbclient.so
    '';
  });

  firebird = firebird_5;

}
