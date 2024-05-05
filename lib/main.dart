import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_auto_gui/flutter_auto_gui.dart';
import 'package:process_run/process_run.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      home: LandingPage(),
    );
  }
}

class LandingPage extends StatelessWidget {
  const LandingPage({
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        body: Padding(
      padding: const EdgeInsets.symmetric(vertical: 24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Row(
            children: [],
          ),
          ButtonWidget(
            title: 'FORMAT TEXT',
            onTap: () async {
              // bool runInShell = Platform.isWindows;
              final clipboardData =
                  await Clipboard.getData(Clipboard.kTextPlain);
              final text = clipboardData?.text;

              final indentedText2 =
                  text?.split('\n').asMap().entries.map((entry) {
                final index = entry.key;
                final line = entry.value;
                if (index % 1 == 0) {
                  return '   \n\n$line';
                }
                return line;
              }).join('');

              final useful = ClipboardData(text: indentedText2 ?? '');
              print(indentedText2);

              // Copy the indented text to the clipboard
              await Clipboard.setData(useful).then((value) async {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Text Formatted'),
                  ),
                );
                await _createSongFile();
              });
            },
          ),
          // ButtonWidget(
          //   title: 'FORMAT IMAGE',
          //   onTap: () async {
          //
          //     // Navigator.of(context).push(
          //     //     MaterialPageRoute(builder: (context) => DragDropPage()));
          //   },
          // ),
        ],
      ),
    ));
  }

  Future<void> _createSongFile() async {
    await Shell().run(
        'start "" "C:\\Program Files (x86)\\Softouch\\EasyWorship 7\\EasyWorship.exe"');

    // mouse move function
    await FlutterAutoGUI.moveTo(
      point: const Point(32, 70),
      duration: const Duration(microseconds: 1),
    );

    await Future.delayed(Duration(milliseconds: 50));

    await FlutterAutoGUI.click(
      button: MouseButton.left,
      // interval: const Duration(microseconds: 1),
    );

    await FlutterAutoGUI.moveTo(
      point: const Point(63, 129),
      duration: const Duration(microseconds: 1),
    );

    await Future.delayed(Duration(milliseconds: 50));

    await FlutterAutoGUI.click(
      button: MouseButton.left,
    );
    await Future.delayed(Duration(milliseconds: 50));

    //
    // await FlutterAutoGUI.press(
    //   key: "down",
    //   interval: Duration.zero,
    // );
    //
    await FlutterAutoGUI.hotkey(
      keys: ['ctrl', 'v'],
      interval: const Duration(microseconds: 1),
    );

    await FlutterAutoGUI.moveTo(
      point: const Point(367, 164),
      duration: const Duration(microseconds: 1),
    );

    await Future.delayed(Duration(milliseconds: 50));

    await FlutterAutoGUI.click(
      button: MouseButton.left,
    );

    await FlutterAutoGUI.hotkey(
      keys: ['ctrl', 'v'],
      interval: const Duration(microseconds: 1),
    );
    await Future.delayed(Duration(milliseconds: 50));

    await FlutterAutoGUI.moveTo(
      point: const Point(1377, 799),
      duration: const Duration(microseconds: 1),
    );

    await Future.delayed(Duration(milliseconds: 50));

    await FlutterAutoGUI.click(
      button: MouseButton.left,
    );
  }
}

class ButtonWidget extends StatelessWidget {
  const ButtonWidget({
    Key? key,
    this.onTap,
    required this.title,
  }) : super(key: key);

  final VoidCallback? onTap;
  final String title;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: EdgeInsets.all(24),
        height: 50,
        width: 150,
        decoration: BoxDecoration(
          color: Colors.blue,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Center(
          child: Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }
}
