import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../../config/theme.dart';
import '../../../models/room.dart';
import '../../../models/message.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/chat_provider.dart';
import '../../../providers/voice_provider.dart';
import '../../../widgets/brutal_button.dart';
import '../../../widgets/brutal_input.dart';
import '../../../widgets/brutal_card.dart';
import '../../../widgets/brutal_skeleton.dart';
import 'active_call_bar.dart';

class ChatView extends StatefulWidget {
  final Room room;

  const ChatView({super.key, required this.room});

  @override
  State<ChatView> createState() => _ChatViewState();
}

class _ChatViewState extends State<ChatView> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  void _sendMessage() {
    final content = _messageController.text;
    if (content.trim().isEmpty) return;

    final auth = context.read<AuthProvider>();
    final chat = context.read<ChatProvider>();

    if (auth.user != null) {
      chat.sendMessage(content, auth.user!.username);
      _messageController.clear();
      chat.setTyping(false);
      
      // Mesaj gönderildikten kısa bir süre sonra aşağı kaydır
      Future.delayed(const Duration(milliseconds: 100), _scrollToBottom);
    }
  }

  @override
  Widget build(BuildContext context) {
    final chat = context.watch<ChatProvider>();
    final auth = context.watch<AuthProvider>();

    // Yeni mesaj geldiğinde otomatik aşağı kaydır (eğer en aşağıdaysak veya kendi mesajımızsa)
    // Şimdilik basitçe her mesaj listesi değiştiğinde kaydıralım
    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());

    return Column(
      children: [
        // Oda Başlığı ve Durumu
        _buildHeader(chat, context),

        // Sesli Arama Barı (Eğer bağlıysa ve bu odadaysa)
        const ActiveCallBar(),

        // Mesaj Listesi
        Expanded(
          child: chat.isLoadingMessages
              ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
              : _buildMessageList(chat, auth.user?.username ?? ''),
        ),

        // Yazıyor Göstergesi
        if (chat.typingUser != null)
          _buildTypingIndicator(chat.typingUser!),

        // Input Alanı
        _buildInputArea(),
      ],
    );
  }

  Widget _buildHeader(ChatProvider chat, BuildContext context) {
    final voiceProvider = context.watch<VoiceProvider>();
    final isConnectedToThisRoom = voiceProvider.isConnected && voiceProvider.room?.name == widget.room.id; // livekit room name genellikle room id olur

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Colors.black, width: 2)),
      ),
      child: Row(
        children: [
          Icon(widget.room.isVoice ? Icons.volume_up : Icons.tag, size: 20),
          const SizedBox(width: 8),
          Text(
            widget.room.name.toUpperCase(),
            style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18),
          ),
          const Spacer(),
          if (widget.room.isVoice && !isConnectedToThisRoom)
            BrutalButton(
              onPressed: () {
                // Eğer başka bir odaya bağlıysa önce oradan çıkmalı veya uyarı vermeli
                // Şimdilik direkt katıla basınca diğerinden düşüp buna girecek şekilde provider ayarlı değilse
                // sadece katıl çağırıyoruz.
                 context.read<VoiceProvider>().joinRoom(widget.room.id);
              },
              backgroundColor: AppColors.success,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              isLoading: voiceProvider.isLoading,
              text: 'KATIL',
            ),
          if (widget.room.isVoice && isConnectedToThisRoom)
             const Text("BAĞLANDI", style: TextStyle(color: AppColors.success, fontWeight: FontWeight.w900, fontSize: 12)),
        ],
      ),
    );
  }

  Widget _buildMessageList(ChatProvider chat, String currentUsername) {
    if (chat.isLoadingMessages && chat.messages.isEmpty) {
      return const MessagesSkeleton();
    }

    if (chat.error != null && chat.messages.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 48, color: AppColors.error),
            const SizedBox(height: 16),
            Text(chat.error!, style: const TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            BrutalButton(
              onPressed: () => chat.refreshMessages(),
              text: 'TEKRAR DENE',
              width: 150,
            ),
          ],
        ),
      );
    }

    if (chat.messages.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.forum_outlined, size: 48, color: AppColors.grey),
            const SizedBox(height: 16),
            Text(
              'HENÜZ MESAJ YOK',
              style: TextStyle(fontWeight: FontWeight.w900, color: Colors.black.withAlpha(128)),
            ),
            const Text('İlk mesajı sen gönder!', style: TextStyle(color: AppColors.grey)),
          ],
        ),
      );
    }

    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.all(16),
      itemCount: chat.messages.length,
      itemBuilder: (context, index) {
        final message = chat.messages[index];
        final isMe = message.isOwner(currentUsername);

        return _buildMessageBubble(message, isMe);
      },
    );
  }

  Widget _buildMessageBubble(Message message, bool isMe) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (!isMe)
                Text(
                  message.username,
                  style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 12),
                ),
              if (!isMe) const SizedBox(width: 8),
              Text(
                DateFormat('HH:mm').format(message.createdAt),
                style: const TextStyle(color: AppColors.grey, fontSize: 10),
              ),
              if (isMe) const SizedBox(width: 8),
              if (isMe)
                Text(
                  message.username,
                  style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 12),
                ),
            ],
          ),
          const SizedBox(height: 4),
          Stack(
            clipBehavior: Clip.none,
            children: [
              BrutalCard(
                backgroundColor: message.bubbleColor,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                child: Text(
                  message.content,
                  style: const TextStyle(fontWeight: FontWeight.w500),
                ),
              ),
              if (isMe)
                Positioned(
                  top: -8,
                  right: -8,
                  child: GestureDetector(
                    onTap: () async {
                      final confirmed = await showDialog<bool>(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: const Text('MESAJI SİL?'),
                          content: const Text('Bu mesaj kalıcı olarak silinecek.'),
                          actions: [
                            TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('İPTAL')),
                            TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('SİL', style: TextStyle(color: AppColors.error))),
                          ],
                        ),
                      );
                      if (confirmed == true && mounted) {
                        context.read<ChatProvider>().deleteMessage(message.id);
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: AppColors.white,
                        border: Border.all(color: AppColors.black, width: 2),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.delete_outline, size: 12, color: AppColors.error),
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTypingIndicator(String username) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      alignment: Alignment.centerLeft,
      child: Text(
        '$username yazıyor...',
        style: const TextStyle(
          fontSize: 12,
          fontStyle: FontStyle.italic,
          color: AppColors.grey,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildInputArea() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Colors.black, width: 2)),
      ),
      child: Row(
        children: [
          Expanded(
            child: BrutalInput(
              controller: _messageController,
              hint: 'Mesaj yaz...',
              onChanged: (val) {
                context.read<ChatProvider>().setTyping(val.isNotEmpty);
              },
              onSubmitted: (_) => _sendMessage(),
            ),
          ),
          const SizedBox(width: 12),
          BrutalButton(
            onPressed: _sendMessage,
            backgroundColor: AppColors.primary,
            child: Icon(Icons.send, color: Colors.white),
          ),
        ],
      ),
    );
  }
}
