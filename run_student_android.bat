@echo off
echo Starting EdLab Student Android App...
echo.

REM Check if Flutter is installed
flutter --version >nul 2>&1
if %errorlevel% neq 0 (
    echo Error: Flutter is not installed or not in PATH
    echo Please install Flutter from https://flutter.dev/docs/get-started/install
    pause
    exit /b 1
)

REM Check if Android device/emulator is connected
echo Checking for connected Android devices...
adb devices

echo.
echo Building and running the student app on Android...
echo.

REM Run the student app
flutter run -t lib/student/main.dart

pause