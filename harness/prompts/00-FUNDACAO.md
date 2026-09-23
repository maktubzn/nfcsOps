# 00 — Fundação (sem antecipar as vinte telas)
1. Inspecionar SDK, doctor, dispositivos, projeto vazio, PRD, manifesto e fontes. Fixar versões; não atualizar SDK global por conveniência.
2. Definir arquitetura modular Flutter, navegação, estado, repositórios, modelos e contratos backend. Registrar dependências escolhidas e motivos, origem/compatibilidade/lockfile. Não transportar código React do PRD.
3. Separar fixture visual (47 serviços, 18 empresas, data 20/09/2026) de emulador e produção. Definir todos schemas do PRD, autorização e testes negativos.
4. Medir referências e documentar tokens/crops/viewports por quadro sem alterar as imagens. Revisar divergências semânticas de imagens versus PRD.
5. Preparar infraestrutura de testes de widget/integração/golden e plano de captura real. Não aprovar somente por contagem de pixels.
6. Definir interfaces de Auth/Firestore/Storage/HealthCheck. Pacotes Firebase podem ser adicionados nesta fase executada pelo Antigravity, não estavam presentes no scaffold inicial.
7. Registrar plano de autenticação humana e banco nomeado conforme FIREBASE.md. A fundação pode passar sem login real se plano e testes de contrato/emulador forem reais; S01 e gate final não podem alegar integração real antes do login.
8. Evidências: architecture.md, calibration.md, data-contracts.md, security-plan.md, specification.md, functional-review.md e logs de analyze/test. Nenhuma tela de produto é necessária para concluir esta fundação.
