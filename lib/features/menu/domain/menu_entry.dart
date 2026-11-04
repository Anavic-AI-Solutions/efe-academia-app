class MenuEntry {
  final String label;
  final IconData icon;
  final IconData selectedIcon;
  final String route;
  final String? tooltip;
  final bool showInBottomNav;
  final bool isAcademic;
  final bool isCommunication;
  final bool isAccount;
  final bool isSupport;

  const MenuEntry({
    required this.label,
    required this.icon,
    required this.selectedIcon,
    required this.route,
    this.tooltip,
    this.showInBottomNav = true,
    this.isAcademic = false,
    this.isCommunication = false,
    this.isAccount = false,
    this.isSupport = false,
  });

  static List<MenuEntry> allEntries() => [
    MenuEntry(
      label: 'Menú',
      icon: PhosphorIconsRegular.grid,
      selectedIcon: PhosphorIconsFill.grid,
      route: '/menu',
    ),
    MenuEntry(
      label: 'Historial',
      icon: PhosphorIconsRegular.history,
      selectedIcon: PhosphorIconsFill.history,
      route: '/history',
      isAcademic: true,
    ),
    MenuEntry(
      label: 'Biblioteca',
      icon: PhosphorIconsRegular.bookOpen,
      selectedIcon: PhosphorIconsFill.bookOpen,
      route: '/library',
      isCommunication: true,
    ),
    MenuEntry(
      label: 'FAQ',
      icon: PhosphorIconsRegular.questionCircle,
      selectedIcon: PhosphorIconsFill.questionCircle,
      route: '/faqs',
      isSupport: true,
    ),
    MenuEntry(
      label: 'Estadísticas',
      icon: PhosphorIconsRegular.chart,
      selectedIcon: PhosphorIconsFill.chart,
      route: '/statistics',
      isAccount: true,
    ),
  ];

  static List<MenuEntry> forRole(String role) {
    final all = allEntries();
    switch (role) {
      case 'admin':
        return all;
      case 'sede':
        return all;
      case 'professor':
        return [
          ...all.where((e) => e.isAcademic || e.isCommunication),
        ];
      case 'parent':
        return [
          ...all.where((e) => !e.isAccount || e.route == '/menu'),
          MenuEntry(
            label: 'Pagos',
            icon: PhosphorIconsRegular.wallet,
            selectedIcon: PhosphorIconsFill.wallet,
            route: '/payments',
          ),
        ];
      case 'student':
        return [
          ...all.where((e) => e.route == '/menu' || e.route == '/history'),
        ];
      default:
        return all;
    }
  }
}