# Como produzir evidência

1. Rodar a aplicação Flutter real. Não comparar código-fonte a uma imagem como se fosse runtime.
2. Fixar fixture/data/viewport/DPR/fonte. Medir o recorte de cada quadro na prancha (x y largura altura).
3. Capturar PNG do app na dimensão exata do recorte. Guardar captura bruta e metadados do browser/dispositivo. Sem resize/warp.
4. Produzir diagnóstico com Pillow, já encontrado no Python local (12.3.0):

```powershell
python harness/compare_visual.py --reference design/01-acesso-e-empresas.png --actual harness/evidence/S01/attempt-01/capture.png --crop X Y W H --out-dir harness/evidence/S01/attempt-01/comparison
```

X Y W H são medidas a substituir, não valores universais. O script recorta uma cópia de referência para comparação; nunca altera a prancha. Rejeita dimensões divergentes e pasta já usada. Gera referência/captura lado a lado, overlay, diferença amplificada 4× e métricas sem aprovação automática. Se Pillow faltar em outra máquina, avaliar instalação oficial antes de instalar; o runner usa apenas biblioteca padrão.

5. Abrir referência, comparação e overlay no revisor visual. Anexar observações mensuráveis a visual-review.md. Com máscara ou tolerância excepcional, justificar exatamente qual região e por quê. Sem esconder a UI em máscaras.
6. Para cada comando executado, salvar stdout/stderr e exit code reais. Anexar logs relevantes de análise, testes e build. Falhas não são omitidas.
7. Criar template via runner, copiar para review.json, completar critérios/pareceres/artifacts/checks. Caminhos são relativos à raiz do projeto, todos dentro da tentativa atual. Atualizar fingerprint somente DEPOIS da última mudança e de repetir testes/capturas.
8. Ids dos revisores devem identificar sessões diferentes (não apenas trocar o nome do mesmo executor). O validador não consegue autenticar essas identidades; orquestrador deve conferir delegação efetiva.
9. submit registra histórico e não aceita template vazio. Uma rejeição de relatório consome a tentativa: revisar os caminhos e metadados antes de submeter. Falha após 3 tentativas exige plano revisado/decisão humana, sem zerar contador.

Não anexar config/firebase.local.json, cookies, tokens OAuth, service accounts ou dados pessoais aos relatórios. Capturas com login real devem ser redigidas quando guardadas/compartilhadas.
