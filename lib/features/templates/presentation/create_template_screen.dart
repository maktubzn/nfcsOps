import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/models/activity_entry.dart';
import '../../../core/models/plate_template.dart';
import '../../../core/providers/app_providers.dart';
import '../../../core/services/qr_scanner_service.dart';
import '../../../core/services/url_launcher_service.dart';
import '../../../core/theme/app_colors.dart';
import 'qr_editor_screen.dart';

/// Tela de criação de modelos de placa em 3 etapas simples e acessíveis (/ponytail).
/// Para templates Canva:
/// 1. Link do Projeto no Canva
/// 2. Foto da arte anexada -> Lê o QR Code automaticamente e preenche o link do QR Code da arte!
class CreateTemplateScreen extends ConsumerStatefulWidget {
  const CreateTemplateScreen({super.key});

  @override
  ConsumerState<CreateTemplateScreen> createState() => _CreateTemplateScreenState();
}

class _CreateTemplateScreenState extends ConsumerState<CreateTemplateScreen> {
  int _currentStep = 0; // 0: Identificação, 1: Arte & Links, 2: Revisão

  final _nameCtrl = TextEditingController();
  final _widthCtrl = TextEditingController(text: '10.0');
  final _heightCtrl = TextEditingController(text: '10.0');
  final _serviceCtrl = TextEditingController(text: 'Instagram');
  final _canvaUrlCtrl = TextEditingController();
  final _qrLinkCtrl = TextEditingController();
  final _finalFileUrlCtrl = TextEditingController();

  String _origin = 'canva'; // 'canva' (padrão) ou 'internal'
  final String _category = 'social';
  final String _productType = 'placa_acrilica';
  String? _localImagePath;
  QrPlacement? _placement;
  bool _isSaving = false;
  bool _isScanningQr = false;
  String? _detectedQrUrl;
  String? _scanMessage;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _widthCtrl.dispose();
    _heightCtrl.dispose();
    _serviceCtrl.dispose();
    _canvaUrlCtrl.dispose();
    _qrLinkCtrl.dispose();
    _finalFileUrlCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final picked = await ImagePicker().pickImage(source: source, imageQuality: 95);
      if (picked == null) return;

      setState(() {
        _localImagePath = picked.path;
        _finalFileUrlCtrl.text = picked.path;
        _isScanningQr = true;
        _scanMessage = 'Analisando arte e lendo QR Code...';
      });

      // Ler bytes e decodificar QR Code automaticamente em pure Dart
      final bytes = await picked.readAsBytes();
      final detected = QrScannerService.decodeFromBytes(bytes);

      setState(() {
        _isScanningQr = false;
        if (detected != null && detected.trim().isNotEmpty) {
          _detectedQrUrl = detected.trim();
          _qrLinkCtrl.text = detected.trim();
          _scanMessage = 'QR Code detectado automaticamente!';
        } else {
          _detectedQrUrl = null;
          _scanMessage = 'Nenhum QR Code encontrado na foto. Você pode inserir o link abaixo.';
        }
      });

