import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../../core/models/activity_entry.dart';
import '../../../core/models/dynamic_qr_code.dart';
import '../../../core/providers/app_providers.dart';
import '../../../core/services/url_launcher_service.dart';
import '../../../core/theme/app_colors.dart';

class QrDetailScreen extends ConsumerStatefulWidget {
  final String qrId;

  const QrDetailScreen({super.key, required this.qrId});

  @override
  ConsumerState<QrDetailScreen> createState() => _QrDetailScreenState();
}

class _QrDetailScreenState extends ConsumerState<QrDetailScreen> {
  final TextEditingController _destinationCtrl = TextEditingController();
  bool _isEditing = false;
  bool _isSaving = false;

  @override
  void dispose() {
    _destinationCtrl.dispose();
    super.dispose();
  }

  void _copyToClipboard(String text, String message) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.greenSuccess,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _handleSaveDestination(DynamicQrCode qr) async {
    final newUrl = _destinationCtrl.text.trim();
    if (newUrl.isEmpty || !newUrl.startsWith('http')) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Informe uma URL válida iniciando com http:// ou https://'), backgroundColor: AppColors.redError),
      );
      return;
    }

    if (newUrl == qr.currentDestination) {
      setState(() => _isEditing = false);
      return;
    }

    setState(() => _isSaving = true);
    try {
      final repo = ref.read(qrCodeRepositoryProvider);
      final actRepo = ref.read(activityRepositoryProvider);
      final curUser = ref.read(currentUserProvider);

      await repo.updateDestination(
        qr.id,
        newUrl,
        changedByUid: curUser?.uid ?? 'usr-operador',
        changedByName: curUser?.displayName ?? 'Operador',
      );

      await actRepo.logActivity(ActivityEntry(
        id: 'act-${DateTime.now().millisecondsSinceEpoch}',
        actorUid: curUser?.uid ?? 'usr-operador',
        actorName: curUser?.displayName ?? 'Operador',
        actionType: 'update_qr_destination',
        description: 'Destino do QR [${qr.shortCode}] alterado para "$newUrl".',
        entityType: 'qr_code',
        entityId: qr.id,
        timestamp: DateTime.now(),
      ));

      if (!mounted) return;
      setState(() {
        _isEditing = false;
        _isSaving = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Destino atualizado com sucesso! A placa física já redireciona para o novo link.'),
          backgroundColor: AppColors.greenSuccess,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _isSaving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao atualizar destino: $e'), backgroundColor: AppColors.redError),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final qrCodesAsync = ref.watch(qrCodesStreamProvider);
    final companiesAsync = ref.watch(companiesStreamProvider);

    final allQrCodes = qrCodesAsync.value ?? [];
    final companies = companiesAsync.value ?? [];

    final qr = allQrCodes.where((q) => q.id == widget.qrId).firstOrNull;

    if (qr == null) {
      return Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(backgroundColor: Colors.transparent, leading: IconButton(icon: const Icon(Icons.arrow_back, color: Colors.white), onPressed: () => context.pop())),
        body: const Center(child: Text('QR Code não encontrado.', style: TextStyle(color: Colors.white70))),
      );
    }

    final company = companies.where((c) => c.id == qr.companyId).firstOrNull;
    final companyName = company?.tradeName ?? 'Empresa';

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        leading: IconButton(icon: const Icon(Icons.arrow_back, color: Colors.white), onPressed: () => context.pop()),
        title: Text(
          'QR [${qr.shortCode}]',
          style: const TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.w700, color: Colors.white, fontSize: 18),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Card do QR Code com fundo creme
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: AppColors.surfaceCream,
                  borderRadius: BorderRadius.circular(28),
                ),
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.08),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: QrImageView(
                        data: qr.publicUrl,
                        version: QrVersions.auto,
                        size: 180.0,
                        backgroundColor: Colors.white,
                        eyeStyle: const QrEyeStyle(eyeShape: QrEyeShape.square, color: Color(0xFF10110F)),
                        dataModuleStyle: const QrDataModuleStyle(dataModuleShape: QrDataModuleShape.square, color: Color(0xFF10110F)),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Código: ${qr.shortCode}',
                      style: const TextStyle(fontFamily: 'Courier', fontSize: 18, fontWeight: FontWeight.w800, color: Color(0xFF10110F), letterSpacing: 1.2),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      companyName,
                      style: const TextStyle(fontFamily: 'Inter', fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF6B7280)),
                    ),
                    const SizedBox(height: 10),
                    // Caixa do link permanente
                    InkWell(
                      onTap: () => _copyToClipboard(qr.publicUrl, 'URL pública permanente copiada!'),
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE2E1D4),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Flexible(
                              child: Text(
                                qr.publicUrl,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(fontFamily: 'Courier', fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF10110F)),
                              ),
                            ),
                            const SizedBox(width: 6),
                            const Icon(LucideIcons.copy, size: 14, color: Color(0xFF10110F)),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // Card do Destino Atual
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF1C1D1B),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFF282A26)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Destino Atual (Redirecionamento)',
                          style: TextStyle(fontFamily: 'Inter', fontSize: 14, fontWeight: FontWeight.w700, color: Colors.white),
                        ),
                        if (!_isEditing)
                          InkWell(
                            onTap: () {
                              _destinationCtrl.text = qr.currentDestination;
                              setState(() => _isEditing = true);
                            },
                            child: const Row(
                              children: [
                                Icon(Icons.edit, size: 14, color: AppColors.orangeAction),
                                SizedBox(width: 4),
                                Text('Alterar', style: TextStyle(fontFamily: 'Inter', fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.orangeAction)),
                              ],
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    if (_isEditing) ...[
                      TextField(
                        controller: _destinationCtrl,
                        style: const TextStyle(color: Colors.white, fontFamily: 'Inter', fontSize: 14),
                        decoration: InputDecoration(
                          hintText: 'https://...',
                          hintStyle: const TextStyle(color: Color(0xFF6B7280)),
                          filled: true,
                          fillColor: const Color(0xFF222421),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          TextButton(
                            onPressed: () => setState(() => _isEditing = false),
                            child: const Text('Cancelar', style: TextStyle(color: Colors.white70)),
                          ),
                          const SizedBox(width: 8),
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.orangeAction,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            ),
                            onPressed: _isSaving ? null : () => _handleSaveDestination(qr),
                            child: _isSaving
                                ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                                : const Text('Salvar Novo Destino', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
                          ),
                        ],
                      ),
                    ] else ...[
                      Text(
                        qr.currentDestination,
                        style: const TextStyle(fontFamily: 'Inter', fontSize: 14, color: Color(0xFFECEBDE), height: 1.3),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          OutlinedButton.icon(
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.white,
                              side: const BorderSide(color: Color(0xFF333532)),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            ),
                            onPressed: () => UrlLauncherService.openUrlWithFeedback(context, qr.currentDestination),
                            icon: const Icon(LucideIcons.externalLink, size: 14),
                            label: const Text('Testar destino'),
                          ),
                          const SizedBox(width: 8),
                          OutlinedButton.icon(
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.white,
                              side: const BorderSide(color: Color(0xFF333532)),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            ),
                            onPressed: () => _copyToClipboard(qr.currentDestination, 'Destino copiado!'),
                            icon: const Icon(LucideIcons.copy, size: 14),
                            label: const Text('Copiar'),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // Histórico de alterações de destino
              const Text(
                'Histórico de Alterações',
                style: TextStyle(fontFamily: 'Inter', fontSize: 16, fontWeight: FontWeight.w700, color: Colors.white),
              ),
              const SizedBox(height: 8),
              if (qr.history.isEmpty)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF161715),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFF282A26)),
                  ),
                  child: const Text(
                    'Destino original nunca foi alterado após a criação.',
                    style: TextStyle(fontFamily: 'Inter', fontSize: 13, color: Color(0xFF9E9E9E)),
                  ),
                )
              else
                ...qr.history.reversed.map((h) {
                  final formattedDate = DateFormat('dd/MM/yyyy HH:mm').format(h.changedAt);
                  return Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1C1D1B),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: const Color(0xFF282A26)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              h.changedByName,
                              style: const TextStyle(fontFamily: 'Inter', fontSize: 13, fontWeight: FontWeight.w700, color: Colors.white),
                            ),
                            Text(
                              formattedDate,
                              style: const TextStyle(fontFamily: 'Inter', fontSize: 11, color: Color(0xFF8E918F)),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'De: ${h.previousUrl}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontFamily: 'Inter', fontSize: 12, color: Colors.redAccent),
                        ),
                        Text(
                          'Para: ${h.newUrl}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontFamily: 'Inter', fontSize: 12, color: Color(0xFF22C55E)),
                        ),
                      ],
                    ),
                  );
                }),
            ],
          ),
        ),
      ),
    );
  }
}
