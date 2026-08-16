{ lib
, stdenv
, buildGoModule
, fetchFromGitHub
, pkg-config
, copyDesktopItems
, makeDesktopItem
, makeWrapper
, exiftool
, zenity
, libglvnd
, libxkbcommon
, wayland
, wayland-protocols
, xorg
, waylandSupport ? false
}:

buildGoModule rec {
  pname = "googletakeoutfixer";
  version = "1.4.0";

  src = fetchFromGitHub {
    owner = "feloex";
    repo = "GoogleTakeoutFixer";
    tag = "v${version}";
    hash = "sha256-bfsDQGdokF2KRUK93zmkwEbu0C3diTT0GC+tByPVNgU=";
  };

  vendorHash = "sha256-BFhQR1sM9e+C6aEOEA5F853efTFQ+IyGi732mHt2po4=";

  subPackages = [ "cmd" ];

  nativeBuildInputs = [
    pkg-config
    copyDesktopItems
    makeWrapper
  ];

  # go-gl/glfw cannot support X11 and Wayland in a single build.
  tags = lib.optionals waylandSupport [ "wayland" ];

  # libX11/libXxf86vm are needed even for the Wayland build: go-gl pulls in
  # GL/glx.h, which includes X11/Xlib.h.
  buildInputs = [
    libglvnd
    xorg.libX11
    xorg.libXxf86vm
  ] ++ lib.optionals (!waylandSupport) [
    xorg.libXcursor
    xorg.libXext
    xorg.libXi
    xorg.libXinerama
    xorg.libXrandr
  ] ++ lib.optionals waylandSupport [
    libxkbcommon
    wayland
    wayland-protocols
  ];

  ldflags = [
    "-s"
    "-w"
    "-X github.com/feloex/GoogleTakeoutFixer/internal/version.Tag=v${version}"
  ];

  # Upstream ships exiftool next to the binary; without a bundled copy the app
  # falls back to whatever is in PATH. zenity is what ncruces/zenity shells out
  # to for the folder pickers.
  postInstall = ''
    mv $out/bin/cmd $out/bin/GoogleTakeoutFixer
    ln -s GoogleTakeoutFixer $out/bin/googletakeoutfixer

    wrapProgram $out/bin/GoogleTakeoutFixer \
      --prefix PATH : ${lib.makeBinPath [ exiftool zenity ]}

    install -Dm644 images/GoogleTakeoutFixer.png \
      $out/share/icons/hicolor/512x512/apps/googletakeoutfixer.png
  '';

  desktopItems = [
    (makeDesktopItem {
      name = "googletakeoutfixer";
      exec = "GoogleTakeoutFixer";
      icon = "googletakeoutfixer";
      desktopName = "Google Takeout Fixer";
      genericName = "Google Photos Takeout cleaner";
      comment = meta.description;
      categories = [ "Graphics" "Photography" "Utility" ];
    })
  ];

  meta = {
    description = "Clean and organize Google Photos Takeout exports";
    homepage = "https://github.com/feloex/GoogleTakeoutFixer";
    changelog = "https://github.com/feloex/GoogleTakeoutFixer/releases/tag/v${version}";
    license = lib.licenses.gpl3Plus;
    mainProgram = "GoogleTakeoutFixer";
    platforms = lib.platforms.linux;
  };
}
