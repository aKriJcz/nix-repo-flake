# ActivityWatch 0.14, based on the nixpkgs expression (pkgs/applications/office/activitywatch, 0.13.2 there).
# Call with qt6Packages.callPackage.
{
  lib,
  fetchFromGitHub,
  rustPlatform,
  makeWrapper,
  pkg-config,
  perl,
  openssl,
  rust-jemalloc-sys,
  tzdata,
  python3,
  python3Packages,
  wrapQtAppsHook,
  qtbase,
  qtsvg,
  xdg-utils,
  nodejs_22,
  buildNpmPackage,
}:

let
  version = "0.14.3";
  sources = fetchFromGitHub {
    owner = "ActivityWatch";
    repo = "activitywatch";
    rev = "v${version}";
    hash = "sha256-WKtEVS6FFPppF61rpkBQE/9UhOZslwLlzkDpdr/gJDI=";
    fetchSubmodules = true;
  };

  # aw-core and aw-client at the revisions the release pins (its submodules); aw-qt needs a newer aw-core than
  # nixpkgs has.
  pythonPackages = python3Packages.overrideScope (final: prev: {
    aw-core = prev.aw-core.overridePythonAttrs (old: {
      version = "0.5.18";
      src = "${sources}/aw-core";
      propagatedBuildInputs = old.propagatedBuildInputs ++ [ final.click final.idna ];
    });
    aw-client = prev.aw-client.overridePythonAttrs (old: {
      src = "${sources}/aw-client";
    });
  });
