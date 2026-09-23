# Contrato visual e revisão rigorosa
## Fontes e prioridade
Pranchas canônicas: design/01-acesso-e-empresas.png até design/05-fluxos-complementares.png; prancha 02 recebe a revisão v2 aprovada, com original preservado em design/archive/.
Não renderizar a borda de apresentação, os títulos S01 etc. fora dos quadros, os espaços entre quadros ou uma moldura de telefone.
O PRD prevalece sobre erros gerados nas imagens: campos opcionais não se tornam obrigatórios; navegação sempre Início / Empresas / + / Estoque / Mais; nomes de pagamento são status e não método. Nome interno do serviço é opcional. Datas e cifras servem como fixture, não conteúdo fixo.

## Calibração antes de construir
1. Abrir a imagem em resolução original e identificar os limites internos de cada tela.
2. Registrar retângulo x,y,width,height por Sxx no specification.md, sem alterar a imagem.
3. Definir viewport de comparação pela largura/altura do recorte. As pranchas têm telas aproximadamente 374×870; NÃO esticar para 390×844 por conveniência. Medir cada quadro.
4. Capturar o app na mesma dimensão em pixels, escala 1×, texto 1× e mesma fixture; retirar apenas chrome externo de sistema conforme especificação. Guardar referência e captura originais.
5. Viewports adicionais: 360×800, 390×844, 430×932 e desktop 1440×1024. Nestes, adaptar layout sem esticar texto. Desktop segue a sidebar do PRD, cuja aparência não tem referência exata; declarar a adaptação.
6. Extrair ativos limpos ou gerar separadamente quando necessário; nunca recortar a UI inteira e disfarçá-la de widget. Ícones devem corresponder a forma, traço e tamanho; logos oficiais não podem virar emoji.

## Medições
Paleta inicial aproximada: preto #10110F; creme #ECEBDE; laranja #FF4F0A; lilás #A5ADEB; verde #96F044. Amostrar a referência para os valores finais.
Medir fonte/peso/tamanho/altura de linha, baseline, distância entre blocos, padding, raio, bordas, alinhamento de ícones e hitbox. Não aceitar Material padrão quando divergir. Usar fontes locais licenciadas e versão fixa.
Cards principais ~24 px de raio: medir, não assumir. Toque mínimo 44×44; sem depender apenas de cor. Preservar nomes em português e acentos.

## Rubrica (cada dimensão ≥ 98/100)
Geometria; tipografia; cores/superfícies; ícones/ativos; conteúdo/estados.
A nota não basta: qualquer diferença visível identificada deve constar como pendência. Gate exige zero pendência visual aberta. Tolerâncias de medição: bordas/baselines/alinhamento até 1 px no viewport canônico, áreas cromáticas sólidas até 3/255 por canal; antialiasing pode diferir, mas não justifica escala ou fonte errada.
Métricas de pixel são evidências auxiliares, nunca aprovação automática. Meta SSIM ≥ .99 só se houver ferramenta real instalada; não inventar número nem instalar dependência sem avaliação. Diferenças por acessibilidade/PRD precisam de justificativa explícita e não devem ser ocultadas em máscaras.
O revisor deve inspecionar referência + captura + overlay no mesmo contexto e listar área, esperado, observado, gravidade e correção. Não aprovar só porque compilou.

## Estados e interação
Captura principal reproduz a referência. Capturas adicionais provam loading, vazio, falha, validação e foco/teclado. S04 e S06 formulários devem comportar teclado e rolagem. Navegação não deve cobrir CTA. QR precisa ser funcional e legível, mesmo que a matriz gerada na referência seja ilustrativa: equivalência funcional prevalece na matriz do QR.
