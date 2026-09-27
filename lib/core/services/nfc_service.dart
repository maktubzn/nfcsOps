import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:nfc_manager/ndef_record.dart';
import 'package:nfc_manager/nfc_manager.dart';
import 'package:nfc_manager/nfc_manager_android.dart';
import 'package:nfc_manager/nfc_manager_ios.dart';

/// Resultado estruturado da leitura de uma tag NFC física.
class NfcScanResult {
  final String uid; // Formato canônico: 04:A2:3B:5C:89:1F
  final String? ndefUrl; // URL gravada no chip, se houver
  final String? tagType; // Tipo da tag (NfcA, Mifare, Ndef, etc.)
  final bool isWritable; // Se o chip aceita gravação
  final int? maxCapacity; // Capacidade em bytes

  const NfcScanResult({
    required this.uid,
    this.ndefUrl,
    this.tagType,
    this.isWritable = true,
    this.maxCapacity,
  });

  @override
  String toString() => 'NfcScanResult(uid: $uid, url: $ndefUrl, type: $tagType)';
}

/// Status detalhado de suporte e disponibilidade do hardware NFC.
enum NfcHardwareStatus {
  /// Hardware NFC suportado e ativado no sistema
  ready,

  /// Hardware NFC presente no aparelho, mas desativado nas configurações do sistema
  disabled,

  /// Aparelho não possui hardware NFC ou ambiente não suportado (ex: Web/Emulador sem sensor)
  unsupported,
}

/// Serviço central de leitura e gravação NFC nativa (sem depender de apps externos).
class NfcService {
  static final NfcService instance = NfcService._();
  NfcService._();

  bool _isSessionActive = false;
  bool get isSessionActive => _isSessionActive;

  /// Diagnóstico detalhado do hardware e status do NFC no aparelho.
  Future<NfcHardwareStatus> checkHardwareStatus() async {
    try {
      if (kIsWeb) return NfcHardwareStatus.unsupported;
      final availability = await NfcManager.instance.checkAvailability();
      return switch (availability) {
        NfcAvailability.enabled => NfcHardwareStatus.ready,
        NfcAvailability.disabled => NfcHardwareStatus.disabled,
        NfcAvailability.unsupported => NfcHardwareStatus.unsupported,
      };
    } catch (_) {
      return NfcHardwareStatus.unsupported;
    }
  }

  /// Verifica se o dispositivo possui hardware NFC e se está habilitado.
  Future<bool> isAvailable() async {
    final status = await checkHardwareStatus();
    return status == NfcHardwareStatus.ready;
  }

  /// Inicia sessão de leitura de tags NFC.
  Future<void> startReadingSession({
    required void Function(NfcScanResult result) onDiscovered,
    void Function(String error)? onError,
  }) async {
    if (kIsWeb) {
      onError?.call('NFC não é suportado no ambiente web.');
      return;
    }

    try {
      final status = await checkHardwareStatus();
      if (status == NfcHardwareStatus.unsupported) {
        onError?.call('Hardware NFC não disponível neste aparelho.');
        return;
      }
      if (status == NfcHardwareStatus.disabled) {
        onError?.call('O sensor NFC está desativado. Ative o NFC nas configurações do seu celular.');
        return;
      }

      await stopSession();
      _isSessionActive = true;

      await NfcManager.instance.startSession(
        pollingOptions: {
          NfcPollingOption.iso14443,
          NfcPollingOption.iso15693,
          NfcPollingOption.iso18092,
        },
        onSessionErrorIos: (error) {
          _isSessionActive = false;
          onError?.call('Sessão NFC cancelada: ${error.message}');
        },
        onDiscovered: (NfcTag tag) async {
          try {
            final result = parseTag(tag);
            onDiscovered(result);
          } catch (e) {
            onError?.call('Erro ao processar tag NFC: $e');
          }
        },
      );
    } catch (e) {
      _isSessionActive = false;
      onError?.call('Falha ao iniciar leitura NFC: $e');
    }
  }

