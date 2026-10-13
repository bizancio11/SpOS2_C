@echo off
setlocal
chcp 65001 >nul
cd /d "%~dp0"
title SpOS2 - construir 3 ISOs (N / Programer / Premium)

if not exist "app\main.py"  (echo Falta app\main.py & goto :fin)
if not exist "app\core.py"  (echo Falta app\core.py - copia TODO tu proyecto SpOS2 dentro de la carpeta app & goto :fin)
if not exist "app\logo.png" (echo Falta app\logo.png - copia TODO tu proyecto SpOS2 dentro de la carpeta app & goto :fin)

wsl --status >nul 2>&1
if errorlevel 1 goto :instalar
wsl -l -q 2>nul | findstr /r /c:"." >nul
if errorlevel 1 goto :instalar
goto :construir

:instalar
echo WSL/Ubuntu no esta instalado. Instalando (pide permisos de administrador)...
powershell -Command "Start-Process wsl -ArgumentList '--install','-d','Ubuntu' -Verb RunAs"
echo.
echo Cuando termine, REINICIA Windows, abre Ubuntu una vez para crear tu usuario
echo y vuelve a ejecutar este archivo.
goto :fin

:construir
set "WSLDIR="
for /f "delims=" %%i in ('wsl wslpath -a "%CD%"') do set "WSLDIR=%%i"
if "%WSLDIR%"=="" (echo No se pudo obtener la ruta en WSL & goto :fin)
echo Construyendo las 3 ISOs (tarda bastante, necesita internet)...
wsl -u root bash "%WSLDIR%/wsl_build.sh" "%WSLDIR%"
if errorlevel 1 (echo. & echo ERROR: la construccion fallo. Copia el mensaje de arriba.) else (echo. & echo Listo: SpOS2_N.iso, SpOS2_Programer.iso y SpOS2_Premium.iso estan en esta carpeta.)

:fin
echo.
pause
