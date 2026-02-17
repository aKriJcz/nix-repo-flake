{
  lib,
  buildPythonPackage,
  fetchPypi,
  setuptools,
  stdenvNoCC,
  pkgs,
  nix-update-script,
}:

buildPythonPackage rec {
  pname = "mfusepy";
  version = "3.1.0";
  pyproject = true;

  src = fetchPypi {
    inherit pname version;
    hash = "sha256-M7XhPRWVx6zwFx+zD6rxzkffSERXNSsdN5qeKzmsPT8=";
  };

  build-system = [ setuptools ];

  propagatedBuildInputs = [ pkgs.fuse ];

  patchPhase = lib.optionalString (!stdenvNoCC.hostPlatform.isDarwin) ''
    substituteInPlace mfusepy.py --replace-fail \
      "find_library('fuse')" "'${lib.getLib pkgs.fuse}/lib/libfuse.so'"
  '';

  pythonImportsCheck = [ "mfusepy" ];

  passthru.updateScript = nix-update-script { };

  meta = {
    description = "Ctypes bindings for the high-level API in libfuse 2 and 3";
    homepage = "https://pypi.org/project/mfusepy";
    license = lib.licenses.isc;
    maintainers = with lib.maintainers; [ yiyu ];
    mainProgram = "mfusepy";
    platforms = lib.platforms.linux;
  };
}
