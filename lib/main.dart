import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'audio/grove_audio.dart';
import 'persist/save.dart';
import 'screens/shell.dart';
import 'theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]);
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Color(0x00000000),
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: night,
    ),
  );
  final save = await GroveSave.open();
  final audio = GroveAudio(save);
  runApp(GroveApp(save: save, audio: audio));
}

class GroveApp extends StatelessWidget {
  const GroveApp({super.key, required this.save, required this.audio});
  final GroveSave save;
  final GroveAudio audio;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Glimmer Grove',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: night,
        splashFactory: NoSplash.splashFactory,
        fontFamily: 'Nunito',
        colorScheme: ColorScheme.fromSeed(
          seedColor: goldDeep,
          brightness: Brightness.dark,
        ),
      ),
      home: GroveShell(save: save, audio: audio),
    );
  }
}
