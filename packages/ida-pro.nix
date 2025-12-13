{
  autoPatchelfHook,
  cairo,
  dbus,
  fetchtorrent,
  fetchurl,
  fontconfig,
  freetype,
  glib,
  gtk3,
  lib,
  libdrm,
  libGL,
  libkrb5,
  libsecret,

  libunwind,
  libxkbcommon,
  makeWrapper,
  openssl,
  python3,
  stdenv,
  xorg,
  zlib,
}:

stdenv.mkDerivation (finalAttrs: rec {
  pname = "ida-pro";
  version = "9.2";

  # https://auth.lol/ida
  src = fetchtorrent {
    name = "ida-pro-src";
    url = "magnet:?xt=urn:btih:ce86306a417dd64fab8d26a4983a58412008aa9e&dn=ida92&tr=http%3A%2F%2Ftracker.mywaifu.best%3A6969%2Fannounce&tr=udp%3A%2F%2Ftracker.qu.ax%3A6969%2Fannounce&tr=http%3A%2F%2Ftracker.renfei.net%3A8080%2Fannounce&tr=https%3A%2F%2Ftracker.bjut.jp%3A443%2Fannounce&tr=http%3A%2F%2Ffleira.no%3A6969%2Fannounce";
    hash = "sha256-KvAmdzgBMlxeYKhjAQSGI2FwhMF2C5BcJvVz0bk6Ito=";
  };

  patcher = fetchurl {
    url = "https://raw.githubusercontent.com/misaka18931/misakaPkgs/b9732443a451c81f57f75ab295dfb5cd518b5ba4/pkgs/ida-pro-91/keygen3.py";
    hash = "sha256-8UWf1RKsRNWJ8CC6ceDeIOv4eY3ybxZ9tv5MCHx80NY=";
  };

  nativeBuildInputs = [
    makeWrapper
    autoPatchelfHook
    python3
  ];

  # We just get a runfile in $src, so no need to unpack it.
  dontUnpack = true;

  # Add everything to the RPATH, in case IDA decides to dlopen things.
  runtimeDependencies = [
    cairo
    dbus
    fontconfig
    freetype
    glib
    gtk3
    libdrm
    libGL
    libkrb5
    libsecret

    libunwind
    libxkbcommon
    openssl
    stdenv.cc.cc
    xorg.libICE
    xorg.libSM
    xorg.libX11
    xorg.libXau
    xorg.libxcb
    xorg.libXext
    xorg.libXi
    xorg.libXrender
    xorg.xcbutilimage
    xorg.xcbutilkeysyms
    xorg.xcbutilrenderutil
    xorg.xcbutilwm
    xorg.xcbutilcursor
    zlib
  ];
  buildInputs = runtimeDependencies;

  # IDA comes with its own Qt6, some dependencies are missing in the installer.
  autoPatchelfIgnoreMissingDeps = [
    "libQt6Network.so.6"
    "libQt6EglFSDeviceIntegration.so.6"
    "libQt6WaylandEglClientHwIntegration.so.6"
    "libQt6WlShellIntegration.so.6"
    "libQt6WaylandCompositor.so.6"
  ];

  installPhase = ''
    runHook preInstall

    mkdir -p $out/bin $out/lib $out/opt
    mkdir -p $out/.local/share/applications

    # IDA depends on quite some things extracted by the runfile, so first extract everything
    # into $out/opt, then remove the unnecessary files and directories.
    IDADIR=$out/opt/${finalAttrs.pname}-${finalAttrs.version}

    # The installer doesn't honor `--prefix` in all places,
    # thus needing to set `HOME` here.
    HOME=$out

    INSTALLER="$src/ida-pro_92_x64linux.run"

    if [ ! -f "$INSTALLER" ]; then
      echo "Error: Installer not found at $INSTALLER"
      ls -R $src
      exit 1
    fi

    # Invoke the installer with the dynamic loader directly, avoiding the need
    # to copy it to fix permissions and patch the executable.
    $(cat $NIX_CC/nix-support/dynamic-linker) "$INSTALLER" \
      --mode unattended --prefix $IDADIR

    pushd $IDADIR
    python $patcher
    mv libida.so.patched libida.so
    mv libida32.so.patched libida32.so
    popd

    # move IDA remote debug servers
    mv $IDADIR/dbgsrv $out

    # Some libraries come with the installer.
    addAutoPatchelfSearchPath $IDADIR

    # Wrap the ida executable to set QT_PLUGIN_PATH
    wrapProgram $IDADIR/ida --prefix QT_PLUGIN_PATH : $IDADIR/plugins/platforms
    ln -s $IDADIR/ida $out/bin/ida



    # runtimeDependencies don't get added to non-executables, and openssl is needed
    #  for cloud decompilation
    patchelf --add-needed libcrypto.so $IDADIR/libida.so

    mv $out/.local/share $out
    rm -r $out/.local

    runHook postInstall
  '';

  meta = with lib; {
    description = "The world's smartest and most feature-full disassembler";
    homepage = "https://hex-rays.com/ida-pro/";
    changelog = "https://hex-rays.com/products/ida/news/";
    license = licenses.unfree;
    mainProgram = "ida";
    maintainers = with maintainers; [ Misaka13514 ];
    platforms = [ "x86_64-linux" ]; # Right now, the installation script only supports Linux.
    sourceProvenance = with sourceTypes; [ binaryNativeCode ];
  };
})
