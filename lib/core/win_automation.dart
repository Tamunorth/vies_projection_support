import 'package:untitled/core/block_input.dart';
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

  // Find the  Easy worship page
  int findEasyWorshipMainPage() {
    final titles = [
      'EasyWorship - Default',
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
    final dialogHwnd = findEasyWorshipMainPage();
    if (dialogHwnd == 0) {
      print('Editor dialog not found');
      return null;
    }
    final children = getAllChildWindows(dialogHwnd);

    for (final child in children) {
      final className = getClassName(child);
      // print('Child HWND: $child, Class: $className');
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
      // print('Child HWND: $child, Class: $className');
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

  Future<T?> retryOperation<T>(
    T? Function() operation,
    bool Function(T?) isSuccess, {
    int maxAttempts = 3,
    Duration? delay,
    String operationName = 'Operation',
  }) async {
    final retryDelay = delay ?? Duration(milliseconds: 200);

    for (int attempt = 1; attempt <= maxAttempts; attempt++) {
      print('$operationName (attempt $attempt/$maxAttempts)');
      final result = operation();

      if (isSuccess(result)) {
        print('$operationName succeeded on attempt $attempt: $result');
        return result;
      }

      if (attempt < maxAttempts) {
        print(
            '$operationName failed, waiting ${retryDelay.inMilliseconds}ms before retry...');
        await Future.delayed(retryDelay);
      }
    }

    print('$operationName failed after $maxAttempts attempts');
    return null;
  }

  Future<int?> findSongEditorDialogWithRetry({
    int maxAttempts = 3,
    Duration? delay,
  }) async {
    return retryOperation<int>(
      () => findSongEditorDialog(),
      (result) => result != null && result != 0,
      maxAttempts: maxAttempts,
      delay: delay,
      operationName: 'Finding Song Editor dialog',
    );
  }

  Future<int?> findTitleFieldWithRetry(
    int dialog, {
    int maxAttempts = 3,
    Duration? delay,
  }) async {
    return retryOperation<int?>(
      () => findTitleField(dialog),
      (result) => result != null,
      maxAttempts: maxAttempts,
      delay: delay,
      operationName: 'Finding title field',
    );
  }

  Future<int?> findOkButtonWithRetry(
    int dialog, {
    int maxAttempts = 3,
    Duration? delay,
  }) async {
    return retryOperation<int?>(
      () => findOkButton(dialog),
      (result) => result != null,
      maxAttempts: maxAttempts,
      delay: delay,
      operationName: 'Finding OK button',
    );
  }

// Updated fillSongDialog using the retry functions
  Future<bool> fillSongDialog(String title, {Duration? delay}) async {
    final dialog = await findSongEditorDialogWithRetry(delay: delay);

    if (dialog == null) {
      return false;
    }

    print('Proceeding with dialog: $dialog');

    await Future.delayed(delay ?? Duration(milliseconds: 200));

    await ViesBlockInput.downKey();

    await pasteClipboard();

    // Find and fill title field
    final titleField = await findTitleFieldWithRetry(dialog, delay: delay);
    if (titleField == null) {
      print('Title field not found after retries');
      return false;
    }

    print('Found title field: $titleField');
    SetFocus(titleField);
    await Future.delayed(Duration(milliseconds: 100));

    setControlText(titleField, title);

    await Future.delayed(Duration(milliseconds: 300));

    // Find and click OK button
    final okButton = await findOkButtonWithRetry(dialog, delay: delay);
    if (okButton == null) {
      print('OK button not found after retries');
      return false;
    }

    print('Found OK button: $okButton');
    clickControl(okButton);

    return true;
  } /////

// Helper: Find window by partial title match
  int? findWindowByPartialTitle(String partialTitle) {
    final List<int> foundWindows = [];

    int enumWindowProc(int hwnd, int lParam) {
      final text = getWindowText(hwnd);
      if (text.contains(partialTitle)) {
        foundWindows.add(hwnd);
        return FALSE; // Stop enumeration once found
      }
      return TRUE;
    }

    final callback = NativeCallable<WNDENUMPROC>.isolateLocal(
      enumWindowProc,
      exceptionalReturn: FALSE,
    );

    EnumWindows(callback.nativeFunction, 0);
    callback.close();

    if (foundWindows.isNotEmpty) {
      print('Found window containing "$partialTitle": ${foundWindows.first}');
      return foundWindows.first;
    }

    print('Window containing "$partialTitle" not found');
    return null;
  }

// Find the main EasyWorship window (works with any profile)
  int? findEasyWorshipMainWindow() {
    return findWindowByPartialTitle('EasyWorship');
  }

// Updated findNewButton using the new helper
  int? findNewButton() {
    // Find the main EasyWorship window
    final mainWindow = findEasyWorshipMainWindow();

    if (mainWindow == null || mainWindow == 0) {
      print('EasyWorship main window not found');
      return null;
    }

    print(
        'Found EasyWorship window: $mainWindow (${getWindowText(mainWindow)})');

    final children = getAllChildWindows(mainWindow);
    print('Found ${children.length} child windows');

    for (final child in children) {
      final text = getWindowText(child);

      // Look for control with "New" text
      if (text == 'New') {
        print('Found New button: $child');
        return child;
      }
    }

    print('New button not found');
    return null;
  }

// Find the "New song..." menu item after clicking New
  int? findNewSongMenuItem1() {
    // Menu items are typically in a popup window
    // We need to find all top-level windows and look for menu
    final menuWindow =
        FindWindow('#32768'.toNativeUtf16(), nullptr); // Standard menu class

    print('Checking menu item: $menuWindow');

    if (menuWindow != 0) {
      final children = getAllChildWindows(menuWindow);

      print('Found ${children} menu items');

      for (final child in children) {
        final text = getWindowText(child);
        print('Checking menu item: $text');

        if (text.contains('New Song')) {
          print('Found New song menu item: $child');
          return child;
        }
      }
    }

    // Alternative: enumerate all windows to find the menu item
    return _findWindowByText('New song...');
  }

// Find menu window right after clicking New
  int? findMenuWindow() {
    final List<int> menuWindows = [];

    int enumWindowProc(int hwnd, int lParam) {
      final className = getClassName(hwnd);

      // Menu class is typically "#32768"
      if (className == '#32768') {
        // Check if it's visible
        if (IsWindowVisible(hwnd) == TRUE) {
          menuWindows.add(hwnd);
        }
      }
      return TRUE;
    }

    final callback = NativeCallable<WNDENUMPROC>.isolateLocal(
      enumWindowProc,
      exceptionalReturn: FALSE,
    );

    EnumWindows(callback.nativeFunction, 0);
    callback.close();

    if (menuWindows.isNotEmpty) {
      print('Found ${menuWindows} menu windows');
      return menuWindows.last; // Return the most recent one
    }

    return null;
  }

// Helper: Find any window by text
  int? _findWindowByText(String searchText) {
    final List<int> foundWindows = [];

    int enumWindowProc(int hwnd, int lParam) {
      final text = getWindowText(hwnd);
      if (text.contains(searchText)) {
        foundWindows.add(hwnd);
      }
      return TRUE;
    }

    final callback = NativeCallable<WNDENUMPROC>.isolateLocal(
      enumWindowProc,
      exceptionalReturn: FALSE,
    );

    EnumWindows(callback.nativeFunction, 0);
    callback.close();

    if (foundWindows.isNotEmpty) {
      print('Found window with text "$searchText": ${foundWindows.first}');
      return foundWindows.first;
    }

    // If not found at top level, search all child windows of all windows
    final List<int> allWindows = [];

    int enumAllWindows(int hwnd, int lParam) {
      allWindows.add(hwnd);
      return TRUE;
    }

    final callback2 = NativeCallable<WNDENUMPROC>.isolateLocal(
      enumAllWindows,
      exceptionalReturn: FALSE,
    );

    EnumWindows(callback2.nativeFunction, 0);
    callback2.close();

    for (final window in allWindows) {
      final children = getAllChildWindows(window);
      for (final child in children) {
        final text = getWindowText(child);
        if (text.contains(searchText)) {
          print('Found child window with text "$searchText": $child');
          return child;
        }
      }
    }

    print('Window with text "$searchText" not found');
    return null;
  }

// Click the New button
  Future<bool> clickNewButton() async {
    final newButton = findNewButton();
    if (newButton == null) return false;

    clickControl(newButton);
    await Future.delayed(Duration(milliseconds: 50)); // Wait for menu to appear
    return true;
  }

  // Click menu item by sending WM_COMMAND
  Future<bool> clickNewSongMenuItemAdvanced() async {
    await Future.delayed(Duration(milliseconds: 200));

    final menuWindow = findMenuWindow();
    if (menuWindow != null) {
      print('Found menu window: $menuWindow');

      /// Click the second item (index 1)
      await clickMenuItemByIndex(index: 1, currentWindow: menuWindow);

      return true;
    }

    return false;
  }

  // Click any menu item by index (0 = first, 1 = second, etc.)
  Future<bool> clickMenuItemByIndex(
      {required int index, required int currentWindow}) async {
    // Press DOWN arrow 'index + 1' times
    for (int i = 0; i <= index; i++) {
      await ViesBlockInput.downKey();
      await Future.delayed(Duration(milliseconds: 50));
    }

    // await Future.delayed(Duration(milliseconds: 100));

    ///enter
    PostMessage(currentWindow, WM_KEYDOWN, VK_RETURN, 0);

    await Future.delayed(Duration(milliseconds: 300));
    return true;
  }

// Open the New Song dialog
  Future<bool> openNewSongDialog() async {
    final clicked = await clickNewButton();
    if (!clicked) {
      print('Failed to click New button');
      return false;
    }

    print('Clicking New song menu item...');
    final menuClicked = await clickNewSongMenuItemAdvanced();
    if (!menuClicked) {
      print('Failed to click New song menu item');
      return false;
    }

    print('New song dialog should be open');
    return true;
  }

  Future<void> pasteClipboard() async {
    // Create input structures for Ctrl+V
    final inputs = calloc<INPUT>(4);

    // Press Ctrl
    inputs[0].type = INPUT_KEYBOARD;
    inputs[0].ki.wVk = VK_CONTROL;
    inputs[0].ki.dwFlags = 0;

    // Press V
    inputs[1].type = INPUT_KEYBOARD;
    inputs[1].ki.wVk = VK_V;
    inputs[1].ki.dwFlags = 0;

    // Release V
    inputs[2].type = INPUT_KEYBOARD;
    inputs[2].ki.wVk = VK_V;
    inputs[2].ki.dwFlags = KEYEVENTF_KEYUP;

    // Release Ctrl
    inputs[3].type = INPUT_KEYBOARD;
    inputs[3].ki.wVk = VK_CONTROL;
    inputs[3].ki.dwFlags = KEYEVENTF_KEYUP;

    SendInput(4, inputs, sizeOf<INPUT>());
    calloc.free(inputs);

    await Future.delayed(Duration(milliseconds: 100));
  }
}
