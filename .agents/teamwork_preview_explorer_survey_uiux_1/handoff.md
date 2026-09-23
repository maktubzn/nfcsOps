# Handoff Report — UI/UX, Layout, Responsiveness & Design System Audit

## 1. Observation
Across a comprehensive read-only inspection of 32 UI/presentation files in `lib/`, the following direct observations were recorded:

1. **Modal Keyboard Overflows (`RenderFlex overflowed`)**:
   - `lib/features/inventory/presentation/widgets/nfc_scan_modal.dart:188-197`: Modal contains text input inside `Column(mainAxisSize: MainAxisSize.min)` with `Padding(padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom))`. It lacks `SingleChildScrollView`.
   - `lib/features/inventory/presentation/device_detail_screen.dart:613-623`: `_showWriteNfcModal` builds a `Column(mainAxisSize: MainAxisSize.min)` with text fields and URL inputs without scrolling support.
   - `lib/features/inventory/presentation/inventory_screen.dart:597-607`: `_showCreateDeviceModal` repeats the same non-scrollable column pattern.
   - `lib/features/orders/presentation/create_order_screen.dart:100-115`: `_showAddItemModal` repeats the same non-scrollable pattern for adding order items.

2. **Asymmetrical Header & Horizontal Overflow**:
   - `lib/core/widgets/nfc_app_header.dart:42`: Default padding is hardcoded as `const EdgeInsets.fromLTRB(16, 25, 29, 0)`. The 29px right padding clashes with the 16px horizontal margins used across the application.
   - `lib/core/widgets/nfc_app_header.dart:102-154`: The profile greeting and username are in a `Column` directly inside a `Row` without `Expanded` or `Flexible`, causing horizontal overflow when display names exceed 16 characters on a 372px screen.

3. **Bottom Navigation Overlap with System Indicators**:
   - `lib/core/widgets/nfc_bottom_nav_bar.dart:36-38`: `SafeArea(top: false, bottom: false)` with fixed `height: 83`. This disables bottom inset protection on Android gesture navigation and iOS home indicators.
   - `lib/core/router/app_router.dart:257-263`: `_calculateSelectedIndex` falls back to `0` for `/orders`, `/health`, and `/activities`, falsely highlighting the "Início" tab.

4. **Dead Visual Elements & Unreachable Code**:
   - `lib/features/services/presentation/service_detail_screen.dart:144-152`: `Container` holding `Icon(Icons.more_vert)` has no `InkWell`, `GestureDetector`, or callback.
   - `lib/features/inventory/presentation/inventory_screen.dart:327-346`: "Estoque baixo • Adesivos: 3" is a static container with a chevron icon and no `onTap`.
   - `lib/features/dashboard/presentation/dashboard_screen.dart:130, 265`: Line 265 wraps `_buildCriticalAlertCard` with `if (criticalCount > 0)`. Inside `_buildCriticalAlertCard`, line 166 has an `else` branch displaying "Operação estável • Todos os 12 serviços respondendo normalmente". This branch is dead code and hardcodes the count "12".

5. **Misleading Metrics & Hardcoded Static Placeholders**:
   - `lib/features/dashboard/presentation/dashboard_screen.dart:84-85`: `healthRatio = totalServices > 0 ? healthyCount / totalServices : 1.0;`. Displays 100% green health on an empty database.
   - `lib/features/health/presentation/health_center_screen.dart:417`: Same 1.0 fallback on zero services.
   - `lib/features/companies/presentation/company_detail_screen.dart:44-46`: `_formatCityUf` appends `'$cityUf / SP'` for any city without a slash.
   - `lib/features/companies/presentation/company_detail_screen.dart:564-566`: Fallback contact name is hardcoded as `'Carlos Silva'`.
   - `lib/features/companies/presentation/company_detail_screen.dart:448-452`: Company avatar always renders `CrossedWrenchesWidget` (mechanic wrenches), regardless of company category.
   - `lib/features/inventory/presentation/device_detail_screen.dart:905-922`: Hardcoded `"R$ 18,00"` cost and `"Fornecedor A"`.
   - `lib/features/orders/presentation/create_order_screen.dart:47-50`: Pre-fills 2 mock items (`'Cartão NFC PVC'`, `'Adesivo Epóxi 30mm'`) when creating a new order.
   - `lib/features/settings/presentation/settings_screen.dart:298-302`: Static authorized user list with hardcoded names and emails.

6. **Severe Text Truncation in Canonical 372px Width**:
   - `lib/features/companies/presentation/company_detail_screen.dart:813-932`: Service card has fixed elements totaling 224px (padding, icon, "Abrir" button, "Testar" button, chevron, gaps), leaving only 116px for the title and status row. The status text `"Saudável • Hoje, 14:10"` is aggressively truncated to `"Saudável • H..."`.
   - `lib/features/orders/presentation/order_detail_screen.dart:351-424`: Top bar row has back button, delete button, and status pill (`"AGUARDANDO APROVAÇÃO"`, ~178px). Total fixed elements = 308px. This leaves only 64px for `Text('Pedido #${order.orderNumber}')`, truncating the screen title to `"Ped..."`.

