# NFC Ops — conceitos visuais

Data: 20/09/2026. Referência: PRD_NFC_Ops_Profissional.md, versão 1.0.

Entrega de imagens, sem implementação. As telas são conceitos visuais para revisão; botões e QR são ilustrativos. Dados de empresas, contatos, pedidos e destinos são exemplos.

## Pranchas

- 01-acesso-e-empresas.png: S01 Login, S02 Dashboard, S03 Empresas, S04 Nova empresa.
- 02-empresa-e-servicos-v2.png: S05 Detalhe da empresa, S06 Editar empresa, S07 Detalhe do serviço, S08 Editar serviço.
- 03-qr-saude-e-estoque.png: S09 QR Code, S10 Central de saúde, S11 Estoque, S12 Dispositivo.
- 04-pedidos-e-gestao.png: S13 Pedidos, S14 Detalhe do pedido, S15 Atividades, S16 Configurações.
- 05-fluxos-complementares.png: ações rápidas, novo serviço, novo pedido e checklist físico.

## Direção visual

Referência original preservada em referencias/referencia-visual.png. Fundo preto, cards creme, laranja de ação, lilás de apoio e verde de sucesso. Mobile primeiro, tipografia clara, listas curtas e estados acompanhados de texto.

As 16 telas do mapa do PRD estão representadas; conteúdos extensos usam áreas recolhidas ou rolagem conceitual. Não são especificações exaustivas de todos os estados. A adaptação desktop não faz parte destas pranchas mobile.

## Regras para preservar no refinamento

- Só nome, categoria e status são obrigatórios no cadastro da empresa. O nome interno do serviço é opcional no modelo do PRD, mesmo quando representado com asterisco no conceito.
- Verificação manual deve usar estado neutro acompanhado de rótulo, sem afirmar que um perfil foi excluído.
- Os 47 serviços do exemplo são 43 saudáveis, 2 em atenção, 1 em erro e 1 manual: aproximadamente 91% saudáveis.
- NFC e QR estáticos exigem atualização física quando o destino muda.
- Saúde remota não substitui teste físico.
- O checklist possui oito itens; aprovação e pedido pronto dependem de conclusão.
- Gravação NFC ocorre externamente; portal do cliente, analytics e faturamento recorrente permanecem fora do MVP.

## Método e fontes

Geração pelo ImageGen nativo, com a referência visual anexada a cada chamada. Orientação de Product Design (get-context e ideate); uso do Superdesign como canvas das imagens. A skill img-to-html foi consultada para análise da referência, sem executar sua conversão para HTML, conforme pedido expresso.

Skill solicitada: https://github.com/rtadewald/skills/tree/main/img-to-html

Canvas: https://superdesign.dev/teams/8ab9ebcc-3f7b-46cf-907d-e21c817e2610/projects/9ffea456-21a2-4b6b-8e38-907cf0cc0479
