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
      theme: _buildLightTheme(),
      home: ListenableBuilder(
        listenable: authState,
        builder: (context, _) {
          switch (authState.status) {
            case AuthStatus.unknown:
              return const Scaffold(
                backgroundColor: AppColors.bg,
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

ThemeData _buildLightTheme() {
  const fieldFill = Color(0xFFF2F4F8);
  const border = AppColors.border;

  final colorScheme = ColorScheme.fromSeed(
    seedColor: AppColors.blue,
    brightness: Brightness.light,
  ).copyWith(surface: AppColors.card, primary: AppColors.blue);

  final outlineBorder = OutlineInputBorder(
    borderRadius: BorderRadius.circular(12),
    borderSide: const BorderSide(color: border),
  );

  final buttonShape = RoundedRectangleBorder(
    borderRadius: BorderRadius.circular(14),
    side: const BorderSide(color: border),
  );

  return ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    colorScheme: colorScheme,
    scaffoldBackgroundColor: AppColors.bg,
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 0,
      foregroundColor: AppColors.textPrimary,
    ),
    cardTheme: CardThemeData(
      color: AppColors.card,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: border),
      ),
    ),
    dividerTheme: const DividerThemeData(color: border),
    listTileTheme: const ListTileThemeData(
      iconColor: AppColors.textSecondary,
      textColor: AppColors.textPrimary,
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: fieldFill,
      hintStyle: const TextStyle(color: AppColors.textSecondary),
      labelStyle: const TextStyle(color: AppColors.textSecondary),
      border: outlineBorder,
      enabledBorder: outlineBorder,
      focusedBorder: outlineBorder.copyWith(
        borderSide: BorderSide(color: colorScheme.primary, width: 1.5),
      ),
    ),
    chipTheme: ChipThemeData(
      backgroundColor: fieldFill,
      side: const BorderSide(color: border),
      labelStyle: const TextStyle(color: AppColors.textPrimary),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: AppColors.blue,
        foregroundColor: Colors.white,
        elevation: 0,
        shape: buttonShape,
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.blue,
        foregroundColor: Colors.white,
        elevation: 0,
        shape: buttonShape,
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        backgroundColor: AppColors.card,
        foregroundColor: AppColors.textPrimary,
        side: const BorderSide(color: border),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(foregroundColor: AppColors.blue),
    ),
  );
}
