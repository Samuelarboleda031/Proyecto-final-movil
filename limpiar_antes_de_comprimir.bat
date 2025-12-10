@echo off
echo ========================================
echo Limpiando proyecto antes de comprimir
echo ========================================
echo.

REM Cambiar al directorio del proyecto
cd /d "%~dp0"

echo [1/5] Limpiando archivos de build de Flutter...
if exist build rmdir /s /q build
if exist .dart_tool rmdir /s /q .dart_tool
if exist .flutter-plugins del /q .flutter-plugins 2>nul
if exist .flutter-plugins-dependencies del /q .flutter-plugins-dependencies 2>nul
if exist .packages del /q .packages 2>nul
if exist pubspec.lock del /q pubspec.lock 2>nul

echo [2/5] Limpiando archivos temporales de Android...
if exist android\.gradle rmdir /s /q android\.gradle 2>nul
if exist android\app\build rmdir /s /q android\app\build 2>nul
if exist android\build rmdir /s /q android\build 2>nul
if exist android\.idea rmdir /s /q android\.idea 2>nul
if exist android\local.properties del /q android\local.properties 2>nul

echo [3/5] Limpiando archivos temporales de iOS...
if exist ios\Pods rmdir /s /q ios\Pods 2>nul
if exist ios\.symlinks rmdir /s /q ios\.symlinks 2>nul
if exist ios\Flutter\Flutter.framework rmdir /s /q ios\Flutter\Flutter.framework 2>nul
if exist ios\Flutter\Flutter.podspec del /q ios\Flutter\Flutter.podspec 2>nul

echo [4/5] Limpiando archivos temporales de otros sistemas...
if exist windows\build rmdir /s /q windows\build 2>nul
if exist linux\build rmdir /s /q linux\build 2>nul
if exist macos\Flutter\ephemeral rmdir /s /q macos\Flutter\ephemeral 2>nul
if exist web\build rmdir /s /q web\build 2>nul

echo [5/5] Limpiando archivos de IDE...
if exist .idea rmdir /s /q .idea 2>nul
if exist .vscode rmdir /s /q .vscode 2>nul
if exist *.iml del /q *.iml 2>nul

echo.
echo ========================================
echo Limpieza completada!
echo ========================================
echo.
echo El proyecto esta listo para comprimir.
echo Puedes comprimir la carpeta 'parte_movil' ahora.
echo.
echo Archivos excluidos del proyecto:
echo - build/
echo - .dart_tool/
echo - android/build/
echo - ios/Pods/
echo - Archivos temporales de IDE
echo.
pause

