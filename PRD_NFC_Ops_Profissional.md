---
title: "PRD — NFC Ops"
version: "1.0"
status: "Draft para implementação"
owner: "Produto / Operações"
product_type: "Web App / PWA interno"
language: "pt-BR"
last_updated: "2026-09-20"
stack_target: "React + TypeScript + Firebase"
---

# PRD — NFC Ops

> **Nome provisório:** NFC Ops  
> **Tipo de produto:** sistema interno de operação e gestão de soluções NFC/QR para negócios locais  
> **Plataforma inicial:** Web App responsivo / PWA, mobile-first  
> **Stack alvo:** React + TypeScript + Firebase  
> **Objetivo deste documento:** servir como fonte única de verdade para design, geração de telas, desenvolvimento, modelagem do Firebase, QA e evolução futura do produto.

---

# 1. Resumo executivo

O **NFC Ops** será o sistema operacional interno de um negócio que vende soluções físicas e digitais para comerciantes locais usando NFC + QR Code.

O negócio poderá vender serviços como:

- Google Reviews;
- Instagram;
- WhatsApp;
- cardápio;
- catálogo;
- agendamento;
- localização;
- Wi-Fi;
- site;
- cartão digital;
- Pix;
- feedback;
- kits personalizados.

O sistema não deve ser apenas um cadastro de clientes. Ele deve controlar o ciclo completo:

```text
Prospecção
  ↓
Empresa
  ↓
Serviços contratados
  ↓
Pedido
  ↓
Produção
  ↓
NFC + QR
  ↓
Testes
  ↓
Entrega
  ↓
Monitoramento
  ↓
Manutenção
  ↓
Upsell / recorrência
```

A primeira versão será **interna**, usada pelo operador do negócio.

No futuro, a mesma infraestrutura poderá evoluir para:

- links dinâmicos próprios;
- analytics;
- portal do cliente;
- mensalidades;
- gestão multiunidade;
- automações.

---

# 2. Por que este produto existe

Sem um sistema próprio, a operação tende a ficar distribuída entre:

- WhatsApp;
- planilhas;
- links salvos;
- arquivos de arte;
- anotações;
- memória do operador;
- etiquetas físicas.

Isso cria riscos operacionais:

1. entregar uma placa com link errado;
2. perder o vínculo entre placa física e cliente;
3. não saber quais serviços uma empresa possui;
4. não saber se um link parou de funcionar;
5. esquecer de testar NFC ou QR antes da entrega;
6. perder histórico de alterações;
7. não enxergar oportunidades de upsell;
8. aumentar retrabalho conforme a carteira cresce.

O NFC Ops deverá reduzir esses riscos e permitir que uma operação pequena cresça de dezenas para centenas de clientes sem perder controle.

---

# 3. Visão do produto

## 3.1 Declaração de visão

> **Centralizar, testar e operar toda a infraestrutura NFC/QR de clientes locais em um único sistema simples, rápido e confiável.**

## 3.2 Princípios

### P1 — NFC é meio, não o produto final

O comerciante compra praticidade, reputação, presença digital e facilidade de contato.

### P2 — Poucos toques

As ações mais usadas devem estar a 1–3 interações de distância.

### P3 — Mobile primeiro

O sistema deve funcionar muito bem durante:

- visitas presenciais;
- instalação;
- teste de placa;
- entrega;
- atendimento pelo celular.

### P4 — Prevenir erro antes de corrigir

Testes, validações e checklists fazem parte do fluxo principal.

### P5 — Monitorar após a entrega

A responsabilidade operacional não acaba quando a placa é instalada.

### P6 — Crescer em camadas

Não construir um SaaS completo antes de validar o negócio.

---

# 4. Objetivos

## 4.1 Objetivos do usuário

O operador deve conseguir:

- encontrar qualquer cliente rapidamente;
- saber quais serviços ele possui;
- abrir, copiar e editar cada destino;
- gerar QR Codes corretos;
- saber qual dispositivo físico pertence a quem;
- testar links individualmente ou em lote;
- identificar links problemáticos;
- acompanhar estoque;
- registrar pedidos;
- concluir checklist antes da entrega;
- visualizar pendências;
- oferecer serviços adicionais.

## 4.2 Objetivos do negócio

- reduzir retrabalho;
- reduzir erro de configuração;
- aumentar velocidade de atendimento;
- aumentar ticket médio;
- estimular venda de kits;
- criar base para receita recorrente;
- tornar o hardware uma porta de entrada para software;
- construir histórico operacional útil.

## 4.3 Métricas de sucesso iniciais

| Métrica | Meta inicial |
|---|---:|
| Serviços com link válido no momento da entrega | 100% |
| Produtos entregues com checklist completo | 100% |
| Dispositivos físicos sem empresa/serviço identificado após entrega | 0 |
| Links ativos em estado saudável | > 95% |
| Tempo para localizar um cliente | < 10 s |
| Tempo para localizar um serviço de um cliente | < 15 s |
| Tempo para registrar nova empresa + primeiro serviço | < 3 min |
| Erros de QR/NFC descobertos somente após entrega | < 2% |

---

# 5. Fora de escopo do MVP

Não implementar na V1:

- aplicativo nativo iOS;
- aplicativo nativo Android;
- gravação NFC diretamente pelo navegador;
- ERP completo;
- emissão de NF;
- gateway de pagamento;
- automação de WhatsApp;
- CRM de prospecção completo;
- fidelidade/pontos;
- IA complexa;
- analytics avançado de NFC;
- portal do cliente;
- billing recorrente;
- integração profunda com Google Business Profile;
- busca fuzzy avançada estilo Elasticsearch/Algolia.

---

# 6. Usuários e permissões

## 6.1 Administrador — V1

Acesso total.

Pode:

- criar e editar empresas;
- criar serviços;
- alterar URLs;
- gerar QR;
- cadastrar dispositivos;
- movimentar estoque;
- executar testes;
- criar pedidos;
- alterar status;
- visualizar histórico;
- configurar catálogo;
- visualizar alertas.

