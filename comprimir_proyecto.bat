@echo off
echo ========================================
echo Compresor de Proyecto Flutter
echo ========================================
echo.

REM Cambiar al directorio padre
cd /d "%~dp0\.."

REM Obtener nombre de carpeta sin caracteres especiales
set "FOLDER_NAME=parte_movil"
set "ZIP_NAME=ParteMovil_Barberia_%date:~-4,4%%date:~-7,2%%date:~-10,2%_%time:~0,2%%time:~3,2%%time:~6,2%"
set "ZIP_NAME=%ZIP_NAME: =0%"

echo Limpiando proyecto antes de comprimir...
call "parte_movil\limpiar_antes_de_comprimir.bat"

echo.
echo ========================================
echo Comprimiendo proyecto...
echo ========================================
echo.

REM Verificar si PowerShell está disponible
where powershell >nul 2>&1
if %errorlevel% equ 0 (
    echo Usando PowerShell para comprimir...
    powershell -NoProfile -ExecutionPolicy Bypass -Command "Compress-Archive -Path 'parte_movil' -DestinationPath '%ZIP_NAME%.zip' -Force"
    if %errorlevel% equ 0 (
        echo.
        echo ========================================
        echo Compresion completada exitosamente!
        echo ========================================
        echo.
        echo Archivo creado: %ZIP_NAME%.zip
        echo Ubicacion: %CD%
        echo.
    ) else (
        echo.
        echo ERROR: No se pudo comprimir con PowerShell.
        echo.
        echo SOLUCIONES ALTERNATIVAS:
        echo 1. Usa WinRAR o 7-Zip manualmente
        echo 2. Cierra todos los programas que puedan estar usando archivos
        echo 3. Ejecuta este script como Administrador
        echo.
    )
) else (
    echo PowerShell no disponible.
    echo.
    echo Por favor, comprime manualmente la carpeta 'parte_movil'
    echo usando WinRAR, 7-Zip o el compresor de Windows.
    echo.
)

pause

