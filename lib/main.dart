import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'core/app_colors.dart';
import 'providers/task_provider.dart';
import 'screens/dashboard_screen.dart';
import 'services/task_storage_service.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const DailyWorkApp());
}

class DailyWorkApp extends StatelessWidget {
  const DailyWorkApp({super.key, this.storage});

  final TaskStorage? storage;

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<TaskProvider>(
      create: (_) =>
          TaskProvider(storage ?? TaskStorageService())..initialize(),
      child: MaterialApp(
        title: 'todo list jakkob',
        debugShowCheckedModeBanner: false,
        theme: _buildTheme(),
        home: const DashboardScreen(),
      ),
    );
  }

  ThemeData _buildTheme() {
    const colorScheme = ColorScheme.light(
      primary: AppColors.royalBlue,
      onPrimary: AppColors.white,
      secondary: AppColors.navy,
      onSecondary: AppColors.white,
      surface: AppColors.white,
      onSurface: AppColors.slate900,
      error: AppColors.danger,
      outline: AppColors.slate300,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: AppColors.slate50,
      fontFamily: 'Arial',
      dividerColor: AppColors.slate200,
      visualDensity: VisualDensity.standard,
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.white,
        foregroundColor: AppColors.slate900,
        elevation: 0,
        scrolledUnderElevation: 0,
      ),
      cardTheme: const CardThemeData(
        color: AppColors.white,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(16)),
          side: BorderSide(color: AppColors.slate200),
        ),
      ),
      inputDecorationTheme: const InputDecorationTheme(
        filled: true,
        fillColor: AppColors.white,
        isDense: true,
        contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(12)),
          borderSide: BorderSide(color: AppColors.slate300),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(12)),
          borderSide: BorderSide(color: AppColors.slate300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(12)),
          borderSide: BorderSide(color: AppColors.royalBlue, width: 1.5),
        ),
        labelStyle: TextStyle(color: AppColors.slate600),
        hintStyle: TextStyle(color: AppColors.slate500),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.royalBlue,
          foregroundColor: AppColors.white,
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: const TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.slate700,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
          side: const BorderSide(color: AppColors.slate300),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: const TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
      popupMenuTheme: const PopupMenuThemeData(
        color: AppColors.white,
        surfaceTintColor: AppColors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(12)),
          side: BorderSide(color: AppColors.slate200),
        ),
      ),
      snackBarTheme: const SnackBarThemeData(
        backgroundColor: AppColors.slate900,
        contentTextStyle: TextStyle(color: AppColors.white),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}
