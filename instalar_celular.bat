@echo off
cd /d "%~dp0"

echo =======================================================
echo          NFC Ops - Instalador no Celular Android
echo =======================================================
echo.

set "ADB_PATH="
if exist "C:\Android\sdk\platform-tools\adb.exe" (
    set "ADB_PATH=C:\Android\sdk\platform-tools\adb.exe"
) else if exist "%LOCALAPPDATA%\Android\Sdk\platform-tools\adb.exe" (
    set "ADB_PATH=%LOCALAPPDATA%\Android\Sdk\platform-tools\adb.exe"
) else (
    set "ADB_PATH=adb"
)

echo [1/3] Verificando conexao com o aparelho...
echo Executavel ADB: %ADB_PATH%
echo.

"%ADB_PATH%" devices
echo.

echo [2/3] Compilando e gerando APK atualizado...
call flutter build apk --debug
if errorlevel 1 (
    echo.
    echo [ERRO] Falha ao compilar o APK Flutter.
    pause
    exit /b 1
)

set "APK_FILE=build\app\outputs\flutter-apk\app-debug.apk"
echo.
echo [3/3] Instalando no celular e abrindo...
"%ADB_PATH%" install -r "%APK_FILE%"
if errorlevel 1 (
    echo.
    echo [ERRO] Falha ao instalar via ADB.
    pause
    exit /b 1
)

"%ADB_PATH%" shell monkey -p com.example.nfc_ops -c android.intent.category.LAUNCHER 1 > nul 2>&1

echo.
echo =======================================================
echo       NFC Ops instalado e aberto com sucesso!
echo =======================================================
echo.
pause