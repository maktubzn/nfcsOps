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
import 'package:nfc_ops/features/companies/presentation/company_detail_screen.dart';

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

  testWidgets('Capture S05 canonical', (tester) async {
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
    final actRepo = InMemoryActivityRepository();

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
          activityRepositoryProvider.overrideWithValue(actRepo),
        ],
        child: MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: AppTheme.darkTheme,
          home: RepaintBoundary(
            key: key,
            child: Scaffold(
              backgroundColor: const Color(0xFF10110F),
              body: const CompanyDetailScreen(companyId: 'emp-01'),
              bottomNavigationBar: NfcBottomNavBar(
                currentIndex: 1,
                height: 72,
                padding: const EdgeInsets.only(bottom: 4),
                onDestinationSelected: (_) {},
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    await tester.runAsync(() async {
      final boundary = key.currentContext!.findRenderObject() as RenderRepaintBoundary;
      final image = await boundary.toImage(pixelRatio: 1.0);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      final pngBytes = byteData!.buffer.asUint8List();

      final outDir = Directory('harness/evidence/S05/attempt-01');
      if (!outDir.existsSync()) {
        outDir.createSync(recursive: true);
      }
      File('${outDir.path}/capture.png').writeAsBytesSync(pngBytes);
    });
  });

  testWidgets('Capture S05 alternate viewport', (tester) async {
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
    final actRepo = InMemoryActivityRepository();

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
          activityRepositoryProvider.overrideWithValue(actRepo),
        ],
        child: MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: AppTheme.darkTheme,
          home: RepaintBoundary(
            key: key,
            child: Scaffold(
              backgroundColor: const Color(0xFF10110F),
              body: const CompanyDetailScreen(companyId: 'emp-01'),
              bottomNavigationBar: NfcBottomNavBar(
                currentIndex: 1,
                height: 72,
                padding: const EdgeInsets.only(bottom: 4),
                onDestinationSelected: (_) {},
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    await tester.runAsync(() async {
      final boundary = key.currentContext!.findRenderObject() as RenderRepaintBoundary;
      final image = await boundary.toImage(pixelRatio: 1.0);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      final pngBytes = byteData!.buffer.asUint8List();

      final outDir = Directory('harness/evidence/S05/attempt-01');
      if (!outDir.existsSync()) {
        outDir.createSync(recursive: true);
      }
      File('${outDir.path}/alternate_viewport.png').writeAsBytesSync(pngBytes);
    });
  });
}
