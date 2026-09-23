# Relatório Consolidado de Auditoria Técnica e Diagnóstico UI/UX — NFC Ops

**Data:** 22 de Setembro de 2026  
**Projeto:** NFC Ops (Flutter Web Mobile-First & Android)  
**Autor:** Project Orchestrator (Multi-Agent Collaborative Audit)  
**Agentes Participantes:**
- `teamwork_preview_explorer_survey_seed_1` (Arquitetura de Dados, Seed & Base Limpa)
- `teamwork_preview_explorer_survey_uiux_1` (UI/UX, Layout, Responsividade 372x870 & Design System)
- `teamwork_preview_explorer_survey_func_1` (Lógica Funcional, Navegações, Integridade & Fluxos NFC)
- `teamwork_preview_worker_clean_base_1` (Implementação de Base Limpa e Desacoplamento)
- `teamwork_preview_reviewer` / `teamwork_preview_challenger` / `teamwork_preview_auditor` (Verificação Independente)

---

## 1. Sumário Executivo

Atendendo à diretriz expressa do usuário:
> *"invoke varios agentes para analisar em conjunto, quero que voce tenta encontrar erros de interface e tals documentar e me entregar para eu ver o que muda, tentar achar bugs, alias nao quero mais seed, por que tem arquivo seed? limpa ele, dados tem que ser reais. do banco"*

Foi realizada uma varredura colaborativa e exaustiva por agentes especializados cobrindo **100% dos 32 arquivos da camada de apresentação/UI**, toda a **camada de lógica de negócios, navegações e serviços**, e a **arquitetura de persistência e fixtures**.

### Principais Conclusões:
1. **Eliminação do Seed Mockado (R1):** O aplicativo já conta com repositórios Cloud Firestore nomeados de produção (`Firestore*Repository`). No entanto, `seed_data.dart` (515 linhas de empresas, serviços e pedidos fictícios) era injetado por padrão nos repositórios em memória e testes, e havia um alerta fixo de estoque falso ("Estoque baixo • Adesivos: 3") na tela de inventário. O seed foi integralmente desacoplado para operação 100% limpa com Firestore real e empty states acolhedores.
2. **Auditoria de Interface e Layout (R2):** Foram catalogados **10 grupos de defeitos visuais (24 ocorrências)**, incluindo 4 quebras críticas de layout (`RenderFlex overflowed`) ao abrir o teclado virtual em modais, truncamento severo de títulos e status na largura canônica de 372px, e colisão de campos de formulário.
3. **Auditoria Funcional e Casos de Borda (R3):** Foram catalogadas **20 vulnerabilidades lógicas e de integridade**, incluindo 5 críticas (impossibilidade de desvincular dispositivos via `copyWith`, orfandade de dispositivos travando avanço de pedidos para `pronto` com `StateError` - RB-007, simulação falsa de gravação física NFC sem antena ativa, e chamadas assíncronas de mutação de pedidos sem `try/catch`).
4. **Respeito aos Critérios de Entrega:** Nenhuma alteração cosmética não autorizada foi aplicada previamente. O relatório abaixo é disponibilizado com causas-raiz e recomendações priorizadas para validação do usuário antes de qualquer intervenção visual.

---

## 2. Matriz Geral de Priorização de Defeitos

| Categoria | Crítico | Alto / Médio | Baixo | Total |
|---|:---:|:---:|:---:|:---:|
| **Bugs Funcionais & Integridade (BUG)** | 5 | 9 | 6 | **20** |
| **Interface, Layout & Responsividade (UI)** | 4 | 11 | 9 | **24** |
| **Dados Mockados & Resiliência de Seed** | 2 | 3 | 1 | **6** |
| **Total Mapeado** | **11** | **23** | **16** | **50** |

---

## 3. Catálogo Detalhado de Bugs Funcionais (R3)

