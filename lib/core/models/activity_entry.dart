/// Entrada de log de auditoria / atividades (S15 Atividades).
class ActivityEntry {
  final String id;
  final String actorUid;
  final String actorName;
  final String actionType; // create, update, delete, status_change, checklist_item, health_check
  final String entityType; // company, service, device, order, user
  final String entityId;
  final String description;
  final DateTime timestamp;
  final Map<String, dynamic> metadata;

  const ActivityEntry({
    required this.id,
    required this.actorUid,
    required this.actorName,
    required this.actionType,
    required this.entityType,
    required this.entityId,
    required this.description,
    required this.timestamp,
    this.metadata = const {},
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'actorUid': actorUid,
      'actorName': actorName,
      'actionType': actionType,
      'entityType': entityType,
      'entityId': entityId,
      'description': description,
      'timestamp': timestamp.toIso8601String(),
      'metadata': metadata,
    };
  }

  factory ActivityEntry.fromMap(Map<String, dynamic> map, String id) {
    return ActivityEntry(
      id: id,
      actorUid: map['actorUid'] as String? ?? '',
      actorName: map['actorName'] as String? ?? 'Sistema',
      actionType: map['actionType'] as String? ?? map['action'] as String? ?? 'status_change',
      entityType: map['entityType'] as String? ?? 'company',
      entityId: map['entityId'] as String? ?? '',
      description: map['description'] as String? ?? map['summary'] as String? ?? '',
      timestamp: map['timestamp'] != null
          ? DateTime.tryParse(map['timestamp'].toString()) ?? DateTime.now()
          : (map['createdAt'] != null
              ? DateTime.tryParse(map['createdAt'].toString()) ?? DateTime.now()
              : DateTime.now()),
      metadata: map['metadata'] as Map<String, dynamic>? ?? {},
    );
  }
}
