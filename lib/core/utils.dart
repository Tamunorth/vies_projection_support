import 'dart:convert';
import 'dart:math';
import 'dart:ui';
import 'dart:developer' as dev;

import 'package:collection/collection.dart';
import 'package:desktop_multi_window/desktop_multi_window.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:process_run/process_run.dart';
import 'package:untitled/core/block_input.dart';
import 'package:untitled/core/local_storage.dart';
import 'package:screen_retriever/screen_retriever.dart';
import 'package:untitled/shared/snackbar.dart';
import 'package:untitled/core/win_automation.dart';
import '../pages/lyrics/lyrics_notifier.dart';

ValueNotifier<List<Display>> screenDimensions = ValueNotifier([]);

/// A helper function to load screen data using screen_retriever.
/// This should be called once when your app initializes.
Future<void> loadScreenDimensions() async {
  screenDimensions.value = await screenRetriever.getAllDisplays();
}

class EasyUtils {
  final automation = EasyWorshipAutomation();

  Future<void> createSongFile() async {
    final duration = localStore.get('duration');
    final delayDuration = duration == null
        ? Duration(milliseconds: 300)
        : Duration(milliseconds: int.parse(duration));
    await Shell().run(
        'start "" "C:\\Program Files (x86)\\Softouch\\EasyWorship 7\\EasyWorship.exe"');

    final clipboardData = await Clipboard.getData(Clipboard.kTextPlain);

    final songTitle = clipboardData?.text?.split('\n').firstOrNull;

    await automation.openNewSongDialog();

    await Future.delayed(delayDuration);

    await automation.fillSongDialog(songTitle ?? '', delay: delayDuration);
  }

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

      RegExp(r'[.,\[\]{}]', caseSensitive: false),
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
      CustomNotification.show(
        context,
        "Text Formatted",
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