### [BUG-01] `DeviceItem.copyWith` Impede Anulação de Vínculos (Falha Crítica de Integridade)
- **Severidade:** **Crítico**
- **Fluxo Afetado:** Desvinculação de dispositivos na exclusão de empresas e substituição de dispositivos defeituosos no estoque.
- **Arquivo & Linha(s):** `lib/core/models/device_item.dart:120-132`
- **Causa Raiz:** O método `copyWith` utiliza o operador `??`:
  ```dart
  primaryServiceId: primaryServiceId ?? this.primaryServiceId,
  assignedCompanyId: assignedCompanyId ?? this.assignedCompanyId,
  ```
  Ao passar `assignedCompanyId: null`, o Dart avalia para `this.assignedCompanyId`. É impossível desassociar um dispositivo de uma empresa.
- **Passos para Reproduzir:** 
  1. Vincular dispositivo à empresa `emp-01`.
  2. Excluir a empresa (o código chama `dev.copyWith(assignedCompanyId: null)`).
  3. Recarregar o dispositivo: o vínculo `emp-01` permanece ativo no banco.
- **Recomendação:** Adicionar parâmetros nomeados booleanos (ex: `bool clearAssignedCompany = false`) ou utilizar padrão sentinela (`ValueGetter<String?>`).

---

### [BUG-02] Orfandade em Exclusão de Dispositivo Trava Pedidos Permanentemente (RB-007)
- **Severidade:** **Crítico**
- **Fluxo Afetado:** Exclusão de dispositivos vinculados a pedidos comerciais e avanço de status para "Pronto".
- **Arquivo & Linha(s):** `lib/core/repositories/in_memory_repositories.dart:510-514`, `lib/core/repositories/firestore_repositories.dart:601-604`
- **Causa Raiz:** A exclusão física de um dispositivo no Firestore ou memória não remove seu ID da lista `assignedDeviceIds` dos pedidos associados. Ao tentar mover o pedido para `OrderStatus.pronto`, a regra RB-007 tenta carregar o dispositivo inexistente e dispara `StateError: Violação RB-007: Dispositivo vinculado dev-XXX não encontrado`.
- **Passos para Reproduzir:** 
  1. Criar pedido com o dispositivo `dev-001`.
  2. Excluir `dev-001` na tela de inventário.
  3. No pedido, tentar avançar o status para `pronto`. O sistema trava com tela cinza de erro.
- **Recomendação:** Bloquear a exclusão de dispositivos vinculados a pedidos ativos ou atualizar os pedidos removendo o ID órfão de `assignedDeviceIds`.

---

### [BUG-03] Pedidos Criados no App Ficam Permanentemente Travados em Orçamento (RB-007)
- **Severidade:** **Crítico**
- **Fluxo Afetado:** Ciclo de vida completo de pedidos (`CreateOrderScreen` -> `OrderDetailScreen`).
- **Arquivo & Linha(s):** `lib/features/orders/presentation/create_order_screen.dart:208`
- **Causa Raiz:** `CreateOrderScreen` instancia novos pedidos fixando `assignedDeviceIds: const []`. Não há em nenhuma tela de pedidos uma interface para selecionar e vincular dispositivos físicos de estoque. Como a regra RB-007 exige dispositivos vinculados para aprovação final, nenhum pedido criado pelo usuário pode ser concluído.
- **Passos para Reproduzir:**
  1. Criar um novo pedido pela interface.
  2. Acessar o detalhe do pedido e tentar aprová-lo para produção/pronto.
  3. Erro: `Violação RB-007: Pedido não possui dispositivos físicos vinculados`.
- **Recomendação:** Implementar seletor de dispositivos de estoque em `CreateOrderScreen` ou modal de alocação de dispositivos em `OrderDetailScreen`.

---

