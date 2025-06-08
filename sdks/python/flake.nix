{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs =
    {
      self,
      nixpkgs,
      flake-utils,
    }:
    flake-utils.lib.eachDefaultSystem (
      system:
      let
        pkgs = import nixpkgs { inherit system; };
        python = pkgs.python312;
        pythonPackages = python.pkgs;
        lib-path = with pkgs; pkgs.lib.makeLibraryPath [
          pkgs.libffi
          pkgs.openssl
          pkgs.stdenv.cc.cc
        ];

        # Import the opik derivation
        opik = pythonPackages.callPackage ./nix/python/opik.nix { };
      in
      {
        # Expose the opik package as a top-level output
        packages.opik = opik;
        packages.default = opik;
        
        # Create an overlay providing the Python package extension
        overlays.default = final: prev: {
          pythonPackagesExtensions = prev.pythonPackagesExtensions ++ [
            (python-final: python-prev: {
              opik = opik;
            })
          ];
        };

        devShells.default =
          pkgs.mkShell {
            packages = [
              opik # Add the new opik package
              pythonPackages.pydantic
              pythonPackages.psycopg2
              pythonPackages.orjson
              pythonPackages.sqlalchemy
              pythonPackages.uvicorn
              pythonPackages.fastapi
              pythonPackages.venvShellHook #very important
              pkgs.readline
              pkgs.libffi
              pkgs.openssl
              pkgs.git
              pkgs.openssh
              pkgs.rsync
            ];

            shellHook = ''
              SOURCE_DATE_EPOCH=$(date +%s)
              export "LD_LIBRARY_PATH=$LD_LIBRARY_PATH:${lib-path}"
              VENV=.venv

              if test ! -d $VENV; then
                python3.12 -m venv $VENV
                # check if requirements.txt exists
                  if test -f requirements.txt; then
                      echo "Installing requirements from requirements.txt"
                      pip install -r requirements.txt
                  else
                      echo "No requirements.txt found, skipping pip install"
                  fi
              else
                echo "venv already exists"

              fi
              source ./$VENV/bin/activate
              export PYTHONPATH=`pwd`/$VENV/${python.sitePackages}/:$PYTHONPATH
              #Required for testing
              export GOOGLE_CLOUD_PROJECT="baby-names-app-db-ab831"
              export GOOGLE_CLOUD_LOCATION="us-central1"
              export GOOGLE_APPLICATION_CREDENTIALS="/home/slaser79/.config/gcloud/application_default_credentials.json"
              source ~/.openai_key
              source ~/.claude_key
              source ~/.gemini.key
              source ~/.perplexity.key
              source ~/.brave_search_key

            '';

            postShellHook = ''
              ln -sf ${python.sitePackages}/* ./.venv/lib/python3.12/site-packages
            '';
          };
      }
    );
}
