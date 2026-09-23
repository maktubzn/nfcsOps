# Relatório de Análise Técnica: Desacoplamento de Seed e Arquitetura de Base Limpa

**Data**: 22 de Setembro de 2026  
**Responsável**: Teamwork Explorer (Survey & Seed Architecture)  
**Escopo**: Auditoria de `seed_data.dart`, mapeamento de fixtures mockadas, resiliência de *empty states*, impacto na suíte de testes e plano cirúrgico para transição definitiva para base limpa e real.

---

## 1. Sumário Executivo & Diagnóstico

O usuário solicitou enfaticamente a eliminação de fixtures mockadas estáticas:
> *"não quero mais seed, por que tem arquivo seed? limpa ele, dados tem que ser reais. do banco"*

A investigação identificou que o arquivo `lib/core/fixtures/seed_data.dart` (515 linhas) continha 18 empresas fictícias, 47 serviços com URLs arbitrárias, 5 dispositivos de estoque e 5 pedidos. Essa fixture foi introduzida na fase inicial de fundação visual (`00-FUNDACAO`) para verificar a fidelidade de pixel-a-pixel contra as pranchas do Figma.

Contudo, a aplicação **já possui** toda a camada de repositórios reais integrados ao Cloud Firestore nomeado (`ai-studio-conectordebanco-005a990b-ecd4-41ad-ba1e-0e68b83c29fd`), implementada em `lib/core/repositories/firestore_repositories.dart` e configurada em `lib/main.dart` com `AppMode.production`.

O problema reside no fato de que os repositórios em memória (`InMemory*Repository`) em `lib/core/repositories/in_memory_repositories.dart` injetam `SeedData.*` por padrão caso nenhum dado inicial seja passado, e a existência desse arquivo na árvore de código de produção induz a falsas suposições de dados fictícios. Além disso, foi descoberto **um mock hardcoded visual** dentro da tela de inventário (`inventory_screen.dart`, linhas 327–347) que exibe *"Estoque baixo • Adesivos: 3"* mesmo se a base estiver totalmente limpa.

Este relatório detalha todas as dependências, analisa o comportamento das 5 telas principais com base vazia, mapeia exatamente os testes que quebram com a limpeza e estabelece um plano cirúrgico para a execução pelo Worker.

---

## 2. Mapeamento Completo de Referências em `lib/` e `test/`

### 2.1. Ocorrências no Código da Aplicação (`lib/`)

No diretório de produção `lib/`, o uso de `SeedData` restringe-se a apenas **dois arquivos**:

1. **`lib/core/fixtures/seed_data.dart`**:
   - Definição canônica de 515 linhas: `SeedData.fixedDate`, `demoAdmin`, `unauthorizedUser`, `companies` (18 itens), `services` (47 itens), `devices` (5 itens), `orders` (5 itens).

2. **`lib/core/repositories/in_memory_repositories.dart`**:
   - **Linha 2**: `import '../fixtures/seed_data.dart';`
   - **Linhas 26-27**: `_registeredUsers[SeedData.demoAdmin.uid] = SeedData.demoAdmin;` e `_registeredUsers[SeedData.unauthorizedUser.uid] = SeedData.unauthorizedUser;`
   - **Linha 40**: `final targetUid = uid ?? SeedData.demoAdmin.uid;`
   - **Linhas 99-100**: `clock = clock ?? (() => SeedData.fixedDate);` e `final list = initialCompanies ?? SeedData.companies;`
   - **Linhas 199-200**: `clock = clock ?? (() => SeedData.fixedDate);` e `final list = initialServices ?? SeedData.services;`
   - **Linhas 309-310**: `clock = clock ?? (() => SeedData.fixedDate);` e `final list = initialDevices ?? SeedData.devices;`
   - **Linhas 436-437**: `clock = clock ?? (() => SeedData.fixedDate);` e `final list = initialOrders ?? SeedData.orders;`
   - **Linhas 617, 628, 639, 650, 662, 673**: `checkedAt: SeedData.fixedDate` no `MockHealthCheckService`.

