@echo off
setlocal
chcp 932 > nul

REM 実行ファイルのディレクトリへ移動
cd /d "%~dp0"

REM PowerShellスクリプトの実行
powershell -NoProfile -ExecutionPolicy Bypass -File ".\generate-readme.ps1"

echo.
echo 処理が完了しました。
pause