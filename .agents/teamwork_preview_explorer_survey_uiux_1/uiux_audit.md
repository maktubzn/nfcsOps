# Relatório de Auditoria UI/UX, Layout, Responsividade e Design System
**Projeto:** NFC Ops (Flutter Web Mobile-First & Android)  
**Data da Auditoria:** 22 de Setembro de 2026  
**Auditor:** Explorer UI/UX (teamwork_preview_explorer_survey_uiux_1)  
**Modo:** Estritamente Leitura (Read-Only Investigation)  
**Alvo Canônico:** Viewport Mobile Canônico de 372 x 870 px & Telas Compactas  

---

## 1. Sumário Executivo

Uma varredura exaustiva linha a linha foi conduzida em todos os 32 arquivos visuais e de apresentação (`lib/features/*`, `lib/core/widgets/*`, `lib/core/theme/*`, `lib/core/router/*`). 
A aplicação apresenta uma identidade visual sólida alinhada ao design canônico (Dark Theme `#10110F`, Laranja de Ação `#FF5500`, Card Creme `#FAF9F0` e Cards Escuros `#161715` / `#1C1D1B`).

Entretanto, foram identificados **10 grupos de defeitos visuais, de layout e usabilidade**, totalizando **24 ocorrências pontuais**, das quais **4 são Críticas** (quebras de layout com erro `RenderFlex overflowed` ao abrir teclado ou em larguras de 372px), **11 são de Alta Severidade** (dados fictícios/chumbados em produção, botões 'fantasma' sem ação e truncamentos severos de texto essencial), e **9 são de Média/Baixa Severidade** (inconsistências de tokens de design, sobreposição de barras do sistema e desvios de navegação).

---

## 2. Matriz Consolidada de Defeitos UI/UX

| ID | Severidade | Categoria | Componente / Tela | Impacto Visual Principal |
|---|---|---|---|---|
| **UI-01** | **Crítico** | Layout / Overflow | Modais & Bottom Sheets | RenderFlex overflow (quebra com listras amarelas/pretas) ao abrir teclado virtual |
| **UI-02** | **Médio** | Layout / Header | `NfcAppHeader` | Padding direito assimétrico (29px vs 16px) e risco de overflow por nome longo |
| **UI-03** | **Médio** | Responsividade | `NfcBottomNavBar` | Barra de navegação sobreposta pela barra de gestos do sistema (falta Safe Area inferior) |
| **UI-04** | **Alto** | Usabilidade / Dead Elements | Detalhes de Serviço, Inventário, Dashboard | Ícones clicáveis sem ação (`Icons.more_vert`), cards de estoque falsos sem clique, código morto |
| **UI-05** | **Alto** | Mock / Dados Chumbados | Dashboard, Saúde, Empresas, Detalhes de Dispositivo | 100% saudável exibido para base com 0 serviços; nomes e custos mockados fixos |
| **UI-06** | **Alto** | Responsividade / Truncamento | Cards de Serviço, Top Bar de Pedido | Textos essenciais esmagados em menos de 60-100px na largura canônica de 372px |
| **UI-07** | **Alto** | Formulários / Estado | Criação de Empresa, Edição de Empresa, Detalhes de Serviço | Campo de Endereço espelhado no Bairro; falta de validação; tag "Ativo" fixa para inativos |
| **UI-08** | **Médio** | Plataforma / Exportação | Tela de QR Code (`qr_code_screen.dart`) | Gravação em `Directory.systemTemp` sem garantia de persistência na galeria |
| **UI-09** | **Médio** | Design System / Tokens | Cores, Tipografia, Raios de Borda | Bypass de `AppTypography` com estilos inline; duplicação de literais hexadecimais |
| **UI-10** | **Baixo** | Layout / Viewport Compacto | Animações de Radar NFC, Quick Actions | Gráficos fixos ocupando altura excessiva em telas com altura < 750px |

---

## 3. Detalhamento Exaustivo dos Defeitos Encontrados

