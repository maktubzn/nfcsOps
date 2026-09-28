import 'dart:io';
import 'dart:typed_data';
import 'package:image/image.dart' as img;
import 'package:zxing_lib/common.dart';
import 'package:zxing_lib/qrcode.dart';
import 'package:zxing_lib/zxing.dart';

class QrScannerService {
  /// Decodifica o primeiro QR Code encontrado nos bytes de uma imagem.
  /// Funciona com PNG, JPEG, WEBP, etc.
  static String? decodeFromBytes(Uint8List bytes) {
    try {
      final image = img.decodeImage(bytes);
      if (image == null) return null;

      // 1. Tenta decodificar a imagem original
      var result = _tryDecodeImage(image);
      if (result != null) return result;

      // 2. Se a imagem for muito grande, redimensiona para 1000px de largura e tenta novamente
      if (image.width > 1200 || image.height > 1200) {
        final resized = img.copyResize(
          image,
          width: image.width > image.height ? 1000 : null,
          height: image.height >= image.width ? 1000 : null,
        );
        result = _tryDecodeImage(resized);
        if (result != null) return result;
      }

      return null;
    } catch (_) {
      return null;
    }
  }

  /// Lê uma imagem do sistema de arquivos e decodifica o QR Code.
  static Future<String?> decodeFromFilePath(String path) async {
    try {
      final file = File(path);
      if (!await file.exists()) return null;
      final bytes = await file.readAsBytes();
      return decodeFromBytes(bytes);
    } catch (_) {
      return null;
    }
  }

  static String? _tryDecodeImage(img.Image image) {
    final width = image.width;
    final height = image.height;
    final luminances = Int32List(width * height);

    for (var y = 0; y < height; y++) {
      for (var x = 0; x < width; x++) {
        final pixel = image.getPixel(x, y);
        final r = pixel.r.toInt();
        final g = pixel.g.toInt();
        final b = pixel.b.toInt();
        luminances[y * width + x] = 0xFF000000 | (r << 16) | (g << 8) | b;
      }
    }

    final source = RGBLuminanceSource(width, height, luminances);
    final bitmap = BinaryBitmap(HybridBinarizer(source));

    // Tentativa 1: QRCodeReader direto
    try {
      final reader = QRCodeReader();
      final res = reader.decode(bitmap, DecodeHint(tryHarder: true));
      if (res.text.isNotEmpty) return res.text;
    } catch (_) {}

    // Tentativa 2: MultiFormatReader com inversão de cores
    try {
      final multiReader = MultiFormatReader();
      final res = multiReader.decode(
        bitmap,
        DecodeHint(tryHarder: true, alsoInverted: true),
      );
      if (res.text.isNotEmpty) return res.text;
    } catch (_) {}

    return null;
  }
}
