{ stdenv, cmake, fetchFromGitHub }:

stdenv.mkDerivation rec {
  pname = "libomemo-c";
  version = "20200328";

  src = fetchFromGitHub {
    owner = "dino";
    repo = pname;
    rev = "06184660790daa42433e616fa3dee730717d1c1b";
    sha256 = "sha256-3ZprFaB1Aklk8B8tAdqulZzwZcIUr7r0Ur6SskIuSPE=";
  };

  nativeBuildInputs = [ cmake ];
}
