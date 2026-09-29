import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../core/models/activity_entry.dart';
import '../../../core/models/company.dart';
import '../../../core/models/device_item.dart';
import '../../../core/models/dynamic_qr_code.dart';
import '../../../core/models/generated_design.dart';
import '../../../core/models/order_item.dart';
import '../../../core/models/plate_template.dart';
import '../../../core/models/service_item.dart';
import '../../../core/providers/app_providers.dart';
import '../../../core/theme/app_colors.dart';
import 'widgets/nfc_write_modal.dart';

class GenerateDesignScreen extends ConsumerStatefulWidget {
  final String? initialCompanyId;
  final String? initialTemplateId;
  final String? designId;

  const GenerateDesignScreen({
    super.key,
    this.initialCompanyId,
    this.initialTemplateId,
    this.designId,
  });

  @override
  ConsumerState<GenerateDesignScreen> createState() => _GenerateDesignScreenState();
}

class _GenerateDesignScreenState extends ConsumerState<GenerateDesignScreen> {
  int _currentStep = 1; // 1: Empresa & Dados, 2: Estoque & Produção, 3: Resumo

  String? _selectedCompanyId;
  String? _selectedTemplateId;
  String? _selectedServiceId;
  String? _selectedDeviceId;
  bool _createProductionOrder = false;

  final TextEditingController _destinationCtrl = TextEditingController();
  bool _isSaving = false;
  bool _initializedFromTemplate = false;
  bool _initializedEditData = false;

  bool get _isEditMode => widget.designId != null;

  @override
  void initState() {
    super.initState();
    _selectedCompanyId = widget.initialCompanyId;
    _selectedTemplateId = widget.initialTemplateId;
  }

  @override
  void dispose() {
    _destinationCtrl.dispose();
    super.dispose();
  }

  void _syncEditData(List<GeneratedDesign> designs, List<DynamicQrCode> qrCodes, List<PlateTemplate> templates) {
    if (_initializedEditData || widget.designId == null) return;
    final dsg = designs.where((d) => d.id == widget.designId).firstOrNull;
    if (dsg != null) {
      _initializedEditData = true;
      _selectedCompanyId = dsg.companyId;
      _selectedTemplateId = dsg.templateId;
      _selectedServiceId = dsg.serviceId;
      _selectedDeviceId = dsg.deviceId;
      final qr = qrCodes.where((q) => q.id == dsg.qrCodeId).firstOrNull;
      if (qr != null && qr.currentDestination.isNotEmpty) {
        _destinationCtrl.text = qr.currentDestination;
      } else {
        final tmpl = templates.where((t) => t.id == dsg.templateId).firstOrNull;
        if (tmpl?.page1DynamicUrl != null && tmpl!.page1DynamicUrl!.isNotEmpty) {
          _destinationCtrl.text = tmpl.page1DynamicUrl!;
        }
      }
    }
  }

  void _syncTemplateData(PlateTemplate template) {
    if (_initializedFromTemplate || _isEditMode) return;
    _initializedFromTemplate = true;
    final url = template.page1DynamicUrl;
    if (_destinationCtrl.text.isEmpty && url != null && url.isNotEmpty) {
      _destinationCtrl.text = url;
    }
  }

  String _generateShortCode() {
    const chars = 'ABCDEFGHJKMNPQRSTUVWXYZ23456789';
    final rng = Random.secure();
    return List.generate(6, (_) => chars[rng.nextInt(chars.length)]).join();
  }

