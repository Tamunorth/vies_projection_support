import 'package:flutter/material.dart';
import 'package:vies_projection_support/pages/image_compress/image_compress.dart';
import 'package:vies_projection_support/pages/qr_code/qr_generator.dart';
import 'package:vies_projection_support/pages/settings/settings.dart';
import 'package:vies_projection_support/pages/timer/timer_page.dart';
import 'package:vies_projection_support/utils/local_storage.dart';
import 'package:vies_projection_support/utils/utils.dart';
import 'package:url_launcher/url_launcher_string.dart';

import '../utils/custom_nav_tile.dart';
import 'lyrics/lyrics_tab.dart';

ValueNotifier<int> globalIndentationValue = ValueNotifier(1);

// Navigation Item Model
class NavItem {
  final String title;
  final IconData icon;
  final Widget page;

  const NavItem({
    required this.title,
    required this.icon,
    required this.page,
  });
}

class HomePageAlt extends StatefulWidget {
  const HomePageAlt({super.key});

  @override
  State<HomePageAlt> createState() => _HomePageAltState();
}

class _HomePageAltState extends State<HomePageAlt> {
  final EasyUtils utils = EasyUtils();
  int _value = 0;

  // Define all navigation items
  late final List<NavItem> navigationItems = [
    NavItem(
      title: 'Lyrics',
      icon: Icons.music_note,
      page: ValueListenableBuilder(
        valueListenable: globalIndentationValue,
        builder: (context, value, child) {
          return LyricsTab(key: ValueKey(value));
        },
      ),
    ),
    // NavItem(
    //   title: 'Browser',
    //   icon: Icons.web,
    //   page: ExampleBrowser(),
    // ),
    NavItem(
      title: 'Timer',
      icon: Icons.timer,
      page: const TimerTab(),
    ),
    NavItem(
      title: 'Image Compress',
      icon: Icons.image,
      page: const ImageCompress(),
    ),
    NavItem(
      title: 'QR Generator',
      icon: Icons.image,
      page: const QrGenerator(),
    ),
    // NavItem(
    //   title: 'EasyWorship Viewer',
    //   icon: Icons.schedule,
    //   page: const EasyWorshipViewer(),
    // ),
    // NavItem(
    //   title: 'Video Modifier',
    //   icon: Icons.schedule,
    //   page: const VideoEditorPage(),
    // ),
    NavItem(
      title: 'Settings',
      icon: Icons.settings,
      page: SettingsPage(),
    ),
  ];

  @override
  void initState() {
    super.initState();
    init();
  }

  init() {
    globalIndentationValue.value = int.parse(
      (localStore.get('indent') != null && localStore.get('indent')!.isNotEmpty)
          ? localStore.get('indent')!
          : '1',
    );
    loadScreenDimensions();
  }

  @override
  Widget build(BuildContext context) {
    globalIndentationValue.value = int.parse(
      (localStore.get('indent') != null && localStore.get('indent')!.isNotEmpty)
          ? localStore.get('indent')!
          : '1',
    );

    return Scaffold(
      backgroundColor: const Color(0xff141414),
      body: Row(
        children: [
          Container(
            decoration: const BoxDecoration(
              color: Color(0xff262626),
            ),
            width: 300,
            height: MediaQuery.sizeOf(context).height,
            child: SingleChildScrollView(
              child: Column(
                children: [
                  const SizedBox(height: 50),
                  Image.asset(
                    'assets/logo.png',
                    width: 100,
                    height: 100,
                  ),
                  const SizedBox(height: 100),
                  Column(
                    children: [
                      // Navigation Items
                      ...navigationItems.asMap().entries.map((entry) {
                        final index = entry.key;
                        final item = entry.value;
                        return MyRadioListTile(
                          value: index,
                          groupValue: _value,
                          onChanged: (value) => setState(() => _value = value!),
                          title: item.title,
                          icon: item.icon,
                        );
                      }),

                      const SizedBox(height: 45),
                      // Footer section
                      InkWell(
                        onTap: () {
                          launchUrlString(
                              'https://www.linkedin.com/in/davies-manuel/');
                        },
                        child: const Row(
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
          ),
          Expanded(
            child: IndexedStack(
              index: _value,
              children: navigationItems.map((item) => item.page).toList(),
            ),
          )
        ],
      ),
    );
  }
}

enum AppTab { timer, lyrics, settings, browser }
