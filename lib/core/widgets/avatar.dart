import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

class AppAvatar extends StatelessWidget {
  final String? imageUrl;
  final String name;
  final double size;
  final bool showBorder;

  const AppAvatar({
    super.key,
    this.imageUrl,
    required this.name,
    this.size = 40,
    this.showBorder = false,
  });

  static const List<Color> _colorPalette = [
    Color(0xFFEF4444),
    Color(0xFFF97316),
    Color(0xFFF59E0B),
    Color(0xFF10B981),
    Color(0xFF3B82F6),
    Color(0xFF8B5CF6),
    Color(0xFFEC4899),
    Color(0xFF06B6D4),
  ];

  Color get _backgroundColor {
    final index = name.hashCode.abs() % _colorPalette.length;
    return _colorPalette[index];
  }

  String get _initials {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty) return '?';
    if (parts.length == 1) return parts[0][0].toUpperCase();
    return '${parts[0][0]}${parts[parts.length - 1][0]}'.toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final borderWidth = showBorder ? 2.0 : 0.0;
    final totalSize = size + borderWidth * 2;

    return Container(
      width: totalSize,
      height: totalSize,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: showBorder
            ? Border.all(
                color: Theme.of(context).colorScheme.surface,
                width: borderWidth,
              )
            : null,
      ),
      child: ClipOval(
        child: imageUrl != null && imageUrl!.isNotEmpty
            ? CachedNetworkImage(
                imageUrl: imageUrl!,
                width: size,
                height: size,
                fit: BoxFit.cover,
                placeholder: (context, url) => _buildInitials(),
                errorWidget: (context, url, error) => _buildInitials(),
              )
            : _buildInitials(),
      ),
    );
  }

  Widget _buildInitials() {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: _backgroundColor,
        shape: BoxShape.circle,
      ),
      alignment: Alignment.center,
      child: Text(
        _initials,
        style: TextStyle(
          color: Colors.white,
          fontSize: size * 0.38,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
