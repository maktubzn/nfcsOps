import 'package:flutter_test/flutter_test.dart';
import 'package:nfc_ops/core/models/activity_entry.dart';
import 'package:nfc_ops/core/models/company.dart';
import 'package:nfc_ops/core/models/device_item.dart';
import 'package:nfc_ops/core/models/health_check_result.dart';
import 'package:nfc_ops/core/models/order_item.dart';
import 'package:nfc_ops/core/models/service_item.dart';
import 'package:nfc_ops/core/models/user_profile.dart';

void main() {
  group('Domain Models Unit Tests', () {
    test('UserProfile role and authorization checks', () {
      final admin = UserProfile(
        uid: 'u-1',
        email: 'admin@test.com',
        displayName: 'Admin User',
        role: 'admin',
        isActive: true,
        createdAt: DateTime.utc(2026, 9, 20),
      );
      expect(admin.isAdmin, isTrue);
      expect(admin.isAuthorized, isTrue);

      final inactiveAdmin = UserProfile(
        uid: 'u-2',
        email: 'inactive@test.com',
        displayName: 'Inactive Admin',
        role: 'admin',
        isActive: false,
        createdAt: DateTime.utc(2026, 9, 20),
      );
      expect(inactiveAdmin.isAdmin, isFalse);
      expect(inactiveAdmin.isAuthorized, isFalse);

      final viewer = UserProfile(
        uid: 'u-3',
        email: 'viewer@test.com',
        displayName: 'Viewer',
        role: 'viewer',
        isActive: true,
        createdAt: DateTime.utc(2026, 9, 20),
      );
      expect(viewer.isAdmin, isFalse);
      expect(viewer.isAuthorized, isFalse);
    });

    test('Company serialization and copyWith', () {
      final now = DateTime.utc(2026, 9, 20);
      final comp = Company(
        id: 'c-1',
        tradeName: 'Restaurante Exemplo',
        category: 'alimentacao',
        status: 'ativo',
        createdAt: now,
        updatedAt: now,
      );

      final map = comp.toMap();
      expect(map['tradeName'], 'Restaurante Exemplo');
      expect(map['category'], 'alimentacao');
      expect(map['legalName'], isNull);

      final restored = Company.fromMap(map, 'c-1');
      expect(restored.tradeName, comp.tradeName);
      expect(restored.category, comp.category);

      final updated = comp.copyWith(tradeName: 'Novo Nome');
      expect(updated.tradeName, 'Novo Nome');
      expect(updated.id, 'c-1');
    });

    test('ServiceItem healthStatus and serialization', () {
      final now = DateTime.utc(2026, 9, 20);
      final srv = ServiceItem(
        id: 's-1',
        companyId: 'c-1',
        serviceType: 'google_review',
        publicTitle: 'Avaliação Google',
        destinationUrl: 'https://g.page/r/test',
        healthStatus: ServiceHealthStatus.warning,
        consecutiveFailures: 2,
        createdAt: now,
        updatedAt: now,
      );

      final map = srv.toMap();
      expect(map['healthStatus'], 'warning');
      expect(map['consecutiveFailures'], 2);

      final restored = ServiceItem.fromMap(map, 's-1');
      expect(restored.healthStatus, ServiceHealthStatus.warning);
      expect(restored.consecutiveFailures, 2);
    });

    test('PhysicalChecklist completion requires all 8 items', () {
      const incomplete = PhysicalChecklist(
        visualInspection: true,
        nfcChipWriting: true,
        nfcReadingTest: true,
        qrPrintInspection: true,
        qrScanVerification: true,
        urlMatchConfirmation: true,
        companyVerification: true,
        finalPackaging: false, // 7 de 8
      );
      expect(incomplete.isComplete, isFalse);
      expect(incomplete.completedCount, 7);

      const complete = PhysicalChecklist(
        visualInspection: true,
        nfcChipWriting: true,
        nfcReadingTest: true,
        qrPrintInspection: true,
        qrScanVerification: true,
        urlMatchConfirmation: true,
        companyVerification: true,
        finalPackaging: true,
      );
      expect(complete.isComplete, isTrue);
      expect(complete.completedCount, 8);
    });

    test('OrderItem monetary calculation in cents', () {
      final now = DateTime.utc(2026, 9, 20);
      const detail1 = OrderItemDetail(
        title: 'Display NFC',
        quantity: 2,
        unitPriceInCents: 12000,
      );
      expect(detail1.totalInCents, 24000);

      const detail2 = OrderItemDetail(
        title: 'Adesivo Balcão',
        quantity: 3,
        unitPriceInCents: 3500,
      );
      expect(detail2.totalInCents, 10500);

      final order = OrderItem(
        id: 'o-1',
        companyId: 'c-1',
        orderNumber: '#1001',
        status: OrderStatus.orcamento,
        paymentStatus: PaymentStatus.pendente,
        totalInCents: detail1.totalInCents + detail2.totalInCents,
        items: const [detail1, detail2],
        createdAt: now,
        updatedAt: now,
      );
      expect(order.totalInCents, 34500); // R$ 345,00
    });

    test('ActivityEntry and HealthCheckResult serialization', () {
      final now = DateTime.utc(2026, 9, 20);
      final activity = ActivityEntry(
        id: 'act-1',
        actorUid: 'u-1',
        actorName: 'Admin',
        actionType: 'create',
        entityType: 'company',
        entityId: 'c-1',
        description: 'Empresa criada',
        timestamp: now,
      );
      expect(activity.toMap()['actionType'], 'create');

      final hc = HealthCheckResult(
        serviceId: 's-1',
        destinationUrl: 'https://example.com',
        status: ServiceHealthStatus.healthy,
        httpCode: 200,
        responseTimeMs: 120,
        checkedAt: now,
      );
      expect(hc.toMap()['httpCode'], 200);
      expect(hc.toMap()['status'], 'healthy');
    });
  });
}