## 6.2 Vendedor — futuro

Pode:

- cadastrar empresa;
- criar pedido;
- consultar catálogo;
- consultar empresas atribuídas;
- registrar observações.

Não pode:

- alterar configurações críticas;
- excluir histórico;
- alterar regras globais.

## 6.3 Cliente — futuro

Acesso restrito à própria organização.

Pode, conforme plano:

- atualizar destinos permitidos;
- visualizar QR;
- ver analytics;
- consultar serviços;
- atualizar dados básicos.

---

# 7. Catálogo de serviços

O catálogo deverá ser configurável, mas a aplicação deverá nascer com tipos padrão.

| Tipo | Código | Destino típico | Prioridade V1 | Monitoramento |
|---|---|---|---:|---|
| Google Reviews | `google_review` | link direto de avaliação | Alta | Sim |
| Instagram | `instagram` | perfil | Alta | Sim |
| WhatsApp | `whatsapp` | conversa/link wa.me | Alta | Sim |
| Cardápio | `menu` | URL/PDF/menu | Alta | Sim |
| Catálogo | `catalog` | site/PDF/catálogo | Alta | Sim |
| Agendamento | `booking` | agenda/WhatsApp/site | Alta | Sim |
| Localização | `maps` | Google Maps | Média | Sim |
| Site | `website` | domínio do cliente | Média | Sim |
| Wi‑Fi | `wifi` | QR/landing/instrução | Média | Parcial |
| Cartão digital | `digital_card` | página de contato | Média | Sim |
| Pix | `pix` | página/QR específico | Média | Parcial |
| Feedback | `feedback` | formulário | Média | Sim |
| Fidelidade | `loyalty` | sistema próprio | Futuro | Futuro |

---

# 8. Recomendações por nicho

O sistema deverá poder sugerir serviços ao cadastrar a categoria da empresa.

## Oficina / estética automotiva

Recomendados:

- Google Reviews;
- WhatsApp;
- localização;
- catálogo/serviços.

## Barbearia / salão

Recomendados:

- Google Reviews;
- Instagram;
- WhatsApp;
- agendamento.

## Restaurante / cafeteria

Recomendados:

- Google Reviews;
- cardápio;
- Instagram;
- Wi‑Fi.

## Pet shop

Recomendados:

- Google Reviews;
- WhatsApp;
- Instagram;
- agendamento.

## Clínica / dentista

Recomendados:

- Google Reviews;
- agendamento;
- WhatsApp;
- localização.

## Pousada / hotel

Recomendados:

- Google Reviews;
- Instagram;
- Wi‑Fi;
- localização.

Essas recomendações são comerciais e não devem adicionar serviços automaticamente.

---

# 9. Arquitetura de navegação

## 9.1 Mobile

Bottom navigation:

```text
[ Início ] [ Empresas ] [ + ] [ Estoque ] [ Mais ]
```

O botão central abre ações rápidas:

- Nova empresa;
- Novo serviço;
- Novo pedido;
- Novo dispositivo.

## 9.2 Desktop

Sidebar:

```text
Dashboard
Empresas
Serviços
Saúde
Pedidos
Estoque
Atividades
Configurações
```

---

# 10. Sistema visual e UX

## 10.1 Direção visual

- B2B moderno;
- limpo;
- operacional;
- confiável;
- baixa carga cognitiva;
- sem excesso de gráficos;
- sem visual “gamer”;
- sem efeitos decorativos que atrapalhem leitura.

## 10.2 Estrutura

- grid de 8 px;
- cards com raio moderado;
- hierarquia clara;
- áreas clicáveis grandes;
- listas com informação escaneável;
- ícone + texto para ações críticas;
- status com cor + rótulo;
- ações destrutivas sempre confirmadas.

## 10.3 Acessibilidade

Meta: **WCAG 2.2 AA**.

Regras internas:

- targets de toque: preferencialmente ≥ 44 × 44 px;
- nunca depender somente de cor;
- foco visível;
- contraste suficiente;
- labels sempre associados aos inputs;
- erro exibido em texto;
- suporte completo a teclado no desktop;
- ícones críticos com label acessível;
- animações curtas e não essenciais.

## 10.4 Estados semânticos

```text
🟢 Saudável
🟡 Atenção
🔴 Erro
⚪ Verificação manual
🔵 Em produção
⚫ Inativo
```

---

# 11. Mapa de telas

| ID | Rota sugerida | Tela | Prioridade |
|---|---|---|---:|
| S01 | `/login` | Login | Must |
| S02 | `/` | Dashboard | Must |
| S03 | `/companies` | Empresas | Must |
| S04 | `/companies/new` | Nova empresa | Must |
| S05 | `/companies/:id` | Detalhe da empresa | Must |
| S06 | `/companies/:id/edit` | Editar empresa | Must |
| S07 | `/services/:id` | Detalhe do serviço | Must |
| S08 | `/services/:id/edit` | Editar serviço | Must |
| S09 | `/services/:id/qr` | QR Code | Must |
| S10 | `/health` | Central de saúde | Must |
| S11 | `/devices` | Estoque/dispositivos | Must |
| S12 | `/devices/:id` | Detalhe do dispositivo | Must |
| S13 | `/orders` | Pedidos | Should |
| S14 | `/orders/:id` | Detalhe do pedido | Should |
| S15 | `/activity` | Atividades | Should |
| S16 | `/settings` | Configurações | Should |

---

# 12. Especificação das telas

## S01 — Login

### Objetivo

Permitir acesso seguro ao sistema.

### Componentes

- logo/nome;
- texto curto;
- botão “Entrar com Google”;
- feedback de erro.

### Regra

Somente usuários autorizados poderão entrar, mesmo possuindo conta Google válida.

### Aceite

- login funciona;
- usuário não autorizado é bloqueado;
- sessão persiste;
- logout funciona.

