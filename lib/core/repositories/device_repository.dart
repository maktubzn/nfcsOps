import '../models/device_item.dart';

/// Contrato abstrato para gestão de estoque físico e checklist de produção (S11, S12, RB-005).
abstract class DeviceRepository {
  /// Lista dispositivos do estoque com filtros opcionais
  Future<List<DeviceItem>> getDevices({DeviceStatus? statusFilter, String? companyId});

  /// Obtém dispositivo por ID
  Future<DeviceItem?> getDeviceById(String id);

  /// Obtém dispositivo pelo UID do chip NFC físico
  Future<DeviceItem?> getDeviceByNfcUid(String nfcUid);

  /// Cria novo dispositivo / lote
  Future<DeviceItem> createDevice(DeviceItem device);

  /// Atualiza dados de um dispositivo
  Future<DeviceItem> updateDevice(DeviceItem device);

  /// Atualiza o checklist físico (8 itens)
  Future<DeviceItem> updateChecklist(String id, PhysicalChecklist checklist);

  /// Atualiza o status do dispositivo
  Future<DeviceItem> updateStatus(String id, DeviceStatus status);

  /// Exclui um dispositivo do estoque
  Future<void> deleteDevice(String id);

  /// Stream reativa de dispositivos
  Stream<List<DeviceItem>> watchDevices();
}