### [UI-01] Layout Overflow por Teclado Virtual em Modais e Bottom Sheets
- **Severidade:** **Crítico**
- **Categoria:** Layout / Overflow (RenderFlex Overflow)
- **Locais Afetados:**
  1. `lib/features/inventory/presentation/widgets/nfc_scan_modal.dart:188-197`
  2. `lib/features/inventory/presentation/device_detail_screen.dart:613-623` (`_showWriteNfcModal`)
  3. `lib/features/inventory/presentation/inventory_screen.dart:597-607` (`_showCreateDeviceModal`)
  4. `lib/features/orders/presentation/create_order_screen.dart:100-115` (`_showAddItemModal`)
- **Evidência no Código:**
  ```dart
  // inventory_screen.dart:597-607
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    builder: (ctx) => SafeArea(
      child: Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [ ...Campos de texto... ]
        )
      )
    )
  );
  ```
- **Impacto Visual:**
  Ao tocar em um campo de texto (`TextFormField`) dentro do modal em dispositivos com viewport vertical compacto (especialmente 870px de altura com teclado de ~300px ou em aparelhos menores), o `Column` com `mainAxisSize: MainAxisSize.min` não rola e sofre **RenderFlex overflowed by 80-140 pixels** na parte inferior, cobrindo o botão de confirmação e exibindo faixas pretas e amarelas de erro do Flutter.
- **Recomendação de Correção:**
  Envolver os filhos do modal em um `SingleChildScrollView` com `physics: const ClampingScrollPhysics()` ou usar `DraggableScrollableSheet` com padding dinâmico de `viewInsets.bottom`.

---

### [UI-02] Espaçamento Assimétrico e Risco de Overflow Horizontal no Cabeçalho
- **Severidade:** **Médio**
- **Categoria:** Layout / Header Consistency
- **Locais Afetados:**
  1. `lib/core/widgets/nfc_app_header.dart:42`
  2. `lib/core/widgets/nfc_app_header.dart:102-154`
- **Evidência no Código:**
  ```dart
  // nfc_app_header.dart:42
  final EdgeInsets padding = widget.padding ?? const EdgeInsets.fromLTRB(16, 25, 29, 0);
  ```
  ```dart
  // nfc_app_header.dart:118-142
  Row(
    children: [
      Container(width: 50, height: 50, ...),
      const SizedBox(width: 12),
      Column( // <-- Sem Expanded ou Flexible
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(widget.userGreeting ?? 'Olá,', ...),
          Text(widget.userName ?? 'Gustavo', ...),
        ],
      ),
      const Spacer(),
      _buildIconButton(...),
    ],
  )
  ```
- **Impacto Visual:**
  - O padding direito padrão de `29px` não se alinha com o padding lateral de `16px` adotado em todas as telas (`dashboard_screen`, `inventory_screen`, `companies_screen`), causando uma assimetria visível de 13px na margem direita do cabeçalho.
  - O `Column` do nome do usuário não está encapsulado em `Expanded` ou `Flexible`. Caso o nome vindo do Firebase Auth tenha mais de 16 caracteres (ex: "Gustavo Henrique de Oliveira"), ele empurra os botões de ação para fora da tela de 372px, provocando `RenderFlex overflowed by XX pixels on the right`.
- **Recomendação de Correção:**
  - Padronizar o padding padrão para `const EdgeInsets.fromLTRB(16, 16, 16, 0)`.
  - Envolver o `Column` com `Expanded` e adicionar `overflow: TextOverflow.ellipsis, maxLines: 1` no `Text` do nome do usuário.

---

### [UI-03] Sobreposição da Barra Inferior com Indicadores de Sistema (Safe Area) e Rota de Abas
- **Severidade:** **Médio**
- **Categoria:** Responsividade / Navegação do Sistema
- **Locais Afetados:**
  1. `lib/core/widgets/nfc_bottom_nav_bar.dart:36-38`
  2. `lib/core/router/app_router.dart:257-263`
