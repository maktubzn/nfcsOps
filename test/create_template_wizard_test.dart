import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nfc_ops/core/providers/app_providers.dart';
import 'package:nfc_ops/core/theme/app_theme.dart';
import 'package:nfc_ops/features/templates/presentation/create_template_screen.dart';

void main() {
  testWidgets('CreateTemplateScreen 3-step wizard completes without BoxConstraints error', (tester) async {
    // Set standard phone viewport
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.75;
    addTearDown(() => tester.view.resetPhysicalSize());

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          appModeProvider.overrideWith((ref) => AppMode.fixture),
        ],
        child: MaterialApp(
          theme: AppTheme.darkTheme,
          home: const CreateTemplateScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // 1. Etapa 1: Deve mostrar campo de nome e botão Avançar
    expect(find.text('Etapa 1 de 3'), findsOneWidget);
    expect(find.text('Avançar'), findsOneWidget);

    // Preenche o nome
    await tester.enterText(find.byType(TextField).first, 'Placa Teste 10x10');
    await tester.pumpAndSettle();

    // Clica em Avançar
    await tester.tap(find.text('Avançar'));
    await tester.pumpAndSettle();

    // 2. Etapa 2: Deve mostrar Etapa 2 de 3 e botão Voltar (sem erro de BoxConstraints infinite width!)
    expect(find.text('Etapa 2 de 3'), findsOneWidget);
    expect(find.text('Voltar'), findsOneWidget);
    expect(tester.takeException(), isNull); // Nenhuma exceção de layout!

    // Clica em Avançar para ir para Etapa 3
    await tester.tap(find.text('Avançar'));
    await tester.pumpAndSettle();

    // 3. Etapa 3: Deve mostrar Etapa 3 de 3 e botão "Salvar Modelo"
    expect(find.text('Etapa 3 de 3'), findsOneWidget);
    expect(find.text('Salvar Modelo'), findsOneWidget);
    expect(find.text('Voltar'), findsOneWidget);
    expect(tester.takeException(), isNull);

    // 4. Clica em "Salvar Modelo"
    await tester.tap(find.text('Salvar Modelo'));
    await tester.pumpAndSettle();

    // 5. Deve abrir o modal de sucesso com "Modelo Criado!" e botão "Concluir"
    expect(find.text('Modelo Criado!'), findsOneWidget);
    expect(find.text('Concluir'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
