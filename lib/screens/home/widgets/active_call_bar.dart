import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../config/theme.dart';
import '../../../providers/voice_provider.dart';
import '../../../widgets/brutal_button.dart';

class ActiveCallBar extends StatelessWidget {
  const ActiveCallBar({super.key});

  @override
  Widget build(BuildContext context) {
    final voiceProvider = context.watch<VoiceProvider>();

    if (!voiceProvider.isConnected) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: AppColors.success.withAlpha(50), // Hafif yeşil arka plan
      child: Row(
        children: [
          const CircleAvatar(
            radius: 4,
            backgroundColor: AppColors.success,
          ),
          const SizedBox(width: 8),
          Text(
            '${voiceProvider.participants.length} kişi (${voiceProvider.activeSpeakers.length} konuşuyor)',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          const Spacer(),
          // Mikrofon Butonu
          BrutalButton(
            onPressed: () => voiceProvider.toggleMic(),
            backgroundColor: voiceProvider.isMicEnabled ? AppColors.white : AppColors.error,
            width: 40,
            height: 36,
            padding: EdgeInsets.zero,
            child: Icon(
              voiceProvider.isMicEnabled ? Icons.mic : Icons.mic_off,
              color: voiceProvider.isMicEnabled ? AppColors.success : AppColors.white,
              size: 20,
            ),
          ),
          const SizedBox(width: 8),
          // Ayrıl Butonu
          BrutalButton(
            onPressed: () => voiceProvider.leaveRoom(),
            backgroundColor: AppColors.bgMain, // Kırmızımsı bir renk olabilir veya gri
            width: 40, // Küçük buton
            height: 36,
            padding: EdgeInsets.zero,
            child: const Icon(Icons.call_end, color: AppColors.error, size: 20),
          ),
        ],
      ),
    );
  }
}
