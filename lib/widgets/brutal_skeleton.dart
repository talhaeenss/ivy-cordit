import 'package:flutter/material.dart';
import '../config/theme.dart';

class BrutalSkeleton extends StatefulWidget {
  final double width;
  final double height;
  final double borderRadius;

  const BrutalSkeleton({
    super.key,
    this.width = double.infinity,
    this.height = 20,
    this.borderRadius = 0,
  });

  @override
  State<BrutalSkeleton> createState() => _BrutalSkeletonState();
}

class _BrutalSkeletonState extends State<BrutalSkeleton> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat(reverse: true);
    _animation = Tween<double>(begin: 0.3, end: 0.6).animate(_controller);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Opacity(
          opacity: _animation.value,
          child: Container(
            width: widget.width,
            height: widget.height,
            decoration: BoxDecoration(
              color: AppColors.grey.withAlpha(50),
              border: Border.all(color: Colors.black, width: 2),
            ),
          ),
        );
      },
    );
  }
}

class MessagesSkeleton extends StatelessWidget {
  const MessagesSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: 6,
      padding: const EdgeInsets.all(16),
      itemBuilder: (context, index) {
        final isMe = index % 2 == 0;
        return Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: Column(
            crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
            children: [
              BrutalSkeleton(width: 80, height: 12),
              const SizedBox(height: 4),
              BrutalSkeleton(width: 200, height: 40),
            ],
          ),
        );
      },
    );
  }
}