      if (!mounted) return;
      if (detected != null && detected.trim().isNotEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ QR Code detectado e preenchido automaticamente!'),
            backgroundColor: AppColors.greenSuccess,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _isScanningQr = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao processar imagem: $e')),
      );
    }
  }

  void _showImageSourceDialog() {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF191A18),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.photo_library, color: AppColors.orangeAction),
                title: const Text('Escolher da Galeria', style: TextStyle(color: Colors.white, fontFamily: 'Inter')),
                onTap: () {
                  Navigator.of(ctx).pop();
                  _pickImage(ImageSource.gallery);
                },
              ),
              ListTile(
                leading: const Icon(Icons.camera_alt, color: AppColors.orangeAction),
                title: const Text('Tirar Foto da Placa', style: TextStyle(color: Colors.white, fontFamily: 'Inter')),
                onTap: () {
                  Navigator.of(ctx).pop();
                  _pickImage(ImageSource.camera);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _openQrEditor() async {
    final w = double.tryParse(_widthCtrl.text.replaceAll(',', '.')) ?? 10.0;
    final h = double.tryParse(_heightCtrl.text.replaceAll(',', '.')) ?? 10.0;
    final res = await Navigator.of(context).push<QrPlacement>(
      MaterialPageRoute(
        builder: (_) => QrEditorScreen(
          localImagePath: _localImagePath,
          imageUrl: _finalFileUrlCtrl.text.isNotEmpty ? _finalFileUrlCtrl.text : null,
          physicalWidthCm: w,
          physicalHeightCm: h,
          initialPlacement: _placement,
        ),
      ),
    );
    if (res != null) setState(() => _placement = res);
  }

  void _nextStep() {
    if (_currentStep == 0) {
      if (_nameCtrl.text.trim().isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Digite o nome do modelo para continuar.')),
        );
        return;
      }
      if (_serviceCtrl.text.trim().isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Informe qual serviço essa placa oferece.')),
        );
        return;
      }
    }
    if (_currentStep < 2) {
      setState(() => _currentStep++);
    } else {
      _saveTemplate();
    }
  }

  void _prevStep() {
    if (_currentStep > 0) {
      setState(() => _currentStep--);
    } else {
      context.pop();
    }
  }

  Future<void> _saveTemplate() async {
    setState(() => _isSaving = true);
    final name = _nameCtrl.text.trim();
    final w = double.tryParse(_widthCtrl.text.replaceAll(',', '.')) ?? 10.0;
    final h = double.tryParse(_heightCtrl.text.replaceAll(',', '.')) ?? 10.0;
    final service = _serviceCtrl.text.trim().isNotEmpty ? _serviceCtrl.text.trim() : 'Geral';
    final qrUrl = _qrLinkCtrl.text.trim();

    try {
      final repo = ref.read(templateRepositoryProvider);
      final actRepo = ref.read(activityRepositoryProvider);
      final user = ref.read(currentUserProvider);

      final qrList = [
        _placement ??
            QrPlacement(
              id: 'qr-${DateTime.now().millisecondsSinceEpoch}',
              label: 'QR $service',
              xPercent: 0.1,
              yPercent: 0.1,
              wPercent: 0.3,
              hPercent: 0.3,
              dynamicUrl: qrUrl.isNotEmpty ? qrUrl : null,
            )
      ];

      final template = PlateTemplate(
        id: 'tmpl-${DateTime.now().millisecondsSinceEpoch}',
        name: name,
        category: _category,
        productType: _productType,
        origin: _origin,
        canvaProjectUrl: _origin == 'canva' ? _canvaUrlCtrl.text.trim() : null,
        finalExportedFileUrl: _finalFileUrlCtrl.text.trim().isNotEmpty ? _finalFileUrlCtrl.text.trim() : null,
        relatedServiceType: service,
        page1ServiceType: service,
        page1DynamicUrl: qrUrl.isNotEmpty ? qrUrl : null,
        physicalWidthCm: w,
        physicalHeightCm: h,
        baseImageUrl: _finalFileUrlCtrl.text.trim(),
        qrPlacements: qrList,
        status: 'ativo',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await repo.createTemplate(template).timeout(
        const Duration(seconds: 6),
        onTimeout: () {
          debugPrint('[CreateTemplate] Timeout salvando template no Firestore; prosseguindo com cache');
          return template;
        },
      );

      try {
        await actRepo.logActivity(ActivityEntry(
          id: 'act-${DateTime.now().millisecondsSinceEpoch}',
          actorUid: user?.uid ?? 'system',
          actorName: user?.displayName ?? 'Operador Mobile',
          actionType: 'create_template',
          entityType: 'template',
          entityId: template.id,
          description: 'Modelo "$name" ($service) cadastrado.',
          timestamp: DateTime.now(),
        )).timeout(const Duration(seconds: 3), onTimeout: () {});
      } catch (_) {}

      if (!mounted) return;
      setState(() => _isSaving = false);
      _showSuccessDialog(template, service);
    } catch (e) {
      if (!mounted) return;
      setState(() => _isSaving = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erro ao salvar: $e')));
    }
  }

  void _showSuccessDialog(PlateTemplate template, String service) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF191A18),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: const BorderSide(color: Color(0xFF282A26)),
        ),
        title: Column(
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: const BoxDecoration(color: Color(0xFF132216), shape: BoxShape.circle),
              child: const Icon(Icons.check_circle, color: Color(0xFF22C55E), size: 36),
            ),
            const SizedBox(height: 12),
            const Text(
              'Modelo Criado!',
              style: TextStyle(fontFamily: 'Inter', fontSize: 20, fontWeight: FontWeight.w800, color: Colors.white),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'O modelo "${template.name}" foi salvo com sucesso.',
              style: const TextStyle(fontFamily: 'Inter', fontSize: 13, color: Color(0xFFCCCCCC)),
            ),
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: const Color(0xFF141513), borderRadius: BorderRadius.circular(12)),
              child: Column(
                children: [
                  _dialogRow('Origem', template.isCanva ? '🎨 Canva' : '📐 Interno'),
                  const SizedBox(height: 6),
                  _dialogRow('Serviço', service),
                  const SizedBox(height: 6),
                  _dialogRow('Tamanho', '${template.physicalWidthCm} x ${template.physicalHeightCm} cm'),
                  if (template.page1DynamicUrl != null && template.page1DynamicUrl!.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    _dialogRow('Link do QR', template.page1DynamicUrl!),
                  ],
                ],
              ),
            ),
          ],
        ),
        actions: [
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.orangeAction,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              onPressed: () {
                Navigator.of(ctx).pop();
                context.pop();
              },
              child: const Text('Concluir', style: TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.w700, color: Colors.white)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _dialogRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(fontFamily: 'Inter', fontSize: 12, color: Color(0xFF9E9E9E))),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            value,
            textAlign: TextAlign.end,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontFamily: 'Inter', fontSize: 12, fontWeight: FontWeight.w700, color: Colors.white),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = !kIsWeb &&
        (defaultTargetPlatform == TargetPlatform.windows ||
            defaultTargetPlatform == TargetPlatform.linux ||
            defaultTargetPlatform == TargetPlatform.macOS);

    if (kIsWeb || isDesktop) {
      return Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          leading: IconButton(icon: const Icon(Icons.arrow_back, color: Colors.white), onPressed: () => context.pop()),
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(LucideIcons.smartphone, size: 48, color: AppColors.orangeAction),
                const SizedBox(height: 16),
                const Text('Criação no App Mobile', style: TextStyle(fontFamily: 'Inter', fontSize: 20, fontWeight: FontWeight.w700, color: Colors.white)),
                const SizedBox(height: 8),
                const Text('A criação de modelos é exclusiva do celular para controle tátil de produção.', textAlign: TextAlign.center, style: TextStyle(color: Color(0xFF9E9E9E))),
                const SizedBox(height: 20),
                ElevatedButton(onPressed: () => context.pop(), child: const Text('Voltar')),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        leading: IconButton(icon: const Icon(Icons.arrow_back, color: Colors.white), onPressed: _prevStep),
        title: Text(
          'Novo Modelo (${_currentStep + 1}/3)',
          style: const TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.w700, color: Colors.white, fontSize: 18),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Indicador de progresso das 3 etapas
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              child: Row(
                children: List.generate(3, (idx) {
                  final active = idx <= _currentStep;
                  return Expanded(
                    child: Container(
                      height: 4,
                      margin: EdgeInsets.only(right: idx < 2 ? 8 : 0),
                      decoration: BoxDecoration(
                        color: active ? AppColors.orangeAction : const Color(0xFF282A26),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  );
                }),
              ),
            ),

            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: _buildCurrentStepContent(),
              ),
            ),

            // Barra inferior com botões de navegação
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              decoration: const BoxDecoration(
                color: Color(0xFF141513),
                border: Border(top: BorderSide(color: Color(0xFF242622))),
              ),
              child: Row(
                children: [
                  if (_currentStep > 0) ...[
                    OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.white70,
                        side: const BorderSide(color: Color(0xFF333530)),
                        minimumSize: const Size(80, 52),
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                      onPressed: _prevStep,
                      child: const Text('Voltar'),
                    ),
                    const SizedBox(width: 12),
                  ],
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.orangeAction,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                      onPressed: _isSaving ? null : _nextStep,
                      child: _isSaving
                          ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                          : Text(
                              _currentStep == 2 ? 'Salvar Modelo' : 'Avançar',
                              style: const TextStyle(fontFamily: 'Inter', fontSize: 16, fontWeight: FontWeight.w700),
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCurrentStepContent() {
    switch (_currentStep) {
      case 0:
        return _buildStep1Basic();
      case 1:
        return _buildStep2DesignAndLinks();
      case 2:
        return _buildStep3Review();
      default:
        return const SizedBox();
    }
  }

  // ETAPA 1: Identificação & Dimensões
  Widget _buildStep1Basic() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Etapa 1 de 3', style: TextStyle(fontFamily: 'Inter', fontSize: 12, color: AppColors.orangeAction, fontWeight: FontWeight.w700)),
        const SizedBox(height: 4),
        const Text('Identificação & Dimensões', style: TextStyle(fontFamily: 'Inter', fontSize: 22, fontWeight: FontWeight.w800, color: Colors.white)),
        const SizedBox(height: 18),

        // Seletor de Origem: Canva vs Interno
        const Text('Onde a arte foi criada?', style: TextStyle(fontFamily: 'Inter', fontSize: 13, color: Color(0xFF9E9E9E))),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(child: _buildOriginChoice(label: '🎨 Arte no Canva', value: 'canva')),
            const SizedBox(width: 10),
            Expanded(child: _buildOriginChoice(label: '📐 Modelo Interno', value: 'internal')),
          ],
        ),
        const SizedBox(height: 20),

        // Nome do modelo
        const Text('Nome do Modelo *', style: TextStyle(fontFamily: 'Inter', fontSize: 13, color: Color(0xFF9E9E9E))),
        const SizedBox(height: 6),
        TextField(
          controller: _nameCtrl,
          style: const TextStyle(color: Colors.white, fontFamily: 'Inter'),
          decoration: _inputDeco('Ex: Placa Instagram 10x10, Balcão Pix'),
        ),
        const SizedBox(height: 18),

        // Qual serviço esse cartão/placa vai oferecer (Livre)
        const Text('Serviço que este cartão oferece *', style: TextStyle(fontFamily: 'Inter', fontSize: 13, color: Color(0xFF9E9E9E))),
        const SizedBox(height: 6),
        TextField(
          controller: _serviceCtrl,
          style: const TextStyle(color: Colors.white, fontFamily: 'Inter', fontWeight: FontWeight.w600),
          decoration: _inputDeco('Digite qualquer serviço (Instagram, Avaliações, Pix, etc.)'),
        ),
        const SizedBox(height: 8),

        // Chips de sugestões rápidas
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: ['Instagram', 'Avaliações Google', 'Cardápio', 'WhatsApp', 'Wi-Fi', 'Chave Pix'].map((s) {
            return InkWell(
              onTap: () => setState(() => _serviceCtrl.text = s),
              borderRadius: BorderRadius.circular(14),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E201D),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFF2C2E2A)),
                ),
                child: Text(s, style: const TextStyle(fontFamily: 'Inter', fontSize: 11, color: Color(0xFFCCCCCC))),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 18),

        // Dimensões Físicas
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Largura (cm)', style: TextStyle(fontFamily: 'Inter', fontSize: 13, color: Color(0xFF9E9E9E))),
                  const SizedBox(height: 6),
                  TextField(
                    controller: _widthCtrl,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    style: const TextStyle(color: Colors.white, fontFamily: 'Inter'),
                    decoration: _inputDeco('10.0'),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Altura (cm)', style: TextStyle(fontFamily: 'Inter', fontSize: 13, color: Color(0xFF9E9E9E))),
                  const SizedBox(height: 6),
                  TextField(
                    controller: _heightCtrl,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    style: const TextStyle(color: Colors.white, fontFamily: 'Inter'),
                    decoration: _inputDeco('10.0'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  // ETAPA 2: Arte & Links (Canva com 2 links e Leitura Automática de QR)
  Widget _buildStep2DesignAndLinks() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Etapa 2 de 3', style: TextStyle(fontFamily: 'Inter', fontSize: 12, color: AppColors.orangeAction, fontWeight: FontWeight.w700)),
        const SizedBox(height: 4),
        const Text('Arte & Links', style: TextStyle(fontFamily: 'Inter', fontSize: 22, fontWeight: FontWeight.w800, color: Colors.white)),
        const SizedBox(height: 18),

        if (_origin == 'canva') ...[
          // Link 1: Projeto no Canva
          const Text('1. Link para ir ao Design no Canva', style: TextStyle(fontFamily: 'Inter', fontSize: 13, fontWeight: FontWeight.w700, color: Colors.white)),
          const SizedBox(height: 6),
          TextField(
            controller: _canvaUrlCtrl,
            style: const TextStyle(color: Colors.white, fontFamily: 'Inter'),
            decoration: _inputDeco('https://canva.com/design/...').copyWith(
              suffixIcon: IconButton(
                icon: const Icon(LucideIcons.externalLink, size: 18, color: Color(0xFFA5ADEB)),
                onPressed: () {
                  final u = _canvaUrlCtrl.text.trim();
                  if (u.isNotEmpty) UrlLauncherService.openUrl(u);
                },
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Foto da Arte com Leitor Automático de QR Code
          const Text('2. Foto da Arte da Placa', style: TextStyle(fontFamily: 'Inter', fontSize: 13, fontWeight: FontWeight.w700, color: Colors.white)),
          const SizedBox(height: 4),
          const Text(
            'Ao anexar a imagem da arte, o app lerá o QR Code automaticamente!',
            style: TextStyle(fontFamily: 'Inter', fontSize: 12, color: Color(0xFF9E9E9E)),
          ),
          const SizedBox(height: 8),

          InkWell(
            onTap: _showImageSourceDialog,
            borderRadius: BorderRadius.circular(14),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF1C1D1B),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: _detectedQrUrl != null ? const Color(0xFF22C55E) : const Color(0xFF282A26),
                  width: _detectedQrUrl != null ? 1.5 : 1.0,
                ),
              ),
              child: Column(
                children: [
                  if (_localImagePath != null && File(_localImagePath!).existsSync()) ...[
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.file(
                        File(_localImagePath!),
                        height: 130,
                        width: double.infinity,
                        fit: BoxFit.contain,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.refresh, size: 16, color: Colors.white70),
                        const SizedBox(width: 6),
                        const Text('Trocar Imagem', style: TextStyle(color: Colors.white70, fontSize: 12)),
                      ],
                    ),
                  ] else ...[
                    const Icon(LucideIcons.imagePlus, size: 36, color: Color(0xFFA5ADEB)),
                    const SizedBox(height: 8),
                    const Text('Toque para anexar a arte (Galeria ou Câmera)', style: TextStyle(color: Colors.white, fontFamily: 'Inter', fontSize: 13, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 4),
                    const Text('PNG, JPG ou WEBP', style: TextStyle(color: Color(0xFF737373), fontSize: 11)),
                  ],

                  if (_isScanningQr) ...[
                    const SizedBox(height: 12),
                    const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.orangeAction)),
                        SizedBox(width: 10),
                        Text('Lendo QR Code da imagem...', style: TextStyle(color: Colors.white70, fontSize: 12)),
                      ],
                    ),
                  ] else if (_scanMessage != null) ...[
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: _detectedQrUrl != null ? const Color(0xFF132216) : const Color(0xFF221F17),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            _detectedQrUrl != null ? Icons.check_circle : Icons.info_outline,
                            size: 16,
                            color: _detectedQrUrl != null ? const Color(0xFF22C55E) : Colors.amber,
                          ),
                          const SizedBox(width: 6),
                          Flexible(
                            child: Text(
                              _scanMessage!,
                              style: TextStyle(
                                fontSize: 12,
                                color: _detectedQrUrl != null ? const Color(0xFF22C55E) : Colors.amber,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Link 2: Link do QR Code da Arte
          const Text('3. Link do QR Code da Arte', style: TextStyle(fontFamily: 'Inter', fontSize: 13, fontWeight: FontWeight.w700, color: Colors.white)),
          const SizedBox(height: 4),
          const Text(
            'Detectado da foto ou preenchido manualmente:',
            style: TextStyle(fontFamily: 'Inter', fontSize: 12, color: Color(0xFF9E9E9E)),
          ),
          const SizedBox(height: 6),
          TextField(
            controller: _qrLinkCtrl,
            style: const TextStyle(color: Colors.white, fontFamily: 'Inter', fontWeight: FontWeight.w600),
            decoration: _inputDeco('https://...').copyWith(
              suffixIcon: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (_qrLinkCtrl.text.isNotEmpty)
                    IconButton(
                      icon: const Icon(LucideIcons.externalLink, size: 18, color: Color(0xFF22C55E)),
                      tooltip: 'Testar link',
                      onPressed: () {
                        final u = _qrLinkCtrl.text.trim();
                        if (u.isNotEmpty) UrlLauncherService.openUrl(u);
                      },
                    ),
                  IconButton(
                    icon: const Icon(Icons.paste, size: 18, color: Colors.white54),
                    tooltip: 'Colar',
                    onPressed: () async {
                      final data = await Clipboard.getData('text/plain');
                      if (data?.text != null) {
                        setState(() => _qrLinkCtrl.text = data!.text!.trim());
                      }
                    },
                  ),
                ],
              ),
            ),
          ),
        ] else ...[
          // Modelo interno: Imagem de fundo e posicionamento manual do QR
          const Text('Imagem de Fundo da Placa', style: TextStyle(fontFamily: 'Inter', fontSize: 13, color: Color(0xFF9E9E9E))),
          const SizedBox(height: 6),
          InkWell(
            onTap: _showImageSourceDialog,
            child: Container(
              height: 120,
              width: double.infinity,
              decoration: BoxDecoration(color: const Color(0xFF1C1D1B), borderRadius: BorderRadius.circular(14), border: Border.all(color: const Color(0xFF282A26))),
              child: _localImagePath != null
                  ? Image.file(File(_localImagePath!), fit: BoxFit.contain)
                  : const Center(child: Text('Toque para escolher imagem', style: TextStyle(color: Colors.white70))),
            ),
          ),
          const SizedBox(height: 12),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF222420), foregroundColor: Colors.white),
            onPressed: _openQrEditor,
            icon: const Icon(Icons.qr_code_2),
            label: Text(_placement != null ? 'QR Configurado (Alterar)' : 'Definir Área do QR Code'),
          ),
          const SizedBox(height: 18),
          const Text('Link do QR Code', style: TextStyle(fontFamily: 'Inter', fontSize: 13, color: Color(0xFF9E9E9E))),
          const SizedBox(height: 6),
          TextField(
            controller: _qrLinkCtrl,
            style: const TextStyle(color: Colors.white, fontFamily: 'Inter'),
            decoration: _inputDeco('https://...'),
          ),
        ],
      ],
    );
  }

  // ETAPA 3: Revisão & Finalização
  Widget _buildStep3Review() {
    final service = _serviceCtrl.text.trim().isNotEmpty ? _serviceCtrl.text.trim() : 'Geral';
    final hasImage = _localImagePath != null && File(_localImagePath!).existsSync();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Etapa 3 de 3', style: TextStyle(fontFamily: 'Inter', fontSize: 12, color: AppColors.orangeAction, fontWeight: FontWeight.w700)),
        const SizedBox(height: 4),
        const Text('Revisão & Conclusão', style: TextStyle(fontFamily: 'Inter', fontSize: 22, fontWeight: FontWeight.w800, color: Colors.white)),
        const SizedBox(height: 18),

        // Card com visualização
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFF1C1D1B),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFF282A26)),
          ),
          child: Column(
            children: [
              if (hasImage) ...[
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.file(
                    File(_localImagePath!),
                    height: 140,
                    width: double.infinity,
                    fit: BoxFit.contain,
                  ),
                ),
                const SizedBox(height: 14),
              ],
              Text(
                _nameCtrl.text,
                style: const TextStyle(fontFamily: 'Inter', fontSize: 18, fontWeight: FontWeight.w800, color: Colors.white),
              ),
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFF132216),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFF22C55E).withValues(alpha: 0.3)),
                ),
                child: Text(
                  'Serviço: $service',
                  style: const TextStyle(fontFamily: 'Inter', fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF22C55E)),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Card com os dois links
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: const Color(0xFF141513),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFF242622)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _dialogRow('Origem', _origin == 'canva' ? '🎨 Canva' : '📐 Modelo Interno'),
              const SizedBox(height: 8),
              _dialogRow('Dimensões', '${_widthCtrl.text} x ${_heightCtrl.text} cm'),
              const Divider(color: Color(0xFF282A26), height: 18),

              // Link 1: Canva
              if (_canvaUrlCtrl.text.isNotEmpty) ...[
                Row(
                  children: [
                    const Icon(LucideIcons.palette, size: 16, color: Color(0xFFA5ADEB)),
                    const SizedBox(width: 8),
                    const Expanded(
                      child: Text('Projeto Canva:', style: TextStyle(fontFamily: 'Inter', fontSize: 12, color: Color(0xFF9E9E9E))),
                    ),
                    TextButton.icon(
                      style: TextButton.styleFrom(padding: EdgeInsets.zero, visualDensity: VisualDensity.compact),
                      onPressed: () => UrlLauncherService.openUrl(_canvaUrlCtrl.text.trim()),
                      icon: const Icon(LucideIcons.externalLink, size: 14, color: Color(0xFFA5ADEB)),
                      label: const Text('Abrir', style: TextStyle(fontSize: 12, color: Color(0xFFA5ADEB))),
                    ),
                  ],
                ),
                Text(
                  _canvaUrlCtrl.text.trim(),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontFamily: 'Inter', fontSize: 11, color: Colors.white70),
                ),
                const SizedBox(height: 10),
              ],

              // Link 2: QR Code da Arte
              Row(
                children: [
                  const Icon(Icons.qr_code, size: 16, color: Color(0xFF22C55E)),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text('Link do QR Code da Arte:', style: TextStyle(fontFamily: 'Inter', fontSize: 12, color: Color(0xFF9E9E9E))),
                  ),
                  if (_qrLinkCtrl.text.isNotEmpty)
                    TextButton.icon(
                      style: TextButton.styleFrom(padding: EdgeInsets.zero, visualDensity: VisualDensity.compact),
                      onPressed: () => UrlLauncherService.openUrl(_qrLinkCtrl.text.trim()),
                      icon: const Icon(LucideIcons.externalLink, size: 14, color: Color(0xFF22C55E)),
                      label: const Text('Testar', style: TextStyle(fontSize: 12, color: Color(0xFF22C55E))),
                    ),
                ],
              ),
              Text(
                _qrLinkCtrl.text.isNotEmpty ? _qrLinkCtrl.text.trim() : '(Nenhum link definido)',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 11,
                  color: _qrLinkCtrl.text.isNotEmpty ? const Color(0xFF22C55E) : Colors.grey,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildOriginChoice({required String label, required String value}) {
    final active = _origin == value;
    return InkWell(
      onTap: () => setState(() => _origin = value),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: active ? AppColors.orangeAction : const Color(0xFF1C1D1B),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: active ? AppColors.orangeAction : const Color(0xFF282A26)),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: active ? Colors.white : const Color(0xFF9E9E9E),
          ),
        ),
      ),
    );
  }

  InputDecoration _inputDeco(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: Color(0xFF6B7280), fontSize: 13),
      filled: true,
      fillColor: const Color(0xFF1C1D1B),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF282A26))),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF282A26))),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.orangeAction)),
    );
  }
}
