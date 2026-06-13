@echo off
setlocal enabledelayedexpansion
chcp 65001 >nul

echo.
echo ==========================================
echo [🛑] CORDIT DURDURULUYOR...
echo ==========================================
echo.

:: 1. ADIM: DİZİNE GİT
cd /d "%~dp0"

:: 2. ADIM: DOCKER KONTEYNERLARINI DURDUR
echo [🔄] Docker konteynerlar durduruluyor...
docker compose down
if %errorlevel% equ 0 (
    echo [✅] Konteynerlar başarıyla durduruldu.
) else (
    echo [❌] Konteynerlar durdurulurken hata oluştu.
)

:: 3. ADIM: DOCKER DESKTOP'I KAPAT
echo.
echo [🐳] Docker Desktop kapatılıyor...
taskkill /F /IM "Docker Desktop.exe" >nul 2>&1
taskkill /F /IM "com.docker.backend.exe" >nul 2>&1
taskkill /F /IM "com.docker.proxy.exe" >nul 2>&1

if %errorlevel% equ 0 (
    echo [✅] Docker Desktop kapatıldı.
) else (
    echo [⚠️] Docker Desktop zaten kapalıydı veya kapatılamadı.
)

echo.
echo ==========================================
echo [🎉] CORDIT VE DOCKER DURDURULDU!
echo ==========================================
echo.
echo [ℹ️] CMD'yi kapatmak için bir tuşa bas...
pause >nul
