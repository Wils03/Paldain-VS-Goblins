@echo off
rem Recria os efeitos sonoros retro em Audio\sfx (substitui os .wav gerados).
rem Basta dar dois cliques neste arquivo.

set "GODOT=C:\Users\Wilson\Downloads\Godot_v4.6.2-stable_win64.exe\Godot_v4.6.2-stable_win64_console.exe"

if not exist "%GODOT%" (
    echo Godot nao encontrado em:
    echo   %GODOT%
    echo Edite a linha "set GODOT=" deste arquivo com o caminho certo.
    pause
    exit /b 1
)

cd /d "%~dp0.."
"%GODOT%" --headless --path . --script res://tools/gerar_sfx.gd
echo.
echo Pronto! Os sons estao em Audio\sfx.
pause
