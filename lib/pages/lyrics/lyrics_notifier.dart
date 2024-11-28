import 'package:flutter/cupertino.dart';

final LyricsNotifier lyricsNotifier = LyricsNotifier();

class LyricsNotifier extends ChangeNotifier {
  final TextEditingController indentCtrl = TextEditingController();

  ValueNotifier<String> formattedText = ValueNotifier('');
}
