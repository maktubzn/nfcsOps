# Relatório de Auditoria Funcional, Navegação, Validações e Fluxos NFC

**Data**: 2026-09-22  
**Projeto**: NFC Ops (Flutter / Dart)  
**Escopo**: Lógica de Negócios, Rotas & Navegação, Validações de Formulários, Integridade de Dados, Operações NFC e Ciclo de Vida Assíncrono (`lib/`)  
**Auditor**: Explorer Funcional (`teamwork_preview_explorer_survey_func_1`)  
**Modo de Inspeção**: Estritamente Leitura (Read-Only)

---

## 1. Sumário Executivo

A inspeção detalhada da camada de negócios, persistência e interfaces do projeto NFC Ops identificou **20 vulnerabilidades funcionais**, categorizadas em:
- **5 Críticas**: Falhas graves que causam corrupção e orfandade de dados, bloqueios insolúveis de fluxo operacional (pedidos travados permanentemente), violações das regras do projeto (simulação enganosa de gravação física de chip NFC) e crashes com exceções assíncronas não tratadas.
- **9 Médias**: Falhas de validação de formulários (campos obrigatórios vazios aceitos), truncamento silencioso de testes de links (falso relatório de cobertura), vazamentos de conexões HTTP e sockets do SO, falhas de retorno em navegação deep link web, quebras na barra de navegação inferior e orfandade em exclusões.
- **6 Baixas**: Problemas cosméticos de concatenação (`Pedido ##1042`), enums sem internacionalização, usuário mockado estático (`usr-001`) sobrepondo o usuário autenticado real e botões com simulações de download na web.

Abaixo está o catálogo completo de todos os defeitos encontrados.

---

## 2. Catálogo Estruturado de Bugs e Casos de Borda

---

### BUG-01: `DeviceItem.copyWith` Impede Anulação de Vínculos (Falha Crítica de Integridade)
- **Fluxo / Funcionalidade Afetada**: Desvinculação de dispositivos na exclusão de empresas e substituição de dispositivos defeituosos no estoque.
- **Arquivo e Linha(s)**: `lib/core/models/device_item.dart:120-132`
- **Severidade**: **Crítico**
- **Passos para Reprodução**:
  1. Cadastre um dispositivo vinculado a uma empresa (`assignedCompanyId = 'comp-101'`).
  2. Acesse a edição da empresa e clique em "Excluir empresa".
  3. O código executa `dev.copyWith(assignedCompanyId: null, primaryServiceId: null, status: DeviceStatus.disponivel)`.
  4. Salve e recarregue o dispositivo do banco de dados.
  5. Observe que `assignedCompanyId` CONTINUA sendo `'comp-101'`.
- **Causa Raiz no Código**:
  ```dart
  DeviceItem copyWith({
    ...
    String? primaryServiceId,
    String? assignedCompanyId,
    ...
  }) {
    return DeviceItem(
      ...
      primaryServiceId: primaryServiceId ?? this.primaryServiceId,
      assignedCompanyId: assignedCompanyId ?? this.assignedCompanyId,
      ...
    );
  }
  ```
  Ao passar `null`, a expressão `assignedCompanyId ?? this.assignedCompanyId` avalia para `this.assignedCompanyId`. É impossível desvincular um dispositivo usando `copyWith`.
- **Recomendação de Correção**:
  Implementar sentinela explícita para campos anuláveis ou parâmetros nomeados booleanos como `bool clearAssignedCompany = false`, ou adotar o padrão `ValueGetter<String?>? assignedCompanyId`.

---

### BUG-02: Orfandade em Exclusão de Dispositivo Trava Pedidos Permanentemente (RB-007)
- **Fluxo / Funcionalidade Afetada**: Exclusão de dispositivos vinculados a pedidos comerciais e avanço de status para "Pronto".
- **Arquivo e Linha(s)**: `lib/core/repositories/in_memory_repositories.dart:510-514`, `lib/core/repositories/firestore_repositories.dart:601-604`, `lib/features/inventory/presentation/device_detail_screen.dart:94`
- **Severidade**: **Crítico**
- **Passos para Reprodução**:
  1. Crie um pedido que possua um dispositivo na lista `assignedDeviceIds: ['dev-001']`.
  2. Acesse a tela de detalhes do dispositivo `dev-001` e execute a exclusão permanente do estoque.
  3. Retorne ao pedido e tente avançar seu status para `pronto`.
  4. O sistema dispara a exceção `StateError: Violação RB-007: Dispositivo vinculado dev-001 não encontrado.`.
