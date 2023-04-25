{ lib, stdenv, fetchurl, ppp } :
let
in
stdenv.mkDerivation rec {
  pname = "rp-pppoe";
  version = "4.0-beta1";

  src = fetchurl {
    url = "https://dianne.skoll.ca/projects/rp-pppoe/download/rp-pppoe-${version}.tar.gz";
    hash = "sha256-UEzn+LmQPCs61y2EYMBhU4A7Z5h51ttGsG4tjxGxThw=";
  };

  buildInputs = [ ppp ];

  preConfigure = ''
    cd src
    export PPPD=${ppp}/sbin/pppd
  '';

  configureFlags = [
    "--enable-plugin=${ppp}"
  ];

  postConfigure = ''
    sed -i Makefile -e 's@DESTDIR)/etc/ppp@out)/etc/ppp@'
    sed -i Makefile -e 's@PPPOESERVER_PPPD_OPTIONS=@&$(out)@'
  '';

  makeFlags = [
    "AR:=$(AR)"
    "PLUGIN_DIR=$(out)/lib/pppd"
  ];

  meta = with lib; {
    description = "Roaring Penguin Point-to-Point over Ethernet tool";
    platforms = platforms.linux;
    homepage = "https://dianne.skoll.ca/projects/rp-pppoe/";
    license = licenses.gpl2Plus;
  };
}
