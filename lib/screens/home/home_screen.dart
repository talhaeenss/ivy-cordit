import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/theme.dart';
import '../../providers/auth_provider.dart';
import '../../providers/chat_provider.dart';

import '../../widgets/brutal_card.dart';
import 'widgets/chat_view.dart';
import '../admin/admin_screen.dart';
import '../../widgets/brutal_nav_bar.dart';
import '../../widgets/brutal_skeleton.dart';
import '../auth/login_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    // Odaları yükle ve socket'i bağla
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final auth = context.read<AuthProvider>();
      if (auth.user != null) {
        // Socket bağlantısını başlat
        // Not: SocketService zaten main'de oluşturuldu, ChatProvider içinde kullanılıyor
        context.read<ChatProvider>().fetchRooms();
      }
    });
  }
  @override
  Widget build(BuildContext context) {
    final chatProvider = context.watch<ChatProvider>();
    final authProvider = context.watch<AuthProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('CORDIT', style: TextStyle(fontWeight: FontWeight.w900)),
        centerTitle: true,
      ),
      drawer: _buildDrawer(context, chatProvider),
      body: _buildBody(chatProvider, authProvider),
      bottomNavigationBar: BrutalNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) => setState(() => _selectedIndex = index),
        items: [
          BrutalNavItem(icon: Icons.chat_bubble, label: 'CHAT'),
          BrutalNavItem(icon: Icons.list, label: 'ROOMS'),
        ],
      ),
    );
  }

  Widget _buildBody(ChatProvider chat, AuthProvider auth) {
    switch (_selectedIndex) {
      case 0:
        return chat.currentRoom == null
            ? _buildNoRoomSelected()
            : ChatView(room: chat.currentRoom!);
      case 1:
        return _buildRoomsView(chat);
      default:
        return _buildNoRoomSelected();
    }
  }

  Widget _buildRoomsView(ChatProvider chat) {
    if (chat.isLoadingRooms) {
      return Column(
        children: [
          const Padding(
            padding: EdgeInsets.all(16.0),
            child: Text('YÜKLENİYOR...', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18)),
          ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: 5,
              itemBuilder: (context, index) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: BrutalSkeleton(height: 60),
              ),
            ),
          ),
        ],
      );
    }

    return Column(
      children: [
        const Padding(
          padding: EdgeInsets.all(16.0),
          child: Text(
            'ODALAR',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900),
          ),
        ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: chat.rooms.length,
            itemBuilder: (context, index) {
              final room = chat.rooms[index];
              final isSelected = chat.currentRoom?.id == room.id;

              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: InkWell(
                  onTap: () {
                    chat.selectRoom(room);
                    setState(() => _selectedIndex = 0); // Chat sekmesine dön
                  },
                  child: BrutalCard(
                    backgroundColor: isSelected ? AppColors.primary : Colors.white,
                    child: Row(
                      children: [
                        Icon(
                          room.isVoice ? Icons.volume_up : Icons.tag,
                          color: isSelected ? Colors.white : Colors.black,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            room.name.toUpperCase(),
                            style: TextStyle(
                              fontWeight: FontWeight.w900,
                              color: isSelected ? Colors.white : Colors.black,
                            ),
                          ),
                        ),
                        if (room.isVoice)
                          const Icon(Icons.record_voice_over, color: AppColors.success, size: 16),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildDrawer(BuildContext context, ChatProvider chat) {
    return Drawer(
      backgroundColor: AppColors.bgMain,
      width: MediaQuery.of(context).size.width * 0.8,
      child: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: BrutalCard(
                child: Column(
                  children: [
                    const Text(
                      'ODALAR',
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900),
                    ),
                    const Divider(color: Colors.black, thickness: 2),
                    if (chat.isLoadingRooms)
                      Column(
                        children: List.generate(
                          3, // Number of skeleton items
                          (index) => Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: BrutalSkeleton(height: 60),
                          ),
                        ),
                      )
                    else if (chat.rooms.isEmpty)
                      const Text('Oda bulunamadı')
                    else
                      const SizedBox.shrink(),
                  ],
                ),
              ),
            ),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: chat.rooms.length,
                itemBuilder: (context, index) {
                  final room = chat.rooms[index];
                  final isSelected = chat.currentRoom?.id == room.id;

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: InkWell(
                      onTap: () {
                        chat.selectRoom(room);
                        Navigator.pop(context); // Drawer'ı kapat
                      },
                      child: BrutalCard(
                        backgroundColor: isSelected ? AppColors.primary : Colors.white,
                        child: Row(
                          children: [
                            Icon(
                              room.isVoice ? Icons.volume_up : Icons.tag,
                              color: isSelected ? Colors.white : Colors.black,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                room.name.toUpperCase(),
                                style: TextStyle(
                                  fontWeight: FontWeight.w900,
                                  color: isSelected ? Colors.white : Colors.black,
                                ),
                              ),
                            ),
                            if (room.isVoice)
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: AppColors.success,
                                  border: Border.all(color: Colors.black, width: 2),
                                ),
                                child: const Text(
                                  'LIVE',
                                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            // Admin Panel Butonu (Sadece adminler için)
            if (context.read<AuthProvider>().user?.isAdmin ?? false)
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: BrutalCard(
                  backgroundColor: AppColors.warning,
                  child: ListTile(
                    leading: const Icon(Icons.admin_panel_settings, color: Colors.black),
                    title: const Text('ADMIN PANEL', style: TextStyle(fontWeight: FontWeight.w900)),
                    onTap: () {
                      Navigator.pop(context); // Drawer'ı kapat
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const AdminScreen()),
                      );
                    },
                  ),
                ),
              ),
            // Çıkış Yap Butonu
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: BrutalCard(
                backgroundColor: AppColors.error,
                child: ListTile(
                  leading: const Icon(Icons.logout, color: Colors.white),
                  title: const Text('ÇIKIŞ YAP', style: TextStyle(fontWeight: FontWeight.w900, color: Colors.white)),
                  onTap: () async {
                    Navigator.pop(context); // Drawer'ı kapat
                    await context.read<AuthProvider>().logout();
                    if (context.mounted) {
                      Navigator.of(context).pushAndRemoveUntil(
                        MaterialPageRoute(builder: (_) => LoginScreen()),
                        (route) => false,
                      );
                    }
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNoRoomSelected() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.chat_bubble_outline, size: 80, color: AppColors.grey),
            const SizedBox(height: 24),
            Text(
              'BİR ODA SEÇİN',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w900,
                color: Colors.black.withAlpha(178),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            const Text(
              'Mesajlaşmaya başlamak için sol taraftaki menüden bir odaya katılın.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.grey),
            ),
          ],
        ),
      ),
    );
  }
}
