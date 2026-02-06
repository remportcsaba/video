@echo off
cd /d "%~dp0"
set "LOG=%~dp0indulas_log.txt"
echo ===== INDULAS %date% %time% ===== > "%LOG%"
echo Mappa: %cd%>> "%LOG%"
echo start-yt.cmd fut...>> "%LOG%"
call "%~dp0start-yt.cmd" >> "%LOG%" 2>>&1
echo.
echo (Ha bezarodik, nezd meg: %LOG%)
pause
