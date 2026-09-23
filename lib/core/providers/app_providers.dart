import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../models/activity_entry.dart';
import '../models/company.dart';
import '../router/app_router.dart';
import '../models/device_item.dart';
import '../models/order_item.dart';
import '../models/service_item.dart';
import '../models/user_profile.dart';
import '../repositories/activity_repository.dart';
import '../repositories/auth_repository.dart';
import '../repositories/company_repository.dart';
import '../repositories/device_repository.dart';
import '../repositories/firestore_repositories.dart';
import '../repositories/in_memory_repositories.dart';
import '../repositories/order_repository.dart';
import '../repositories/service_repository.dart';
import '../services/health_check_service.dart';
import '../services/nfc_service.dart';
import '../services/real_health_check_service.dart';

/// Modos de operação do aplicativo
enum AppMode {
  /// Modo de correspondência visual e testes offline com fixtures SeedData
  fixture,

  /// Modo conectado aos emuladores locais do Firebase
  emulator,

  /// Modo conectado ao banco Cloud Firestore nomeado de produção
  production,
}

/// Chaveamento de modo de execução do NFC Ops (F-05)
final appModeProvider = StateProvider<AppMode>((ref) => AppMode.production);

/// Provider do repositório de autenticação
final authRepositoryProvider = Provider<AuthRepository>((ref) {
  final mode = ref.watch(appModeProvider);
  if (mode == AppMode.production) {
    return FirestoreAuthRepository();
  }
  return InMemoryAuthRepository();
});

/// Provider do repositório de empresas (com injeção de autorização F-04)
final companyRepositoryProvider = Provider<CompanyRepository>((ref) {
  final mode = ref.watch(appModeProvider);
  final auth = ref.watch(authRepositoryProvider);
  if (mode == AppMode.production) {
    return FirestoreCompanyRepository(authRepository: auth);
  }
  return InMemoryCompanyRepository(authRepository: auth);
});

/// Provider do repositório de serviços (com injeção de autorização F-04)
final serviceRepositoryProvider = Provider<ServiceRepository>((ref) {
  final mode = ref.watch(appModeProvider);
  final auth = ref.watch(authRepositoryProvider);
  if (mode == AppMode.production) {
    return FirestoreServiceRepository(authRepository: auth);
  }
  return InMemoryServiceRepository(authRepository: auth);
});

/// Provider do repositório de dispositivos / estoque (com injeção de autorização F-04)
final deviceRepositoryProvider = Provider<DeviceRepository>((ref) {
  final mode = ref.watch(appModeProvider);
  final auth = ref.watch(authRepositoryProvider);
  if (mode == AppMode.production) {
    return FirestoreDeviceRepository(authRepository: auth);
  }
  return InMemoryDeviceRepository(authRepository: auth);
});

/// Provider do repositório de pedidos (com validação estrita de checklist F-01 e autorização F-04)
final orderRepositoryProvider = Provider<OrderRepository>((ref) {
  final mode = ref.watch(appModeProvider);
  final deviceRepo = ref.watch(deviceRepositoryProvider);
  final auth = ref.watch(authRepositoryProvider);
  if (mode == AppMode.production) {
    return FirestoreOrderRepository(
      deviceRepository: deviceRepo,
      authRepository: auth,
    );
  }
  return InMemoryOrderRepository(
    deviceRepository: deviceRepo,
    authRepository: auth,
  );
});

/// Provider do repositório de atividades
final activityRepositoryProvider = Provider<ActivityRepository>((ref) {
  final mode = ref.watch(appModeProvider);
  if (mode == AppMode.production) {
    return FirestoreActivityRepository();
  }
  return InMemoryActivityRepository();
});

/// Provider do serviço de verificação de saúde (respeitando conectividade F-03)
final healthCheckServiceProvider = Provider<HealthCheckService>((ref) {
  final mode = ref.watch(appModeProvider);
  if (mode == AppMode.production) {
    return RealHealthCheckService();
  }
  final hasBackend = mode == AppMode.emulator;
  return MockHealthCheckService(hasBackendConnectivity: hasBackend);
});

/// Provider do serviço nativo de hardware NFC
final nfcServiceProvider = Provider<NfcService>((ref) {
  return NfcService.instance;
});

/// Stream do usuário autenticado no app
final authStateProvider = StreamProvider<UserProfile?>((ref) {
  final repo = ref.watch(authRepositoryProvider);
  return repo.authStateChanges();
});

/// Usuário atual síncrono
final currentUserProvider = Provider<UserProfile?>((ref) {
  final asyncUser = ref.watch(authStateProvider);
  return asyncUser.value ?? ref.watch(authRepositoryProvider).currentUser;
});

/// Stream reativa de empresas
final companiesStreamProvider = StreamProvider<List<Company>>((ref) {
  final repo = ref.watch(companyRepositoryProvider);
  return repo.watchCompanies();
});

/// Stream reativa de serviços
final servicesStreamProvider = StreamProvider<List<ServiceItem>>((ref) {
  final repo = ref.watch(serviceRepositoryProvider);
  return repo.watchAllServices();
});

/// Stream reativa de dispositivos de estoque
final devicesStreamProvider = StreamProvider<List<DeviceItem>>((ref) {
  final repo = ref.watch(deviceRepositoryProvider);
  return repo.watchDevices();
});

/// Stream reativa de pedidos
final ordersStreamProvider = StreamProvider<List<OrderItem>>((ref) {
  final repo = ref.watch(orderRepositoryProvider);
  return repo.watchOrders();
});

/// Stream reativa de atividades recentes
final activitiesStreamProvider = StreamProvider<List<ActivityEntry>>((ref) {
  final repo = ref.watch(activityRepositoryProvider);
  return repo.watchActivities();
});

/// Notifier que reage a streams para acionar o redirect do GoRouter sem recriá-lo
class GoRouterRefreshStream extends ChangeNotifier {
  late final StreamSubscription<dynamic> _subscription;

  GoRouterRefreshStream(Stream<dynamic> stream) {
    notifyListeners();
    _subscription = stream.asBroadcastStream().listen((_) => notifyListeners());
  }

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}

/// Provider reativo do GoRouter
final routerProvider = Provider<GoRouter>((ref) {
  final authRepo = ref.watch(authRepositoryProvider);
  final refresh = GoRouterRefreshStream(authRepo.authStateChanges());
  ref.onDispose(() => refresh.dispose());

  return createAppRouter(
    getCurrentUser: () => ref.read(currentUserProvider),
    refreshListenable: refresh,
  );
});
