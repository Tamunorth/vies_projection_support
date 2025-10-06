import 'package:win32/win32.dart';
import 'package:ffi/ffi.dart';
import 'dart:ffi';

class EasyWorshipAutomation {
  final List<int> _childWindows = [];

  // Define missing constants
  static const int BM_CLICK = 0x00F5;
  static const int MK_LBUTTON = 0x0001;

  // Callback for EnumChildWindows
  int enumChildProc(int hwnd, int lParam) {
    _childWindows.add(hwnd);
    return TRUE;
  }

  // Find the Song Editor dialog
  int findSongEditorDialog() {
    final titles = [
      'Song Editor - Untitled',
      'Song Editor',
    ];

    for (final title in titles) {
      final titlePtr = title.toNativeUtf16();
      final hwnd = FindWindow(nullptr, titlePtr);
      calloc.free(titlePtr);
      if (hwnd != 0) return hwnd;
    }
    return 0;
  }

  // Find the  Editor dialog
  int findEditorDialog() {
    final titles = [
      'EasyWorship -',
    ];

    for (final title in titles) {
      final titlePtr = title.toNativeUtf16();
      final hwnd = FindWindow(nullptr, titlePtr);
      calloc.free(titlePtr);
      if (hwnd != 0) return hwnd;
    }
    return 0;
  }

  // Find first Edit control
  int? findAllWIndowsWithinEasyWorship() {
    final dialogHwnd = findEditorDialog();
    if (dialogHwnd == 0) {
      print('Editor dialog not found');
      return null;
    }
    final children = getAllChildWindows(dialogHwnd);

    for (final child in children) {
      final className = getClassName(child);
      print('Child HWND: $child, Class: $className');
      if (className == 'Edit' || className == 'TsdEdit') {
        return child;
      }
    }
    return null;
  }

  // Get all child windows
  List<int> getAllChildWindows(int parentHwnd) {
    _childWindows.clear();

    final callback = NativeCallable<WNDENUMPROC>.isolateLocal(
      enumChildProc,
      exceptionalReturn: FALSE,
    );

    EnumChildWindows(parentHwnd, callback.nativeFunction, 0);
    callback.close();

    return List.from(_childWindows);
  }

  // Get window class name
  String getClassName(int hwnd) {
    final buffer = wsalloc(256);
    GetClassName(hwnd, buffer, 256);
    final result = buffer.toDartString();
    free(buffer);
    return result;
  }

  // Get window text
  String getWindowText(int hwnd) {
    final length = GetWindowTextLength(hwnd);
    if (length == 0) return '';

    final buffer = wsalloc(length + 1);
    GetWindowText(hwnd, buffer, length + 1);
    final result = buffer.toDartString();
    free(buffer);
    return result;
  }

  // Find first Edit control
  int? findTitleField(int dialogHwnd) {
    final children = getAllChildWindows(dialogHwnd);

    for (final child in children) {
      final className = getClassName(child);
      print('Child HWND: $child, Class: $className');
      if (className == 'Edit' || className == 'TsdEdit') {
        return child;
      }
    }
    return null;
  }

  // Find OK button
  int? findOkButton(int dialogHwnd) {
    final children = getAllChildWindows(dialogHwnd);

    // Get dialog rectangle
    final dialogRect = calloc<RECT>();
    GetWindowRect(dialogHwnd, dialogRect);
    final dialogBottom = dialogRect.ref.bottom;
    final dialogRight = dialogRect.ref.right;
    calloc.free(dialogRect);

    int? bestCandidate;

    for (final child in children) {
      final text = getWindowText(child);

      // Check if it has "OK" text
      if (text.toUpperCase().contains('OK')) {
        return child;
      }

      // Check if it's in bottom-right area
      final rect = calloc<RECT>();
      GetWindowRect(child, rect);

      final isBottomRight = (rect.ref.bottom > dialogBottom - 50) &&
          (rect.ref.left > dialogRight - 150);

      calloc.free(rect);

      if (isBottomRight) {
        bestCandidate = child;
      }
    }

    return bestCandidate;
  }

  // Set text in control
  void setControlText(int hwnd, String text) {
    final textPtr = text.toNativeUtf16();
    SendMessage(hwnd, WM_SETTEXT, 0, textPtr.address);
    calloc.free(textPtr);
  }

  // Click control
  void clickControl(int hwnd) {
    SetFocus(hwnd);
    PostMessage(hwnd, WM_LBUTTONDOWN, MK_LBUTTON, 0);
    PostMessage(hwnd, WM_LBUTTONUP, 0, 0);
    SendMessage(hwnd, BM_CLICK, 0, 0);
  }

  // Main automation method
  Future<bool> fillSongDialog(String title) async {
    final dialog = findSongEditorDialog();

    if (dialog == 0) {
      print('Song Editor dialog not found');
      return false;
    }

    print('Found dialog: $dialog');

    await Future.delayed(Duration(milliseconds: 200));

    // Find and fill title field
    final titleField = findTitleField(dialog);
    if (titleField == null) {
      print('Title field not found');
      return false;
    }

    print('Found title field: $titleField');
    SetFocus(titleField);
    await Future.delayed(Duration(milliseconds: 100));

    setControlText(titleField, title);

    await Future.delayed(Duration(milliseconds: 300));

    // Find and click OK button
    final okButton = findOkButton(dialog);
    if (okButton == null) {
      print('OK button not found');
      return false;
    }

    print('Found OK button: $okButton');
    clickControl(okButton);

    return true;
  }
}
