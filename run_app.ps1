#!/usr/bin/env pwsh
# EdLab Flutter App Runner (PowerShell version)
# Run all or individual entry points

param(
    [Parameter(ValueFromRemainingArguments=$true)]
    [string]$Option
)

$ErrorActionPreference = "Stop"

# Define entry points
$EntryPoints = @{
    "1" = @{
        name = "Admin"
        path = "lib/admin/main_admin.dart"
    }
    "2" = @{
        name = "HOD (Head of Department)"
        path = "lib/hod/main_hod.dart"
    }
    "3" = @{
        name = "Staff"
        path = "lib/staff/main_staff.dart"
    }
    "4" = @{
        name = "Staff Advisor"
        path = "lib/staff_advisor/main_staff_advisor.dart"
    }
    "5" = @{
        name = "Student"
        path = "lib/student/main.dart"
    }
}

function Show-Help {
    Write-Host ""
    Write-Host "========================================"
    Write-Host "       EdLab App Runner"
    Write-Host "========================================"
    Write-Host ""
    Write-Host "Usage: .\run_app.ps1 [option]"
    Write-Host ""
    Write-Host "Options:"
    Write-Host "  1   - Run Admin (Web)"
    Write-Host "  2   - Run HOD (Head of Department) (Web)"
    Write-Host "  3   - Run Staff (Web)"
    Write-Host "  4   - Run Staff Advisor (Web)"
    Write-Host "  5   - Run Student (App)"
    Write-Host "  all - Run all 5 entry points"
    Write-Host ""
    Write-Host "Examples:"
    Write-Host "  .\run_app.ps1 1"
    Write-Host "  .\run_app.ps1 all"
    Write-Host ""
}

function Test-Flutter {
    try {
        flutter --version | Out-Null
        return $true
    } catch {
        return $false
    }
}

function Run-EntryPoint {
    param(
        [string]$Key
    )
    
    $entry = $EntryPoints[$Key]
    
    if ($Key -eq "5") {
        Write-Host "Running $($entry.name) entry point (App)..." -ForegroundColor Cyan
        Write-Host "Path: $($entry.path)" -ForegroundColor Gray
        & flutter run -t $entry.path
    } else {
        Write-Host "Running $($entry.name) entry point (Web on Chrome)..." -ForegroundColor Cyan
        Write-Host "Path: $($entry.path)" -ForegroundColor Gray
        & flutter run -d chrome -t $entry.path
    }
}

function Run-All {
    Write-Host ""
    Write-Host "Starting all 4 web entry points..." -ForegroundColor Green
    Write-Host "4 Web instances (Chrome)." -ForegroundColor Yellow
    Write-Host ""
    
    foreach ($key in @("1", "2", "3", "4")) {
        $entry = $EntryPoints[$key]
        
        Write-Host "[$key/4] Starting $($entry.name) (Web on Chrome)..." -ForegroundColor Cyan
        Start-Process -NoNewWindow -FilePath "flutter" -ArgumentList "run -d chrome -t $($entry.path)"
        
        # Brief delay between starts
        Start-Sleep -Seconds 2
    }
    
    Write-Host ""
    Write-Host "All web entry points started in separate windows." -ForegroundColor Green
}

# Main logic
if (-not $Option -or $Option -eq "help" -or $Option -eq "-h" -or $Option -eq "--help") {
    Show-Help
    exit 0
}

# Check Flutter
if (-not (Test-Flutter)) {
    Write-Host "Error: Flutter is not installed or not in PATH" -ForegroundColor Red
    exit 1
}

switch ($Option.ToLower()) {
    "1" { Run-EntryPoint "1" }
    "2" { Run-EntryPoint "2" }
    "3" { Run-EntryPoint "3" }
    "4" { Run-EntryPoint "4" }
    "5" { Run-EntryPoint "5" }
    "all" { Run-All }
    default {
        Write-Host "Invalid option: $Option" -ForegroundColor Red
        Write-Host ""
        Write-Host "Valid options: 1, 2, 3, 4, 5, all" -ForegroundColor Yellow
        Show-Help
        exit 1
    }
}
