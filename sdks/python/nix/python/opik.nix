{ lib
, buildPythonPackage
, setuptools
# Dependencies from install_requires
, boto3-stubs
, click
, httpx
, levenshtein
, litellm
, openai
, pydantic-settings
, pydantic
, rich
, sentry-sdk_2
, tenacity
, tokenizers # Conditional dependency
, tqdm
, uuid6
, jinja2
# Dependencies from extras_require.proxy
, fastapi
, uvicorn
# Test dependencies
, pytestCheckHook
}:

buildPythonPackage rec {
  pname = "opik";
  version = "1.7.23"; # Using default from setup.py

  src = ../..; # Local source - Point to the project root

  pyproject = true; # Recommended

  build-system = [
    setuptools
  ];

  dependencies = [
    boto3-stubs
    click
    httpx
    levenshtein
    litellm
    openai
    pydantic-settings
    pydantic
    rich
    sentry-sdk_2
    tenacity
    # tokenizers # Conditional dependency - Handled by setup.py marker
    tqdm
    uuid6
    jinja2
  ];

  optional-dependencies = {
    proxy = [
      fastapi
      uvicorn
    ];
  };

  nativeCheckInputs = [
    pytestCheckHook
  ];

  pythonImportsCheck = [
    "opik"
  ];

  # pythonRelaxDeps = true; # Re-evaluate if needed later

  doCheck = false; # Disable tests as they require external services/credentials not available during build

  postPatch = ''
    substituteInPlace setup.py \
      --replace 'os.path.join(HERE, "..", "..", "README.md")' 'os.path.join(HERE, "README.md")' \
      --replace '"pytest",' "" # Remove pytest from install_requires
  '';

  preBuild = ''
    echo "--- Content of setup.py after patchPhase ---"
    cat setup.py
    echo "--------------------------------------------"
  '';

  meta =  {
    description = "Comet tool for logging and evaluating LLM traces"; # From setup.py
    homepage = "https://www.comet.com"; # From setup.py
    license = lib.licenses.asl20; # From setup.py - Corrected license name
    # maintainers = []; # Add if known
  };
}
