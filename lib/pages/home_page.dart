import 'package:flutter/material.dart';
import 'package:untitled/pages/browser/t_browser_alt.dart';
import 'package:untitled/pages/settings/settings.dart';
import 'package:untitled/pages/timer/timer_page.dart';
import 'package:untitled/utils/utils.dart';
import 'package:url_launcher/url_launcher_string.dart';
import 'package:window_size/window_size.dart';

import '../utils/custom_nav_tile.dart';
import 'lyrics/lyrics_tab.dart';

class HomePage extends StatefulWidget {
  HomePage({
    super.key,
  });

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final EasyUtils utils = EasyUtils();

  int _value = 0;

  final pages = [
    LyricsTab(),
    ExampleBrowser(),
    TimerTab(),
    SettingsPage(),
  ];

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    getList();
  }

  getList() async {
    final list = await getScreenList();

    screenDimensions.value = list;

    list?.forEach((element) {
      print(element.frame);
    });

    final screen = await getCurrentScreen();

    // print(screen?.visibleFrame);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        backgroundColor: Color(0xff141414),
        body: Row(
          children: [
            Container(
              decoration: BoxDecoration(color: Color(0xff262626)),
              width: 300,
              child: Column(
                children: [
                  SizedBox(
                    height: 50,
                  ),
                  Image.asset(
                    'assets/logo.png',
                    width: 100,
                    height: 100,
                  ),
                  SizedBox(
                    height: 100,
                  ),
                  Column(
                    children: [
                      MyRadioListTile(
                        value: 0,
                        groupValue: _value,
                        onChanged: (value) => setState(() => _value = value!),
                        title: "Lyrics",
                        icon: Icons.music_note,
                      ),
                      MyRadioListTile(
                        value: 1,
                        groupValue: _value,
                        onChanged: (value) => setState(() => _value = value!),
                        title: "Browser",
                        icon: Icons.web,
                      ),
                      MyRadioListTile(
                        value: 2,
                        groupValue: _value,
                        onChanged: (value) => setState(() => _value = value!),
                        title: "Timer",
                        icon: Icons.timer,
                      ),
                      SizedBox(
                        height: 45,
                      ),
                      MyRadioListTile(
                        value: 3,
                        groupValue: _value,
                        onChanged: (value) => setState(() => _value = value!),
                        title: "Settings",
                        icon: Icons.settings,
                      ),
                      SizedBox(
                        height: 45,
                      ),
                      InkWell(
                        onTap: () {
                          launchUrlString(
                              'https://www.linkedin.com/in/davies-manuel/');
                        },
                        child: Row(
                          children: [
                            SizedBox(width: 24),
                            Text(
                              '@Tamunorth',
                              style: TextStyle(color: Colors.white),
                            ),
                          ],
                        ),
                      )
                    ],
                  ),
                ],
              ),
            ),
            Expanded(
                child: IndexedStack(
              index: _value,
              children: pages,
            ))
          ],
        ));
  }
}

enum AppTab { timer, lyrics, settings, browser }