- **Causa Raiz no Código**:
  A exclusão do dispositivo em `FirestoreDeviceRepository.deleteDevice` e `InMemoryDeviceRepository.deleteDevice` remove o documento sem verificar se há pedidos vinculados e sem limpar o `assignedDeviceIds` dos pedidos afetados. Ao tentar mover o pedido para `pronto`, a validação RB-007 falha com `StateError` não recuperável.
- **Recomendação de Correção**:
  Em `deleteDevice`, verificar se o dispositivo está em `assignedDeviceIds` de algum pedido. Se estiver, bloquear a exclusão com mensagem de erro clara ao operador, ou atualizar os pedidos removendo o ID órfão.

---

### BUG-03: Pedidos Criados no App Ficam Permanentemente Travados em Orçamento (RB-007)
- **Fluxo / Funcionalidade Afetada**: Fluxo completo de pedidos (`CreateOrderScreen` -> `OrderDetailScreen`).
- **Arquivo e Linha(s)**: `lib/features/orders/presentation/create_order_screen.dart:208`, `lib/core/repositories/in_memory_repositories.dart:505-508`
- **Severidade**: **Crítico**
- **Passos para Reprodução**:
  1. Crie um novo pedido pela interface `CreateOrderScreen`.
  2. O pedido é salvo com `assignedDeviceIds: const []`.
  3. Abra o pedido em `OrderDetailScreen` e tente avançar seu status operacional até `OrderStatus.pronto`.
  4. O repositório lança `StateError: Violação RB-007: Pedido ord-xxx não possui dispositivos físicos vinculados para validação de checklist.`.
- **Causa Raiz no Código**:
  O aplicativo não oferece em nenhuma tela (nem na criação nem no detalhe) a funcionalidade para o operador selecionar ou vincular dispositivos do estoque ao pedido. Ao mesmo tempo, a regra de negócio RB-007 exige que pedidos em `pronto` possuam dispositivos com checklist aprovado.
- **Recomendação de Correção**:
  Incluir seleção de dispositivos de estoque em `CreateOrderScreen` ou modal de alocação de dispositivos em `OrderDetailScreen`, permitindo associar itens do estoque ao pedido antes do envio para teste e liberação.

---

### BUG-04: Gravação Falsa Silenciosa de Chip NFC sem Hardware Ativo (Violação de Produção)
- **Fluxo / Funcionalidade Afetada**: Gravação e teste de chip NFC em `DeviceDetailScreen`.
- **Arquivo e Linha(s)**: `lib/features/inventory/presentation/device_detail_screen.dart:730-735`
- **Severidade**: **Crítico**
- **Passos para Reprodução**:
  1. Desative o NFC nas configurações do Android ou execute em dispositivo/emulador sem suporte.
  2. Acesse os detalhes de um dispositivo e toque em "Aproximar e Gravar".
  3. O código detecta `!available`, aguarda 600ms e chama `await onRecorded()`.
  4. O sistema marca os itens do checklist `nfcChipWriting: true`, `nfcReadingTest: true`, `urlMatchConfirmation: true` e exibe: *"Chip NFC gravado com sucesso com a URL da empresa!"*.
- **Causa Raiz no Código**:
  ```dart
  final available = await NfcService.instance.isAvailable();
  if (!available) {
    // Modo simulação para emulador/testes sem hardware
    await Future.delayed(const Duration(milliseconds: 600));
    await onRecorded();
    return;
  }
  ```
  O código engana o operador, simulando em runtime de produção que um chip físico foi gravado e validado, quando na verdade nada foi gravado. Violação expressa de `AGENTS.md` ("dado de produção simulado").
- **Recomendação de Correção**:
  Exibir alerta claro informando que o NFC está desativado ou indisponível, instruindo o operador a ligar o NFC nas configurações do dispositivo. Nunca simular gravação física com sucesso em modo de produção.

---

