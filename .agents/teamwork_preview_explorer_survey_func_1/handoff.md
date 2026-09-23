# Handoff Report — Functional, Navigation, Form & NFC Audit

**Agent**: Explorer Funcional (`teamwork_preview_explorer_survey_func_1`)  
**Parent Agent**: Orchestrator (`c5394cbb-227a-4654-9193-372b2ea5a2a6`)  
**Data**: 2026-09-22  
**Tipo**: Hard Handoff (Auditoria Concluída)  
**Artefato Primário**: `functional_audit.md`

---

## 1. Observation

Durante a investigação estritamente de leitura realizada em toda a árvore `lib/`, foram diretamente observadas as seguintes evidências e trechos literais no código-fonte:

1. **`lib/core/models/device_item.dart:126-127`**:
   ```dart
   primaryServiceId: primaryServiceId ?? this.primaryServiceId,
   assignedCompanyId: assignedCompanyId ?? this.assignedCompanyId,
   ```
   A expressão de desvinculação em `dev.copyWith(assignedCompanyId: null)` preserva o valor anterior devido ao operador `??`, impedindo a desassociação do dispositivo.

2. **`lib/core/repositories/in_memory_repositories.dart:505-520`**:
   ```dart
   if (o.assignedDeviceIds.isEmpty) {
     throw StateError('Violação RB-007: Pedido $id não possui dispositivos físicos vinculados...');
   }
   for (final devId in o.assignedDeviceIds) {
     final dev = await deviceRepository!.getDeviceById(devId);
     if (dev == null) {
       throw StateError('Violação RB-007: Dispositivo vinculado $devId não encontrado.');
     }
     if (!dev.checklist.isComplete) { ... }
   }
   ```
   Pedidos sem dispositivos ou que tiveram dispositivos excluídos disparam `StateError` não tratável.

3. **`lib/features/orders/presentation/create_order_screen.dart:208`**:
   ```dart
   assignedDeviceIds: const [],
   ```
   A tela de criação de pedidos sempre inicializa a lista de dispositivos vazia, sem qualquer controle de UI para associar itens do estoque ao pedido.

4. **`lib/features/inventory/presentation/device_detail_screen.dart:729-735`**:
   ```dart
   final available = await NfcService.instance.isAvailable();
   if (!available) {
     // Modo simulação para emulador/testes sem hardware
     await Future.delayed(const Duration(milliseconds: 600));
     await onRecorded();
     return;
   }
   ```
   Simulação silenciosa em produção marcando o checklist físico como gravado mesmo sem hardware NFC ativo.

5. **`lib/features/orders/presentation/order_detail_screen.dart:210, 534`**:
   ```dart
   // Linha 210
   await ref.read(orderRepositoryProvider).updateOrderStatus(order.id, st);
   // Linha 534
   await repo.updatePaymentStatus(order.id, PaymentStatus.aprovado);
   ```
   Ambas as chamadas ocorrem fora de blocos `try/catch`.

6. **`lib/features/companies/presentation/edit_company_screen.dart:580-607`**:
   O helper `_buildInput` instancia `TextFormField` sem parâmetro `validator`. O campo obrigatório `Nome da empresa *` pode ser submetido como string vazia `""`.

7. **`lib/core/services/real_health_check_service.dart:67-76`**:
   `final client = HttpClient()..` é instanciado a cada requisição sem fechamento em bloco `finally`.

8. **`lib/features/dashboard/presentation/dashboard_screen.dart:177`**:
   `NfcScanModal.show(context, companies: companies)` é chamado sem o parâmetro `onNewTagDetected`.

9. **`lib/features/companies/presentation/company_detail_screen.dart:198`**:
   `onPressed: () => context.pop()` sem verificação de `context.canPop()`, disparando `GoError` ao acessar via deep link na web.

10. **`lib/core/router/app_router.dart:257-263`**:
    `_calculateSelectedIndex` retorna `0` como fallback para `/orders`, `/health` e `/activities`, ativando indevidamente a aba "Início".

---

