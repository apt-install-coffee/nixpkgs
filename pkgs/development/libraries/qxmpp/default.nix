{ mkDerivation
, lib
, fetchFromGitHub
, cmake
, pkg-config
, withGstreamer ? true
, gst_all_1
, qca-qt5
, libomemo-c
}:

mkDerivation rec {
  pname = "qxmpp";
  version = "1.4.0";

  src = fetchFromGitHub {
    owner = "olomono";
    repo = pname;
    rev = "8787df0c6bffda1a920cdb6a29e4631e8a293c53";
    sha256 = "sha256-r9R70C2odV9GagoCBbTAu8RTjc5LbCSdjR/4KxURD7c=";
  };

  nativeBuildInputs = [
    cmake
  ] ++ lib.optionals withGstreamer [
    pkg-config
  ];
  buildInputs = lib.optionals withGstreamer (with gst_all_1; [
    gstreamer
    gst-plugins-bad
    gst-plugins-base
    gst-plugins-good
    qca-qt5
    libomemo-c
  ]);
  cmakeFlags = [
    "-DBUILD_EXAMPLES=false"
    "-DBUILD_TESTS=false"
    "-DWITH_OMEMO=true"
  ] ++ lib.optionals withGstreamer [
    "-DWITH_GSTREAMER=ON"
  ];

  meta = with lib; {
    description = "Cross-platform C++ XMPP client and server library";
    homepage = "https://github.com/qxmpp-project/qxmpp";
    license = licenses.lgpl21Plus;
    maintainers = with maintainers; [ astro ];
    platforms = with platforms; linux;
  };
}
