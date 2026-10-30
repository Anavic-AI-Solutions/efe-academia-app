import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import '../../app/theme/app_colors.dart';

class AppAvatar extends StatelessWidget {
  final String? imageUrl;
  final String name;
  final double size;
  final bool showBorder;
  final bool showGradientRing;

  const AppAvatar({
    super.key,
    this.imageUrl,
    required this.name,
    this.size = 44,
    this.showBorder = false,
    this.showGradientRing = false,
  });

  static const List<Color> _colorPalette = [
    Color(0xFFEF4444),
    Color(0xFFF97316),
    Color(0xFFF59E0B),
    Color(0xFF10B981),
    Color(0xFF3B82F6),
    Color(0xFF06B6D4),
    Color(0xFFEC4899),
    Color(0xFF14B8A6),
  ];

  Color get _backgroundColor {
    final index = name.hashCode.abs() % _colorPalette.length;
    return _colorPalette[index];
  }

  String get _initials {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return '?';
    final parts = trimmed.split(RegExp(r'\s+'));
    if (parts.isEmpty || parts[0].isEmpty) return '?';
    if (parts.length == 1) return parts[0][0].toUpperCase();
    return '${parts[0][0]}${parts[parts.length - 1][0]}'.toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final borderWidth = showBorder ? 2.0 : 0.0;
    final totalSize = size + borderWidth * 2;
    final ringWidth = showGradientRing ? 3.0 : 0.0;
    final ringTotalSize = totalSize + ringWidth * 2;

    Widget avatar = ClipOval(
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
    );

    if (showBorder) {
      avatar = Container(
        width: totalSize,
        height: totalSize,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(
            color: Theme.of(context).colorScheme.surface,
            width: borderWidth,
          ),
        ),
        child: avatar,
      );
    }

    if (showGradientRing) {
      avatar = Container(
        width: ringTotalSize,
        height: ringTotalSize,
        padding: const EdgeInsets.all(3),
        decoration: const BoxDecoration(
          shape: BoxShape.circle,
          gradient: AppColors.primaryGradient,
        ),
        child: Container(
          width: totalSize,
          height: totalSize,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: Theme.of(context).colorScheme.surface,
              width: borderWidth > 0 ? borderWidth : 2,
            ),
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
        ),
      );
    }

    return avatar;
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
          fontSize: size * 0.36,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
