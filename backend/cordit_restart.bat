@echo off
setlocal enabledelayedexpansion
chcp 65001 >nul

echo.
echo ==========================================
echo [🔄] CORDIT ZORLU YENİDEN BAŞLATMA...
echo ==========================================
echo.

:: 1. ADIM: DOCKER KONTROLÜ
echo [🐳] Docker kontrol ediliyor...
docker info >nul 2>&1
if %errorlevel% neq 0 (
    echo [!] Docker Desktop çalışmıyor gibi görünüyor, lütfen başlatın!
    pause
    exit /b
)

:: 2. ADIM: DİZİNE GİT
cd /d "%~dp0"

:: 3. ADIM: TAM TEMİZLİK
echo [🧹] Eski kalıntılar ve portlar temizleniyor...
:: Hata mesajlarını görmek için nul yönlendirmesini kaldırdım
docker compose down --remove-orphans

:: Portların serbest kalması için kısa bir bekleme
echo [⏳] Portların (7880, 3000, 3001) serbest kalması bekleniyor...
timeout /t 3 /nobreak >nul

:: 4. ADIM: .ENV KONTROLÜ
set "URL_FOUND="
for /f "tokens=2 delims==" %%a in ('findstr /I "FRONTEND_URL" .env') do (
    set "URL_FOUND=%%a"
    set "URL_FOUND=!URL_FOUND: =!"
)

:: 5. ADIM: SIFIRDAN BAŞLAT
echo [🚀] Konteynerlar yeniden build ediliyor ve ateşleniyor...
docker compose up -d --build

if %errorlevel% equ 0 (
    echo.
    echo ==========================================
    echo [🎉] CORDIT BAŞARIYLA AYAĞA KALKTI!
    echo [🔗] Link: !URL_FOUND!
    echo ==========================================
    
    :: Tarayıcıyı aç
    if not "!URL_FOUND!"=="" start "" "!URL_FOUND!"
) else (
    echo.
    echo ==========================================
    echo [❌] HATA: Port çakışması devam ediyor!
    echo [💡] İPUCU: Docker Desktop'ı tamamen kapatıp açmayı deneyin.
    echo ==========================================
)

echo.
echo [ℹ️] CMD'yi kapatmak için bir tuşa bas...
pause >nul
