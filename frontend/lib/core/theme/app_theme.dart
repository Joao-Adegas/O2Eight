// lib/core/theme/app_theme.dart
import 'dart:ui' show FontFeature;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

// ═════════════════════════════════════════════════════════════════════
//  Design system do O₂Eight
//  Regra geral: nenhuma tela deve usar Color(0x...) solto. Use as
//  constantes abaixo; assim um ajuste de cor vale para o app inteiro.
// ═════════════════════════════════════════════════════════════════════

/// Paleta. Cada cor tem uma função definida.
class AppColors {
  AppColors._();
  

  // ── Marca ──
  /// Fundo do topo (degradê) e superfícies escuras
  static const navy900 = Color(0xFF0B2A4A);

  /// Superfícies elevadas sobre fundo escuro (campo de texto do chat)
  static const navy800 = Color(0xFF12375E);

  /// Cor primária: botões principais, títulos, ícones ativos
  static const navy700 = Color(0xFF0D4F7C);

  /// Fundo leve de destaque (seleção, chips) com texto navy700
  static const navy50 = Color(0xFFE7EFF6);

  /// Turquesa para usar SOBRE FUNDO ESCURO (anel, brilho, ícones do topo)
  static const teal500 = Color(0xFF3CCCB4);

  /// Turquesa para usar SOBRE FUNDO CLARO (texto e ícones) — contraste AA
  static const teal700 = Color(0xFF177A6D);

  /// Fundo leve turquesa (opção selecionada) com texto teal700
  static const teal50 = Color(0xFFE3F5F2);

  // ── Neutros ──
  static const text = Color(0xFF0F1F33);
  static const textSecondary = Color(0xFF5B6B7C);
  static const border = Color(0xFFE2E8EF);
  static const background = Color(0xFFF4F7FA);
  static const surface = Colors.white;

  // ── Sobre fundo escuro ──
  static const onDark = Colors.white;
  static const onDarkSecondary = Color(0xB3FFFFFF); // branco 70%

  // ── Feedback ──
  static const error = Color(0xFFC62828);

  
  /// Coração de curtida (convenção universal das redes sociais)
  static const like = Color(0xFFE0245E);

  // ── Estado do pulmão (uso EXCLUSIVO do indicador de recuperação) ──
  static const statusRecent = Color(0xFFFF8A65);
  static const statusStabilizing = Color(0xFFFFC857);
  static const statusHealthy = teal500;
}

/// Escala de cantos arredondados.
class AppRadius {
  AppRadius._();

  static const double sm = 8; // chips, tags pequenas
  static const double md = 12; // botões, campos de texto
  static const double lg = 16; // cards
  static const double xl = 32; // base do topo, bottom sheets
  static const double pill = 999; // pílulas e avatares

  static final small = BorderRadius.circular(sm);
  static final medium = BorderRadius.circular(md);
  static final large = BorderRadius.circular(lg);
  static final pillShape = BorderRadius.circular(pill);

  /// Topo das telas: só os cantos de baixo arredondados
  static const heroBottom = BorderRadius.only(
    bottomLeft: Radius.circular(xl),
    bottomRight: Radius.circular(xl),
  );
}

/// Escala de espaçamento (múltiplos de 4).
class AppSpacing {
  AppSpacing._();

  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 24;
  static const double xxl = 32;

  /// Margem lateral padrão das telas
  static const double screen = 24;
}

/// Sombra única para cards.
class AppShadows {
  AppShadows._();

  static const card = [
    BoxShadow(
      color: Color(0x0F000000), // preto 6%
      blurRadius: 16,
      offset: Offset(0, 4),
    ),
  ];
}

/// O único degradê do app: usado apenas nos topos de tela.
class AppGradients {
  AppGradients._();

  static const hero = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [AppColors.navy700, AppColors.navy900],
  );
}

/// Estilos de texto que não existem no tema padrão.
class AppTextStyles {
  AppTextStyles._();

  /// Números que mudam (contadores, dinheiro): largura fixa por dígito,
  /// para o texto não "tremer" enquanto os valores sobem.
  static const tabularFigures = [FontFeature.tabularFigures()];

  /// Número principal do topo (dias sem fumar)
  static const display = TextStyle(
    fontSize: 84,
    fontWeight: FontWeight.w700,
    height: 1,
    letterSpacing: -2,
    color: AppColors.onDark,
    fontFeatures: tabularFigures,
  );
}

/// Tema do app (Material 3).
class AppTheme {
  AppTheme._();

  static ThemeData get lightTheme {
    final base = ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
    );

    final textTheme = GoogleFonts.plusJakartaSansTextTheme(base.textTheme)
        .apply(bodyColor: AppColors.text, displayColor: AppColors.text);

