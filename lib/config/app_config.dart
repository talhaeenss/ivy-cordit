/// Cordit uygulama yapılandırması
/// 
/// Kullanım: 
/// - Development için: lib/config/app_config.dart dosyasındaki LOCAL URL'leri kullanın
/// - Production için: Environment variables kullanın veya aşağıdaki production URL'leri uncomment edin
class AppConfig {
  // API URL'leri
  // Geliştirme için kendi backend URL'nizi buraya yazın
  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://localhost:3001', // Varsayılan: localhost
  );
  
  static const String socketUrl = String.fromEnvironment(
    'SOCKET_URL',
    defaultValue: 'http://localhost:3001',
  );
  
  static const String livekitUrl = String.fromEnvironment(
    'LIVEKIT_URL',
    defaultValue: 'ws://localhost:7880',
  );

  // Uygulama bilgileri
  static const String appName = 'Cordit';
  static const String appVersion = '1.0.0';
}

