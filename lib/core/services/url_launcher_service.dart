import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

/// Serviço utilitário robusto para abertura de URLs externas, WhatsApp e telefone.
class UrlLauncherService {
  /// Abre uma URL no navegador externo ou aplicativo correspondente com suporte multiplataforma (Web e Mobile).
  static Future<bool> openUrl(String rawUrl) async {
    try {
      String formattedUrl = rawUrl.trim();
      if (formattedUrl.isEmpty) return false;

      // Suporte para URLs sem protocolo HTTP/HTTPS explícito
      if (!formattedUrl.startsWith('http://') &&
          !formattedUrl.startsWith('https://') &&
          !formattedUrl.startsWith('tel:') &&
          !formattedUrl.startsWith('mailto:')) {
        formattedUrl = 'https://$formattedUrl';
      }

      Uri? uri = Uri.tryParse(formattedUrl);
      if (uri == null) {
        try {
          uri = Uri.parse(Uri.encodeFull(formattedUrl));
        } catch (_) {
          return false;
        }
      }

      if (kIsWeb) {
        return await launchUrl(
          uri,
          mode: LaunchMode.platformDefault,
          webOnlyWindowName: '_blank',
        );
      }

      bool launched = false;
      try {
        launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
      } catch (_) {
        launched = false;
      }

      if (!launched) {
        try {
          launched = await launchUrl(uri, mode: LaunchMode.platformDefault);
        } catch (_) {
          launched = false;
        }
      }

      if (!launched) {
        try {
          launched = await launchUrl(uri, mode: LaunchMode.inAppBrowserView);
        } catch (_) {
          launched = false;
        }
      }

      return launched;
    } catch (e) {
      debugPrint('Erro ao abrir URL: $rawUrl -> $e');
      return false;
    }
  }

  /// Abre uma URL com feedback imediato via SnackBar em caso de falha ou URL vazia.
  static Future<bool> openUrlWithFeedback(BuildContext context, String rawUrl) async {
    final clean = rawUrl.trim();
    if (clean.isEmpty) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Este serviço não possui uma URL de destino cadastrada.'),
            backgroundColor: Color(0xFFEF4444),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
      return false;
    }

    final success = await openUrl(clean);
    if (!success && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Não foi possível abrir o link: $clean'),
          backgroundColor: const Color(0xFFEF4444),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
    return success;
  }

  /// Abre uma conversa no WhatsApp diretamente com o número informado.
  static Future<bool> openWhatsApp(String phone, {String? message}) async {
    try {
      final digits = phone.replaceAll(RegExp(r'[^0-9]'), '');
      if (digits.isEmpty) return false;

      // Se o número tiver 10 ou 11 dígitos (DDD + número brasileiro), adiciona DDI 55
      final formattedNumber = (digits.length == 10 || digits.length == 11) ? '55$digits' : digits;

      String url = 'https://wa.me/$formattedNumber';
      if (message != null && message.trim().isNotEmpty) {
        url += '?text=${Uri.encodeComponent(message.trim())}';
      }

      return await openUrl(url);
    } catch (e) {
      debugPrint('Erro ao abrir WhatsApp: $phone -> $e');
      return false;
    }
  }

  /// Abre WhatsApp com feedback visual no contexto caso o número seja inválido ou falhe.
  static Future<bool> openWhatsAppWithFeedback(
    BuildContext context,
    String? phone, {
    String? message,
  }) async {
    if (phone == null || phone.trim().isEmpty) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Empresa sem telefone cadastrado.'),
            backgroundColor: Color(0xFFEF4444),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
      return false;
    }

    final ok = await openWhatsApp(phone, message: message);
    if (!ok && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Não foi possível abrir o WhatsApp para o número $phone'),
          backgroundColor: const Color(0xFFEF4444),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
    return ok;
  }

  /// Dispara ligação telefônica.
  static Future<bool> makePhoneCall(String phone) async {
    try {
      final digits = phone.replaceAll(RegExp(r'[^0-9+]'), '');
      if (digits.isEmpty) return false;

      final uri = Uri.parse('tel:$digits');
      if (kIsWeb) {
        return await launchUrl(uri);
      }
      return await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (e) {
      debugPrint('Erro ao ligar para o telefone: $phone -> $e');
      return false;
    }
  }
}