  /// Grava uma URL NDEF no chip NFC físico (placa ou cartão).
  Future<void> writeNdefUrl({
    required String url,
    required void Function() onSuccess,
    void Function(String error)? onError,
  }) async {
    if (kIsWeb) {
      onError?.call('NFC não é suportado no ambiente web.');
      return;
    }

    try {
      final status = await checkHardwareStatus();
      if (status == NfcHardwareStatus.unsupported) {
        onError?.call('Hardware NFC não disponível neste aparelho.');
        return;
      }
      if (status == NfcHardwareStatus.disabled) {
        onError?.call('O sensor NFC está desativado. Ative o NFC nas configurações do seu celular.');
        return;
      }

      await stopSession();
      _isSessionActive = true;

      await NfcManager.instance.startSession(
        pollingOptions: {
          NfcPollingOption.iso14443,
          NfcPollingOption.iso15693,
          NfcPollingOption.iso18092,
        },
        onSessionErrorIos: (error) {
          _isSessionActive = false;
          onError?.call('Sessão de gravação NFC cancelada: ${error.message}');
        },
        onDiscovered: (NfcTag tag) async {
          try {
            final record = createUriRecord(url);
            final message = NdefMessage(records: [record]);

            if (defaultTargetPlatform == TargetPlatform.android) {
              // 1. Android: NDEF já formatado
              final ndefAndroid = NdefAndroid.from(tag);
              if (ndefAndroid != null) {
                if (!ndefAndroid.isWritable) {
                  onError?.call('Esta tag NFC está protegida contra gravação (somente leitura).');
                  await stopSession();
                  return;
                }
                if (ndefAndroid.maxSize < message.byteLength) {
                  onError?.call('A URL excede a capacidade de memória do chip (${ndefAndroid.maxSize} bytes).');
                  await stopSession();
                  return;
                }
                await ndefAndroid.writeNdefMessage(message);
                await stopSession();
                onSuccess();
                return;
              }

              // 2. Android: Tag virgem / não formatada (NDEF Formatable)
              final formatableAndroid = NdefFormatableAndroid.from(tag);
              if (formatableAndroid != null) {
                await formatableAndroid.format(message);
                await stopSession();
                onSuccess();
                return;
              }
            } else if (defaultTargetPlatform == TargetPlatform.iOS) {
              // 3. iOS NDEF
              final ndefIos = NdefIos.from(tag);
              if (ndefIos != null) {
                if (ndefIos.status != NdefStatusIos.readWrite) {
                  onError?.call('Esta tag NFC está bloqueada para gravação.');
                  await stopSession();
                  return;
                }
                if (ndefIos.capacity < message.byteLength) {
                  onError?.call('A URL excede a capacidade de memória do chip (${ndefIos.capacity} bytes).');
                  await stopSession();
                  return;
                }
                await ndefIos.writeNdef(message);
                await stopSession();
                onSuccess();
                return;
              }
            }

            onError?.call('Esta tag NFC não é compatível com escrita NDEF.');
            await stopSession();
          } catch (e) {
            await stopSession();
            final errStr = e.toString().toLowerCase();
            if (errStr.contains('taglost') || errStr.contains('ioexception') || errStr.contains('connection lost')) {
              onError?.call('A placa foi afastada antes da conclusão da gravação. Mantenha a placa firme encostada na traseira do celular.');
            } else {
              onError?.call('Erro ao gravar chip NFC: $e');
            }
          }
        },
      );
    } catch (e) {
      _isSessionActive = false;
      onError?.call('Falha ao iniciar gravação NFC: $e');
    }
  }

  /// Encerra qualquer sessão ativa de NFC de forma segura.
  Future<void> stopSession() async {
    if (!_isSessionActive) return;
    _isSessionActive = false;
    try {
      await NfcManager.instance.stopSession();
    } catch (_) {}
  }