---

## S02 — Dashboard

### Objetivo

Mostrar situação geral da operação.

### Bloco superior

```text
Bom dia

18 empresas
47 serviços ativos
3 pedidos pendentes
1 problema crítico
```

### Cards

**Saúde dos serviços**

```text
97% saudáveis
143 OK
3 atenção
1 erro
```

**Pedidos**

- aguardando;
- produção;
- testes;
- prontos.

**Estoque**

- disponíveis;
- reservados;
- baixo estoque.

**Pendências**

- link com erro;
- pedido aguardando teste;
- produto pronto para entrega.

### Ações rápidas

- Nova empresa;
- Testar serviços;
- Ver problemas;
- Novo pedido;
- Novo dispositivo.

### Aceite

O operador deve entender em menos de 5 segundos se existe problema que exige atenção.

---

## S03 — Empresas

### Componentes

- busca;
- filtros;
- botão nova empresa;
- cards/linhas de empresas.

### Resultado

```text
Auto Center Silva
Oficina • Barueri
4 serviços
🟢 Ativo
```

### Filtros

- status;
- categoria;
- cidade;
- serviço contratado.

### Busca MVP

Suportar:

- nome/prefixo;
- telefone normalizado;
- código interno.

Busca fuzzy não é requisito inicial.

---

## S04 — Nova empresa

### Campos

Obrigatórios:

- nome;
- categoria;
- status.

Opcionais:

- responsável;
- telefone;
- WhatsApp;
- e-mail;
- endereço;
- cidade;
- UF;
- logo;
- observações.

### Após salvar

Oferecer:

```text
Empresa criada.

[ Adicionar primeiro serviço ]
[ Ir para empresa ]
```

---

## S05 — Detalhe da empresa

### Cabeçalho

- logo;
- nome;
- categoria;
- status;
- contato;
- ações rápidas.

### Tabs

1. Visão geral
2. Serviços
3. Dispositivos
4. Pedidos
5. Histórico

### Serviços

```text
⭐ Google Reviews
🟢 Saudável
Último teste: hoje 13:42
[ Abrir ] [ Testar ]

📸 Instagram
🟡 Atenção
Último teste: hoje 13:40
[ Ver problema ]
```

### CTA

`+ Adicionar serviço`

### Ação em lote

`Testar todos os serviços`

---

## S07 — Detalhe do serviço

### Mostrar

- tipo;
- empresa;
- status comercial;
- destino;
- URL dinâmica — quando existir;
- QR;
- dispositivo associado;
- saúde;
- última verificação;
- última alteração.

### Ações

- Abrir destino;
- Copiar;
- Testar agora;
- Editar;
- Ver QR;
- Associar dispositivo;
- Histórico;
- Desativar.

---

## S08 — Editar serviço

### Campos

- tipo;
- nome interno;
- destino;
- status;
- observação.

### Comportamento ao salvar

1. validar sintaxe;
2. persistir;
3. disparar health check;
4. mostrar resultado;
5. registrar atividade.

### Resultado

```text
Destino atualizado.

🟢 Link testado e funcionando.
```

ou

```text
Destino salvo.

🟡 Não foi possível confirmar automaticamente.
Verificação manual recomendada.
```

---

## S09 — QR Code

### Mostrar

- preview;
- URL codificada;
- tipo de serviço;
- empresa.

### Ações

- Baixar PNG;
- Baixar SVG;
- Copiar URL;
- Abrir URL;
- Regenerar visualmente.

### Regras

- quiet zone obrigatória;
- contraste alto;
- versão vetorial disponível;
- QR deve codificar exatamente o destino atual definido para impressão.

---

## S10 — Central de saúde

### Topo

```text
Saúde geral: 97%

🟢 143 saudáveis
🟡 3 atenção
🔴 1 erro
⚪ 2 manuais
```

### Filtros

- empresa;
- status;
- tipo de serviço;
- última verificação.

### Lista de problemas

```text
Auto Center Silva
WhatsApp
🔴 3 falhas consecutivas
Último teste: 13:42

[ Abrir serviço ]
[ Testar novamente ]
```

### Ações

- Testar problemas;
- Testar tudo;
- Marcar verificação manual concluída.

---

## S11 — Estoque/dispositivos

### Resumo

- Em estoque;
- Reservados;
- Em produção;
- Instalados;
- Defeituosos.

### Busca

- código interno;
- empresa;
- lote;
- tipo.

### Exemplo

```text
NFC-00142
Placa acrílica
NTAG213
🟢 Em estoque
```

---

## S12 — Dispositivo

### Campos

- código;
- tipo físico;
- chip;
- fornecedor;
- lote;
- custo;
- empresa;
- serviço;
- status;
- teste físico;
- instalação.

### Ações

- Associar;
- Reservar;
- Marcar em produção;
- Executar checklist;
- Marcar defeituoso;
- Substituir.

---

## S13/S14 — Pedidos

### Campos

- empresa;
- itens;
- quantidades;
- valor;
- desconto;
- status de pagamento;
- status operacional;
- previsão;
- notas.

### Fluxo

```text
Orçamento
→ Aguardando aprovação
→ Aprovado
→ Em produção
→ Aguardando testes
→ Pronto
→ Entregue
```

---

# 13. Fluxos principais

## F01 — Cadastrar empresa e primeiro serviço

```text
Dashboard
→ Nova empresa
→ Dados
→ Salvar
→ Adicionar serviço
→ Selecionar tipo
→ Inserir link
→ Validar
→ Health check
→ Gerar QR
→ Concluído
```

## F02 — Preparar placa

```text
Empresa
→ Serviço
→ Associar dispositivo
→ Selecionar item do estoque
→ Em produção
→ Gravar NFC externamente
→ Testar NFC
→ Testar QR
→ Checklist
→ Pronto
```

## F03 — Corrigir link quebrado

