# Original User Request

## 2026-09-22T10:22:44Z

O usuário solicitou explicitamente: "invoke varios agentes para analisar em conjunto, quero que voce tenta encontrar erros de interface e tals documentar e me entregar para eu ver o que muda, tentar achar bugs, alias nao quero mais seed, por que tem arquivo seed? limpa ele, dados tem que ser reais. do banco"

O usuário solicitou uma análise conjunta com múltiplos agentes para varrer a aplicação NFC Ops à procura de erros de interface, quebras de layout e bugs funcionais, entregando um relatório completo e priorizado de problemas para aprovação prévia de alterações, além de eliminar definitivamente qualquer dado mockado de seed (`seed_data.dart`) para que o aplicativo passe a trabalhar exclusivamente com dados reais a partir de uma base limpa.

Working directory: c:\Projetos\estudos\flutter\nfcsOps
Integrity mode: development

## Requirements

### R1. Eliminação Definitiva de Seed Mockado e Operação com Base Real
Remover as fixtures estáticas de seed (`seed_data.dart`) que injetam dados fictícios na inicialização. O aplicativo deve iniciar com a base limpa/real, permitindo ao usuário cadastrar seus próprios dados reais (empresas, dispositivos, pedidos) e garantindo que todas as telas apresentem estados vazios (*empty states*) amigáveis e ações para criar o primeiro item.

### R2. Auditoria Colaborativa Multi-Agente de Interface (UI/UX)
Realizar uma inspeção profunda em todas as telas e fluxos do aplicativo (Acesso, Dashboard, Inventário/Estoque, Detalhes de Dispositivo/Empresa/Serviço/Pedido, Modais de NFC, Central de Saúde, Criação/Edição):
- Mapear potenciais quebras de layout e overflows em viewports estreitos (ex.: 372x870 canônico) e diferentes densidades de tela;
- Verificar espaçamentos, legibilidade, contraste, alinhamentos e comportamentos de componentes interativos (botões, listas, inputs).

### R3. Caça a Bugs Funcionais e Casos de Borda
Identificar falhas de lógica, navegações interrompidas, inconsistências de validação em formulários, comportamento ao excluir registros relacionados, e tratamento de estados de erro na leitura/gravação de chips NFC.

### R4. Relatório Consolidado de Diagnósticos e Melhorias
Elaborar um relatório estruturado e priorizado detalhando:
- Categoria e severidade do defeito (Crítico, Médio, Baixo/Cosmético);
- Tela afetada e passos para reprodução;
- Causa raiz no código e recomendação de mudança para que o usuário avalie antes de qualquer alteração visual.

### R5. Garantia de Estabilidade e Integridade do Projeto
Garantir que a limpeza do seed e ajustes não quebrem a compilação ou os testes essenciais do projeto, mantendo `dart analyze lib test` e a suíte de testes funcionais executando com sucesso.

## Acceptance Criteria

### Limpeza de Dados e Base Real
- [ ] O arquivo `seed_data.dart` é limpo/desacoplado, sem carregar empresas, serviços ou placas de mentira por padrão.
- [ ] Ao abrir o app com banco limpo, as telas de Dashboard, Empresas, Inventário, Pedidos e Saúde exibem *empty states* limpos sem falhas ou erros nulos.

### Qualidade da Auditoria e Documentação
- [ ] Relatório consolidado documentado com a lista completa de bugs, pontos de melhoria de UI e recomendações claras.
- [ ] Não realizar mudanças cosméticas não autorizadas antes da entrega do relatório para avaliação do usuário.

### Estabilidade Técnica
- [ ] `dart analyze lib test` finaliza sem erros ou advertências.
- [ ] Testes automatizados ajustados para a base real/limpa passam sem falhas.
