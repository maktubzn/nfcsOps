import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb_auth;
import '../config/firebase_bootstrap.dart';
import '../models/activity_entry.dart';
import '../models/company.dart';
import '../models/device_item.dart';
import '../models/order_item.dart';
import '../models/service_item.dart';
import '../models/user_profile.dart';
import '../models/plate_template.dart';
import '../models/dynamic_qr_code.dart';
import '../models/generated_design.dart';
import 'template_repository.dart';
import 'qr_code_repository.dart';
import 'generated_design_repository.dart';
import 'activity_repository.dart';
import 'auth_repository.dart';
import 'company_repository.dart';
import 'device_repository.dart';
import 'order_repository.dart';
import 'service_repository.dart';

import 'package:google_sign_in/google_sign_in.dart';

/// Helper que intercepta erros assíncronos no stream do Firestore (como permission-denied),
/// registrando o erro no console de debug e emitindo uma lista vazia para proteger a árvore de widgets.
Stream<List<T>> _safeStream<T>(Stream<List<T>> stream) async* {
  try {
    await for (final items in stream) {
      yield items;
    }
  } catch (error) {
    debugPrint('[Firestore Stream Resilient Handler] Erro capturado com segurança: $error');
    yield <T>[];
  }
}

/// Repositório de autenticação real integrado com FirebaseAuth e o Firestore nomeado.
class FirestoreAuthRepository implements AuthRepository {
  final fb_auth.FirebaseAuth _firebaseAuth;
  final FirebaseFirestore _firestore;
  UserProfile? _cachedUser;
  final StreamController<UserProfile?> _controller =
      StreamController<UserProfile?>.broadcast();
  bool _googleSignInInitialized = false;

  FirestoreAuthRepository({
    fb_auth.FirebaseAuth? firebaseAuth,
    FirebaseFirestore? firestore,
  })  : _firebaseAuth = firebaseAuth ?? fb_auth.FirebaseAuth.instance,
        _firestore = firestore ?? FirebaseBootstrap.getFirestoreInstance() {
    _firebaseAuth.authStateChanges().listen((fbUser) async {
      if (fbUser == null) {
        _cachedUser = null;
        _controller.add(null);
      } else {
        final profile = await getUserProfile(fbUser.uid);
        _cachedUser = profile;
        _controller.add(profile);
      }
    });
  }

  Future<void> _ensureGoogleSignInInitialized() async {
    if (_googleSignInInitialized) return;
    try {
      await GoogleSignIn.instance.initialize(
        serverClientId:
            '28901594364-vec5tnh28mnsn0u07p6gv3mi02bk32di.apps.googleusercontent.com',
      );
      _googleSignInInitialized = true;
    } catch (e) {
      debugPrint('Aviso na inicialização do GoogleSignIn: $e');
    }
  }

  @override
  UserProfile? get currentUser => _cachedUser;

  @override
  Stream<UserProfile?> authStateChanges() async* {
    yield _cachedUser;
    yield* _controller.stream;
  }

  @override
  Future<UserProfile?> getUserProfile(String uid) async {
    try {
      final docSnap = await _firestore.collection('users').doc(uid).get();
      if (!docSnap.exists || docSnap.data() == null) {
        return null;
      }
      return UserProfile.fromMap(docSnap.data()!, uid);
    } catch (e) {
      debugPrint('Erro ao buscar perfil $uid: $e');
      return null;
    }
  }