```text
Dashboard alerta
→ Central de saúde
→ Serviço
→ Testar novamente
→ Confirmar erro
→ Editar destino
→ Salvar
→ Teste automático
→ Saudável
```

## F04 — Alteração futura com redirect dinâmico

```text
Cliente muda Instagram
→ Empresa
→ Serviço Instagram
→ Editar destinationUrl
→ Salvar
→ Redirect continua igual
→ NFC e QR físicos continuam iguais
```

---

# 14. Saúde dos links

## 14.1 Objetivo

Detectar links inválidos ou destinos potencialmente quebrados antes que o cliente perceba.

## 14.2 Tipos de teste

### A. Ao cadastrar

Executar imediatamente.

### B. Ao editar

Executar imediatamente.

### C. Manual

Botão `Testar agora`.

### D. Empresa inteira

Botão `Testar todos`.

### E. Automático

Rodar uma vez ao dia para serviços ativos.

---

# 15. Estratégia de health check

O health check não deve confundir:

- “URL válida”;
- “servidor alcançável”;
- “perfil real existe”;
- “plataforma permite bot”.

São níveis diferentes.

## 15.1 Etapas

1. parse da URL;
2. exigir protocolo permitido;
3. validar hostname;
4. aplicar proteção SSRF;
5. executar request com timeout;
6. acompanhar redirects dentro de limite;
7. registrar status HTTP;
8. registrar URL final;
9. registrar latência;
10. aplicar regra específica por provedor;
11. atualizar resumo atual do serviço;
12. armazenar histórico.

## 15.2 Estados

### `healthy`

Resposta compatível com expectativa.

### `warning`

Exemplos:

- primeira falha;
- lentidão;
- redirect inesperado;
- status inconclusivo.

### `error`

Exemplos:

- URL inválida;
- domínio indisponível;
- falhas repetidas;
- timeout repetido.

### `manual`

A plataforma não permite diagnóstico confiável automatizado.

---

# 16. Falsos positivos

Google, Instagram, WhatsApp e outros serviços podem:

- bloquear bots;
- alterar resposta por região;
- exigir JavaScript;
- redirecionar;
- aplicar rate limiting.

Logo:

```text
1 falha → warning
2 falhas consecutivas → warning
3 falhas consecutivas → error
```

O número deve ser configurável.

O sistema nunca deve afirmar que “o perfil foi excluído” apenas porque um request automatizado falhou.

---

# 17. Segurança do health checker

Uma função que acessa URLs fornecidas pelo usuário cria risco de SSRF.

Requisitos:

- permitir somente `https://` no fluxo padrão;
- bloquear `localhost`;
- bloquear IPs privados;
- bloquear metadata endpoints de cloud;
- validar DNS;
- limitar redirects;
- aplicar timeout;
- limitar tamanho da resposta;
- rate limiting;
- executar somente para usuários autorizados;
- logs sem dados sensíveis desnecessários.

Para serviços conhecidos, usar validadores específicos.

Exemplos:

```text
Instagram → hostname esperado
WhatsApp → wa.me / api.whatsapp.com quando aplicável
Google → domínios conhecidos, sem depender exclusivamente disso
```

---

# 18. Teste físico de NFC e QR

Monitoramento remoto não confirma integridade física.

## Checklist obrigatório

```text
[ ] Arte correta
[ ] Logo correta
[ ] URL correta
[ ] QR abre destino esperado
[ ] NFC abre destino esperado
[ ] NFC e QR apontam ao mesmo serviço
[ ] Dispositivo associado ao cliente correto
[ ] Acabamento aprovado
```

### Resultado

- aprovado;
- reprovado;
- não testado.

### Dados

- testado em;
- testado por;
- observação.

---

# 19. Links estáticos e dinâmicos

## 19.1 V1 — Estático

```text
NFC → destinationUrl
QR  → destinationUrl
```

Vantagem: implantação rápida.

Desvantagem: QR impresso não pode mudar.

## 19.2 V2/V3 — Redirect próprio

```text
NFC ──┐
      ├── https://go.dominio.com/a8K2
QR ───┘
              ↓
       destinationUrl
```

### Requisitos

- código curto não sequencial;
- serviço ativo/inativo;
- destino editável;
- redirect rápido;
- logs mínimos;
- fallback de erro amigável;
- proteção contra destino inseguro.

---

# 20. Analytics futuro

Quando o redirect próprio existir, registrar eventos.

## Métricas

- acessos totais;
- por empresa;
- por serviço;
- por dia;
- última utilização;
- destino;
- dispositivo/navegador quando permitido.

Não prometer distinção NFC vs QR se ambos utilizarem exatamente a mesma URL e não houver mecanismo específico de diferenciação.

---

# 21. Arquitetura técnica

## 21.1 Front-end

- React;
- TypeScript;
- PWA;
- React Router;
- biblioteca de UI consistente;
- validação de formulários por schema;
- estado remoto orientado a queries.

## 21.2 Firebase

### Authentication

Login Google no MVP.

Criar autorização de aplicação separada da autenticação.

Exemplo:

```text
Autenticou com Google
        ↓
Existe users/{uid} ativo?
        ↓
Sim → entra
Não → acesso negado
```

### Firestore

Banco operacional principal.

### Storage

- logos;
- artes;
- PDFs;
- anexos.

### Hosting

Hospedagem do SPA/PWA.

### Cloud Functions 2nd gen

- health check;
- rotinas privilegiadas;
- redirects futuros;
- automações;
- tarefas administrativas.

### Cloud Scheduler

- health check diário;
- limpeza/retention quando necessário.

### App Check

Habilitar em produção para reduzir abuso de recursos expostos ao cliente web.

---

# 22. Estratégia de ambientes

Recomendado:

```text
nfc-ops-dev
nfc-ops-prod
```

Opcional futuramente:

```text
nfc-ops-staging
```

Nunca testar regras destrutivas diretamente em produção.

Usar Firebase Emulator Suite no desenvolvimento.

---

# 23. Modelo Firestore