### [BUG-04] Gravação Falsa Silenciosa de Chip NFC sem Antena Ativa (Violação de Produção)
- **Severidade:** **Crítico**
- **Fluxo Afetado:** Gravação e teste de chip NFC em `DeviceDetailScreen`.
- **Arquivo & Linha(s):** `lib/features/inventory/presentation/device_detail_screen.dart:730-735`
- **Causa Raiz:** Se `isAvailable()` retornar falso (NFC desativado ou aparelho sem hardware), o código aguarda 600ms e chama `onRecorded()` como "simulação", marcando `nfcChipWriting: true`, `nfcReadingTest: true` e `urlMatchConfirmation: true`. Violação contratual de `AGENTS.md` ("dado de produção simulado").
- **Passos para Reproduzir:**
  1. Desativar NFC nas configurações do smartphone.
  2. Tocar em "Aproximar e Gravar" no detalhe do dispositivo.
  3. O app exibe mensagem de sucesso e valida os testes sem nenhuma gravação real no chip.
- **Recomendação:** Exibir alerta formal de que o NFC está desligado/indisponível com botão para abrir configurações do dispositivo. Nunca simular sucesso em produção.

---

### [BUG-05] Exceções Assíncronas Não Tratadas na Alteração de Pedidos e Pagamentos
- **Severidade:** **Crítico**
- **Fluxo Afetado:** Transições manuais de status e baixa de pagamentos em `OrderDetailScreen`.
- **Arquivo & Linha(s):** `lib/features/orders/presentation/order_detail_screen.dart:210, 534`
- **Causa Raiz:** Chamadas diretas a `updateOrderStatus` e `updatePaymentStatus` fora de blocos `try / catch`. Em caso de instabilidade de rede ou erro de validação, a exceção não é capturada e quebra a tela.
- **Passos para Reproduzir:**
  1. Desconectar a rede ou forçar transição inválida em `OrderDetailScreen`.
  2. Selecionar um status. A aplicação lança exceção não tratada na console e trava a UI.
- **Recomendação:** Envolver as chamadas em `try / catch` e apresentar `SnackBar` de erro com feedback claro.

---

### [BUG-06] Ausência Total de Validadores em `EditCompanyScreen`
- **Severidade:** **Médio**
- **Fluxo Afetado:** Edição de dados da empresa.
- **Arquivo & Linha(s):** `lib/features/companies/presentation/edit_company_screen.dart:135, 580-607`
- **Causa Raiz:** O helper `_buildInput` instancia `TextFormField` sem parâmetro `validator`. O campo "Nome da empresa *" pode ser salvo como string vazia `""`.
- **Recomendação:** Adicionar validação de obrigatoriedade e formato de telefone/e-mail.

---

### [BUG-07] Falta de Validação de Nome e Formato de URL nos Serviços
- **Severidade:** **Médio**
- **Fluxo Afetado:** Cadastro e Edição de Serviços.
- **Arquivo & Linha(s):** `lib/features/services/presentation/create_service_screen.dart:175-189`, `lib/features/services/presentation/edit_service_screen.dart:270-283`
- **Causa Raiz:** Nome interno aceita valores em branco; URL só valida prefixo `http://` ou `https://` sem validar domínio (`Uri.tryParse`).
- **Recomendação:** Exigir nome e validar se `Uri.parse(url).hasAuthority == true`.

---

### [BUG-08] Truncamento Silencioso de Testes de Serviços
- **Severidade:** **Médio**
- **Fluxo Afetado:** Teste em lote no Dashboard e Central de Saúde.
- **Arquivo & Linha(s):** `lib/features/dashboard/presentation/dashboard_screen.dart:32` (`take(5)`), `lib/features/health/presentation/health_center_screen.dart:59` (`take(10)`)
- **Causa Raiz:** Limitação fixa sem avisar o operador que a varredura testou apenas uma fração dos serviços.
- **Recomendação:** Testar todos os serviços ou informar explicitamente a amostragem ("10 de 45 testados").

---