### BUG-05: Exceções Assíncronas Não Tratadas na Alteração de Pedidos e Pagamentos
- **Fluxo / Funcionalidade Afetada**: Alteração manual de status e recebimento de pagamentos em `OrderDetailScreen`.
- **Arquivo e Linha(s)**: `lib/features/orders/presentation/order_detail_screen.dart:210, 534`
- **Severidade**: **Crítico**
- **Passos para Reprodução**:
  1. Abra um pedido em `OrderDetailScreen`.
  2. Toque no status para abrir o modal de seleção de status.
  3. Selecione um novo status ou clique no botão "Receber" pagamento em condições de erro (falha de rede ou violação de RB-007).
  4. O app lança exceção assíncrona não capturada (`Uncaught Exception`), podendo fechar a tela ou exibir erro cinza do Flutter.
- **Causa Raiz no Código**:
  ```dart
  // Linha 210
  await ref.read(orderRepositoryProvider).updateOrderStatus(order.id, st);
  
  // Linha 534
  await repo.updatePaymentStatus(order.id, PaymentStatus.aprovado);
  ```
  Ambas as chamadas ocorrem sem bloco `try / catch`.
- **Recomendação de Correção**:
  Envolver as invocações em blocos `try / catch`, capturando o erro e exibindo uma `SnackBar` de erro com a mensagem amigável para o operador.

---

### BUG-06: Ausência Total de Validadores em `EditCompanyScreen`
- **Fluxo / Funcionalidade Afetada**: Edição de empresas (`EditCompanyScreen`).
- **Arquivo e Linha(s)**: `lib/features/companies/presentation/edit_company_screen.dart:135, 365, 580-607`
- **Severidade**: **Médio**
- **Passos para Reprodução**:
  1. Abra uma empresa e clique em "Editar empresa".
  2. Apague completamente o texto do campo "Nome da empresa *".
  3. Clique em "Salvar alterações".
  4. A tela salva a empresa com `tradeName = ""` e fecha normalmente.
- **Causa Raiz no Código**:
  O método `_buildInput` não possui parâmetro `validator`. Mesmo havendo um `_formKey.currentState!.validate()`, nenhum campo do formulário tem regra de validação associada.
- **Recomendação de Correção**:
  Adicionar parâmetro `String? Function(String?)? validator` ao método `_buildInput` e validar obrigatoriedade do nome, formato de e-mail e telefone.

---

### BUG-07: Falta de Validação de Nome e Formato Rigoroso de URL nos Serviços
- **Fluxo / Funcionalidade Afetada**: Cadastro e Edição de Serviços (`CreateServiceScreen` e `EditServiceScreen`).
- **Arquivo e Linha(s)**: `lib/features/services/presentation/create_service_screen.dart:175-189`, `lib/features/services/presentation/edit_service_screen.dart:270-283`
- **Severidade**: **Médio**
- **Passos para Reprodução**:
  1. Abra o formulário de novo serviço ou edição.
  2. Deixe o campo "Nome interno" em branco.
  3. No campo "Destino *", digite `https://` ou `http:// invalid domain`.
  4. Clique em "Salvar e testar".
  5. O serviço é salvo com título em branco e URL sintaticamente inválida.
- **Causa Raiz no Código**:
  `_nameCtrl` / `_titleCtrl` não possui validador. A validação de URL limita-se a checar prefixos (`startsWith('http://') || startsWith('https://')`) sem usar `Uri.tryParse` ou checar `uri.hasAuthority` e `uri.host`.
- **Recomendação de Correção**:
  Tornar o nome interno obrigatório e validar a URL com expressão regular e `Uri.tryParse(v)?.hasAuthority == true`.

---

### BUG-08: Truncamento Silencioso de Testes de Serviços (Falsa Cobertura de Saúde)
- **Fluxo / Funcionalidade Afetada**: Varredura de links no Dashboard e Central de Saúde.
- **Arquivo e Linha(s)**: `lib/features/dashboard/presentation/dashboard_screen.dart:32`, `lib/features/health/presentation/health_center_screen.dart:59`
- **Severidade**: **Médio**
- **Passos para Reprodução**:
  1. Cadastre 20 serviços de empresas no sistema.
  2. Na Central de Saúde, toque no botão "Testar todos".
  3. O app testa apenas os 10 primeiros (`services.take(10)`).
  4. O app exibe a mensagem: *"Varredura completa de saúde concluída!"*.