## 23.1 Decisão estrutural

Usar **coleções de primeiro nível para entidades operacionais consultadas globalmente**, e subcoleções para históricos que crescem continuamente.

Estrutura:

```text
users/{uid}

companies/{companyId}

services/{serviceId}
  └─ healthChecks/{checkId}

devices/{deviceId}

orders/{orderId}

activities/{activityId}

serviceCatalog/{serviceType}

settings/{document}

redirects/{shortCode}          # futuro
```

---

# 24. Schema — users

```ts
type UserRole = "admin" | "seller" | "client";

interface User {
  uid: string;
  email: string;
  displayName?: string;
  photoUrl?: string;

  role: UserRole;
  active: boolean;

  companyIds?: string[]; // futuro para client

  createdAt: Timestamp;
  updatedAt: Timestamp;
}
```

---

# 25. Schema — companies

```ts
type CompanyStatus = "lead" | "active" | "inactive";

interface Company {
  id: string;

  name: string;
  normalizedName: string;

  category: string;

  contactName?: string;
  phone?: string;
  normalizedPhone?: string;
  whatsapp?: string;
  email?: string;

  address?: {
    street?: string;
    number?: string;
    district?: string;
    city?: string;
    state?: string;
    zipCode?: string;
  };

  logoPath?: string;

  status: CompanyStatus;

  notes?: string;

  serviceCount: number;
  activeServiceCount: number;

  createdAt: Timestamp;
  updatedAt: Timestamp;
  createdBy: string;
  updatedBy: string;
}
```

---

# 26. Schema — services

```ts
type ServiceStatus =
  | "draft"
  | "active"
  | "paused"
  | "inactive";

type HealthStatus =
  | "unknown"
  | "healthy"
  | "warning"
  | "error"
  | "manual";

interface Service {
  id: string;

  companyId: string;

  type: string;
  customName?: string;

  destinationUrl: string;

  // futuro
  shortCode?: string;
  dynamicUrl?: string;

  status: ServiceStatus;

  health: {
    status: HealthStatus;
    lastCheckedAt?: Timestamp;
    lastSuccessAt?: Timestamp;
    httpStatus?: number;
    responseTimeMs?: number;
    finalUrl?: string;
    consecutiveFailures: number;
    lastErrorCode?: string;
  };

  qr: {
    mode: "static" | "dynamic";
    encodedUrl: string;
    lastGeneratedAt?: Timestamp;
  };

  notes?: string;

  createdAt: Timestamp;
  updatedAt: Timestamp;
  createdBy: string;
  updatedBy: string;
}
```

---

# 27. Schema — healthChecks

Subcoleção:

```text
services/{serviceId}/healthChecks/{checkId}
```

```ts
interface HealthCheck {
  id: string;

  companyId: string;
  serviceId: string;

  source:
    | "create"
    | "edit"
    | "manual"
    | "company_batch"
    | "scheduled";

  requestedUrl: string;
  finalUrl?: string;

  result:
    | "healthy"
    | "warning"
    | "error"
    | "manual";

  httpStatus?: number;
  responseTimeMs?: number;
  redirectCount?: number;

  errorCode?: string;
  errorMessage?: string;

  checkedAt: Timestamp;
}
```

### Retenção inicial

Manter histórico detalhado por 180 dias.

O resumo de saúde no documento `services` permanece indefinidamente enquanto o serviço existir.

---

# 28. Schema — devices

```ts
type DeviceStatus =
  | "stock"
  | "reserved"
  | "production"
  | "testing"
  | "ready"
  | "installed"
  | "defective"
  | "replaced"
  | "discarded";

interface Device {
  id: string;

  internalCode: string;

  physicalType:
    | "pvc_card"
    | "acrylic_plate"
    | "sticker"
    | "other";

  chip?: "NTAG213" | "NTAG215" | "NTAG216" | "other";

  supplier?: string;
  batch?: string;
  unitCost?: number;

  companyId?: string;
  serviceId?: string;

  status: DeviceStatus;

  physicalTest?: {
    status: "not_tested" | "passed" | "failed";
    nfcPassed?: boolean;
    qrPassed?: boolean;
    testedAt?: Timestamp;
    testedBy?: string;
    notes?: string;
  };

  installedAt?: Timestamp;

  createdAt: Timestamp;
  updatedAt: Timestamp;
}
```

---

# 29. Schema — orders

```ts
type OrderStatus =
  | "quote"
  | "waiting_approval"
  | "approved"
  | "production"
  | "testing"
  | "ready"
  | "delivered"
  | "cancelled";

interface OrderItem {
  id: string;
  serviceType?: string;
  description: string;
  quantity: number;
  unitPrice: number;
  unitCost?: number;
}

interface Order {
  id: string;

  companyId: string;

  items: OrderItem[];

  subtotal: number;
  discount: number;
  total: number;

  paymentStatus:
    | "pending"
    | "partial"
    | "paid"
    | "refunded";

  status: OrderStatus;

  expectedDeliveryAt?: Timestamp;
  deliveredAt?: Timestamp;

  notes?: string;

  createdAt: Timestamp;
  updatedAt: Timestamp;
  createdBy: string;
}
```

Itens podem ficar embutidos porque um pedido típico terá poucos itens e são lidos junto do pedido.

---

# 30. Schema — activities

```ts
interface Activity {
  id: string;

  actorUid: string;

  companyId?: string;

  entityType:
    | "company"
    | "service"
    | "device"
    | "order"
    | "system";

  entityId?: string;

  action: string;

  summary: string;

  metadata?: Record<string, string | number | boolean>;

  createdAt: Timestamp;
}
```

Não armazenar segredos nem snapshots enormes em `metadata`.

---

# 31. Catálogo de serviços

```text
serviceCatalog/{serviceType}
```

Exemplo:

