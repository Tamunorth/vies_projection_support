import 'dart:io';
import 'dart:developer' as developer;

import 'package:ffi/ffi.dart';
import 'dart:ffi';
import 'package:path/path.dart' as p;
import 'package:process_run/shell.dart';
import 'package:vies_projection_support/core/local_storage.dart';
import 'package:win32/win32.dart';

class EasyWorshipHandler {
  // A constant for the logger name to ensure consistency.
  static const _logName = 'EasyWorshipHandler';
  static const _localEasyworshipPathKey = 'easyworship_path';

  /// A reusable function to launch an executable with a scalable retry mechanism.
  ///
  /// It attempts to launch an application a specified number of times. The first
  /// attempt uses a cached path if available, while all subsequent retries
  /// force a fresh search for the executable's path.
  Future<(String? error, bool success)> _launchWithRetry({
    required String appName,
    required String? initialPath,
    required Future<String?> Function() pathFinder,
    required int maxRetries,
  }) async {
    final totalAttempts = maxRetries + 1;
    String? lastError;

    for (int attempt = 1; attempt <= totalAttempts; attempt++) {
      String? pathToTry;

      // On the first attempt, prioritize the cached path.
      // On all retries, force a fresh search.
      if (attempt == 1 && initialPath != null && initialPath.isNotEmpty) {
        pathToTry = initialPath;
      } else {
        if (attempt > 1) {
          developer.log('Forcing path re-scan for retry.', name: _logName);
        }
        pathToTry = await pathFinder();
      }

      if (pathToTry == null) {
        lastError = '$appName installation not found.';
        developer.log(lastError, name: _logName, level: 900);
        continue; // Skip to the next attempt
      }

      developer.log(
        'Launching $appName (Attempt $attempt of $totalAttempts)...',
        name: _logName,
      );

      try {
        await Shell().run('"$pathToTry"');
        return (null, true); // Success!
      } catch (e, stackTrace) {
        lastError = 'Attempt $attempt to launch $appName failed: $e';
        developer.log(
          lastError,
          name: _logName,
          error: e,
          stackTrace: stackTrace,
          level: 900, // WARNING level for a failed attempt
        );
      }
    }

    // If the loop finishes, all attempts have failed.
    final finalError =
        '$appName failed to launch after $totalAttempts attempts.';
    developer.log(finalError, name: _logName, level: 1000); // SEVERE level
    return (lastError ?? finalError, false);
  }

  /// Finds and launches EasyWorship, retrying upon failure.
  ///
  /// The [retries] parameter controls how many times to retry after the
  /// initial attempt fails. The default is 1 retry.
  Future<(String? error, bool success)> openEasyWorship({
    int retries = 1,
  }) async {
    return _launchWithRetry(
      appName: 'EasyWorship',
      initialPath: localStore.get(_localEasyworshipPathKey),
      pathFinder: findEasyWorshipPath,
      maxRetries: retries,
    );
  }

  /// Queries a string value from an open registry key handle.
  ///
  /// This is a low-level helper that deals with FFI pointers and buffers.
  String? _queryValue(int keyHandle, String valueName) {
    final valueNamePtr = valueName.toNativeUtf16();
    final dataType = calloc<DWORD>();
    final dataSize = calloc<DWORD>();
    String? result;

    try {
      var status = RegQueryValueEx(
          keyHandle, valueNamePtr, nullptr, dataType, nullptr, dataSize);

      if (status == ERROR_SUCCESS) {
        final data = calloc<BYTE>(dataSize.value);
        try {
          status = RegQueryValueEx(
              keyHandle, valueNamePtr, nullptr, dataType, data, dataSize);
          if (status == ERROR_SUCCESS && dataType.value == REG_SZ) {
            result = data.cast<Utf16>().toDartString();
          }
        } finally {
          free(data);
        }
      }
    } finally {
      free(valueNamePtr);
      free(dataType);
      free(dataSize);
    }
    return result;
  }

  /// Finds the installation path of the EasyWorship executable by searching
  /// the Windows Registry.
  Future<String?> findEasyWorshipPath() async {
    const uninstallPaths = [
      r'SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall',
      r'SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall',
    ];

    final uninstallKey = calloc<HKEY>();
    final programKey = calloc<HKEY>();
    final subKeyNamePtr = wsalloc(256);

    try {
      for (final path in uninstallPaths) {
        developer.log('Searching registry path: $path', name: _logName);
        final pathPtr = path.toNativeUtf16();
        try {
          if (RegOpenKeyEx(
                  HKEY_LOCAL_MACHINE, pathPtr, 0, KEY_READ, uninstallKey) ==
              ERROR_SUCCESS) {
            try {
              for (int i = 0;
                  RegEnumKey(uninstallKey.value, i, subKeyNamePtr, 256) ==
                      ERROR_SUCCESS;
                  i++) {
                if (RegOpenKeyEx(uninstallKey.value, subKeyNamePtr, 0, KEY_READ,
                        programKey) ==
                    ERROR_SUCCESS) {
                  try {
                    final displayName =
                        _queryValue(programKey.value, 'DisplayName');
                    if (displayName != null) {
                      developer.log('Found app: $displayName', name: _logName);
                    }
                    if (displayName != null &&
                        displayName.contains('EasyWorship')) {
                      final installLocation =
                          _queryValue(programKey.value, 'InstallLocation');
                      if (installLocation != null &&
                          installLocation.isNotEmpty) {
                        final exePath =
                            p.join(installLocation, 'EasyWorship.exe');
                        if (await File(exePath).exists()) {
                          localStore.setValue(
                              _localEasyworshipPathKey, exePath);
                          return exePath;
                        }
                      }
                    }
                  } finally {
                    RegCloseKey(programKey.value);
                  }
                }
              }
            } finally {
              RegCloseKey(uninstallKey.value);
            }
          }
        } finally {
          free(pathPtr);
        }
      }
    } finally {
      free(uninstallKey);
      free(programKey);
      free(subKeyNamePtr);
    }
    return null;
  }
}
