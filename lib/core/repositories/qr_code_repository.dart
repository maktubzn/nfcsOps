import '../models/dynamic_qr_code.dart';

abstract class QrCodeRepository {
  Future<List<DynamicQrCode>> getQrCodes({String? companyId});
  Future<DynamicQrCode?> getQrCodeById(String id);
  Future<DynamicQrCode?> getQrCodeByShortCode(String shortCode);
  Future<DynamicQrCode> createQrCode(DynamicQrCode qrCode);
  Future<DynamicQrCode> updateDestination(
    String id,
    String newDestination, {
    required String changedByUid,
    required String changedByName,
  });
  Future<void> incrementScanCount(String id);
  Future<void> deleteQrCode(String id);
  Stream<List<DynamicQrCode>> watchQrCodes({String? companyId});
}