```ts
interface ServiceCatalogItem {
  type: string;
  name: string;
  icon: string;
  active: boolean;

  urlValidation?: {
    allowedHosts?: string[];
    preferredHosts?: string[];
  };

  suggestedCategories: string[];

  createdAt: Timestamp;
  updatedAt: Timestamp;
}
```

---

# 32. Redirects futuros

```text
redirects/{shortCode}
```

```ts
interface Redirect {
  shortCode: string;

  companyId: string;
  serviceId: string;

  destinationUrl: string;

  enabled: boolean;

  createdAt: Timestamp;
  updatedAt: Timestamp;
}
```

Não expor escrita pública.

O redirect deve ser resolvido por backend.

---

# 33. Índices previstos

## Companies

- `status + normalizedName`;
- `category + status`.

## Services

- `companyId + status`;
- `companyId + type`;
- `health.status + status`;
- `type + status`.

## Devices

- `status + physicalType`;
- `companyId + status`.

## Orders

- `companyId + createdAt desc`;
- `status + createdAt desc`.

Criar apenas os índices realmente utilizados.

---

# 34. Regras de negócio

## RB-001

Uma empresa pode possuir vários serviços do mesmo tipo somente se houver uso legítimo.

Ex.: duas unidades/links diferentes.

## RB-002

Um dispositivo físico só pode estar associado a um serviço principal por vez.

## RB-003

Um dispositivo `installed` deve possuir `companyId`.

## RB-004

Um pedido não pode ir para `ready` se possuir dispositivo com checklist físico obrigatório pendente.

## RB-005

Alterar `destinationUrl` dispara teste automático.

## RB-006

Serviço `inactive` não participa de monitoramento agendado.

## RB-007

Três falhas consecutivas podem mudar a saúde para `error`.

## RB-008

Resultado inconclusivo por bloqueio de automação deve virar `manual`, não `error`.

## RB-009

QR para impressão deve exibir explicitamente a URL que está sendo codificada antes do download.

## RB-010

Exclusão destrutiva deve exigir confirmação.

Preferir arquivamento/inativação em entidades com histórico.

---

# 35. Segurança e autorização

## 35.1 Firebase Authentication

Google Sign-In na V1.

Autenticação não significa autorização.

Usuário autenticado deve existir em `users/{uid}` e estar ativo.

## 35.2 Firestore Security Rules

Princípio:

> negar por padrão e liberar o necessário por papel.

Na V1:

- admin: acesso operacional;
- qualquer usuário desconhecido: nenhum acesso.

## 35.3 Cloud Functions

Operações que exigem segredo, rede externa ou privilégio devem ocorrer no backend.

Exemplos:

- health check;
- redirect;
- tarefas agendadas;
- deleção em cascata;
- ações administrativas.

## 35.4 Storage

Uploads devem possuir:

- autenticação;
- limite de tamanho;
- tipos MIME permitidos;
- caminho previsível;
- regras por papel.

---

# 36. Privacidade

O produto armazenará dados comerciais e de contato.

Princípios:

- coletar somente o necessário;
- permitir correção;
- registrar quem alterou dados críticos;
- evitar dados pessoais desnecessários;
- não armazenar senhas de Wi‑Fi em logs;
- não incluir credenciais em Activity Log;
- documentar política de retenção.

---

# 37. Cloud Functions previstas

## FN-01 `checkServiceHealth`

Entrada:

```ts
{
  serviceId: string
}
```

Uso:

- manual;
- create;
- edit.

Saída:

```ts
{
  status: "healthy" | "warning" | "error" | "manual";
  httpStatus?: number;
  responseTimeMs?: number;
  finalUrl?: string;
}
```

## FN-02 `checkCompanyHealth`

Entrada:

```ts
{
  companyId: string
}
```

Processa serviços ativos da empresa com limites de concorrência.

## FN-03 `scheduledHealthChecks`

Executada 1x/dia.

Deve ser:

- idempotente;
- paginada;
- tolerante a falhas;
- protegida contra execuções sobrepostas.

## FN-04 `deleteServiceSafely`

Futuro/administrativo.

Remove ou arquiva serviço e histórico conforme política.

## FN-05 `resolveRedirect`

Futuro.

```text
GET /r/:shortCode
```

Retorna redirect para destino válido ou tela de fallback.

---

# 38. Erros e mensagens

Mensagens devem explicar:

1. o que aconteceu;
2. o que o usuário pode fazer.

Ruim:

```text
Erro 500.
```

Bom:

```text
Não conseguimos testar este link agora.

O destino foi salvo, mas a plataforma bloqueou a verificação automática.

[ Abrir manualmente ]
[ Testar novamente ]
```

---

# 39. Empty states

## Empresas

```text
Nenhuma empresa cadastrada.

Cadastre seu primeiro cliente para começar a organizar serviços, placas e QR Codes.

[ Nova empresa ]
```

## Saúde

```text
Tudo certo por aqui.

Nenhum serviço precisa de atenção.
```

## Estoque

```text
Nenhum dispositivo em estoque.

[ Adicionar dispositivo ]
```

---

# 40. Loading e offline

Como PWA:

- mostrar skeletons em carregamentos;
- manter última navegação estável;
- exibir estado offline;
- nunca fingir que um dado foi salvo sem confirmação;
- ações críticas devem indicar sincronização.

Offline completo para edição não é requisito da V1.

---

# 41. Requisitos funcionais

| ID | Requisito | Prioridade |
|---|---|---|
| RF-001 | Login Google | Must |
| RF-002 | Autorizar apenas usuários cadastrados | Must |
| RF-003 | Criar empresa | Must |
| RF-004 | Editar empresa | Must |
| RF-005 | Buscar empresas | Must |
| RF-006 | Criar serviço | Must |
| RF-007 | Editar destino | Must |
| RF-008 | Abrir/copiar destino | Must |
| RF-009 | Gerar QR | Must |
| RF-010 | Baixar QR PNG/SVG | Must |
| RF-011 | Cadastrar dispositivo | Must |
| RF-012 | Associar dispositivo | Must |
| RF-013 | Gerenciar status do dispositivo | Must |
| RF-014 | Testar link individual | Must |
| RF-015 | Testar empresa inteira | Must |
| RF-016 | Health check automático diário | Should |
| RF-017 | Central de saúde | Must |
| RF-018 | Histórico de health checks | Should |
| RF-019 | Checklist físico | Must |
| RF-020 | Dashboard | Must |
| RF-021 | Pedidos | Should |
| RF-022 | Activity log | Should |
| RF-023 | Sugestões por nicho | Should |
| RF-024 | Redirect dinâmico | Future |
| RF-025 | Analytics | Future |
| RF-026 | Portal do cliente | Future |

