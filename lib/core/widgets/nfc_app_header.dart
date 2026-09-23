import 'package:flutter/material.dart';
import '../../features/auth/presentation/widgets/nfc_wave_icon.dart';
import '../theme/app_colors.dart';

/// Cabeçalho superior padrão das telas do NFC Ops.
/// Suporta dois modos:
/// 1. Modo perfil: Avatar com inicial ('G'), 'Bom dia, Gustavo' + Sino de notificação.
/// 2. Modo marca: Wordmark 'NFC Ops' + Sino de notificação ou botão voltar.
class NfcAppHeader extends StatelessWidget {
  final String? greeting;
  final String? userName;
  final String? userInitial;
  final bool showWordmark;
  final bool showBackButton;
  final VoidCallback? onBack;
  final VoidCallback? onNotificationTap;
  final bool hasUnreadNotifications;
  final EdgeInsetsGeometry? padding;
  final double? waveIconWidth;
  final double? waveIconHeight;
  final double? waveIconSize;

  const NfcAppHeader({
    super.key,
    this.greeting = 'Bom dia,',
    this.userName = 'Gustavo',
    this.userInitial = 'G',
    this.showWordmark = false,
    this.showBackButton = false,
    this.onBack,
    this.onNotificationTap,
    this.hasUnreadNotifications = true,
    this.padding,
    this.waveIconWidth,
    this.waveIconHeight,
    this.waveIconSize,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: padding ?? const EdgeInsets.fromLTRB(16, 25, 16, 0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          if (showBackButton)
            InkWell(
              onTap: onBack ?? () => Navigator.of(context).maybePop(),
              borderRadius: BorderRadius.circular(25),
              child: Container(
                width: 50,
                height: 50,
                decoration: const BoxDecoration(
                  color: Color(0xFF222422),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.arrow_back,
                  color: Colors.white,
                  size: 20,
                ),
              ),
            )
          else if (showWordmark)
            Row(
              children: [
                NfcWaveIcon(
                  width: waveIconWidth,
                  height: waveIconHeight,
                  size: waveIconSize ?? 26,
                ),
                const SizedBox(width: 8),
                RichText(
                  text: const TextSpan(
                    children: [
                      TextSpan(
                        text: 'NFC ',
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 21,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                          letterSpacing: -0.3,
                        ),
                      ),
                      TextSpan(
                        text: 'Ops',
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 21,
                          fontWeight: FontWeight.w400,
                          color: Colors.white,
                          letterSpacing: -0.3,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            )
          else
            Expanded(
              child: Row(
                children: [
                  Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      color: const Color(0xFF222422),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: const Color(0xFF333333),
                        width: 1.0,
                      ),
                    ),
                    child: Center(
                      child: Text(
                        userInitial ?? 'G',
                        style: const TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          greeting ?? 'Bom dia,',
                          style: const TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 12,
                            fontWeight: FontWeight.w400,
                            color: Color(0xFF9E9E9E),
                          ),
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                        ),
                        Text(
                          userName ?? 'Gustavo',
                          style: const TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 17,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                            letterSpacing: -0.2,
                          ),
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                ],
              ),
            ),

          // Botão Sino de Notificações
          InkWell(
            onTap: onNotificationTap,
            borderRadius: BorderRadius.circular(25),
            child: Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: const Color(0xFF222422),
                shape: BoxShape.circle,
                border: Border.all(
                  color: const Color(0xFF333333),
                  width: 1.0,
                ),
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  const Icon(
                    Icons.notifications,
                    color: Colors.white,
                    size: 20,
                  ),
                  if (hasUnreadNotifications)
                    Positioned(
                      top: 11,
                      right: 12,
                      child: Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                          color: AppColors.orangeAction,
                          shape: BoxShape.circle,
                        ),
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
