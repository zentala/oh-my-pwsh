@echo off
pwsh.exe -NonInteractive -WindowStyle Hidden -ExecutionPolicy Bypass -File "%~dp0daemon.ps1"
