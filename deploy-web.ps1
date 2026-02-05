# deploy-web.ps1
# Script untuk deploy Flutter Web ke Laravel public folder
# Jalankan: .\deploy-web.ps1
#
# Setelah script selesai, commit dan push Laravel ke VPS:
#   cd C:\xampp\htdocs\buysindo
#   git add .
#   git commit -m "Update Flutter Web"
#   git push origin main

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  DEPLOY FLUTTER WEB KE LARAVEL" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# ============ KONFIGURASI PATH ============
$flutterPath = "E:\projek_flutter\buysindo\buysindo_app"
$laravelPath = "C:\xampp\htdocs\buysindo\public\app"
# ==========================================

# Step 1: Build Flutter Web
Write-Host "[1/3] Building Flutter Web..." -ForegroundColor Yellow
Set-Location $flutterPath
flutter build web --release --base-href "/app/"

if ($LASTEXITCODE -ne 0) {
    Write-Host "ERROR: Flutter build failed!" -ForegroundColor Red
    exit 1
}

Write-Host "Build successful!" -ForegroundColor Green
Write-Host ""

# Step 2: Hapus folder lama
Write-Host "[2/3] Cleaning old files..." -ForegroundColor Yellow
if (Test-Path $laravelPath) {
    Remove-Item -Path "$laravelPath\*" -Recurse -Force
    Write-Host "Old files removed." -ForegroundColor Green
}
Write-Host ""

# Step 3: Copy file baru
Write-Host "[3/3] Copying new build..." -ForegroundColor Yellow
Copy-Item -Path "$flutterPath\build\web\*" -Destination $laravelPath -Recurse -Force
Write-Host "Files copied successfully!" -ForegroundColor Green
Write-Host ""

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  DEPLOY COMPLETE!" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Flutter Web sudah di-deploy ke:" -ForegroundColor White
Write-Host "  $laravelPath" -ForegroundColor Gray
Write-Host ""
Write-Host "Langkah selanjutnya - push ke VPS:" -ForegroundColor Yellow
Write-Host "  cd C:\xampp\htdocs\buysindo" -ForegroundColor Gray
Write-Host "  git add ." -ForegroundColor Gray
Write-Host "  git commit -m 'Update Flutter Web'" -ForegroundColor Gray
Write-Host "  git push origin main" -ForegroundColor Gray
Write-Host ""
