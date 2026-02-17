# fix_027_package_nix.R
# Issue: https://github.com/JohnGavin/coMMpass-analysis/issues/27
# Branch: infra/issue-27-package-nix
#
# Summary:
#   Add package.nix and push_to_cachix.sh so the coMMpass R package can be
#   built as a Nix derivation and pushed to johngavin cachix (Step 5).
#
# Files created:
#   - package.nix (buildRPackage derivation, same pin as default.nix)
#   - push_to_cachix.sh (builds + pushes single derivation)
#   - R/dev/issues/fix_027_package_nix.R (this file)
#
# Files modified:
#   - .Rbuildignore (exclude package.nix and push_to_cachix.sh from R build)
#
# Pattern: follows irishbuoys canonical implementation
# Verification:
#   nix-build package.nix --no-out-link  # builds successfully
#   ./push_to_cachix.sh                  # pushes to cachix
