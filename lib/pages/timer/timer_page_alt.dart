// import 'package:custom_timer/custom_timer.dart';
// import 'package:desktop_multi_window/desktop_multi_window.dart';
// import 'package:flutter/material.dart';
// import 'package:flutter/services.dart';
// import 'package:stop_watch_timer/stop_watch_timer.dart';
// // import 'package:flutter_multi_window_example/event_widget.dart';
//
// class TimerSubwindowCounterAlt extends StatefulWidget {
//   const TimerSubwindowCounterAlt({
//     super.key,
//     // required this.updateTimer,
//     // required this.resetTimer,
//     required this.args,
//   });
//
//   final List args;
//
//   // final VoidCallback updateTimer;
//   // final VoidCallback resetTimer;
//
//   static final GlobalKey<_TimerSubwindowCounterAltState> globalKey =
//       GlobalKey();
//
//   @override
//   _TimerSubwindowCounterAltState createState() =>
//       _TimerSubwindowCounterAltState();
// }
//
// class _TimerSubwindowCounterAltState extends State<TimerSubwindowCounterAlt>
//     with TickerProviderStateMixin {
//   late CustomTimerController _controller = CustomTimerController(
//     vsync: this,
//     begin: const Duration(minutes: 0, seconds: 0),
//     end: const Duration(),
//     initialState: CustomTimerState.counting,
//     interval: CustomTimerInterval.milliseconds,
//   );
//
//   StopWatchTimer? stopwatch;
//   bool isCountdown = true;
//   double fontsize = 12;
//
//   @override
//   void initState() {
//     super.initState();
//     _controller.state.addListener(() {
//       if (_controller.state.value == CustomTimerState.finished) {
//         switchToStopwatch();
//       }
//     });
//     _initTimerAndStopwatch();
//   }
//
//   _initTimerAndStopwatch() {
//     stopwatch = StopWatchTimer(
//       mode: StopWatchMode.countUp,
//     );
//   }
//
//   void switchToStopwatch() {
//     setState(() {
//       isCountdown = false;
//     });
//
//     stopwatch?.onStartTimer();
//   }
//
//   void onChange() {
//     print('object');
//     _controller.begin = Duration(
//       minutes: int.parse(widget.args[0]),
//       seconds: int.parse(widget.args[1]),
//     );
//     _controller.reset();
//     _controller.start();
//     isCountdown = true;
//     stopwatch?.onResetTimer();
//     setState(() {});
//   }
//
//   void resetTimer() {
//     _controller.begin = Duration(
//       minutes: int.parse(widget.args[0]),
//       seconds: int.parse(widget.args[1]),
//     );
//     _controller.reset();
//     isCountdown = true;
//     stopwatch?.onResetTimer();
//     setState(() {});
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     // fontsize = MediaQuery.sizeOf(context).width * 0.2;
//     return Scaffold(
//       backgroundColor: Colors.black,
//       body: Center(
//         child: Column(
//           mainAxisAlignment: MainAxisAlignment.center,
//           children: <Widget>[
//             if (isCountdown)
//               CustomTimer(
//                   controller: _controller,
//                   builder: (state, time) {
//                     return Text(
//                       time.hours != '00'
//                           ? "${time.hours}:${time.minutes}:${time.seconds}"
//                           : "${time.minutes}:${time.seconds}",
//                       style: TextStyle(
//                           fontSize:
//                               time.hours != '00' ? fontsize - 100 : fontsize,
//                           color: Colors.white,
//                           fontWeight: FontWeight.w600),
//                     );
//                   }),
//             if (!isCountdown)
//               StreamBuilder<int>(
//                 stream: stopwatch?.rawTime,
//                 initialData: stopwatch?.rawTime.value,
//                 builder: (context, snapshot) {
//                   final value = snapshot.data;
//                   final displayTime = StopWatchTimer.getDisplayTime(value!,
//                       hours: false, milliSecond: false);
//                   return Text(
//                     '-${displayTime}',
//                     style: TextStyle(
//                       fontSize: fontsize,
//                       color: Colors.red,
//                       fontWeight: FontWeight.w600,
//                     ),
//                   );
//                 },
//               ),
//           ],
//         ),
//       ),
//     );
//   }
//
//   Future<dynamic> _handleMethodCallback(
//       MethodCall call, int fromWindowId) async {
//     if (call.method == 'onChange') {
//       // debugPrint("onChange result2: ${call.arguments.toString()}");
//       // _controller?.start();
//
//       _controller.begin = Duration(
//         minutes: int.parse(widget.args[0]),
//         seconds: int.parse(widget.args[1]),
//       );
//       _controller.reset();
//       _controller.start();
//       isCountdown = true;
//       stopwatch?.onResetTimer();
//       setState(() {});
//
//       return "send";
//     }
//     if (call.method == 'onReset') {
//       _controller.begin = Duration(
//         minutes: int.parse(widget.args[0]),
//         seconds: int.parse(widget.args[1]),
//       );
//       _controller.reset();
//       isCountdown = true;
//       stopwatch?.onResetTimer();
//       setState(() {});
//       return "reset";
//     }
//     if (call.arguments.toString() == "ping") {
//       return "pong";
//     }
//
//     /// if the callback method is not handled do this instead
//     return Future.value('no callback');
//   }
//
//   @override
//   void dispose() {
//     _controller.dispose();
//     stopwatch?.dispose();
//     DesktopMultiWindow.setMethodHandler(null);
//
//     super.dispose();
//   }
// }
