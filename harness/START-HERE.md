# Harness NFC Ops — comece aqui
## Estado inicial
Flutter 3.47.2 stable / Dart 3.13.2. Aplicação gerada por flutter create --empty, sem telas, pacotes Firebase ou conexão remota. PRD e referências já existem. Objetivo deste harness: transformar as cinco pranchas em uma aplicação funcional, uma tela por vez.

## Como iniciar
No Antigravity, abra C:/Projetos/estudos/flutter/nfcsOps e cole PROMPT-INICIAL.md.
Use a skill local .agents/skills/nfc-ops-loop/SKILL.md. O workflow .agents/workflows/nfc-ops-loop.md é uma entrada alternativa para versões que ainda usam workflows. As instruções também funcionam por leitura direta, sem depender de descoberta automática.
O Python não chama modelos nem automatiza cliques: organiza contexto, tentativas, evidências e gates; o Antigravity executa a implementação, captura e delegação.

## Ordem obrigatória
00-FUNDACAO → prancha 01 (S01–S04) → prancha 02 (S05–S08) → prancha 03 (S09–S12) → prancha 04 (S13–S16) → prancha 05 (A01–A04) → 99-INTEGRACAO.
Cada tela segue ESPECIFICAR → IMPLEMENTAR → EXECUTAR → CAPTURAR → REVISAR → CORRIGIR ou APROVAR.
Não construir vinte telas de uma vez. Serviços transversais podem existir antes; seu acabamento visual permanece na sua unidade.

## Comandos locais
```powershell
python harness/runner.py status
python harness/runner.py next
python harness/runner.py begin
python harness/runner.py template
python harness/runner.py fingerprint
python harness/runner.py submit harness/evidence/<unidade>/attempt-01/review.json
python harness/runner.py block "Aguardando login humano no Firebase"
python harness/runner.py resume "Login concluído e leitura mínima verificada"
```
begin cria a tentativa e o identificador; template cria review.template.json na tentativa atual, com critérios falsos. Copie para review.json e preencha somente após verificação real. submit só aprova com todos os critérios, hashes atuais, logs e pareceres; reprovação mantém a mesma unidade. Depois de três tentativas reprovadas, o estado fica bloqueado. resume exige um motivo, preserva o histórico e só deve ser usado após mudança de estratégia, resolução do ambiente ou orientação humana. Não usar resume para zerar contadores: ele não zera.

## Divisão de responsabilidades
- Orquestrador: lê próximo prompt, coordena executor/revisores, confere evidências e atualiza Obsidian.
- Executor: altera apenas arquivos do escopo, implementa ações e estados reais, escreve testes significativos.
- Revisor visual: usa .agents/agents/nfc-visual-reviewer.md; não edita aplicação, referências nem estado.
- Revisor funcional: usa .agents/agents/nfc-functional-reviewer.md; verifica dados, ações, regras e falhas.
Se a versão do Antigravity não suportar subagentes, abrir uma sessão separada para revisão com os mesmos arquivos. Autorrevisão é registrada como limitação e não preenche o critério de revisão independente.

## Evidências
Por tentativa: specification.md, screenshots da referência e do app em viewport idêntico, comparison.png/overlay.png/diff.png quando aplicável, visual-review.md, functional-review.md, logs dos testes/análise/build e review.json.
Use fixtures isoladas e data fixa 20/09/2026 para correspondência visual. O app real usa dados reais; não trocar por fixtures para demonstrar integração.
Compare as vinte telas novamente em 99-INTEGRACAO; mudanças globais tardias podem regredir telas anteriores.
O gate valida estrutura, arquivos e hashes, mas não pode provar honestidade de um relato nem ausência universal de bugs. O revisor e os testes reais são indispensáveis.

## Escopo e acabamento
Ler VISUAL-CONTRACT.md, FUNCTIONAL-CONTRACT.md, FIREBASE.md e o PRD. A referência é um conceito raster, não um arquivo Figma com métricas exatas. A meta é reproduzir a geometria, tipografia, cores e conteúdo sem divergência visível, com exceções documentadas de acessibilidade ou correções do PRD. Não prometer identidade matemática entre renderizadores nem ausência absoluta de bugs.
