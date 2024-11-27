import 'package:custom_timer/custom_timer.dart';
import 'package:desktop_multi_window/desktop_multi_window.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:stop_watch_timer/stop_watch_timer.dart';
import 'package:untitled/utils/button_widget.dart';
import 'package:untitled/utils/utils.dart';
// import 'package:flutter_multi_window_example/event_widget.dart';

class TimerTab extends StatefulWidget {
  const TimerTab({Key? key}) : super(key: key);

  @override
  State<TimerTab> createState() => _TimerTabState();
}

class _TimerTabState extends State<TimerTab> {
  late final TextEditingController secondsCtrl;
  late final TextEditingController minutesCtrl;

  @override
  void initState() {
    super.initState();
    minutesCtrl = TextEditingController();
    secondsCtrl = TextEditingController();

    timerWindowInit();
  }

  timerWindowInit() async {
    // await EasyUtils.createTimerWindow();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const SizedBox(
          height: 50,
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TimerTextField(
              hint: "Minutes",
              minutesCtrl: minutesCtrl,
            ),
            const SizedBox(
              width: 20,
            ),
            Text(
              ':',
              style: TextStyle(
                fontSize: 52,
                color: Colors.white,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(
              width: 20,
            ),
            TimerTextField(
              hint: "Seconds",
              minutesCtrl: secondsCtrl,
            ),
          ],
        ),
        const SizedBox(
          height: 50,
        ),
        Wrap(
          alignment: WrapAlignment.center,
          runAlignment: WrapAlignment.center,
          children: [
            ButtonWidget(
              title: "Create Timer Windows",
              color: Colors.green,
              onTap: _createTimerWindow,
            ),
            ButtonWidget(
              title: 'Update Timer',
              onTap: _updateTimer,
            ),
            ButtonWidget(
              title: "Reset Timer",
              color: Colors.grey,
              onTap: _resetTimer,
            ),
            ButtonWidget(
              title: "Close Timer Windows",
              color: Colors.red,
              onTap: () => EasyUtils.closeTimerWindows(),
            ),
            // SizedBox(
            //   height: 200,
            //   width: 200,
            //   child: TimerSubwindowCounterAlt(
            //     args: [minutesCtrl.text.trim(), secondsCtrl.text.trim()],
            //   ),
            // )
          ],
        ),
      ],
    );
  }

  void _createTimerWindow() async {
    // final previewScreenDimens = screenDimensions.value
    //     .firstWhere((element) => element.frame.left == 0.0)
    //     .frame;
    // final mainScreenDimens = screenDimensions.value
    //     .firstWhere((element) => element.frame.left != 0.0)
    //     .frame;
    //
    // final windowMain = await DesktopMultiWindow.createWindow(jsonEncode({
    //   'args1': 'Timer window',
    //   'args2': 10,
    //   'args3': true,
    //   'window_type': 'main',
    // }));
    // final windowPreview = await DesktopMultiWindow.createWindow(jsonEncode({
    //   'args1': 'Preview window',
    //   'args2': 10,
    //   'args3': true,
    //   'window_type': 'preview',
    // }));
    //
    // windowMain
    //   ..setFrame(Offset(mainScreenDimens.left, mainScreenDimens.top) &
    //       Size(mainScreenDimens.width, mainScreenDimens.height))
    //   ..show();
    //
    // windowPreview
    //   ..setFrame(Offset(previewScreenDimens.left,
    //           previewScreenDimens.top + (previewScreenDimens.height / 2)) &
    //       Size(previewScreenDimens.width / 2, previewScreenDimens.height / 2.5))
    //   ..show();
    //
    //
    // await EasyUtils.createTimerWindow();

    try {
      // final subWindowIds = await DesktopMultiWindow.getAllSubWindowIds();
      //
      // subWindowIds.forEach((element) {
      //   WindowController.fromWindowId(element).close();
      // });

      await EasyUtils.closeTimerWindows();
    } catch (e) {
      print(e);
      // await EasyUtils.createTimerWindow();
    } finally {
      await EasyUtils.createTimerWindow();
    }
  }

  void _resetTimer() async {
    if (minutesCtrl.text.trim().isEmpty) {
      minutesCtrl.text = '0';
    }

    if (secondsCtrl.text.trim().isEmpty) {
      secondsCtrl.text = '0';
    }

    try {
      final subWindowIds = await DesktopMultiWindow.getAllSubWindowIds();
      for (final windowId in subWindowIds) {
        DesktopMultiWindow.invokeMethod(
          windowId,
          'onReset',
          [minutesCtrl.text.trim(), secondsCtrl.text.trim()],
        );
      }

      // TimerSubwindowCounterAlt.globalKey.currentState?.resetTimer();
    } catch (e) {}
  }

  void _updateTimer() async {
    if (minutesCtrl.text.trim().isEmpty) {
      minutesCtrl.text = '0';
    }

    if (secondsCtrl.text.trim().isEmpty) {
      secondsCtrl.text = '0';
    }

    try {
      final subWindowIds = await DesktopMultiWindow.getAllSubWindowIds();
      for (final windowId in subWindowIds) {
        DesktopMultiWindow.invokeMethod(
          windowId,
          'onChange',
          [minutesCtrl.text.trim(), secondsCtrl.text.trim()],
        );
      }

      // TimerSubwindowCounterAlt.globalKey.currentState?.onChange();
    } catch (e) {}
  }
}