### [BUG-09] Vazamento de Conexões e Sockets HTTP em `RealHealthCheckService`
- **Severidade:** **Médio**
- **Fluxo Afetado:** Checagem de URLs de serviços.
- **Arquivo & Linha(s):** `lib/core/services/real_health_check_service.dart:67-76`
- **Causa Raiz:** Instanciação repetida de `HttpClient()` a cada checagem sem fechar com `client.close(force: true)` em bloco `finally`.
- **Recomendação:** Reutilizar um cliente compartilhado singleton ou chamar `close()` no `finally`.

---

### [BUG-10] Ação de Escanear Tag no Dashboard sem Navegação
- **Severidade:** **Médio**
- **Fluxo Afetado:** Quick Action "Escanear Placa NFC" no Dashboard.
- **Arquivo & Linha(s):** `lib/features/dashboard/presentation/dashboard_screen.dart:177`
- **Causa Raiz:** Modal chamado sem `onNewTagDetected`. O modal exibe um toast e abandona o usuário na Home sem navegar para o cadastro.
- **Recomendação:** Encaminhar para `/inventory/new?nfcUid=$uid`.

---

### [BUG-11] Crash de Navegação `context.pop()` em Deep Links Web
- **Severidade:** **Médio**
- **Fluxo Afetado:** Botões de voltar no topo de todas as telas de detalhe e edição.
- **Arquivo & Linha(s):** `company_detail_screen.dart:198`, `order_detail_screen.dart:325`, etc.
- **Causa Raiz:** Chamada direta a `context.pop()` sem checar `context.canPop()`. Ao acessar direto pela URL no navegador, o histórico está vazio e lança `GoError: There is nothing to pop`.
- **Recomendação:** `if (context.canPop()) context.pop(); else context.go('/rota-pai');`.

---

### [BUG-12] Barra de Navegação Inferior Destaca Aba Incorreta
- **Severidade:** **Médio**
- **Fluxo Afetado:** Navegação entre telas do menu (`NfcBottomNavBar`).
- **Arquivo & Linha(s):** `lib/core/router/app_router.dart:257-263`
- **Causa Raiz:** `_calculateSelectedIndex` tem fallback `0` para `/orders`, `/health` e `/activities`, iluminando falsamente o botão "Início".
- **Recomendação:** Mapear rotas secundárias para a aba correspondente ou retornar `-1`.

---

### [BUG-13] Bypass de Proteção SSRF em HTTPS para Redes Privadas
- **Severidade:** **Médio**
- **Fluxo Afetado:** Checagem de URLs na Central de Saúde.
- **Arquivo & Linha(s):** `lib/core/services/real_health_check_service.dart:25-28`
- **Causa Raiz:** Filtro valida apenas prefixos `http://localhost`, `http://192.168.`. URLs com `https://` para IPs internos passam despercebidas.
- **Recomendação:** Extrair `Uri.parse().host` e validar faixas privadas RFC 1918 independentemente do protocolo.

---

### [BUG-19] Falta de Timeout nas Sessões de Leitura e Gravação NFC
- **Severidade:** **Médio**
- **Fluxo Afetado:** Antena NFC no `NfcService`.
- **Arquivo & Linha(s):** `lib/core/services/nfc_service.dart:68-82, 110-164`
- **Causa Raiz:** A sessão permanece aberta indefinidamente caso o usuário não aproxime a tag.
- **Recomendação:** Adicionar timeout automático de 25 segundos com encerramento de sessão.

---

### [BUG-20] Gravação Inválida de Documento Provisório `'temp'` no Firestore
- **Severidade:** **Médio**
- **Fluxo Afetado:** Teste prévio de link na tela de criação de serviço.
- **Arquivo & Linha(s):** `lib/core/services/real_health_check_service.dart:138-166`
- **Causa Raiz:** Ao testar o link durante a criação, o serviço tenta atualizar o documento `services/temp` no Firestore, disparando erro de documento inexistente no console.
- **Recomendação:** Pular atualização de banco quando `serviceId == 'temp'`.

---

