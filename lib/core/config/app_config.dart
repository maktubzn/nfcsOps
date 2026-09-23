/// Configurações gerais e identificadores autorizados do Firebase para o NFC Ops.
abstract class AppConfig {
  /// ID do Projeto Firebase
  static const String firebaseProjectId = 'gusta-nfcs';

  /// ID EXATO do Cloud Firestore nomeado (nunca utilizar banco default)
  static const String firestoreNamedDatabaseId =
      'ai-studio-conectordebanco-005a990b-ecd4-41ad-ba1e-0e68b83c29fd';

  /// Auth domain oficial
  static const String firebaseAuthDomain = 'gusta-nfcs.firebaseapp.com';

  /// Storage Bucket oficial
  static const String firebaseStorageBucket = 'gusta-nfcs.firebasestorage.app';

  /// Identificador do App Web
  static const String firebaseWebAppId = '1:28901594364:web:bfb7fe740ca8b71035b379';

  /// Identificador do App Android
  static const String firebaseAndroidAppId = '1:28901594364:android:8f2f4c30dd64e37435b379';

  /// Firebase API Key
  static const String firebaseApiKey = 'AIzaSyCd0HZaL65mIuHrUmTl-Rtpgn6ZC3i_2f8';

  /// Messaging Sender ID
  static const String firebaseMessagingSenderId = '28901594364';

  /// Mensagem de pausa de autenticação humana
  static const String waitingUserAuthTag = 'WAITING_USER_AUTH';
}
