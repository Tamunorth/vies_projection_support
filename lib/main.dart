import 'dart:convert';

import 'package:desktop_multi_window/desktop_multi_window.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
// import 'package:media_kit/media_kit.dart';
import 'package:untitled/pages/home_page_alt.dart';
import 'package:untitled/pages/timer/timer_page.dart';
import 'package:untitled/utils/local_storage.dart';
import 'package:window_manager/window_manager.dart';

bool hasInitWindowManger = false;

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        textTheme: GoogleFonts.plusJakartaSansTextTheme(),
      ),
      home: HomePageAlt(),
    );
  }
}

void main(List<String> args) async {
  WidgetsFlutterBinding.ensureInitialized();

  // MediaKit.ensureInitialized();

  await localStore.init();
  // if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
  //   setWindowTitle('title here');
  // }

  if (args.firstOrNull == 'multi_window') {
    final windowId = int.parse(args[1]);
    final argument = args[2].isEmpty
        ? const {}
        : jsonDecode(args[2]) as Map<String, dynamic>;

    runApp(TimerSubWindow(
      windowController: WindowController.fromWindowId(windowId),
      args: argument,
    ));

    // Use it only after calling `hiddenWindowAtLaunch`
    windowManager.waitUntilReadyToShow().then((_) async {
// Hide window title bar
      await windowManager.setTitleBarStyle(TitleBarStyle.hidden);
      await windowManager.setFullScreen(true);
      await windowManager.center();
      await windowManager.show();
      await windowManager.setSkipTaskbar(false);
    });
  } else {
    if (!hasInitWindowManger) {
      await windowManager.ensureInitialized();
    }

    hasInitWindowManger = true;
    runApp(MyApp());
  }
}
