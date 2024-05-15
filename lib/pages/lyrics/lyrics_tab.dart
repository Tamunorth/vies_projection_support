import 'package:flutter/material.dart';
import 'package:untitled/utils/local_storage.dart';
import 'package:untitled/utils/utils.dart';

import '../../utils/button_widget.dart';
import '../timer/timer_page.dart';

class LyricsTab extends StatefulWidget {
  LyricsTab({
    super.key,
  });

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

  final EasyUtils utils = EasyUtils();

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
          const Text(
            'NB: Please switch off NUM LOCK',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 16,
              color: Colors.red,
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
              await utils.copyClipboard(
                context,
                int.parse(
                  indentCtrl.text.isNotEmpty
                      ? indentCtrl.text
                      : (localStore.get('indent') != null &&
                              localStore.get('indent')!.isNotEmpty)
                          ? localStore.get('indent')!
                          : '1',
                ),
              );

              localStore.setValue(
                'indent',
                indentCtrl.text.isNotEmpty ? indentCtrl.text : '1',
              );
            },
          ),
        ],
      ),
    );
  }
}
