@echo off
echo Iniciando Chrome con CORS deshabilitado para desarrollo...
echo.
echo IMPORTANTE: Cierra todas las ventanas de Chrome antes de ejecutar este script.
echo.
pause

REM Encuentra la ruta de Chrome
set CHROME_PATH=
if exist "C:\Program Files\Google\Chrome\Application\chrome.exe" (
    set CHROME_PATH=C:\Program Files\Google\Chrome\Application\chrome.exe
) else if exist "C:\Program Files (x86)\Google\Chrome\Application\chrome.exe" (
    set CHROME_PATH=C:\Program Files (x86)\Google\Chrome\Application\chrome.exe
) else (
    echo Chrome no encontrado. Por favor, ejecuta Flutter manualmente.
    pause
    exit /b 1
)

REM Crea directorio temporal para datos de usuario
if not exist "C:\temp\chrome_dev" mkdir "C:\temp\chrome_dev"

REM Inicia Chrome con CORS deshabilitado
start "" "%CHROME_PATH%" --user-data-dir="C:\temp\chrome_dev" --disable-web-security --disable-features=VizDisplayCompositor

echo.
echo Chrome iniciado con CORS deshabilitado.
echo Ahora ejecuta: flutter run -d chrome
echo.
pause

