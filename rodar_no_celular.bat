@echo off
cd /d "%~dp0"

echo =======================================================
echo     NFC Ops - Executar com Hot Reload no Celular
echo =======================================================
echo.
echo Iniciando no dispositivo conectado...
echo Dica: Pressione "r" no terminal para Hot Reload instantaneo
echo       Pressione "R" para Hot Restart
echo       Pressione "q" para sair
echo.

call flutter run -d android
if errorlevel 1 (
    echo.
    echo Ocorreu um erro ao executar no celular.
)
pause