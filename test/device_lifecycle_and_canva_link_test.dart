import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nfc_ops/core/models/company.dart';
import 'package:nfc_ops/core/models/device_item.dart';
import 'package:nfc_ops/core/models/generated_design.dart';
import 'package:nfc_ops/core/models/plate_template.dart';
import 'package:nfc_ops/core/providers/app_providers.dart';
import 'package:nfc_ops/core/theme/app_theme.dart';
import 'package:nfc_ops/features/designs/presentation/design_preview_screen.dart';
import 'package:nfc_ops/features/inventory/presentation/device_detail_screen.dart';

void main() {
  final now = DateTime.now();

  final company = Company(
    id: 'comp-01',
    tradeName: 'Reis e Fios',
    category: 'Oficina',
    city: 'São Paulo',
    status: 'ativa',
    createdAt: now,
    updatedAt: now,
  );

  final template = PlateTemplate(
    id: 'tmpl-canva-01',
    name: 'Reis e Fios Instagram',
    category: 'social',
    productType: 'placa_acrilica',
    origin: 'canva',
    baseImageUrl: 'https://example.com/art.png',
    physicalWidthCm: 10,
    physicalHeightCm: 10,
    page1DynamicUrl: 'https://www.canvaqr.com/RGT2SrhNVz',
    createdAt: now,
    updatedAt: now,
  );

  final design = GeneratedDesign(
    id: 'dsg-01',
    templateId: 'tmpl-canva-01',
    companyId: 'comp-01',
    qrCodeId: 'qr-01',
    deviceId: 'dev-01',
    status: 'pronto',
    createdAt: now,
    updatedAt: now,
  );

  final deviceInProduction = DeviceItem(
    id: 'dev-01',
    batchId: '04:D8:39:A1:76:26:81 placa reis e fios',
    deviceType: 'cartao_pvc',
    status: DeviceStatus.emProducao,
    assignedCompanyId: 'comp-01',
    primaryServiceId: 'srv-1790044886836',
    nfcUid: '04:D8:39:A1:76:26:81',
    nfcRecordedBy: 'Gustavo Alves',
    nfcRecordedAt: now,
    checklist: const PhysicalChecklist(
      visualInspection: true,
      nfcChipWriting: true,
      nfcReadingTest: true,
      qrPrintInspection: true,
      qrScanVerification: true,
      urlMatchConfirmation: true,
      companyVerification: true,
      finalPackaging: true,
    ),
    createdAt: now,
    updatedAt: now,
  );

  final deviceInstalled = deviceInProduction.copyWith(
    status: DeviceStatus.instalado,
  );

  testWidgets('DeviceDetailScreen in emProducao shows checklist and Marcar como instalado, but NO Marcar em producao', (tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.75;
    addTearDown(() => tester.view.resetPhysicalSize());

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          appModeProvider.overrideWith((ref) => AppMode.fixture),
          devicesStreamProvider.overrideWith((ref) => Stream.value([deviceInProduction])),
          companiesStreamProvider.overrideWith((ref) => Stream.value([company])),
          templatesStreamProvider.overrideWith((ref) => Stream.value([template])),
          generatedDesignsStreamProvider.overrideWith((ref) => Stream.value([design])),
          servicesStreamProvider.overrideWith((ref) => Stream.value([])),
        ],
        child: MaterialApp(
          theme: AppTheme.darkTheme,
          home: const DeviceDetailScreen(deviceId: 'dev-01'),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // 1. Confirma exibição do Card Visual da Placa Canva
    expect(find.text('Reis e Fios Instagram'), findsOneWidget);
    expect(find.text('CANVA'), findsOneWidget);
    expect(find.text('Ver Arte'), findsOneWidget);

    // 2. Confirma que o subtítulo da empresa exibe o nome do modelo em vez do ID cru srv-...
    expect(find.text('srv-1790044886836'), findsNothing);

    // 3. Confirma presença de Executar checklist e Marcar como instalado
    expect(find.text('Executar checklist'), findsOneWidget);
    expect(find.text('Marcar como instalado'), findsOneWidget);

    // 4. Confirma que Marcar em produção foi REMOVIDO pois já está em produção
    expect(find.text('Marcar em produção'), findsNothing);
  });

  testWidgets('DeviceDetailScreen in instalado shows Instalado no Cliente banner and no transition buttons', (tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.75;
    addTearDown(() => tester.view.resetPhysicalSize());

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          appModeProvider.overrideWith((ref) => AppMode.fixture),
          devicesStreamProvider.overrideWith((ref) => Stream.value([deviceInstalled])),
          companiesStreamProvider.overrideWith((ref) => Stream.value([company])),
          templatesStreamProvider.overrideWith((ref) => Stream.value([template])),
          generatedDesignsStreamProvider.overrideWith((ref) => Stream.value([design])),
          servicesStreamProvider.overrideWith((ref) => Stream.value([])),
        ],
        child: MaterialApp(
          theme: AppTheme.darkTheme,
          home: const DeviceDetailScreen(deviceId: 'dev-01'),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // Confirma banner de instalado
    expect(find.text('Dispositivo Instalado no Cliente'), findsOneWidget);

    // Confirma que não há botões de transição
    expect(find.text('Marcar em produção'), findsNothing);
    expect(find.text('Marcar como instalado'), findsNothing);
  });

  testWidgets('DesignPreviewScreen shows linked physical chip information from inventory', (tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.75;
    addTearDown(() => tester.view.resetPhysicalSize());

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          appModeProvider.overrideWith((ref) => AppMode.fixture),
          devicesStreamProvider.overrideWith((ref) => Stream.value([deviceInProduction])),
          companiesStreamProvider.overrideWith((ref) => Stream.value([company])),
          templatesStreamProvider.overrideWith((ref) => Stream.value([template])),
          generatedDesignsStreamProvider.overrideWith((ref) => Stream.value([design])),
          qrCodesStreamProvider.overrideWith((ref) => Stream.value([])),
        ],
        child: MaterialApp(
          theme: AppTheme.darkTheme,
          home: const DesignPreviewScreen(designId: 'dsg-01'),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // Confirma exibição dos dados do Chip Físico na placa
    expect(find.text('Chip Físico (Estoque)'), findsOneWidget);
    expect(find.text('04:D8:39:A1:76:26:81 placa reis e fios'), findsOneWidget);
    expect(find.text('Gravado no Mobile'), findsOneWidget);
  });
}
