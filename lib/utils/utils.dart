import 'dart:convert';
import 'dart:math';
import 'dart:ui';

import 'package:collection/collection.dart';
import 'package:desktop_multi_window/desktop_multi_window.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_auto_gui/flutter_auto_gui.dart';
import 'package:process_run/process_run.dart';
import 'package:vies_projection_support/block_input.dart';
import 'package:vies_projection_support/utils/local_storage.dart';
import 'package:screen_retriever/screen_retriever.dart';
import '../pages/lyrics/lyrics_notifier.dart';

ValueNotifier<List<Display>> screenDimensions = ValueNotifier([]);

/// A helper function to load screen data using screen_retriever.
/// This should be called once when your app initializes.
Future<void> loadScreenDimensions() async {
  screenDimensions.value = await screenRetriever.getAllDisplays();
}

class EasyUtils {
  Future<void> createSongFile() async {
    final duration = localStore.get('duration');
    final delayDuration = duration == null
        ? Duration(milliseconds: 50)
        : Duration(milliseconds: int.parse(duration));
    await Shell().run(
        'start "" "C:\\Program Files (x86)\\Softouch\\EasyWorship 7\\EasyWorship.exe"');

    // await BlockInput.blockInput();

    final clipboardData = await Clipboard.getData(Clipboard.kTextPlain);

    final clipboardText = clipboardData?.text?.split('\n').firstOrNull;

    List<String>? chars = clipboardText?.characters.toList();

    // mouse move function
    await FlutterAutoGUI.moveTo(
      point: const Point(32, 70),
      duration: const Duration(microseconds: 1),
    );

    await Future.delayed(delayDuration);

    await FlutterAutoGUI.click(
      button: MouseButton.left, clicks: 1,
      // interval: const Duration(milliseconds: 1),
    );

    // PASTE LYRIC

    await Future.delayed(delayDuration);

    // await FlutterAutoGUI.press(
    //   key: 'down',
    //   times: 2,
    //   // interval: const Duration(microseconds: 1),
    // );

    //
    await BlockInput.downKey();
    await BlockInput.downKey();

    await Future.delayed(delayDuration);

    await FlutterAutoGUI.press(
      key: 'enter',
      interval: const Duration(microseconds: 1),
    );
    await Future.delayed(delayDuration);

    // PASTE LYRICS
    await FlutterAutoGUI.hotkey(
      keys: ['ctrl', 'v'],
      interval: const Duration(microseconds: 1),
    );

    await Future.delayed(delayDuration);

    await FlutterAutoGUI.moveTo(
      point: const Point(320, 76),
      duration: const Duration(microseconds: 1),
    );

    await Future.delayed(delayDuration);

    await FlutterAutoGUI.click(
      button: MouseButton.left,
    );
    //
    // await FlutterAutoGUI.hotkey(
    //   keys: ['ctrl', 'v'],
    //   interval: const Duration(microseconds: 1),
    // );

    ///PASTE JUST THE FIRST LINE AS TITLE
    await FlutterAutoGUI.hotkey(
      keys: chars ?? ['ctrl', 'v'],
      interval: const Duration(microseconds: 1),
    );
    await Future.delayed(delayDuration);

    ///CLICK OK

    await FlutterAutoGUI.press(
      key: 'tab',
      times: 5,
      interval: const Duration(microseconds: 1),
    );

    await FlutterAutoGUI.press(
      key: 'enter',
      times: 1,
      interval: const Duration(microseconds: 1),
    );

    await FlutterAutoGUI.moveTo(
      point: const Point(1275, 701),
      duration: const Duration(microseconds: 1),
    );

    await Future.delayed(delayDuration);

    await FlutterAutoGUI.click(
      button: MouseButton.left,
    );
    await Future.delayed(delayDuration);

    // await BlockInput.unblockInput();

    ///
    if (localStore.getBool('sendLyrics')) {
      await FlutterAutoGUI.press(key: 'enter', times: 3);
    }
  }

  // String removeDollyStrings(String text) {
  //   // Remove lines starting with (, {, or [
  //   List<String> lines = text.split('\n');
  //   lines.removeWhere((line) =>
  //       line.trimLeft().startsWith('Verse') ||
  //       line.trimLeft().startsWith('verse') ||
  //       line.trimLeft().startsWith('Chorus') ||
  //       line.trimLeft().startsWith('chorus'));
  //
  //   // Remove specified occurrences
  //   String result = lines.join('\n');
  //   result = result.replaceAll('2ce', '');
  //   result = result.replaceAll('...', '');
  //   result = result.replaceAll('2x', '');
  //   // result = result.replaceAll('(', '');
  //   // result = result.replaceAll(')', '');
  //   result = result.replaceAll('.', '');
  //   result = result.replaceAll(',', '');
  //   result = result.replaceAll('Chorus', '');
  //   result = result.replaceAll('chorus', '');
  //   result = result.replaceAll('Verse', '');
  //   result = result.replaceAll('verse', '');
  //   result = result.replaceAll('Bridge', '');
  //   result = result.replaceAll('bridge', '');
  //
  //   return result;
  // }