- **Causa Raiz no Código**:
  Tanto no Dashboard (`take(5)`) quanto na Central de Saúde (`take(10)`), foi fixado um limitador rígido sem paginação ou aviso de que a varredura foi parcial.
- **Recomendação de Correção**:
  Iterar sobre todos os serviços ou informar explicitamente ao usuário a quantidade de serviços avaliados versus o total existente.

---

### BUG-09: Vazamento de Conexões e Sockets HTTP em `RealHealthCheckService`
- **Fluxo / Funcionalidade Afetada**: Rotina de verificação de URLs de destino (`HealthCheckService`).
- **Arquivo e Linha(s)**: `lib/core/services/real_health_check_service.dart:67-76`
- **Severidade**: **Médio**
- **Passos para Reprodução**:
  1. Dispare a verificação em lote de 50 serviços na Central de Saúde.
  2. Para cada URL testada, `HttpClient()` é instanciado.
  3. O socket da requisição é fechado, mas o cliente `client.close()` nunca é invocado.
- **Causa Raiz no Código**:
  Falta de chamada a `client.close(force: true)` em bloco `finally`. Cada chamada aloca novos recursos de rede não liberados adequadamente.
- **Recomendação de Correção**:
  Reutilizar um cliente HTTP singleton gerenciado ou garantir `client.close(force: true)` no `finally` de `checkUrl`.

---

### BUG-10: Botão de Escanear Placa no Dashboard Abandonado com Toast (Rota Incompleta)
- **Fluxo / Funcionalidade Afetada**: Ação rápida de escanear tag NFC no Dashboard (`DashboardScreen`).
- **Arquivo e Linha(s)**: `lib/features/dashboard/presentation/dashboard_screen.dart:177`, `lib/features/inventory/presentation/widgets/nfc_scan_modal.dart:170-180`
- **Severidade**: **Médio**
- **Passos para Reprodução**:
  1. No Dashboard, clique no card "Escanear Placa NFC".
  2. Aproxime uma tag NFC nova (não cadastrada no banco).
  3. O modal informa "Iniciando cadastro...", fecha e exibe uma `SnackBar` dizendo que a tag foi identificada.
  4. O usuário permanece no Dashboard sem ser redirecionado para a tela de cadastro.
- **Causa Raiz no Código**:
  Em `dashboard_screen.dart:177`, `NfcScanModal.show(context, companies: companies)` é chamado sem passar o callback `onNewTagDetected`. O modal faz fallback para um toast e não navega. Viola regra de `AGENTS.md` ("toast substituindo uma ação").
- **Recomendação de Correção**:
  Passar `onNewTagDetected: (uid, url) => context.push('/inventory/new?nfcUid=$uid')` ou abrir o modal de criação pré-preenchido.

---

### BUG-11: Crash de Navegação `context.pop()` em Acessos Diretos Web / Deep Links
- **Fluxo / Funcionalidade Afetada**: Botões de voltar no topo das telas de detalhe e edição.
- **Arquivo e Linha(s)**: `lib/features/companies/presentation/company_detail_screen.dart:198`, `lib/features/companies/presentation/edit_company_screen.dart:306`, `lib/features/services/presentation/service_detail_screen.dart:87`, `lib/features/orders/presentation/order_detail_screen.dart:325`
- **Severidade**: **Médio**
- **Passos para Reprodução**:
  1. Abra o app via Web diretamente em uma URL de detalhe (ex: `http://localhost:port/#/companies/comp-001`).
  2. Clique na seta voltar (`IconButton` com `context.pop()`).
  3. O GoRouter lança `GoError: There is nothing to pop`.
- **Causa Raiz no Código**:
  O Flutter GoRouter requer verificação `if (context.canPop()) context.pop(); else context.go('/sua-rota-pai');`. Chamar `pop()` com histórico vazio lança exceção em tempo de execução.
- **Recomendação de Correção**:
  Substituir todas as chamadas diretas a `context.pop()` por verificação de `canPop()` com fallback para a rota pai (ex: `context.canPop() ? context.pop() : context.go('/companies')`).

