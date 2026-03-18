import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../constants/app_colors.dart';

class AppTheme {
  // ────────────────────────────────────────────────────────
  //  LIGHT
  // ────────────────────────────────────────────────────────
  static ThemeData light(Color accentColor) {
    final colorScheme = ColorScheme(
      brightness: Brightness.light,
      primary: accentColor,
      onPrimary: Colors.white,
      primaryContainer: AppColors.accentBgLight,
      onPrimaryContainer: accentColor,
      secondary: AppColors.lightSecondary,
      onSecondary: Colors.white,
      secondaryContainer: AppColors.lightInput,
      onSecondaryContainer: AppColors.lightText,
      tertiary: AppColors.lightMuted,
      onTertiary: Colors.white,
      error: AppColors.danger,
      onError: Colors.white,
      errorContainer: const Color(0xFFFDEDED),
      onErrorContainer: AppColors.danger,
      surface: AppColors.lightBg,
      onSurface: AppColors.lightText,
      onSurfaceVariant: AppColors.lightSecondary,
      outline: AppColors.lightBorder,
      outlineVariant: AppColors.lightBorder,
      shadow: Colors.black,
      scrim: Colors.black,
      inverseSurface: AppColors.darkCard,
      onInverseSurface: AppColors.darkText,
      inversePrimary: AppColors.accentDark,
      surfaceContainerHighest: AppColors.lightInput,
    );

    return _buildTheme(
      colorScheme: colorScheme,
      accentColor: accentColor,
      cardColor: AppColors.lightCard,
      inputFill: AppColors.lightInput,
      borderColor: AppColors.lightBorder,
      secondaryText: AppColors.lightSecondary,
      mutedText: AppColors.lightMuted,
      statusBarBrightness: Brightness.dark, // dark icons on light bg
    );
  }

  // ────────────────────────────────────────────────────────
  //  DARK
  // ────────────────────────────────────────────────────────
  static ThemeData dark(Color accentColor) {
    final darkAccent =
        Color.lerp(accentColor, AppColors.accentDark, 0.4) ?? accentColor;

    final colorScheme = ColorScheme(
      brightness: Brightness.dark,
      primary: darkAccent,
      onPrimary: Colors.white,
      primaryContainer: AppColors.accentBgDark,
      onPrimaryContainer: darkAccent,
      secondary: AppColors.darkSecondary,
      onSecondary: Colors.black,
      secondaryContainer: AppColors.darkInput,
      onSecondaryContainer: AppColors.darkText,
      tertiary: AppColors.darkMuted,
      onTertiary: Colors.black,
      error: AppColors.danger,
      onError: Colors.white,
      errorContainer: const Color(0xFF3C1A1A),
      onErrorContainer: const Color(0xFFFFB4AB),
      surface: AppColors.darkBg,
      onSurface: AppColors.darkText,
      onSurfaceVariant: AppColors.darkSecondary,
      outline: AppColors.darkBorder,
      outlineVariant: AppColors.darkBorder,
      shadow: Colors.black,
      scrim: Colors.black,
      inverseSurface: AppColors.lightCard,
      onInverseSurface: AppColors.lightText,
      inversePrimary: accentColor,
      surfaceContainerHighest: AppColors.darkInput,
    );

    return _buildTheme(
      colorScheme: colorScheme,
      accentColor: darkAccent,
      cardColor: AppColors.darkCard,
      inputFill: AppColors.darkInput,
      borderColor: AppColors.darkBorder,
      secondaryText: AppColors.darkSecondary,
      mutedText: AppColors.darkMuted,
      statusBarBrightness: Brightness.light, // light icons on dark bg
    );
  }

