{
  buildFHSEnv,
  stdenv,
  fetchurl,
  p7zip,
}:

let
  perlnavigator-pkg = stdenv.mkDerivation rec {
  name = "perlnavigator";
  version = "0.8.18";
  src = fetchurl {
    url = "https://github.com/bscan/PerlNavigator/releases/download/v${version}/${name}-linux-x86_64.zip";
    hash = "sha256-G8YMIAQOWCV7uvtA7LtH671427pUExIWKEuG8mIj1G0=";
  };

  buildCommand = ''
    ${p7zip}/bin/7z x "$src"
    mkdir -p $out/bin
    install -Dm755 perlnavigator-linux-x86_64/perlnavigator $out/bin/perlnavigator-bin
  '';
  };
in buildFHSEnv {
  name = "perlnavigator";
  targetPkgs = pkgs: [ perlnavigator-pkg ];
  runScript = "${perlnavigator-pkg}/bin/perlnavigator-bin";
}