---

### BUG-12: Barra de Navegação Inferior Destaca Aba Incorreta em Pedidos, Saúde e Atividades
- **Fluxo / Funcionalidade Afetada**: Navegação persistente na `NfcBottomNavBar`.
- **Arquivo e Linha(s)**: `lib/core/router/app_router.dart:257-263`
- **Severidade**: **Médio**
- **Passos para Reprodução**:
  1. Navegue para `/orders` ou `/health` ou `/activities`.
  2. Observe a barra inferior de navegação (`NfcBottomNavBar`).
  3. O ícone ativo selecionado é o primeiro ("Início" / Dashboard), apesar de a tela atual ser Pedidos ou Central de Saúde.
- **Causa Raiz no Código**:
  ```dart
  int _calculateSelectedIndex(String location) {
    if (location.startsWith('/dashboard')) return 0;
    if (location.startsWith('/companies')) return 1;
    if (location.startsWith('/inventory')) return 3;
    if (location.startsWith('/more')) return 4;
    return 0; // Fallback para 0 para qualquer outra rota da ShellRoute!
  }
  ```
- **Recomendação de Correção**:
  Mapear rotas secundárias para a aba correspondente (ex: rotas de gestão para o índice 4 "Mais", ou manter o estado prévio sem forçar seleção de Dashboard).

---

### BUG-13: Bypass de Proteção SSRF em Protocolos HTTPS para Redes Locais
- **Fluxo / Funcionalidade Afetada**: Sanitização de segurança de URLs em `RealHealthCheckService`.
- **Arquivo e Linha(s)**: `lib/core/services/real_health_check_service.dart:25-28`
- **Severidade**: **Médio**
- **Passos para Reprodução**:
  1. Cadastre um serviço com destino `https://localhost:8443` ou `https://192.168.0.1`.
  2. Dispare a checagem de saúde do serviço.
  3. A verificação passa pelo filtro SSRF e tenta conectar ao host privado.
- **Causa Raiz no Código**:
  O filtro verifica apenas prefixos `http://localhost`, `http://127.0.0.1`, `http://192.168.`, `http://10.`. O protocolo `https://` e as faixas `172.16.0.0/12` foram ignorados.
- **Recomendação de Correção**:
  Fazer parse do host via `Uri.parse(trimmedUrl).host` e validar se é loopback ou IP privado independente do esquema (`http` ou `https`).

---

### BUG-14: Botões de Exportação de QR Code Inoperantes na Web (Download Fake)
- **Fluxo / Funcionalidade Afetada**: Exportação de QR Code em PNG e SVG (`QrCodeScreen`).
- **Arquivo e Linha(s)**: `lib/features/qr/presentation/qr_code_screen.dart:42-52, 97-105`
- **Severidade**: **Baixo**
- **Passos para Reprodução**:
  1. Abra a tela de QR Code na versão Web do app.
  2. Clique no botão "Baixar PNG" ou "Baixar SVG".
  3. O app exibe o toast: *"QR Code pronto para uso!"*, mas nenhum download é disparado no navegador.
- **Causa Raiz no Código**:
  O bloco `if (kIsWeb)` simplesmente exibe a `SnackBar` e retorna prematuramente, sem usar APIs de download web (`dart:html` / `package:web`).
- **Recomendação de Correção**:
  Implementar o download real via `AnchorElement` / `web.HTMLAnchorElement` ou `url_launcher` para disponibilizar o arquivo para download no navegador.

---

### BUG-15: Duplicação de Prefixo `#` nos Pedidos e Enums de Status Não Formatados
- **Fluxo / Funcionalidade Afetada**: Listagem e confirmação de exclusão de pedidos (`OrdersScreen` e `OrderDetailScreen`).
- **Arquivo e Linha(s)**: `lib/features/orders/presentation/order_detail_screen.dart:253, 281`, `lib/features/orders/presentation/orders_screen.dart:181`
- **Severidade**: **Baixo**
- **Passos para Reprodução**:
  1. Abra a lista de pedidos e visualize um pedido com status de orçamento. O subtítulo exibe `R$ 250,00 • orcamento` (nome bruto do enum).
  2. Abra os detalhes e clique em "Excluir Pedido".
  3. O diálogo de confirmação exibe: *"Deseja realmente excluir o Pedido ##1042?"*.
