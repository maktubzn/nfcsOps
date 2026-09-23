import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/config/firebase_bootstrap.dart';
import 'core/providers/app_providers.dart';
import 'core/theme/app_colors.dart';
import 'core/theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  String? initError;

  try {
    await FirebaseBootstrap.initialize();
  } catch (e) {
    initError = e.toString();
    debugPrint('Firebase init error: $e');
  }

  runApp(
    ProviderScope(
      overrides: [
        appModeProvider.overrideWith((ref) => AppMode.production),
      ],
      child: initError != null
          ? NfcInitErrorApp(error: initError)
          : const NfcOpsApp(),
    ),
  );
}

class NfcOpsApp extends ConsumerWidget {
  const NfcOpsApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);

    return MaterialApp.router(
      title: 'NFC Ops',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      routerConfig: router,
    );
  }
}

/// Tela de diagnóstico caso a inicialização do Firebase falhe
class NfcInitErrorApp extends StatelessWidget {
  final String error;
  const NfcInitErrorApp({super.key, required this.error});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'NFC Ops — Erro de Inicialização',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      home: Scaffold(
        backgroundColor: AppColors.background,
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.cloud_off, color: AppColors.orangeAction, size: 64),
                  const SizedBox(height: 20),
                  const Text(
                    'Falha ao conectar com Firebase',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'O app está configurado para operar exclusivamente com dados reais do banco Cloud Firestore nomeado.',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 14,
                      color: Color(0xFF9E9E9E),
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1C1D1B),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFF282A26)),
                    ),
                    child: Text(
                      error,
                      style: const TextStyle(
                        fontFamily: 'Courier',
                        fontSize: 11,
                        color: Color(0xFFEF4444),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
