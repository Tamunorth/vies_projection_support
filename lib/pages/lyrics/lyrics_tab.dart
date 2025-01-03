import 'package:flutter/material.dart';
import 'package:untitled/pages/lyrics/lyrics_notifier.dart';
import 'package:untitled/pages/lyrics/lyrics_textfield.dart';
import 'package:untitled/utils/local_storage.dart';
import 'package:untitled/utils/utils.dart';

import '../../utils/button_widget.dart';
import '../timer/timer_page.dart';

class LyricsTab extends StatefulWidget {
  LyricsTab({
    super.key,
    // required this.indetationVal,
  });

  // final String indetationVal;

  @override
  State<LyricsTab> createState() => _LyricsTabState();
}

class _LyricsTabState extends State<LyricsTab> {
  final pref = localStore;

  @override
  void didUpdateWidget(covariant LyricsTab oldWidget) {
    super.didUpdateWidget(oldWidget);
    lyricsNotifier.indentCtrl.text = pref.get('indent') ?? '';
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    lyricsNotifier.indentCtrl.text = pref.get('indent') ?? '';
  }

  @override
  void initState() {
    super.initState();
    lyricsNotifier.indentCtrl.text = pref.get('indent') ?? '';
  }

  final EasyUtils utils = EasyUtils();

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 100),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(height: 40),
            ValueListenableBuilder(
                valueListenable: lyricsNotifier.formattedText,
                builder: (context, text, _) {
                  return LyricsDisplay(lyrics: text);
                }),
            // const Text(
            //   'Convert lyric text to EasyWorship slides with ease',
            //   textAlign: TextAlign.center,
            //   style: TextStyle(
            //     fontSize: 48,
            //     color: Colors.white,
            //     fontWeight: FontWeight.w700,
            //   ),
            // ),
            const SizedBox(
              height: 20,
            ),
            const Text(
              'Simplify your worship slide preparations and enhance your presentations',
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
              minutesCtrl: lyricsNotifier.indentCtrl,
              onChanged: (value) {
                if (value.isNotEmpty) {
                  localStore.setValue(
                    'indent',
                    lyricsNotifier.indentCtrl.text.isNotEmpty
                        ? lyricsNotifier.indentCtrl.text
                        : '1',
                  );
                }
              },
            ),
            ButtonWidget(
              title: 'Format Text',
              onTap: () async {
                lyricsNotifier.formattedText.value = await utils.copyClipboard(
                      context,
                      createSong: localStore.getBool('openEasyWorship'),
                      indentation: int.parse(
                        lyricsNotifier.indentCtrl.text.isNotEmpty
                            ? lyricsNotifier.indentCtrl.text
                            : (localStore.get('indent') != null &&
                                    localStore.get('indent')!.isNotEmpty)
                                ? localStore.get('indent')!
                                : '1',
                      ),
                    ) ??
                    '';
              },
            ),
          ],
        ),
      ),
    );
  }
}
