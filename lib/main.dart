import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'core/api_client.dart';
import 'screens/home_screen.dart';
import 'screens/login_screen.dart';
import 'state/auth_state.dart';
import 'theme/app_colors.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('ko_KR');
  final apiClient = await ApiClient.init();
  final authState = AuthState(apiClient);
  await authState.restore();
  runApp(SiscApp(authState: authState));
}

class SiscApp extends StatelessWidget {
  const SiscApp({super.key, required this.authState});

  final AuthState authState;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SISC',
      theme: _buildDarkTheme(),
      builder: (context, child) => Stack(
        fit: StackFit.expand,
        children: [
          Image.asset('assets/images/home_background.png', fit: BoxFit.cover),
          if (child != null) child,
        ],
      ),
      home: ListenableBuilder(
        listenable: authState,
        builder: (context, _) {
          switch (authState.status) {
            case AuthStatus.unknown:
              return const Scaffold(
                backgroundColor: Colors.transparent,
                body: Center(child: CircularProgressIndicator()),
              );
            case AuthStatus.loggedOut:
              return LoginScreen(authState: authState);
            case AuthStatus.loggedIn:
              return HomeScreen(authState: authState);
          }
        },
      ),
    );
  }
}

ThemeData _buildDarkTheme() {
  const background = Color(0xFF070B1E);
  final glassFill = Colors.white.withValues(alpha: 0.06);
  final glassBorder = Colors.white.withValues(alpha: 0.12);
  final glassButtonFill = Colors.white.withValues(alpha: 0.14);

  final colorScheme = ColorScheme.fromSeed(
    seedColor: Colors.indigo,
    brightness: Brightness.dark,
  ).copyWith(surface: background);

  final outlineBorder = OutlineInputBorder(
    borderRadius: BorderRadius.circular(12),
    borderSide: BorderSide(color: glassBorder),
  );

  final buttonShape = RoundedRectangleBorder(
    borderRadius: BorderRadius.circular(14),
    side: BorderSide(color: glassBorder),
  );

  return ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    colorScheme: colorScheme,
    // 공용 배경 이미지가 MaterialApp.builder에서 그려지므로 Scaffold는 투명하게 둔다.
    scaffoldBackgroundColor: Colors.transparent,
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 0,
      foregroundColor: Colors.white,
    ),
    cardTheme: CardThemeData(
      color: glassFill,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: glassBorder),
      ),
    ),
    dividerTheme: DividerThemeData(color: glassBorder),
    listTileTheme: const ListTileThemeData(
      iconColor: Colors.white70,
      textColor: Colors.white,
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: glassFill,
      hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.5)),
      labelStyle: TextStyle(color: Colors.white.withValues(alpha: 0.7)),
      border: outlineBorder,
      enabledBorder: outlineBorder,
      focusedBorder: outlineBorder.copyWith(
        borderSide: BorderSide(color: colorScheme.primary, width: 1.5),
      ),
    ),
    chipTheme: ChipThemeData(
      backgroundColor: glassFill,
      side: BorderSide(color: glassBorder),
      labelStyle: const TextStyle(color: Colors.white),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: glassButtonFill,
        foregroundColor: Colors.white,
        elevation: 0,
        shape: buttonShape,
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: glassButtonFill,
        foregroundColor: Colors.white,
        elevation: 0,
        shape: buttonShape,
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        backgroundColor: glassFill,
        foregroundColor: Colors.white,
        side: BorderSide(color: glassBorder),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(foregroundColor: Colors.white),
    ),
    extensions: const [AppColors.dark],
  );
}