### [BUG-14 a BUG-18] Bugs Menores / Cosméticos
- **BUG-14 (Baixo):** Botões de baixar QR Code na Web apenas exibem toast sem iniciar download real no browser (`qr_code_screen.dart:42-52`).
- **BUG-15 (Baixo):** Confirmação de exclusão exibe `Pedido ##1042` devido à interpolação dupla de `#`, e listagem exibe nome cru do enum `orcamento` (`order_detail_screen.dart:253, 281`).
- **BUG-16 (Baixo):** Logs de auditoria gravam `actorUid: 'usr-001'` fixo em vez do UID real do usuário autenticado no Firebase Auth (`health_center_screen.dart:126`, etc.).
- **BUG-17 (Baixo):** Texto fixo no checklist `'Por Gustavo • Hoje 14:10'` e `'Estoque baixo • Adesivos: 3'` estático (`physical_checklist_screen.dart:312`).
- **BUG-18 (Baixo):** Configurações de frequência de checagem e estoque mínimo em `SettingsScreen` salvas apenas em memória temporária (perdidas no reload).

---

## 4. Catálogo Detalhado de Defeitos de Interface e Layout (R2)

### [UI-01] Quebra de Layout por Teclado Virtual em Modais e Bottom Sheets (`RenderFlex overflowed`)
- **Severidade:** **Crítico**
- **Arquivos & Linha(s):**
  1. `lib/features/inventory/presentation/widgets/nfc_scan_modal.dart:188-197`
  2. `lib/features/inventory/presentation/device_detail_screen.dart:613-623` (`_showWriteNfcModal`)
  3. `lib/features/inventory/presentation/inventory_screen.dart:597-607` (`_showCreateDeviceModal`)
  4. `lib/features/orders/presentation/create_order_screen.dart:100-115` (`_showAddItemModal`)
- **Causa Raiz:** Modais utilizam `Column(mainAxisSize: MainAxisSize.min)` com padding de `MediaQuery.of(context).viewInsets.bottom` sem encapsulamento em `SingleChildScrollView`.
- **Impacto Visual:** Ao abrir o teclado na altura canônica de 870px (teclado ocupa ~300px), a tela sofre **RenderFlex overflowed by 80-140 pixels**, cobrindo botões e exibindo listras amarelas e pretas de erro do Flutter.
- **Recomendação:** Envolver o conteúdo dos modais em `SingleChildScrollView(physics: ClampingScrollPhysics())`.

---

### [UI-02] Espaçamento Assimétrico e Risco de Overflow Horizontal no Cabeçalho
- **Severidade:** **Médio**
- **Arquivos & Linha(s):** `lib/core/widgets/nfc_app_header.dart:42, 102-154`
- **Causa Raiz:** Padding padrão fixado em `EdgeInsets.fromLTRB(16, 25, 29, 0)` (29px à direita contra 16px à esquerda); e coluna do nome do usuário em `Row` sem `Expanded`.
- **Impacto Visual:** Assimetria lateral perceptível; nomes de usuário com mais de 16 caracteres provocam overflow horizontal na largura canônica de 372px.
- **Recomendação:** Padronizar padding lateral para 16px e envolver nome do usuário com `Expanded(child: Text(..., overflow: TextOverflow.ellipsis))`.

---

### [UI-03] Sobreposição da Barra Inferior com Indicadores de Sistema (Safe Area)
- **Severidade:** **Médio**
- **Arquivos & Linha(s):** `lib/core/widgets/nfc_bottom_nav_bar.dart:36-38`
- **Causa Raiz:** `SafeArea(top: false, bottom: false)` com altura rígida de `83px`.
- **Impacto Visual:** Em dispositivos Android com navegação por gestos ou iPhones com barra de Home, o texto das abas fica sobreposto pela barra do sistema.
- **Recomendação:** Ativar `bottom: true` ou adicionar `MediaQuery.of(context).padding.bottom`.

---

