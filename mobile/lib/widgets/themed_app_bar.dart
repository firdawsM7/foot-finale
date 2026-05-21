import 'package:flutter/material.dart';

import 'theme_mode_toggle.dart';

/// AppBar avec bascule thème clair/sombre intégrée.
class ThemedAppBar extends StatelessWidget implements PreferredSizeWidget {
  final Widget? title;
  final String? titleText;
  final List<Widget>? actions;
  final Widget? leading;
  final PreferredSizeWidget? bottom;
  final bool automaticallyImplyLeading;

  const ThemedAppBar({
    super.key,
    this.title,
    this.titleText,
    this.actions,
    this.leading,
    this.bottom,
    this.automaticallyImplyLeading = true,
  });

  @override
  Size get preferredSize => Size.fromHeight(
        kToolbarHeight + (bottom?.preferredSize.height ?? 0),
      );

  @override
  Widget build(BuildContext context) {
    return AppBar(
      title: title ?? (titleText != null ? Text(titleText!) : null),
      leading: leading,
      automaticallyImplyLeading: automaticallyImplyLeading,
      bottom: bottom,
      actions: AppBarActions.withTheme(extra: actions),
    );
  }
}