3. **`lib/core/providers/app_providers.dart`**:
   - **Linha 26**: Apenas um comentário informativo (`/// Modo de correspondência visual e testes offline com fixtures SeedData`).

### 2.2. Situação dos Repositórios Firestore Reais (`lib/core/repositories/firestore_repositories.dart`)
- **Independência Total**: Nenhum dos repositórios Firestore (`FirestoreCompanyRepository`, `FirestoreServiceRepository`, `FirestoreDeviceRepository`, `FirestoreOrderRepository`, `FirestoreActivityRepository`, `FirestoreAuthRepository`) importa ou referencia `seed_data.dart`.
- **Comportamento em Base Vazia**:
  - `getCompanies()`: `snap.docs.map(...)` retorna `[]` sem erros caso a coleção esteja vazia.
  - `getAllServices()`, `getDevices()`, `getOrders()`, `getActivities()`: todos retornam listas vazias (`[]`) sem lançar exceções.
  - Streams reativas (`watchCompanies`, `watchAllServices`, `watchDevices`, `watchOrders`, `watchActivities`): emitem listas vazias `[]` de imediato.
  - Escritas e mutações utilizam IDs dinâmicos gerados pelo Firestore (`doc().id`) e timestamps `DateTime.now().toIso8601String()`.

---

## 3. Auditoria de *Empty States* e Riscos de Crash

Foi realizada uma análise rigorosa do código de renderização de cada uma das telas quando coleções retornam `[]` (banco 100% limpo):

### 3.1. Dashboard (`DashboardScreen`) — `lib/features/dashboard/presentation/dashboard_screen.dart`
- **Métricas Superiores (Linhas 72–85)**:
  - `totalServices = 0` ("0 serviços ativos")
  - `totalCompanies = 0` ("0 empresas")
  - `criticalCount = 0`: O card laranja de problema crítico (`_buildCriticalAlertCard`) **não é renderizado** (`if (criticalCount > 0)` na linha 130).
- **Card de Resumo de Saúde (Linhas 561–649)**:
  - `healthyCount = 0`, `warningCount = 0`, `errorCount = 0`, `manualCount = 0`.
  - **Inconsistência Visual**: A fórmula atual:
    ```dart
    final healthRatio = totalServices > 0 ? (healthyCount / totalServices) : 1.0;
    final healthPercent = (healthRatio * 100).round();
    ```
    Quando `totalServices == 0`, exibe **"100%" com anel verde** e "0 saudáveis, 0 atenção, 0 erro, 0 manual". Exibir 100% com base vazia passa a impressão de dados fictícios ou falso positivo. Deve exibir "0%" ou "—" com mensagem neutra.
- **Pendências de Pedidos (Linhas 270–284)**:
  - Já possui tratamento para lista vazia:
    ```dart
    if (orders.isEmpty)
      Container(
        child: Text('Nenhuma pendência operacional no momento.'),
      )
    ```
  - Seguro, sem risco de crash.
- **Botão "Testar serviços" (Linhas 24–63)**:
  - Se `services.isEmpty`, o laço `for (final s in services.take(5))` executa 0 vezes e exibe SnackBar: *"0 serviços verificados com sucesso!"*. Não quebra, mas deve receber uma validação amigável: se não há serviços cadastrados, orientar o usuário a cadastrar a primeira empresa/serviço.
- **Onboarding / CTA Inicial**:
  - Falta um card acolhedor de primeiro acesso incentivando: *"Comece cadastrando sua primeira empresa parceira"* com botão para `/companies/new`.

### 3.2. Empresas (`CompaniesScreen`) — `lib/features/companies/presentation/companies_screen.dart`
- **Header (Linha 104)**: Exibe `"0 cadastradas"`.
- **Lista de Empresas (Linhas 245–254)**:
  ```dart
  child: filteredCompanies.isEmpty
      ? const Center(
          child: Text(
            'Nenhuma empresa encontrada.',
            style: TextStyle(fontFamily: 'Inter', color: Color(0xFF8E8E93)),
          ),
        )
      : ListView.builder(...)
  ```
