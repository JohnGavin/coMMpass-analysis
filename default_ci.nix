# CoMMpass Analysis - CI Environment
# For GitHub Actions workflows
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
      crew
      tarchetypes
      targets
      # Analysis packages
      DESeq2
      edgeR
      limma
      survival
      # Note: survminer not in nixpkgs - removed from pipeline requirements
      # tidyverse meta-package (includes all tidyverse packages)
      tidyverse
      # Core tidyverse packages (already included by tidyverse above)
      dplyr
      ggplot2
      purrr
      readr
      stringr
      tibble
      tidyr
      forcats
      lubridate
      # Utilities
      fs
      glue
      here
      logger
      mirai
      nanonext
      tictoc
      # CI-specific: documentation
      devtools
      gert
      knitr
      pkgdown
      quarto
      rmarkdown
      testthat;
  };

  system_packages = builtins.attrValues {
    inherit (pkgs)
      cacert
      curl
      gh
      git
      pandoc
      R;
  };

  shell = pkgs.mkShell {
    LOCALE_ARCHIVE = if pkgs.system == "x86_64-linux" then "${pkgs.glibcLocales}/lib/locale/locale-archive" else "";
    LANG = "en_US.UTF-8";
    LC_ALL = "en_US.UTF-8";

    buildInputs = [ rpkgs system_packages ];
    shellHook = "export R_MAKEVARS_USER=/dev/null\nprintf 'CoMMpass CI environment ready.\\n'";
  };
in
  {
    inherit pkgs shell;
  }
