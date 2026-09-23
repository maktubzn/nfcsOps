import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nfc_ops/core/fixtures/seed_data.dart';
import 'package:nfc_ops/core/providers/app_providers.dart';
import 'package:nfc_ops/core/repositories/in_memory_repositories.dart';
import 'package:nfc_ops/core/theme/app_theme.dart';
import 'package:nfc_ops/features/companies/presentation/create_company_screen.dart';

void main() {
  group('CreateCompanyScreen (S04) Tests', () {
    late InMemoryAuthRepository authRepo;
    late InMemoryCompanyRepository compRepo;
    late InMemoryServiceRepository srvRepo;
    late InMemoryActivityRepository actRepo;

    setUp(() {
      authRepo = InMemoryAuthRepository();
      authRepo.registerUser(SeedData.demoAdmin);
      authRepo.simulateLogin(SeedData.demoAdmin);

      compRepo = InMemoryCompanyRepository();
      srvRepo = InMemoryServiceRepository();
      actRepo = InMemoryActivityRepository();
    });

    Widget createTestWidget({
      String? initialName,
      String? initialCategory,
      String? initialStatus,
      String? initialContact,
      String? initialPhone,
      String? initialCityUf,
    }) {
      return ProviderScope(
        overrides: [
          authRepositoryProvider.overrideWithValue(authRepo),
          companyRepositoryProvider.overrideWithValue(compRepo),
          serviceRepositoryProvider.overrideWithValue(srvRepo),
          activityRepositoryProvider.overrideWithValue(actRepo),
        ],
        child: MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: AppTheme.darkTheme,
          home: CreateCompanyScreen(
            initialName: initialName,
            initialCategory: initialCategory,
            initialStatus: initialStatus,
            initialContact: initialContact,
            initialPhone: initialPhone,
            initialCityUf: initialCityUf,
          ),
        ),
      );
    }

    testWidgets('renders all canonical elements of S04', (tester) async {
      tester.view.physicalSize = const Size(372, 870);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      expect(find.text('Nova empresa'), findsOneWidget);
      expect(find.text('Nome da empresa *'), findsOneWidget);
      expect(find.text('Categoria *'), findsOneWidget);
      expect(find.text('Status *'), findsOneWidget);
      expect(find.text('Responsável'), findsOneWidget);
      expect(find.text('CEP (busca automática de endereço)'), findsOneWidget);
      expect(find.text('Cidade *'), findsOneWidget);
      expect(find.text('Estado (UF) *'), findsOneWidget);
      expect(find.text('Mais dados opcionais'), findsOneWidget);
      expect(find.text('Logo e observações'), findsOneWidget);
      expect(find.text('Sugestões para oficinas'), findsOneWidget);
      expect(find.text('Reviews'), findsOneWidget);
      expect(find.text('WhatsApp'), findsNWidgets(2)); // Field label + suggestion chip
      expect(find.text('Salvar empresa'), findsOneWidget);
    });

    testWidgets('validates required name field', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      final initialCompanies = await compRepo.getCompanies();

      // Tap Salvar empresa with empty name
      await tester.ensureVisible(find.text('Salvar empresa'));
      await tester.tap(find.text('Salvar empresa'));
      await tester.pumpAndSettle();

      expect(find.text('Informe o nome da empresa'), findsOneWidget);
      final afterCompanies = await compRepo.getCompanies();
      expect(afterCompanies.length, equals(initialCompanies.length));
    });

    testWidgets('saves company and logs activity when valid', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      final initialCompanies = await compRepo.getCompanies();
      final initialActivities = await actRepo.getActivities();

      // Fill name
      final nameField = find.byType(TextFormField).first;
      await tester.enterText(nameField, 'Auto Center Silva');

      // Tap Salvar empresa
      await tester.ensureVisible(find.text('Salvar empresa'));
      await tester.tap(find.text('Salvar empresa'));
      await tester.pumpAndSettle();

      final afterCompanies = await compRepo.getCompanies();
      final afterActivities = await actRepo.getActivities();

      expect(afterCompanies.length, equals(initialCompanies.length + 1));
      expect(afterCompanies.any((c) => c.tradeName == 'Auto Center Silva'), isTrue);
      expect(afterActivities.length, equals(initialActivities.length + 1));
      expect(afterActivities.first.description, contains('Auto Center Silva'));
    });

    testWidgets('collapsible sections toggle visibility', (tester) async {
      tester.view.physicalSize = const Size(372, 870);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      expect(find.text('CNPJ'), findsNothing);
      expect(find.text('Complemento / Bairro'), findsNothing);
      expect(find.text('Observações internas'), findsNothing);

      // Expand Mais dados opcionais
      await tester.ensureVisible(find.text('Mais dados opcionais'));
      await tester.tap(find.text('Mais dados opcionais'));
      await tester.pumpAndSettle();

      expect(find.text('CNPJ'), findsOneWidget);
      expect(find.text('E-mail'), findsOneWidget);
      expect(find.text('Complemento / Bairro'), findsOneWidget);

      // Expand Logo e observações
      await tester.ensureVisible(find.text('Logo e observações'));
      await tester.tap(find.text('Logo e observações'));
      await tester.pumpAndSettle();

      expect(find.text('Observações internas'), findsOneWidget);

      // Collapse Mais dados opcionais
      await tester.ensureVisible(find.text('Mais dados opcionais'));
      await tester.tap(find.text('Mais dados opcionais'));
      await tester.pumpAndSettle();

      expect(find.text('CNPJ'), findsNothing);
      expect(find.text('Complemento / Bairro'), findsNothing);
      expect(find.text('Observações internas'), findsOneWidget);
    });

    testWidgets('suggestions do not auto-create services', (tester) async {
      tester.view.physicalSize = const Size(372, 870);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      final initialServices = await srvRepo.getAllServices();

      // Tap Reviews suggestion chip
      await tester.ensureVisible(find.text('Reviews'));
      await tester.tap(find.text('Reviews'));
      await tester.pumpAndSettle();

      final afterServices = await srvRepo.getAllServices();
      expect(afterServices.length, equals(initialServices.length));
    });
  });
}