- **Diagnóstico**:
  - Não há crash nem erro nulo.
  - **Deficiência de UX**: Não diferencia "banco zerado" de "termo de busca não localizado". O texto cinza simples centralizado não atende plenamente ao critério R1 do usuário (*"apresentem estados vazios amigáveis e ações para criar o primeiro item"*).
  - **Recomendação**: Quando `allCompanies.isEmpty`, exibir componente ilustrado/ícone com título *"Nenhuma empresa cadastrada"*, descrição amigável e botão CTA *"Cadastrar primeira empresa"*.

### 3.3. Inventário (`InventoryScreen`) — `lib/features/inventory/presentation/inventory_screen.dart`
- **Métricas Superiores (Linhas 39–43)**: Todos os contadores zeram corretamente (`0 em estoque`, `0 reservados`, `0 em produção`, etc.).
- **Lista de Dispositivos (Linhas 351–373)**:
  - Já possui distinção entre lista vazia e filtro:
    ```dart
    allDevices.isEmpty
        ? 'Nenhum dispositivo cadastrado no inventário.\nToque no botão abaixo para adicionar.'
        : 'Nenhum dispositivo encontrado para o filtro selecionado.'
    ```
  - Botões inferiores de `+ Novo dispositivo` e `Escanear Placa NFC` presentes e funcionais.
- **DEFEITO CRÍTICO ENCONTRADO (MOCK VAZADO NA UI)**:
  - **Linhas 326–347**:
    ```dart
    // Alerta Laranja: "Estoque baixo • Adesivos: 3"
    Container(
      child: Text('Estoque baixo • Adesivos: 3'),
    )
    ```
  - Este card está **hardcoded** estaticamente na tela! Mesmo que a base tenha 0 dispositivos, a tela exibe o alerta mockado de 3 adesivos.
  - **Ação Obrigatória**: Tornar condicional ao cálculo real de itens em estoque (`if (stickersCount > 0 && stickersCount <= 5)`), ou ocultar caso o estoque esteja zerado.

### 3.4. Pedidos (`OrdersScreen`) — `lib/features/orders/presentation/orders_screen.dart`
- **Filtros e Contagem (Linhas 81–86)**: Exibe `"0 pedidos"`.
- **Lista de Pedidos (Linhas 111–132)**:
  - Apresenta card com texto informativo:
    ```dart
    'Nenhum pedido encontrado para o filtro selecionado.\nToque no botão abaixo para criar um novo pedido.'
    ```
  - Botão fixo inferior `+ Novo pedido` funcional.
  - Seguro contra null pointer e crashes.

### 3.5. Central de Saúde (`HealthCenterScreen`) — `lib/features/health/presentation/health_center_screen.dart`
- **Card Visão Geral (Linhas 479–562)**: Exibe `0 serviços`, `100% saudáveis`.
- **Lista e Filtros (Linhas 740–778)**:
  - Quando `services.isEmpty`, o escopo padrão `'problemas'` cai no bloco `filteredServices.isEmpty` e exibe:
    ```dart
    _filterScope == 'problemas'
        ? 'Todos os serviços saudáveis'
        : 'Nenhum serviço com esses filtros'
    ```
    com o ícone verde `Icons.check_circle` e *"Nenhum erro ou advertência de link detectado no momento."*.
  - **Diagnóstico**: Afirmar que "todos os serviços estão saudáveis" quando a base não tem nenhum serviço é incorreto. Deve exibir: *"Nenhum serviço cadastrado"* e orientar o cadastro de empresas/serviços.

