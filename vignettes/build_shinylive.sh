#!/bin/bash
# Build script for Shinylive vignette

set -e

echo "Building CoMMpass Shinylive Dashboard..."
echo "========================================"

# Check if Quarto is installed
if ! command -v quarto &> /dev/null; then
    echo "ERROR: Quarto is not installed"
    echo "Install from: https://quarto.org/docs/get-started/"
    exit 1
fi

echo "✓ Quarto version: $(quarto --version)"

# Check if Shinylive extension is installed
if ! quarto list extensions | grep -q "shinylive"; then
    echo "Installing Shinylive extension..."
    quarto add quarto-ext/shinylive --no-prompt
fi

echo "✓ Shinylive extension installed"

# Navigate to vignettes directory
cd "$(dirname "$0")"

echo ""
echo "Rendering dashboard_shinylive.qmd..."
echo "This may take 30-60 seconds..."

# Render the document
quarto render dashboard_shinylive.qmd

if [ -f "dashboard_shinylive.html" ]; then
    FILE_SIZE=$(du -h dashboard_shinylive.html | cut -f1)
    echo ""
    echo "✓ Build successful!"
    echo "  Output: dashboard_shinylive.html"
    echo "  Size: $FILE_SIZE"
    echo ""
    echo "Next steps:"
    echo "1. Open dashboard_shinylive.html in browser"
    echo "2. Wait 30-60 seconds for packages to load (first time only)"
    echo "3. Open browser console (F12) to check for errors"
    echo "4. Test all tabs and interactivity"
    echo ""
    echo "To preview with live server:"
    echo "  quarto preview dashboard_shinylive.qmd"
    echo ""
    
    # Offer to open in browser
    read -p "Open in browser now? (y/n) " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        if [[ "$OSTYPE" == "darwin"* ]]; then
            open dashboard_shinylive.html
        elif [[ "$OSTYPE" == "linux-gnu"* ]]; then
            xdg-open dashboard_shinylive.html
        else
            echo "Please open dashboard_shinylive.html manually"
        fi
    fi
else
    echo "ERROR: Build failed - output file not created"
    exit 1
fi

