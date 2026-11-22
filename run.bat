@echo off
title Sahabat Masjid - Backend Server
echo ==============================================================
echo   Menjalankan Server Backend Sahabat Masjid (MySQL)
echo ==============================================================

if exist "%LOCALAPPDATA%\Programs\Python\Python312\python.exe" (
    "%LOCALAPPDATA%\Programs\Python\Python312\python.exe" run.py
) else (
    py run.py
)

pause
