import '../models/company.dart';

/// Contrato abstrato para operações de empresas (S03, S04, S05, S06).
abstract class CompanyRepository {
  /// Lista todas as empresas com filtros opcionais de busca e status
  Future<List<Company>> getCompanies({String? search, String? statusFilter});

  /// Obtém uma empresa específica por ID
  Future<Company?> getCompanyById(String id);

  /// Cria uma nova empresa
  Future<Company> createCompany(Company company);

  /// Atualiza uma empresa existente
  Future<Company> updateCompany(Company company);

  /// Remove uma empresa (ou desativa)
  Future<void> deleteCompany(String id);

  /// Stream reativa de empresas para sincronização em tempo real
  Stream<List<Company>> watchCompanies();
}
