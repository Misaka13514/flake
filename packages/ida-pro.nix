{
  autoPatchelfHook,
  cairo,
  dbus,
  fetchtorrent,
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
  stdenv,
  zlib,
  libice,
  libsm,
  libx11,
  libxau,
  libxcb,
  libxext,
  libxi,
  libxrender,
  libxcb-cursor,
  libxcb-image,
  libxcb-keysyms,
  libxcb-render-util,
  libxcb-wm,
}:
stdenv.mkDerivation (finalAttrs: rec {
  pname = "ida-pro";
  version = "9.3";

  # https://auth.lol/ida
  # http://hexrayst6tfcqxausqtn2dlhngdcvkzux57df6ryrsxi3maupcvzn7id.onion.run
  src = fetchtorrent {
    name = "ida-pro-src";
    url = "magnet:?xt=urn:btih:4520c7a7369ef43b7da462cabb85c44c23493158&dn=ida93&xl=4467442676&tr=udp%3A%2F%2Ftracker.opentrackr.org%3A1337%2Fannounce&tr=udp%3A%2F%2Fopen.stealth.si%3A80%2Fannounce&tr=udp%3A%2F%2Ftracker.torrent.eu.org%3A451%2Fannounce&tr=http%3A%2F%2Flucke.fenesisu.moe%3A6969%2Fannounce&tr=http%3A%2F%2Ftracker.renfei.net%3A8080%2Fannounce&tr=udp%3A%2F%2Ftracker.1h.is%3A1337%2Fannounce&tr=http%3A%2F%2Fipv4.rer.lol%3A2710%2Fannounce&tr=https%3A%2F%2Ftracker.manager.v6.navy%3A443%2Fannounce&tr=udp%3A%2F%2Fopen.demonii.com%3A1337%2Fannounce&tr=udp%3A%2F%2Ftracker.tryhackx.org%3A6969%2Fannounce";
    hash = "sha256-+nxbWSW6/X5uwc6+hzepMaaBv4wFvk/dYS/PCUyYmlo=";
  };

  nativeBuildInputs = [
    makeWrapper
    autoPatchelfHook
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
    libice
    libsm
    libx11
    libxau
    libxcb
    libxext
    libxi
    libxrender
    libxcb-image
    libxcb-keysyms
    libxcb-render-util
    libxcb-wm
    libxcb-cursor
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

    # https://www.virustotal.com/gui/file/2ed43ae4bb84d74dcae6f0099210dfa8d61bfea4952f5f9a07a9aae16cb70f82
    INSTALLER="$src/ida-pro_93_x64linux.run"

    if [ ! -f "$INSTALLER" ]; then
      echo "Error: Installer not found at $INSTALLER"
      ls -R $src
      exit 1
    fi

    # Invoke the installer with the dynamic loader directly, avoiding the need
    # to copy it to fix permissions and patch the executable.
    $(cat $NIX_CC/nix-support/dynamic-linker) "$INSTALLER" \
      --mode unattended --prefix $IDADIR

    # https://www.virustotal.com/gui/file/b60465440c1f3c7dbc52e7771479b2ee06813a770f8892bbca61a46ab1388e1d
    # https://www.virustotal.com/gui/file/7eb70f6dc2d579cfaab7e0f006f577fed35364e640394dc86e75d4f1a357325f
    # https://www.virustotal.com/gui/file/17985fa1a0d1bf404e19bde0a50ac712feabba0bea05f0aa8c06b8c010302596
    install -t $IDADIR \
      $src/kg_patch/idapro.hexlic \
      $src/kg_patch/linux/libida.so \
      $src/kg_patch/linux/libida32.so

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