- **Evidência no Código:**
  ```dart
  // nfc_bottom_nav_bar.dart:36-38
  return SafeArea(
    top: false,
    bottom: false, // <-- Desativa proteção da barra do sistema
    child: Container(
      height: 83,
  ```
  ```dart
  // app_router.dart:257-263
  int _calculateSelectedIndex(BuildContext context) {
    final location = GoRouterState.of(context).uri.toString();
    if (location.startsWith('/dashboard')) return 0;
    if (location.startsWith('/inventory')) return 1;
    if (location.startsWith('/companies')) return 2;
    if (location.startsWith('/settings')) return 3;
    return 0; // Rotas /orders, /health, /activities marcam aba 0 incorretamente
  }
  ```
- **Impacto Visual:**
  - Em dispositivos Android modernos (navegação por gestos) ou iPhones com Home Indicator, a barra de navegação fica colada na borda física e os textos ("Início", "Dispositivos") são sobrepostos pela linha do sistema.
  - Ao navegar para `/orders`, `/health` ou `/activities`, o ícone "Início" permanece destacado em laranja, induzindo o usuário ao erro cognitivo de que está na Home.
- **Recomendação de Correção:**
  - Definir `bottom: true` no `SafeArea` ou usar `MediaQuery.of(context).padding.bottom` para adicionar padding dinâmico na altura total da barra.
  - Se a rota não for uma das 4 abas principais, `_calculateSelectedIndex` deve retornar `-1`, evitando iluminar a aba errada.

---

### [UI-04] Elementos Visuais 'Fantasmas' e Código Morto sem Resposta
- **Severidade:** **Alto**
- **Categoria:** Usabilidade / Violação do Contrato AGENTS.md (Regra 8)
- **Locais Afetados:**
  1. `lib/features/services/presentation/service_detail_screen.dart:144-152`
  2. `lib/features/inventory/presentation/inventory_screen.dart:327-346`
  3. `lib/features/dashboard/presentation/dashboard_screen.dart:130, 265`
- **Evidência no Código:**
  ```dart
  // service_detail_screen.dart:144-152
  Container(
    width: 44,
    height: 44,
    decoration: const BoxDecoration(
      color: Color(0xFF1E201D),
      shape: BoxShape.circle,
    ),
    child: const Icon(Icons.more_vert, color: Colors.white, size: 20), // Sem InkWell ou onTap
  ),
  ```
  ```dart
  // inventory_screen.dart:327-346
  // Card estático com chevron que parece clicável mas não faz nada:
  Row(
    children: [
      Icon(LucideIcons.alertTriangle, color: AppColors.orangeAction),
      Text('Estoque baixo • Adesivos: 3'),
      Spacer(),
      Icon(Icons.chevron_right, color: Color(0xFF6B7280)), // Sem ação
    ]
  )
  ```
  ```dart
  // dashboard_screen.dart:265 e 130-180
  if (criticalCount > 0) _buildCriticalAlertCard(context, criticalCount),
  // Dentro de _buildCriticalAlertCard:
  if (isCritical) { ... } else {
    // Código inalcançável: nunca executa pois o método só é chamado se criticalCount > 0!
    // Além disso, contém texto chumbado: "Todos os 12 serviços respondendo normalmente"
  }
  ```
- **Impacto Visual:**
  - O botão de três pontos no detalhe de serviço tem aparência de menu interativo de contexto, mas não reage ao toque (feedback tátil nulo).
  - O card de estoque baixo no inventário exibe um chevron sugerindo navegação, mas não possui `onTap` e sempre exibe "Adesivos: 3" mesmo quando não há nenhum adesivo cadastrado.
  - A ramificação saudável do card crítico do dashboard é código morto.
- **Recomendação de Correção:**
  - Adicionar menu pop-up ou remover o botão inativo em `service_detail_screen.dart`.
  - Conectar o card de estoque à contagem real de itens e adicionar `onTap` para filtrar dispositivos com estoque baixo.
  - Remover a ramificação morta em `_buildCriticalAlertCard`.

---