- **Causa Raiz no Código**:
  `order.orderNumber` já armazena a hashtag (`#1042`). O código interpola `'Pedido #${order.orderNumber}'`, resultando em `##`. Em `orders_screen.dart:181`, o código usa `order.status.name` em vez de `_formatStatusName(order.status)`.
- **Recomendação de Correção**:
  Remover a hashtag duplicada da interpolação e formatar os nomes dos status com texto legível em português.

---

### BUG-16: Atribuição de Auditoria a Usuário Fictício Estático (`usr-001`)
- **Fluxo / Funcionalidade Afetada**: Registro de logs na coleção `activities`.
- **Arquivo e Linha(s)**: `lib/features/health/presentation/health_center_screen.dart:126`, `lib/features/companies/presentation/edit_company_screen.dart:257`, `lib/features/inventory/presentation/device_detail_screen.dart:99`, `lib/features/orders/presentation/create_order_screen.dart:218`
- **Severidade**: **Baixo**
- **Passos para Reprodução**:
  1. Faça login com uma conta Google real autorizada (ex: `gustavo@...`).
  2. Crie um pedido, exclua uma empresa ou resolva uma pendência na Central de Saúde.
  3. Abra a tela de Atividades recentes (`/activities`).
  4. O log registra que a ação foi efetuada por `usr-001` / `Operador NFC Ops`.
- **Causa Raiz no Código**:
  O identificador do usuário autenticado foi fixado com string literal em vez de ler `ref.read(currentUserProvider)`.
- **Recomendação de Correção**:
  Injetar `final user = ref.read(currentUserProvider)` e registrar `actorUid: user?.uid ?? 'anonimo'` e `actorName: user?.displayName ?? 'Operador'`.

---

### BUG-17: Strings e Alertas Estáticos Fictícios de Auditoria e Estoque
- **Fluxo / Funcionalidade Afetada**: Checklist Físico e Tela de Estoque.
- **Arquivo e Linha(s)**: `lib/features/inventory/presentation/physical_checklist_screen.dart:312`, `lib/features/inventory/presentation/inventory_screen.dart:339`
- **Severidade**: **Baixo**
- **Passos para Reprodução**:
  1. Abra o checklist físico de qualquer dispositivo.
  2. No rodapé, o texto estático exibe sempre: `'Por Gustavo • Hoje 14:10'`.
  3. Abra a tela de Estoque com a base vazia (0 itens).
  4. O banner laranja continua exibindo: `'Estoque baixo • Adesivos: 3'`.
- **Causa Raiz no Código**:
  Textos mockados fixados no código Flutter sem ligação com o banco de dados.
- **Recomendação de Correção**:
  Substituir por dados dinâmicos: nome do operador autenticado e contagem real de itens com status disponível abaixo do threshold configurado.

---

### BUG-18: Configurações do Sistema Não Persistidas (Perda ao Recarregar)
- **Fluxo / Funcionalidade Afetada**: Tela de Configurações (`SettingsScreen`).
- **Arquivo e Linha(s)**: `lib/features/settings/presentation/settings_screen.dart:18-20, 212, 241, 271`
- **Severidade**: **Baixo**
- **Passos para Reprodução**:
  1. Acesse Configurações (`/more`).
  2. Altere a frequência de monitoramento para "A cada 6 horas" e o estoque mínimo para 10.
  3. Atualize a página no navegador ou reinicie o aplicativo.
  4. As configurações retornam para "Diariamente" e 5.
- **Causa Raiz no Código**:
  As opções são salvas apenas em variáveis locais `setState` de `_SettingsScreenState` e não são salvas no `SharedPreferences` ou no Firestore.
- **Recomendação de Correção**:
  Criar um `SettingsRepository` ou persistir as opções via `SharedPreferences`.

---

