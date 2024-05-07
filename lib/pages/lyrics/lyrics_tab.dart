import 'package:flutter/material.dart';
import 'package:untitled/utils/local_storage.dart';
import 'package:untitled/utils/utils.dart';

import '../../utils/button_widget.dart';
import '../timer/timer_page.dart';

class LyricsTab extends StatefulWidget {
  LyricsTab({
    super.key,
    required this.utils,
  });

  final EasyUtils utils;

  @override
  State<LyricsTab> createState() => _LyricsTabState();
}

class _LyricsTabState extends State<LyricsTab> {
  final TextEditingController indentCtrl = TextEditingController();

  @override
  void initState() {
    // TODO: implement initState
    super.initState();

    indentCtrl.text = localStore.get('indent') ?? '2';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 100),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text(
            'Convert lyric text to EasyWorship slides with ease',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 48,
              color: Colors.white,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(
            height: 40,
          ),
          const Text(
            'Simplify your worship slide preparations and enhance your presentations with SongSync',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 16,
              color: Colors.white,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(
            height: 40,
          ),
          TimerTextField(
            hint: "Indentation",
            paddingVert: 20,
            minutesCtrl: indentCtrl,
          ),
          ButtonWidget(
            title: 'Format Text',
            onTap: () async {
              await widget.utils.copyClipboard(
                context,
                int.parse(
                  (localStore.get('indent') != null &&
                          localStore.get('indent')!.isNotEmpty)
                      ? localStore.get('indent')!
                      : indentCtrl.text,
                ),
              );

              await localStore.setValue('indent', indentCtrl.text);
            },
          ),
        ],
      ),
    );
  }
}
