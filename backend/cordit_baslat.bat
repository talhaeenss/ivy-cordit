@echo off
setlocal enabledelayedexpansion
chcp 65001 >nul

:: 1. ADIM: DOCKER KONTROLÜ
echo [🐳] Docker kontrol ediliyor...
docker info >nul 2>&1
if %errorlevel% neq 0 (
    echo [!] Docker kapalıymış moruk, uyandırıyorum...
    start "" "C:\Program Files\Docker\Docker\Docker Desktop.exe"
    echo [⏳] Docker'ın uyanması için 30 saniye bekliyorum...
    timeout /t 30 /nobreak
) else (
    echo [✅] Docker zaten uyanık.
)

:: 2. ADIM: DİZİNE GİT
cd /d "%~dp0"

:: 3. ADIM: .ENV KONTROLÜ
set "URL_FOUND="
for /f "tokens=2 delims==" %%a in ('findstr /I "FRONTEND_URL" .env') do (
    set "URL_FOUND=%%a"
    :: URL'nin sonundaki boşlukları temizleyelim
    set "URL_FOUND=!URL_FOUND: =!"
)

:: 4. ADIM: SERVER RESET VE BAŞLATMA
echo [🔄] Eski konteynerlar temizleniyor ve server ateşleniyor...
docker compose down >nul 2>&1
docker compose up -d --build

:: 5. ADIM: TARAYICIDA AÇ VE RAPOR VER
echo.
echo ==========================================
echo [🎉] CORDIT AYAKTA!
echo [🔗] Link: !URL_FOUND!
echo ==========================================

:: Tarayıcıyı zorla açmak için start komutunu URL ile tetikleyelim
start "" "!URL_FOUND!"

echo [ℹ️] CMD'yi kapatmak için bir tuşa bas cano...
pause >nul