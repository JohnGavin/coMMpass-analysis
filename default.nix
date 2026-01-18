# CoMMpass Analysis - User Environment (Minimal)
# Use this to run the analysis pipeline
# Snapshot: 2026-01-12
let
  pkgs = import (fetchTarball "https://github.com/rstats-on-nix/nixpkgs/archive/2026-01-12.tar.gz") {};

  rpkgs = builtins.attrValues {
    inherit (pkgs.rPackages)
      # Data access
      aws_s3
      aws_signature
      GenomicDataCommons
      SummarizedExperiment
      TCGAbiolinks
      # Pipeline
      tarchetypes
      targets
      # Core tidyverse
      dplyr
      ggplot2
      purrr
      readr
      stringr
      tibble
      tidyr
      # Utilities
      fs
      glue
      here
      logger
      mirai
      nanonext
      tictoc;
  };

  system_packages = builtins.attrValues {
    inherit (pkgs)
      cacert
      curl
      git
      pandoc
      R;
  };

  shell = pkgs.mkShell {
    LOCALE_ARCHIVE = if pkgs.system == "x86_64-linux" then "${pkgs.glibcLocales}/lib/locale/locale-archive" else "";
    LANG = "en_US.UTF-8";
    LC_ALL = "en_US.UTF-8";

    buildInputs = [ rpkgs system_packages ];
    shellHook = "export R_MAKEVARS_USER=/dev/null\nprintf 'CoMMpass analysis environment ready.\\n'";
  };
in
  {
    inherit pkgs shell;
  }
