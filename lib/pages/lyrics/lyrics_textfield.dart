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
      color: Colors.white,
      height: 300,
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: TextField(
            controller: TextEditingController(text: lyrics),
            maxLines: null,
            minLines: 10,
            style: TextStyle(
              fontSize: 16,
              height: 1.5,
              fontFamily: 'Monospace',
            ),
            decoration: const InputDecoration(
              border: InputBorder.none,
              contentPadding: EdgeInsets.zero,
            ),
            textAlign: TextAlign.left,
          ),
        ),
      ),
    );
  }
}
