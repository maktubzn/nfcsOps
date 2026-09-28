import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../../core/services/nfc_service.dart';
import '../../../../core/theme/app_colors.dart';

enum NfcWriteState {
  writing,
  success,
  error,
}

class NfcWriteModal extends StatefulWidget {
  final String url;
  final String? companyName;
  final VoidCallback? onCompleted;

  const NfcWriteModal({
    super.key,
    required this.url,
    this.companyName,
    this.onCompleted,
  });

  static Future<bool?> show(
    BuildContext context, {
    required String url,
    String? companyName,
    VoidCallback? onCompleted,
  }) {
    return showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF161715),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (ctx) => NfcWriteModal(
        url: url,
        companyName: companyName,
        onCompleted: onCompleted,
      ),
    );
  }

  @override
  State<NfcWriteModal> createState() => _NfcWriteModalState();
}

class _NfcWriteModalState extends State<NfcWriteModal> with SingleTickerProviderStateMixin {
  late final AnimationController _pulseCtrl;
  late final Animation<double> _pulseAnimation;

  NfcWriteState _state = NfcWriteState.writing;
  String _message = 'Aproxime o cartão ou placa NFC da traseira do celular.';

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 0.88, end: 1.12).animate(
      CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut),
    );

    _startWriting();
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    NfcService.instance.stopSession();
    super.dispose();
  }

  Future<void> _startWriting() async {
    if (!mounted) return;
    setState(() {
      _state = NfcWriteState.writing;
      _message = 'Aproxime o cartão ou placa NFC da traseira do celular.';
    });

    if (kIsWeb) {
      setState(() {
        _state = NfcWriteState.error;
        _message = 'Gravação física de rádio NFC está disponível apenas no aplicativo Android.';
      });
      return;
    }

    final hw = await NfcService.instance.checkHardwareStatus();
    if (hw == NfcHardwareStatus.disabled) {
      if (mounted) {
        setState(() {
          _state = NfcWriteState.error;
          _message = 'O sensor NFC do celular está desativado nas configurações do sistema. Ative o NFC para continuar.';
        });
      }
      return;
    } else if (hw == NfcHardwareStatus.unsupported) {
      if (mounted) {
        setState(() {
          _state = NfcWriteState.error;
          _message = 'Este aparelho não possui hardware sensor NFC.';
        });
      }
      return;
    }

    await NfcService.instance.writeNdefUrl(
      url: widget.url,
      onSuccess: () {
        if (!mounted) return;
        HapticFeedback.heavyImpact();
        setState(() {
          _state = NfcWriteState.success;
          _message = 'Chip NFC gravado com sucesso!';
        });
        widget.onCompleted?.call();
      },
      onError: (err) {
        if (!mounted) return;
        HapticFeedback.vibrate();
        setState(() {
          _state = NfcWriteState.error;
          _message = err;
        });
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
        left: 20,
        right: 20,
        top: 20,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag handle
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.white24,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 20),

          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Gravar Chip NFC',
                    style: TextStyle(fontFamily: 'Inter', fontSize: 18, fontWeight: FontWeight.w700, color: Colors.white),
                  ),
                  if (widget.companyName != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      widget.companyName!,
                      style: const TextStyle(fontFamily: 'Inter', fontSize: 13, color: Color(0xFF9E9E9E)),
                    ),
                  ],
                ],
              ),
              IconButton(
                icon: const Icon(Icons.close, color: Colors.white70),
                onPressed: () => Navigator.of(context).pop(_state == NfcWriteState.success),
              ),
            ],
          ),

          const SizedBox(height: 28),

          // Visual Circle
          if (_state == NfcWriteState.writing)
            ScaleTransition(
              scale: _pulseAnimation,
              child: Container(
                width: 110,
                height: 110,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.orangeAction.withValues(alpha: 0.15),
                  border: Border.all(color: AppColors.orangeAction, width: 2),
                ),
                child: const Center(
                  child: Icon(LucideIcons.nfc, color: AppColors.orangeAction, size: 52),
                ),
              ),
            )
          else if (_state == NfcWriteState.success)
            Container(
              width: 110,
              height: 110,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF22C55E).withValues(alpha: 0.15),
                border: Border.all(color: const Color(0xFF22C55E), width: 2),
              ),
              child: const Center(
                child: Icon(Icons.check_circle_outline, color: Color(0xFF22C55E), size: 60),
              ),
            )
          else
            Container(
              width: 110,
              height: 110,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFFEF4444).withValues(alpha: 0.15),
                border: Border.all(color: const Color(0xFFEF4444), width: 2),
              ),
              child: const Center(
                child: Icon(Icons.error_outline, color: Color(0xFFEF4444), size: 60),
              ),
            ),

          const SizedBox(height: 24),

          // Status message
          Text(
            _message,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: _state == NfcWriteState.error
                  ? const Color(0xFFEF4444)
                  : (_state == NfcWriteState.success ? const Color(0xFF22C55E) : Colors.white),
            ),
          ),

          const SizedBox(height: 14),

          // URL preview card
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: const Color(0xFF1E201D),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFF282A26)),
            ),
            child: Row(
              children: [
                const Icon(LucideIcons.link, size: 14, color: AppColors.orangeAction),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    widget.url,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontFamily: 'Inter', fontSize: 12, color: Color(0xFFB0B0B0)),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Action buttons
          if (_state == NfcWriteState.error) ...[
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.orangeAction,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                ),
                onPressed: _startWriting,
                icon: const Icon(Icons.refresh, size: 18),
                label: const Text('Tentar Novamente', style: TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.w700)),
              ),
            ),
          ] else if (_state == NfcWriteState.success) ...[
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF22C55E),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                ),
                onPressed: () => Navigator.of(context).pop(true),
                child: const Text('Concluído', style: TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.w700)),
              ),
            ),
          ] else ...[
            SizedBox(
              width: double.infinity,
              height: 48,
              child: OutlinedButton(
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.white70,
                  side: const BorderSide(color: Color(0xFF333532)),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                ),
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Cancelar', style: TextStyle(fontFamily: 'Inter')),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