### [UI-05] Métricas Ilusórias e Dados Estáticos 'Chumbados' em Telas de Produção
- **Severidade:** **Alto**
- **Categoria:** Integridade Visual de Dados / Mock em Produção
- **Locais Afetados:**
  1. `lib/features/dashboard/presentation/dashboard_screen.dart:84-85`
  2. `lib/features/health/presentation/health_center_screen.dart:417`
  3. `lib/features/companies/presentation/company_detail_screen.dart:44-46, 564-566, 448-452`
  4. `lib/features/inventory/presentation/device_detail_screen.dart:905-922, 924-940`
  5. `lib/features/orders/presentation/create_order_screen.dart:47-50`
  6. `lib/features/settings/presentation/settings_screen.dart:298-302`
  7. `lib/features/inventory/presentation/physical_checklist_screen.dart:312`
- **Evidência no Código:**
  ```dart
  // dashboard_screen.dart:84-85
  final healthRatio = totalServices > 0 ? healthyCount / totalServices : 1.0;
  // Se totalServices == 0, exibe "100% dos serviços saudáveis" com anel verde completo!
  ```
  ```dart
  // company_detail_screen.dart:44-46
  String _formatCityUf(String cityUf) {
    if (cityUf.isEmpty) return 'São Paulo / SP';
    if (!cityUf.contains('/')) return '$cityUf / SP'; // Força / SP para qualquer cidade!
    return cityUf;
  }
  ```
  ```dart
  // company_detail_screen.dart:564-566
  final contactName = company.primaryContactName.isNotEmpty
      ? company.primaryContactName
      : 'Carlos Silva'; // Nome fictício chumbado
  ```
  ```dart
  // company_detail_screen.dart:448-452
  // Avatar da empresa sempre exibe chaves de mecânica cruzadas:
  child: CrossedWrenchesWidget(size: 26, color: Colors.white),
  ```
  ```dart
  // create_order_screen.dart:47-50
  final List<Map<String, dynamic>> _items = [
    {'type': 'Cartão NFC PVC', 'qty': 20, 'unitPrice': 15.0},
    {'type': 'Adesivo Epóxi 30mm', 'qty': 50, 'unitPrice': 8.5},
  ]; // Formulário de criação já abre com itens falsos preenchidos!
  ```
  ```dart
  // settings_screen.dart:298-302
  final users = [
    {'name': 'Gustavo Alves', 'email': 'gustwwavomitopai@gmail.com', ...},
    {'name': 'Operador Técnico', ...},
  ]; // Lista de usuários autorizados totalmente estática
  ```
- **Impacto Visual:**
  - Uma instalação limpa com 0 serviços cadastrados engana o operador exibindo "100% Saudável" e "Operação Estável".
  - Se uma empresa for cadastrada com a cidade "Belo Horizonte", a tela exibe "Belo Horizonte / SP".
  - Se o contato não for preenchido, a tela diz que o responsável é "Carlos Silva".
  - Cafeterias, consultórios médicos e pet shops exibem o ícone de mecânica automotiva no topo.
  - Operadores criando novos pedidos precisam apagar itens fictícios preenchidos previamente.
- **Recomendação de Correção:**
  - Quando `totalServices == 0`, exibir estado vazio: ratio 0.0, cor cinza, e mensagem "Nenhum serviço cadastrado".
  - Corrigir `_formatCityUf` para não forçar "SP".
  - Exibir "Não informado" em vez de nomes fictícios como "Carlos Silva".
  - Conectar o avatar da empresa à sua categoria cadastrada (usando ícones dinâmicos).
  - Inicializar `_items` vazio (`[]`) em `create_order_screen.dart`.
  - Conectar modal de usuários ao Firestore ou indicar visualmente "Configuração estática de demonstração".

---

### [UI-06] Truncamento Severo de Conteúdo na Largura Canônica de 372px
- **Severidade:** **Alto**
- **Categoria:** Responsividade / Truncamento de Texto
- **Locais Afetados:**
  1. `lib/features/companies/presentation/company_detail_screen.dart:813-932` (`_buildServiceCard`)
  2. `lib/features/orders/presentation/order_detail_screen.dart:351-424` (Top Bar)
  3. `lib/features/inventory/presentation/inventory_screen.dart:487-548` (`_buildDeviceCard`)
