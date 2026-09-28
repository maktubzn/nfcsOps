import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../features/activities/presentation/activities_screen.dart';
import '../../features/auth/presentation/login_screen.dart';
import '../../features/companies/presentation/companies_screen.dart';
import '../../features/companies/presentation/company_detail_screen.dart';
import '../../features/companies/presentation/create_company_screen.dart';
import '../../features/companies/presentation/edit_company_screen.dart';
import '../../features/dashboard/presentation/dashboard_screen.dart';
import '../../features/health/presentation/health_center_screen.dart';
import '../../features/inventory/presentation/create_device_screen.dart';
import '../../features/inventory/presentation/device_detail_screen.dart';
import '../../features/inventory/presentation/inventory_screen.dart';
import '../../features/inventory/presentation/physical_checklist_screen.dart';
import '../../features/orders/presentation/create_order_screen.dart';
import '../../features/orders/presentation/order_detail_screen.dart';
import '../../features/orders/presentation/orders_screen.dart';
import '../../features/qr/presentation/qr_code_screen.dart';
import '../../features/quick_actions/presentation/quick_actions_modal.dart';
import '../../features/services/presentation/create_service_screen.dart';
import '../../features/services/presentation/edit_service_screen.dart';
import '../../features/services/presentation/service_detail_screen.dart';
import '../../features/settings/presentation/settings_screen.dart';
import '../../features/designs/presentation/design_preview_screen.dart';
import '../../features/designs/presentation/generate_design_screen.dart';
import '../../features/qr/presentation/qr_detail_screen.dart';
import '../../features/qr/presentation/qr_library_screen.dart';
import '../../features/qr/presentation/qr_redirect_screen.dart';
import '../../features/templates/presentation/create_template_screen.dart';
import '../../features/templates/presentation/template_detail_screen.dart';
import '../../features/templates/presentation/templates_screen.dart';
import '../models/user_profile.dart';
import '../widgets/nfc_bottom_nav_bar.dart';

/// Chaves de navegação global
final GlobalKey<NavigatorState> rootNavigatorKey = GlobalKey<NavigatorState>();
final GlobalKey<NavigatorState> shellNavigatorKey = GlobalKey<NavigatorState>();