  @override
  Future<UserProfile?> signInWithGoogle({String? uid}) async {
    fb_auth.UserCredential? credential;

    if (kIsWeb) {
      final provider = fb_auth.GoogleAuthProvider();
      provider.addScope('email');
      provider.addScope('profile');
      credential = await _firebaseAuth.signInWithPopup(provider);
    } else {
      await _ensureGoogleSignInInitialized();
      try {
        final googleAccount = await GoogleSignIn.instance.authenticate();
        final idToken = googleAccount.authentication.idToken;
        if (idToken == null || idToken.isEmpty) {
          throw StateError(
              'O Google Play Services não retornou um idToken válido. Verifique se o SHA-1 está registrado no Firebase.');
        }
        final authCred = fb_auth.GoogleAuthProvider.credential(idToken: idToken);
        credential = await _firebaseAuth.signInWithCredential(authCred);
      } catch (googleErr) {
        debugPrint('Erro no Google Sign-In nativo: $googleErr');
        final errText = googleErr.toString().toLowerCase();
        if (errText.contains('cancel') || errText.contains('abort')) {
          return null;
        }
        rethrow;
      }
    }

    final fbUser = credential.user ?? _firebaseAuth.currentUser;
    if (fbUser == null) {
      return null;
    }

    final effectiveUid = fbUser.uid;
    final effectiveEmail = fbUser.email ?? 'admin@nfcops.com.br';
    final effectiveName = fbUser.displayName ?? 'Operador NFC';
    final effectivePhoto = fbUser.photoURL ?? '';

    try {
      final userDocRef = _firestore.collection('users').doc(effectiveUid);
      final docSnap = await userDocRef.get();
      final now = DateTime.now();

      if (!docSnap.exists || docSnap.data() == null) {
        final newUser = UserProfile(
          uid: effectiveUid,
          email: effectiveEmail,
          displayName: effectiveName,
          role: 'admin',
          isActive: true,
          createdAt: now,
        );

        await userDocRef.set({
          'uid': effectiveUid,
          'email': effectiveEmail,
          'displayName': effectiveName,
          'photoUrl': effectivePhoto,
          'role': 'admin',
          'active': true,
          'isActive': true,
          'createdAt': now.toIso8601String(),
          'updatedAt': now.toIso8601String(),
        });

        // Registrar atividade de login
        try {
          final actId = 'act_${DateTime.now().millisecondsSinceEpoch}';
          await _firestore.collection('activities').doc(actId).set({
            'id': actId,
            'actorUid': effectiveUid,
            'actorName': effectiveName,
            'action': 'user_registered',
            'actionType': 'login',
            'entityType': 'system',
            'entityId': effectiveUid,
            'summary': 'Operador $effectiveName ($effectiveEmail) iniciou sessão',
            'description': 'Operador $effectiveName ($effectiveEmail) iniciou sessão',
            'createdAt': now.toIso8601String(),
            'timestamp': now.toIso8601String(),
          });
        } catch (_) {}

        _cachedUser = newUser;
        _controller.add(newUser);
        return newUser;
      } else {
        final existing = UserProfile.fromMap(docSnap.data()!, effectiveUid);
        // Atualiza photoUrl e displayName caso tenham mudado
        try {
          await userDocRef.update({
            'displayName': effectiveName,
            'photoUrl': effectivePhoto,
            'updatedAt': now.toIso8601String(),
          });
        } catch (_) {}
        _cachedUser = existing;
        _controller.add(existing);
        return existing;
      }
    } catch (fsErr) {
      debugPrint('Erro ao sincronizar perfil no Firestore: $fsErr');
      rethrow;
    }
  }

  @override
  Future<void> signOut() async {
    try {
      if (!kIsWeb) {
        await GoogleSignIn.instance.signOut();
      }
    } catch (_) {}
    await _firebaseAuth.signOut();
    _cachedUser = null;
    _controller.add(null);
  }
}

/// Repositório de empresas integrado diretamente ao Cloud Firestore nomeado.
class FirestoreCompanyRepository implements CompanyRepository {
  final FirebaseFirestore _firestore;

  FirestoreCompanyRepository({
    FirebaseFirestore? firestore,
    dynamic authRepository,
  })  : _firestore = firestore ?? FirebaseBootstrap.getFirestoreInstance();

  CollectionReference<Map<String, dynamic>> get _collection =>
      _firestore.collection('companies');

  @override
  Future<List<Company>> getCompanies({String? search, String? statusFilter}) async {
    try {
      final snap = await _collection.get();
      var list = snap.docs.map((d) => Company.fromMap(d.data(), d.id)).toList();

      if (statusFilter != null && statusFilter.isNotEmpty) {
        final sf = statusFilter.toLowerCase();
        list = list.where((c) => c.status.toLowerCase() == sf).toList();
      }

      if (search != null && search.trim().isNotEmpty) {
        final q = search.trim().toLowerCase();
        list = list.where((c) {
          return c.tradeName.toLowerCase().contains(q) ||
              (c.legalName?.toLowerCase().contains(q) ?? false) ||
              (c.phone?.contains(q) ?? false) ||
              (c.contactName?.toLowerCase().contains(q) ?? false);
        }).toList();
      }

      list.sort((a, b) => a.tradeName.toLowerCase().compareTo(b.tradeName.toLowerCase()));
      return list;
    } catch (e) {
      debugPrint('[FirestoreCompanyRepository.getCompanies] Erro protegido: $e');
      return [];
    }
  }

