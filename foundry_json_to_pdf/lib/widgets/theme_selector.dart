import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class ThemeSelector extends StatelessWidget {
  const ThemeSelector({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: AppTheme.themeModeNotifier,
      builder: (context, themeMode, child) {
        return DropdownButton<ThemeMode>(
          value: themeMode,
          underline: const SizedBox(),
          icon: const Icon(Icons.brightness_6),
          items: const [
            DropdownMenuItem(
              value: ThemeMode.light,
              child: Text('Hell'),
            ),
            DropdownMenuItem(
              value: ThemeMode.dark,
              child: Text('Dunkel'),
            ),
            DropdownMenuItem(
              value: ThemeMode.system,
              child: Text('System'),
            ),
          ],
          onChanged: (ThemeMode? selectedThemeMode) {
            if (selectedThemeMode != null) {
              AppTheme.themeModeNotifier.value = selectedThemeMode;
            }
          },
        );
      },
    );
  }
}