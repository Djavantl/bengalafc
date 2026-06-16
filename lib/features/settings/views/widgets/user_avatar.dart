import 'dart:convert';
import 'package:flutter/material.dart';
import '../../models/app_user_model.dart';
import '../../services/avatar_service.dart';

class UserAvatar extends StatelessWidget {
  final AppUserModel user;
  final double radius;
  final VoidCallback? onTap;

  const UserAvatar({
    super.key,
    required this.user,
    this.radius = 20,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<String?>(
      future: AvatarService.getLocalAvatar(user.id),
      builder: (context, snapshot) {
        final localBase64 = snapshot.data;
        Widget avatarWidget;

        if (user.avatarUrl != null && user.avatarUrl!.isNotEmpty) {
          avatarWidget = CircleAvatar(
            radius: radius,
            backgroundImage: NetworkImage(user.avatarUrl!),
          );
        } else if (localBase64 != null && localBase64.isNotEmpty) {
          try {
            final bytes = base64Decode(localBase64);
            avatarWidget = CircleAvatar(
              radius: radius,
              backgroundImage: MemoryImage(bytes),
            );
          } catch (e) {
            avatarWidget = _buildFallbackAvatar(context);
          }
        } else {
          avatarWidget = _buildFallbackAvatar(context);
        }

        if (onTap != null) {
          return GestureDetector(
            onTap: onTap,
            child: avatarWidget,
          );
        }
        return avatarWidget;
      },
    );
  }

  Widget _buildFallbackAvatar(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final nameStr = user.name.trim();
    String initials = 'U';

    if (nameStr.isNotEmpty) {
      final parts = nameStr.split(' ').where((p) => p.isNotEmpty).toList();
      if (parts.isNotEmpty) {
        if (parts.length >= 2) {
          initials = '${parts[0][0]}${parts[1][0]}'.toUpperCase();
        } else {
          initials = parts[0][0].toUpperCase();
        }
      }
    }

    return CircleAvatar(
      radius: radius,
      backgroundColor: cs.primary.withOpacity(0.15),
      child: Text(
        initials,
        style: TextStyle(
          color: cs.primary,
          fontWeight: FontWeight.bold,
          fontSize: radius * 0.8,
        ),
      ),
    );
  }
}