  @override
  Future<Company?> getCompanyById(String id) async {
    try {
      final doc = await _collection.doc(id).get();
      if (!doc.exists || doc.data() == null) return null;
      return Company.fromMap(doc.data()!, doc.id);
    } catch (e) {
      debugPrint('[FirestoreCompanyRepository.getCompanyById] Erro protegido: $e');
      return null;
    }
  }

  @override
  Future<Company> createCompany(Company company) async {
    final docRef = company.id.isEmpty ? _collection.doc() : _collection.doc(company.id);
    final toSave = company.copyWith(id: docRef.id);
    final map = toSave.toMap();
    map['name'] = toSave.tradeName;
    map['normalizedName'] = toSave.tradeName.toLowerCase().trim();
    if (toSave.phone != null) {
      map['normalizedPhone'] = toSave.phone!.replaceAll(RegExp(r'\D'), '');
    }
    await docRef.set(map);
    return toSave;
  }

  @override
  Future<Company> updateCompany(Company company) async {
    final map = company.toMap();
    map['name'] = company.tradeName;
    map['normalizedName'] = company.tradeName.toLowerCase().trim();
    if (company.phone != null) {
      map['normalizedPhone'] = company.phone!.replaceAll(RegExp(r'\D'), '');
    }
    await _collection.doc(company.id).update(map);
    return company;
  }

  @override
  Future<void> deleteCompany(String id) async {
    await _collection.doc(id).delete();
  }

  @override
  Stream<List<Company>> watchCompanies() {
    return _safeStream(
      _collection.snapshots().map((snapshot) {
        final list = snapshot.docs.map((d) => Company.fromMap(d.data(), d.id)).toList();
        list.sort((a, b) => a.tradeName.toLowerCase().compareTo(b.tradeName.toLowerCase()));
        return list;
      }),
    );
  }
}

/// Repositório de serviços integrado diretamente ao Cloud Firestore nomeado.
class FirestoreServiceRepository implements ServiceRepository {
  final FirebaseFirestore _firestore;

  FirestoreServiceRepository({
    FirebaseFirestore? firestore,
    dynamic authRepository,
  })  : _firestore = firestore ?? FirebaseBootstrap.getFirestoreInstance();

  CollectionReference<Map<String, dynamic>> get _collection =>
      _firestore.collection('services');

  @override
  Future<List<ServiceItem>> getAllServices({ServiceHealthStatus? statusFilter}) async {
    try {
      final snap = await _collection.get();
      var list = snap.docs.map((d) => ServiceItem.fromMap(d.data(), d.id)).toList();
      if (statusFilter != null) {
        list = list.where((s) => s.healthStatus == statusFilter).toList();
      }
      list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return list;
    } catch (e) {
      debugPrint('[FirestoreServiceRepository.getAllServices] Erro protegido: $e');
      return [];
    }
  }

  @override
  Future<List<ServiceItem>> getServicesByCompanyId(String companyId) async {
    try {
      final snap = await _collection.where('companyId', isEqualTo: companyId).get();
      var list = snap.docs.map((d) => ServiceItem.fromMap(d.data(), d.id)).toList();
      list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return list;
    } catch (e) {
      debugPrint('[FirestoreServiceRepository.getServicesByCompanyId] Erro protegido: $e');
      return [];
    }
  }

  @override
  Future<ServiceItem?> getServiceById(String id) async {
    try {
      final doc = await _collection.doc(id).get();
      if (!doc.exists || doc.data() == null) return null;
      return ServiceItem.fromMap(doc.data()!, doc.id);
    } catch (e) {
      debugPrint('[FirestoreServiceRepository.getServiceById] Erro protegido: $e');
      return null;
    }
  }