7. **Form Input and Validation Bugs**:
   - `lib/features/companies/presentation/create_company_screen.dart:418, 440`: `_addressController` is assigned to both the "Endereço" field and the "Bairro" field. Typing into address mirrors directly into neighborhood.
   - `lib/features/companies/presentation/edit_company_screen.dart:593-605`: `_buildInput` has no `validator`, permitting blank submissions.
   - `lib/features/services/presentation/service_detail_screen.dart:216-224`: `_buildTag(service.status == 'active' ? 'Ativo' : 'Ativo', AppColors.greenSuccess)` always renders "Ativo" in green even when inactive.

---

## 2. Logic Chain

1. **Modal Layout Failure**:
   - *Observation 1*: Modais use `Column(mainAxisSize: MainAxisSize.min)` with `MediaQuery.of(context).viewInsets.bottom` inside bottom sheets without scrolling (`SingleChildScrollView`).
   - *Logic*: When the software keyboard activates (height 280-320px), available vertical space is reduced to < 400px. A column containing multiple inputs and buttons exceeds 400px. Without scroll physics, Flutter fails layout layout constraints with `RenderFlex overflowed by xx pixels`.

2. **Horizontal Layout Truncation**:
   - *Observation 6*: In `company_detail_screen.dart` and `order_detail_screen.dart`, multiple fixed-width action buttons and large status pills share a single horizontal `Row` with an `Expanded` text label on a 372px screen.
   - *Logic*: Total screen width (372px) minus screen padding (32px) yields 340px. When fixed elements take 224px or 308px, the `Expanded` widget receives less than 116px or 64px. Any text string longer than 8-10 characters gets truncated with ellipsis, impairing critical information visibility (order numbers, health timestamps).

3. **Contract & Quality Violations**:
   - *Observation 4 & 5*: Dead elements (`Icons.more_vert` with no handler), static fake alerts ("Adesivos: 3"), hardcoded fallback strings ("Carlos Silva", "Fornecedor A", "R$ 18,00"), and empty database displaying "100% dos serviços saudáveis".
   - *Logic*: `AGENTS.md` explicitly mandates: "Nenhum botão pode ser aprovado com callback vazio, toast substituindo uma ação, dado de produção simulado ou rota incompleta." These elements violate project rules and present a deceptive UI to users.

4. **Input Data Corruption**:
   - *Observation 7*: The controller `_addressController` is attached to two distinct form fields in `create_company_screen.dart`.
   - *Logic*: Flutter `TextEditingController` synchronizes all listeners. When the user edits the address, the neighborhood field immediately mutates to match, corrupting company registration data.

---

## 3. Caveats

- **Device Hardware Testing**: Visual inspection was performed programmatically via code analysis and pixel-budget calculation on canonical specifications (372x870 px viewport). Testing on physical iOS devices was not conducted as macOS hardware is required for iOS builds.
- **Read-Only Investigation Scope**: In accordance with explorer guidelines, no application source code was modified during this audit. All findings are documented as proposals for subsequent implementation sprints.

---

## 4. Conclusion

The application possesses a high-quality visual aesthetic and adheres well to the core dark palette (`#10110F`, `#FF5500`, `#FAF9F0`). However, it contains **4 Critical defects** (RenderFlex keyboard overflows in modals), **11 High-severity defects** (data corruption via controller reuse, severe truncation of headers and card content in 372px width, dead clickable elements, and deceptive 100% health metrics on empty databases), and **9 Medium/Low defects** (design system token bypass, safe area clipping, and static authorized users).

Remediating these issues is straightforward and localized, primarily requiring `SingleChildScrollView` wrappers on modals, splitting over-crowded horizontal rows into vertical stacks or icon-only buttons, separating form controllers, and removing hardcoded mock strings.

---

## 5. Verification Method

To independently verify all observations and conclusions:

1. **Verify Modal Keyboard Overflow**:
   - Launch app on Android emulator or browser with viewport constrained to 372 x 870 px.
   - Navigate to "Dispositivos" (`/inventory`), tap "+ Novo Dispositivo". Focus on "Tag / Nome" or "NFC UID". Observe bottom sheet behavior when on-screen keyboard opens.

2. **Verify Form Controller Duplication**:
   - Navigate to "Empresas" (`/companies`), tap "+ Nova Empresa".
   - Type "Avenida Paulista, 1000" into "Endereço". Inspect the "Bairro" field immediately below; confirm it mirrors the text automatically.

3. **Verify Text Truncation in 372px**:
   - Navigate to any company with registered services (or seed data).
   - View the service list in `company_detail_screen.dart`. Verify that "Saudável • Hoje, 14:10" truncates prematurely due to the "Abrir" and "Testar" buttons.
   - Navigate to `/orders/order-001`. Observe the top bar: the text "Pedido #1024" is compressed to "Ped..." due to the large "AGUARDANDO APROVAÇÃO" pill.

4. **Verify Dead Elements**:
   - Open any service detail screen (`/services/:id`). Tap the top-right three-dots button (`Icons.more_vert`). Verify lack of visual ripple and no event triggered.

5. **Flutter Code Health Verification**:
   - Run `flutter analyze` from project root to ensure no syntax errors are introduced during subsequent fixes.
