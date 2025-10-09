import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:vies_projection_support/core/local_storage.dart';

// Import the file where your LocalStore is defined.
// e.g., import 'path/to/your/local_store.dart';

/// A service to handle application update checks.
class UpdateService {
  static const String _jsonUrl =
      'https://raw.githubusercontent.com/Tamunorth/vies_projection_support/refs/heads/gh-pages/latest.json';
  static const String _suppressUntilKey = 'suppress_update_dialog_until';

  /// Checks for application updates and shows a dialog if a new version exists.
  static Future<void> checkForUpdates(BuildContext context) async {
    try {
      // Use the global localStore instance to get the suppression date.
      final suppressedUntilString = localStore.get(_suppressUntilKey);

      if (suppressedUntilString != null) {
        final suppressedUntil = DateTime.tryParse(suppressedUntilString);
        if (suppressedUntil != null &&
            DateTime.now().isBefore(suppressedUntil)) {
          return; // Still within the suppression period.
        }
      }

      final packageInfo = await PackageInfo.fromPlatform();
      final currentBuildNumber = int.parse(packageInfo.buildNumber);
      final response = await http.get(Uri.parse(_jsonUrl));

      if (response.statusCode == 200) {
        final List<dynamic> jsonData = jsonDecode(response.body);
        final versions =
            jsonData.map((data) => VersionInfo.fromJson(data)).toList();

        if (versions.isNotEmpty) {
          final latestVersion = versions.first;
          final latestBuildNumber = latestVersion.buildNumber;

          if (latestBuildNumber != null &&
              latestBuildNumber > currentBuildNumber) {
            if (context.mounted) {
              final bool? userClickedLater = await showDialog<bool>(
                context: context,
                barrierDismissible: false,
                builder: (BuildContext dialogContext) {
                  return UpdateDialog(versionInfo: latestVersion);
                },
              );

              if (userClickedLater == true) {
                final newSuppressionDate =
                    DateTime.now().add(const Duration(days: 7));
                // Use the global localStore instance to set the value.
                await localStore.setValue(
                  _suppressUntilKey,
                  newSuppressionDate.toIso8601String(),
                );
              }
            }
          }
        }
      } else {
        debugPrint('Update check failed with status: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('An error occurred during update check: $e');
    }
  }
}

/// Represents version information for the application.
class VersionInfo {
  final String version;
  final String notes;
  final String url;

  VersionInfo({
    required this.version,
    required this.notes,
    required this.url,
  });

  factory VersionInfo.fromJson(Map<String, dynamic> json) {
    return VersionInfo(
      version: json['version'] as String? ?? '0.0.0+0',
      notes: json['notes'] as String? ?? '',
      url: json['url'] as String? ?? '',
    );
  }

  int? get buildNumber {
    final parts = version.split('+');
    if (parts.length == 2) {
      return int.tryParse(parts[1]);
    }
    return null;
  }
}

/// A dialog that informs the user about a new update.
class UpdateDialog extends StatelessWidget {
  final VersionInfo versionInfo;

  const UpdateDialog({
    super.key,
    required this.versionInfo,
  });

  Future<void> _downloadUpdate() async {
    final Uri url = Uri.parse(versionInfo.url);
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } else {
      debugPrint('Could not launch ${versionInfo.url}');
    }
  }

  @override
  Widget build(BuildContext context) {
    return CustomWindowsStyleUpdateDialog(
      currentVersion: versionInfo.version,
      onDownloadPressed: () {
        _downloadUpdate();
        // Pop without a value for download.
        Navigator.of(context).pop();
      },
      onLaterPressed: () {
        // --- MODIFIED LINE ---
        // Pop with `true` to indicate the user chose "Later".
        Navigator.of(context).pop(true);
      },
    );
  }
}

/// The custom dialog widget (no changes needed here).
class CustomWindowsStyleUpdateDialog extends StatelessWidget {
  final String currentVersion;
  final VoidCallback onDownloadPressed;
  final VoidCallback onLaterPressed;

  const CustomWindowsStyleUpdateDialog({
    Key? key,
    required this.currentVersion,
    required this.onDownloadPressed,
    required this.onLaterPressed,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final Color primaryBlue = Color(0xFF0078D7);
    final Color borderColor = Color(0xFFCCCCCC);
    final TextStyle titleStyle = TextStyle(
        fontSize: 18, fontWeight: FontWeight.w600, color: Colors.black);
    final TextStyle contentStyle =
        TextStyle(fontSize: 14, color: Colors.black87);
    final TextStyle buttonTextStyle = TextStyle(
        fontSize: 14, fontWeight: FontWeight.w500, color: primaryBlue);
    final TextStyle filledButtonTextStyle = TextStyle(
        fontSize: 14, fontWeight: FontWeight.w500, color: Colors.white);

    return Dialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(4),
        side: BorderSide(color: borderColor, width: 1),
      ),
      elevation: 8,
      child: Container(
        padding: const EdgeInsets.all(20),
        width: 360,
        constraints: BoxConstraints(maxWidth: 400),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Update Available', style: titleStyle),
            const SizedBox(height: 16),
            Text('A new version ($currentVersion) is available.',
                style: contentStyle),
            const SizedBox(height: 8),
            Text('Would you like to download it now?', style: contentStyle),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  style: TextButton.styleFrom(
                    foregroundColor: primaryBlue,
                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(2)),
                    textStyle: buttonTextStyle,
                  ),
                  onPressed: onLaterPressed,
                  child: const Text('Later'),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryBlue,
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(2)),
                    textStyle: filledButtonTextStyle,
                    elevation: 0,
                    minimumSize: Size(90, 36),
                  ),
                  onPressed: onDownloadPressed,
                  child: const Text('Download'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
