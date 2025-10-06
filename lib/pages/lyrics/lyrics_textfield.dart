import 'package:flutter/material.dart';

class LyricsDisplay extends StatelessWidget {
  final String lyrics;

  const LyricsDisplay({
    super.key,
    required this.lyrics,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      child: SingleChildScrollView(
        child: TextField(
          controller: TextEditingController(text: lyrics),
          maxLines: 14,
          minLines: 14,
          textAlign: TextAlign.left,
          decoration: InputDecoration(
            contentPadding: EdgeInsets.all(12),
            hintText: 'Enter or Paste lyrcs here',
          ),
        ),
      ),
    );
  }
}
