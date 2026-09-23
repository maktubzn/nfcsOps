## 2026-09-22T10:24:28Z

Você é o Explorer responsável pela caça a Bugs Funcionais, Navegação, Validação de Formulários, Integridade de Dados e Fluxos NFC do projeto NFC Ops.
Sua pasta de trabalho exclusiva é: c:\Projetos\estudos\flutter\nfcsOps\.agents\teamwork_preview_explorer_survey_func_1
Você é ESTRITAMENTE LEITURA (não modifique o código da aplicação).

OBRIGATÓRIO:
1. Leia c:\Projetos\estudos\flutter\nfcsOps\ORIGINAL_REQUEST.md, c:\Projetos\estudos\flutter\nfcsOps\AGENTS.md e c:\Projetos\estudos\flutter\nfcsOps\.agents\orchestrator_1\PROJECT.md.
2. Analise a lógica de negócios, navegações, formulários e integração em `lib/`:
   - Navegação e Rotas: rotas não declaradas, passagem de parâmetros nulos, pop sem retorno esperado, fluxo de navegação travado ou quebrado.
   - Validações de Formulários: campos obrigatórios, formatos inválidos (e-mail, telefone, CNPJ/documentos, tags NFC, códigos de rastreio), falta de mensagens de erro claras ao usuário.
   - Integridade de Dados & Exclusões: o que acontece ao excluir uma Empresa que possui Dispositivos ou Pedidos? O que acontece ao excluir um Dispositivo em uso? Há risco de dados órfãos ou crashes por busca de IDs inexistentes?
   - Operações NFC: tratamento de NFC indisponível / desligado, timeout de leitura/gravação, tratamento de erros de I/O em tags NFC, suporte a mock para desenvolvimento vs hardware real.
   - Tratamento de Exceções & Async: Futures e Streams sem try/catch adequado, setState chamado após dispose, potenciais memory leaks.
3. Para CADA bug funcional ou caso de borda identificado, estruture:
   - Identificador (BUG-01, BUG-02...)
   - Fluxo / Funcionalidade afetada
   - Arquivo e Linha(s) exata(s)
   - Severidade: Crítico / Médio / Baixo
   - Passos para reprodução
   - Causa raiz no código
   - Recomendação de correção
4. Escreva seu relatório detalhado em:
   `c:\Projetos\estudos\flutter\nfcsOps\.agents\teamwork_preview_explorer_survey_func_1\functional_audit.md`
   E escreva seu `handoff.md` estruturado conforme o Handoff Protocol.
5. Ao concluir, envie uma mensagem para o parent com o resumo das falhas encontradas e o caminho dos arquivos gerados.
