import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:nfc_ops/core/models/company.dart';
import 'package:nfc_ops/core/models/generated_design.dart';
import 'package:nfc_ops/core/models/plate_template.dart';
import 'package:nfc_ops/core/providers/app_providers.dart';
import 'package:nfc_ops/core/theme/app_theme.dart';
import 'package:nfc_ops/features/designs/presentation/design_preview_screen.dart';
import 'package:nfc_ops/features/templates/presentation/template_detail_screen.dart';

void main() {
  final now = DateTime.now();

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

  final company = Company(
    id: 'comp-01',
    tradeName: 'Reis e Fios',
    category: 'Oficina',
    city: 'São Paulo',
    status: 'ativa',
    createdAt: now,
    updatedAt: now,
  );

  final design = GeneratedDesign(
    id: 'dsg-01',
    templateId: 'tmpl-canva-01',
    companyId: 'comp-01',
    qrCodeId: 'qr-01',
    status: 'pronto',
    createdAt: now,
    updatedAt: now,
  );

  testWidgets('TemplateDetailScreen shows Ver Placa da Empresa and pencil icon when linked', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          appModeProvider.overrideWith((ref) => AppMode.fixture),
          templatesStreamProvider.overrideWith((ref) => Stream.value([template])),
          companiesStreamProvider.overrideWith((ref) => Stream.value([company])),
          generatedDesignsStreamProvider.overrideWith((ref) => Stream.value([design])),
        ],
        child: MaterialApp(
          theme: AppTheme.darkTheme,
          home: const TemplateDetailScreen(templateId: 'tmpl-canva-01'),
        ),
      ),
    );

    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    // Verifica que exibe o banner de Placa Vinculada
    expect(find.text('Placa Vinculada'), findsOneWidget);
    expect(find.text('Reis e Fios'), findsOneWidget);

    // Verifica que o botão virou "Ver Placa da Empresa"
    expect(find.text('Ver Placa da Empresa'), findsOneWidget);
    expect(find.text('Vincular e Gerar Placa para Empresa'), findsNothing);

    // Verifica o ícone de edição (lápis)
    expect(find.byIcon(LucideIcons.pencil), findsWidgets);
  });

  testWidgets('DesignPreviewScreen for Canva plate shows Gravar Chip NFC and Testar Link without fake redirect', (tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.75;
    addTearDown(() => tester.view.resetPhysicalSize());

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          appModeProvider.overrideWith((ref) => AppMode.fixture),
          templatesStreamProvider.overrideWith((ref) => Stream.value([template])),
          companiesStreamProvider.overrideWith((ref) => Stream.value([company])),
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

    // Verifica que exibe Gravar Chip NFC e Testar Link
    expect(find.text('Gravar Chip NFC'), findsOneWidget);
    expect(find.text('Testar Link'), findsOneWidget);

    // Verifica que NÃO exibe Editar Destino para placas Canva
    expect(find.text('Editar Destino'), findsNothing);
    expect(find.text('Link Permanente'), findsNothing);

    // Verifica que exibe o Link da Arte (Canva)
    expect(find.text('Link da Arte (Canva)'), findsOneWidget);
  });
}