    final colorScheme = ColorScheme.fromSeed(
      seedColor: AppColors.navy700,
      brightness: Brightness.light,
    ).copyWith(
      primary: AppColors.navy700,
      onPrimary: Colors.white,
      secondary: AppColors.teal700,
      onSecondary: Colors.white,
      surface: AppColors.surface,
      onSurface: AppColors.text,
      onSurfaceVariant: AppColors.textSecondary,
      outline: AppColors.border,
      outlineVariant: AppColors.border,
      error: AppColors.error,
      onError: Colors.white,
    );

    final buttonShape = RoundedRectangleBorder(borderRadius: AppRadius.medium);
    const buttonText = TextStyle(fontSize: 16, fontWeight: FontWeight.w600);

    OutlineInputBorder inputBorder(Color color, [double width = 1]) =>
        OutlineInputBorder(
          borderRadius: AppRadius.medium,
          borderSide: BorderSide(color: color, width: width),
        );

    return base.copyWith(
      colorScheme: colorScheme,
      scaffoldBackgroundColor: AppColors.background,
      textTheme: textTheme,
      primaryTextTheme: textTheme,

      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.surface,
        foregroundColor: AppColors.text,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: textTheme.titleLarge?.copyWith(
          fontWeight: FontWeight.w700,
          color: AppColors.text,
        ),
      ),

      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.navy700,
          foregroundColor: Colors.white,
          disabledBackgroundColor: AppColors.navy700.withValues(alpha: 0.4),
          disabledForegroundColor: Colors.white70,
          elevation: 0,
          minimumSize: const Size.fromHeight(52),
          shape: buttonShape,
          textStyle: buttonText,
        ),
      ),

      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.text,
          backgroundColor: AppColors.surface,
          side: const BorderSide(color: AppColors.border),
          minimumSize: const Size.fromHeight(52),
          shape: buttonShape,
          textStyle: buttonText,
        ),
      ),

      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.navy700,
          textStyle: const TextStyle(fontWeight: FontWeight.w600),
        ),
      ),

      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surface,
        hintStyle: const TextStyle(color: AppColors.textSecondary),
        prefixIconColor: AppColors.textSecondary,
        suffixIconColor: AppColors.textSecondary,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        enabledBorder: inputBorder(AppColors.border),
        focusedBorder: inputBorder(AppColors.navy700, 1.5),
        errorBorder: inputBorder(AppColors.error),
        focusedErrorBorder: inputBorder(AppColors.error, 1.5),
        errorStyle: const TextStyle(color: AppColors.error),
      ),

      cardTheme: CardThemeData(
        color: AppColors.surface,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: AppRadius.large,
          side: const BorderSide(color: AppColors.border),
        ),
      ),

      chipTheme: base.chipTheme.copyWith(
        backgroundColor: AppColors.surface,
        side: const BorderSide(color: AppColors.border),
        shape: RoundedRectangleBorder(borderRadius: AppRadius.pillShape),
        labelStyle: const TextStyle(color: AppColors.navy700),
      ),

      dividerTheme: const DividerThemeData(
        color: AppColors.border,
        thickness: 1,
        space: 1,
      ),

      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: AppColors.navy700,
      ),

      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppColors.navy900,
        contentTextStyle: const TextStyle(color: Colors.white),
        shape: RoundedRectangleBorder(borderRadius: AppRadius.medium),
      ),

      dialogTheme: DialogThemeData(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: AppRadius.large),
      ),

      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
      ),

      tooltipTheme: TooltipThemeData(
        decoration: BoxDecoration(
          color: AppColors.navy900,
          borderRadius: AppRadius.small,
        ),
        textStyle: const TextStyle(color: Colors.white, fontSize: 12),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ),
    );
  }

  // ── Compatibilidade com código antigo ──────────────────────────────
  // Mantidos para não quebrar arquivos que ainda usam os nomes antigos
  // (ex: gradient_button.dart). Serão removidos na migração das telas.

  @Deprecated('Use AppColors.teal500')
  static const Color accentStart = AppColors.teal500;
  @Deprecated('Use AppColors.navy700')
  static const Color accentEnd = AppColors.navy700;
  @Deprecated('Use AppColors.navy700')
  static const Color accentMid = AppColors.navy700;
  @Deprecated('Use AppColors.navy900')
  static const Color darkBackground = AppColors.navy900;
  @Deprecated('Use AppColors.surface')
  static const Color lightBackground = AppColors.surface;
  @Deprecated('Use AppGradients.hero')
  static const LinearGradient primaryGradient = AppGradients.hero;

  /// O tema escuro ainda não foi desenhado; por enquanto é o mesmo do claro.
  @Deprecated('Tema escuro ainda não desenhado; use lightTheme')
  static ThemeData get darkTheme => lightTheme;
}