### 3.6. Telas de Detalhes (`CompanyDetailScreen`, `DeviceDetailScreen`, `OrderDetailScreen`)
- **`CompanyDetailScreen`**:
  - `company == null`: Exibe tela de fallback *"Empresa não localizada no banco de dados"* com botão de voltar (linha 192).
  - Aba Serviços vazia: Exibe container *"Nenhum serviço cadastrado para esta empresa. Toque em '+ Adicionar serviço' abaixo."* (linha 670).
  - Aba Pedidos vazia: Já possui um empty state excelente com ícone de sacola, texto explicativo e botão *"Criar primeiro pedido"* (linhas 1102–1147).
  - Aba Dispositivos vazia: Exibe *"Nenhum dispositivo associado a esta empresa."* (linha 1018).
  - Aba Histórico vazia: Trata lista sem registros (linha 1248).
- **`DeviceDetailScreen` e `OrderDetailScreen`**:
  - Ambas possuem proteção para ID não encontrado ou lista vazia sem lançar NullPointerException.

---

## 4. Diagnóstico Detalhado da Suíte de Testes (`test/`)

Atualmente, todos os 84 testes passam (`All tests passed!`). Porém, diversos testes dependiam implicitamente das 18 empresas e 47 serviços do seed padrão nos repositórios em memória.

Abaixo está o mapeamento exato de cada um dos 17 arquivos de teste:

| # | Arquivo de Teste | Dependência de Seed | Impacto com Base Limpa | Estratégia de Ajuste |
|---|---|---|---|---|
| 1 | `test/theme_test.dart` | Nenhuma | **PASS** | Nenhuma alteração necessária. |
| 2 | `test/models_test.dart` | Nenhuma | **PASS** | Nenhuma alteração necessária. |
| 3 | `test/nfc_service_test.dart` | Cria seus próprios dispositivos no teste | **PASS** | Nenhuma alteração necessária. |
| 4 | `test/create_company_screen_test.dart` | Usa `SeedData.demoAdmin` para login; calcula deltas de criação dinamicamente | **PASS** | Substituir import por usuário de teste local `testAdmin`. |
| 5 | `test/login_screen_test.dart` | Usa `SeedData.unauthorizedUser` para teste de banner de erro | **PASS** | Substituir por perfil local `testUnauthorizedUser`. |
| 6 | `test/router_test.dart` | Usa `SeedData.demoAdmin` e `SeedData.unauthorizedUser` | **PASS** | Usar instâncias locais de `UserProfile` no teste. |
| 7 | `test/fixtures_test.dart` | **Crítico**: Asserta estritamente `SeedData.companies.length == 18` e `SeedData.services.length == 47` | **FALHA** | Como o usuário determinou a eliminação do seed mockado, este teste canônico deve ser convertido para validar as regras de invariância da base limpa (repositórios iniciam vazios por padrão) ou aposentado. |
| 8 | `test/repositories_test.dart` | **Crítico**: Asserta `all.length == 18`, `active.length == 14`, busca por 'Bella Massa', 'srv-01', 'dev-003', 'ord-1043' | **FALHA** (7 asserções) | Atualizar para criar fixtures pontuais dentro do próprio teste ou testar fluxo real de CRUD a partir do zero. Para o teste RB-007 (checklist de pedidos), instanciar dispositivo e pedido locais no próprio teste. |
| 9 | `test/dashboard_screen_test.dart` | **Crítico**: Asserta `47` serviços, `18` empresas, `43` saudáveis, `91%`, `Pedido #028`, `Pedido #027` | **FALHA** | Ajustar o teste para validar o comportamento da Dashboard em **base limpa** (`0 empresas`, `0 serviços`, empty state de pendências) e criar um teste secundário que valida a renderização quando itens são adicionados. |
| 10 | `test/companies_screen_test.dart` | **Crítico**: Asserta 'Auto Center Silva', 'Café Aurora', 'Pet Vila', filtros por 'Oficina' e 'Osasco' | **FALHA** (8 asserções) | Inserir 2 a 3 empresas no `setUp` do teste via `compRepo.createCompany()` para validar busca e filtros de categoria/cidade, e adicionar teste específico para validar a tela com 0 empresas (Empty State). |
| 11 | `test/company_detail_screen_test.dart` | **Crítico**: Abre `emp-01` e asserta 'Auto Center Silva' com 4 serviços | **FALHA** | No `setUp` do teste, criar a empresa `emp-01` e seus serviços de teste no `compRepo` e `srvRepo`. |
| 12 | `test/fixes_verification_test.dart` | Na linha 138 pesquisa por `'LOT-2026-09A'` esperando encontrar dispositivo do seed | **FALHA** (Linha 138) | Na linha 125 do teste de inventário, criar um dispositivo com lote `'LOT-2026-09A'` via `devRepo.createDevice()` antes de digitar no campo de busca. |
| 13-17 | `test/capture_s01_test.dart` a `capture_s05_test.dart` | Testes de captura visual do harness | **PARCIAL** (capturarão as telas vazias se não receberem dados) | Injetar dados de demonstração locais apenas dentro das fixtures de teste do harness se necessária correspondência pixelada, ou permitir captura de telas operacionais limpas. |

