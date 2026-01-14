# Manual fix for CoMMpass Analysis Environment
# Snapshot: 2026-01-12
let
 pkgs = import (fetchTarball "https://github.com/rstats-on-nix/nixpkgs/archive/2026-01-12.tar.gz") {};
 
  rpkgs = builtins.attrValues {
    inherit (pkgs.rPackages) 
      aws_s3
      aws_signature
      dplyr
      fs
      GenomicDataCommons
      gert
      ggplot2
      gh
      glue
      here
      logger
      mirai
      nanonext
      pkgdown
      purrr
      readr
      stringr
      styler
      SummarizedExperiment
      tarchetypes
      targets
      TCGAbiolinks
      testthat
      tibble
      tictoc
      tidyr
      usethis;
  };
      
  system_packages = builtins.attrValues {
    inherit (pkgs) 
      bc
      cacert
      curl
      direnv
      duckdb
      gcc
      gh
      git
      htop
      jq
      libiconv
      libxml2
      locale
      nano
      nix
      openssl
      pandoc
      R
      tree
      unzip
      zlib;
  };
  
  shell = pkgs.mkShell {
    LOCALE_ARCHIVE = if pkgs.system == "x86_64-linux" then "${pkgs.glibcLocales}/lib/locale/locale-archive" else "";
    LANG = "en_US.UTF-8";
    LC_ALL = "en_US.UTF-8";
    
    buildInputs = [ rpkgs system_packages ];
    shellHook = "export R_MAKEVARS_USER=/dev/null\nprintf 'CoMMpass environment ready.\n'";
  }; 
in
  {
    inherit pkgs shell;
  }