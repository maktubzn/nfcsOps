import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/providers/app_providers.dart';
import '../../../core/theme/app_colors.dart';

class QrRedirectScreen extends ConsumerStatefulWidget {
  final String shortCode;

  const QrRedirectScreen({super.key, required this.shortCode});

  @override
  ConsumerState<QrRedirectScreen> createState() => _QrRedirectScreenState();
}

class _QrRedirectScreenState extends ConsumerState<QrRedirectScreen> {
  bool _isLoading = true;
  String? _destinationUrl;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _handleRedirect();
  }

  Future<void> _handleRedirect() async {
    try {
      final repo = ref.read(qrCodeRepositoryProvider);
      final qr = await repo.getQrCodeByShortCode(widget.shortCode);

      if (qr == null) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'QR Code não encontrado ou desativado.';
        });
        return;
      }

      if (qr.status != 'ativo') {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Este QR Code foi temporariamente pausado pela empresa.';
        });
        return;
      }

      await repo.incrementScanCount(qr.id);

      setState(() {
        _isLoading = false;
        _destinationUrl = qr.currentDestination;
      });

      final uri = Uri.parse(qr.currentDestination);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Erro ao processar redirecionamento: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (_isLoading) ...[
                  const CircularProgressIndicator(color: AppColors.orangeAction),
                  const SizedBox(height: 20),
                  Text(
                    'Redirecionando [${widget.shortCode}]...',
                    style: const TextStyle(fontFamily: 'Inter', fontSize: 16, color: Colors.white70),
                  ),
                ] else if (_errorMessage != null) ...[
                  const Icon(Icons.error_outline, size: 56, color: AppColors.redError),
                  const SizedBox(height: 16),
                  Text(
                    _errorMessage!,
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontFamily: 'Inter', fontSize: 16, color: Colors.white),
                  ),
                ] else if (_destinationUrl != null) ...[
                  const Icon(Icons.check_circle_outline, size: 56, color: AppColors.greenSuccess),
                  const SizedBox(height: 16),
                  const Text(
                    'Redirecionando para:',
                    style: TextStyle(fontFamily: 'Inter', fontSize: 14, color: Color(0xFF9E9E9E)),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _destinationUrl!,
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontFamily: 'Inter', fontSize: 16, fontWeight: FontWeight.w700, color: Colors.white),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.orangeAction,
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                    ),
                    onPressed: () {
                      final uri = Uri.parse(_destinationUrl!);
                      launchUrl(uri, mode: LaunchMode.externalApplication);
                    },
                    child: const Text('Abrir Link Agora', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
