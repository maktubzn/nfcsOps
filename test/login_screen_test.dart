import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nfc_ops/core/fixtures/seed_data.dart';
import 'package:nfc_ops/core/providers/app_providers.dart';
import 'package:nfc_ops/core/repositories/in_memory_repositories.dart';
import 'package:nfc_ops/features/auth/presentation/login_screen.dart';

void main() {
  group('LoginScreen (S01) Widget & Interaction Tests', () {
    late InMemoryAuthRepository authRepo;

    setUp(() {
      authRepo = InMemoryAuthRepository();
    });

    Widget createTestWidget() {
      return ProviderScope(
        overrides: [
          authRepositoryProvider.overrideWithValue(authRepo),
        ],
        child: const MaterialApp(
          home: LoginScreen(),
        ),
      );
    }

    testWidgets('Renders all canonical visual elements of S01', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Marca (RichText)
      expect(
        find.byWidgetPredicate((w) => w is RichText && w.text.toPlainText().contains('NFC Ops')),
        findsOneWidget,
      );

      // Headline (RichText)
      expect(
        find.byWidgetPredicate((w) => w is RichText && w.text.toPlainText().contains('Sua operação,\nconectada.')),
        findsOneWidget,
      );

      // Subtítulo
      expect(find.textContaining('Clientes, placas e serviços'), findsOneWidget);

      // Botão Entrar com Google
      expect(find.text('Entrar com Google'), findsOneWidget);

      // Disclaimer
      expect(find.text('Acesso exclusivo para usuários autorizados.'), findsOneWidget);
    });

    testWidgets('Tapping Google login with unauthorized profile displays error banner', (tester) async {
      tester.view.physicalSize = const Size(372, 870);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      // Configura authRepo para retornar usuário não autorizado
      authRepo.registerUser(SeedData.unauthorizedUser);

      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Simula login de usuário não autorizado
      authRepo.simulateLogin(SeedData.unauthorizedUser);

      final button = find.text('Entrar com Google');
      await tester.ensureVisible(button);
      await tester.tap(button);
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.info_outline), findsOneWidget);
    });
  });
}
