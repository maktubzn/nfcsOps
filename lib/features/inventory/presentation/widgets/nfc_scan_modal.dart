import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../../core/models/company.dart';
import '../../../../core/providers/app_providers.dart';
import '../../../../core/services/nfc_service.dart';
import '../../../../core/theme/app_colors.dart';

enum NfcScanState {
  scanning,
  processing,
  foundExisting,
  foundNew,
  error,
}

/// Modal nativo de leitura NFC com animação de aproximação e roteamento inteligente.
class NfcScanModal extends ConsumerStatefulWidget {
  final List<Company> companies;
  final void Function(String nfcUid, String? ndefUrl)? onNewTagDetected;

  const NfcScanModal({
    super.key,
    required this.companies,
    this.onNewTagDetected,
  });

  static Future<void> show(
    BuildContext context, {
    required List<Company> companies,
    void Function(String nfcUid, String? ndefUrl)? onNewTagDetected,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF161715),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (ctx) => NfcScanModal(
        companies: companies,
        onNewTagDetected: onNewTagDetected,
      ),
    );
  }

  @override
  ConsumerState<NfcScanModal> createState() => _NfcScanModalState();
}

class _NfcScanModalState extends ConsumerState<NfcScanModal>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  late final AnimationController _pulseController;
  late final Animation<double> _pulseAnimation;

  NfcScanState _state = NfcScanState.scanning;
  String _statusMessage = 'Aproxime o cartão ou placa NFC da traseira do aparelho.';
  String? _detectedUid;
  final TextEditingController _simulatedUidCtrl = TextEditingController(text: '04:A2:3B:5C:89:1F');
  bool _showSimulator = false;
  bool _isNfcDisabled = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 0.85, end: 1.15).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _startNfcSession();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused || state == AppLifecycleState.inactive) {
      NfcService.instance.stopSession();
    } else if (state == AppLifecycleState.resumed && _state == NfcScanState.scanning && mounted) {
      _startNfcSession();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _pulseController.dispose();
    _simulatedUidCtrl.dispose();
    NfcService.instance.stopSession();
    super.dispose();
  }

  Future<void> _startNfcSession() async {
    if (!mounted) return;
    setState(() {
      _state = NfcScanState.scanning;
      _isNfcDisabled = false;
      _statusMessage = 'Aproxime o cartão ou placa NFC da traseira do aparelho.';
    });

    final status = await NfcService.instance.checkHardwareStatus();
    if (status == NfcHardwareStatus.disabled) {
      if (mounted) {
        setState(() {
          _isNfcDisabled = true;
          _showSimulator = true;
          _statusMessage = 'O sensor NFC está desativado nas configurações do celular. Ative o NFC para ler placas físicas.';
        });
      }
      return;
    } else if (status == NfcHardwareStatus.unsupported) {
      if (mounted) {
        setState(() {
          _showSimulator = true;
          _statusMessage = 'Sensor NFC não disponível neste dispositivo. Utilize a simulação abaixo.';
        });
      }
      return;
    }

    await NfcService.instance.startReadingSession(
      onDiscovered: (result) {
        if (mounted) {
          _handleTagDiscovered(result.uid, result.ndefUrl);
        }
      },
      onError: (err) {
        if (mounted) {
          setState(() {
            _state = NfcScanState.error;
            _statusMessage = err;
            _showSimulator = true;
          });
        }
      },
    );
  }
  Future<void> _handleTagDiscovered(String uid, String? ndefUrl) async {
    if (!mounted) return;
    try {
      _pulseController.stop();
    } catch (_) {}

    setState(() {
      _state = NfcScanState.processing;
      _detectedUid = uid;
      _statusMessage = 'Tag detectada: $uid\nConsultando inventário...';
    });

    try {
      HapticFeedback.mediumImpact();
    } catch (_) {}

    await NfcService.instance.stopSession();

    final deviceRepo = ref.read(deviceRepositoryProvider);
    final existingDevice = await deviceRepo.getDeviceByNfcUid(uid);

    if (!mounted) return;

    if (existingDevice != null) {
      // Dispositivo já existe -> NÃO duplicar, abrir na tela dele
      setState(() {
        _state = NfcScanState.foundExisting;
        _statusMessage = 'Dispositivo #${existingDevice.batchId.isNotEmpty ? existingDevice.batchId : existingDevice.id} encontrado!';
      });

      await Future.delayed(const Duration(milliseconds: 700));
      if (!mounted) return;

      Navigator.of(context).pop();
      context.push('/inventory/${existingDevice.id}');

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Dispositivo #${existingDevice.batchId} localizado com sucesso!'),
          backgroundColor: AppColors.greenSuccess,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } else {
      // Dispositivo não existe -> abrir cadastro com UID pré-preenchido
      setState(() {
        _state = NfcScanState.foundNew;
        _statusMessage = 'Nova tag NFC detectada ($uid)!\nIniciando cadastro...';
      });

      await Future.delayed(const Duration(milliseconds: 700));
      if (!mounted) return;

      Navigator.of(context).pop();

      if (widget.onNewTagDetected != null) {
        widget.onNewTagDetected!(uid, ndefUrl);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Tag NFC $uid identificada para novo cadastro.'),
            backgroundColor: AppColors.orangeAction,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      physics: const ClampingScrollPhysics(),
      child: Padding(
        padding: EdgeInsets.only(
          left: 20,
          right: 20,
          top: 16,
          bottom: MediaQuery.of(context).viewInsets.bottom + 28,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
          // Drag handle
          Container(
            width: 44,
            height: 4,
            decoration: BoxDecoration(
              color: const Color(0xFF333532),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 20),

          // Título e Ícone
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: AppColors.orangeAction.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: const Center(
                  child: Icon(LucideIcons.radio, color: AppColors.orangeAction, size: 20),
                ),
              ),
              const SizedBox(width: 10),
              const Flexible(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    'Escanear Placa NFC',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          Text(
            _statusMessage,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 13,
              color: _state == NfcScanState.error
                  ? const Color(0xFFEF4444)
                  : _state == NfcScanState.foundExisting
                      ? const Color(0xFF22C55E)
                      : const Color(0xFF9E9E9E),
              height: 1.4,
            ),
          ),

          if (_isNfcDisabled) ...[
            const SizedBox(height: 8),
            TextButton.icon(
              onPressed: _startNfcSession,
              icon: const Icon(Icons.refresh, size: 16, color: AppColors.orangeAction),
              label: const Text(
                'Já ativei o NFC, verificar novamente',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.orangeAction,
                ),
              ),
            ),
          ],

          const SizedBox(height: 28),

          // Animação de Onda NFC
          AnimatedBuilder(
            animation: _pulseAnimation,
            builder: (context, child) {
              final scale = _state == NfcScanState.scanning ? _pulseAnimation.value : 1.0;
              final ringColor = _state == NfcScanState.foundExisting
                  ? const Color(0xFF22C55E)
                  : _state == NfcScanState.foundNew
                      ? AppColors.orangeAction
                      : _state == NfcScanState.error
                          ? const Color(0xFFEF4444)
                          : AppColors.orangeAction;

              return Stack(
                alignment: Alignment.center,
                children: [
                  // Anel Externo Pulsante
                  Container(
                    width: 120 * scale,
                    height: 120 * scale,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: ringColor.withValues(alpha: 0.08),
                    ),
                  ),
                  // Anel Médio
                  Container(
                    width: 96,
                    height: 96,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: ringColor.withValues(alpha: 0.18),
                      border: Border.all(color: ringColor.withValues(alpha: 0.4), width: 1.5),
                    ),
                  ),
                  // Núcleo com ícone
                  Container(
                    width: 68,
                    height: 68,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: const Color(0xFF222421),
                      border: Border.all(color: ringColor, width: 2),
                    ),
                    child: Center(
                      child: _state == NfcScanState.processing
                          ? const SizedBox(
                              width: 28,
                              height: 28,
                              child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white),
                            )
                          : _state == NfcScanState.foundExisting
                              ? const Icon(Icons.check_circle_outline, color: Color(0xFF22C55E), size: 36)
                              : _state == NfcScanState.foundNew
                                  ? const Icon(Icons.add_circle_outline, color: AppColors.orangeAction, size: 36)
                                  : _state == NfcScanState.error
                                      ? const Icon(Icons.error_outline, color: Color(0xFFEF4444), size: 36)
                                      : const Icon(LucideIcons.radio, color: AppColors.orangeAction, size: 32),
                    ),
                  ),
                ],
              );
            },
          ),

          const SizedBox(height: 24),

          if (_detectedUid != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFF222421),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFF2E302C)),
              ),
              child: Text(
                'UID: $_detectedUid',
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                  letterSpacing: 0.5,
                ),
              ),
            ),

          const SizedBox(height: 16),

          // Seletor de simulação (para emulador/testes sem tag física no momento)
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              TextButton.icon(
                onPressed: () => setState(() => _showSimulator = !_showSimulator),
                icon: Icon(
                  _showSimulator ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                  size: 16,
                  color: const Color(0xFF9E9E9E),
                ),
                label: Text(
                  _showSimulator ? 'Ocultar simulador' : 'Simular leitura de tag',
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 12,
                    color: Color(0xFF9E9E9E),
                  ),
                ),
              ),
            ],
          ),

          if (_showSimulator) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF1E201D),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFF2E302C)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Simular aproximação de tag (Emulador/Desktop):',
                    style: TextStyle(fontFamily: 'Inter', fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF9E9E9E)),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _simulatedUidCtrl,
                          style: const TextStyle(color: Colors.white, fontFamily: 'Inter', fontSize: 13),
                          decoration: InputDecoration(
                            hintText: 'Ex: 04:A2:3B:5C:89:1F ou dev-01',
                            hintStyle: const TextStyle(color: Color(0xFF6B7280), fontSize: 12),
                            filled: true,
                            fillColor: const Color(0xFF262925),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton(
                        onPressed: () {
                          final val = _simulatedUidCtrl.text.trim();
                          if (val.isNotEmpty) {
                            _handleTagDiscovered(val, 'https://nfcops.app/d/$val');
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.orangeAction,
                          minimumSize: const Size(0, 38),
                          padding: const EdgeInsets.symmetric(horizontal: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        child: const Text('Simular', style: TextStyle(fontFamily: 'Inter', fontSize: 12, fontWeight: FontWeight.w700, color: Colors.white)),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],

          const SizedBox(height: 12),

          // Botão Cancelar
          OutlinedButton(
            onPressed: () {
              NfcService.instance.stopSession();
              Navigator.of(context).pop();
            },
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xFFCCCCCC),
              side: const BorderSide(color: Color(0xFF2E302C)),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              minimumSize: const Size(double.infinity, 44),
            ),
            child: const Text('Cancelar', style: TextStyle(fontFamily: 'Inter', fontSize: 14, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    ),);
  }
}
