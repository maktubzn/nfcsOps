import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nfc_ops/core/fixtures/seed_data.dart';
import 'package:nfc_ops/core/models/company.dart';
import 'package:nfc_ops/core/providers/app_providers.dart';
import 'package:nfc_ops/core/repositories/in_memory_repositories.dart';
import 'package:nfc_ops/core/theme/app_theme.dart';
import 'package:nfc_ops/features/companies/presentation/companies_screen.dart';

void main() {
  late InMemoryAuthRepository authRepo;
  late InMemoryCompanyRepository compRepo;
  late InMemoryServiceRepository srvRepo;
  late InMemoryOrderRepository orderRepo;
  late InMemoryDeviceRepository devRepo;

  setUp(() async {
    authRepo = InMemoryAuthRepository();
    authRepo.registerUser(SeedData.demoAdmin);
    authRepo.simulateLogin(SeedData.demoAdmin);
    compRepo = InMemoryCompanyRepository();
    srvRepo = InMemoryServiceRepository();
    orderRepo = InMemoryOrderRepository();
    devRepo = InMemoryDeviceRepository();

    final testDate = DateTime.utc(2026, 9, 20);

    // Inserir 3 empresas pontuais no repositório para os testes de busca, categorias e cidades
    await compRepo.createCompany(Company(
      id: 'emp-01',
      tradeName: 'Auto Center Silva',
      legalName: 'Silva Centro Automotivo LTDA',
      category: 'Oficina',
      status: 'ativo',
      contactName: 'Carlos Silva',
      city: 'Barueri',
      servicesCount: 4,
      createdAt: testDate,
      updatedAt: testDate,
    ));
    await compRepo.createCompany(Company(
      id: 'emp-02',
      tradeName: 'Café Aurora',
      legalName: 'Aurora Cafés Especiais LTDA',
      category: 'Cafeteria',
      status: 'ativo',
      contactName: 'Juliana Mendes',
      city: 'Osasco',
      servicesCount: 2,
      createdAt: testDate,
      updatedAt: testDate,
    ));
    await compRepo.createCompany(Company(
      id: 'emp-03',
      tradeName: 'Pet Vila',
      legalName: 'Vila Pet Shop LTDA',
      category: 'Pet Shop',
      status: 'lead',
      contactName: 'Renata Lima',
      city: 'Cotia',
      servicesCount: 1,
      createdAt: testDate,
      updatedAt: testDate,
    ));
  });

  Widget buildApp() {
    return ProviderScope(
      overrides: [
        authRepositoryProvider.overrideWithValue(authRepo),
        companyRepositoryProvider.overrideWithValue(compRepo),
        serviceRepositoryProvider.overrideWithValue(srvRepo),
        orderRepositoryProvider.overrideWithValue(orderRepo),
        deviceRepositoryProvider.overrideWithValue(devRepo),
      ],
      child: MaterialApp(
        theme: AppTheme.darkTheme,
        home: const CompaniesScreen(),
      ),
    );
  }

  testWidgets('CompaniesScreen (S03) renders welcoming empty state on clean base (0 companies)', (tester) async {
    final emptyCompRepo = InMemoryCompanyRepository();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authRepositoryProvider.overrideWithValue(authRepo),
          companyRepositoryProvider.overrideWithValue(emptyCompRepo),
          serviceRepositoryProvider.overrideWithValue(srvRepo),
          orderRepositoryProvider.overrideWithValue(orderRepo),
          deviceRepositoryProvider.overrideWithValue(devRepo),
        ],
        child: MaterialApp(
          theme: AppTheme.darkTheme,
          home: const CompaniesScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Nenhuma empresa cadastrada'), findsOneWidget);
    expect(find.text('+ Cadastrar Empresa'), findsOneWidget);
    expect(find.textContaining('0 cadastradas'), findsOneWidget);
  });

  testWidgets('CompaniesScreen (S03) renders header and company count', (tester) async {
    await tester.pumpWidget(buildApp());
    await tester.pumpAndSettle();

    expect(find.text('Empresas'), findsOneWidget);
    expect(find.textContaining('cadastradas'), findsOneWidget);
  });

  testWidgets('CompaniesScreen (S03) renders search field', (tester) async {
    await tester.pumpWidget(buildApp());
    await tester.pumpAndSettle();

    expect(find.byType(TextField), findsOneWidget);
    expect(find.text('Nome, telefone ou código'), findsOneWidget);
  });

  testWidgets('CompaniesScreen (S03) renders filter chips', (tester) async {
    await tester.pumpWidget(buildApp());
    await tester.pumpAndSettle();

    expect(find.text('Ativas'), findsOneWidget);
    expect(find.text('Categoria'), findsOneWidget);
    expect(find.text('Cidade'), findsOneWidget);
  });

  testWidgets('CompaniesScreen (S03) renders company cards from fixture', (tester) async {
    await tester.pumpWidget(buildApp());
    await tester.pumpAndSettle();

    // Card 1 (featured) should display Auto Center Silva
    expect(find.text('Auto Center Silva'), findsOneWidget);
    // Card 2
    expect(find.text('Café Aurora'), findsOneWidget);
  });

  testWidgets('CompaniesScreen (S03) search filters companies by name', (tester) async {
    await tester.pumpWidget(buildApp());
    await tester.pumpAndSettle();

    // Enter search text
    await tester.enterText(find.byType(TextField), 'Aurora');
    await tester.pumpAndSettle();

    // Should find Café Aurora
    expect(find.text('Café Aurora'), findsOneWidget);
    // Should NOT find Auto Center Silva
    expect(find.text('Auto Center Silva'), findsNothing);
  });

  testWidgets('CompaniesScreen (S03) search by city', (tester) async {
    await tester.pumpWidget(buildApp());
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), 'Cotia');
    await tester.pumpAndSettle();

    // Pet Vila is in Cotia
    expect(find.text('Pet Vila'), findsOneWidget);
  });

  testWidgets('CompaniesScreen (S03) search shows empty state', (tester) async {
    await tester.pumpWidget(buildApp());
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), 'zzzzzznonexistent');
    await tester.pumpAndSettle();

    expect(find.text('Nenhuma empresa encontrada para o filtro selecionado.'), findsOneWidget);
  });

  testWidgets('CompaniesScreen (S03) clear search button works', (tester) async {
    await tester.pumpWidget(buildApp());
    await tester.pumpAndSettle();

    // Enter text
    await tester.enterText(find.byType(TextField), 'test');
    await tester.pumpAndSettle();

    // Close button should appear
    expect(find.byIcon(Icons.close), findsOneWidget);

    // Tap to clear
    await tester.tap(find.byIcon(Icons.close));
    await tester.pumpAndSettle();

    // Auto Center Silva should be visible again
    expect(find.text('Auto Center Silva'), findsOneWidget);
  });

  testWidgets('CompaniesScreen (S03) filter chip toggles Ativas/Todas', (tester) async {
    await tester.pumpWidget(buildApp());
    await tester.pumpAndSettle();

    // Initially 'Ativas'
    expect(find.text('Ativas'), findsOneWidget);

    // Tap to toggle to 'Todas'
    await tester.tap(find.text('Ativas'));
    await tester.pumpAndSettle();

    expect(find.text('Todas'), findsOneWidget);
  });

  testWidgets('CompaniesScreen (S03) displays + Nova empresa button', (tester) async {
    await tester.pumpWidget(buildApp());
    await tester.pumpAndSettle();

    expect(find.text('Nova empresa'), findsOneWidget);
    expect(find.byIcon(Icons.add), findsWidgets);
  });

  testWidgets('CompaniesScreen (S03) card shows services count and status', (tester) async {
    await tester.pumpWidget(buildApp());
    await tester.pumpAndSettle();

    // Auto Center Silva has 4 serviços and is Ativa
    expect(find.textContaining('4 serviços'), findsWidgets);
    expect(find.textContaining('Ativa'), findsWidgets);
  });

  testWidgets('CompaniesScreen (S03) Lead status shows correctly for Pet Vila', (tester) async {
    tester.view.physicalSize = const Size(372, 870);
    tester.view.devicePixelRatio = 1.0;

    await tester.pumpWidget(buildApp());
    await tester.pumpAndSettle();

    // Toggle to 'Todas' to see Lead companies
    await tester.tap(find.text('Ativas'));
    await tester.pumpAndSettle();

    // Pet Vila is visible
    expect(find.text('Pet Vila'), findsOneWidget);
    expect(find.textContaining('Lead'), findsWidgets);

    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });

  testWidgets('CompaniesScreen (S03) Categoria filter modal opens and filters', (tester) async {
    await tester.pumpWidget(buildApp());
    await tester.pumpAndSettle();

    // Tap Categoria chip
    await tester.tap(find.text('Categoria'));
    await tester.pumpAndSettle();

    // Modal title should appear
    expect(find.text('Filtrar por Categoria'), findsOneWidget);

    // Tap 'Oficina'
    await tester.tap(find.text('Oficina'));
    await tester.pumpAndSettle();

    // Auto Center Silva (Oficina) should be visible
    expect(find.text('Auto Center Silva'), findsOneWidget);
    // Café Aurora (Cafeteria) should NOT be visible
    expect(find.text('Café Aurora'), findsNothing);
  });

  testWidgets('CompaniesScreen (S03) Cidade filter modal opens and filters', (tester) async {
    await tester.pumpWidget(buildApp());
    await tester.pumpAndSettle();

    // Tap Cidade chip
    await tester.tap(find.text('Cidade'));
    await tester.pumpAndSettle();

    // Modal title should appear
    expect(find.text('Filtrar por Cidade'), findsOneWidget);

    // Tap 'Osasco'
    await tester.tap(find.text('Osasco'));
    await tester.pumpAndSettle();

    // Café Aurora is in Osasco
    expect(find.text('Café Aurora'), findsOneWidget);
    // Auto Center Silva is in Barueri -> not visible
    expect(find.text('Auto Center Silva'), findsNothing);
  });
}
