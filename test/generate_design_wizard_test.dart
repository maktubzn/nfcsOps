import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nfc_ops/core/models/company.dart';
import 'package:nfc_ops/core/models/generated_design.dart';
import 'package:nfc_ops/core/models/plate_template.dart';
import 'package:nfc_ops/core/providers/app_providers.dart';
import 'package:nfc_ops/core/repositories/in_memory_repositories.dart';
import 'package:nfc_ops/core/theme/app_theme.dart';
import 'package:nfc_ops/features/designs/presentation/design_preview_screen.dart';
import 'package:nfc_ops/features/designs/presentation/generate_design_screen.dart';
import 'package:qr_flutter/qr_flutter.dart';

void main() {
  testWidgets('GenerateDesignScreen loads 3-step wizard and inherits Canva template data', (tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.75;
    addTearDown(() => tester.view.resetPhysicalSize());

    final companyRepo = InMemoryCompanyRepository();
    final templateRepo = InMemoryTemplateRepository();

    final testCompany = Company(
      id: 'comp-test-1',
      tradeName: 'Reis e Fios Salão',
      category: 'Beleza',
      status: 'ativa',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
    await companyRepo.createCompany(testCompany);

    final canvaTemplate = PlateTemplate(
      id: 'tmpl-canva-1',
      name: 'reis e fios Instagram',
      category: 'acrilico',
      productType: 'placa_acrilica',
      physicalWidthCm: 10.0,
      physicalHeightCm: 10.0,
      baseImageUrl: '',
      origin: 'canva',
      canvaProjectUrl: 'https://canva.com/design/123',
      page1DynamicUrl: 'https://instagram.com/reisefios',
      relatedServiceType: 'Instagram',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
    await templateRepo.createTemplate(canvaTemplate);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          appModeProvider.overrideWith((ref) => AppMode.fixture),
          companyRepositoryProvider.overrideWithValue(companyRepo),
          templateRepositoryProvider.overrideWithValue(templateRepo),
        ],
        child: MaterialApp(
          theme: AppTheme.darkTheme,
          home: const GenerateDesignScreen(
            initialCompanyId: 'comp-test-1',
            initialTemplateId: 'tmpl-canva-1',
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // 1. Verifica título e indicador das 3 etapas
    expect(find.text('Vincular Placa para Empresa'), findsOneWidget);
    expect(find.text('Empresa'), findsWidgets);
    expect(find.text('Estoque'), findsOneWidget);
    expect(find.text('Revisão'), findsOneWidget);

    // 2. Verifica dados herdados do template Canva
    expect(find.text('reis e fios Instagram'), findsOneWidget);
    expect(find.text('CANVA'), findsOneWidget);
    expect(find.text('Herdado da arte'), findsOneWidget);
    expect(find.text('https://instagram.com/reisefios'), findsOneWidget);

    // 3. Avançar para Etapa 2
    await tester.tap(find.text('Avançar'));
    await tester.pumpAndSettle();

    expect(find.text('Placa Física & Estoque'), findsOneWidget);
    expect(find.text('Criar Pedido de Produção'), findsOneWidget);
    expect(find.text('Voltar'), findsOneWidget);

    // 4. Avançar para Etapa 3 (Revisão)
    await tester.tap(find.text('Avançar'));
    await tester.pumpAndSettle();

    expect(find.text('Revisão da Placa'), findsOneWidget);
    expect(find.text('Reis e Fios Salão'), findsOneWidget);
    expect(find.text('Salvar e Vincular Placa'), findsOneWidget);
  });

  testWidgets('DesignPreviewScreen suppresses superimposed QrImageView for Canva templates', (tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.75;
    addTearDown(() => tester.view.resetPhysicalSize());

    final designRepo = InMemoryGeneratedDesignRepository();
    final templateRepo = InMemoryTemplateRepository();
    final companyRepo = InMemoryCompanyRepository();

    final testCompany = Company(
      id: 'comp-10',
      tradeName: 'Barbearia Top',
      category: 'Barbearia',
      status: 'ativa',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
    await companyRepo.createCompany(testCompany);

    final canvaTemplate = PlateTemplate(
      id: 'tmpl-canva-pure',
      name: 'Arte Pronta Canva',
      category: 'acrilico',
      productType: 'placa_acrilica',
      physicalWidthCm: 10.0,
      physicalHeightCm: 10.0,
      baseImageUrl: '',
      origin: 'canva',
      page1DynamicUrl: 'https://instagram.com/barbearia',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
    await templateRepo.createTemplate(canvaTemplate);

    final testDesign = GeneratedDesign(
      id: 'dsg-canva-test',
      templateId: 'tmpl-canva-pure',
      companyId: 'comp-10',
      qrCodeId: 'qr-dummy',
      status: 'pronto',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
    await designRepo.createDesign(testDesign);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          appModeProvider.overrideWith((ref) => AppMode.fixture),
          companyRepositoryProvider.overrideWithValue(companyRepo),
          templateRepositoryProvider.overrideWithValue(templateRepo),
          generatedDesignRepositoryProvider.overrideWithValue(designRepo),
        ],
        child: MaterialApp(
          theme: AppTheme.darkTheme,
          home: const DesignPreviewScreen(designId: 'dsg-canva-test'),
        ),
      ),
    );

    await tester.pumpAndSettle();

    final err = tester.takeException();
    if (err != null) {
      debugPrint('TEST 2 EXCEPTION: $err');
    }

    // Canva templates must NEVER render the superimposed QrImageView widget
    expect(find.byType(QrImageView), findsNothing);
    expect(find.text('Exportar PNG para Impressão'), findsOneWidget);
  });
}
