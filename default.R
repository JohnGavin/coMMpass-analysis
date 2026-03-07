library(rix)

# ── Extract deps directly from DESCRIPTION (single source of truth) ──────────
desc_raw <- read.dcf("DESCRIPTION")
parse_field <- function(field) {
  if (!field %in% colnames(desc_raw)) return(character())
  pkgs <- strsplit(desc_raw[, field], ",\\s*|\n\\s*")[[1]]
  gsub("\\s*\\([^)]+\\)", "", trimws(pkgs)) |>
    (\(x) x[nzchar(x) & !is.na(x)])()
}
# Packages excluded from Nix build (broken upstream hashes or unavailable)
nix_exclude <- c(
  "msigdbr"  # broken sha256 in rstats-on-nix (all tested dates Aug 2025-Feb 2026)
)
desc_deps <- unique(c(parse_field("Imports"), parse_field("Suggests")))
desc_deps <- desc_deps[!desc_deps %in% nix_exclude]

# Dev tools not in DESCRIPTION (intentionally excluded from package deps)
dev_extras <- c(
  "devtools", "mirai", "nanonext", "usethis", "gert", "gh",
  "pkgdown", "styler", "air", "spelling"
)
r_pkgs <- unique(c(desc_deps, dev_extras)) |> sort()

# Bioconductor packages (subset of desc_deps that need Bioc)
bioc_pkgs <- c(
  "TCGAbiolinks", "GenomicDataCommons", "SummarizedExperiment",
  "DESeq2", "edgeR", "limma", "fgsea"
)

# Remove bioc packages from r_pkgs (they go in a separate arg)
r_pkgs <- r_pkgs[!r_pkgs %in% bioc_pkgs]

system_pkgs <- c(
  "curl", "openssl", "libxml2", "glpk", "zlib",
  "locale", "direnv", "jq", "curlMinimal", "nano",
  "duckdb", "tree", "bc", "htop", "btop", "cacert",
  "gh", "git", "gnupg", "toybox", "gettext", "pandoc",
  "less", "unzip", "libiconv", "gcc", "libgcc", "clang",
  "quarto"
) |> unique() |> sort()

shell_hook <- paste0(
  # Get the nix store hash of the current R binary
  "_R_HASH=$(basename $(dirname $(dirname $(which R))))\n",
  # Filter R_LIBS_SITE: keep entries that either have no .so files,
  # or have .so files that link against OUR R build
  "_FILTERED_LIBS=$(echo \"$R_LIBS_SITE\" | tr \":\" \"\\n\" | while read _L; do\n",
  "  if [ -d \"$_L\" ]; then\n",
  "    _SO=$(find \"$_L\" -name \"*.so\" -maxdepth 4 2>/dev/null | head -1)\n",
  "    if [ -n \"$_SO\" ]; then\n",
  "      if otool -L \"$_SO\" 2>/dev/null | grep -q \"$_R_HASH\"; then\n",
  "        echo \"$_L\"\n",
  "      fi\n",
  "    else\n",
  "      echo \"$_L\"\n",
  "    fi\n",
  "  fi\n",
  "done | tr \"\\n\" \":\" | sed 's/:$//')\n",
  "export R_LIBS_SITE=\"$_FILTERED_LIBS\"\n",
  "unset R_LIBS\n",
  "export R_MAKEVARS_USER=/dev/null\n",
  "printf 'CoMMpass environment ready.\\n'"
)

message("Generating default.nix...")
message("  DESCRIPTION deps: ", paste(desc_deps, collapse = ", "))
message("  Dev extras: ", paste(dev_extras, collapse = ", "))

rix::rix(
  date = "2026-01-05",
  r_pkgs = c(r_pkgs, bioc_pkgs),
  system_pkgs = system_pkgs,
  project_path = ".",
  overwrite = TRUE,
  shell_hook = shell_hook
)

message("Created default.nix successfully")
