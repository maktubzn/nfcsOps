## 2026-09-22T10:34:20Z
Você é o Worker responsável pela implementação da Milestone M2: Eliminação Definitiva de Seed Mockado, Operação com Base Real e Estabilidade de Testes (R1 e R5 do NFC Ops).
Sua pasta de trabalho exclusiva é: c:\Projetos\estudos\flutter\nfcsOps\.agents\teamwork_preview_worker_clean_base_1

MANDATORY INTEGRITY WARNING:
DO NOT CHEAT. All implementations must be genuine. DO NOT hardcode test results, create dummy/facade implementations, or circumvent the intended task. A auditor will independently verify your work. Integrity violations WILL be detected and your work WILL be rejected.

DOCUMENTOS DE ENTRADA OBRIGATÓRIOS:
1. Leia atentamente:
   - `c:\Projetos\estudos\flutter\nfcsOps\ORIGINAL_REQUEST.md`
   - `c:\Projetos\estudos\flutter\nfcsOps\AGENTS.md`
   - `c:\Projetos\estudos\flutter\nfcsOps\.agents\teamwork_preview_explorer_survey_seed_1\seed_analysis.md`
   - `c:\Projetos\estudos\flutter\nfcsOps\.agents\orchestrator_1\AUDIT_REPORT.md`

SUAS TAREFAS DE IMPLEMENTAÇÃO:
1. **Desacoplamento de Seed e Higienização**:
   - Em `lib/core/repositories/in_memory_repositories.dart`:
     - Alterar os construtores de `InMemoryCompanyRepository`, `InMemoryServiceRepository`, `InMemoryDeviceRepository`, `InMemoryOrderRepository` para terem fallback `?? const []` quando `initial*` for nulo (não usar mais `SeedData.*`).
     - Em `clock`: usar `clock = clock ?? DateTime.now;` em vez de `SeedData.fixedDate`.
     - Em `MockHealthCheckService`: usar `DateTime.now()` em vez de `SeedData.fixedDate`.
     - Em `InMemoryAuthRepository`: inicializar sem forçar usuário estático ou usar perfil configurável/vazio por padrão.
     - Remover import `seed_data.dart` de `in_memory_repositories.dart`.
   - Em `lib/core/fixtures/seed_data.dart`:
     - Limpar todas as listas fictícias estáticas para listas vazias (`static const List<Company> companies = [];`, `services = [];`, `devices = [];`, `orders = [];`).
2. **Eliminar Mock Hardcoded na UI de Estoque**:
   - Em `lib/features/inventory/presentation/inventory_screen.dart` (linhas 326–347):
     - Remover o card fixo estático `"Estoque baixo • Adesivos: 3"` ou torná-lo condicional aos dados reais (`if (allDevices.isNotEmpty && lowStockDevices <= 3)`). Em base vazia, nunca deve ser exibido.
3. **Refinar Empty States das 5 Telas Principais**:
   - **Dashboard (`dashboard_screen.dart`)**:
     - Se `totalServices == 0`, a razão de saúde não deve reportar "100% saudáveis". Exibir estado neutro "Nenhum serviço monitorado" ou ratio 0.0 sem anel verde de falso positivo.
     - No botão "Testar serviços", validar se há serviços antes de tentar rodar.
   - **Empresas (`companies_screen.dart`)**:
     - Quando `allCompanies.isEmpty`, exibir um empty state acolhedor e visual com título "Nenhuma empresa cadastrada", descrição orientando o cadastro da primeira parceira e botão de ação `+ Cadastrar Empresa` navegando para `/companies/new`.
   - **Central de Saúde (`health_center_screen.dart`)**:
     - Quando `services.isEmpty`, substituir a mensagem "Todos os serviços saudáveis" por "Nenhum serviço cadastrado para monitoramento".
   - **Inventário e Pedidos**:
     - Garantir que exibam seus empty states limpos com ação para criar o primeiro item.
4. **Cópia do Relatório de Auditoria para a Raiz**:
   - Copiar o arquivo `c:\Projetos\estudos\flutter\nfcsOps\.agents\orchestrator_1\AUDIT_REPORT.md` para a raiz do workspace em `c:\Projetos\estudos\flutter\nfcsOps\AUDIT_REPORT.md`.
5. **Adaptação dos Testes em `test/` (R5)**:
   - Os testes unitários e de widget que dependiam do seed em memória devem ser adaptados para passar 100%:
     - `test/fixtures_test.dart`: Validar regras de base limpa (repositórios vazios por padrão).
     - `test/repositories_test.dart`: Fornecer fixtures pontuais dentro do teste ou via `setUp` para os testes de busca por nome e checklist RB-007, e testar que a base inicia limpa.
     - `test/dashboard_screen_test.dart`: Testar Dashboard com 0 empresas/0 serviços e com itens inseridos.
     - `test/companies_screen_test.dart`: No `setUp`, inserir 2-3 empresas de teste para validar os filtros de busca/cidade, e validar o novo Empty State de base zerada.
     - `test/company_detail_screen_test.dart`: Criar empresa e serviços de teste no `setUp`.
     - `test/fixes_verification_test.dart`: Criar dispositivo de teste antes da busca na linha 138.
     - Testes do harness de captura (`capture_s01` a `s05`): injetar dados se necessário ou verificar que passam.
6. **Verificação Técnica Rigorosa**:
   - Executar `dart analyze lib test` e garantir ZERO erros ou advertências.
   - Executar `flutter test` e garantir que TODOS os testes passem com 100% de sucesso.
7. **Handoff e Relatório**:
   - Escrever `c:\Projetos\estudos\flutter\nfcsOps\.agents\teamwork_preview_worker_clean_base_1\handoff.md` contendo:
     - Arquivos modificados e resumo das alterações
     - Saídas completas dos comandos de análise e teste
     - Confirmação do encerramento com sucesso
   - Enviar mensagem de conclusão para o parent orchestrator.
