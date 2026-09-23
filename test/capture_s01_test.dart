import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nfc_ops/core/theme/app_theme.dart';
import 'package:nfc_ops/features/auth/presentation/login_screen.dart';

Future<void> loadInterFonts() async {
  final fontLoader = FontLoader('Inter');
  final paths = [
    'assets/fonts/Inter-Regular.otf',
    'assets/fonts/Inter-Medium.otf',
    'assets/fonts/Inter-SemiBold.otf',
    'assets/fonts/Inter-Bold.otf',
  ];
  for (final p in paths) {
    final file = File(p);
    if (file.existsSync()) {
      final bytes = file.readAsBytesSync();
      fontLoader.addFont(Future.value(ByteData.view(bytes.buffer)));
    }
  }
  await fontLoader.load();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Capture S01 canonical', (tester) async {
    await tester.runAsync(() async {
      await loadInterFonts();
    });

    tester.view.physicalSize = const Size(372, 870);
    tester.view.devicePixelRatio = 1.0;

    final key = GlobalKey();
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: AppTheme.darkTheme,
          home: RepaintBoundary(
            key: key,
            child: const SizedBox(
              width: 372,
              height: 870,
              child: LoginScreen(),
            ),
          ),
        ),
      ),
    );
    await tester.pump();

    await tester.runAsync(() async {
      final boundary = key.currentContext!.findRenderObject() as RenderRepaintBoundary;
      final image = await boundary.toImage(pixelRatio: 1.0);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      File('harness/evidence/S01/attempt-01/capture.png').writeAsBytesSync(byteData!.buffer.asUint8List());
      image.dispose();
    });

    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });

  testWidgets('Capture S01 alternate', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;

    final key = GlobalKey();
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: AppTheme.darkTheme,
          home: RepaintBoundary(
            key: key,
            child: const SizedBox(
              width: 390,
              height: 844,
              child: LoginScreen(),
            ),
          ),
        ),
      ),
    );
    await tester.pump();

    await tester.runAsync(() async {
      final boundary = key.currentContext!.findRenderObject() as RenderRepaintBoundary;
      final image = await boundary.toImage(pixelRatio: 1.0);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      File('harness/evidence/S01/attempt-01/alternate_viewport.png').writeAsBytesSync(byteData!.buffer.asUint8List());
      image.dispose();
    });

    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });
}
