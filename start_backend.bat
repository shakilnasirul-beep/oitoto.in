@echo off
title Oi Toto! - REST API Server (Port 8000)
color 0A
echo ===================================================================
echo     Oi Toto! — Tap. Book. Cholo! (Backend REST API)
echo ===================================================================
echo.
echo [1/2] Checking MySQL connection...
C:\xampp\mysql\bin\mysqladmin.exe -u root ping >nul 2>&1
if %errorlevel% neq 0 (
    echo [WARNING] MySQL is not running!
    echo Please open XAMPP Control Panel and start MySQL service.
    echo.
) else (
    echo [OK] MySQL is running and connected!
)

echo [2/2] Starting PHP API Server on 0.0.0.0:8000 ...
echo [INFO] Accessible locally at: http://localhost:8000
echo [INFO] Accessible from phone on Wi-Fi at: http://192.168.1.10:8000
echo Press Ctrl + C to stop the server anytime.
echo.
cd /d G:\oitoto\backend
C:\php82\php.exe -S 0.0.0.0:8000 -t public
pause
