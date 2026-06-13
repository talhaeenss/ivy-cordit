# Cordit

Modern, neobrutalist tasarımlı gerçek zamanlı sohbet ve sesli görüşme uygulaması.

## Özellikler

- 💬 **Gerçek Zamanlı Mesajlaşma** - Socket.IO ile anlık mesajlaşma
- 🎤 **Sesli Görüşme** - LiveKit entegrasyonu ile yüksek kaliteli sesli sohbet
- 🎨 **Neobrutalist Tasarım** - Cesur renkler, kalın kenarlıklar ve gölgelerle modern UI
- 👥 **Çoklu Oda Desteği** - Farklı odalarda eşzamanlı sohbet
- 🔐 **JWT Kimlik Doğrulama** - Güvenli kullanıcı yönetimi
- 📱 **Cross-Platform** - Android, iOS, Web ve Desktop desteği

## Teknolojiler

### Frontend (Flutter)
- **State Management:** Provider
- **Networking:** HTTP, Socket.IO Client
- **Voice Chat:** LiveKit Client
- **UI:** Custom Neobrutalist Components

### Backend
- Node.js + Express
- Socket.IO
- MongoDB
- LiveKit Server Interface

---

## 🛠 Kurulum ve Yapılandırma

Bu proje iki ana parçadan oluşur: **Backend** (Sunucu) ve **Frontend** (Flutter Uygulaması). Her iki ortam için Local ve Server kurulumları aşağıda detaylandırılmıştır.

### 1. Backend Yapılandırması (`backend/.env`)

Backend dizinindeki `.env` dosyası tüm sistemin beynidir.

#### A. Local (Yerel) Kurulum
Kendi bilgisayarınızda test yaparken:
```env
# URL Ayarları
BACKEND_URL=http://192.168.1.45:3001  # Bilgisayarınızın yerel IP'si
LIVEKIT_URL=ws://192.168.1.45:7880

# CORS (Web testi için kritik)
ALLOWED_ORIGINS=http://localhost:3000,http://192.168.1.45:3000

# Veritabanı
DATABASE_URL=mongodb://localhost:27017/cordit
```

#### B. Server (Sunucu/Production) Kurulum
Canlıya çıkarken:
```env
# URL Ayarları
BACKEND_URL=https://your-backend-domain.com
LIVEKIT_URL=wss://your-livekit-domain.com

# CORS
ALLOWED_ORIGINS=https://your-frontend-domain.com,https://your-backend-domain.com

# Güvenlik (Karmaşık anahtarlar kullanın)
ACCESS_TOKEN_SECRET=your_strong_secret_key
LIVEKIT_API_KEY=your_livekit_key
LIVEKIT_API_SECRET=your_livekit_secret
```
> **Not:** `.env` değişikliğinden sonra backend'i yeniden başlatmayı unutmayın.

---

### 2. Flutter Yapılandırması (`lib/config/app_config.dart`)

Uygulamanın hangi sunucuya bağlanacağını buradan seçersiniz.

#### A. Local (Yerel) Test
Aynı Wi-Fi ağındaki cihazlar için:
```dart
static const String baseUrl = 'http://192.168.1.45:3001';
static const String socketUrl = 'http://192.168.1.45:3001';
static const String livekitUrl = 'ws://192.168.1.45:7880';
```

#### B. Server (Canlı) Bağlantı
Uygulamayı yayınladığınızda veya uzak sunucuyu kullanırken:
```dart
static const String baseUrl = 'https://your-backend-domain.com';
static const String socketUrl = 'https://your-backend-domain.com';
static const String livekitUrl = 'wss://your-livekit-domain.com';
```

---

## 🚀 Çalıştırma Adımları

### Backend İçin:
1. `cd backend`
2. `npm install`
3. `npm run dev` (Local için) veya `npm start` (Server için)

### Flutter İçin:
1. `flutter pub get`
2. Web testi için: `flutter run -d chrome`
3. Mobile testi için: Cihazınızı bağlayın ve `flutter run`

---

## 🔐 Yönetici (Admin) Hesabı
`.env` dosyasındaki `ADMIN_USERNAME` ve `ADMIN_PASSWORD` bilgileri, sistem ilk kurulduğunda otomatik olarak oluşturulan yönetici hesabıdır. Bu hesapla giriş yaparak oda oluşturabilir ve kullanıcıları yönetebilirsiniz.

## Proje Yapısı

```
lib/
├── config/          # Uygulama yapılandırması ve tema
├── models/          # Veri modelleri (User, Room, Message, Invite)
├── providers/       # State management (Auth, Chat, Voice, Admin)
├── screens/         # UI ekranları
├── services/        # API ve Socket servisleri
└── widgets/         # Yeniden kullanılabilir UI bileşenleri
```

---

## 📜 Lisans

**PROPRIETARY LICENSE - ALL RIGHTS RESERVED**

Bu projenin tüm hakları **talhaeens**'e aittir. Kodun izinsiz kopyalanması, dağıtılması veya değiştirilmesi kesinlikle yasaktır. Sadece görüntüleme amaçlıdır.

## 📧 İletişim
Sorularınız için: [talhaeens]


## 📱 Flutter Mobil Uygulama Kurulumu

### Gereksinimler
- Flutter SDK (3.10.7+)
- Dart SDK
- Android Studio / Xcode

### Adımlar

1. **Bağımlılıkları yükleyin:**
```bash
flutter pub get
```

2. **Backend URL'lerini yapılandırın:**

**Yöntem 1: Environment Variables (Önerilen)**
```bash
flutter run --dart-define=API_BASE_URL=http://YOUR_IP:3001 \
           --dart-define=SOCKET_URL=http://YOUR_IP:3001 \
           --dart-define=LIVEKIT_URL=ws://YOUR_IP:7880
```

**Yöntem 2: Config Dosyasını Düzenle**
`lib/config/app_config.dart` dosyasındaki `defaultValue` değerlerini düzenleyin:
```dart
static const String baseUrl = String.fromEnvironment(
  'API_BASE_URL',
  defaultValue: 'http://YOUR_IP:3001', // Buraya backend URL'nizi yazın
);
```

3. **Uygulamayı çalıştırın:**
```bash
flutter run
```

### Android Uygulama Bilgileri
- **Programlama Dili:** Dart (Flutter Framework)
- **Native Android Kod:** Kotlin (android/app/src/main/kotlin/)
- **Minimum SDK:** Android 6.0 (API 23)
- **Target SDK:** Android 14 (API 34)