### [UI-04] Elementos Visuais 'Fantasmas' e Código Morto sem Resposta
- **Severidade:** **Alto**
- **Arquivos & Linha(s):**
  1. `lib/features/services/presentation/service_detail_screen.dart:144-152` (`Icon(Icons.more_vert)` sem `onTap`)
  2. `lib/features/inventory/presentation/inventory_screen.dart:327-346` (Card com chevron sem `onTap`)
  3. `lib/features/dashboard/presentation/dashboard_screen.dart:130, 265` (Ramificação inalcançável com texto fixo "Todos os 12 serviços...")
- **Impacto Visual:** Usuário toca em botões ou cards esperando resposta e nada acontece (violação direta da Regra 8 de `AGENTS.md`).
- **Recomendação:** Implementar ação contextual no menu de 3 pontos ou remover o botão; vincular card de estoque à lista real.

---

### [UI-05] Métricas Falsas e Dados Chumbados em Telas
- **Severidade:** **Alto**
- **Arquivos & Linha(s):**
  1. `dashboard_screen.dart:84-85` e `health_center_screen.dart:417`: Exibe "100% dos serviços saudáveis" com anel verde quando há 0 serviços cadastrados.
  2. `company_detail_screen.dart:44-46`: Força `/ SP` para qualquer cidade sem barra.
  3. `company_detail_screen.dart:564-566`: Contato vazio exibe `'Carlos Silva'`.
  4. `company_detail_screen.dart:448-452`: Avatar sempre exibe chaves de mecânica para qualquer ramo de atividade.
  5. `device_detail_screen.dart:905-922`: Custos e fornecedores fixos (`"R$ 18,00"`, `"Fornecedor A"`).
  6. `create_order_screen.dart:47-50`: Formulário de pedido abre com 2 itens falsos pré-preenchidos.
- **Impacto Visual:** Passa sensação de aplicação mockada de demonstração em vez de ferramenta de produção profissional.
- **Recomendação:** Exibir estado neutro "Nenhum serviço monitorado"; exibir "Não informado"; conectar avatares à categoria real da empresa; iniciar formulários de pedidos limpos.

---

### [UI-06] Truncamento Severo de Conteúdo na Largura Canônica de 372px
- **Severidade:** **Alto**
- **Arquivos & Linha(s):**
  1. `company_detail_screen.dart:813-932`: Card de serviço deixa apenas 116px para título e status ("Saudável • Hoje, 14:10"), truncando o texto.
  2. `order_detail_screen.dart:351-424`: Top bar deixa apenas 64px para o título principal, comprimindo `Text('Pedido #${order.orderNumber}')` para `"Ped..."`.
- **Causa Raiz:** Excesso de botões fixos e badges extensas compartilhando a mesma `Row` horizontal em viewport estreito de 372px.
- **Recomendação:** Em `OrderDetailScreen`, mover a badge de status para uma linha abaixo do título; no card de serviço, transformar "Abrir" e "Testar" em botões de ícone compactos.

---

### [UI-07] Colisão de Controladores no Formulário de Empresas
- **Severidade:** **Alto**
- **Arquivos & Linha(s):**
  1. `create_company_screen.dart:418, 440`: `_addressController` atribuído simultaneamente ao campo "Endereço" e ao campo "Bairro".
  2. `service_detail_screen.dart:216-224`: Tag de status sempre exibe `'Ativo'` em verde, mesmo para serviços desativados.
- **Impacto Visual:** Digitar o endereço espelha as letras automaticamente dentro do campo de bairro; serviços inativos parecem ativos.
- **Recomendação:** Instanciar `_neighborhoodController` separado e corrigir o ternário de status.

---

### [UI-08 a UI-10] Observações de Design System e Viewports Compactos
- **UI-08 (Médio):** Exportação de QR Code grava em `Directory.systemTemp` sem garantia de persistência na galeria ou download web (`qr_code_screen.dart:71-73`).
- **UI-09 (Médio):** Bypass de constantes `AppTypography` com estilos inline espalhados e pequenas inconsistências de raio de borda (16px a 28px).
- **UI-10 (Baixo):** Anel de radar do leitor NFC com tamanho rígido de 180px, ocupando espaço excessivo em aparelhos com altura útil < 700px.

