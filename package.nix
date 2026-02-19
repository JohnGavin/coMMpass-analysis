# package.nix - Build coMMpass as an installable R package derivation
#
# Used by push_to_cachix.sh to build and push to johngavin cachix.
# Uses same rstats-on-nix pin as default.nix (2026-02-16).
#
# Usage:
#   nix-build package.nix --no-out-link
#   # Push ONLY this package (not deps!) via watch-exec:
#   cachix watch-exec johngavin --watch-mode auto -- nix-build package.nix --no-out-link

let
  pkgs = import (fetchTarball "https://github.com/rstats-on-nix/nixpkgs/archive/2026-02-16.tar.gz") {};

  coMMpass = pkgs.rPackages.buildRPackage {
    name = "coMMpass";
    src = ./.;

    # Imports from DESCRIPTION
    propagatedBuildInputs = with pkgs.rPackages; [
      arrow
      aws_s3
      cli
      crew
      DBI
      dbplyr
      DESeq2
      dplyr
      duckdb
      edgeR
      GenomicDataCommons
      ggplot2
      glue
      limma
      logger
      SummarizedExperiment
      survival
      tarchetypes
      targets
      TCGAbiolinks
      tibble
    ];
  };

in coMMpass