  // ────────────────────────────────────────────────────────
  //  SHARED BUILDER
  // ────────────────────────────────────────────────────────
  static ThemeData _buildTheme({
    required ColorScheme colorScheme,
    required Color accentColor,
    required Color cardColor,
    required Color inputFill,
    required Color borderColor,
    required Color secondaryText,
    required Color mutedText,
    required Brightness statusBarBrightness,
  }) {
    final isLight = colorScheme.brightness == Brightness.light;
    final textColor = colorScheme.onSurface;

    // ── Text theme ──────────────────────────────────────
    final textTheme = TextTheme(
      displayLarge: TextStyle(fontSize: 32, fontWeight: FontWeight.w600, color: textColor, letterSpacing: -0.5),
      displayMedium: TextStyle(fontSize: 28, fontWeight: FontWeight.w600, color: textColor, letterSpacing: -0.5),
      displaySmall: TextStyle(fontSize: 24, fontWeight: FontWeight.w600, color: textColor),
      headlineLarge: TextStyle(fontSize: 22, fontWeight: FontWeight.w600, color: textColor),
      headlineMedium: TextStyle(fontSize: 20, fontWeight: FontWeight.w600, color: textColor),
      headlineSmall: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: textColor),
      titleLarge: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: textColor),
      titleMedium: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: textColor),
      titleSmall: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: textColor),
      bodyLarge: TextStyle(fontSize: 16, fontWeight: FontWeight.w400, color: textColor, height: 1.5),
      bodyMedium: TextStyle(fontSize: 14, fontWeight: FontWeight.w400, color: textColor, height: 1.5),
      bodySmall: TextStyle(fontSize: 12, fontWeight: FontWeight.w400, color: secondaryText, height: 1.4),
      labelLarge: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: textColor),
      labelMedium: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: secondaryText),
      labelSmall: TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: mutedText),
    );

    return ThemeData(
      useMaterial3: true,
      brightness: colorScheme.brightness,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: colorScheme.surface,
      textTheme: textTheme,

      // ── AppBar ────────────────────────────────────────
      appBarTheme: AppBarTheme(
        centerTitle: false,
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: colorScheme.surface,
        foregroundColor: textColor,
        surfaceTintColor: Colors.transparent,
        systemOverlayStyle: SystemUiOverlayStyle(
          statusBarBrightness: isLight ? Brightness.light : Brightness.dark,
          statusBarIconBrightness: statusBarBrightness,
          statusBarColor: Colors.transparent,
        ),
        titleTextStyle: TextStyle(
          color: textColor,
          fontSize: 22,
          fontWeight: FontWeight.w600,
        ),
      ),

      // ── Card ──────────────────────────────────────────
      cardTheme: CardThemeData(
        elevation: 0,
        color: cardColor,
        surfaceTintColor: Colors.transparent,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
          side: BorderSide(color: borderColor, width: 0.5),
        ),
      ),

      // ── FAB ───────────────────────────────────────────
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: accentColor,
        foregroundColor: Colors.white,
        elevation: 2,
        highlightElevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),

      // ── NavigationBar (Material 3) ────────────────────
      navigationBarTheme: NavigationBarThemeData(
        elevation: 0,
        backgroundColor: cardColor,
        surfaceTintColor: Colors.transparent,
        indicatorColor: accentColor.withValues(alpha: 0.12),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: accentColor,
            );
          }
          return TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: secondaryText,
          );
        }),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return IconThemeData(color: accentColor, size: 24);
          }
          return IconThemeData(color: secondaryText, size: 24);
        }),
      ),

      // ── BottomNavigationBar (legacy) ──────────────────
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        type: BottomNavigationBarType.fixed,
        selectedItemColor: accentColor,
        unselectedItemColor: secondaryText,
        backgroundColor: cardColor,
        elevation: 0,
        selectedLabelStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
        unselectedLabelStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
      ),

      // ── Input ─────────────────────────────────────────
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: inputFill,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: accentColor, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: AppColors.danger, width: 1),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: AppColors.danger, width: 1.5),
        ),
        hintStyle: TextStyle(color: mutedText, fontWeight: FontWeight.w400),
        labelStyle: TextStyle(color: secondaryText),
      ),

      // ── Chips ─────────────────────────────────────────
      chipTheme: ChipThemeData(
        backgroundColor: inputFill,
        selectedColor: accentColor.withValues(alpha: 0.15),
        disabledColor: inputFill,
        labelStyle: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: textColor),
        secondaryLabelStyle: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: accentColor),
        side: BorderSide(color: borderColor, width: 0.5),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      ),

      // ── Dialog ────────────────────────────────────────
      dialogTheme: DialogThemeData(
        backgroundColor: cardColor,
        surfaceTintColor: Colors.transparent,
        elevation: 8,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        titleTextStyle: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: textColor),
        contentTextStyle: TextStyle(fontSize: 14, fontWeight: FontWeight.w400, color: secondaryText, height: 1.5),
      ),

      // ── BottomSheet ───────────────────────────────────
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: cardColor,
        surfaceTintColor: Colors.transparent,
        elevation: 8,
        modalElevation: 8,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        showDragHandle: true,
        dragHandleColor: mutedText.withValues(alpha: 0.4),
        dragHandleSize: const Size(36, 4),
      ),

      // ── ListTile ──────────────────────────────────────
      listTileTheme: ListTileThemeData(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        minVerticalPadding: 8,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        titleTextStyle: TextStyle(fontSize: 15, fontWeight: FontWeight.w500, color: textColor),
        subtitleTextStyle: TextStyle(fontSize: 13, fontWeight: FontWeight.w400, color: secondaryText),
        iconColor: secondaryText,
      ),

      // ── Divider ───────────────────────────────────────
      dividerTheme: DividerThemeData(
        color: borderColor,
        thickness: 0.5,
        space: 0,
      ),
      dividerColor: borderColor,

      // ── Checkbox / Switch / Radio ─────────────────────
      checkboxTheme: CheckboxThemeData(
        fillColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return accentColor;
          return Colors.transparent;
        }),
        checkColor: WidgetStatePropertyAll(Colors.white),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
        side: BorderSide(color: mutedText, width: 1.5),
      ),

      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return Colors.white;
          return mutedText;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return accentColor;
          return inputFill;
        }),
        trackOutlineColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return Colors.transparent;
          return borderColor;
        }),
      ),

      radioTheme: RadioThemeData(
        fillColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return accentColor;
          return mutedText;
        }),
      ),

      // ── TextButton / ElevatedButton / OutlinedButton ──
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: accentColor,
          textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        ),
      ),

      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: accentColor,
          foregroundColor: Colors.white,
          elevation: 0,
          textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        ),
      ),

      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: accentColor,
          side: BorderSide(color: accentColor),
          textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        ),
      ),

      // ── Snackbar ──────────────────────────────────────
      snackBarTheme: SnackBarThemeData(
        backgroundColor: isLight ? AppColors.lightText : AppColors.darkCard,
        contentTextStyle: TextStyle(
          color: isLight ? Colors.white : AppColors.darkText,
          fontSize: 14,
        ),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        elevation: 4,
      ),

      // ── PopupMenu ─────────────────────────────────────
      popupMenuTheme: PopupMenuThemeData(
        color: cardColor,
        surfaceTintColor: Colors.transparent,
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        textStyle: TextStyle(fontSize: 14, fontWeight: FontWeight.w400, color: textColor),
      ),

      // ── TabBar ────────────────────────────────────────
      tabBarTheme: TabBarThemeData(
        labelColor: accentColor,
        unselectedLabelColor: secondaryText,
        labelStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
        unselectedLabelStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
        indicatorColor: accentColor,
        indicatorSize: TabBarIndicatorSize.label,
        dividerColor: borderColor,
        dividerHeight: 0.5,
      ),

      // ── ProgressIndicator ─────────────────────────────
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: accentColor,
        linearTrackColor: inputFill,
        circularTrackColor: inputFill,
      ),

      // ── Tooltip ───────────────────────────────────────
      tooltipTheme: TooltipThemeData(
        decoration: BoxDecoration(
          color: isLight ? AppColors.lightText : AppColors.darkCard,
          borderRadius: BorderRadius.circular(6),
        ),
        textStyle: TextStyle(
          color: isLight ? Colors.white : AppColors.darkText,
          fontSize: 12,
        ),
      ),

      // ── Misc ──────────────────────────────────────────
      splashColor: accentColor.withValues(alpha: 0.08),
      highlightColor: accentColor.withValues(alpha: 0.04),
      splashFactory: InkSparkle.splashFactory,
    );
  }
}
