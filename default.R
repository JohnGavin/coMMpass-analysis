library(rix)

# ── Extract deps directly from DESCRIPTION (single source of truth) ──────────
desc_raw <- read.dcf("DESCRIPTION")
parse_field <- function(field) {
  if (!field %in% colnames(desc_raw)) return(character())
  pkgs <- strsplit(desc_raw[, field], ",\\s*|\n\\s*")[[1]]
  gsub("\\s*\\([^)]+\\)", "", trimws(pkgs)) |>
    (\(x) x[nzchar(x) & !is.na(x)])()
}
desc_deps <- unique(c(parse_field("Imports"), parse_field("Suggests")))

# Dev tools not in DESCRIPTION (intentionally excluded from package deps)
dev_extras <- c(
  "devtools", "mirai", "nanonext", "usethis", "gert", "gh",
  "pkgdown", "styler", "air", "spelling"
)
r_pkgs <- unique(c(desc_deps, dev_extras)) |> sort()

# Bioconductor packages (subset of desc_deps that need Bioc)
bioc_pkgs <- c(
  "TCGAbiolinks", "GenomicDataCommons", "SummarizedExperiment",
  "DESeq2", "edgeR", "limma"
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

shell_hook <- "export R_MAKEVARS_USER=/dev/null\nprintf 'CoMMpass environment ready.\n'"

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