## 2. Logic Chain

1. **A partir da Observação 1**: Como `DeviceItem.copyWith` não aceita anulação de chaves estrangeiras, qualquer tentativa de desvincular um dispositivo (na exclusão de empresa ou substituição por avaria) falha silenciosamente. O dispositivo retém o ID da empresa excluída no Firestore, gerando orfandade e inconsistência de estoque.
2. **A partir da Observação 2 e 3**: Como novos pedidos são criados com `assignedDeviceIds: []` e a exclusão de um dispositivo não limpa os pedidos que o continham, a regra de validação RB-007 invariavelmente lança `StateError` ao tentar aprovar pedidos. Como resultado, o ciclo de produção fica permanentemente travado.
3. **A partir da Observação 4**: A simulação em produção da gravação NFC quando `isAvailable()` é falso viola a regra contratual de `AGENTS.md` e mascara a falha física de hardware, permitindo a aprovação de dispositivos que não possuem a URL gravada.
4. **A partir da Observação 5**: A ausência de `try/catch` nas transições de status e pagamentos em `OrderDetailScreen` transforma qualquer rejeição de regra ou erro de conectividade em crash de interface com erro cinza no Flutter.
5. **A partir das Observações 6 a 10**: As telas de formulário e navegação contêm brechas de integridade (gravação de dados em branco, vazamento de sockets HTTP, rotas quebradas em links diretos e perda de contexto na navegação).

---

## 3. Caveats

- A auditoria não executou testes de escrita no Cloud Firestore de produção, em estrita conformidade com as regras do projeto (`AGENTS.md` seção 12).
- Os testes de hardware NFC com antena física dependem de dispositivos Android reais com leitor integrado e chip NTAG213/215/216.
- A camada de autenticação foi avaliada conceitualmente em relação a tokens Google OAuth, mas a validação de certificados SHA-1 em produção depende da configuração do console Google Cloud / Firebase do usuário.

---

## 4. Conclusion

Foram identificadas e catalogadas **20 falhas funcionais e de integridade** no projeto NFC Ops, incluindo 5 bugs críticos com potencial de travar o ciclo de vida dos pedidos, corromper referências de banco de dados e simular operações de hardware sem gravação física real.

O relatório consolidado e priorizado está pronto para a equipe de engenharia em:
`c:\Projetos\estudos\flutter\nfcsOps\.agents\teamwork_preview_explorer_survey_func_1\functional_audit.md`.

As correções prioritárias recomendadas são:
1. Ajustar `DeviceItem.copyWith` para suportar anulação explícita de `assignedCompanyId` e `primaryServiceId`.
2. Prover mecanismo de vinculação de estoque aos pedidos e proteção em cascata ao excluir dispositivos.
3. Remover a simulação falsa de gravação NFC em produção e notificar o usuário caso o hardware esteja desligado.
4. Envolver todas as mutações assíncronas de repositório em blocos `try/catch`.
5. Proteger navegações com `context.canPop() ? context.pop() : context.go(...)`.

---

## 5. Verification Method

Para verificar independentemente os apontamentos reportados:

1. **Inspeção de Código**:
   - Inspecione `lib/core/models/device_item.dart` nas linhas 126-127 para confirmar a impossibilidade de anular vínculos.
   - Inspecione `lib/features/inventory/presentation/device_detail_screen.dart:730-735` para confirmar a simulação de gravação quando `!available`.
   - Inspecione `lib/features/orders/presentation/order_detail_screen.dart:210` para verificar a chamada desprotegida a `updateOrderStatus`.

2. **Comando de Testes Automatizados**:
   Execute no terminal do projeto:
   ```pwsh
   flutter test test/core/in_memory_repositories_test.dart
   dart analyze lib test
   ```
   Para validar a falha de orfandade: crie um teste unitário adicionando um pedido com `dev-001`, chame `deviceRepo.deleteDevice('dev-001')` e execute `orderRepo.updateOrderStatus(orderId, OrderStatus.pronto)` — o teste falhará com `StateError`.
