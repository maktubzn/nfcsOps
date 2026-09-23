import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nfc_ops/core/fixtures/seed_data.dart';
import 'package:nfc_ops/core/providers/app_providers.dart';
import 'package:nfc_ops/core/repositories/in_memory_repositories.dart';
import 'package:nfc_ops/core/theme/app_theme.dart';
import 'package:nfc_ops/core/widgets/nfc_bottom_nav_bar.dart';
import 'package:nfc_ops/features/dashboard/presentation/dashboard_screen.dart';

Future<void> loadAllFonts() async {
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

  final lucideFile = File('assets/fonts/lucide.ttf');
  if (lucideFile.existsSync()) {
    final bytes = lucideFile.readAsBytesSync();
    final lucide1 = FontLoader('packages/lucide_icons_flutter/Lucide');
    lucide1.addFont(Future.value(ByteData.view(bytes.buffer)));
    await lucide1.load();

    final lucide2 = FontLoader('Lucide');
    lucide2.addFont(Future.value(ByteData.view(bytes.buffer)));
    await lucide2.load();
  }

  final matFile = File('assets/fonts/MaterialIcons-Regular.otf');
  if (matFile.existsSync()) {
    final bytes = matFile.readAsBytesSync();
    final matLoader = FontLoader('MaterialIcons');
    matLoader.addFont(Future.value(ByteData.view(bytes.buffer)));
    await matLoader.load();
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Capture S02 canonical', (tester) async {
    await tester.runAsync(() async {
      await loadAllFonts();
    });

    final authRepo = InMemoryAuthRepository();
    authRepo.registerUser(SeedData.demoAdmin);
    authRepo.simulateLogin(SeedData.demoAdmin);

    final compRepo = InMemoryCompanyRepository();
    final srvRepo = InMemoryServiceRepository();
    final orderRepo = InMemoryOrderRepository();
    final devRepo = InMemoryDeviceRepository();

    tester.view.physicalSize = const Size(372, 870);
    tester.view.devicePixelRatio = 1.0;

    final key = GlobalKey();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authRepositoryProvider.overrideWithValue(authRepo),
          companyRepositoryProvider.overrideWithValue(compRepo),
          serviceRepositoryProvider.overrideWithValue(srvRepo),
          orderRepositoryProvider.overrideWithValue(orderRepo),
          deviceRepositoryProvider.overrideWithValue(devRepo),
        ],
        child: MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: AppTheme.darkTheme,
          home: RepaintBoundary(
            key: key,
            child: Scaffold(
              backgroundColor: const Color(0xFF10110F),
              body: const DashboardScreen(),
              bottomNavigationBar: NfcBottomNavBar(
                currentIndex: 0,
                onDestinationSelected: (_) {},
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    await tester.runAsync(() async {
      final boundary = key.currentContext!.findRenderObject() as RenderRepaintBoundary;
      final image = await boundary.toImage(pixelRatio: 1.0);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      final dir = Directory('harness/evidence/S02/attempt-02');
      dir.createSync(recursive: true);
      File('harness/evidence/S02/attempt-02/capture.png').writeAsBytesSync(byteData!.buffer.asUint8List());
      image.dispose();
    });

    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });

  testWidgets('Capture S02 alternate', (tester) async {
    final authRepo = InMemoryAuthRepository();
    authRepo.registerUser(SeedData.demoAdmin);
    authRepo.simulateLogin(SeedData.demoAdmin);

    final compRepo = InMemoryCompanyRepository();
    final srvRepo = InMemoryServiceRepository();
    final orderRepo = InMemoryOrderRepository();
    final devRepo = InMemoryDeviceRepository();

    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;

    final key = GlobalKey();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authRepositoryProvider.overrideWithValue(authRepo),
          companyRepositoryProvider.overrideWithValue(compRepo),
          serviceRepositoryProvider.overrideWithValue(srvRepo),
          orderRepositoryProvider.overrideWithValue(orderRepo),
          deviceRepositoryProvider.overrideWithValue(devRepo),
        ],
        child: MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: AppTheme.darkTheme,
          home: RepaintBoundary(
            key: key,
            child: Scaffold(
              backgroundColor: const Color(0xFF10110F),
              body: const DashboardScreen(),
              bottomNavigationBar: NfcBottomNavBar(
                currentIndex: 0,
                onDestinationSelected: (_) {},
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    await tester.runAsync(() async {
      final boundary = key.currentContext!.findRenderObject() as RenderRepaintBoundary;
      final image = await boundary.toImage(pixelRatio: 1.0);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      File('harness/evidence/S02/attempt-02/alternate_viewport.png').writeAsBytesSync(byteData!.buffer.asUint8List());
      image.dispose();
    });

    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });
}
