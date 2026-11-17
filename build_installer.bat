@echo off
call flutter build windows --release
"C:\Program Files (x86)\Inno Setup 6\ISCC.exe" installer\setup.iss
echo.
echo Kurulum dosyasi: installer\output\FRC_Scouting_Setup.exe
pause
