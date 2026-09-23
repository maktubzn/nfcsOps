import '../models/activity_entry.dart';

/// Contrato abstrato para auditoria e histórico de atividades (S15, RB-008).
abstract class ActivityRepository {
  /// Lista entradas de atividade com paginação/limite
  Future<List<ActivityEntry>> getActivities({int limit = 50, String? entityType});

  /// Registra uma nova atividade de auditoria
  Future<void> logActivity(ActivityEntry entry);

  /// Stream reativa de atividades
  Stream<List<ActivityEntry>> watchActivities({int limit = 50});
}
