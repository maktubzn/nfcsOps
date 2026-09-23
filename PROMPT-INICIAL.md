# Prompt inicial para o Antigravity

Você vai implementar o NFC Ops em Flutter neste projeto: C:/Projetos/estudos/flutter/nfcsOps.

Leia AGENTS.md, harness/START-HERE.md, harness/VISUAL-CONTRACT.md, harness/FUNCTIONAL-CONTRACT.md e harness/FIREBASE.md. Leia o PRD_NFC_Ops_Profissional.md como requisitos de produto; a stack agora é Flutter, não React. Consulte as notas em C:/Projetos/cerebro/projetos/nfcsOps.

Inicie com python harness/runner.py status e python harness/runner.py next. Execute somente a unidade atual. Abra a prancha real antes de especificar; leia o prompt individual da tela. Comece pela fundação e depois S01, S02, S03 e S04 da imagem 01. Só avance à imagem 02 após aprovação das quatro telas anteriores. Repita para as cinco pranchas.

Quero reprodução fiel, não uma reinterpretação. Ative um revisor visual independente com .agents/agents/nfc-visual-reviewer.md e um revisor funcional com .agents/agents/nfc-functional-reviewer.md. Eles devem receber referência, captura real, especificação, hash da implementação e evidências. Não aceite uma tela por parecer semelhante. Compare lado a lado, sobreposição e diferenças, apontando coordenadas e correções. Mantenha a identidade visual das imagens.

Cada ação deve funcionar de verdade: navegação, validação, persistência, busca, filtros, login, QR, estoque, pedidos, monitoramento e configurações. Implemente os estados de carregamento, vazio, erro, sucesso, offline e permissão negada onde aplicáveis. Não use callbacks vazios, telas falsas, resultados inventados ou dados de demonstração no modo real.

Use o Firebase configurado em config/firebase.local.json e exatamente o databaseId documentado. Primeiro valide em emuladores. Ao precisar de login Firebase/Google, abra o fluxo e aguarde EU entrar; não preencha credenciais, não selecione minha conta por mim e não trate timeout como autorização. Login na CLI não substitui login no aplicativo nem autorização users/{uid}. Não crie outro projeto/banco nem use (default) por conveniência.

Para cada unidade: begin → especificar → implementar → rodar → capturar → revisar → corrigir → submit. Preencha o template de evidências apenas com fatos observados. Continue automaticamente quando aprovado; se falhar, retorne à mesma tela. Máximo três correções por unidade; ao esgotar, registre causa e bloqueio, sem reduzir a exigência. Login humano pendente deve pausar apenas o trabalho dependente, preservando estado.

Atualize as notas de progresso no Obsidian por marco. Ao final execute 99-INTEGRACAO com regressão das vinte telas, fluxos F01–F04 aplicáveis ao MVP, build e verificação real autorizada do banco. Entregue relatório com evidências, plataformas verificadas e limitações reais. Não publique nem faça mudanças destrutivas em produção.