- **Evidência no Código & Cálculo de Largura em 372px:**
  - Em `company_detail_screen.dart:813-932`:
    Largura total: 372px.
    Padding da tela: 16px * 2 = 32px (largura do card: 340px).
    Dentro do card:
    Padding horizontal: 14px * 2 = 28px.
    Container do ícone: 44px + 12px gap = 56px.
    Botão "Abrir": ~52px.
    Gap: 6px.
    Botão "Testar": ~58px.
    Gap: 6px.
    Chevron: 18px.
    Soma dos elementos fixos = 28 + 56 + 52 + 6 + 58 + 6 + 18 = **224px**.
    Espaço restante para título e status = **116px**!
    O status `"Saudável • Hoje, 14:10"` necessita de pelo menos 145px.
    **Resultado:** O texto fica truncado para `"Saudável • H..."` ou colide com os botões.
  - Em `order_detail_screen.dart:351-424`:
    Largura total: 372px.
    Padding da tela: 32px.
    Botão voltar: 44px + 10px gap = 54px.
    Botão lixeira: 36px + 8px gap = 44px.
    Pill de status `"AGUARDANDO APROVAÇÃO"`: ~170px + 8px gap = 178px.
    Soma dos elementos fixos = 32 + 54 + 44 + 178 = **308px**!
    Espaço restante para o título principal da tela (`Text('Pedido #${order.orderNumber}')`): **64px**!
    **Resultado:** O título é violentamente truncado para `"Ped..."`.
- **Recomendação de Correção:**
  - Em `order_detail_screen.dart`: Mover a pílula de status para baixo do título ou empilhar em duas linhas no cabeçalho.
  - Em `company_detail_screen.dart`: No card de serviço, transformar os botões "Abrir" e "Testar" em botões de ícone com tooltip ou organizá-los em uma linha secundária inferior.

---

### [UI-07] Colisão de Controladores e Falhas de Validação em Formulários
- **Severidade:** **Alto**
- **Categoria:** Formulários e Integridade de Interface
- **Locais Afetados:**
  1. `lib/features/companies/presentation/create_company_screen.dart:418, 440`
  2. `lib/features/companies/presentation/edit_company_screen.dart:593-605`
  3. `lib/features/services/presentation/service_detail_screen.dart:216-224`
- **Evidência no Código:**
  ```dart
  // create_company_screen.dart:418 e 440
  // Linha 418:
  _buildInput(
    controller: _addressController,
    label: 'Endereço (Rua, Av, etc)',
  ),
  // Linha 440:
  _buildInput(
    controller: _addressController, // <-- MESMO CONTROLADOR!
    label: 'Bairro',
  ),
  ```
  ```dart
  // edit_company_screen.dart:593-605
  Widget _buildInput(...) {
    return TextFormField(
      controller: controller,
      // Nenhum 'validator' configurado! Permite submeter campos vazios.
    );
  }
  ```
  ```dart
  // service_detail_screen.dart:216-224
  _buildTag(
    service.status == 'active' ? 'Ativo' : 'Ativo', // <-- Sempre "Ativo"!
    AppColors.greenSuccess,
  ),
  ```
- **Impacto Visual:**
  - Ao digitar o endereço da empresa, o texto é espelhado instantaneamente no campo Bairro, impossibilitando preenchimento correto.
  - Usuários podem limpar o nome da empresa e salvar, gerando cards vazios na listagem.
  - Serviços com status "inativo" ou "suspenso" continuam exibindo a etiqueta verde "Ativo".
- **Recomendação de Correção:**
  - Criar `_neighborhoodController` separado em `create_company_screen.dart`.
  - Adicionar validadores obrigatórios em `edit_company_screen.dart`.
  - Corrigir a condicional do status em `service_detail_screen.dart` para exibir `'Inativo'` em vermelho quando não for ativo.

---

