@echo off
SETLOCAL EnableDelayedExpansion

echo ===========================================
echo   Instalador de pin2top para PopUp WEB
echo ===========================================

:: Verificar permisos de administrador
net session >nul 2>&1
if %errorLevel% == 0 (
    echo [OK] Ejecutando con permisos de administrador.
) else (
    echo [ERROR] Por favor, ejecuta este archivo como ADMINISTRADOR.
    pause
    exit /b
)

:: Obtener la ruta actual de la carpeta
set "CURRENT_DIR=%~dp0"
set "EXE_PATH=%CURRENT_DIR%pin2top.exe"
set "JSON_PATH=%CURRENT_DIR%com.popupweb.pin2top.json"

:: Reemplazar las barras invertidas simples por dobles para el JSON (formato requerido por Chrome)
set "ESCAPED_EXE_PATH=%EXE_PATH:\=\\%"

:: Crear/Actualizar el archivo JSON con la ruta absoluta correcta
echo { > "%JSON_PATH%"
echo   "name": "com.popupweb.pin2top", >> "%JSON_PATH%"
echo   "description": "Puente para fijar ventanas de PopUp WEB", >> "%JSON_PATH%"
echo   "path": "%ESCAPED_EXE_PATH%", >> "%JSON_PATH%"
echo   "type": "stdio", >> "%JSON_PATH%"
echo   "allowed_origins": [ >> "%JSON_PATH%"
echo     "chrome-extension://*/*" >> "%JSON_PATH%"
echo   ] >> "%JSON_PATH%"
echo } >> "%JSON_PATH%"

:: Registrar en Google Chrome
REG ADD "HKEY_CURRENT_USER\Software\Google\Chrome\NativeMessagingHosts\com.popupweb.pin2top" /ve /t REG_SZ /d "%JSON_PATH%" /f

:: Registrar en Microsoft Edge (por si acaso)
REG ADD "HKEY_CURRENT_USER\Software\Microsoft\Edge\NativeMessagingHosts\com.popupweb.pin2top" /ve /t REG_SZ /d "%JSON_PATH%" /f

echo.
echo ===========================================
echo   INSTALACION COMPLETADA
echo ===========================================
echo.
echo 1. Asegurate de que pin2top.exe este en esta carpeta.
echo 2. Reinicia tu navegador.
echo 3. ¡Listo para usar!
echo.
pause