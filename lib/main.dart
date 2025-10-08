import 'dart:convert';

import 'package:desktop_multi_window/desktop_multi_window.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:untitled/core/analytics.dart';
// import 'package:media_kit/media_kit.dart';
import 'package:untitled/pages/home_page.dart';
import 'package:untitled/pages/timer/timer_page.dart';
import 'package:untitled/core/local_storage.dart';
import 'package:window_manager/window_manager.dart';

bool hasInitWindowManger = false;

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
          textTheme: GoogleFonts.poppinsTextTheme().copyWith(
            bodyLarge: GoogleFonts.poppins(
              color: Colors.white,
              fontSize: 14,
            ),
            bodyMedium: GoogleFonts.poppins(color: Colors.white),
          ),
          scrollbarTheme: ScrollbarThemeData(
            thumbColor: WidgetStatePropertyAll(Colors.grey.withOpacity(0.5)),
            trackColor: MaterialStateProperty.all(Colors.transparent),
            trackBorderColor: MaterialStateProperty.all(Colors.transparent),
            radius: Radius.circular(0),
            thickness: MaterialStateProperty.all(8),
            thumbVisibility: MaterialStateProperty.all(true),
          ),
          inputDecorationTheme: InputDecorationTheme(
            filled: true,
            fillColor: Color(0xff262626),
            hintStyle: TextStyle(color: Colors.white.withOpacity(0.5)),
            labelStyle: TextStyle(color: Colors.white),
            contentPadding: EdgeInsets.all(24.0),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.zero,
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.zero,
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.zero,
              borderSide: BorderSide.none,
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.zero,
              borderSide: BorderSide(color: Colors.red),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.zero,
              borderSide: BorderSide(color: Colors.red),
            ),
          )),
      home: HomePageAlt(),
    );
  }
}

void main(List<String> args) async {
  WidgetsFlutterBinding.ensureInitialized();

  await localStore.init();
  // if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
  //   setWindowTitle('title here');
  // }

  await Analytics.instance.initialize(
    "ubruc6OOoJ1hTsfu",
    debug: kDebugMode,
    sessionExpiration: Duration(minutes: 30),
  );

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
    // windowManager.waitUntilReadyToShow().then((_) async {
// Hide window title bar

    // });

    // WindowOptions windowOptions = WindowOptions(
    //   size: Size(800, 600),
    //   center: true,
    //   backgroundColor: Colors.transparent,
    //   skipTaskbar: false,
    //   titleBarStyle: TitleBarStyle.hidden,
    // );
    // await windowManager.show();
    // await windowManager.setSkipTaskbar(false);
    // await windowManager.setFullScreen(true);
    // await windowManager.focus();
  } else {
    if (!hasInitWindowManger) {
      await windowManager.ensureInitialized();
    }

    hasInitWindowManger = true;
    runApp(MyApp());
  }
}
