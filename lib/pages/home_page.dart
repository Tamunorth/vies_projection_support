import 'package:flutter/material.dart';
import 'package:untitled/pages/browser/t_browser_alt.dart';
import 'package:untitled/pages/settings/settings.dart';
import 'package:untitled/pages/timer/timer_page.dart';
import 'package:untitled/utils/utils.dart';
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

  AppTab _value = AppTab.lyrics;

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    getList();
  }

  getList() async {
    final list = await getScreenList();

    list?.forEach((element) {
      print(element.frame);
    });
    final screen = await getCurrentScreen();

    print(screen?.visibleFrame);
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
                        value: AppTab.lyrics,
                        groupValue: _value,
                        onChanged: (value) => setState(() => _value = value!),
                        title: "Lyrics",
                        icon: Icons.music_note,
                      ),
                      MyRadioListTile(
                        value: AppTab.browser,
                        groupValue: _value,
                        onChanged: (value) => setState(() => _value = value!),
                        title: "Browser",
                        icon: Icons.web,
                      ),
                      MyRadioListTile(
                        value: AppTab.timer,
                        groupValue: _value,
                        onChanged: (value) => setState(() => _value = value!),
                        title: "Timer",
                        icon: Icons.timer,
                      ),
                      SizedBox(
                        height: 45,
                      ),
                      MyRadioListTile(
                        value: AppTab.settings,
                        groupValue: _value,
                        onChanged: (value) => setState(() => _value = value!),
                        title: "Settings",
                        icon: Icons.settings,
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Expanded(child: Builder(builder: (context) {
              if (_value == AppTab.lyrics) {
                return LyricsTab(utils: utils);
              }

              if (_value == AppTab.settings) {
                return SettingsPage();
              }
              if (_value == AppTab.browser) {
                return BrowserWindow();
              }

              return TimerTab();
            })),
          ],
        ));
  }
}

enum AppTab { timer, lyrics, settings, browser }