  void _goToStep(int step) {
    if (step > _currentStep) {
      if (_currentStep == 1) {
        if (_selectedCompanyId == null) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Selecione uma empresa cliente para prosseguir.'), backgroundColor: AppColors.redError),
          );
          return;
        }
        if (_selectedTemplateId == null) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Selecione o modelo de placa.'), backgroundColor: AppColors.redError),
          );
          return;
        }
        final dest = _destinationCtrl.text.trim();
        if (dest.isEmpty || !dest.startsWith('http')) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Informe uma URL válida iniciada por http:// ou https://'), backgroundColor: AppColors.redError),
          );
          return;
        }
      }
    }
    setState(() => _currentStep = step);
  }

  Future<void> _handleSave(PlateTemplate? template, Company? company) async {
    if (_selectedCompanyId == null || _selectedTemplateId == null) return;
    final dest = _destinationCtrl.text.trim();
    if (dest.isEmpty || !dest.startsWith('http')) return;

    setState(() => _isSaving = true);
    try {
      final qrRepo = ref.read(qrCodeRepositoryProvider);
      final designRepo = ref.read(generatedDesignRepositoryProvider);
      final serviceRepo = ref.read(serviceRepositoryProvider);
      final deviceRepo = ref.read(deviceRepositoryProvider);
      final orderRepo = ref.read(orderRepositoryProvider);
      final actRepo = ref.read(activityRepositoryProvider);
      final curUser = ref.read(currentUserProvider);

      final now = DateTime.now();

      // MODO EDIÇÃO: Atualizar placa existente sem duplicar
      if (_isEditMode) {
        final allDesigns = await designRepo.getDesigns();
        final existingDesign = allDesigns.where((d) => d.id == widget.designId).firstOrNull;
        if (existingDesign != null) {
          // 1. Atualizar Serviço vinculado
          if (_selectedServiceId != null) {
            final allServices = await serviceRepo.getAllServices();
            final existingSrv = allServices.where((s) => s.id == _selectedServiceId).firstOrNull;
            if (existingSrv != null) {
              await serviceRepo.updateService(existingSrv.copyWith(
                companyId: _selectedCompanyId!,
                destinationUrl: dest,
                updatedAt: now,
              ));
            }
          }

          // 2. Atualizar QR Code vinculado se houver
          if (existingDesign.qrCodeId.isNotEmpty) {
            try {
              await qrRepo.updateDestination(
                existingDesign.qrCodeId,
                dest,
                changedByUid: curUser?.uid ?? 'usr-operador',
                changedByName: curUser?.displayName ?? 'Operador',
              );
            } catch (_) {}
          }

          // 3. Atualizar Dispositivo Físico se alterado
          if (existingDesign.deviceId != _selectedDeviceId) {
            final allDevs = await deviceRepo.getDevices();
            if (existingDesign.deviceId != null) {
              final oldDev = allDevs.where((d) => d.id == existingDesign.deviceId).firstOrNull;
              if (oldDev != null) {
                await deviceRepo.updateDevice(oldDev.copyWith(
                  status: DeviceStatus.disponivel,
                  clearAssignedCompany: true,
                  clearPrimaryService: true,
                  updatedAt: now,
                ));
              }
            }
            if (_selectedDeviceId != null) {
              final newDev = allDevs.where((d) => d.id == _selectedDeviceId).firstOrNull;
              if (newDev != null) {
                await deviceRepo.updateDevice(newDev.copyWith(
                  status: DeviceStatus.instalado,
                  assignedCompanyId: _selectedCompanyId,
                  primaryServiceId: _selectedServiceId,
                  updatedAt: now,
                ));
              }
            }
          }

          // 4. Atualizar Design
          final updatedDesign = existingDesign.copyWith(
            companyId: _selectedCompanyId!,
            serviceId: _selectedServiceId,
            deviceId: _selectedDeviceId,
            clearDeviceId: _selectedDeviceId == null,
            updatedAt: now,
          );
          await designRepo.updateDesign(updatedDesign);

          // 5. Auditoria
          await actRepo.logActivity(ActivityEntry(
            id: 'act_${now.millisecondsSinceEpoch}',
            actorUid: curUser?.uid ?? 'usr-operador',
            actorName: curUser?.displayName ?? 'Operador',
            actionType: 'update_plate_design',
            description: 'Placa atualizada para ${company?.tradeName ?? 'Empresa'}.',
            entityType: 'design',
            entityId: updatedDesign.id,
            timestamp: now,
          ));

          if (!mounted) return;
          setState(() => _isSaving = false);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Placa atualizada com sucesso!'), backgroundColor: AppColors.greenSuccess),
          );
          context.pushReplacement('/designs/${updatedDesign.id}/preview');
          return;
        }
      }

      final shortCode = _generateShortCode();

      // 1. Garantir ou vincular serviço da empresa
      String? finalServiceId = _selectedServiceId;
      if (finalServiceId == null && template != null) {
        final newService = ServiceItem(
          id: 'srv-${now.millisecondsSinceEpoch}',
          companyId: _selectedCompanyId!,
          serviceType: template.relatedServiceType ?? 'personalizado',
          publicTitle: template.name,
          destinationUrl: dest,
          createdAt: now,
          updatedAt: now,
        );
        await serviceRepo.createService(newService);
        finalServiceId = newService.id;
      }

      // 2. Criar QR Dinâmico
      final newQr = DynamicQrCode(
        id: 'qr-${now.millisecondsSinceEpoch}',
        shortCode: shortCode,
        companyId: _selectedCompanyId!,
        serviceId: finalServiceId,
        templateId: _selectedTemplateId,
        deviceId: _selectedDeviceId,
        currentDestination: dest,
        status: 'ativo',
        createdAt: now,
        updatedAt: now,
      );
      await qrRepo.createQrCode(newQr);

      // 3. Criar Design Gerado
      final newDesign = GeneratedDesign(
        id: 'dsg-${now.millisecondsSinceEpoch}',
        templateId: _selectedTemplateId!,
        companyId: _selectedCompanyId!,
        serviceId: finalServiceId,
        qrCodeId: newQr.id,
        deviceId: _selectedDeviceId,
        status: 'pronto',
        createdAt: now,
        updatedAt: now,
      );
      await designRepo.createDesign(newDesign);

      // 4. Vincular dispositivo físico se selecionado
      if (_selectedDeviceId != null) {
        final allDevices = await deviceRepo.getDevices();
        final dev = allDevices.where((d) => d.id == _selectedDeviceId).firstOrNull;
        if (dev != null) {
          await deviceRepo.updateDevice(dev.copyWith(
            status: DeviceStatus.instalado,
            assignedCompanyId: _selectedCompanyId,
            primaryServiceId: finalServiceId,
            updatedAt: now,
          ));
        }
      }

      // 5. Criar Pedido de Produção se solicitado
      if (_createProductionOrder && company != null) {
        final orderNum = '#${(now.millisecondsSinceEpoch % 900 + 100)}';
        await orderRepo.createOrder(OrderItem(
          id: 'ord-${now.millisecondsSinceEpoch}',
          companyId: _selectedCompanyId!,
          orderNumber: orderNum,
          status: OrderStatus.producao,
          items: [
            OrderItemDetail(
              title: 'Placa Acrílica ${template?.name ?? 'Personalizada'}',
              quantity: 1,
              unitPriceInCents: 12000,
              serviceId: finalServiceId,
            ),
          ],
          totalInCents: 12000,
          paymentStatus: PaymentStatus.pendente,
          notes: 'Gerado automaticamente via vinculação de template.',
          createdAt: now,
          updatedAt: now,
        ));
      }

      // 6. Registrar Auditoria
      await actRepo.logActivity(ActivityEntry(
        id: 'act-${now.millisecondsSinceEpoch}',
        actorUid: curUser?.uid ?? 'usr-operador',
        actorName: curUser?.displayName ?? 'Operador',
        actionType: 'generate_plate_design',
        description: 'Placa vinculada para ${company?.tradeName ?? 'Empresa'} com QR [$shortCode].',
        entityType: 'design',
        entityId: newDesign.id,
        timestamp: now,
      ));

      if (!mounted) return;
      setState(() => _isSaving = false);
      _showSuccessConfirmation(newDesign, dest, company?.tradeName);
    } catch (e) {
      if (!mounted) return;
      setState(() => _isSaving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao salvar placa: $e'), backgroundColor: AppColors.redError),
      );
    }
  }

  void _showSuccessConfirmation(GeneratedDesign design, String destUrl, String? companyName) {
    showModalBottomSheet(
      context: context,
      isDismissible: false,
      enableDrag: false,
      backgroundColor: const Color(0xFF161715),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (ctx) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 68,
                height: 68,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFF22C55E).withValues(alpha: 0.15),
                  border: Border.all(color: const Color(0xFF22C55E), width: 2),
                ),
                child: const Center(
                  child: Icon(Icons.check, color: Color(0xFF22C55E), size: 36),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Placa Vinculada com Sucesso!',
                style: TextStyle(fontFamily: 'Inter', fontSize: 18, fontWeight: FontWeight.w800, color: Colors.white),
              ),
              const SizedBox(height: 6),
              Text(
                companyName != null
                    ? 'A placa agora faz parte da operação de $companyName.'
                    : 'A placa foi configurada com sucesso.',
                textAlign: TextAlign.center,
                style: const TextStyle(fontFamily: 'Inter', fontSize: 13, color: Color(0xFF9E9E9E)),
              ),
              const SizedBox(height: 24),

              // Atalho 1: Gravar Chip NFC Agora
              Material(
                color: AppColors.orangeAction,
                borderRadius: BorderRadius.circular(24),
                child: InkWell(
                  onTap: () {
                    Navigator.of(ctx).pop();
                    NfcWriteModal.show(context, url: destUrl, companyName: companyName);
                  },
                  borderRadius: BorderRadius.circular(24),
                  child: Container(
                    height: 50,
                    width: double.infinity,
                    alignment: Alignment.center,
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(LucideIcons.nfc, color: Colors.white, size: 20),
                        SizedBox(width: 8),
                        Text(
                          'Gravar Chip NFC no Celular',
                          style: TextStyle(fontFamily: 'Inter', fontSize: 15, fontWeight: FontWeight.w700, color: Colors.white),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 10),

              // Atalho 2: Ver Arte / Exportar para Gráfica
              SizedBox(
                width: double.infinity,
                height: 50,
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white,
                    side: const BorderSide(color: Color(0xFF333532)),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                  ),
                  onPressed: () {
                    Navigator.of(ctx).pop();
                    context.pushReplacement('/designs/${design.id}/preview');
                  },
                  icon: const Icon(LucideIcons.printer, size: 18),
                  label: const Text('Ver Arte / Exportar para Gráfica', style: TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.w600)),
                ),
              ),
              const SizedBox(height: 10),

              // Atalho 3: Concluir e Voltar
              TextButton(
                onPressed: () {
                  Navigator.of(ctx).pop();
                  if (_selectedCompanyId != null) {
                    context.go('/companies/$_selectedCompanyId');
                  } else {
                    context.go('/templates');
                  }
                },
                child: const Text('Concluir e Voltar', style: TextStyle(fontFamily: 'Inter', color: Colors.white70, fontSize: 14)),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final companiesAsync = ref.watch(companiesStreamProvider);
    final servicesAsync = ref.watch(servicesStreamProvider);
    final templatesAsync = ref.watch(templatesStreamProvider);
    final devicesAsync = ref.watch(devicesStreamProvider);
    final designsAsync = ref.watch(generatedDesignsStreamProvider);
    final qrCodesAsync = ref.watch(qrCodesStreamProvider);

    final companies = companiesAsync.value ?? [];
    final allServices = servicesAsync.value ?? [];
    final templates = templatesAsync.value ?? [];
    final allDevices = devicesAsync.value ?? [];
    final allDesigns = designsAsync.value ?? [];
    final allQrCodes = qrCodesAsync.value ?? [];

    if (_isEditMode && !_initializedEditData) {
      _syncEditData(allDesigns, allQrCodes, templates);
    }

    final template = templates.where((t) => t.id == _selectedTemplateId).firstOrNull;
    final company = companies.where((c) => c.id == _selectedCompanyId).firstOrNull;
    final companyServices = allServices.where((s) => s.companyId == _selectedCompanyId).toList();
    final availableDevices = allDevices.where((d) => d.status == DeviceStatus.disponivel || d.id == _selectedDeviceId).toList();

    if (template != null) {
      _syncTemplateData(template);
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            if (_currentStep > 1) {
              _goToStep(_currentStep - 1);
            } else {
              context.pop();
            }
          },
        ),
        title: Text(
          _isEditMode ? 'Editar Placa da Empresa' : 'Vincular Placa para Empresa',
          style: const TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.w700, color: Colors.white, fontSize: 18),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Indicador de Etapas no Topo
            _buildStepIndicator(),

            // Conteúdo da Etapa
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                child: _buildCurrentStep(template, company, companyServices, availableDevices, templates),
              ),
            ),

            // Barra de Navegação Inferior
            _buildBottomNavButtons(template, company),
          ],
        ),
      ),
    );
  }

  Widget _buildStepIndicator() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: const BoxDecoration(
        color: Color(0xFF141513),
        border: Border(bottom: BorderSide(color: Color(0xFF222420))),
      ),
      child: Row(
        children: [
          _buildStepCircle(1, 'Empresa'),
          Expanded(child: Container(height: 2, color: _currentStep >= 2 ? AppColors.orangeAction : const Color(0xFF282A26))),
          _buildStepCircle(2, 'Estoque'),
          Expanded(child: Container(height: 2, color: _currentStep >= 3 ? AppColors.orangeAction : const Color(0xFF282A26))),
          _buildStepCircle(3, 'Revisão'),
        ],
      ),
    );
  }

  Widget _buildStepCircle(int step, String label) {
    final isActive = _currentStep == step;
    final isDone = _currentStep > step;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isDone
                ? const Color(0xFF22C55E)
                : (isActive ? AppColors.orangeAction : const Color(0xFF1C1D1B)),
            border: Border.all(
              color: isActive ? AppColors.orangeAction : (isDone ? const Color(0xFF22C55E) : const Color(0xFF333532)),
              width: 1.5,
            ),
          ),
          child: Center(
            child: isDone
                ? const Icon(Icons.check, size: 16, color: Colors.white)
                : Text(
                    '$step',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontWeight: FontWeight.w700,
                      color: isActive ? Colors.white : Colors.white54,
                      fontSize: 13,
                    ),
                  ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: 11,
            fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
            color: isActive ? Colors.white : const Color(0xFF8E918F),
          ),
        ),
      ],
    );
  }

  Widget _buildCurrentStep(
    PlateTemplate? template,
    Company? company,
    List<ServiceItem> companyServices,
    List<DeviceItem> availableDevices,
    List<PlateTemplate> allTemplates,
  ) {
    switch (_currentStep) {
      case 1:
        return _buildStep1CompanyAndTemplate(template, companyServices, allTemplates);
      case 2:
        return _buildStep2InventoryAndProduction(availableDevices, template);
      case 3:
      default:
        return _buildStep3Review(template, company, availableDevices);
    }
  }

  // --- ETAPA 1: Empresa Cliente & Dados do Modelo ---
  Widget _buildStep1CompanyAndTemplate(
    PlateTemplate? template,
    List<ServiceItem> companyServices,
    List<PlateTemplate> allTemplates,
  ) {
    final companies = ref.watch(companiesStreamProvider).value ?? [];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Card de Resumo do Modelo Selecionado (Herança direta de dados)
        if (template != null)
          Container(
            padding: const EdgeInsets.all(14),
            margin: const EdgeInsets.only(bottom: 18),
            decoration: BoxDecoration(
              color: const Color(0xFF191B18),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFF2E312B)),
            ),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: const Color(0xFF262824),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Center(
                    child: Icon(LucideIcons.layoutTemplate, color: AppColors.orangeAction, size: 24),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              template.name,
                              style: const TextStyle(fontFamily: 'Inter', fontSize: 14, fontWeight: FontWeight.w700, color: Colors.white),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (template.isCanva)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: const Color(0xFF00C4CC).withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(color: const Color(0xFF00C4CC).withValues(alpha: 0.4)),
                              ),
                              child: const Text('CANVA', style: TextStyle(fontFamily: 'Inter', fontSize: 9, fontWeight: FontWeight.w700, color: Color(0xFF00C4CC))),
                            ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${template.physicalWidthCm}x${template.physicalHeightCm} cm • ${template.relatedServiceType ?? 'Geral'}',
                        style: const TextStyle(fontFamily: 'Inter', fontSize: 12, color: Color(0xFF9E9E9E)),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          )
        else
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Modelo de Placa *', style: TextStyle(fontFamily: 'Inter', fontSize: 13, color: Color(0xFF9E9E9E))),
              const SizedBox(height: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14),
                decoration: BoxDecoration(
                  color: const Color(0xFF1C1D1B),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFF282A26)),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String?>(
                    value: _selectedTemplateId,
                    dropdownColor: const Color(0xFF222421),
                    isExpanded: true,
                    hint: const Text('Selecione o modelo de placa', style: TextStyle(color: Color(0xFF6B7280), fontFamily: 'Inter')),
                    style: const TextStyle(color: Colors.white, fontFamily: 'Inter'),
                    items: allTemplates.map((t) => DropdownMenuItem(value: t.id, child: Text('${t.name} (${t.physicalWidthCm}x${t.physicalHeightCm} cm)'))).toList(),
                    onChanged: (v) => setState(() => _selectedTemplateId = v),
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),

        // 1. Selecionar Empresa Cliente
        const Text('1. Empresa Cliente *', style: TextStyle(fontFamily: 'Inter', fontSize: 13, fontWeight: FontWeight.w600, color: Colors.white)),
        const SizedBox(height: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14),
          decoration: BoxDecoration(
            color: const Color(0xFF1C1D1B),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFF282A26)),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String?>(
              value: _selectedCompanyId,
              dropdownColor: const Color(0xFF222421),
              isExpanded: true,
              hint: const Text('Selecione a empresa cliente', style: TextStyle(color: Color(0xFF6B7280), fontFamily: 'Inter')),
              style: const TextStyle(color: Colors.white, fontFamily: 'Inter'),
              items: companies.map((c) => DropdownMenuItem(value: c.id, child: Text(c.tradeName))).toList(),
              onChanged: (v) {
                setState(() {
                  _selectedCompanyId = v;
                  _selectedServiceId = null;
                });
              },
            ),
          ),
        ),

        const SizedBox(height: 18),

        // 2. Serviço da Empresa (Opcional)
        const Text('2. Vincular a Serviço Existente (Opcional)', style: TextStyle(fontFamily: 'Inter', fontSize: 13, fontWeight: FontWeight.w600, color: Colors.white)),
        const SizedBox(height: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14),
          decoration: BoxDecoration(
            color: const Color(0xFF1C1D1B),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFF282A26)),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String?>(
              value: _selectedServiceId,
              dropdownColor: const Color(0xFF222421),
              isExpanded: true,
              hint: Text(
                _selectedCompanyId == null ? 'Selecione a empresa primeiro' : 'Criar novo serviço a partir deste modelo',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: Color(0xFF6B7280), fontFamily: 'Inter'),
              ),
              style: const TextStyle(color: Colors.white, fontFamily: 'Inter'),
              items: [
                const DropdownMenuItem(value: null, child: Text('Criar novo serviço a partir deste modelo', maxLines: 1, overflow: TextOverflow.ellipsis)),
                ...companyServices.map((s) => DropdownMenuItem(value: s.id, child: Text(s.publicTitle, maxLines: 1, overflow: TextOverflow.ellipsis))),
              ],
              onChanged: (v) {
                setState(() {
                  _selectedServiceId = v;
                  if (v != null) {
                    final srv = companyServices.where((s) => s.id == v).firstOrNull;
                    if (srv != null && srv.destinationUrl.isNotEmpty) {
                      _destinationCtrl.text = srv.destinationUrl;
                    }
                  }
                });
              },
            ),
          ),
        ),

        const SizedBox(height: 18),

        // 3. Destino do QR Code / NFC
        Row(
          children: [
            const Expanded(
              child: Text(
                '3. Destino do QR / NFC *',
                style: TextStyle(fontFamily: 'Inter', fontSize: 13, fontWeight: FontWeight.w600, color: Colors.white),
              ),
            ),
            if (template != null && (template.page1DynamicUrl?.isNotEmpty ?? false))
              const Text(
                'Herdado da arte',
                style: TextStyle(fontFamily: 'Inter', fontSize: 11, color: AppColors.orangeAction, fontWeight: FontWeight.w600),
              ),
          ],
        ),
        const SizedBox(height: 6),
        TextField(
          controller: _destinationCtrl,
          style: const TextStyle(color: Colors.white, fontFamily: 'Inter'),
          decoration: InputDecoration(
            hintText: 'https://instagram.com/..., https://g.page/...',
            hintStyle: const TextStyle(color: Color(0xFF6B7280)),
            filled: true,
            fillColor: const Color(0xFF1C1D1B),
            prefixIcon: const Icon(LucideIcons.link, size: 16, color: Color(0xFF9E9E9E)),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF282A26))),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF282A26))),
          ),
        ),
        const SizedBox(height: 4),
        const Text(
          'Esta é a URL que o cliente acessa ao ler o QR Code ou aproximar o celular da placa NFC.',
          style: TextStyle(fontFamily: 'Inter', fontSize: 11, color: Color(0xFF8E918F), height: 1.3),
        ),
      ],
    );
  }

  // --- ETAPA 2: Estoque & Produção ---
  Widget _buildStep2InventoryAndProduction(
    List<DeviceItem> availableDevices,
    PlateTemplate? template,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Placa Física & Estoque',
          style: TextStyle(fontFamily: 'Inter', fontSize: 15, fontWeight: FontWeight.w700, color: Colors.white),
        ),
        const SizedBox(height: 6),
        const Text(
          'Você pode vincular uma peça física do estoque agora para gravação NFC imediata, ou encomendar na produção.',
          style: TextStyle(fontFamily: 'Inter', fontSize: 12, color: Color(0xFF9E9E9E)),
        ),
        const SizedBox(height: 20),

        // Opção 1: Vincular peça disponível em estoque
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFF191B18),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: _selectedDeviceId != null ? AppColors.orangeAction : const Color(0xFF282A26)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(LucideIcons.boxes, size: 20, color: AppColors.orangeAction),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      'Vincular Placa em Estoque',
                      style: TextStyle(fontFamily: 'Inter', fontSize: 14, fontWeight: FontWeight.w700, color: Colors.white),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: availableDevices.isNotEmpty ? const Color(0xFF22C55E).withValues(alpha: 0.15) : const Color(0xFFEF4444).withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '${availableDevices.length} disponíveis',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: availableDevices.isNotEmpty ? const Color(0xFF22C55E) : const Color(0xFFEF4444),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              if (availableDevices.isEmpty)
                const Text(
                  'Não há placas físicas disponíveis no estoque. Você pode gerar a arte e vincular o chip posteriormente.',
                  style: TextStyle(fontFamily: 'Inter', fontSize: 12, color: Colors.white60),
                )
              else
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  decoration: BoxDecoration(
                    color: const Color(0xFF121311),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFF2E312B)),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String?>(
                      value: _selectedDeviceId,
                      dropdownColor: const Color(0xFF222421),
                      isExpanded: true,
                      hint: const Text('Selecione a placa física', style: TextStyle(color: Color(0xFF6B7280), fontFamily: 'Inter')),
                      style: const TextStyle(color: Colors.white, fontFamily: 'Inter'),
                      items: [
                        const DropdownMenuItem(value: null, child: Text('Nenhuma (Vincular depois)')),
                        ...availableDevices.map((d) => DropdownMenuItem(value: d.id, child: Text('${d.batchId} (${d.deviceType})'))),
                      ],
                      onChanged: (v) => setState(() => _selectedDeviceId = v),
                    ),
                  ),
                ),
            ],
          ),
        ),

        const SizedBox(height: 16),

        // Opção 2: Fabricar sob encomenda / Criar Pedido
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFF191B18),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFF282A26)),
          ),
          child: Row(
            children: [
              Checkbox(
                value: _createProductionOrder,
                activeColor: AppColors.orangeAction,
                onChanged: (v) => setState(() => _createProductionOrder = v ?? false),
              ),
              const SizedBox(width: 8),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Criar Pedido de Produção',
                      style: TextStyle(fontFamily: 'Inter', fontSize: 14, fontWeight: FontWeight.w700, color: Colors.white),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'Registra uma ordem de serviço pendente para corte do acrílico e gravação.',
                      style: TextStyle(fontFamily: 'Inter', fontSize: 11, color: Color(0xFF9E9E9E)),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // --- ETAPA 3: Revisão & Conclusão ---
  Widget _buildStep3Review(
    PlateTemplate? template,
    Company? company,
    List<DeviceItem> availableDevices,
  ) {
    final dev = availableDevices.where((d) => d.id == _selectedDeviceId).firstOrNull;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Revisão da Placa',
          style: TextStyle(fontFamily: 'Inter', fontSize: 16, fontWeight: FontWeight.w800, color: Colors.white),
        ),
        const SizedBox(height: 4),
        const Text(
          'Confira os dados antes de finalizar a vinculação com a empresa cliente.',
          style: TextStyle(fontFamily: 'Inter', fontSize: 12, color: Color(0xFF9E9E9E)),
        ),
        const SizedBox(height: 18),

        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFF191B18),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: const Color(0xFF2E312B)),
          ),
          child: Column(
            children: [
              _buildReviewRow('Empresa Cliente', company?.tradeName ?? '—', LucideIcons.building2),
              const Divider(color: Color(0xFF282A26), height: 18),
              _buildReviewRow('Modelo da Placa', template?.name ?? '—', LucideIcons.layoutTemplate),
              const Divider(color: Color(0xFF282A26), height: 18),
              _buildReviewRow('Destino QR/NFC', _destinationCtrl.text.trim(), LucideIcons.link),
              const Divider(color: Color(0xFF282A26), height: 18),
              _buildReviewRow('Placa Física', dev?.batchId ?? (_createProductionOrder ? 'Pedido de Produção' : 'Vincular posteriormente'), LucideIcons.boxes),
            ],
          ),
        ),

        const SizedBox(height: 20),

        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: const Color(0xFF132216),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFF22C55E).withValues(alpha: 0.3)),
          ),
          child: const Row(
            children: [
              Icon(Icons.info_outline, color: Color(0xFF22C55E), size: 18),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Após salvar, você poderá gravar o chip NFC imediatamente aproximando o celular e exportar a arte pronta.',
                  style: TextStyle(fontFamily: 'Inter', fontSize: 12, color: Color(0xFFE0E0E0), height: 1.3),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildReviewRow(String label, String value, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 16, color: AppColors.orangeAction),
        const SizedBox(width: 10),
        Text(label, style: const TextStyle(fontFamily: 'Inter', fontSize: 13, color: Color(0xFF9E9E9E))),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            value,
            textAlign: TextAlign.end,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontFamily: 'Inter', fontSize: 13, fontWeight: FontWeight.w700, color: Colors.white),
          ),
        ),
      ],
    );
  }

  Widget _buildBottomNavButtons(PlateTemplate? template, Company? company) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
      decoration: const BoxDecoration(
        color: Color(0xFF141513),
        border: Border(top: BorderSide(color: Color(0xFF222420))),
      ),
      child: Row(
        children: [
          if (_currentStep > 1) ...[
            SizedBox(
              height: 50,
              width: 110,
              child: OutlinedButton(
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.white70,
                  side: const BorderSide(color: Color(0xFF333532)),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
                ),
                onPressed: () => _goToStep(_currentStep - 1),
                child: const Text('Voltar', style: TextStyle(fontFamily: 'Inter')),
              ),
            ),
            const SizedBox(width: 12),
          ],
          Expanded(
            child: Material(
              color: AppColors.orangeAction,
              borderRadius: BorderRadius.circular(25),
              child: InkWell(
                onTap: _isSaving
                    ? null
                    : () {
                        if (_currentStep < 3) {
                          _goToStep(_currentStep + 1);
                        } else {
                          _handleSave(template, company);
                        }
                      },
                borderRadius: BorderRadius.circular(25),
                child: Container(
                  height: 50,
                  alignment: Alignment.center,
                  child: _isSaving
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : Text(
                          _currentStep < 3 ? 'Avançar' : (_isEditMode ? 'Salvar Alterações' : 'Salvar e Vincular Placa'),
                          style: const TextStyle(fontFamily: 'Inter', fontSize: 15, fontWeight: FontWeight.w700, color: Colors.white),
                        ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
