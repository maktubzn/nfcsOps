import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:nfc_ops/core/services/qr_scanner_service.dart';
import 'package:qr/qr.dart';

void main() {
  test('QrScannerService successfully decodes QR from image bytes', () {
    const testUrl = 'https://instagram.com/sabordecasa';
    final qrCode = QrCode.fromData(
      data: testUrl,
      errorCorrectLevel: QrErrorCorrectLevel.M,
    );
    final qrImage = QrImage(qrCode);

    const quietZone = 4;
    final totalModules = qrImage.moduleCount + quietZone * 2;
    const moduleSize = 8;
    final width = totalModules * moduleSize;
    final height = totalModules * moduleSize;
    final image = img.Image(width: width, height: height);
    img.fill(image, color: img.ColorRgb8(255, 255, 255));

    for (var x = 0; x < qrImage.moduleCount; x++) {
      for (var y = 0; y < qrImage.moduleCount; y++) {
        if (qrImage.isDark(y, x)) {
          img.fillRect(
            image,
            x1: (x + quietZone) * moduleSize,
            y1: (y + quietZone) * moduleSize,
            x2: (x + quietZone + 1) * moduleSize - 1,
            y2: (y + quietZone + 1) * moduleSize - 1,
            color: img.ColorRgb8(0, 0, 0),
          );
        }
      }
    }

    final pngBytes = Uint8List.fromList(img.encodePng(image));
    final decoded = QrScannerService.decodeFromBytes(pngBytes);

    expect(decoded, equals(testUrl));
  });

  test('QrScannerService returns null for image without QR', () {
    final image = img.Image(width: 100, height: 100);
    img.fill(image, color: img.ColorRgb8(200, 200, 200));
    final pngBytes = Uint8List.fromList(img.encodePng(image));

    final decoded = QrScannerService.decodeFromBytes(pngBytes);
    expect(decoded, isNull);
  });
}
