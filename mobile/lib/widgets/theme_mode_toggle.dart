import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/theme/app_theme.dart';
import '../providers/theme_provider.dart';

/// Bouton clair / sombre réutilisable (AppBar, login, etc.).
class ThemeModeToggle extends StatelessWidget {
  final bool showTooltip;

  const ThemeModeToggle({super.key, this.showTooltip = true});

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();
    final isDark = themeProvider.isDarkMode;

    final button = IconButton(
      icon: Icon(
        isDark ? Icons.light_mode_outlined : Icons.dark_mode_outlined,
        color: Theme.of(context).appBarTheme.iconTheme?.color ?? AppTheme.masYellow,
      ),
      onPressed: () => themeProvider.toggleTheme(!isDark),
    );

    if (!showTooltip) return button;

    return Tooltip(
      message: isDark ? 'Mode clair' : 'Mode sombre',
      child: button,
    );
  }
}

/// Interrupteur pour les écrans de paramètres (profil, etc.).
class ThemeModeSwitchTile extends StatelessWidget {
  const ThemeModeSwitchTile({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();
    final isDark = themeProvider.isDarkMode;

    return SwitchListTile(
      secondary: Icon(isDark ? Icons.dark_mode : Icons.light_mode),
      title: Text(isDark ? 'Mode sombre' : 'Mode clair'),
      subtitle: const Text('Apparence de l\'application'),
      value: isDark,
      thumbColor: MaterialStateProperty.all(AppTheme.masYellow),
      onChanged: themeProvider.toggleTheme,
    );
  }
}

/// Actions AppBar standard : thème + actions supplémentaires.
class AppBarActions {
  AppBarActions._();

  static List<Widget> withTheme({List<Widget>? extra}) {
    return [
      const ThemeModeToggle(),
      ...?extra,
    ];
  }
}
