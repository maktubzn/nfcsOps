import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nfc_ops/core/models/activity_entry.dart';
import 'package:nfc_ops/core/models/company.dart';
import 'package:nfc_ops/core/models/order_item.dart';
import 'package:nfc_ops/core/models/user_profile.dart';
import 'package:nfc_ops/core/providers/app_providers.dart';
import 'package:nfc_ops/core/repositories/in_memory_repositories.dart';
import 'package:nfc_ops/core/theme/app_theme.dart';
import 'package:nfc_ops/features/activities/presentation/activities_screen.dart';
import 'package:nfc_ops/features/orders/presentation/orders_screen.dart';

Future<void> loadInterFonts() async {
  final fontLoader = FontLoader('Inter');
  final paths = [
    'assets/fonts/Inter-Regular.otf',
    'assets/fonts/Inter-Medium.otf',
    'assets/fonts/Inter-SemiBold.otf',
    'assets/fonts/Inter-Bold.otf',
  ];
  for (final p in paths) {
    final file = File(p);
    if (file.existsSync()) {
      final bytes = file.readAsBytesSync();
      fontLoader.addFont(Future.value(ByteData.view(bytes.buffer)));
    }
  }
  await fontLoader.load();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    await loadInterFonts();
  });

  final testDate = DateTime.utc(2026, 9, 22, 10, 0, 0);

  final testUser = UserProfile(
    uid: 'challenger-tester-01',
    email: 'challenger@nfcops.com.br',
    displayName: 'Empirical Challenger',
    role: 'admin',
    isActive: true,
    createdAt: testDate,
  );

  Widget createHarness({
    required Widget child,
    InMemoryOrderRepository? orderRepo,
    InMemoryCompanyRepository? compRepo,
    InMemoryActivityRepository? actRepo,
    TextScaler textScaler = TextScaler.noScaling,
  }) {
    final auth = InMemoryAuthRepository();
    auth.registerUser(testUser);
    auth.simulateLogin(testUser);

    final companyRepository = compRepo ?? InMemoryCompanyRepository(authRepository: auth);
    final orderRepository = orderRepo ??
        InMemoryOrderRepository(
          deviceRepository: InMemoryDeviceRepository(authRepository: auth),
          authRepository: auth,
        );
    final activityRepository = actRepo ?? InMemoryActivityRepository();

    return ProviderScope(
      overrides: [
        appModeProvider.overrideWith((ref) => AppMode.fixture),
        authRepositoryProvider.overrideWithValue(auth),
        companyRepositoryProvider.overrideWithValue(companyRepository),
        orderRepositoryProvider.overrideWithValue(orderRepository),
        activityRepositoryProvider.overrideWithValue(activityRepository),
      ],
      child: MaterialApp(
        theme: AppTheme.darkTheme,
        home: MediaQuery(
          data: MediaQueryData(
            size: const Size(372, 870),
            textScaler: textScaler,
          ),
          child: child,
        ),
      ),
    );
  }

  group('CHALLENGER ADVERSARIAL: OrdersScreen Viewport & Overflow Invariants', () {
    testWidgets('OrdersScreen canonical viewport 372x870 px: clean base, no overflow', (tester) async {
      tester.view.physicalSize = const Size(372, 870);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final List<FlutterErrorDetails> errors = [];
      final oldHandler = FlutterError.onError;
      FlutterError.onError = (details) {
        errors.add(details);
        oldHandler?.call(details);
      };
      addTearDown(() => FlutterError.onError = oldHandler);

      await tester.pumpWidget(createHarness(child: const OrdersScreen()));
      await tester.pumpAndSettle();

      expect(find.text('0 pedidos'), findsOneWidget);
      expect(find.text('Todos'), findsOneWidget);
      expect(find.text('Produção'), findsOneWidget);
      expect(find.text('Prontos'), findsOneWidget);

      // Verify no RenderFlex overflow
      expect(errors.where((e) => e.toString().contains('RenderFlex overflowed')), isEmpty);
    });

    testWidgets('OrdersScreen canonical viewport 372x870 px: populated with multiple orders and filter toggles', (tester) async {
      tester.view.physicalSize = const Size(372, 870);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final auth = InMemoryAuthRepository();
      auth.registerUser(testUser);
      auth.simulateLogin(testUser);

      final compRepo = InMemoryCompanyRepository(authRepository: auth);
      final devRepo = InMemoryDeviceRepository(authRepository: auth);
      final orderRepo = InMemoryOrderRepository(deviceRepository: devRepo, authRepository: auth);

      // Create company with very long name to test flex bounds
      final comp1 = await compRepo.createCompany(Company(
        id: 'comp-long-name-01',
        tradeName: 'Restaurante & Pizzaria Super Extraordinária com Nome Gigante Ltda',
        category: 'gastronomia',
        status: 'ativo',
        city: 'São Paulo',
        createdAt: testDate,
        updatedAt: testDate,
      ));

      final comp2 = await compRepo.createCompany(Company(
        id: 'comp-02',
        tradeName: 'Padaria Artesanal Silva',
        category: 'alimentacao',
        status: 'ativo',
        city: 'Barueri',
        createdAt: testDate,
        updatedAt: testDate,
      ));

      // Create orders: 1 in producao, 1 in pronto, 1 in orcamento
      await orderRepo.createOrder(OrderItem(
        id: 'ord-01',
        companyId: comp1.id,
        orderNumber: 'PED-99998888-LONG',
        status: OrderStatus.producao,
        paymentStatus: PaymentStatus.aprovado,
        totalInCents: 99999900,
        items: const [
          OrderItemDetail(title: 'Display Acrílico NFC Premium Luxo', quantity: 50, unitPriceInCents: 199999)
        ],
        createdAt: testDate,
        updatedAt: testDate,
      ));

      await orderRepo.createOrder(OrderItem(
        id: 'ord-02',
        companyId: comp2.id,
        orderNumber: 'PED-0002',
        status: OrderStatus.pronto,
        paymentStatus: PaymentStatus.aprovado,
        totalInCents: 25000,
        items: const [
          OrderItemDetail(title: 'Tag NFC Adesiva', quantity: 10, unitPriceInCents: 2500)
        ],
        createdAt: testDate,
        updatedAt: testDate,
      ));

      final List<FlutterErrorDetails> errors = [];
      final oldHandler = FlutterError.onError;
      FlutterError.onError = (details) {
        errors.add(details);
        oldHandler?.call(details);
      };
      addTearDown(() => FlutterError.onError = oldHandler);

      await tester.pumpWidget(createHarness(
        child: const OrdersScreen(),
        compRepo: compRepo,
        orderRepo: orderRepo,
      ));
      await tester.pumpAndSettle();

      expect(find.text('2 pedidos'), findsOneWidget);

      // Filter by 'Produção'
      await tester.tap(find.text('Produção'));
      await tester.pumpAndSettle();
      expect(find.text('1 pedido'), findsOneWidget);

      // Filter by 'Prontos'
      await tester.tap(find.text('Prontos'));
      await tester.pumpAndSettle();
      expect(find.text('1 pedido'), findsOneWidget);

      // Filter back to 'Todos'
      await tester.tap(find.text('Todos'));
      await tester.pumpAndSettle();
      expect(find.text('2 pedidos'), findsOneWidget);

      // Verify zero overflow errors
      expect(errors.where((e) => e.toString().contains('RenderFlex overflowed')), isEmpty);
    });

    testWidgets('OrdersScreen narrow viewport 320x640 px & large text scale stress test', (tester) async {
      tester.view.physicalSize = const Size(320, 640);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final List<FlutterErrorDetails> errors = [];
      final oldHandler = FlutterError.onError;
      FlutterError.onError = (details) {
        errors.add(details);
        oldHandler?.call(details);
      };
      addTearDown(() => FlutterError.onError = oldHandler);

      await tester.pumpWidget(createHarness(
        child: const OrdersScreen(),
        textScaler: const TextScaler.linear(1.4),
      ));
      await tester.pumpAndSettle();

      // Ensure horizontal scroll works on filter pills in 320px
      expect(find.byType(SingleChildScrollView), findsWidgets);
      expect(errors.where((e) => e.toString().contains('RenderFlex overflowed')), isEmpty);
    });
  });

  group('CHALLENGER ADVERSARIAL: ActivitiesScreen Viewport & Header Invariants', () {
    testWidgets('ActivitiesScreen canonical viewport 372x870 px: clean base, no overflow', (tester) async {
      tester.view.physicalSize = const Size(372, 870);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final List<FlutterErrorDetails> errors = [];
      final oldHandler = FlutterError.onError;
      FlutterError.onError = (details) {
        errors.add(details);
        oldHandler?.call(details);
      };
      addTearDown(() => FlutterError.onError = oldHandler);

      await tester.pumpWidget(createHarness(child: const ActivitiesScreen()));
      await tester.pumpAndSettle();

      expect(find.text('Atividades recentes'), findsOneWidget);
      expect(find.text('Nenhuma atividade recente'), findsOneWidget);
      expect(errors.where((e) => e.toString().contains('RenderFlex overflowed')), isEmpty);
    });

    testWidgets('ActivitiesScreen canonical viewport 372x870 px: populated with 10 activities', (tester) async {
      tester.view.physicalSize = const Size(372, 870);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final actRepo = InMemoryActivityRepository();
      for (int i = 1; i <= 10; i++) {
        await actRepo.logActivity(ActivityEntry(
          id: 'act-$i',
          actorUid: 'user-$i',
          actorName: 'Administrador Responsável Número $i',
          actionType: i.isEven ? 'create' : 'update',
          entityType: 'device',
          entityId: 'dev-$i',
          description: 'Alteração cadastral detalhada e complexa com texto longo na entidade número $i.',
          timestamp: testDate.subtract(Duration(minutes: i * 15)),
        ));
      }

      final List<FlutterErrorDetails> errors = [];
      final oldHandler = FlutterError.onError;
      FlutterError.onError = (details) {
        errors.add(details);
        oldHandler?.call(details);
      };
      addTearDown(() => FlutterError.onError = oldHandler);

      await tester.pumpWidget(createHarness(
        child: const ActivitiesScreen(),
        actRepo: actRepo,
      ));
      await tester.pumpAndSettle();

      expect(find.text('Atividades recentes'), findsOneWidget);
      expect(find.byType(ListView), findsOneWidget);
      expect(errors.where((e) => e.toString().contains('RenderFlex overflowed')), isEmpty);
    });

    testWidgets('ActivitiesScreen narrow viewport 320x640 px & large text scale stress test', (tester) async {
      tester.view.physicalSize = const Size(320, 640);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final List<FlutterErrorDetails> errors = [];
      final oldHandler = FlutterError.onError;
      FlutterError.onError = (details) {
        errors.add(details);
        oldHandler?.call(details);
      };
      addTearDown(() => FlutterError.onError = oldHandler);

      await tester.pumpWidget(createHarness(
        child: const ActivitiesScreen(),
        textScaler: const TextScaler.linear(1.5),
      ));
      await tester.pumpAndSettle();

      // Expanded on 'Atividades recentes' prevents header from overflowing
      expect(find.text('Atividades recentes'), findsOneWidget);
      expect(errors.where((e) => e.toString().contains('RenderFlex overflowed')), isEmpty);
    });
  });
}
