import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../../app/theme/app_colors.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/error_view.dart';
import '../../../core/widgets/loading_shimmer.dart';
import '../../../l10n/l10n.dart';
import '../../auth/providers/auth_provider.dart';
import '../domain/menu_entry.dart';

class MenuScreen extends ConsumerStatefulWidget {
  const MenuScreen({super.key});

  @override
  ConsumerState<MenuScreen> createState() => _MenuScreenState();
}

class _MenuScreenState extends ConsumerState<MenuScreen> {
  late final List<MenuEntry> _entries;

  @override
  void initState() {
    super.initState();
    final role = ref.read(authProvider).user?.role ?? 'student';
    _entries = MenuEntry.forRole(role);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (_entries.isEmpty) {
      return const Scaffold(
        body: EmptyState(
          icon: PhosphorIconsRegular.list,
          title: 'Sin opciones',
          subtitle: 'No hay opciones disponibles para tu rol.',
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.backgroundFor(isDark),
      appBar: AppBar(
        title: Text(l10n.navMenu),
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _entries.length,
        itemBuilder: (context, index) {
          final entry = _entries[index];
          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            child: ListTile(
              leading: Icon(
                entry.icon,
                color: isDark
                    ? AppColors.darkTextPrimary
                    : AppColors.lightTextPrimary,
              ),
              title: Text(entry.label),
              trailing: const Icon(
                PhosphorIconsRegular.arrowRight,
              ),
              onTap: () => context.push(entry.route),
            ),
          );
        },
      ),
    );
  }
}
