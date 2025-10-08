import 'package:flutter/material.dart';
import 'package:untitled/pages/home_page.dart';
import 'package:untitled/pages/timer/timer_page.dart';
import 'package:untitled/shared/snackbar.dart';

import '../../shared/button_widget.dart';
import '../../core/local_storage.dart';

class SettingsPage extends StatefulWidget {
  SettingsPage({super.key});

  static final pageId = 'settings_page';

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  final durationTimer = TextEditingController();
  final intentation = TextEditingController();
  final screenWidth = TextEditingController();
  final screenHeight = TextEditingController();
  final easyWorshipPath = TextEditingController();

  final pref = localStore;

  // Store initial values
  late String _initialDuration;
  late String _initialIntentation;
  late String _initialScreenWidth;
  late String _initialScreenHeight;
  late bool _initialOpenEasyWorship;

  // Current checkbox value
  bool _openEasyWorship = false;

  // Track if anything has changed
  bool _hasChanges = false;

  @override
  void initState() {
    super.initState();

    // Load initial values
    _initialDuration = pref.get('duration') ?? '';
    _initialIntentation = pref.get('indent') ?? '';
    _initialScreenWidth = pref.get('screenWidth') ?? '';
    _initialScreenHeight = pref.get('screenHeight') ?? '';
    _initialOpenEasyWorship = localStore.getBool('openEasyWorship');

    // Set text controllers
    durationTimer.text = _initialDuration;
    intentation.text = _initialIntentation;
    screenWidth.text = _initialScreenWidth;
    screenHeight.text = _initialScreenHeight;
    _openEasyWorship = _initialOpenEasyWorship;

    // Add listeners to text fields
    durationTimer.addListener(_checkForChanges);
    intentation.addListener(_checkForChanges);
    screenWidth.addListener(_checkForChanges);
    screenHeight.addListener(_checkForChanges);
  }

  @override
  void dispose() {
    // Remove listeners
    durationTimer.removeListener(_checkForChanges);
    intentation.removeListener(_checkForChanges);
    screenWidth.removeListener(_checkForChanges);
    screenHeight.removeListener(_checkForChanges);

    // Dispose controllers
    durationTimer.dispose();
    intentation.dispose();
    screenWidth.dispose();
    screenHeight.dispose();
    easyWorshipPath.dispose();

    super.dispose();
  }

  // Check if any values have changed
  void _checkForChanges() {
    final hasChanges = durationTimer.text != _initialDuration ||
        intentation.text != _initialIntentation ||
        screenWidth.text != _initialScreenWidth ||
        screenHeight.text != _initialScreenHeight ||
        _openEasyWorship != _initialOpenEasyWorship;

    if (hasChanges != _hasChanges) {
      setState(() {
        _hasChanges = hasChanges;
      });
    }
  }

  // Save and reset initial values
  void _saveSettings() {
    pref.setValue(
        'duration', durationTimer.text.isEmpty ? '50' : durationTimer.text);

    pref.setValue('indent', intentation.text.isEmpty ? '2' : intentation.text);

    pref.setValue(
        'screenWidth', screenWidth.text.isEmpty ? '1920' : screenWidth.text);
    pref.setValue(
        'screenHeight', screenHeight.text.isEmpty ? '1080' : screenHeight.text);

    globalIndentationValue.value = int.parse(
      (localStore.get('indent') != null && localStore.get('indent')!.isNotEmpty)
          ? localStore.get('indent')!
          : '1',
    );

    // Update initial values after saving
    _initialDuration = durationTimer.text.isEmpty ? '50' : durationTimer.text;
    _initialIntentation = intentation.text.isEmpty ? '2' : intentation.text;
    _initialScreenWidth = screenWidth.text.isEmpty ? '1920' : screenWidth.text;
    _initialScreenHeight =
        screenHeight.text.isEmpty ? '1080' : screenHeight.text;
    _initialOpenEasyWorship = _openEasyWorship;

    setState(() {
      _hasChanges = false;
    });

    CustomNotification.show(
      context,
      "Saved!",
    );
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
                    'Lines before break',
                    style: TextStyle(fontSize: 24, color: Colors.white),
                  ),
                  subtitle: Text(
                    'Line break frequency',
                    style: TextStyle(fontSize: 14, color: Colors.grey),
                  ),
                ),
              ),
              TimerTextField(
                minutesCtrl: intentation,
                hint: '',
              ),
            ],
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: ListTile(
                  title: Text(
                    'Open EasyWorship',
                    style: TextStyle(fontSize: 24, color: Colors.white),
                  ),
                ),
              ),
              SizedBox(
                width: 100,
                height: 100,
                child: Checkbox(
                  value: _openEasyWorship,
                  onChanged: (value) {
                    setState(() {
                      _openEasyWorship = value ?? true;
                      localStore.setBool('openEasyWorship', _openEasyWorship);
                      _checkForChanges();
                    });
                  },
                ),
              ),
            ],
          ),
          ButtonWidget(
            title: 'Save Updates',
            onTap: _hasChanges ? _saveSettings : null,
          ),
        ],
      ),
    );
  }
}
