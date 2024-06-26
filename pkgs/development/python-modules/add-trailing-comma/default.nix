{ lib
, buildPythonPackage
, fetchFromGitHub
, pytestCheckHook
, pythonOlder
, tokenize-rt
}:

buildPythonPackage rec {
  pname = "add-trailing-comma";
  version = "3.0.0";
  format = "setuptools";

  disabled = pythonOlder "3.8";

  src = fetchFromGitHub {
    owner = "asottile";
    repo = pname;
    rev = "v${version}";
    hash = "sha256-uknXi7fsCWK5ngCEyfpkjovCtvL5v6OwN5kVoBpNZsY=";
  };

  propagatedBuildInputs = [
    tokenize-rt
  ];

  pythonImportsCheck = [
    "add_trailing_comma"
  ];

  nativeCheckInputs = [
    pytestCheckHook
  ];

  meta = with lib; {
    description = "A tool (and pre-commit hook) to automatically add trailing commas to calls and literals";
    homepage = "https://github.com/asottile/add-trailing-comma";
    license = licenses.mit;
    maintainers = with maintainers; [ gador ];
  };
}