  @override
  Future<ServiceItem> createService(ServiceItem service) async {
    final docRef = service.id.isEmpty ? _collection.doc() : _collection.doc(service.id);
    final toSave = service.copyWith(id: docRef.id);
    final map = toSave.toMap();
    map['type'] = toSave.serviceType;
    map['customName'] = toSave.publicTitle;
    map['destinationUrl'] = toSave.destinationUrl.trim();
    map['qr'] = {
      'mode': 'static',
      'encodedUrl': toSave.destinationUrl.trim(),
      'lastGeneratedAt': DateTime.now().toIso8601String(),
    };
    await docRef.set(map);

    // Atualiza contagem de serviços da empresa
    if (toSave.companyId.isNotEmpty) {
      try {
        final compRef = _firestore.collection('companies').doc(toSave.companyId);
        final compSnap = await compRef.get();
        if (compSnap.exists) {
          final cur = (compSnap.data()?['serviceCount'] as num?)?.toInt() ??
              (compSnap.data()?['servicesCount'] as num?)?.toInt() ?? 0;
          await compRef.update({
            'serviceCount': cur + 1,
            'servicesCount': cur + 1,
            'updatedAt': DateTime.now().toIso8601String(),
          });
        }
      } catch (_) {}
    }

    return toSave;
  }

  @override
  Future<ServiceItem> updateService(ServiceItem service) async {
    final map = service.toMap();
    map['type'] = service.serviceType;
    map['customName'] = service.publicTitle;
    map['destinationUrl'] = service.destinationUrl.trim();
    await _collection.doc(service.id).update(map);
    return service;
  }

  @override
  Future<void> deleteService(String id) async {
    final docSnap = await _collection.doc(id).get();
    final companyId = docSnap.data()?['companyId'] as String?;
    await _collection.doc(id).delete();

    if (companyId != null && companyId.isNotEmpty) {
      try {
        final compRef = _firestore.collection('companies').doc(companyId);
        final compSnap = await compRef.get();
        if (compSnap.exists) {
          final cur = (compSnap.data()?['serviceCount'] as num?)?.toInt() ??
              (compSnap.data()?['servicesCount'] as num?)?.toInt() ?? 1;
          await compRef.update({
            'serviceCount': (cur - 1).clamp(0, 99999),
            'servicesCount': (cur - 1).clamp(0, 99999),
            'updatedAt': DateTime.now().toIso8601String(),
          });
        }
      } catch (_) {}
    }
  }

  @override
  Future<void> updateHealthStatus(
    String id,
    ServiceHealthStatus status, {
    int consecutiveFailures = 0,
    DateTime? lastCheckedAt,
  }) async {
    final updates = <String, dynamic>{
      'currentHealthStatus': status.name,
      'status': status.name,
      'consecutiveFailures': consecutiveFailures,
      'health.status': status.name,
      'health.consecutiveFailures': consecutiveFailures,
    };
    if (lastCheckedAt != null) {
      updates['lastCheckedAt'] = lastCheckedAt.toIso8601String();
      updates['health.lastCheckedAt'] = lastCheckedAt.toIso8601String();
    }
    await _collection.doc(id).update(updates);
  }

  @override
  Stream<List<ServiceItem>> watchAllServices() {
    return _safeStream(
      _collection.snapshots().map((s) {
        final list = s.docs.map((d) => ServiceItem.fromMap(d.data(), d.id)).toList();
        list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        return list;
      }),
    );
  }
}

/// Repositório de pedidos integrado ao Cloud Firestore nomeado.
class FirestoreOrderRepository implements OrderRepository {
  final FirebaseFirestore _firestore;

  FirestoreOrderRepository({
    FirebaseFirestore? firestore,
    dynamic deviceRepository,
    dynamic authRepository,
  }) : _firestore = firestore ?? FirebaseBootstrap.getFirestoreInstance();

  CollectionReference<Map<String, dynamic>> get _collection =>
      _firestore.collection('orders');

  @override
  Future<List<OrderItem>> getOrders({OrderStatus? statusFilter, String? companyId}) async {
    try {
      final snap = await _collection.get();
      var list = snap.docs.map((d) => OrderItem.fromMap(d.data(), d.id)).toList();
      if (companyId != null && companyId.isNotEmpty) {
        list = list.where((o) => o.companyId == companyId).toList();
      }
      if (statusFilter != null) {
        list = list.where((o) => o.status == statusFilter).toList();
      }
      list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return list;
    } catch (e) {
      debugPrint('[FirestoreOrderRepository.getOrders] Erro protegido: $e');
      return [];
    }
  }

