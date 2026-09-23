# NFC Ops — contrato do projeto
Leia `harness/START-HERE.md` antes de implementar. O pedido de preparação deixou Flutter vazio; só o prompt inicial do usuário no Antigravity inicia a implementação.
- Prioridade: pedido atual > regras deste projeto > requisitos funcionais do PRD > referências visuais > sugestões de skills.
- Flutter/Dart substituem a stack React do PRD. Alvos: web mobile-first e Android; iOS preparado, validação requer macOS.
- Uma tela por vez, na ordem do manifesto. Não saltar da prancha 1 para a 2 com critérios pendentes. Suportes funcionais compartilhados podem ser implementados antes da tela correspondente; nenhuma navegação pode terminar em placeholder no aceite.
- Use `python harness/runner.py next`. Não editar estado para simular progresso.
- Executor e revisor visual são papéis separados. Usuário autoriza agente de revisão independente; leitura e relatórios apenas. Não reverter trabalho de outros agentes.
- Nenhum botão pode ser aprovado com callback vazio, toast substituindo uma ação, dado de produção simulado ou rota incompleta.
- Comparar capturas reais da aplicação a referências; não incorporar a screenshot como tela ou conteúdo de interface.
- No máximo três ciclos de correção por unidade, e no máximo duas tentativas da mesma abordagem. Depois registrar bloqueio com evidências, sem reduzir critérios nem fingir aprovação.
- Firebase: ler `harness/FIREBASE.md`. Usar exatamente o banco nomeado. Pausar para login humano; nunca pedir senha ou token. Não alterar regras de produção para vencer erro de permissão.
- Não publicar, fazer commit ou migrar/deletar dados externos sem pedido. Testes de escrita usam emulador; verificação real inicial é leitura mínima.
- Preservar design e PRD originais. Configuração local em `config/firebase.local.json`; nunca copiá-la para prompts, Obsidian ou logs.
