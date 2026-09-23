# 99 — Integração e entrega
Reabrir e capturar TODAS as 20 telas após a última alteração; revisar todos controles visíveis e estados, incluindo subtelas de configurações, cadastro de dispositivo, navegação Mais e catálogo. Arquivo regression.md deve mapear cada S01–S16/A01–A04 a captura fresca e caso de teste.
Executar F01–F03 do PRD; F04 dinâmico fica futuro V1 estático. Verificar persistência, concorrência, rede/negação, login/logout, deep links, dinheiro, QR PNG/SVG e regras de pronto.
Exigir Firestore no databaseId fornecido, leitura real mínima autenticada e autorização users/{uid}; login humano se necessário. Emulador não prova conexão de produção.
Health checker e diário dependem de backend real: evidenciar ambiente verificado e implantação autorizada, ou registrar bloqueio sem aprovação total. Teste físico de NFC não pode ser fabricado: se sem hardware, registrar limitação e manter prova física pendente.
Rode flutter analyze, testes unit/widget/integration e builds web e Android debug. iOS requer macOS: não alegar verificado no Windows; entrega de iOS fica explicitamente pendente se estiver no escopo de aceitação final do usuário.
Comparação visual final por revisor independente, zero pendências conhecidas. Gere release-report.md com cenários, plataforma, versões, evidências, limitações e próximos passos. Não faça deploy, commit ou publicação automaticamente.
