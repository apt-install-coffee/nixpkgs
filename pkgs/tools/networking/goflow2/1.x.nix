{ lib
, buildGoModule
, fetchFromGitHub
}:

buildGoModule rec {
  pname = "goflow2";
  version = "1.3.5";

  src = fetchFromGitHub {
    owner = "netsampler";
    repo = pname;
    rev = "v${version}";
    hash = "sha256-YGPeaJqszAw7vQ/WzUBK7g9sAz9p0+aeBfteG4ZcrLU=";
  };

  ldflags = [
    "-s"
    "-w"
    "-X=main.version=${version}"
  ];

  vendorHash = "sha256-jWm/061alLKTzn53uKun1qj2TM77pjltQlZl1/dTd80=";

  meta = with lib; {
    description = "High performance sFlow/IPFIX/NetFlow Collector";
    homepage = "https://github.com/netsampler/goflow2";
    license = licenses.bsd3;
    maintainers = teams.wdz.members;
    mainProgram = "goflow2";
  };
}
