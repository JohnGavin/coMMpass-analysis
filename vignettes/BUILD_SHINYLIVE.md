# Building and Testing the Shinylive Dashboard

This document provides instructions for building and testing the CoMMpass Shinylive dashboard.

## Prerequisites

1. **Quarto** (version 1.4 or higher)
   ```bash
   # Check if Quarto is installed
   quarto --version
   
   # If not installed, download from https://quarto.org/docs/get-started/
   ```

2. **Shinylive Quarto Extension**
   ```bash
   # Install the Shinylive extension
   quarto add quarto-ext/shinylive
   ```

## Building Locally

### Option 1: Render Single Document

```bash
# From project root
cd vignettes
quarto render dashboard_shinylive.qmd

# Output will be in dashboard_shinylive.html
```

### Option 2: Preview with Live Server

```bash
# From vignettes directory
quarto preview dashboard_shinylive.qmd

# This will open a browser with live reload
# Navigate to http://localhost:XXXX
```

## Testing in Browser (MANDATORY)

**DO NOT skip this step!** Always test in browser before committing.

### 1. Build the Document

```bash
cd /Users/johngavin/docs_gh/proj/data/coMMpass/vignettes
quarto render dashboard_shinylive.qmd
```

### 2. Open in Browser

```bash
# macOS
open dashboard_shinylive.html

# Linux
xdg-open dashboard_shinylive.html

# Or drag the file into your browser
```

### 3. Check Browser Console (F12)

**Critical checks:**

1. **Wait for load** (30-60 seconds first time)
2. **Open DevTools** (F12 or Cmd+Option+I on Mac)
3. **Check Console tab** for errors

#### Expected Console Output

```
✓ Loading webR...
✓ Downloading packages: shiny, bslib, plotly, DT, dplyr, ggplot2, survival
✓ Initializing Shinylive...
✓ App running
```

#### Common Errors and Fixes

| Error | Cause | Fix |
|-------|-------|-----|
| `404 on package.data` | Package not in webR | Remove package or use alternative |
| `CORS error` | Wrong URL | Check file:// vs http:// protocol |
| `Service worker registration failed` | Missing sw file | Check `resources:` in YAML |
| `SharedArrayBuffer undefined` | COOP/COEP headers | Normal for local files |
| App doesn't load | JavaScript error | Check console for stack trace |

### 4. Test All Tabs

Once loaded, test each tab:

- [ ] **Overview** - Page displays correctly
- [ ] **Data** - Click "Load Example Data", verify table appears
- [ ] **Quality Control** - Verify plots render (library size, PCA)
- [ ] **Differential Expression** - Check volcano plot, change thresholds
- [ ] **Survival Analysis** - Verify Kaplan-Meier curves render
- [ ] **Pathway Analysis** - Check enrichment bar plot and GSEA

### 5. Test Interactivity

- [ ] Hover over points in plots (tooltips appear)
- [ ] Change thresholds in DE tab (plots update)
- [ ] Switch between survival groups (curves update)
- [ ] Filter/sort tables

## File Size Considerations

Shinylive apps can become large. Current file size:

```bash
# Check size
ls -lh dashboard_shinylive.html

# Check for large embedded resources
grep -o "data:application/.*;" dashboard_shinylive.html | head -5
```

**Typical sizes:**
- HTML file: 50-100 KB (code only)
- After first load with packages: ~30 MB cached in browser
- Each package download: 2-10 MB

## Deployment Options

### Option 1: GitHub Pages

1. Build the vignette
2. Copy `dashboard_shinylive.html` to `docs/` directory
3. Enable GitHub Pages in repo settings
4. Access at: `https://username.github.io/repo/dashboard_shinylive.html`

### Option 2: Include in pkgdown Site

Add to `_pkgdown.yml`:

```yaml
articles:
- title: Interactive Dashboards
  contents:
  - dashboard_shinylive
```

Then build site:

```r
pkgdown::build_site()
```

### Option 3: Standalone HTML

Simply share the `dashboard_shinylive.html` file. It's completely self-contained and can be:
- Emailed
- Hosted on any web server
- Opened directly from disk (with some limitations)

## Troubleshooting

### App Loads but No Data

**Check:** Did you click "Load Example Data" button?

The app starts empty. You must explicitly load data in the Data tab.

### Plots Not Rendering

**Check console for:**
- Missing packages (install via Shinylive)
- JavaScript errors in plot rendering
- Data not loaded (click Load Data first)

### Slow First Load

**Normal behavior.** First load downloads:
- shiny (~5 MB)
- bslib (~2 MB)
- plotly (~8 MB)
- DT (~3 MB)
- dplyr (~4 MB)
- ggplot2 (~5 MB)
- survival (~2 MB)

Total: ~30 MB. Browser caches these for future visits.

### Service Worker Errors

If you see "Failed to register service worker":

1. Check that `shinylive-sw.js` is in resources
2. Try serving via HTTP server (not file://)
3. Check browser console for specific error

```bash
# Serve locally with Python
python3 -m http.server 8000

# Then open http://localhost:8000/dashboard_shinylive.html
```

## Package Dependencies

Packages used and their webR availability:

| Package | Status | Size | Notes |
|---------|--------|------|-------|
| shiny | ✓ Available | ~5 MB | Core framework |
| bslib | ✓ Available | ~2 MB | Bootstrap theming |
| plotly | ✓ Available | ~8 MB | Interactive plots |
| DT | ✓ Available | ~3 MB | Data tables |
| dplyr | ✓ Available | ~4 MB | Data manipulation |
| tidyr | ✓ Available | ~1 MB | Data tidying |
| ggplot2 | ✓ Available | ~5 MB | Static plots |
| survival | ✓ Available | ~2 MB | Survival analysis |

**Not used (too large or unavailable):**
- survminer (not in webR)
- tidyverse (too large, use individual packages)
- DESeq2, edgeR, limma (Bioconductor, not in standard webR)

## Performance Optimization

To reduce file size:

1. **Limit number of genes in examples** (currently 500)
2. **Reduce number of samples** (currently 40)
3. **Remove unused modules**
4. **Simplify plot aesthetics**

Current settings balance:
- Realistic analysis experience
- Reasonable load time
- Browser memory usage

## Version Information

Document the versions used:

```r
# In R console
packageVersion("shiny")
packageVersion("plotly")
packageVersion("survival")
```

WebR uses package versions from CRAN snapshots, usually ~1-2 months behind latest.

## Next Steps

After successful browser test:

1. Commit the `.qmd` source file
2. Add to vignettes in DESCRIPTION
3. Update README with link to live demo
4. Deploy to GitHub Pages or pkgdown site

## Support

For issues:
- Shinylive documentation: https://shiny.posit.co/py/docs/shinylive.html
- Quarto Shinylive: https://quarto-ext.github.io/shinylive/
- WebR documentation: https://docs.r-wasm.org/webr/latest/