  @override
  Future<OrderItem?> getOrderById(String id) async {
    try {
      final doc = await _collection.doc(id).get();
      if (!doc.exists || doc.data() == null) return null;
      return OrderItem.fromMap(doc.data()!, doc.id);
    } catch (e) {
      debugPrint('[FirestoreOrderRepository.getOrderById] Erro protegido: $e');
      return null;
    }
  }

  @override
  Future<OrderItem> createOrder(OrderItem order) async {
    final docRef = order.id.isEmpty ? _collection.doc() : _collection.doc(order.id);
    final toSave = order.copyWith(id: docRef.id);
    final map = toSave.toMap();
    map['total'] = toSave.totalInCents / 100.0;
    await docRef.set(map);
    return toSave;
  }

  @override
  Future<OrderItem> updateOrder(OrderItem order) async {
    final map = order.toMap();
    map['total'] = order.totalInCents / 100.0;
    await _collection.doc(order.id).update(map);
    return order;
  }

  @override
  Future<OrderItem> updateOrderStatus(String id, OrderStatus newStatus) async {
    await _collection.doc(id).update({
      'status': newStatus.name,
      'updatedAt': DateTime.now().toIso8601String(),
    });
    final updated = await getOrderById(id);
    return updated!;
  }

  @override
  Future<OrderItem> updatePaymentStatus(String id, PaymentStatus newStatus) async {
    await _collection.doc(id).update({
      'paymentStatus': newStatus.name,
      'updatedAt': DateTime.now().toIso8601String(),
    });
    final updated = await getOrderById(id);
    return updated!;
  }

  @override
  Future<void> deleteOrder(String id) async {
    await _collection.doc(id).delete();
  }

  @override
  Stream<List<OrderItem>> watchOrders() {
    return _safeStream(
      _collection.snapshots().map((s) {
        final list = s.docs.map((d) => OrderItem.fromMap(d.data(), d.id)).toList();
        list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        return list;
      }),
    );
  }
}

/// Repositório de dispositivos e placas integrado ao Cloud Firestore nomeado.
class FirestoreDeviceRepository implements DeviceRepository {
  final FirebaseFirestore _firestore;

  FirestoreDeviceRepository({
    FirebaseFirestore? firestore,
    dynamic authRepository,
  }) : _firestore = firestore ?? FirebaseBootstrap.getFirestoreInstance();

  CollectionReference<Map<String, dynamic>> get _collection =>
      _firestore.collection('devices');

  @override
  Future<List<DeviceItem>> getDevices({DeviceStatus? statusFilter, String? companyId}) async {
    try {
      final snap = await _collection.get();
      var list = snap.docs.map((d) => DeviceItem.fromMap(d.data(), d.id)).toList();
      if (companyId != null && companyId.isNotEmpty) {
        list = list.where((d) => d.assignedCompanyId == companyId).toList();
      }
      if (statusFilter != null) {
        list = list.where((d) => d.status == statusFilter).toList();
      }
      list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return list;
    } catch (e) {
      debugPrint('[FirestoreDeviceRepository.getDevices] Erro protegido: $e');
      return [];
    }
  }

  @override
  Future<DeviceItem?> getDeviceById(String id) async {
    try {
      final doc = await _collection.doc(id).get();
      if (!doc.exists || doc.data() == null) return null;
      return DeviceItem.fromMap(doc.data()!, doc.id);
    } catch (e) {
      debugPrint('[FirestoreDeviceRepository.getDeviceById] Erro protegido: $e');
      return null;
    }
  }

  @override
  Future<DeviceItem?> getDeviceByNfcUid(String nfcUid) async {
    try {
      final cleanUid = nfcUid.replaceAll(':', '').replaceAll('-', '').toLowerCase().trim();
      if (cleanUid.isEmpty) return null;
      final all = await getDevices();
      return all.where((d) {
        final devNfc = (d.nfcUid ?? '').replaceAll(':', '').replaceAll('-', '').toLowerCase().trim();
        final devId = d.id.replaceAll(':', '').replaceAll('-', '').toLowerCase().trim();
        final devBatch = d.batchId.replaceAll(':', '').replaceAll('-', '').toLowerCase().trim();
        return devNfc == cleanUid || devId == cleanUid || devBatch == cleanUid;
      }).firstOrNull;
    } catch (e) {
      debugPrint('[FirestoreDeviceRepository.getDeviceByNfcUid] Erro protegido: $e');
      return null;
    }
  }