### [UI-08] Risco de Exceção de Sistema de Arquivos na Exportação de QR Code
- **Severidade:** **Médio**
- **Categoria:** Plataforma / Exportação de Assets
- **Locais Afetados:**
  1. `lib/features/qr/presentation/qr_code_screen.dart:71-73, 132-134`
- **Evidência no Código:**
  ```dart
  // qr_code_screen.dart:71-73
  final tempDir = Directory.systemTemp;
  final file = File('${tempDir.path}/qr_${widget.serviceId}.png');
  await file.writeAsBytes(bytes);
  ```
- **Impacto Visual:**
  No Android e no iOS, salvar em `Directory.systemTemp` não adiciona o arquivo à galeria de fotos nem ao diretório Downloads visível para o usuário, além de poder falhar por permissões se executado em diretórios não sandboxados sem `path_provider`. A SnackBar informa que o arquivo foi salvo, mas o usuário não consegue encontrá-lo no celular.
- **Recomendação de Correção:**
  Integrar com `path_provider` (ex: `getApplicationDocumentsDirectory`) ou `share_plus` para permitir compartilhamento direto do PNG/SVG gerado.

---

### [UI-09] Fragmentação de Tokens de Cores e Tipografia Inline
- **Severidade:** **Médio**
- **Categoria:** Design System / Consistência de Tokens
- **Locais Afetados:**
  1. `lib/core/theme/app_colors.dart` vs telas individuais
  2. `lib/core/theme/app_typography.dart` vs estilos inline
- **Evidência no Código:**
  - Em múltiplos arquivos (`settings_screen.dart:25`, `login_screen.dart:187`, `service_detail_screen.dart:148`), a cor escura `#161715` ou `#1C1D1B` é declarada como `const Color(0xFF161715)` em vez de utilizar o token `AppColors.surfaceCardDark` ou `AppColors.surfaceElevatedDark`.
  - Praticamente 100% dos textos nas telas usam `TextStyle(fontFamily: 'Inter', fontSize: X, fontWeight: ...)` inline, sem utilizar as constantes pré-configuradas de `AppTypography` (`heading1`, `bodyMedium`, etc.).
  - Raios de borda de cards variam desnecessariamente entre `16px`, `20px`, `24px` e `28px` sem padrão semântico definido.
- **Impacto Visual:**
  Divergências sutis de peso visual e espaçamento de letras (letterSpacing), dificultando futuras manutenções e quebrando a coerência sistemática do Design System.
- **Recomendação de Correção:**
  Refatorar instâncias inline para consumir centralizadamente `AppColors.*` e `AppTypography.*`.

---

### [UI-10] Escala Fixa de Gráficos e Radares em Viewports Verticais Compactos
- **Severidade:** **Baixo**
- **Categoria:** Layout / Altura Compacta
- **Locais Afetados:**
  1. `lib/features/inventory/presentation/widgets/nfc_scan_modal.dart:240-270`
  2. `lib/features/quick_actions/presentation/quick_actions_modal.dart:75-120`
- **Evidência no Código:**
  O anel de radar NFC possui diâmetro fixo de `180px`, mais padding vertical de `32px` e textos. Em telas com altura útil menor que 700px, o modal ocupa quase a tela inteira, empurrando botões de cancelar para fora do viewport inicial.
- **Recomendação de Correção:**
  Usar `LayoutBuilder` para dimensionar o diâmetro do anel proporcionalmente à altura da tela (`min(180, constraints.maxHeight * 0.25)`).

---

## 4. Auditoria Específica por Tela

### 4.1. Acesso / Login (`login_screen.dart`)
- **Aderência ao Design Canônico:** Alta. Fundo `#10110F`, ilustração heróica estilizada com anéis NFC concêntricos e botão Google estilizado.
- **Responsividade 372x870:** Envolvido em `SingleChildScrollView`, sem quebras verticais.
- **Observações:** O modo de demonstração (`_isDemoMode`, linha 48) realiza bypass automático da autenticação se o Firebase estiver inacessível, mas não exibe uma tarja informativa (banner) alertando que a sessão atual está em modo sandbox local.

