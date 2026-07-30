{
  lib,
  stdenv,
  buildDotnetModule,
  dotnetCorePackages,
  fetchFromGitHub,
  git,
  less,
  openssl,
  # Native AOT produces a single self-contained binary with no .NET runtime in the
  # closure and near-instant startup, which matters a lot for something invoked as a
  # git subcommand. Fall back to a framework-dependent build where ILCompiler is
  # unavailable (e.g. some platforms).
  aot ? dotnetCorePackages.sdk_10_0.hasILCompiler,
}:

buildDotnetModule (finalAttrs: {
  pname = "b-branch";
  # Upstream is 10 commits past the v1.3.0 tag; nixpkgs convention for an
  # unreleased commit. To track the tag instead, set version = "1.3.0" and
  # rev = "v${finalAttrs.version}".
  version = "1.3.0-unstable-2026-07-05";

  src = fetchFromGitHub {
    owner = "SimonNyvall";
    repo = "B-branch";
    rev = "b4565f249f5f00c474a7fdcd7cc77cceeb1bfaf4";
    hash = "sha256-T6DB62l95Pb7rEfrnCPtsEUBwZCGctdq3ku3NgNZIe0=";
  };

  projectFile = "src/Cli/Cli.csproj";
  nugetDeps = ./deps.json;

  dotnet-sdk = dotnetCorePackages.sdk_10_0;
  dotnet-runtime = if aot then null else dotnetCorePackages.runtime_10_0;

  selfContainedBuild = aot;

  # ILCompiler shells out to the C compiler/linker for the final native link.
  nativeBuildInputs = lib.optional aot stdenv.cc;

  dotnetFlags = lib.optionals (!aot) [ "-p:PublishAot=false" ];

  # The `Cli` binary takes the absolute path to `less` as its first argument and
  # spawns `git` from PATH. Bake both in so the tool works standalone.
  #
  # `git` is a *suffix*, so an ambient git always wins -- this is only a fallback,
  # and it adds nothing to your download if the flake shares your nixpkgs (see the
  # `inputs.nixpkgs.follows` note in README.md).
  makeWrapperArgs = [
    "--add-flags"
    (lib.getExe' less "less")
    "--suffix"
    "PATH"
    ":"
    (lib.makeBinPath [ git ])
  ];

  executables = [ "Cli" ];

  preFixup = ''
    # Debug symbols and XML doc files are useless in a deployed CLI.
    rm -f $out/lib/${finalAttrs.pname}/*.dbg $out/lib/${finalAttrs.pname}/*.pdb \
          $out/lib/${finalAttrs.pname}/*.xml
  '';

  # This runs after stdenv's `patchelf --shrink-rpath`, which would otherwise drop
  # the RUNPATH entry below (nothing DT_NEEDEDs libssl).
  postFixup =
    # LibGit2Sharp bundles a libgit2 built with GIT_OPENSSL_DYNAMIC: it dlopen()s
    # "libssl.so.3" by bare soname. That finds nothing on NixOS, and libgit2 does
    # not check the result -- its SHA backend function pointers stay NULL and the
    # process segfaults inside git_repository_open_ext. dlopen() searches the
    # calling object's RUNPATH, so pointing libgit2 at openssl fixes it.
    lib.optionalString stdenv.hostPlatform.isLinux ''
      patchelf --add-rpath ${lib.getLib openssl}/lib \
        $out/lib/${finalAttrs.pname}/libgit2-*.so
    ''
    # `bb` is the standalone name; `git-bb` makes `git bb` resolve through PATH with
    # no gitconfig alias at all -- that is how git discovers third-party subcommands.
    + ''
      mv $out/bin/Cli $out/bin/bb
      ln -s bb $out/bin/git-bb
    '';

  meta = {
    description = "Better git branch - a richer replacement for `git branch`";
    longDescription = ''
      B-branch extends `git branch` with the last commit date, ahead/behind counts
      against the upstream, the branch description and a pager interface.

      Installed as both `bb` and `git-bb`, so `git bb` works as soon as the package
      is on PATH -- no gitconfig alias required.
    '';
    homepage = "https://github.com/SimonNyvall/B-branch";
    changelog = "https://github.com/SimonNyvall/B-branch/blob/main/docs/Changelog.md";
    license = lib.licenses.gpl3Only;
    mainProgram = "bb";
    platforms = [
      "x86_64-linux"
      "aarch64-linux"
      "x86_64-darwin"
      "aarch64-darwin"
    ];
  };
})
