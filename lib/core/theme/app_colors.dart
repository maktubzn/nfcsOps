import 'package:flutter/material.dart';

/// Tokens cromáticos fundamentais do NFC Ops, aferidos diretamente das pranchas de design.
abstract class AppColors {
  /// Preto profundo do plano de fundo (#0D0E0D ~ #10110F)
  static const Color background = Color(0xFF0D0E0D);

  /// Superfície escura de cards secundários e painéis (#1B1C1A)
  static const Color surfaceDark = Color(0xFF1B1C1A);

  /// Superfície de destaque creme dos cards principais (#F0EDE0 ~ #ECEBDE)
  static const Color surfaceCream = Color(0xFFF0EDE0);

  /// Creme suave para containers internos de cards claros (#E5E1D3)
  static const Color creamSubtle = Color(0xFFE5E1D3);

  /// Laranja vibrante para CTAs e ênfases de ação (#FD4701 ~ #FF4F0A)
  static const Color orangeAction = Color(0xFFFD4701);

  /// Lilás de apoio para badges, filtros e categorias (#A0A7FC ~ #A5ADEB)
  static const Color lilacSupport = Color(0xFFA0A7FC);

  /// Verde vibrante para status saudável e aprovações (#89ED46 ~ #96F044)
  static const Color greenSuccess = Color(0xFF89ED46);

  /// Amarelo para status de atenção / alertas
  static const Color yellowWarning = Color(0xFFF59E0B);

  /// Vermelho para status de erro e ações destrutivas
  static const Color redError = Color(0xFFEF4444);

  /// Cinza neutro para status manual
  static const Color greyNeutral = Color(0xFF9CA3AF);

  /// Cor de bordas para cards e inputs no tema escuro (#282A26)
  static const Color borderDark = Color(0xFF282A26);

  /// Cor de bordas sutis em cards creme (#DDD8C8)
  static const Color borderCream = Color(0xFFDDD8C8);

  /// Textos claros (sobre fundo escuro)
  static const Color textLightPrimary = Color(0xFFFFFFFF);
  static const Color textLightSecondary = Color(0xFF9E9E9E);
  static const Color textLightMuted = Color(0xFF6B7280);

  /// Textos escuros (sobre fundo creme)
  static const Color textDarkPrimary = Color(0xFF10110F);
  static const Color textDarkSecondary = Color(0xFF4B5563);
  static const Color textDarkMuted = Color(0xFF6B7280);
}
