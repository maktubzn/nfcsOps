# Handoff Report — Explorer: Survey & Seed Architecture

## 1. Observation

- **Arquivo `lib/core/fixtures/seed_data.dart`**:
  - Contém 515 linhas definindo `SeedData.fixedDate`, `demoAdmin`, `unauthorizedUser`, `companies` (18 itens), `services` (47 itens), `devices` (5 itens) e `orders` (5 itens).
- **Repositórios em Memória (`lib/core/repositories/in_memory_repositories.dart`)**:
  - Linha 2: `import '../fixtures/seed_data.dart';`
  - Linha 26-27: `_registeredUsers[SeedData.demoAdmin.uid] = SeedData.demoAdmin;`
  - Linhas 99-100: `clock = clock ?? (() => SeedData.fixedDate); final list = initialCompanies ?? SeedData.companies;`
  - Linhas 199-200: `clock = clock ?? (() => SeedData.fixedDate); final list = initialServices ?? SeedData.services;`
  - Linhas 309-310: `clock = clock ?? (() => SeedData.fixedDate); final list = initialDevices ?? SeedData.devices;`
  - Linhas 436-437: `clock = clock ?? (() => SeedData.fixedDate); final list = initialOrders ?? SeedData.orders;`
  - Linhas 617-673: `MockHealthCheckService` usa `checkedAt: SeedData.fixedDate`.
- **Repositórios Firestore Reais (`lib/core/repositories/firestore_repositories.dart`)**:
  - Linhas 1 a 662: Totalmente desacoplados de `seed_data.dart`. Comunicam-se diretamente com o Cloud Firestore nomeado (`ai-studio-conectordebanco-005a990b-ecd4-41ad-ba1e-0e68b83c29fd`).
  - Todas as chamadas de listagem (`getCompanies`, `getAllServices`, `getDevices`, `getOrders`, `getActivities`) e streams retornam listas vazias `[]` de forma graciosa sem exceções.
- **Configuração do App (`lib/main.dart` e `lib/core/providers/app_providers.dart`)**:
  - `lib/main.dart`, linha 22: `appModeProvider.overrideWith((ref) => AppMode.production);`
  - `lib/core/providers/app_providers.dart`, linhas 40-112: Injeta `Firestore*Repository` quando `mode == AppMode.production`.
- **Mock Hardcoded Descoberto em Tela (`lib/features/inventory/presentation/inventory_screen.dart`)**:
  - Linhas 326-347: Card de alerta laranja com texto fixo:
    ```dart
    // Alerta Laranja: "Estoque baixo • Adesivos: 3"
    Container(
      child: Text('Estoque baixo • Adesivos: 3'),
    )
    ```
    Renderizado estaticamente mesmo que o inventário esteja 100% vazio.
- **Comportamento de Empty States nas Telas**:
  - `DashboardScreen`: Se `totalServices == 0`, `healthRatio` resulta em `1.0` (linha 84) e exibe "100% saudáveis" com zero serviços; pendências exibem `"Nenhuma pendência operacional no momento."`.
  - `CompaniesScreen`: Linhas 245-254 exibem apenas `"Nenhuma empresa encontrada."` em texto cinza sem botão CTA para criar primeira empresa.
  - `HealthCenterScreen`: Linha 764 exibe `"Todos os serviços saudáveis"` quando `services.isEmpty`, gerando falso positivo.
  - `InventoryScreen` e `OrdersScreen`: Já possuem mensagens e botões de adicionar item.
- **Suíte de Testes (`test/`)**:
  - `flutter test` executou 84 testes com sucesso (100% passing no estado atual).
  - 6 arquivos de teste dependem das listas de `SeedData` e quebrarão se os repositórios em memória iniciarem vazios: `fixtures_test.dart`, `repositories_test.dart`, `dashboard_screen_test.dart`, `companies_screen_test.dart`, `company_detail_screen_test.dart` e `fixes_verification_test.dart` (linha 138).

## 2. Logic Chain

1. A partir das observações em `lib/core/repositories/in_memory_repositories.dart` (linhas 100, 200, 310, 437), os dados fictícios só são injetados porque os construtores usam `?? SeedData.*` como fallback quando a lista opcional é nula.
2. A partir de `lib/core/repositories/firestore_repositories.dart`, o aplicativo já possui uma implementação completa, reativa e limpa de persistência no Cloud Firestore nomeado, que não utiliza nem referencia `seed_data.dart`.
3. Portanto, a remoção do seed consiste em: (a) alterar os construtores de `InMemory*Repository` para terem fallback `?? const []`; (b) esvaziar/remover as listas em `seed_data.dart`; e (c) remover o mock estático de estoque na linha 326 de `inventory_screen.dart`.
4. A partir da inspeção dos Empty States, as telas não quebram (sem null pointer exceptions), porém:
   - A Dashboard exibe falsos "100% saudáveis" sem serviços cadastrados;
   - A Central de Saúde exibe falsos "Todos os serviços saudáveis" sem serviços cadastrados;
   - A tela de Empresas carece de um empty state ilustrado com CTA direcionado para o cadastro do primeiro cliente.
5. A partir da análise dos 17 arquivos de teste, os 6 arquivos afetados dependiam do seed estático herdado da fase de prototipagem visual; para manter a suíte verde e alinhada à base limpa, eles devem prover fixtures locais no `setUp` ou testar cenários a partir de coleções vazias.

## 3. Caveats

- **Ambiente de Produção com Login Humano**: Em tempo de execução real (`AppMode.production`), a aplicação autentica contra o Firebase Auth e grava no Cloud Firestore nomeado. O comportamento depende de haver conectividade e login de usuário humano previamente autorizado em `users/{uid}`.
- **Harness de Captura Visual (`capture_s01` a `s05`)**: Os testes do harness que geram evidências visuais de pranchas usam `InMemory*Repository`. Ao limpar o seed, essas capturas registrarão as telas vazias operacionais, a menos que dados sejam injetados explicitamente no runner visual.

## 4. Conclusion

O desacoplamento de `seed_data.dart` e a operação em base limpa são 100% seguros e realizáveis sem impacto na arquitetura do Firestore. O plano de ação para o Worker está completamente mapeado em `seed_analysis.md`, cobrindo a higienização de repositórios, a eliminação do alerta mockado de adesivos, a elevação dos *empty states* das 5 telas principais e os ajustes necessários nos testes unitários e de widget.

## 5. Verification Method

Para verificar de forma independente as conclusões deste relatório:
1. **Inspecionar imports e referências**:
   - `ripgrep` / `grep_search`: buscar `SeedData` em `lib/` e confirmar que apenas `in_memory_repositories.dart` e `seed_data.dart` o contêm.
2. **Inspecionar o mock hardcoded em inventário**:
   - `view_file` em `lib/features/inventory/presentation/inventory_screen.dart` nas linhas 326–347 e verificar o card estático `"Estoque baixo • Adesivos: 3"`.
3. **Execução de Testes Atual**:
   - `flutter test` no diretório raiz: verificar que a suíte baseline conta com 84 testes passantes.
4. **Relatório Detalhado**:
   - Consultar `c:\Projetos\estudos\flutter\nfcsOps\.agents\teamwork_preview_explorer_survey_seed_1\seed_analysis.md`.