---

# 42. Requisitos não funcionais

## RNF-001 — Performance

- tela principal deve parecer responsiva;
- consultas devem ser paginadas;
- evitar carregar coleções completas.

## RNF-002 — Segurança

- regras restritivas;
- backend para ações privilegiadas;
- validação de URL;
- proteção SSRF;
- logs de mudanças críticas.

## RNF-003 — Acessibilidade

WCAG 2.2 AA como meta.

## RNF-004 — Responsividade

Prioridade:

1. celular;
2. notebook/desktop;
3. tablet.

## RNF-005 — Escalabilidade

Suportar inicialmente:

- 1.000+ empresas;
- 10.000+ serviços;
- 10.000+ dispositivos;
- centenas de milhares de health checks.

Sem redesign estrutural obrigatório.

## RNF-006 — Observabilidade

Functions devem registrar:

- duração;
- erro;
- serviceId;
- resultado;
- sem vazar dados sensíveis.

## RNF-007 — Backup

Definir rotina de export/backup antes de operação crítica em escala.

---

# 43. Critérios de aceite do MVP

## Autenticação

- [ ] usuário autorizado consegue entrar;
- [ ] usuário não cadastrado não acessa dados;
- [ ] logout funciona.

## Empresas

- [ ] criar;
- [ ] editar;
- [ ] buscar;
- [ ] abrir detalhes.

## Serviços

- [ ] criar;
- [ ] editar link;
- [ ] abrir;
- [ ] copiar;
- [ ] visualizar saúde.

## QR

- [ ] gerar;
- [ ] visualizar URL codificada;
- [ ] baixar PNG;
- [ ] baixar SVG;
- [ ] QR testado abre destino esperado.

## Dispositivos

- [ ] cadastrar;
- [ ] alterar status;
- [ ] associar à empresa;
- [ ] associar ao serviço;
- [ ] registrar teste físico.

## Saúde

- [ ] teste manual funciona;
- [ ] resultado é persistido;
- [ ] serviço recebe status atualizado;
- [ ] falha aparece na Central de Saúde;
- [ ] empresa inteira pode ser testada;
- [ ] bloqueio de bot pode virar “manual”.

## Pedidos

- [ ] criar pedido;
- [ ] mudar status;
- [ ] impedir “pronto” quando checklist obrigatório estiver pendente.

## Mobile

- [ ] todos os fluxos principais funcionam em tela de celular;
- [ ] nenhuma ação principal exige hover;
- [ ] navegação inferior funciona.

---

# 44. Casos de teste essenciais

## CT-01

Cadastrar empresa e Google Reviews com URL válida.

**Esperado:** serviço criado + health check executado.

## CT-02

Cadastrar URL malformada.

**Esperado:** impedir salvamento ou solicitar correção.

## CT-03

Salvar URL alcançável que redireciona.

**Esperado:** registrar URL final.

## CT-04

Plataforma bloqueia bot.

**Esperado:** não classificar automaticamente como link quebrado definitivo.

## CT-05

Três falhas consecutivas.

**Esperado:** status `error`.

## CT-06

Tentar marcar pedido como pronto sem QR testado.

**Esperado:** bloquear ação e explicar pendência.

## CT-07

Associar dispositivo já instalado a outro cliente.

**Esperado:** bloquear ou exigir fluxo explícito de substituição/desassociação.

## CT-08

Usuário Google válido, mas não cadastrado no sistema.

**Esperado:** acesso negado.

---

# 45. Instrumentação do próprio produto

Eventos internos sugeridos:

```text
company_created
service_created
service_destination_changed
health_check_started
health_check_failed
health_check_recovered
device_created
device_assigned
device_test_passed
order_created
order_delivered
qr_downloaded
```

Objetivo:

- entender uso;
- encontrar gargalos;
- medir erros operacionais.

---

# 46. KPIs do negócio dentro do painel — futuro próximo

- empresas ativas;
- novos clientes/mês;
- ticket médio;
- serviços por cliente;
- pedidos no mês;
- receita;
- custo físico;
- margem estimada;
- taxa de upsell;
- serviços com problema;
- tempo médio para correção.

---

# 47. Roadmap

## V1 — Operação básica

- Auth;
- empresas;
- serviços;
- QR;
- dispositivos;
- estoque;
- health check manual;
- checklist;
- dashboard.

## V1.1 — Operação comercial

- pedidos;
- kits;
- recomendações por nicho;
- Activity Log.

## V2 — Monitoramento

- scheduler diário;
- histórico de saúde;
- central de problemas;
- alertas internos.

## V3 — Redirect dinâmico

- `go.dominio.com/{code}`;
- QR permanente;
- NFC permanente;
- alteração remota.

## V4 — Analytics

- acessos;
- relatórios;
- comparação de serviços;
- indicadores por cliente.

## V5 — Financeiro/recorrência

- planos;
- mensalidades;
- receita;
- custo;
- margem;
- cobrança integrada.

## V6 — Portal do cliente

- login;
- edição controlada;
- analytics;
- QR;
- serviços;
- plano.

---

# 48. Backlog pós-MVP

