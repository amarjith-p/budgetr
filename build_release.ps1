# build_release.ps1
# Budgetr release build script.
#
# --no-tree-shake-icons is REQUIRED because the app loads Material icon
# codepoints from the database at runtime (category icons). Flutter's
# tree-shaker cannot statically determine which icons are used, so we
# include all icon fonts in the release build.
#
# Usage:
#   .\build_release.ps1          → builds APK
#   .\build_release.ps1 appbundle → builds AAB (for Play Store)

param(
    [string]$Target = "apk"
)

$validTargets = @("apk", "appbundle")
if ($Target -notin $validTargets) {
    Write-Error "Invalid target '$Target'. Use 'apk' or 'appbundle'."
    exit 1
}

Write-Host "Building Flutter $Target (no-tree-shake-icons)..." -ForegroundColor Cyan
flutter build $Target --no-tree-shake-icons @args

if ($LASTEXITCODE -eq 0) {
    Write-Host "`nBuild succeeded!" -ForegroundColor Green
} else {
    Write-Host "`nBuild failed." -ForegroundColor Red
    exit $LASTEXITCODE
}

