import 'package:flutter/material.dart';
import 'package:untitled/pages/timer/timer_page.dart';

import '../utils/button_widget.dart';
import '../utils/local_storage.dart';

class SettingsPage extends StatefulWidget {
  SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  final durationTimer = TextEditingController();
  final intentation = TextEditingController();
  final screenWidth = TextEditingController();
  final screenHeight = TextEditingController();

  final pref = localStore;

  @override
  void initState() {
    // TODO: implement initState
    super.initState();

    durationTimer.text = pref.get('duration') ?? '';

    intentation.text = pref.get('indent') ?? '';
    screenWidth.text = pref.get('screenWidth') ?? '';
    screenHeight.text = pref.get('screenHeight') ?? '';
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: EdgeInsets.symmetric(horizontal: 34),
      child: Column(
        children: [
          SizedBox(
            height: 50,
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: ListTile(
                  title: Text(
                    'Delay Duration (milliseconds)',
                    style: TextStyle(fontSize: 24, color: Colors.white),
                  ),
                  subtitle: Text(
                    'How long to wait between commands (useful for not so performant hardware)',
                    style: TextStyle(fontSize: 14, color: Colors.grey),
                  ),
                ),
              ),
              TimerTextField(
                minutesCtrl: durationTimer,
                hint: 'Delay Duration',
              ),
            ],
          ),
          SizedBox(
            height: 20,
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: ListTile(
                  title: Text(
                    'Default Indentation',
                    style: TextStyle(fontSize: 24, color: Colors.white),
                  ),
                  subtitle: Text(
                    'Lyrics indentation',
                    style: TextStyle(fontSize: 14, color: Colors.grey),
                  ),
                ),
              ),
              TimerTextField(
                minutesCtrl: intentation,
                hint: 'Delay Indentation',
              ),
            ],
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: ListTile(
                  title: Text(
                    'Go live after formatting',
                    style: TextStyle(fontSize: 24, color: Colors.white),
                  ),
                  subtitle: Text(
                    'Send the formatted lyrics to the screen automatically',
                    style: TextStyle(fontSize: 14, color: Colors.grey),
                  ),
                ),
              ),
              SizedBox(
                width: 100,
                height: 100,
                child: Checkbox(
                  value: localStore.getBool('sendLyrics'),
                  onChanged: (value) {
                    setState(() {
                      localStore.setBool('sendLyrics', value ?? false);
                    });
                  },
                ),
              ),
            ],
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: ListTile(
                  title: Text(
                    'Screen Width',
                    style: TextStyle(fontSize: 24, color: Colors.white),
                  ),
                ),
              ),
              TimerTextField(
                minutesCtrl: screenWidth,
                hint: '1920',
              ),
            ],
          ),
          SizedBox(
            height: 50,
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: ListTile(
                  title: Text(
                    'Screen Height',
                    style: TextStyle(fontSize: 24, color: Colors.white),
                  ),
                ),
              ),
              TimerTextField(
                minutesCtrl: screenHeight,
                hint: '1080',
              ),
            ],
          ),
          ButtonWidget(
            title: 'Save Updates',
            onTap: () async {
              pref.setValue('duration', durationTimer.text);

              pref.setValue('indent', intentation.text);

              pref.setValue('screenWidth',
                  screenWidth.text.isEmpty ? '1920' : screenWidth.text);
              pref.setValue('screenHeight',
                  screenHeight.text.isEmpty ? '1080' : screenHeight.text);

              ScaffoldMessenger.of(context)
                  .showSnackBar(SnackBar(content: Text('Saved!')));
            },
          ),
          SizedBox(
            height: 60,
          ),
          Text(
            'Help',
            style: TextStyle(fontSize: 24, color: Colors.white),
          ),
          Text(
            'Ensure the song tab is just after the "Help" tab on your easyworship window as shown below',
            style: TextStyle(fontSize: 14, color: Colors.grey),
          ),
          SizedBox(
            height: 20,
          ),
          Image.asset('assets/example.png'),
        ],
      ),
    );
  }
}
