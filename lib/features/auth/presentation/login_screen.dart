import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/providers/app_providers.dart';
import '../../../../core/theme/app_colors.dart';
import 'widgets/google_logo.dart';
import 'widgets/nfc_hero_illustration.dart';
import 'widgets/nfc_wave_icon.dart';

/// Tela S01 — Login do NFC Ops, reproduzindo rigorosamente o conceito visual da Prancha 01.
class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  bool _isLoading = false;
  String? _errorMessage;

  Future<void> _handleGoogleSignIn() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final authRepo = ref.read(authRepositoryProvider);
      final user = await authRepo.signInWithGoogle();

      if (!mounted) return;

      if (user == null) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Autenticação cancelada pelo usuário.';
        });
        return;
      }

      if (!user.isAuthorized) {
        setState(() {
          _isLoading = false;
          _errorMessage =
              'Acesso restrito: seu perfil (${user.email}) não possui autorização ativa. Contate o administrador.';
        });
        return;
      }

      // Sucesso na autorização: redireciona para o Dashboard (S02)
      context.go('/dashboard');
    } catch (e) {
      if (!mounted) return;
      String friendlyMessage = 'Erro ao realizar login com o Google: $e';
      final errStr = e.toString();
      if (errStr.contains('16') ||
          errStr.contains('Account reauth failed') ||
          errStr.contains('10') ||
          errStr.contains('developer_error') ||
          errStr.contains('ApiException: 10')) {
        friendlyMessage =
            'Google OAuth rejeitou o acesso (Erro 16: Account reauth failed).\nMotivo: A impressão digital SHA-1 do app Android não está cadastrada no Firebase Console.\n\nSHA-1 do debug.keystore:\nE0:A7:54:C6:C7:53:BB:F9:66:25:29:0D:64:57:DD:F9:68:7D:C3:E8\n\nAdicione esta chave no Firebase Console > Configurações do Projeto > com.example.nfc_ops.';
      }
      setState(() {
        _isLoading = false;
        _errorMessage = friendlyMessage;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: IntrinsicHeight(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 89),

                      // 1. Marca / Wordmark: Ícone NFC + "NFC Ops" (centralizado em y=89)
                      Center(
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            const NfcWaveIcon(width: 44, height: 67),
                            const SizedBox(width: 14),
                            RichText(
                              text: const TextSpan(
                                children: [
                                  TextSpan(
                                    text: 'NFC ',
                                    style: TextStyle(
                                      fontFamily: 'Inter',
                                      fontSize: 28,
                                      fontWeight: FontWeight.w700,
                                      color: Colors.white,
                                      letterSpacing: -0.5,
                                    ),
                                  ),
                                  TextSpan(
                                    text: 'Ops',
                                    style: TextStyle(
                                      fontFamily: 'Inter',
                                      fontSize: 28,
                                      fontWeight: FontWeight.w400,
                                      color: Colors.white,
                                      letterSpacing: -0.5,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 40),

                      // 2. Headline principal: "Sua operação, conectada." (inicia em y=196)
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            RichText(
                              text: const TextSpan(
                                style: TextStyle(
                                  fontFamily: 'Inter',
                                  fontSize: 42,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: -0.9,
                                  height: 1.15,
                                ),
                                children: [
                                  TextSpan(
                                    text: 'Sua operação,\n',
                                    style: TextStyle(color: Color(0xFFF2F0E6)),
                                  ),
                                  TextSpan(
                                    text: 'conectada.',
                                    style: TextStyle(color: AppColors.orangeAction),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 28),
                            const Text(
                              'Clientes, placas e serviços\nem um só lugar.',
                              style: TextStyle(
                                fontFamily: 'Inter',
                                fontSize: 18,
                                fontWeight: FontWeight.w400,
                                color: Color(0xFFA0A0A0),
                                height: 1.4,
                                letterSpacing: -0.2,
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 34),

                      // 4. Ilustração central Hero (inicia em y=395)
                      const Center(
                        child: NfcHeroIllustration(size: 236),
                      ),

                      const SizedBox(height: 29),

                      // Alerta de erro / negação de autorização (se houver)
                      if (_errorMessage != null) ...[
                        Material(
                          color: Colors.transparent,
                          child: InkWell(
                            borderRadius: BorderRadius.circular(12),
                            onTap: () {
                              Clipboard.setData(const ClipboardData(
                                  text: 'E0:A7:54:C6:C7:53:BB:F9:66:25:29:0D:64:57:DD:F9:68:7D:C3:E8'));
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('SHA-1 copiado para a área de transferência!'),
                                  duration: Duration(seconds: 3),
                                ),
                              );
                            },
                            child: Container(
                              width: double.infinity,
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                              margin: const EdgeInsets.only(bottom: 12),
                              decoration: BoxDecoration(
                                color: AppColors.redError.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: AppColors.redError.withValues(alpha: 0.4)),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.info_outline, color: AppColors.redError, size: 18),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Text(
                                      _errorMessage!,
                                      style: const TextStyle(
                                        fontFamily: 'Inter',
                                        fontSize: 12,
                                        color: Colors.white,
                                        height: 1.3,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],

                      // 5. Botão "Entrar com Google" (Pill Creme, altura 60px, inicia em y=674)
                      Semantics(
                        button: true,
                        label: 'Entrar com Google',
                        child: Material(
                          color: AppColors.surfaceCream,
                          borderRadius: BorderRadius.circular(30),
                          child: InkWell(
                            onTap: _isLoading ? null : _handleGoogleSignIn,
                            borderRadius: BorderRadius.circular(30),
                            child: Container(
                              height: 60,
                              width: double.infinity,
                              alignment: Alignment.center,
                              child: _isLoading
                                  ? const SizedBox(
                                      width: 24,
                                      height: 24,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2.5,
                                        color: AppColors.textDarkPrimary,
                                      ),
                                    )
                                  : FittedBox(
                                      fit: BoxFit.scaleDown,
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Container(
                                            width: 30,
                                            height: 30,
                                            decoration: const BoxDecoration(
                                              color: Colors.white,
                                              shape: BoxShape.circle,
                                            ),
                                            alignment: Alignment.center,
                                            child: const GoogleLogo(size: 18),
                                          ),
                                          const SizedBox(width: 12),
                                          const Text(
                                            'Entrar com Google',
                                            style: TextStyle(
                                              fontFamily: 'Inter',
                                              fontSize: 16.5,
                                              fontWeight: FontWeight.w600,
                                              color: AppColors.textDarkPrimary,
                                              letterSpacing: -0.2,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 32),

                      // 6. Rodapé: "Acesso exclusivo para usuários autorizados." (inicia em y=766)
                      const Center(
                        child: Text(
                          'Acesso exclusivo para usuários autorizados.',
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 13,
                            fontWeight: FontWeight.w400,
                            color: Color(0xFF8E8E93),
                            letterSpacing: -0.1,
                          ),
                        ),
                      ),

                      const SizedBox(height: 90),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
