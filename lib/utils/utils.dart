import 'dart:convert';
import 'dart:math';

import 'package:desktop_multi_window/desktop_multi_window.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_auto_gui/flutter_auto_gui.dart';
import 'package:process_run/process_run.dart';
import 'package:untitled/utils/local_storage.dart';

class EasyUtils {
  Future<void> createSongFile() async {
    final duration = localStore.get('duration');
    final delayDuration = duration == null
        ? Duration(milliseconds: 50)
        : Duration(milliseconds: int.parse(duration));
    await Shell().run(
        'start "" "C:\\Program Files (x86)\\Softouch\\EasyWorship 7\\EasyWorship.exe"');

    // mouse move function
    await FlutterAutoGUI.moveTo(
      point: const Point(32, 70),
      duration: const Duration(microseconds: 1),
    );

    await Future.delayed(delayDuration);

    await FlutterAutoGUI.click(
      button: MouseButton.left,
      // interval: const Duration(microseconds: 1),
    );

    await FlutterAutoGUI.moveTo(
      point: const Point(63, 129),
      duration: const Duration(microseconds: 1),
    );

    await Future.delayed(delayDuration);

    await FlutterAutoGUI.click(
      button: MouseButton.left,
    );

    await Future.delayed(delayDuration);

    // PASTE LYRICS
    await FlutterAutoGUI.hotkey(
      keys: ['ctrl', 'v'],
      interval: const Duration(microseconds: 1),
    );

    await Future.delayed(delayDuration);

    await FlutterAutoGUI.moveTo(
      point: const Point(320, 69),
      duration: const Duration(microseconds: 1),
    );

    await Future.delayed(delayDuration);

    await FlutterAutoGUI.click(
      button: MouseButton.left,
    );

    await FlutterAutoGUI.hotkey(
      keys: ['ctrl', 'v'],
      interval: const Duration(microseconds: 1),
    );
    await Future.delayed(delayDuration);

    await FlutterAutoGUI.moveTo(
      point: const Point(1275, 701),
      duration: const Duration(microseconds: 1),
    );

    await Future.delayed(delayDuration);

    await FlutterAutoGUI.click(
      button: MouseButton.left,
    );
    // await Future.delayed(delayDuration);
    if (localStore.getBool('sendLyrics')) {
      await FlutterAutoGUI.press(key: 'enter', times: 3);
    }
  }

  String removeDollyStrings(String text) {
    // Remove lines starting with (, {, or [
    List<String> lines = text.split('\n');
    lines.removeWhere((line) =>
        line.trimLeft().startsWith('(') ||
        line.trimLeft().startsWith('{') ||
        line.trimLeft().startsWith('['));

    // Remove specified occurrences
    String result = lines.join('\n');
    result = result.replaceAll('2ce', '');
    result = result.replaceAll('2x', '');
    result = result.replaceAll('(', '');
    result = result.replaceAll(')', '');
    result = result.replaceAll('.', '');
    result = result.replaceAll(',', '');
    result = result.replaceAll('Chorus', '');
    result = result.replaceAll('chorus', '');
    result = result.replaceAll('Verse', '');
    result = result.replaceAll('verse', '');
    result = result.replaceAll('Bridge', '');
    result = result.replaceAll('bridge', '');

    return result;
  }

  Future<void> copyClipboard(
    BuildContext context, [
    int indentation = 2,
  ]) async {
    final clipboardData = await Clipboard.getData(Clipboard.kTextPlain);
    final text = removeDollyStrings(clipboardData?.text ?? '');

    final indentedText2 = text.split('\n').asMap().entries.map((entry) {
      final index = entry.key;
      final line = entry.value;
      if (index % indentation == 0) {
        return '   \n\n$line';
      }
      return line;
    }).join('');

    final useful = ClipboardData(text: indentedText2.trimLeft());

    // Copy the indented text to the clipboard
    await Clipboard.setData(useful).then((value) async {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Text Formatted'),
        ),
      );
      await createSongFile();
    });
  }

  static Future<void> createTimerWindow() async {
    final windowMain = await DesktopMultiWindow.createWindow(jsonEncode({
      'args1': 'Timer window',
      'args2': 10,
      'args3': true,
      'window_type': 'main',
    }));
    final windowPreview = await DesktopMultiWindow.createWindow(jsonEncode({
      'args1': 'Preview window',
      'args2': 10,
      'args3': true,
      'window_type': 'preview',
    }));

    windowMain
      ..setFrame(const Offset(0, 0) & const Size(1920, 1080))
      ..show();

    windowPreview
      ..setFrame(const Offset(-1920, 0) & const Size(720, 450))
      ..show();
  }

  static Future<void> closeTimerWindows() async {
    try {
      final subWindowIds = await DesktopMultiWindow.getAllSubWindowIds();

      subWindowIds.forEach((element) {
        WindowController.fromWindowId(element).close();
      });
    } catch (e) {
      print(e);
    }
  }
}
