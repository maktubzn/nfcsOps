import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'app_config.dart';

/// Inicialização controlada do Cloud Firestore exigindo estritamente o banco nomeado.
abstract class FirebaseBootstrap {
  /// Inicializa o Firebase Core com as credenciais do projeto oficial.
  static Future<FirebaseApp> initialize() async {
    if (Firebase.apps.isNotEmpty) {
      return Firebase.app();
    }
    if (kIsWeb) {
      return Firebase.initializeApp(
        options: const FirebaseOptions(
          apiKey: AppConfig.firebaseApiKey,
          appId: AppConfig.firebaseWebAppId,
          messagingSenderId: AppConfig.firebaseMessagingSenderId,
          projectId: AppConfig.firebaseProjectId,
          authDomain: AppConfig.firebaseAuthDomain,
          storageBucket: AppConfig.firebaseStorageBucket,
        ),
      );
    } else {
      try {
        return await Firebase.initializeApp();
      } catch (_) {
        return Firebase.initializeApp(
          options: const FirebaseOptions(
            apiKey: AppConfig.firebaseApiKey,
            appId: AppConfig.firebaseAndroidAppId,
            messagingSenderId: AppConfig.firebaseMessagingSenderId,
            projectId: AppConfig.firebaseProjectId,
            authDomain: AppConfig.firebaseAuthDomain,
            storageBucket: AppConfig.firebaseStorageBucket,
          ),
        );
      }
    }
  }

  /// Obtém a instância do Firestore estritamente vinculada ao banco nomeado autorizado.
  /// Lança StateError se o databaseId estiver vazio ou for o default inadvertidamente.
  static FirebaseFirestore getFirestoreInstance({FirebaseApp? app}) {
    const dbId = AppConfig.firestoreNamedDatabaseId;
    if (dbId.isEmpty) {
      throw StateError(
        'Bootstrap error: AppConfig.firestoreNamedDatabaseId não pode ser vazio.',
      );
    }
    if (dbId == '(default)' || dbId == 'default') {
      throw StateError(
        'Bootstrap error: O banco (default) não é permitido no NFC Ops. Use o banco nomeado.',
      );
    }

    final targetApp = app ?? Firebase.app();
    return FirebaseFirestore.instanceFor(
      app: targetApp,
      databaseId: dbId,
    );
  }
}
