#!/usr/bin/env pwsh

Write-Host "Starting EdLab Student Android App..." -ForegroundColor Green
Write-Host ""

# Check if Flutter is installed
try {
    $flutterVersion = flutter --version 2>$null
    Write-Host "Flutter found!" -ForegroundColor Green
} catch {
    Write-Host "Error: Flutter is not installed or not in PATH" -ForegroundColor Red
    Write-Host "Please install Flutter from https://flutter.dev/docs/get-started/install" -ForegroundColor Yellow
    Read-Host "Press Enter to exit"
    exit 1
}

# Check for connected Android devices
Write-Host "Checking for connected Android devices..." -ForegroundColor Yellow
adb devices

Write-Host ""
Write-Host "Building and running the student app on Android..." -ForegroundColor Green
Write-Host ""

# Run the student app
flutter run -t lib/student/main.dart

Read-Host "Press Enter to exit"