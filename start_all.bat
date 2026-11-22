@echo off
title Sahabat Masjid - Launcher
echo ==============================================================
echo   MEMULAI SISTEM SAHABAT MASJID (BACKEND & FRONTEND)
echo ==============================================================

set PYTHON_BIN="%LOCALAPPDATA%\Programs\Python\Python312\python.exe"
if not exist %PYTHON_BIN% (
    set PYTHON_BIN=py
)

echo [1/2] Menjalankan Backend Python (Port 8000)...
start "Sahabat Masjid - Backend" %PYTHON_BIN% run.py

timeout /t 2 /nobreak >nul

echo [2/2] Menjalankan Frontend Web (Port 3000)...
start "Sahabat Masjid - Frontend" %PYTHON_BIN% -m http.server 3000 --directory frontend/web

timeout /t 1 /nobreak >nul

echo Membuka aplikasi di browser...
start http://localhost:3000

echo ==============================================================
echo   Sistem berhasil dijalankan!
echo   Frontend : http://localhost:3000
echo   Backend  : http://localhost:8000
echo ==============================================================