---

## 5. Plano Cirúrgico Passo a Passo para o Worker

O Worker deverá executar as seguintes etapas cirúrgicas, garantindo estabilidade e zero regressões:

### Etapa 1: Desacoplar Repositórios InMemory e Higienizar `seed_data.dart`
1. Em `lib/core/repositories/in_memory_repositories.dart`:
   - Alterar os valores padrão dos construtores de:
     - `final list = initialCompanies ?? SeedData.companies;` $\rightarrow$ `final list = initialCompanies ?? const [];`
     - `final list = initialServices ?? SeedData.services;` $\rightarrow$ `final list = initialServices ?? const [];`
     - `final list = initialDevices ?? SeedData.devices;` $\rightarrow$ `final list = initialDevices ?? const [];`
     - `final list = initialOrders ?? SeedData.orders;` $\rightarrow$ `final list = initialOrders ?? const [];`
     - `clock = clock ?? (() => SeedData.fixedDate);` $\rightarrow$ `clock = clock ?? DateTime.now;`
   - Em `InMemoryAuthRepository`:
     - Não registrar automaticamente `SeedData.demoAdmin` como único usuário; inicializar `_registeredUsers` vazio ou aceitar `List<UserProfile>? initialUsers`.
     - Substituir fallback de `SeedData.demoAdmin.uid` por geração de perfil ou usuário inicial configurável.
   - Em `MockHealthCheckService`:
     - Substituir referências a `SeedData.fixedDate` por `DateTime.now()`.
   - Remover `import '../fixtures/seed_data.dart';` de `in_memory_repositories.dart`.
2. Em `lib/core/fixtures/seed_data.dart`:
   - Limpar todas as listas estáticas para listas vazias imutáveis:
     ```dart
     abstract class SeedData {
       static const List<Company> companies = [];
       static const List<ServiceItem> services = [];
       static const List<DeviceItem> devices = [];
       static const List<OrderItem> orders = [];
     }
     ```
   - (Ou desacoplar integralmente a classe caso os testes utilizem fixtures locais).

### Etapa 2: Eliminar Mock Hardcoded na Tela de Estoque
1. Em `lib/features/inventory/presentation/inventory_screen.dart` (linhas 326–347):
   - Remover o banner estático `"Estoque baixo • Adesivos: 3"` ou transformá-lo em cálculo dinâmico baseado em `allDevices`:
     ```dart
     final lowStockDevices = allDevices.where((d) => d.status == DeviceStatus.disponivel).length;
     if (allDevices.isNotEmpty && lowStockDevices <= 3) {
       // Renderiza alerta de reposição com contagem real
     }
     ```
   - Se `allDevices.isEmpty`, esse alerta não deve ser renderizado.