- scanner de QR administrativo;
- etiquetas internas;
- upload de arte final;
- templates de placa;
- geração de orçamento PDF;
- assinatura digital do aceite;
- notificações push;
- integração com WhatsApp Business;
- várias unidades por empresa;
- equipes/vendedores;
- tarefas;
- estoque por lote;
- custo médio;
- relatório de falhas;
- alertas de estoque baixo;
- exportação CSV;
- importação de clientes;
- dashboard de MRR;
- autoatendimento.

---

# 49. Riscos

## R01 — Escopo crescer para ERP

**Mitigação:** roadmap por versões e MVP fechado.

## R02 — Falso positivo no health check

**Mitigação:** múltiplos estados + regras por provedor + modo manual.

## R03 — Health checker ser abusado

**Mitigação:** autenticação, SSRF protection, rate limit.

## R04 — QR errado ser impresso

**Mitigação:** preview da URL + checklist obrigatório.

## R05 — NFC físico defeituoso

**Mitigação:** teste físico registrado.

## R06 — Busca Firestore ficar limitada

**Mitigação:** busca simples no MVP; mecanismo dedicado se necessário no futuro.

## R07 — Crescimento do histórico

**Mitigação:** subcoleções, paginação e política de retenção.

## R08 — Exclusão de dados com subcoleções

**Mitigação:** não depender de delete direto; usar função administrativa/cascade ou arquivar.

---

# 50. Decisões já tomadas

- produto inicial é interno;
- React + TypeScript;
- Firebase como backend;
- Firestore como banco operacional;
- PWA mobile-first;
- Google Sign-In;
- health check faz parte do produto;
- QR + NFC terão checklist físico;
- V1 pode usar URLs diretas;
- redirect próprio vem depois;
- software será desenhado para futura recorrência;
- serviço é unidade lógica central;
- dispositivo físico e serviço digital são entidades separadas.

---

# 51. Questões em aberto

Não bloqueiam a V1, mas precisam ser decididas.

1. Nome comercial final.
2. Domínio principal.
3. Paleta/identidade visual.
4. Se pedidos financeiros entram já na V1 ou V1.1.
5. Política exata de retenção do Activity Log.
6. Qual biblioteca será usada para QR.
7. Provedor de analytics de produto.
8. Limite máximo de upload de logo/arte.
9. Fornecedores físicos homologados.
10. Regras comerciais para kits e descontos.

---

# 52. Definition of Done — V1

A V1 está pronta quando um operador consegue completar sozinho este cenário:

1. entrar com Google;
2. cadastrar uma barbearia;
3. selecionar categoria;
4. adicionar Google Reviews;
5. inserir link;
6. sistema validar/testar;
7. gerar QR;
8. cadastrar uma placa NFC;
9. associá-la ao serviço;
10. executar checklist físico;
11. marcar dispositivo como pronto;
12. encontrar o cliente depois;
13. testar novamente o link;
14. visualizar eventual problema no dashboard;
15. corrigir destino;
16. registrar histórico da alteração.

Sem planilha ou ferramenta externa para controlar o vínculo operacional.

---

# 53. Referências técnicas e de produto

Este PRD foi estruturado seguindo princípios comuns de Product Requirements Documents modernos:

- propósito e resultado esperado;
- metas e métricas;
- hipóteses e escopo;
- requisitos;
- histórias/fluxos de uso;
- UX;
- critérios de aceite;
- itens fora do escopo;
- riscos e questões em aberto.

Referências consultadas:

- Atlassian — Product Requirements / PRD
  - https://www.atlassian.com/br/agile/product-management/requirements
  - https://www.atlassian.com/br/software/confluence/templates/product-requirements

- ProductPlan — Product Requirements Document
  - https://www.productplan.com/glossary/product-requirements-document

- Firebase — Cloud Firestore Data Model
  - https://firebase.google.com/docs/firestore/data-model

- Firebase — Firestore Best Practices
  - https://firebase.google.com/docs/firestore/best-practices

- Firebase — Structure Data
  - https://firebase.google.com/docs/firestore/manage-data/structure-data

- Firebase — Authentication with Google
  - https://firebase.google.com/docs/auth/web/google-signin

- Firebase — Firestore Security Rules
  - https://firebase.google.com/docs/firestore/security/get-started

- Firebase — Cloud Functions
  - https://firebase.google.com/docs/functions

- Firebase — Scheduled Functions
  - https://firebase.google.com/docs/functions/schedule-functions

- Firebase — Hosting
  - https://firebase.google.com/docs/hosting

- W3C — WCAG 2.2
  - https://www.w3.org/TR/WCAG22/

---

# 54. Resumo para designers e agentes de geração de UI

Ao gerar telas a partir deste PRD, considerar:

**Produto:** painel operacional B2B para gerenciar empresas, serviços NFC/QR, links, saúde, estoque e pedidos.

**Usuário principal:** operador do negócio em celular e notebook.

**Tom visual:** profissional, simples, rápido e confiável.

**Prioridade de UX:** localizar cliente → abrir serviço → agir.

**Entidades visuais principais:**

```text
Empresa
  ├── Serviços
  ├── Dispositivos
  ├── Pedidos
  └── Histórico
```

**Status devem ser altamente visíveis.**

**Dashboard não deve virar BI complexo.**

**A Central de Saúde deve destacar exceções, não sobrecarregar o usuário.**

**Mobile deve ser tratado como experiência principal, não adaptação do desktop.**

---

# 55. Resumo para agentes de implementação

Implementar primeiro o domínio central:

```text
Auth
↓
Companies
↓
Services
↓
Devices
↓
Health Checks
```

Depois:

```text
Orders
Activities
Scheduler
Redirects
Analytics
```

Prioridades técnicas:

1. regras de segurança;
2. modelo Firestore;
3. CRUD de empresas;
4. CRUD de serviços;
5. QR;
6. dispositivos;
7. health check manual;
8. checklist;
9. dashboard;
10. monitoramento agendado.

O sistema deve permanecer simples o suficiente para ser operado por uma pessoa, mas organizado o suficiente para crescer sem reescrever o domínio central.
