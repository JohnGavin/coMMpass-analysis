# fix_029_pkgdown_rebuild.R
# Issue: https://github.com/JohnGavin/coMMpass-analysis/issues/29
# Branch: fix/issue-29-pkgdown-rebuild
#
# Summary:
#   Rebuild pkgdown site after vignette rename. Fix _pkgdown.yml reference
#   index to include all 37 documented topics across 8 categories.
#   Remove stale 01_data_acquisition.html from docs/.
#
# Files modified:
#   - _pkgdown.yml (complete reference index with all man pages)
#   - docs/ (rebuilt pkgdown site)
#
# Verification:
#   pkgdown::build_site()  # builds successfully, all 3 vignettes rendered