  @override
  Future<DeviceItem> createDevice(DeviceItem device) async {
    final docRef = device.id.isEmpty ? _collection.doc() : _collection.doc(device.id);
    final toSave = device.copyWith(id: docRef.id);
    final map = toSave.toMap();
    map['internalCode'] = toSave.batchId;
    map['physicalType'] = toSave.deviceType == 'display_acrilico'
        ? 'acrylic_plate'
        : toSave.deviceType == 'cartao_pvc'
            ? 'pvc_card'
            : 'sticker';
    await docRef.set(map);
    return toSave;
  }

  @override
  Future<DeviceItem> updateDevice(DeviceItem device) async {
    final map = device.toMap();
    map['internalCode'] = device.batchId;
    await _collection.doc(device.id).set(map, SetOptions(merge: true));
    return device;
  }

  @override
  Future<DeviceItem> updateChecklist(String id, PhysicalChecklist checklist) async {
    await _collection.doc(id).set({
      'checklist': checklist.toMap(),
      'updatedAt': DateTime.now().toIso8601String(),
    }, SetOptions(merge: true));
    final updated = await getDeviceById(id);
    return updated!;
  }

  @override
  Future<DeviceItem> updateStatus(String id, DeviceStatus status) async {
    await _collection.doc(id).set({
      'status': status.name,
      'updatedAt': DateTime.now().toIso8601String(),
    }, SetOptions(merge: true));
    final updated = await getDeviceById(id);
    return updated!;
  }

  @override
  Future<void> deleteDevice(String id) async {
    await _collection.doc(id).delete();
  }

  @override
  Stream<List<DeviceItem>> watchDevices() {
    return _safeStream(
      _collection.snapshots().map((s) {
        final list = s.docs.map((d) => DeviceItem.fromMap(d.data(), d.id)).toList();
        list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        return list;
      }),
    );
  }
}

/// Repositório de atividades integrado ao Cloud Firestore nomeado.
class FirestoreActivityRepository implements ActivityRepository {
  final FirebaseFirestore _firestore;

  FirestoreActivityRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseBootstrap.getFirestoreInstance();

  CollectionReference<Map<String, dynamic>> get _collection =>
      _firestore.collection('activities');

  @override
  Future<List<ActivityEntry>> getActivities({int limit = 50, String? entityType}) async {
    try {
      final snap = await _collection.get();
      var list = snap.docs.map((d) => ActivityEntry.fromMap(d.data(), d.id)).toList();
      if (entityType != null && entityType.isNotEmpty) {
        list = list.where((a) => a.entityType == entityType).toList();
      }
      list.sort((a, b) => b.timestamp.compareTo(a.timestamp));
      if (list.length > limit) {
        list = list.sublist(0, limit);
      }
      return list;
    } catch (e) {
      debugPrint('[FirestoreActivityRepository.getActivities] Erro protegido: $e');
      return [];
    }
  }

  @override
  Future<void> logActivity(ActivityEntry activity) async {
    final docRef = activity.id.isEmpty ? _collection.doc() : _collection.doc(activity.id);
    final map = activity.toMap();
    map['action'] = activity.actionType;
    map['summary'] = activity.description;
    map['createdAt'] = activity.timestamp.toIso8601String();
    await docRef.set(map);
  }

  @override
  Stream<List<ActivityEntry>> watchActivities({int limit = 50}) {
    return _safeStream(
      _collection.snapshots().map((s) {
        final list = s.docs.map((d) => ActivityEntry.fromMap(d.data(), d.id)).toList();
        list.sort((a, b) => b.timestamp.compareTo(a.timestamp));
        if (list.length > limit) {
          return list.sublist(0, limit);
        }
        return list;
      }),
    );
  }
}

/// Implementação Firestore de TemplateRepository.
class FirestoreTemplateRepository implements TemplateRepository {
  final CollectionReference<Map<String, dynamic>> _collection;

