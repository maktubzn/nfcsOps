import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import 'nfc_wave_icon.dart';

/// Ilustração central de hero para a tela de Login S01:
/// Um disco circular laranja (#FD4701) com a placa NFC acrílica escura inclinada (-24 graus).
class NfcHeroIllustration extends StatelessWidget {
  final double size;

  const NfcHeroIllustration({super.key, this.size = 236.0});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // 1. Círculo de fundo laranja vibrante (#FD4701)
          Container(
            width: size,
            height: size,
            decoration: const BoxDecoration(
              color: AppColors.orangeAction,
              shape: BoxShape.circle,
            ),
          ),

          // 2. Placa acrílica NFC escura inclinada (-24 graus) com chanfro 3D
          Transform.rotate(
            angle: -24.0 * (math.pi / 180.0),
            child: SizedBox(
              width: size * 0.82,
              height: size * 0.82,
              child: Stack(
                children: [
                  // Chanfro 3D translúcido / espessura acrílica no canto inferior esquerdo
                  Positioned(
                    left: -2.5,
                    bottom: -3.5,
                    child: Container(
                      width: size * 0.82,
                      height: size * 0.82,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.22),
                        borderRadius: BorderRadius.circular(26.0),
                      ),
                    ),
                  ),

                  // Placa acrílica principal
                  Container(
                    width: size * 0.82,
                    height: size * 0.82,
                    decoration: BoxDecoration(
                      color: const Color(0xFF222422),
                      borderRadius: BorderRadius.circular(26.0),
                      border: Border.all(
                        color: const Color(0xFF383B37),
                        width: 1.5,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.55),
                          blurRadius: 22,
                          offset: const Offset(4, 12),
                        ),
                      ],
                    ),
                    child: Stack(
                      children: [
                        // Gradiente de reflexo no topo do acrílico
                        Positioned.fill(
                          child: Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(25.0),
                              gradient: LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [
                                  Colors.white.withValues(alpha: 0.10),
                                  Colors.transparent,
                                ],
                              ),
                            ),
                          ),
                        ),

                        // Conteúdo da placa: "NFC" em cinza discreto + ondas laranjas dominantes
                        Center(
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Text(
                                'NFC',
                                style: TextStyle(
                                  fontFamily: 'Inter',
                                  fontSize: size * 0.095,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: -0.3,
                                  color: const Color(0xFF7A7D79),
                                ),
                              ),
                              SizedBox(width: size * 0.035),
                              NfcWaveIcon(
                                width: size * 0.22,
                                height: size * 0.35,
                                color: AppColors.orangeAction,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