  String cleanLyrics(String input) {
    // Regular expressions to remove unwanted parts
    final removePatterns = [
      RegExp(r'\(\w+\)'),
      // Removes text in parentheses (e.g., (Chorus))
      RegExp(r'\[\w+.*?\]'),
      // Removes text in brackets (e.g., [remove this])
      RegExp(r'\d+x|x\d+'),
      // Removes repetitions like 2x, x3, etc.
      RegExp(r'2ce', caseSensitive: false),
      // Removes '2ce' case-insensitively
      RegExp(r'Verse \d+:'),
      // Removes 'Verse' with numbers and colon
      RegExp(r':'),
      // Removes standalone colons

      RegExp(r'[.,()\[\]{}]', caseSensitive: false),
      // Remove punctuation like (), [], {}, and ...
    ];

    // Clean input by applying all patterns
    String cleaned = input;
    for (var pattern in removePatterns) {
      cleaned = cleaned.replaceAll(pattern, '');
    }

    cleaned = cleaned
        .split('\n')
        .map((line) => line.trim())
        .where((line) => line.isNotEmpty)
        .join('\n');

    return cleaned;
  }

  Future<String?> copyClipboard(
    BuildContext context, {
    bool createSong = true,
    int indentation = 2,
    String? copiedText,
  }) async {
    final clipboardData = await Clipboard.getData(Clipboard.kTextPlain);

    final text = cleanLyrics(
      copiedText ?? (clipboardData?.text ?? ''),
    );

    final indentedText2 = text.split('\n').asMap().entries.map((entry) {
      final index = entry.key + 1;
      final line = entry.value;
      if (index % indentation == 0) {
        return '$line\n';
      }
      return line;
    }).join('\n');

    final useful = ClipboardData(text: indentedText2.trimLeft());

    // Copy the indented text to the clipboard
    await Clipboard.setData(useful).then((value) async {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Text Formatted'),
        ),
      );

      //UPDATE Lyrics View
      lyricsNotifier.formattedText.value = useful.text ?? '';

      if (createSong) {
        await createSongFile();
      }
    });
    return useful.text;
  }

  static Future<void> createTimerWindow() async {
    final allDisplays = await screenRetriever.getAllDisplays();

    // Reliably get the primary display.
    final primaryDisplay = await screenRetriever.getPrimaryDisplay();

    // Find a secondary display (if one exists).
    final secondaryDisplay =
        allDisplays.firstWhereOrNull((d) => d.id != primaryDisplay.id);

    // Create the window for the main output (on the secondary screen if available)
    final windowMain = await DesktopMultiWindow.createWindow(jsonEncode({
      'args1': 'Timer window',
      'args2': 10,
      'args3': true,
      'window_type': 'main',
    }));

    // Position on secondary display, or primary if it's the only one.

    if (secondaryDisplay != null) {
      final secondaryPosition =
          secondaryDisplay.visiblePosition ?? const Offset(0, 0);
      // The `&` operator here creates a Rect from an Offset and a Size.
      // This syntax is correct in Flutter.
      windowMain
        ..setFrame(secondaryPosition & secondaryDisplay.size)
        ..show();
    } else {
      final primaryPosition =
          primaryDisplay.visiblePosition ?? const Offset(0, 0);
      windowMain
        ..setFrame(primaryPosition & primaryDisplay.size)
        ..show();
    }

    // Create the window for the preview output (on the primary screen)
    final windowPreview = await DesktopMultiWindow.createWindow(jsonEncode({
      'args1': 'Preview window',
      'args2': 10,
      'args3': true,
      'window_type': 'preview',
    }));

    final primaryPosition =
        primaryDisplay.visiblePosition ?? const Offset(0, 0);
    final previewFrame = Offset(
          primaryPosition.dx,
          primaryPosition.dy + (primaryDisplay.size.height / 2),
        ) &
        Size(
          primaryDisplay.size.width / 2,
          primaryDisplay.size.height / 2.5,
        );

    windowPreview
      ..setFrame(previewFrame)
      ..show();
  }

  static Future<void> closeTimerWindows() async {
    try {
      final subWindowIds = await DesktopMultiWindow.getAllSubWindowIds();
      for (final id in subWindowIds) {
        WindowController.fromWindowId(id).close();
      }
    } catch (e) {
      print(e);
    }
  }
}
