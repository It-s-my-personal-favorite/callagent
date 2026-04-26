import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'backend/admin_api/live_admin_api.dart';
import 'core/theme.dart';
import 'frontend/admin/admin_shell_page.dart';

void main() {
  runApp(const CallAgentApp());
}

class CallAgentApp extends StatefulWidget {
  const CallAgentApp({super.key});

  @override
  State<CallAgentApp> createState() => _CallAgentAppState();
}

class _CallAgentAppState extends State<CallAgentApp> {
  static const _themePrefKey = 'theme_mode';
  ThemeMode _themeMode = ThemeMode.light;

  @override
  void initState() {
    super.initState();
    _loadThemeMode();
  }

  Future<void> _loadThemeMode() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString(_themePrefKey);
    if (!mounted || saved == null) return;
    setState(() {
      _themeMode = saved == ThemeMode.light.name ? ThemeMode.light : ThemeMode.dark;
    });
  }

  void _toggleThemeMode() {
    setState(() {
      _themeMode = _themeMode == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark;
    });
    SharedPreferences.getInstance().then(
      (prefs) => prefs.setString(_themePrefKey, _themeMode.name),
    );
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'CallAgent Admin',
      debugShowCheckedModeBanner: false,
      locale: const Locale('de'),
      supportedLocales: const [Locale('de')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: _themeMode,
      initialRoute: '/admin',
      routes: {
        '/admin': (_) => AdminShellPage(
              api: LiveAdminApi(),
              themeMode: _themeMode,
              onToggleThemeMode: _toggleThemeMode,
            ),
      },
    );
  }
}