in
rec {
  aw-watcher-afk = pythonPackages.buildPythonApplication {
    pname = "aw-watcher-afk";
    inherit version;

    src = "${sources}/aw-watcher-afk";

    pyproject = true;
    build-system = [ pythonPackages.poetry-core ];

    dependencies = with pythonPackages; [
      aw-client
      xlib
      pynput
    ];

    pythonRelaxDeps = [
      "python-xlib"
    ];

    pythonImportsCheck = [ "aw_watcher_afk" ];

    meta = {
      description = "Watches keyboard and mouse activity to determine if you are AFK or not (for use with ActivityWatch)";
      homepage = "https://github.com/ActivityWatch/aw-watcher-afk";
      mainProgram = "aw-watcher-afk";
      license = lib.licenses.mpl20;
    };
  };

  aw-watcher-window = pythonPackages.buildPythonApplication {
    pname = "aw-watcher-window";
    inherit version;

    src = "${sources}/aw-watcher-window";

    pyproject = true;
    build-system = [ pythonPackages.poetry-core ];

    dependencies = with pythonPackages; [
      aw-client
      xlib
    ];

    pythonRelaxDeps = [
      "python-xlib"
    ];

    pythonImportsCheck = [ "aw_watcher_window" ];

    meta = {
      description = "Cross-platform window watcher (for use with ActivityWatch)";
      homepage = "https://github.com/ActivityWatch/aw-watcher-window";
      mainProgram = "aw-watcher-window";
      license = lib.licenses.mpl20;
      badPlatforms = lib.platforms.darwin; # requires pyobjc-framework
    };
  };

  aw-qt = pythonPackages.buildPythonApplication {
    pname = "aw-qt";
    inherit version;

    src = "${sources}/aw-qt";

    pyproject = true;
    build-system = [
      pythonPackages.poetry-core
      pythonPackages.setuptools
    ];

    dependencies = with pythonPackages; [
      aw-core
      qtbase
      qtsvg # Rendering icons in the trayicon menu
      pyqt6
      click
    ];

    nativeBuildInputs = [
      wrapQtAppsHook
    ];

    # Prevent double wrapping
    dontWrapQtApps = true;

    makeWrapperArgs = [
      "--suffix PATH : ${lib.makeBinPath [ xdg-utils ]}"
    ];

    postInstall = ''
      install -D resources/aw-qt.desktop $out/share/applications/aw-qt.desktop

      # The tray icon is looked up next to the aw_qt module.
      install -D media/logo/logo.png $out/${python3.sitePackages}/media/logo/logo.png

      # For .desktop file and your desktop environment
      install -D media/logo/logo.svg $out/share/icons/hicolor/scalable/apps/activitywatch.svg
      install -D media/logo/logo.png $out/share/icons/hicolor/512x512/apps/activitywatch.png
      install -D media/logo/logo-128.png $out/share/icons/hicolor/128x128/apps/activitywatch.png
    '';

    preFixup = ''
      makeWrapperArgs+=(
        "''${qtWrapperArgs[@]}"
      )
    '';

    pythonImportsCheck = [ "aw_qt" ];

    meta = {
      description = "Tray icon that manages ActivityWatch processes, built with Qt";
      homepage = "https://github.com/ActivityWatch/aw-qt";
      mainProgram = "aw-qt";
      license = lib.licenses.mpl20;
      badPlatforms = lib.platforms.darwin; # requires pyobjc-framework
    };
  };

  # Rewritten in Rust in 0.14 (aw-notify-rs).
  aw-notify = rustPlatform.buildRustPackage {
    pname = "aw-notify";
    inherit version;

    src = "${sources}/aw-notify";

    cargoHash = "sha256-Mep7ppAQ/nCwHKSsokjY7HKFwDtakmqK8oFoM6HtTT0=";

    nativeBuildInputs = [ pkg-config ];

    buildInputs = [ openssl ];

    # The scheduling tests need a time zone database.
    nativeCheckInputs = [ tzdata ];

    meta = {
      description = "Desktop notification service for ActivityWatch";
      homepage = "https://github.com/ActivityWatch/aw-notify-rs";
      mainProgram = "aw-notify";
      license = lib.licenses.mpl20;
    };
  };

  aw-server-rust = rustPlatform.buildRustPackage {
    pname = "aw-server-rust";
    inherit version;

    src = "${sources}/aw-server-rust";

    cargoHash = "sha256-8qbH7jlduLQhfrGMbpvZYs/BMojzaGOIa3+Prv0tlO0=";

    # The crate version lags behind the release (0.14.0 in v0.14.3), so report the release version.
    postPatch = ''
      substituteInPlace aw-server/src/version.rs \
        --replace-fail 'option_env!("CARGO_PKG_VERSION")' 'Some("${version}")'

      # aw-sync lists its optional clap and ctrlc without `dep:`, which makes them features too. cargo-auditable
      # passes the enabled features of the crate it compiles to `cargo metadata` for the whole workspace, and
      # that fails on aw-client-rust, whose optional clap is not a feature. The code only tests for `cli`.
      substituteInPlace aw-sync/Cargo.toml \
        --replace-fail 'cli = ["clap", "ctrlc", "dep:rusqlite"]' 'cli = ["dep:clap", "dep:ctrlc", "dep:rusqlite"]'
    '';

    nativeBuildInputs = [
      makeWrapper
      pkg-config
      perl
    ];

    buildInputs = [
      openssl
      rust-jemalloc-sys
    ];

    env.AW_WEBUI_DIR = aw-webui;

    preCheck = ''
      # Fake home folder for tests that use ~/.cache and ~/.local/share
      export HOME="$TMPDIR"
    '';

    meta = {
      description = "High-performance implementation of the ActivityWatch server, written in Rust";
      homepage = "https://github.com/ActivityWatch/aw-server-rust";
      mainProgram = "aw-server";
      platforms = lib.platforms.linux;
      license = lib.licenses.mpl20;
    };
  };

  aw-webui = buildNpmPackage {
    pname = "aw-webui";
    inherit version;

    src = "${sources}/aw-server-rust/aw-webui";

    nodejs = nodejs_22;
    npmDepsHash = "sha256-XJuIBFNdm8he7OF3X6Szxo74/usfIcwtrLPPY3HYnlU=";

    makeCacheWritable = true;
    npmFlags = [ "--legacy-peer-deps" ];

    # The fetched source has no .git, so hardcode the commit hash shown in the developer settings.
    postPatch = ''
      substituteInPlace vue.config.js \
        --replace-fail "child_process.execSync('git rev-parse --short HEAD').toString().trim()" '"${sources.rev}"'
    '';

    installPhase = ''
      runHook preInstall
      mv dist $out
      mv media/logo/logo.{png,svg} $out
      runHook postInstall
    '';

    doCheck = true;
    checkPhase = ''
      runHook preCheck
      npm test
      runHook postCheck
    '';

    meta = {
      description = "Web-based UI for ActivityWatch, built with Vue.js";
      homepage = "https://github.com/ActivityWatch/aw-webui/";
      license = lib.licenses.mpl20;
    };
  };
}
