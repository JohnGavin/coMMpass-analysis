# CoMMpass Analysis Dashboard (Shinylive WebR)

This directory contains a standalone Shinylive dashboard that runs entirely in the browser using WebAssembly.

## What Was Created

Successfully exported from `shiny/app.R` using the `shinylive` R package:

```r
library(shinylive)
shinylive::export(appdir = "shiny", destdir = "docs/dashboard_webr")
```

## Directory Structure

- `index.html` - Main entry point for the dashboard
- `app.json` - Serialized Shiny app code and metadata (98KB)
- `shinylive/` - WebAssembly runtime and packages (121MB total)
- `shinylive-sw.js` - Service worker for caching
- `edit/` - Optional editing interface

## Deployment

To deploy to GitHub Pages:

1. This directory is already in `docs/` which GitHub Pages can serve
2. Configure repository settings: Settings → Pages → Source: Deploy from a branch → Branch: `main` → Folder: `/docs/dashboard_webr`
3. Access at: `https://[username].github.io/[repo]/dashboard_webr/`

Or serve locally:
```bash
cd docs/dashboard_webr
python -m http.server 8000
# Visit http://localhost:8000
```

## Features

- Runs entirely in browser (no R server needed)
- Interactive data visualization with plotly
- Multiple analysis modules:
  - Quality Control (PCA, library size plots)
  - Differential Expression (volcano, MA plots)
  - Survival Analysis (Kaplan-Meier curves)
  - Pathway Analysis (enrichment plots)
- All packages cached in browser after first load
- Works offline after initial download

## Technical Details

- Generated with: `shinylive` R package v0.5+
- App engine: WebR (R compiled to WebAssembly)
- Total size: 121MB (includes all R packages)
- First load: ~30-60 seconds (downloads packages)
- Subsequent loads: Fast (browser caching)

## Differences from Quarto Shinylive

This approach uses the `shinylive` R package directly instead of the Quarto Shinylive extension:

**Advantages:**
- More reliable - no Quarto extension issues
- Direct control over export process
- Cleaner output structure
- Better error messages

**Quarto Extension Issues Encountered:**
- Failed with "ERROR Unsupported engine: shinylive-r"
- Required manual `quarto add quarto-ext/shinylive`
- Complex debugging of Quarto extensions

## Source Code

Original app code: `shiny/app.R` (33KB)
Original Quarto document: `vignettes/dashboard_shinylive.qmd`

Generated: 2026-01-26
