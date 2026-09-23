# Contrato funcional
## Nada decorativo
Inventariar TODO controle visível em cada tela: id, ação, pré-condição, fonte de dados, efeito persistido, erro e teste. Sucesso exige efeito real e leitura após recarregar quando há escrita. Clipboard/download/deep link têm teste observável, não apenas snackbar. Cancelar não persiste. Submissão dupla não duplica.

## Domínio
Empresas; serviços; dispositivos; pedidos; catálogo; usuários autorizados; atividades; healthChecks. Usar os schemas e RB-001–RB-010 do PRD. Modelos tipados, repositórios injetáveis, clock injetável para testes; dados reais separados de fixtures.
Não ler todas as coleções sem limites. Paginação, filtros com índices necessários e normalização de prefixo/telefone/código. Não prometer fuzzy.

## Autenticação e autorização
Google Auth + users/{uid}.active + papel autorizado. Login bem-sucedido não é autorização administrativa. Negar por padrão. Proteger rotas, deep links, Firestore, Storage e Functions. O cliente não pode autopromover seu users/{uid}. Sessão, logout, cancelamento, popup bloqueado e acesso negado devem ser testados.

## Saúde e segurança
O cliente não confirma saúde por simples parse da URL. Health checker em backend autorizado com timeout, limites, DNS/SSRF, HTTPS, bloqueio de redes privadas e política de redirecionamento. Bloqueio de bot → manual; primeiras falhas → atenção; limiar configurável de 3 consecutivas → erro. Não assumir endpoint existente; verificar antes.
Se backend não estiver disponível, implementar e testar contrato/emulador e registrar integração remota bloqueada; não anunciar monitoramento funcional sem ele. Agendamento diário requer infraestrutura efetiva, não um toggle visual.

## Estoque e produção
Associação de dispositivo a um serviço principal; instalada exige empresa. Transições válidas e histórico. Alterações concorrentes e duplo toque protegidos por transações/versionamento. Os oito itens do checklist são obrigatórios, incluindo cliente correto e acabamento. Não permitir pronto com pendência, inclusive por chamada direta ao backend. NFC gravado externamente: checklist de leitura física real, nunca teste remoto tratado como NFC aprovado.

## QR, links, arquivos
QR codifica exatamente o destino de impressão exibido, com quiet zone e alto contraste. Gerar PNG/SVG reais e decodificar ambos no teste; export SVG não pode ser PNG embutido. URLs de demonstração só em fixtures.
Mudança de URL estática exibe necessidade de reimpressão/regravação; não prometer atualização de objeto já entregue.
Upload de logo/arte com limite, MIME, erro, permissão e vínculo; nenhum caminho local salvo como URL remota.

## Pedidos
Fluxo orçamento → aguardando aprovação → aprovado → produção → testes → pronto → entregue. Pagamento separado do fluxo operacional, valores monetários em centavos, desconto e quantidades validados. Histórico e consistência entre lista e detalhe. Sem gateway, nota fiscal ou billing fora do MVP.

## Matriz final
Testar F01 cadastro + primeiro serviço; F02 estoque → produção → checklist → pronto; F03 erro → correção → novo teste; F04 é futuro dinâmico, somente documentar como fora de V1.
Verificar rotas, ações rápidas, todos filtros, validação, persistência/reload, falhas de rede, negação de permissão, concorrência, relatórios de atividade e ajustes administrativos.
A entrega não pode afirmar ausência universal de bugs. Exigir zero falha conhecida nos cenários acordados, logs sem erros relevantes e regressão após a última modificação.
