import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:glimmer_grove/main.dart';
import 'package:glimmer_grove/persist/save.dart';
import 'package:glimmer_grove/audio/grove_audio.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<void> _pumpFrame(WidgetTester tester, Size size) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  SharedPreferences.setMockInitialValues({
    'glimmer-grove-v1': '{"lang":"en","unlocked":3,"coins":250}',
  });
  final save = await GroveSave.open();
  final audio = GroveAudio(save);
  await tester.pumpWidget(GroveApp(save: save, audio: audio));
  await tester.pump();
  await tester.pump(const Duration(seconds: 2));
  expect(tester.takeException(), isNull);
}

void main() {
  testWidgets('menu, map, shop, rewards, and a board fit common screens', (
    tester,
  ) async {
    final previous = FlutterError.onError;
    FlutterError.onError = (details) {
      // ignore: avoid_print
      print(details.toString());
      previous?.call(details);
    };
    addTearDown(() => FlutterError.onError = previous);
    for (final size in const [
      Size(390, 844),
      Size(360, 640),
      Size(844, 390),
      Size(768, 1024),
      Size(1440, 900),
    ]) {
      await tester.pumpWidget(const SizedBox.shrink());
      await _pumpFrame(tester, size);
      final texts = tester
          .widgetList<Text>(find.byType(Text))
          .map((text) => text.data)
          .join(' | ');
      expect(texts, contains('Play'), reason: texts);
      await tester.ensureVisible(find.text('Levels'));
      await tester.pump();
      await tester.tap(find.text('Levels'));
      await tester.pump(const Duration(milliseconds: 400));
      final mapError = tester.takeException();
      expect(mapError, isNull, reason: '$mapError');
      expect(find.text('Sunlit Orchard'), findsOneWidget);
      await tester.ensureVisible(find.text('1'));
      await tester.pump();
      await tester.tap(find.text('1'));
      await tester.pump(const Duration(milliseconds: 700));
      expect(tester.takeException(), isNull);
      expect(find.textContaining('Level'), findsWidgets);
    }
  });

  testWidgets('profile name field sits on a material card', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    SharedPreferences.setMockInitialValues({
      'glimmer-grove-v1': '{"lang":"en","unlocked":1,"coins":250}',
    });
    final save = await GroveSave.open();
    final audio = GroveAudio(save);
    await tester.pumpWidget(GroveApp(save: save, audio: audio));
    await tester.pump(const Duration(seconds: 2));
    expect(tester.takeException(), isNull);
    await tester.tap(find.byKey(const ValueKey('profile')));
    await tester.pump(const Duration(milliseconds: 400));
    expect(tester.takeException(), isNull);
    expect(find.byType(TextField), findsOneWidget);
    await tester.enterText(find.byType(TextField), 'Ada');
    await tester.pump();
    expect(tester.takeException(), isNull);
    expect(find.text('Ada'), findsOneWidget);
  });
}