class TimerTextField extends StatelessWidget {
  const TimerTextField({
    super.key,
    required this.minutesCtrl,
    required this.hint,
    this.paddingVert = 30,
    this.onChanged,
  });

  final TextEditingController minutesCtrl;
  final String hint;
  final Function(String)? onChanged;
  final double paddingVert;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 200,
      child: TextField(
          controller: minutesCtrl,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w700,
          ),
          onChanged: onChanged,
          decoration: InputDecoration(
            hintText: hint,
            fillColor: Colors.white,
            contentPadding:
                EdgeInsets.symmetric(vertical: paddingVert, horizontal: 24),
            filled: true,
            border: OutlineInputBorder(
              borderSide: BorderSide.none,
            ),
          ),
          keyboardType: TextInputType.number,
          inputFormatters: <TextInputFormatter>[
            FilteringTextInputFormatter.allow(RegExp(r'[0-9]')),
          ]),
    );
  }
}

class TimerSubWindow extends StatelessWidget {
  const TimerSubWindow({
    Key? key,
    required this.windowController,
    required this.args,
  }) : super(key: key);

  final WindowController windowController;
  final Map? args;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
        home: TimerSubwindowCounter(
      args: args,
    ));
  }
}

class TimerSubwindowCounter extends StatefulWidget {
  const TimerSubwindowCounter({super.key, this.args});

  final Map? args;

  @override
  _TimerSubwindowCounterState createState() => _TimerSubwindowCounterState();
}

class _TimerSubwindowCounterState extends State<TimerSubwindowCounter>
    with TickerProviderStateMixin {
  late CustomTimerController _controller = CustomTimerController(
    vsync: this,
    begin: const Duration(minutes: 0, seconds: 0),
    end: const Duration(),
    initialState: CustomTimerState.counting,
    interval: CustomTimerInterval.milliseconds,
  );

  StopWatchTimer? stopwatch;
  bool isCountdown = true;
  double fontsize = 200;

  @override
  void initState() {
    super.initState();
    DesktopMultiWindow.setMethodHandler(_handleMethodCallback);
    _controller.state.addListener(() {
      if (_controller.state.value == CustomTimerState.finished) {
        switchToStopwatch();
      }
    });
    _initTimerAndStopwatch();

    // if (widget.args != null) {
    //   if (widget.args!['window_type'] == 'main') {
    //     fontsize = scrWidth / 3;
    //   } else {
    //     fontsize = scrWidth / 3;
    //   }
    // }
  }

  _initTimerAndStopwatch() {
    stopwatch = StopWatchTimer(
      mode: StopWatchMode.countUp,
    );
  }

  void switchToStopwatch() {
    setState(() {
      isCountdown = false;
    });

    stopwatch?.onStartTimer();
  }

  @override
  Widget build(BuildContext context) {
    fontsize = MediaQuery.sizeOf(context).width * 0.2;
    return Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            if (isCountdown)
              CustomTimer(
                  controller: _controller,
                  builder: (state, time) {
                    return Text(
                      time.hours != '00'
                          ? "${time.hours}:${time.minutes}:${time.seconds}"
                          : "${time.minutes}:${time.seconds}",
                      style: TextStyle(
                          fontSize:
                              time.hours != '00' ? fontsize - 100 : fontsize,
                          color: Colors.white,
                          fontWeight: FontWeight.w600),
                    );
                  }),
            if (!isCountdown)
              StreamBuilder<int>(
                stream: stopwatch?.rawTime,
                initialData: stopwatch?.rawTime.value,
                builder: (context, snapshot) {
                  final value = snapshot.data;
                  final displayTime = StopWatchTimer.getDisplayTime(value!,
                      hours: false, milliSecond: false);
                  return Text(
                    '-${displayTime}',
                    style: TextStyle(
                      fontSize: fontsize,
                      color: Colors.red,
                      fontWeight: FontWeight.w600,
                    ),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }

  Future<dynamic> _handleMethodCallback(
      MethodCall call, int fromWindowId) async {
    if (call.method == 'onChange') {
      // debugPrint("onChange result2: ${call.arguments.toString()}");
      // _controller?.start();

      _controller.begin = Duration(
        minutes: int.parse(call.arguments[0]),
        seconds: int.parse(call.arguments[1]),
      );
      _controller.reset();
      _controller.start();
      isCountdown = true;
      stopwatch?.onResetTimer();
      setState(() {});

      return "send";
    }
    if (call.method == 'onReset') {
      _controller.begin = Duration(
        minutes: int.parse(call.arguments[0]),
        seconds: int.parse(call.arguments[1]),
      );
      _controller.reset();
      isCountdown = true;
      stopwatch?.onResetTimer();
      setState(() {});
      return "reset";
    }
    if (call.arguments.toString() == "ping") {
      return "pong";
    }

    /// if the callback method is not handled do this instead
    return Future.value('no callback');
  }

  @override
  void dispose() {
    _controller.dispose();
    stopwatch?.dispose();
    DesktopMultiWindow.setMethodHandler(null);

    super.dispose();
  }
}
