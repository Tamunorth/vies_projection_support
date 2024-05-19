import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:untitled/utils/local_storage.dart';
import 'package:untitled/utils/utils.dart';
import 'package:webview_windows/webview_windows.dart';
// import 'package:window_manager/window_manager.dart';

final navigatorKey = GlobalKey<NavigatorState>();

class BrowserWindow extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(navigatorKey: navigatorKey, home: ExampleBrowser());
  }
}

class ExampleBrowser extends StatefulWidget {
  @override
  State<ExampleBrowser> createState() => _ExampleBrowser();
}

class _ExampleBrowser extends State<ExampleBrowser>
    with AutomaticKeepAliveClientMixin<ExampleBrowser> {
  final _controller = WebviewController();
  final _textController = TextEditingController();
  final List<StreamSubscription> _subscriptions = [];
  bool _isWebviewSuspended = false;

  @override
  void initState() {
    super.initState();

    initPlatformState();
  }

  Future<void> initPlatformState() async {
    // Optionally initialize the webview environment using
    // a custom user data directory
    // and/or a custom browser executable directory
    // and/or custom chromium command line flags
    // await WebviewController.initializeEnvironment(
    //     additionalArguments: '--show-fps-counter');

    try {
      await _controller.initialize();
      _subscriptions.add(_controller.url.listen((url) {
        _textController.text = url;
      }));

      // _subscriptions
      //     .add(_controller.containsFullScreenElementChanged.listen((flag) {
      //   debugPrint('Contains fullscreen element: $flag');
      //   // windowManager.setFullScreen(flag);
      // }));

      await _controller.setBackgroundColor(Colors.transparent);
      await _controller.setPopupWindowPolicy(WebviewPopupWindowPolicy.deny);
      await _controller.loadUrl('https://google.com');

      if (!mounted) return;
      setState(() {});
    } on PlatformException catch (e) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        showDialog(
            context: context,
            builder: (_) => AlertDialog(
                  title: Text('Error'),
                  content: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Code: ${e.code}'),
                      Text('Message: ${e.message}'),
                    ],
                  ),
                  actions: [
                    TextButton(
                      child: Text('Continue'),
                      onPressed: () {
                        Navigator.of(context).pop();
                      },
                    )
                  ],
                ));
      });
    }
  }

  Widget compositeView() {
    if (!_controller.value.isInitialized) {
      return const Text(
        '-',
        style: TextStyle(
          fontSize: 24.0,
          fontWeight: FontWeight.w900,
        ),
      );
    } else {
      return Padding(
        padding: EdgeInsets.all(5),
        child: Column(
          children: [
            Card(
              elevation: 0,
              child: Row(children: [
                Expanded(
                  child: TextField(
                    autofocus: true,
                    decoration: InputDecoration(
                      hintText: 'Enter lyrics to find',
                      contentPadding: EdgeInsets.all(10.0),
                    ),
                    textAlignVertical: TextAlignVertical.center,
                    controller: _textController,
                    onSubmitted: (val) async {
                      await _controller.loadUrl(
                          "https://www.google.com/search?q=$val lyrics");
                    },
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.arrow_back),
                  splashRadius: 20,
                  onPressed: () {
                    _controller.goBack();
                  },
                ),
                IconButton(
                  icon: Icon(Icons.refresh),
                  splashRadius: 20,
                  onPressed: () {
                    _controller.reload();
                  },
                ),
                IconButton(
                  icon: Icon(Icons.arrow_forward),
                  splashRadius: 20,
                  onPressed: () {
                    _controller.goForward();
                  },
                ),
              ]),
            ),
            Expanded(
                child: Card(
                    color: Colors.transparent,
                    elevation: 0,
                    clipBehavior: Clip.antiAliasWithSaveLayer,
                    child: Stack(
                      children: [
                        Webview(
                          _controller,
                          permissionRequested: _onPermissionRequested,
                        ),
                        StreamBuilder<LoadingState>(
                            stream: _controller.loadingState,
                            builder: (context, snapshot) {
                              if (snapshot.hasData &&
                                  snapshot.data == LoadingState.loading) {
                                return LinearProgressIndicator();
                              } else {
                                return SizedBox();
                              }
                            }),
                      ],
                    ))),
          ],
        ),
      );
    }
  }

  final EasyUtils utils = EasyUtils();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      floatingActionButton: Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.sizeOf(context).height * 0.05,
          right: MediaQuery.sizeOf(context).height * 0.05,
        ),
        child: FloatingActionButton.extended(
          backgroundColor: Colors.blue,
          icon: Icon(Icons.format_align_center),
          onPressed: () async {
            final indentation = localStore.get('indent');

            final selectedText = await _controller
                .executeScript('window.getSelection().toString()');

            if (selectedText != null && selectedText.isNotEmpty) {
              await utils.copyClipboard(
                context,
                int.parse(
                  (indentation != null && indentation.isNotEmpty)
                      ? indentation
                      : '1',
                ),
                selectedText,
              );
            } else {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('No text selected')),
              );
            }
          },
          label: Text('Format Text'),
        ),
      ),
      appBar: AppBar(
          backgroundColor: Colors.black,
          title: StreamBuilder<String>(
            stream: _controller.title,
            builder: (context, snapshot) {
              return Text(
                snapshot.hasData ? snapshot.data! : 'Vies Browser',
                style: TextStyle(color: Colors.white),
              );
            },
          )),
      body: Center(
        child: compositeView(),
      ),
    );
  }

  Future<WebviewPermissionDecision> _onPermissionRequested(
      String url, WebviewPermissionKind kind, bool isUserInitiated) async {
    final decision = await showDialog<WebviewPermissionDecision>(
      context: navigatorKey.currentContext!,
      builder: (BuildContext context) => AlertDialog(
        title: const Text('WebView permission requested'),
        content: Text('WebView has requested permission \'$kind\''),
        actions: <Widget>[
          TextButton(
            onPressed: () =>
                Navigator.pop(context, WebviewPermissionDecision.deny),
            child: const Text('Deny'),
          ),
          TextButton(
            onPressed: () =>
                Navigator.pop(context, WebviewPermissionDecision.allow),
            child: const Text('Allow'),
          ),
        ],
      ),
    );

    return decision ?? WebviewPermissionDecision.none;
  }

  @override
  void dispose() {
    _subscriptions.forEach((s) => s.cancel());
    _controller.dispose();
    super.dispose();
  }

  @override
  bool get wantKeepAlive => true;
}
