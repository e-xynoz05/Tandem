import 'package:flutter/material.dart';
import '../models/avatar_config.dart';

class AvatarWidget extends StatelessWidget {
  const AvatarWidget({
    required this.config,
    this.size = 100,
    super.key,
  });

  final AvatarConfig config;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: size,
      width: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: config.skinTone, // Use the selected tone as background
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.2),
          width: size * 0.02,
        ),
        boxShadow: [
          BoxShadow(
            color: config.skinTone.withValues(alpha: 0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Center(
        child: Icon(
          Icons.person_rounded,
          color: Colors.white,
          size: size * 0.6,
        ),
      ),
    );
  }
}