### Etapa 3: Refinar *Empty States* das 5 Telas Principais
1. **Dashboard (`DashboardScreen`)**:
   - Ajustar cálculo do percentual de saúde: se `totalServices == 0`, exibir `0%` ou estado neutro `"Nenhum serviço monitorado"`, evitando o falso `"100% saudáveis"`.
   - No botão "Testar serviços", adicionar verificação: se `services.isEmpty`, exibir SnackBar orientando o cadastro de serviços.
   - Adicionar card de onboarding inicial caso `totalCompanies == 0`.
2. **Empresas (`CompaniesScreen`)**:
   - Criar widget de Empty State amigável quando `allCompanies.isEmpty`:
     - Ícone de prédio/empresa com círculo escuro de fundo;
     - Título: *"Nenhuma empresa cadastrada"*;
     - Descrição: *"Cadastre sua primeira empresa para vincular placas NFC e gerenciar serviços."*;
     - Botão CTA central: *"+ Cadastrar Empresa"*.
   - Manter a mensagem *"Nenhuma empresa encontrada para o filtro"* apenas quando `allCompanies.isNotEmpty` mas a busca não retornar itens.
3. **Inventário (`InventoryScreen`)**:
   - Reforçar o visual do empty state quando `allDevices.isEmpty` com ícone de caixa/tag NFC e CTA claro para adicionar dispositivo.
4. **Pedidos (`OrdersScreen`)**:
   - Enriquecer o container de pedidos vazios quando `allOrders.isEmpty` com ícone `LucideIcons.shoppingBag` e botão direto para criar pedido.
5. **Central de Saúde (`HealthCenterScreen`)**:
   - Quando `services.isEmpty`, substituir a mensagem enganosa *"Todos os serviços saudáveis"* por *"Nenhum serviço cadastrado"* com botão de redirecionamento para a lista de empresas.

### Etapa 4: Atualização da Suíte de Testes (`test/`)
1. **`test/fixtures_test.dart`**:
   - Atualizar para validar que `SeedData` e repositórios operam com coleções limpas por padrão.
2. **`test/repositories_test.dart`**:
   - Adicionar método `_populateSampleData()` ou fixtures locais no `setUp()` para os testes que validam filtros complexos, busca por nome ('Bella Massa') e transição de status com checklist de 8 itens (RB-007).
   - Adicionar teste específico garantindo que os repositórios iniciam com 0 registros por padrão.
3. **`test/dashboard_screen_test.dart`**:
   - Atualizar teste principal para verificar a Dashboard em estado de base limpa (`0 empresas`, `0 serviços`, pendências vazias).
   - Adicionar teste secundário com serviços inseridos para validar cálculo de métricas.
4. **`test/companies_screen_test.dart`**:
   - No `setUp()`, registrar 3 empresas de teste (`Auto Center Silva`, `Café Aurora`, `Pet Vila`) no `compRepo` para validar filtros de busca, categoria e cidade.
   - Adicionar teste dedicado ao Empty State da tela de empresas.
5. **`test/company_detail_screen_test.dart`**:
   - No `setUp()`, criar a empresa de teste `emp-01` e 4 serviços no `compRepo` e `srvRepo`.
6. **`test/fixes_verification_test.dart`**:
   - Na linha 125, criar um `DeviceItem` com lote `'LOT-2026-09A'` antes de filtrar por texto no inventário.

### Etapa 5: Validação Final de Integridade
1. Executar `dart analyze lib test` garantindo zero erros e advertências.
2. Executar `flutter test` garantindo que todos os testes passem com 100% de sucesso.
3. Iniciar o app e verificar a experiência limpa de ponta a ponta.

---

## 6. Conclusão Técnica

O desacoplamento de `seed_data.dart` é altamente viável e seguro: a persistência real do Cloud Firestore já está pronta e ativa em `Firestore*Repository`. As mudanças necessárias concentram-se em desacoplar os valores padrão dos construtores em memória, eliminar o alerta fixo de adesivos vazado no inventário, aperfeiçoar os *empty states* visuais para acolher o usuário em base limpa, e adequar os testes automatizados para prover suas próprias fixtures locais.
