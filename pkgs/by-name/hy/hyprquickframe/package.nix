{
  fetchFromGitHub,
  lib,
  nix-update-script,
  stdenvNoCC,

  # build
  quickshell,
  makeWrapper,

  # runtime deps
  grim,
  imagemagick,
  wl-clipboard,
  satty,
  libnotify,
}:
let
  runtimeDeps = [
    grim
    imagemagick
    wl-clipboard
    satty
    libnotify
  ];
in
stdenvNoCC.mkDerivation (finalAttrs: {
  pname = "hyprquickframe";
  version = "0-unstable-2026-02-06";

  src = fetchFromGitHub {
    owner = "Ronin-CK";
    repo = "HyprQuickFrame";
    rev = "82d9baf7cce704b1bb64277e1da80c3000af0bce";
    hash = "sha256-GfxT0g58rrStZEtPVj1cMuFvGwdqpqSiiypsa+JriCw=";
  };

  nativeBuildInputs = [ makeWrapper ];

  installPhase = ''
    runHook preInstall

    mkdir -p $out/share/HyprQuickFrame $out/bin
    cp -R *.qml *.frag *.frag.qsb $out/share/HyprQuickFrame

    makeWrapper ${quickshell}/bin/quickshell $out/bin/hyprquickframe \
      --prefix PATH : ${lib.makeBinPath runtimeDeps} \
      --add-flags "-c $out/share/HyprQuickFrame -n"

    runHook postInstall
  '';

  passthru.updateScript = nix-update-script { };

  meta = with lib; {
    description = "Quickshell-based screenshot utility for Hyprland";
    homepage = "https://github.com/Ronin-CK/HyprQuickFrame";
    license = licenses.mit;
    platforms = platforms.linux;
    mainProgram = "hyprquickframe";
  };
})