### BUG-19: Ausência de Timeout nas Sessões de Leitura e Gravação NFC
- **Fluxo / Funcionalidade Afetada**: Sessões do hardware NFC nativo em `NfcService`.
- **Arquivo e Linha(s)**: `lib/core/services/nfc_service.dart:68-82, 110-164`
- **Severidade**: **Médio**
- **Passos para Reprodução**:
  1. Inicie a leitura ou gravação de tag NFC.
  2. Afaste o aparelho e não aproxime nenhuma tag.
  3. A antena permanece aberta indefinidamente sem timeout.
- **Causa Raiz no Código**:
  Falta de controle de tempo com `Timer(const Duration(seconds: 20), () => stopSession())`.
- **Recomendação de Correção**:
  Adicionar timer configurável de 20 a 30 segundos com cancelamento automático da sessão e callback de timeout para o usuário.

---

### BUG-20: Gravação Inválida de Documento `'temp'` no Firestore ao Criar Serviço
- **Fluxo / Funcionalidade Afetada**: Cadastro de novo serviço (`CreateServiceScreen`).
- **Arquivo e Linha(s)**: `lib/core/services/real_health_check_service.dart:138-166`, `lib/features/services/presentation/create_service_screen.dart:55`
- **Severidade**: **Médio**
- **Passos para Reprodução**:
  1. Ao preencher o formulário de novo serviço, o app invoca `healthService.checkUrl('temp', url)`.
  2. `_persistHealthCheck` tenta atualizar o documento inexistente `services/temp`.
  3. Uma exceção `not-found` é disparada no Firestore e capturada no log.
- **Causa Raiz no Código**:
  O serviço de health check assume que todo `serviceId` passado já existe como documento raiz no Firestore e tenta executar `servDocRef.update(...)`.
- **Recomendação de Correção**:
  Permitir verificação stateless de URLs (ex.: `checkUrlStateless(url)`) ou pular a persistência no Firestore quando o ID for provisório (`'temp'`).

---

## 3. Matriz de Priorização para Correções

| ID | Área | Gravidade | Impacto | Esforço Estimado |
|---|---|---|---|---|
| **BUG-01** | Integridade / Models | **Crítica** | Desvinculação impossível / orfandade de dispositivos | Baixo |
| **BUG-02** | Integridade / Pedidos | **Crítica** | Exclusão de dispositivo trava pedido para sempre | Médio |
| **BUG-03** | Lógica de Negócios / Fluxos | **Crítica** | Pedidos criados no app não podem ser concluídos | Médio |
| **BUG-04** | NFC / Qualidade | **Crítica** | Gravação física falsa de chips NFC | Baixo |
| **BUG-05** | Async / Exceções | **Crítica** | Crash em operações de pedidos e pagamentos | Baixo |
| **BUG-06** | Formulários | **Média** | Edição de empresa aceita nome em branco | Baixo |
| **BUG-07** | Formulários | **Média** | Serviços sem título e URLs inválidas | Baixo |
| **BUG-08** | Lógica de Negócios | **Média** | Falsa cobertura de testes (limite de 10) | Baixo |
| **BUG-09** | Infraestrutura / Rede | **Média** | Vazamento de sockets `HttpClient` | Baixo |
| **BUG-10** | Navegação / UX | **Média** | Escanear NFC no Dashboard não cadastra tag | Baixo |
| **BUG-11** | Navegação / Web | **Média** | `context.pop()` quebra em deep links web | Baixo |
| **BUG-12** | Navegação / UI | **Média** | Barra inferior destaca aba errada | Baixo |
| **BUG-13** | Segurança | **Média** | Falha no filtro SSRF para HTTPS | Baixo |
| **BUG-19** | NFC / Bateria | **Média** | Falta de timeout no leitor NFC | Baixo |
| **BUG-20** | Banco de Dados | **Média** | Escrita em documento provisório 'temp' | Baixo |
| **BUG-14** | Web / Exportação | **Baixa** | Download falso de QR Code na web | Médio |
| **BUG-15** | UI / Formatação | **Baixa** | Prefixo '##' em pedidos e enums sem tradução | Baixo |
| **BUG-16** | Auditoria | **Baixa** | Ações atribuídas ao usuário fake `usr-001` | Baixo |
| **BUG-17** | UI / Mock Data | **Baixa** | Textos estáticos de estoque e checklist | Baixo |
| **BUG-18** | Persistência | **Baixa** | Configurações perdidas ao recarregar | Médio |
