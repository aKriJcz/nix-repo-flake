{
  lib,
  buildPythonPackage,
  fetchPypi,
  mfusepy,
  indexed-gzip,
  indexed-zstd,
  libarchive-c,
  python-xz,
  pythonOlder,
  rapidgzip,
  rarfile,
  ratarmountcore,
  setuptools,
  # Mount PDFs as archives, exposing their embedded/attached files. Pulls in pypdf
  # and pillow via ratarmountcore's "pdf" extra.
  enablePdf ? true,
}:

buildPythonPackage rec {
  pname = "ratarmount";
  version = "1.3.0";
  pyproject = true;

  disabled = pythonOlder "3.6";

  src = fetchPypi {
    inherit pname version;
    hash = "sha256-npbw+IfbZ6PqaMTsxiXAWjY2zY8p2ASR6xcNk008qgA=";
  };

  pythonRelaxDeps = [ "python-xz" ];

  build-system = [ setuptools ];

  dependencies = [
    mfusepy
    indexed-gzip
    indexed-zstd
    libarchive-c
    python-xz
    rapidgzip
    rarfile
    ratarmountcore
  ]
  ++ lib.optionals enablePdf ratarmountcore.optional-dependencies.pdf;

  checkPhase = ''
    runHook preCheck

    python tests/tests.py

    runHook postCheck
  '';

  meta = with lib; {
    description = "Mounts archives as read-only file systems by way of indexing";
    homepage = "https://github.com/mxmlnkn/ratarmount";
    changelog = "https://github.com/mxmlnkn/ratarmount/blob/v${version}/CHANGELOG.md";
    license = licenses.mit;
    maintainers = with lib.maintainers; [ mxmlnkn ];
    mainProgram = "ratarmount";
    platforms = lib.platforms.linux;
  };
}
