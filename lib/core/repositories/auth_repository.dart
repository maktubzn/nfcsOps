import '../models/user_profile.dart';

/// Contrato abstrato para autenticação e autorização (RB-001, RB-002, RB-003).
abstract class AuthRepository {
  /// Stream de mudanças de estado de autenticação
  Stream<UserProfile?> authStateChanges();

  /// Usuário logado atualmente (ou null se deslogado)
  UserProfile? get currentUser;

  /// Inicia fluxo de autenticação com o Google (opcionalmente fornecendo uid para testes/emulador)
  Future<UserProfile?> signInWithGoogle({String? uid});

  /// Desconecta o usuário
  Future<void> signOut();

  /// Obtém o perfil de permissões users/{uid}
  Future<UserProfile?> getUserProfile(String uid);
}
