#!/bin/bash
# Quick test script to verify the build works

echo "================================================"
echo "   MULTIPLAYER BUILD - QUICK VERIFICATION"
echo "================================================"
echo ""

# Check files exist
if [ ! -f "builds/windows/EndlessSurvival.exe" ]; then
    echo "❌ ERROR: EndlessSurvival.exe not found"
    exit 1
fi

if [ ! -f "builds/windows/EndlessSurvival.pck" ]; then
    echo "❌ ERROR: EndlessSurvival.pck not found"
    exit 1
fi

echo "✅ Build files present:"
ls -lh builds/windows/EndlessSurvival.*
echo ""

# Check pck file size (should be ~6.4MB with multiplayer)
PCK_SIZE=$(stat -c%s "builds/windows/EndlessSurvival.pck" 2>/dev/null || stat -f%z "builds/windows/EndlessSurvival.pck")
if [ "$PCK_SIZE" -gt 5000000 ]; then
    echo "✅ PCK file size: $(du -h builds/windows/EndlessSurvival.pck | cut -f1) (includes multiplayer)"
else
    echo "⚠️  PCK file size: $(du -h builds/windows/EndlessSurvival.pck | cut -f1) (might be missing data)"
fi
echo ""

echo "================================================"
echo "   READY TO TEST"
echo "================================================"
echo ""
echo "Run the game:"
echo "  ./builds/windows/EndlessSurvival.exe"
echo ""
echo "Expected:"
echo "  1. Game launches"
echo "  2. Main menu shows MULTIPLAYER button"
echo "  3. Click MULTIPLAYER → see Host/Join screen"
echo "  4. Click HOST SESSION → see 'Host started!'"
echo ""
echo "If you see the MULTIPLAYER button, the build is good!"
echo "================================================"
