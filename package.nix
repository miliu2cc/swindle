{
  lib,
  stdenv,
  pkg-config,
  wayland-scanner,
  wayland-protocols,
  wayland,
  wlroots_0_20,
  libinput,
  libxkbcommon,
  pixman,
  libdrm,
  lua5_4,
  xwayland,
  xorg,
  withXwayland ? true,
}:

stdenv.mkDerivation (finalAttrs: {
  pname = "swindle";
  version = "0.1";

  src = ./.;

  strictDeps = true;

  depsBuildBuild = [ pkg-config ];

  nativeBuildInputs = [
    pkg-config
    wayland-scanner
  ];

  buildInputs =
    [
      wayland
      wayland-protocols
      wlroots_0_20
      libinput
      libxkbcommon
      pixman
      libdrm
      lua5_4
    ]
    ++ lib.optionals withXwayland [
      xorg.libxcb
      xorg.xcbutilwm # provides xcb-icccm
    ];

  # The source includes Lua headers as <lua5.4/lua.h> (the Debian/Arch
  # layout), but nixpkgs' lua5_4 ships them directly in $dev/include.
  # Create a `lua5.4/` shim dir of symlinks and add it to the include path.
  preBuild = ''
    mkdir -p lua-shim/lua5.4
    for h in lua.h luaconf.h lauxlib.h lualib.h lua.hpp; do
      ln -sf ${lib.getDev lua5_4}/include/$h lua-shim/lua5.4/$h
    done
    export NIX_CFLAGS_COMPILE="-I$PWD/lua-shim $NIX_CFLAGS_COMPILE"
  '';

  # The Makefile's `git describe` fallback fails outside a git checkout,
  # so pin the version explicitly.
  makeFlags = [
    "PREFIX=${placeholder "out"}"
    "_VERSION=${finalAttrs.version}"
    "VERSION=${finalAttrs.version}"
  ]
  ++ lib.optionals (!withXwayland) [
    "XWAYLAND="
    "XLIBS="
  ];

  meta = {
    description = "A dwl fork that feels like the poor man's Hyprland";
    homepage = "https://codeberg.org/dwl/dwl";
    license = lib.licenses.gpl3Plus;
    mainProgram = "swindle";
    platforms = lib.platforms.linux;
  };
})
