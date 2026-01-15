@echo off
REM EdLab Flutter App Runner
REM Run all or individual entry points

setlocal enabledelayedexpansion

echo.
echo ========================================
echo       EdLab App Runner
echo ========================================
echo.

if "%1"=="" (
    echo Usage: run_app.bat [option]
    echo.
    echo Options:
    echo   1  - Run Admin (Web)
    echo   2  - Run HOD (Head of Department) (Web)
    echo   3  - Run Staff (Web)
    echo   4  - Run Staff Advisor (Web)
    echo   5  - Run Student (App)
    echo   all - Run all 5 entry points
    echo.
    echo Examples:
    echo   run_app.bat 1
    echo   run_app.bat all
    echo.
    goto end
)

REM Validate flutter is installed
flutter --version >nul 2>&1
if errorlevel 1 (
    echo Error: Flutter is not installed or not in PATH
    goto end
)

if /i "%1"=="1" (
    echo Running Admin entry point (Web on Chrome)...
    flutter run -d chrome -t lib/admin/main_admin.dart
) else if /i "%1"=="2" (
    echo Running HOD entry point (Web on Chrome)...
    flutter run -d chrome -t lib/hod/main_hod.dart
) else if /i "%1"=="3" (
    echo Running Staff entry point (Web on Chrome)...
    flutter run -d chrome -t lib/staff/main_staff.dart
) else if /i "%1"=="4" (
    echo Running Staff Advisor entry point (Web on Chrome)...
    flutter run -d chrome -t lib/staff_advisor/main_staff_advisor.dart
) else if /i "%1"=="5" (
    echo Running Student entry point (App)...
    flutter run -t lib/student/main.dart
) else if /i "%1"=="all" (
    echo.
    echo Starting all 5 entry points...
    echo 4 Web instances (Chrome) and 1 App instance.
    echo.
    
    echo [1/5] Starting Admin (Web on Chrome)...
    start flutter run -d chrome -t lib/admin/main_admin.dart
    timeout /t 2 /nobreak
    
    echo [2/5] Starting HOD (Web on Chrome)...
    start flutter run -d chrome -t lib/hod/main_hod.dart
    timeout /t 2 /nobreak
    
    echo [3/5] Starting Staff (Web on Chrome)...
    start flutter run -d chrome -t lib/staff/main_staff.dart
    timeout /t 2 /nobreak
    
    echo [4/5] Starting Staff Advisor (Web on Chrome)...
    start flutter run -d chrome -t lib/staff_advisor/main_staff_advisor.dart
    timeout /t 2 /nobreak
    
    echo [5/5] Starting Student (App)...
    start flutter run -t lib/student/main.dart
    
    echo.
    echo All entry points starting...
) else (
    echo Invalid option: %1
    echo.
    echo Valid options: 1, 2, 3, 4, 5, all
)

:end
pause