  FirestoreTemplateRepository({FirebaseFirestore? firestore})
      : _collection = (firestore ?? FirebaseBootstrap.getFirestoreInstance())
            .collection('templates');

  @override
  Future<List<PlateTemplate>> getTemplates({String? category, String? status}) async {
    try {
      Query<Map<String, dynamic>> q = _collection;
      if (category != null) q = q.where('category', isEqualTo: category);
      if (status != null) q = q.where('status', isEqualTo: status);
      final snap = await q.get();
      return snap.docs.map((d) => PlateTemplate.fromMap(d.data(), d.id)).toList();
    } catch (e) {
      debugPrint('[FirestoreTemplateRepository.getTemplates] Erro protegido: $e');
      return [];
    }
  }

  @override
  Future<PlateTemplate?> getTemplateById(String id) async {
    try {
      final doc = await _collection.doc(id).get();
      if (!doc.exists || doc.data() == null) return null;
      return PlateTemplate.fromMap(doc.data()!, doc.id);
    } catch (e) {
      debugPrint('[FirestoreTemplateRepository.getTemplateById] Erro protegido: $e');
      return null;
    }
  }

  @override
  Future<PlateTemplate> createTemplate(PlateTemplate template) async {
    final docRef = template.id.isEmpty ? _collection.doc() : _collection.doc(template.id);
    final now = DateTime.now();
    final toSave = template.copyWith(id: docRef.id, createdAt: now, updatedAt: now);
    await docRef.set(toSave.toMap());
    return toSave;
  }

  @override
  Future<PlateTemplate> updateTemplate(PlateTemplate template) async {
    final now = DateTime.now();
    final toSave = template.copyWith(updatedAt: now);
    await _collection.doc(template.id).set(toSave.toMap(), SetOptions(merge: true));
    return toSave;
  }

  @override
  Future<void> deleteTemplate(String id) async {
    await _collection.doc(id).delete();
  }

  @override
  Stream<List<PlateTemplate>> watchTemplates() {
    return _safeStream(
      _collection.snapshots().map(
        (s) => s.docs.map((d) => PlateTemplate.fromMap(d.data(), d.id)).toList(),
      ),
    );
  }
}

/// Implementação Firestore de QrCodeRepository.
class FirestoreQrCodeRepository implements QrCodeRepository {
  final CollectionReference<Map<String, dynamic>> _collection;

  FirestoreQrCodeRepository({FirebaseFirestore? firestore})
      : _collection = (firestore ?? FirebaseBootstrap.getFirestoreInstance())
            .collection('qr_codes');

  @override
  Future<List<DynamicQrCode>> getQrCodes({String? companyId}) async {
    try {
      Query<Map<String, dynamic>> q = _collection;
      if (companyId != null) q = q.where('companyId', isEqualTo: companyId);
      final snap = await q.get();
      return snap.docs.map((d) => DynamicQrCode.fromMap(d.data(), d.id)).toList();
    } catch (e) {
      debugPrint('[FirestoreQrCodeRepository.getQrCodes] Erro protegido: $e');
      return [];
    }
  }

  @override
  Future<DynamicQrCode?> getQrCodeById(String id) async {
    try {
      final doc = await _collection.doc(id).get();
      if (!doc.exists || doc.data() == null) return null;
      return DynamicQrCode.fromMap(doc.data()!, doc.id);
    } catch (e) {
      debugPrint('[FirestoreQrCodeRepository.getQrCodeById] Erro protegido: $e');
      return null;
    }
  }

  @override
  Future<DynamicQrCode?> getQrCodeByShortCode(String shortCode) async {
    try {
      final snap = await _collection
          .where('shortCode', isEqualTo: shortCode.toUpperCase())
          .limit(1)
          .get();
      if (snap.docs.isEmpty) return null;
      final d = snap.docs.first;
      return DynamicQrCode.fromMap(d.data(), d.id);
    } catch (e) {
      debugPrint('[FirestoreQrCodeRepository.getQrCodeByShortCode] Erro protegido: $e');
      return null;
    }
  }

