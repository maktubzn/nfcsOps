import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nfc_ops/core/theme/app_colors.dart';
import 'package:nfc_ops/core/theme/app_theme.dart';
import 'package:nfc_ops/core/theme/app_typography.dart';

void main() {
  group('Theme & Design Tokens Tests', () {
    test('Palette colors match canonical sampled hexes', () {
      expect(AppColors.background.toARGB32(), 0xFF0D0E0D);
      expect(AppColors.orangeAction.toARGB32(), 0xFFFD4701);
      expect(AppColors.greenSuccess.toARGB32(), 0xFF89ED46);
      expect(AppColors.lilacSupport.toARGB32(), 0xFFA0A7FC);
      expect(AppColors.surfaceCream.toARGB32(), 0xFFF0EDE0);
    });

    test('Typography uses Inter font family across all styles', () {
      expect(AppTypography.displayLarge.fontFamily, 'Inter');
      expect(AppTypography.titleLarge.fontFamily, 'Inter');
      expect(AppTypography.titleMedium.fontFamily, 'Inter');
      expect(AppTypography.bodyMedium.fontFamily, 'Inter');
      expect(AppTypography.button.fontFamily, 'Inter');
    });

    test('ThemeData is dark, uses Inter font, and has dark background', () {
      final theme = AppTheme.darkTheme;
      expect(theme.brightness, Brightness.dark);
      expect(theme.scaffoldBackgroundColor, AppColors.background);
      expect(theme.textTheme.bodyMedium?.fontFamily, 'Inter');
      expect(theme.colorScheme.primary, AppColors.orangeAction);
    });
  });
}
