import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../core/models/company.dart';
import '../../../core/models/dynamic_qr_code.dart';
import '../../../core/providers/app_providers.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/nfc_app_header.dart';

class QrLibraryScreen extends ConsumerStatefulWidget {
  const QrLibraryScreen({super.key});

  @override
  ConsumerState<QrLibraryScreen> createState() => _QrLibraryScreenState();
}

class _QrLibraryScreenState extends ConsumerState<QrLibraryScreen> {
  final TextEditingController _searchCtrl = TextEditingController();

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final qrCodesAsync = ref.watch(qrCodesStreamProvider);
    final companiesAsync = ref.watch(companiesStreamProvider);

    final allQrCodes = qrCodesAsync.value ?? [];
    final companies = companiesAsync.value ?? [];

    final query = _searchCtrl.text.trim().toLowerCase();
    final filtered = allQrCodes.where((qr) {
      if (query.isEmpty) return true;
      final code = qr.shortCode.toLowerCase();
      final dest = qr.currentDestination.toLowerCase();
      final comp = companies.where((c) => c.id == qr.companyId).firstOrNull;
      final compName = comp?.tradeName.toLowerCase() ?? '';
      return code.contains(query) || dest.contains(query) || compName.contains(query);
    }).toList();

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.only(bottom: 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              NfcAppHeader(
                showWordmark: true,
                onNotificationTap: () => context.push('/activities'),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 6),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'QR Codes Dinâmicos',
                              style: TextStyle(
                                fontFamily: 'Inter',
                                fontSize: 26,
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                                letterSpacing: -0.6,
                              ),
                            ),
                            SizedBox(height: 2),
                            Text(
                              'Links permanentes com destino editável.',
                              style: TextStyle(fontFamily: 'Inter', fontSize: 13, color: Color(0xFF9E9E9E)),
                            ),
                          ],
                        ),
                        IconButton(
                          onPressed: () => context.pop(),
                          icon: const Icon(Icons.close, color: Colors.white70),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Barra de busca
                    Container(
                      height: 48,
                      decoration: BoxDecoration(
                        color: const Color(0xFF1C1D1B),
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: const Color(0xFF282A26)),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Row(
                        children: [
                          const Icon(LucideIcons.search, size: 18, color: Color(0xFF8E918F)),
                          const SizedBox(width: 10),
                          Expanded(
                            child: TextField(
                              controller: _searchCtrl,
                              onChanged: (_) => setState(() {}),
                              style: const TextStyle(fontFamily: 'Inter', fontSize: 14, color: Colors.white),
                              decoration: const InputDecoration(
                                hintText: 'Código, empresa ou link de destino',
                                hintStyle: TextStyle(fontFamily: 'Inter', fontSize: 14, color: Color(0xFF6B7280)),
                                border: InputBorder.none,
                                isDense: true,
                              ),
                            ),
                          ),
                          if (_searchCtrl.text.isNotEmpty)
                            InkWell(
                              onTap: () => setState(() => _searchCtrl.clear()),
                              child: const Icon(Icons.close, size: 18, color: Color(0xFF9E9E9E)),
                            ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 16),

                    if (qrCodesAsync.isLoading)
                      const Center(child: Padding(padding: EdgeInsets.all(40), child: CircularProgressIndicator(color: AppColors.orangeAction)))
                    else if (filtered.isEmpty)
                      Container(
                        padding: const EdgeInsets.all(32),
                        decoration: BoxDecoration(
                          color: const Color(0xFF161715),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: const Color(0xFF282A26)),
                        ),
                        child: Center(
                          child: Column(
                            children: [
                              const Icon(Icons.qr_code_2, size: 40, color: Color(0xFF6B7280)),
                              const SizedBox(height: 12),
                              Text(
                                allQrCodes.isEmpty
                                    ? 'Nenhum QR Code dinâmico criado.\nEles são gerados ao criar uma placa para uma empresa.'
                                    : 'Nenhum QR encontrado para o termo pesquisado.',
                                textAlign: TextAlign.center,
                                style: const TextStyle(fontFamily: 'Inter', fontSize: 14, color: Color(0xFF9E9E9E), height: 1.4),
                              ),
                            ],
                          ),
                        ),
                      )
                    else
                      ...filtered.map((qr) {
                        final comp = companies.where((c) => c.id == qr.companyId).firstOrNull;
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: _buildQrCard(qr, comp),
                        );
                      }),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQrCard(DynamicQrCode qr, Company? company) {
    return InkWell(
      onTap: () => context.push('/qr-codes/${qr.id}'),
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF1C1D1B),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFF282A26)),
        ),
        child: Row(
          children: [
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: const Color(0xFF222421),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFF333532)),
              ),
              child: const Icon(Icons.qr_code_2, color: AppColors.orangeAction, size: 28),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        qr.shortCode,
                        style: const TextStyle(
                          fontFamily: 'Courier',
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                          letterSpacing: 1.0,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: qr.status == 'ativo' ? const Color(0xFF22C55E).withValues(alpha: 0.15) : Colors.red.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          qr.status.toUpperCase(),
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: qr.status == 'ativo' ? const Color(0xFF22C55E) : Colors.red,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 3),
                  Text(
                    company?.tradeName ?? 'Empresa não identificada',
                    style: const TextStyle(fontFamily: 'Inter', fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFFECEBDE)),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    qr.currentDestination,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontFamily: 'Inter', fontSize: 12, color: Color(0xFF9E9E9E)),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: Color(0xFF6B7280), size: 20),
          ],
        ),
      ),
    );
  }
}