  @override
  Future<DynamicQrCode> createQrCode(DynamicQrCode qrCode) async {
    final docRef = qrCode.id.isEmpty ? _collection.doc() : _collection.doc(qrCode.id);
    final now = DateTime.now();
    final toSave = qrCode.copyWith(id: docRef.id, createdAt: now, updatedAt: now);
    await docRef.set(toSave.toMap());
    return toSave;
  }

  @override
  Future<DynamicQrCode> updateDestination(
    String id,
    String newDestination, {
    required String changedByUid,
    required String changedByName,
  }) async {
    final existing = await getQrCodeById(id);
    if (existing == null) throw StateError('QR Code não encontrado: $id');
    final now = DateTime.now();
    final newHistory = List<QrRedirectHistory>.from(existing.history)
      ..add(QrRedirectHistory(
        previousUrl: existing.currentDestination,
        newUrl: newDestination,
        changedByUid: changedByUid,
        changedByName: changedByName,
        changedAt: now,
      ));
    final updated = existing.copyWith(
      currentDestination: newDestination,
      history: newHistory,
      updatedAt: now,
    );
    await _collection.doc(id).set(updated.toMap(), SetOptions(merge: true));
    return updated;
  }

  @override
  Future<void> incrementScanCount(String id) async {
    await _collection.doc(id).update({'scanCount': FieldValue.increment(1)});
  }

  @override
  Future<void> deleteQrCode(String id) async {
    await _collection.doc(id).delete();
  }

  @override
  Stream<List<DynamicQrCode>> watchQrCodes({String? companyId}) {
    Query<Map<String, dynamic>> q = _collection;
    if (companyId != null) q = q.where('companyId', isEqualTo: companyId);
    return _safeStream(
      q.snapshots().map(
        (s) => s.docs.map((d) => DynamicQrCode.fromMap(d.data(), d.id)).toList(),
      ),
    );
  }
}

/// Implementação Firestore de GeneratedDesignRepository.
class FirestoreGeneratedDesignRepository implements GeneratedDesignRepository {
  final CollectionReference<Map<String, dynamic>> _collection;

  FirestoreGeneratedDesignRepository({FirebaseFirestore? firestore})
      : _collection = (firestore ?? FirebaseBootstrap.getFirestoreInstance())
            .collection('generated_designs');

  @override
  Future<List<GeneratedDesign>> getDesigns({String? companyId}) async {
    try {
      Query<Map<String, dynamic>> q = _collection;
      if (companyId != null) q = q.where('companyId', isEqualTo: companyId);
      final snap = await q.get();
      return snap.docs.map((d) => GeneratedDesign.fromMap(d.data(), d.id)).toList();
    } catch (e) {
      debugPrint('[FirestoreGeneratedDesignRepository.getDesigns] Erro protegido: $e');
      return [];
    }
  }

  @override
  Future<GeneratedDesign?> getDesignById(String id) async {
    try {
      final doc = await _collection.doc(id).get();
      if (!doc.exists || doc.data() == null) return null;
      return GeneratedDesign.fromMap(doc.data()!, doc.id);
    } catch (e) {
      debugPrint('[FirestoreGeneratedDesignRepository.getDesignById] Erro protegido: $e');
      return null;
    }
  }

  @override
  Future<GeneratedDesign> createDesign(GeneratedDesign design) async {
    final docRef = design.id.isEmpty ? _collection.doc() : _collection.doc(design.id);
    final now = DateTime.now();
    final toSave = design.copyWith(id: docRef.id, createdAt: now, updatedAt: now);
    await docRef.set(toSave.toMap());
    return toSave;
  }

  @override
  Future<GeneratedDesign> updateDesign(GeneratedDesign design) async {
    final now = DateTime.now();
    final toSave = design.copyWith(updatedAt: now);
    await _collection.doc(design.id).set(toSave.toMap(), SetOptions(merge: true));
    return toSave;
  }

  @override
  Future<void> deleteDesign(String id) async {
    await _collection.doc(id).delete();
  }

  @override
  Stream<List<GeneratedDesign>> watchDesigns({String? companyId}) {
    Query<Map<String, dynamic>> q = _collection;
    if (companyId != null) q = q.where('companyId', isEqualTo: companyId);
    return _safeStream(
      q.snapshots().map(
        (s) => s.docs.map((d) => GeneratedDesign.fromMap(d.data(), d.id)).toList(),
      ),
    );
  }
}