### 4.2. Dashboard / Home (`dashboard_screen.dart`)
- **Aderência ao Design Canônico:** Muito alta na prancha visual.
- **Responsividade 372x870:** Grid de 4 cards de estatísticas (2 colunas) cabe perfeitamente em 372px (`(372 - 32 - 10) / 2 = 165px` por card).
- **Problemas Identificados:** [UI-02] Header com padding 29px; [UI-04] Ramo de código morto no card de alerta; [UI-05] Proporção de saúde exibindo 100% verde para 0 serviços.

### 4.3. Inventário & Detalhes de Dispositivo (`inventory_screen.dart`, `device_detail_screen.dart`)
- **Aderência ao Design Canônico:** Alta. Cards com UID, status (virgem, gravado, ativo), data de última leitura.
- **Responsividade 372x870:** Card de dispositivo sofre com risco de overflow na linha inferior caso o UID seja longo ([UI-06]).
- **Problemas Identificados:** [UI-01] Modal de criar dispositivo quebra com teclado; [UI-04] Card de estoque baixo estático; [UI-05] Custos e fornecedores chumbados no detalhe.

### 4.4. Empresas (`companies_screen.dart`, `company_detail_screen.dart`, `create_company_screen.dart`, `edit_company_screen.dart`)
- **Aderência ao Design Canônico:** Boa estruturação por cards e filtros de categoria.
- **Responsividade 372x870:** Card de serviço no detalhe de empresa sofre truncamento extremo do status ([UI-06]).
- **Problemas Identificados:** [UI-05] Cidade formatada forçando "/ SP", avatar sempre mecânica; [UI-07] Colisão de controladores entre endereço e bairro; falta de validação na edição.

### 4.5. Pedidos (`orders_screen.dart`, `order_detail_screen.dart`, `create_order_screen.dart`)
- **Aderência ao Design Canônico:** Excelente paleta com badges de status ("Pendente", "Produção", "Entregue").
- **Responsividade 372x870:** Top bar do detalhe de pedido esmaga o título "Pedido #XXXX" em menos de 64px ([UI-06]).
- **Problemas Identificados:** [UI-01] Modal de adicionar item quebra com teclado; [UI-05] Itens de pedido falsos pré-carregados na criação.

### 4.6. Central de Saúde (`health_center_screen.dart`)
- **Aderência ao Design Canônico:** Gráfico circular de integridade e histórico de varreduras.
- **Problemas Identificados:** [UI-05] 100% de integridade com 0 serviços; timestamps estáticos.

### 4.7. Configurações (`settings_screen.dart`)
- **Aderência ao Design Canônico:** Lista agrupada com visual iOS-like escuro, muito limpo.
- **Problemas Identificados:** [UI-05] Lista de usuários autorizados completamente mockada; configurações de monitoramento não salvas em storage persistente.

---

## 5. Plano de Ação Recomendado para os Agentes de Implementação

1. **Sprint Imediato (Correções Críticas - UI-01 & UI-07):**
   - Corrigir os 4 modais adicionando `SingleChildScrollView` e tratando `viewInsets.bottom`.
   - Separar o controlador de Bairro do Endereço em `create_company_screen.dart`.
   - Corrigir o ternário de status em `service_detail_screen.dart`.

2. **Sprint de Integridade de Dados & Contrato (UI-04, UI-05):**
   - Tratar estado vazio de serviços (0 serviços = 0% ou "Sem dados", não 100% verde).
   - Remover dados falsos (Carlos Silva, Fornecedor A, R$ 18,00, itens pré-carregados).
   - Remover botões mortos ou atribuir callbacks funcionais.

3. **Sprint de Responsividade Canônica (UI-02, UI-03, UI-06):**
   - Reestruturar linha de botões no card de serviço do detalhe de empresa para dar espaço ao status.
   - Reestruturar top bar de detalhes do pedido para evitar truncar o número do pedido.
   - Ajustar Safe Area inferior da `NfcBottomNavBar` e padding lateral do `NfcAppHeader`.
