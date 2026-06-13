import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'config/theme.dart';
import 'providers/auth_provider.dart';
import 'providers/chat_provider.dart';
import 'services/chat_api_service.dart';
import 'services/socket_service.dart';
import 'services/voice_service.dart';
import 'providers/voice_provider.dart';
import 'services/admin_api_service.dart';
import 'providers/admin_provider.dart';
import 'screens/auth/splash_screen.dart';

void main() {
  runApp(const CorditApp());
}

class CorditApp extends StatelessWidget {
  const CorditApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        Provider(create: (_) => SocketService()),
        ChangeNotifierProvider(create: (_) => VoiceService()),
        ProxyProvider2<AuthProvider, SocketService, ChatApiService>(
          update: (context, auth, socket, previous) => ChatApiService(token: auth.user?.token),
        ),
        ProxyProvider<AuthProvider, AdminApiService>(
          update: (context, auth, previous) => AdminApiService(token: auth.user?.token),
        ),
        ChangeNotifierProxyProvider2<ChatApiService, SocketService, ChatProvider>(
          create: (context) => ChatProvider(
            context.read<ChatApiService>(),
            context.read<SocketService>(),
          ),
          update: (context, api, socket, chat) => chat!..updateApiService(api),
        ),
        ChangeNotifierProxyProvider2<VoiceService, ChatApiService, VoiceProvider>(
          create: (context) => VoiceProvider(
            context.read<VoiceService>(),
            context.read<ChatApiService>(),
          ),
          update: (context, voiceService, apiService, voiceProvider) => voiceProvider!..updateApiService(apiService),
        ),
        ChangeNotifierProxyProvider<AdminApiService, AdminProvider>(
          create: (context) => AdminProvider(context.read<AdminApiService>()),
          update: (context, api, previous) => previous!..updateApiService(api),
        ),
      ],
      child: MaterialApp(
        title: 'Cordit',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        home: const SplashScreen(),
      ),
    );
  }
}