  /// Extrai o UID canônico e registros NDEF de um objeto NfcTag.
  static NfcScanResult parseTag(NfcTag tag) {
    String? rawUid;
    String? foundUrl;
    String? tagType;
    bool isWritable = true;
    int? maxCapacity;

    // 1. Android Tag (apenas no Android ou ambiente de teste)
    if (defaultTargetPlatform == TargetPlatform.android) {
      try {
        final androidTag = NfcTagAndroid.from(tag);
        if (androidTag != null && androidTag.id.isNotEmpty) {
          rawUid = formatIdentifier(androidTag.id);
          tagType = androidTag.techList.isNotEmpty ? androidTag.techList.first.split('.').last : 'AndroidTag';
        }

        final ndefAndroid = NdefAndroid.from(tag);
        if (ndefAndroid != null) {
          isWritable = ndefAndroid.isWritable;
          maxCapacity = ndefAndroid.maxSize;
          final cached = ndefAndroid.cachedNdefMessage;
          if (cached != null && cached.records.isNotEmpty) {
            for (final r in cached.records) {
              final url = parseNdefRecord(r);
              if (url != null && url.isNotEmpty) {
                foundUrl = url;
                break;
              }
            }
          }
        }
      } catch (e) {
        debugPrint('[NfcService] Erro ao interpretar tag Android: $e');
      }
    } else if (defaultTargetPlatform == TargetPlatform.iOS) {
      // 2. iOS Tag (apenas no iOS para evitar colisão de Pigeon com Android)
      try {
        final mifare = MiFareIos.from(tag);
        if (mifare != null && mifare.identifier.isNotEmpty) {
          rawUid = formatIdentifier(mifare.identifier);
          tagType = 'MifareIOS';
        }

        final iso7816 = Iso7816Ios.from(tag);
        if (rawUid == null && iso7816 != null && iso7816.identifier.isNotEmpty) {
          rawUid = formatIdentifier(iso7816.identifier);
          tagType = 'Iso7816IOS';
        }

        final ndefIos = NdefIos.from(tag);
        if (ndefIos != null) {
          isWritable = ndefIos.status == NdefStatusIos.readWrite;
          maxCapacity = ndefIos.capacity;
          final cached = ndefIos.cachedNdefMessage;
          if (cached != null && cached.records.isNotEmpty) {
            for (final r in cached.records) {
              final url = parseNdefRecord(r);
              if (url != null && url.isNotEmpty) {
                foundUrl = url;
                break;
              }
            }
          }
        }
      } catch (e) {
        debugPrint('[NfcService] Erro ao interpretar tag iOS: $e');
      }
    }

    // Fallback de UID caso venha vazio
    final finalUid = rawUid ?? 'NFC-${DateTime.now().millisecondsSinceEpoch.toRadixString(16).toUpperCase()}';

    return NfcScanResult(
      uid: finalUid,
      ndefUrl: foundUrl,
      tagType: tagType ?? 'NTAG/NDEF',
      isWritable: isWritable,
      maxCapacity: maxCapacity,
    );
  }

  /// Formata uma lista de bytes como string hexadecimal com dois-pontos (ex: 04:A2:3B:5C).
  static String formatIdentifier(List<int> bytes) {
    return bytes.map((b) => b.toRadixString(16).padLeft(2, '0').toUpperCase()).join(':');
  }

  /// Cria um registro NdefRecord de URI a partir de uma string de URL.
  static NdefRecord createUriRecord(String uriString) {
    int prefixCode = 0x00;
    String rest = uriString;
    if (uriString.startsWith('http://www.')) {
      prefixCode = 0x01;
      rest = uriString.substring(11);
    } else if (uriString.startsWith('https://www.')) {
      prefixCode = 0x02;
      rest = uriString.substring(12);
    } else if (uriString.startsWith('http://')) {
      prefixCode = 0x03;
      rest = uriString.substring(7);
    } else if (uriString.startsWith('https://')) {
      prefixCode = 0x04;
      rest = uriString.substring(8);
    } else if (uriString.startsWith('tel:')) {
      prefixCode = 0x05;
      rest = uriString.substring(4);
    } else if (uriString.startsWith('mailto:')) {
      prefixCode = 0x06;
      rest = uriString.substring(7);
    }

    final payload = Uint8List.fromList([prefixCode, ...utf8.encode(rest)]);
    return NdefRecord(
      typeNameFormat: TypeNameFormat.wellKnown,
      type: Uint8List.fromList([0x55]), // 'U'
      identifier: Uint8List(0),
      payload: payload,
    );
  }

  /// Decodifica payload de registro NDEF (URI ou texto).
  static String? parseNdefRecord(NdefRecord record) {
    try {
      // 0x55 ('U') = URI Record
      if (record.typeNameFormat == TypeNameFormat.wellKnown &&
          record.type.length == 1 &&
          record.type[0] == 0x55) {
        final payload = record.payload;
        if (payload.isEmpty) return null;
        final prefixCode = payload[0];
        final prefix = _uriPrefix(prefixCode);
        final rest = utf8.decode(payload.sublist(1));
        return '$prefix$rest';
      }

      // 0x54 ('T') = Text Record
      if (record.typeNameFormat == TypeNameFormat.wellKnown &&
          record.type.length == 1 &&
          record.type[0] == 0x54) {
        final payload = record.payload;
        if (payload.isEmpty) return null;
        final languageCodeLength = payload[0] & 0x3F;
        final textBytes = payload.sublist(1 + languageCodeLength);
        return utf8.decode(textBytes);
      }
    } catch (_) {}
    return null;
  }

  static String _uriPrefix(int code) {
    return switch (code) {
      0x01 => 'http://www.',
      0x02 => 'https://www.',
      0x03 => 'http://',
      0x04 => 'https://',
      0x05 => 'tel:',
      0x06 => 'mailto:',
      _ => '',
    };
  }
}
