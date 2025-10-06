// import 'package:flutter/material.dart';
// import 'package:untitled/pages/image_compress/image_compress.dart';
// import 'package:untitled/pages/qr_code/qr_generator.dart';
// import 'package:untitled/pages/schedule_editor/easyworship_viewer.dart';
// import 'package:untitled/pages/settings/settings.dart';
// import 'package:untitled/pages/timer/timer_page.dart';
// import 'package:untitled/utils/local_storage.dart';
// import 'package:untitled/utils/utils.dart';
// import 'package:url_launcher/url_launcher_string.dart';
// import 'package:window_size/window_size.dart';

// import '../utils/custom_nav_tile.dart';
// import 'lyrics/lyrics_tab.dart';

// class HomePage extends StatefulWidget {
//   HomePage({
//     super.key,
//   });

//   @override
//   State<HomePage> createState() => _HomePageState();
// }

// class _HomePageState extends State<HomePage> {
//   final EasyUtils utils = EasyUtils();

//   int _value = 0;

//   @override
//   void didChangeDependencies() {
//     // TODO: implement didChangeDependencies
//     super.didChangeDependencies();
//     getList();
//   }

//   @override
//   void didUpdateWidget(covariant HomePage oldWidget) {
//     // TODO: implement didUpdateWidget
//     super.didUpdateWidget(oldWidget);
//     getList();
//   }

//   @override
//   void initState() {
//     // TODO: implement initState
//     super.initState();
//     getList();
//   }

//   getList() async {
//     globalIndentationValue.value = int.parse(
//       (localStore.get('indent') != null && localStore.get('indent')!.isNotEmpty)
//           ? localStore.get('indent')!
//           : '1',
//     );
//     final list = await getScreenList();

//     screenDimensions.value = list;

//     list?.forEach((element) {
//       print(element.frame);
//     });

//     final screen = await getCurrentScreen();

//     // print(screen?.visibleFrame);
//   }

//   final pages = [
//     ValueListenableBuilder(
//         valueListenable: globalIndentationValue,
//         builder: (context, value, child) {
//           return LyricsTab(
//             key: ValueKey(value),
//             // indetationVal: value.toString(),
//           );
//         }),
//     // ExampleBrowser(),
//     TimerTab(),
//     ImageCompress(),
//     QrGenerator(),
//     EasyWorshipViewer(),
//     SettingsPage(),
//   ];

//   @override
//   Widget build(BuildContext context) {
//     globalIndentationValue.value = int.parse(
//       (localStore.get('indent') != null && localStore.get('indent')!.isNotEmpty)
//           ? localStore.get('indent')!
//           : '1',
//     );
//     return Scaffold(
//         backgroundColor: Color(0xff141414),
//         body: Row(
//           children: [
//             Container(
//               decoration: BoxDecoration(color: Color(0xff262626)),
//               width: 300,
//               child: SingleChildScrollView(
//                 child: Column(
//                   children: [
//                     SizedBox(
//                       height: 50,
//                     ),
//                     Image.asset(
//                       'assets/logo.png',
//                       width: 100,
//                       height: 100,
//                     ),
//                     SizedBox(
//                       height: 100,
//                     ),
//                     Column(
//                       children: [
//                         MyRadioListTile(
//                           value: 0,
//                           groupValue: _value,
//                           onChanged: (value) => setState(() => _value = value!),
//                           title: "Lyrics",
//                           icon: Icons.music_note,
//                         ),
//                         MyRadioListTile(
//                           value: 1,
//                           groupValue: _value,
//                           onChanged: (value) => setState(() => _value = value!),
//                           title: "Browser",
//                           icon: Icons.web,
//                         ),
//                         MyRadioListTile(
//                           value: 2,
//                           groupValue: _value,
//                           onChanged: (value) => setState(() => _value = value!),
//                           title: "Timer",
//                           icon: Icons.timer,
//                         ),
//                         MyRadioListTile(
//                           value: 3,
//                           groupValue: _value,
//                           onChanged: (value) => setState(() => _value = value!),
//                           title: "Image Compress",
//                           icon: Icons.image,
//                         ),
//                         MyRadioListTile(
//                           value: 4,
//                           groupValue: _value,
//                           onChanged: (value) => setState(() => _value = value!),
//                           title: "QR Generator",
//                           icon: Icons.image,
//                         ),
//                         MyRadioListTile(
//                           value: 5,
//                           groupValue: _value,
//                           onChanged: (value) => setState(() => _value = value!),
//                           title: "EasyWorship Viewer",
//                           icon: Icons.schedule,
//                         ),
//                         SizedBox(
//                           height: 45,
//                         ),
//                         MyRadioListTile(
//                           value: 6,
//                           groupValue: _value,
//                           onChanged: (value) => setState(() => _value = value!),
//                           title: "Settings",
//                           icon: Icons.settings,
//                         ),
//                         SizedBox(
//                           height: 45,
//                         ),
//                         InkWell(
//                           onTap: () {
//                             launchUrlString(
//                                 'https://www.linkedin.com/in/davies-manuel/');
//                           },
//                           child: Row(
//                             children: [
//                               SizedBox(width: 24),
//                               Text(
//                                 '@Tamunorth',
//                                 style: TextStyle(color: Colors.white),
//                               ),
//                             ],
//                           ),
//                         )
//                       ],
//                     ),
//                   ],
//                 ),
//               ),
//             ),
//             Expanded(
//                 child: IndexedStack(
//               index: _value,
//               children: pages,
//             ))
//           ],
//         ));
//   }
// }

// enum AppTab { timer, lyrics, settings, browser }
