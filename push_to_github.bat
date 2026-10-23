@echo off
title Push Oi Toto to GitHub (oitoto.in)
color 0B
echo ===================================================================
echo     Pushing Oi Toto Project to GitHub: shakilnasirul-beep/oitoto.in
echo ===================================================================
echo.
cd /d G:\oitoto
"%LOCALAPPDATA%\MinGit\cmd\git.exe" push -u origin main
if %errorlevel% equ 0 (
    echo.
    echo ===================================================================
    echo   [SUCCESS] Code pushed to GitHub successfully!
    echo ===================================================================
    echo Now open: https://github.com/shakilnasirul-beep/oitoto.in/actions
    echo Your Customer APK and Driver APK are now building automatically!
) else (
    echo.
    echo [INFO] If prompted for username/password:
    echo Username: shakilnasirul-beep
    echo Password: Use a GitHub Personal Access Token (PAT)
    echo (Generate at: https://github.com/settings/tokens)
)
echo.
pause
