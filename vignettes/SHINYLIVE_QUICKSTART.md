# Shinylive Dashboard - Quick Start Guide

## 1. Build the Dashboard

```bash
# From project root
cd vignettes
./build_shinylive.sh

# Or manually
quarto render dashboard_shinylive.qmd
```

## 2. Test in Browser

```bash
# Open the HTML file
open dashboard_shinylive.html  # macOS
xdg-open dashboard_shinylive.html  # Linux
```

**WAIT 30-60 seconds for packages to download (first time only)**

## 3. Check Browser Console (MANDATORY)

1. Press `F12` (or `Cmd+Option+I` on Mac)
2. Click **Console** tab
3. Look for errors

**Expected:**
```
✓ Loading webR...
✓ Downloading packages...
✓ App running
```

**If you see errors:**
- Check `BUILD_SHINYLIVE.md` troubleshooting section
- Ensure all packages downloaded successfully
- Try serving via HTTP: `python3 -m http.server 8000`

## 4. Test All Features

- [ ] Click "Load Example Data" in Data tab
- [ ] Navigate to each tab (Overview, Data, QC, DE, Survival, Pathways)
- [ ] Hover over plot points (tooltips should appear)
- [ ] Adjust sliders in DE tab (plots should update)
- [ ] Change survival groups (curves should update)
- [ ] Sort/filter tables

## 5. Deploy (Optional)

**GitHub Pages:**
```bash
cp dashboard_shinylive.html ../docs/
git add ../docs/dashboard_shinylive.html
git commit -m "Add Shinylive dashboard"
git push
# Enable Pages in repo settings
```

**pkgdown:**
```r
# Already configured in _pkgdown.yml
pkgdown::build_site()
```

## Common Issues

| Problem | Solution |
|---------|----------|
| App doesn't load | Wait 60 seconds, check console for errors |
| 404 on packages | Package not in webR, remove or replace |
| No plots | Click "Load Example Data" first |
| Slow performance | Reduce number of genes/samples in example data |
| Service worker error | Normal for local files, use HTTP server |

## Quick Commands

```bash
# Build
quarto render dashboard_shinylive.qmd

# Preview with live reload
quarto preview dashboard_shinylive.qmd

# Check file size
ls -lh dashboard_shinylive.html

# Serve locally
python3 -m http.server 8000
# Then open http://localhost:8000/dashboard_shinylive.html
```

## File Structure

```
vignettes/
├── dashboard_shinylive.qmd           # Source (edit this)
├── dashboard_shinylive.html          # Built output (56 KB)
├── dashboard_shinylive_files/        # Support files (auto-generated)
├── build_shinylive.sh                # Build script
├── BUILD_SHINYLIVE.md                # Full documentation
└── SHINYLIVE_QUICKSTART.md          # This file
```

## Help

- Full docs: `BUILD_SHINYLIVE.md`
- Shinylive: https://shiny.posit.co/py/docs/shinylive.html
- Quarto: https://quarto-ext.github.io/shinylive/

