import 'package:flutter_test/flutter_test.dart';
import 'package:nfc_ops/core/models/dynamic_qr_code.dart';
import 'package:nfc_ops/core/models/generated_design.dart';
import 'package:nfc_ops/core/models/plate_template.dart';
import 'package:nfc_ops/core/repositories/in_memory_repositories.dart';

void main() {
  group('Plate Template & Dynamic QR Tests', () {
    test('PlateTemplate and QrPlacement serialization and coordinates', () {
      const placement = QrPlacement(
        id: 'qrp-1',
        label: 'QR Principal',
        xPercent: 0.35,
        yPercent: 0.40,
        wPercent: 0.30,
        hPercent: 0.30,
      );

      final template = PlateTemplate(
        id: 'tmpl-1',
        name: 'TikTok 10x10',
        category: 'social',
        productType: 'placa_acrilica',
        physicalWidthCm: 10.0,
        physicalHeightCm: 10.0,
        baseImageUrl: 'https://example.com/template.png',
        qrPlacements: [placement],
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final map = template.toMap();
      final fromMap = PlateTemplate.fromMap(map, 'tmpl-1');

      expect(fromMap.name, equals('TikTok 10x10'));
      expect(fromMap.physicalWidthCm, equals(10.0));
      expect(fromMap.qrPlacements.length, equals(1));
      expect(fromMap.qrPlacements.first.xPercent, equals(0.35));
      expect(fromMap.qrPlacements.first.wPercent, equals(0.30));
    });

    test('DynamicQrCode generates permanent publicUrl and tracks destination history', () async {
      final repo = InMemoryQrCodeRepository();

      final qr = DynamicQrCode(
        id: 'qr-1',
        shortCode: 'X4K7M2',
        companyId: 'comp-1',
        currentDestination: 'https://instagram.com/sabordecasa',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      expect(qr.publicUrl, equals('https://gusta-nfcs.web.app/q/X4K7M2'));

      await repo.createQrCode(qr);

      // Atualiza o destino
      final updated = await repo.updateDestination(
        'qr-1',
        'https://tiktok.com/@sabordecasa',
        changedByUid: 'usr-1',
        changedByName: 'Gustavo',
      );

      expect(updated.currentDestination, equals('https://tiktok.com/@sabordecasa'));
      expect(updated.publicUrl, equals('https://gusta-nfcs.web.app/q/X4K7M2')); // Link impresso não mudou!
      expect(updated.history.length, equals(1));
      expect(updated.history.first.previousUrl, equals('https://instagram.com/sabordecasa'));
      expect(updated.history.first.newUrl, equals('https://tiktok.com/@sabordecasa'));
      expect(updated.history.first.changedByName, equals('Gustavo'));

      // Busca por shortCode
      final byCode = await repo.getQrCodeByShortCode('X4K7M2');
      expect(byCode?.id, equals('qr-1'));
    });

    test('GeneratedDesign connects template, company, and QR code', () {
      final design = GeneratedDesign(
        id: 'dsg-1',
        templateId: 'tmpl-1',
        companyId: 'comp-1',
        qrCodeId: 'qr-1',
        deviceId: 'dev-1',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final map = design.toMap();
      final fromMap = GeneratedDesign.fromMap(map, 'dsg-1');

      expect(fromMap.templateId, equals('tmpl-1'));
      expect(fromMap.companyId, equals('comp-1'));
      expect(fromMap.qrCodeId, equals('qr-1'));
      expect(fromMap.deviceId, equals('dev-1'));
    });

    test('Canva template and multi-page QR serialization', () {
      final canvaTemplate = PlateTemplate(
        id: 'tmpl-canva-1',
        name: 'Canva Duplo Instagram + Reviews',
        category: 'social',
        productType: 'placa_acrilica',
        origin: 'canva',
        canvaProjectUrl: 'https://canva.com/design/DAF12345/view',
        finalExportedFileUrl: 'https://storage.googleapis.com/final_art.png',
        page1ServiceType: 'instagram',
        page2ServiceType: 'google_review',
        page1DynamicUrl: 'https://nfcops.web.app/q/Q1TEST',
        page2DynamicUrl: 'https://nfcops.web.app/q/Q2TEST',
        physicalWidthCm: 15.0,
        physicalHeightCm: 10.0,
        baseImageUrl: 'https://storage.googleapis.com/final_art.png',
        qrPlacements: const [
          QrPlacement(id: 'q1', xPercent: 0.1, yPercent: 0.1, wPercent: 0.3, hPercent: 0.3, pageIndex: 0),
          QrPlacement(id: 'q2', xPercent: 0.1, yPercent: 0.1, wPercent: 0.3, hPercent: 0.3, pageIndex: 1),
        ],
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final map = canvaTemplate.toMap();
      final fromMap = PlateTemplate.fromMap(map, 'tmpl-canva-1');

      expect(fromMap.isCanva, isTrue);
      expect(fromMap.origin, equals('canva'));
      expect(fromMap.canvaProjectUrl, equals('https://canva.com/design/DAF12345/view'));
      expect(fromMap.page1ServiceType, equals('instagram'));
      expect(fromMap.page2ServiceType, equals('google_review'));
      expect(fromMap.qrPlacements.length, equals(2));
      expect(fromMap.qrPlacements[0].pageIndex, equals(0));
      expect(fromMap.qrPlacements[1].pageIndex, equals(1));
    });
  });
}