/// Construtor da configuração de roteamento go_router para o NFC Ops.
GoRouter createAppRouter({
  UserProfile? initialUser,
  UserProfile? Function()? getCurrentUser,
  bool enableAuthGuards = true,
  Listenable? refreshListenable,
}) {
  final hasSessionInitial =
      (getCurrentUser != null ? getCurrentUser() : initialUser)?.isAuthorized ?? false;
  return GoRouter(
    navigatorKey: rootNavigatorKey,
    initialLocation: hasSessionInitial ? '/dashboard' : '/login',
    refreshListenable: refreshListenable,
    redirect: (context, state) {
      if (!enableAuthGuards) return null;
      final user = getCurrentUser != null ? getCurrentUser() : initialUser;
      final hasSession = user != null && user.isAuthorized;
      final loc = state.matchedLocation;
      if (loc.startsWith('/q/')) return null;
      final isLoggingIn = loc == '/login';

      if (!hasSession && !isLoggingIn) {
        return '/login';
      }
      if (hasSession && (isLoggingIn || loc == '/')) {
        return '/dashboard';
      }
      return null;
    },
    routes: [
      // Raiz '/' com redirecionamento explícito conforme estado de autorização
      GoRoute(
        path: '/',
        redirect: (context, state) {
          final user = getCurrentUser != null ? getCurrentUser() : initialUser;
          final hasSession = user != null && user.isAuthorized;
          return hasSession ? '/dashboard' : '/login';
        },
      ),

      // S01: Login
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),

      // S04: Nova Empresa (Sem Bottom Nav para permitir espaço)
      GoRoute(
        path: '/companies/new',
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) => const CreateCompanyScreen(),
      ),

      // S06: Editar Empresa (Sem Bottom Nav)
      GoRoute(
        path: '/companies/:id/edit',
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) => EditCompanyScreen(
          companyId: state.pathParameters['id'] ?? 'comp-001',
        ),
      ),

      // A02: Novo Serviço
      GoRoute(
        path: '/services/new',
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) => CreateServiceScreen(
          initialCompanyId: state.uri.queryParameters['companyId'],
        ),
      ),

      // S08: Editar Serviço
      GoRoute(
        path: '/services/:id/edit',
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) => EditServiceScreen(
          serviceId: state.pathParameters['id'] ?? 'srv-001',
        ),
      ),

      // A03: Novo Pedido
      GoRoute(
        path: '/orders/new',
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) => CreateOrderScreen(
          initialCompanyId: state.uri.queryParameters['companyId'],
        ),
      ),

      // A04: Checklist Físico
      GoRoute(
        path: '/devices/:id/checklist',
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) => PhysicalChecklistScreen(
          deviceId: state.pathParameters['id'] ?? 'dev-001',
        ),
      ),

      // Novo Dispositivo (Sem Bottom Nav)
      GoRoute(
        path: '/inventory/new',
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) => const CreateDeviceScreen(),
      ),

      // Rota pública de redirecionamento dinâmico
      GoRoute(
        path: '/q/:shortCode',
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) => QrRedirectScreen(
          shortCode: state.pathParameters['shortCode'] ?? '',
        ),
      ),

      // Templates de placas (Sem Bottom Nav)
      GoRoute(
        path: '/templates',
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) => const TemplatesScreen(),
      ),
      GoRoute(
        path: '/templates/new',
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) => const CreateTemplateScreen(),
      ),
      GoRoute(
        path: '/templates/:id',
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) => TemplateDetailScreen(
          templateId: state.pathParameters['id'] ?? '',
        ),
      ),

      // Biblioteca de QR Codes (Sem Bottom Nav)
      GoRoute(
        path: '/qr-codes',
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) => const QrLibraryScreen(),
      ),
      GoRoute(
        path: '/qr-codes/:id',
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) => QrDetailScreen(
          qrId: state.pathParameters['id'] ?? '',
        ),
      ),

      // Geração e prévia de arte da placa (Sem Bottom Nav)
      GoRoute(
        path: '/designs/generate',
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) => GenerateDesignScreen(
          initialCompanyId: state.uri.queryParameters['companyId'],
          initialTemplateId: state.uri.queryParameters['templateId'],
        ),
      ),
      GoRoute(
        path: '/designs/:id/preview',
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) => DesignPreviewScreen(
          designId: state.pathParameters['id'] ?? '',
        ),
      ),

      // Shell Route para as telas principais com persistent NfcBottomNavBar
      ShellRoute(
        navigatorKey: shellNavigatorKey,
        builder: (context, state, child) {
          final selectedIdx = _calculateSelectedIndex(state.matchedLocation);
          return Scaffold(
            body: child,
            bottomNavigationBar: NfcBottomNavBar(
              currentIndex: selectedIdx,
              onDestinationSelected: (idx) {
                switch (idx) {
                  case 0:
                    context.go('/dashboard');
                    break;
                  case 1:
                    context.go('/companies');
                    break;
                  case 2:
                    QuickActionsModal.show(context);
                    break;
                  case 3:
                    context.go('/inventory');
                    break;
                  case 4:
                    context.go('/more');
                    break;
                }
              },
            ),
          );
        },
        routes: [
          // S02: Dashboard / Início
          GoRoute(
            path: '/dashboard',
            builder: (context, state) => const DashboardScreen(),
          ),

          // S03: Empresas
          GoRoute(
            path: '/companies',
            builder: (context, state) => const CompaniesScreen(),
            routes: [
              // S05: Detalhe da Empresa
              GoRoute(
                path: ':id',
                builder: (context, state) => CompanyDetailScreen(
                  companyId: state.pathParameters['id'] ?? 'comp-001',
                ),
              ),
            ],
          ),

          // S07: Detalhe do Serviço
          GoRoute(
            path: '/services/:id',
            builder: (context, state) => ServiceDetailScreen(
              serviceId: state.pathParameters['id'] ?? 'srv-001',
            ),
          ),

          // S09: QR Code
          GoRoute(
            path: '/qr/:id',
            builder: (context, state) => QrCodeScreen(
              serviceId: state.pathParameters['id'] ?? 'srv-001',
            ),
          ),

          // S10: Central de Saúde
          GoRoute(
            path: '/health',
            builder: (context, state) => const HealthCenterScreen(),
          ),

          // S11: Estoque
          GoRoute(
            path: '/inventory',
            builder: (context, state) => const InventoryScreen(),
            routes: [
              // S12: Detalhe do Dispositivo
              GoRoute(
                path: ':id',
                builder: (context, state) => DeviceDetailScreen(
                  deviceId: state.pathParameters['id'] ?? 'dev-001',
                ),
              ),
            ],
          ),

          // S13: Pedidos
          GoRoute(
            path: '/orders',
            builder: (context, state) => const OrdersScreen(),
            routes: [
              // S14: Detalhe do Pedido
              GoRoute(
                path: ':id',
                builder: (context, state) => OrderDetailScreen(
                  orderId: state.pathParameters['id'] ?? 'ord-028',
                ),
              ),
            ],
          ),

          // S15: Atividades
          GoRoute(
            path: '/activities',
            builder: (context, state) => const ActivitiesScreen(),
          ),

          // S16: Configurações e Mais
          GoRoute(
            path: '/more',
            builder: (context, state) => const SettingsScreen(),
          ),
        ],
      ),
    ],
  );
}

int _calculateSelectedIndex(String location) {
  if (location.startsWith('/dashboard')) return 0;
  if (location.startsWith('/companies')) return 1;
  if (location.startsWith('/inventory')) return 3;
  if (location.startsWith('/more')) return 4;
  return 0;
}
