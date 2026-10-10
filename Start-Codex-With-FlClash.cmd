@echo off
powershell.exe -NoLogo -NoProfile -ExecutionPolicy Bypass -File "%~dp0Start-Codex-With-FlClash.ps1"
if errorlevel 1 pause