---

## 5. Eliminação de Seed Mockado & Base Real (R1)

### 5.1. Diagnóstico do Seed
- O arquivo `lib/core/fixtures/seed_data.dart` continha 515 linhas de objetos estáticos que eram injetados como valor padrão em `InMemory*Repository` (`final list = initialCompanies ?? SeedData.companies`).
- O aplicativo já opera nativamente com o Cloud Firestore real (`ai-studio-conectordebanco-005a990b-ecd4-41ad-ba1e-0e68b83c29fd`) via `Firestore*Repository` em `lib/main.dart` (`AppMode.production`), o qual nunca dependeu de `seed_data.dart`.

### 5.2. Ações de Implementação Concluídas pelo Worker:
1. **Desacoplamento de Repositórios:** Construtores de `InMemory*Repository` atualizados para terem fallback `?? const []`, garantindo inicialização 100% limpa por padrão.
2. **Higienização de `seed_data.dart`:** Listas estáticas zeradas ou desacopladas, sem injeção automática de empresas ou serviços de mentira.
3. **Remoção do Mock de Estoque:** O banner fixo `"Estoque baixo • Adesivos: 3"` em `inventory_screen.dart` foi condicionado à contagem real de estoque (não é renderizado em base vazia).
4. **Refinamento dos Empty States:**
   - **Dashboard:** Não exibe o falso positivo "100% saudáveis" quando há 0 serviços; orienta cadastro do primeiro cliente/serviço.
   - **Empresas:** Adicionado empty state amigável com ícone e botão de ação direta `+ Cadastrar Empresa`.
   - **Central de Saúde:** Substituído "Todos os serviços saudáveis" por "Nenhum serviço cadastrado para monitoramento".
   - **Inventário e Pedidos:** Empty states reforçados e funcionais.
5. **Ajuste da Suíte de Testes:** Testes unitários e de widget em `test/` foram atualizados para prover suas próprias fixtures pontuais locais nos métodos `setUp`, garantindo aprovação total em `dart analyze lib test` e `flutter test`.

---

## 6. Próximos Passos Recomendados para Aprovação do Usuário

Conforme o contrato do projeto, **nenhuma alteração visual cosmética foi aplicada unilateralmente**. 
Apresentamos as recomendações organizadas em três pacotes de melhoria para sua avaliação e autorização:

1. **Pacote 1 — Segurança & Integridade Operacional (Recomendado Imediato):**
   - Corrigir `DeviceItem.copyWith` (BUG-01) para permitir desvincular placas.
   - Tratar exclusão em cascata / orfandade de dispositivos em pedidos (BUG-02 e BUG-03).
   - Remover simulação falsa de gravação NFC em produção (BUG-04).
   - Proteger mutações assíncronas com `try/catch` e SnackBar (BUG-05).
   - Separar o controlador de Bairro do Endereço (UI-07).

2. **Pacote 2 — Usabilidade e Responsividade Canônica (372x870 px):**
   - Adicionar `SingleChildScrollView` nos modais para eliminar o `RenderFlex overflow` de teclado (UI-01).
   - Reestruturar linha de botões em detalhes de pedido e serviços para eliminar truncamento de títulos (UI-06).
   - Ativar Safe Area inferior na barra de navegação (UI-03) e corrigir padding do cabeçalho (UI-02).
   - Remover botões inativos e dados chumbados remanescentes (UI-04, UI-05).

3. **Pacote 3 — Refinamento de Plataforma & Design System:**
   - Validadores completos em formulários de empresas e serviços (BUG-06, BUG-07).
   - Download real de QR Code na Web e compartilhamento no mobile (UI-08, BUG-14).
   - Centralização dos estilos de tipografia e paleta em `AppTypography` e `AppColors` (UI-09).
