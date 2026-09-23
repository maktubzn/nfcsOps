import '../models/company.dart';
import '../models/device_item.dart';
import '../models/order_item.dart';
import '../models/service_item.dart';
import '../models/user_profile.dart';

/// Fixture para suites de teste com base limpa e sem mocks de produção.
/// Listas estáticas inicializadas como vazias.
abstract class SeedData {
  static final DateTime fixedDate = DateTime.utc(2026, 9, 20, 12, 0, 0);

  /// Perfil de usuário admin para suites de teste
  static final UserProfile demoAdmin = UserProfile(
    uid: 'demo-admin-uid-2026',
    email: 'admin@nfcops.com.br',
    displayName: 'Gustavo Alves',
    role: 'admin',
    isActive: true,
    createdAt: fixedDate,
  );

  /// Usuário não autorizado para suites de teste negativo (RB-002)
  static final UserProfile unauthorizedUser = UserProfile(
    uid: 'unauthorized-uid-2026',
    email: 'pendente@gmail.com',
    displayName: 'Visitante Não Autorizado',
    role: 'viewer',
    isActive: false,
    createdAt: fixedDate,
  );

  /// Base limpa: sem empresas fictícias pré-carregadas
  static const List<Company> companies = [];

  /// Base limpa: sem serviços fictícios pré-carregados
  static const List<ServiceItem> services = [];

  /// Base limpa: sem dispositivos fictícios pré-carregados
  static const List<DeviceItem> devices = [];

  /// Base limpa: sem pedidos fictícios pré-carregados
  static const List<OrderItem> orders = [];
}
