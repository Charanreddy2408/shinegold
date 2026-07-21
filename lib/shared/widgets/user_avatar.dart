import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';

/// Displays a user's profile photo, or their initials (WhatsApp-style) when
/// no photo is available.
class UserAvatar extends StatelessWidget {
  const UserAvatar({
    super.key,
    required this.name,
    this.photoUrl,
    this.radius = 24,
    this.backgroundColor,
    this.textStyle,
  });

  final String name;
  final String? photoUrl;
  final double radius;
  final Color? backgroundColor;
  final TextStyle? textStyle;

  static String initials(String name) {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty || parts.first.isEmpty) return '?';
    if (parts.length == 1) return parts.first[0].toUpperCase();
    return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
  }

  static const _palette = [
    Color(0xFF1A9B5C), // field green
    Color(0xFFE8A317), // harvest gold
    Color(0xFF5C6BC0), // indigo
    Color(0xFF00897B), // teal
    Color(0xFFD81B60), // pink
    Color(0xFF6D4C41), // brown
    Color(0xFF546E7A), // blue-grey
    Color(0xFFEF6C00), // orange
  ];

  static Color _colorForName(String name) {
    final hash = name.trim().toLowerCase().codeUnits.fold<int>(0, (h, c) => h + c);
    return _palette[hash % _palette.length];
  }

  bool get _hasPhoto =>
      photoUrl != null && photoUrl!.trim().isNotEmpty;

  @override
  Widget build(BuildContext context) {
    if (_hasPhoto) {
      return CircleAvatar(
        radius: radius,
        backgroundColor: backgroundColor ?? AppColors.primarySoft,
        backgroundImage: CachedNetworkImageProvider(photoUrl!),
      );
    }

    final letters = initials(name);
    final bg = backgroundColor ?? _colorForName(name);
    final fontSize = radius * 0.8;

    return CircleAvatar(
      radius: radius,
      backgroundColor: bg,
      child: Text(
        letters,
        style: textStyle ??
            TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w700,
              fontSize: fontSize,
              letterSpacing: 0.5,
            ),
      ),
    );
  }
}
