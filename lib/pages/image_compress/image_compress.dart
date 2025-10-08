import 'dart:io';
import 'dart:math';

import 'package:desktop_drop/desktop_drop.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:image/image.dart' as img_lib;
import 'package:open_dir/open_dir.dart';
import 'package:untitled/core/analytics.dart';
import 'package:untitled/core/compress_image.dart';
import 'package:untitled/pages/home_page.dart';
import 'package:untitled/shared/button_widget.dart';
import 'package:untitled/shared/snackbar.dart';
import 'package:path/path.dart' as p;

class ImageCompress extends StatefulWidget {
  const ImageCompress({super.key});

  static final pageId = 'image_compress_page';

  @override
  State<ImageCompress> createState() => _ImageCompressState();
}

class _ImageCompressState extends State<ImageCompress> {
  File? img;
  String? savedImagePath;
  bool isLoading = false;

  @override
  Widget build(BuildContext context) {
    return DropTarget(
      onDragDone: (detail) async {
        final draggedFile = File(detail.files.first.path);
        await _compressImage(passedFile: draggedFile);
      },
      child: Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Drop Image Here',
              style: Theme.of(context)
                  .textTheme
                  .displayMedium
                  ?.copyWith(color: Colors.white),
            ),
            Row(
              children: [
                const SizedBox(height: 24),
              ],
            ),
            Text(
              'Compress images to the right size for YouTube thumbnails',
              textAlign: TextAlign.center,
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ?.copyWith(color: Colors.white),
            ),
            const SizedBox(height: 24),
            if (img != null)
              MouseRegion(
                cursor: savedImagePath != null
                    ? SystemMouseCursors.click
                    : SystemMouseCursors.basic,
                child: GestureDetector(
                  onTap: savedImagePath == null
                      ? null
                      : () async {
                          try {
                            final directoryPath = p.dirname(savedImagePath!);
                            await OpenDir().openNativeDir(
                                path: directoryPath,
                                highlightedFileName:
                                    p.basename(savedImagePath!));
                          } catch (e) {
                            if (mounted) {
                              CustomNotification.show(
                                context,
                                'Could not open file location.',
                                isSuccess: false,
                              );
                            }
                          }
                        },
                  child: Image.file(
                    img!,
                    width: 240,
                    height: 144,
                    fit: BoxFit.contain,
                  ),
                ),
              )
            else
              const SizedBox(
                width: 240,
                height: 200,
                child: Image(
                    fit: BoxFit.cover,
                    image: AssetImage('assets/image_placeholder.png')),
              ),
            const SizedBox(height: 12),
            if (isLoading) ...[
              CircularProgressIndicator(
                strokeCap: StrokeCap.round,
                strokeWidth: 5,
                backgroundColor: accentColor,
                trackGap: 12,
                color: Colors.blue,
              ),
              const SizedBox(height: 12),
            ],
            ButtonWidget(
              title: "Pick Image",
              onTap: isLoading ? null : _compressImage,
            ),
          ],
        ),
      ),
    );
  }

  /// Formats file size in bytes to a human-readable string (KB, MB, etc.).
  String _formatBytes(int bytes, {int decimals = 2}) {
    if (bytes <= 0) return "0 B";
    const suffixes = ["B", "KB", "MB", "GB", "TB"];
    var i = (log(bytes) / log(1024)).floor();
    return '${(bytes / pow(1024, i)).toStringAsFixed(decimals)} ${suffixes[i]}';
  }

  /// Handles the image selection, compression, and saving process.
  _compressImage({File? passedFile}) async {
    setState(() {
      isLoading = true;
      savedImagePath = null;
    });

    final stopwatch = Stopwatch()..start();

    try {
      File? fileImage;
      const int maxSizeInBytes = 2 * 1024 * 1024;

      if (passedFile == null) {
        final result =
            await FilePicker.platform.pickFiles(type: FileType.image);
        if (result?.files.single.path != null) {
          fileImage = File(result!.files.single.path!);
        }
      } else {
        fileImage = passedFile;
      }

      if (fileImage == null) return;
      final compressedFile =
          await compressImageToSize(fileImage, maxSizeInBytes);
      if (compressedFile == null) {
        throw Exception("Compression returned a null file.");
      }

      setState(() {
        img = compressedFile;
      });

      final originalPath = fileImage.path;
      final directory = p.dirname(originalPath);
      final extension = p.extension(originalPath).replaceAll('.', '');
      final baseName = p.basenameWithoutExtension(originalPath);
      final fileName = '${baseName}_compressed.$extension';

      String? savePath = await FilePicker.platform.saveFile(
        dialogTitle: 'Please select an output file:',
        initialDirectory: directory,
        fileName: fileName,
        allowedExtensions: [extension],
      );

      if (savePath != null) {
        if (p.extension(savePath) != '.$extension') {
          savePath = '$savePath.$extension';
        }
        await compressedFile.copy(savePath);

        setState(() {
          savedImagePath = savePath;
        });

        if (mounted) {
          CustomNotification.show(
            context,
            "Compressed image saved! Click the preview to open.",
            isSuccess: true,
          );
        }
      }
    } catch (e, trace) {
      Analytics.instance.trackEventWithProperties(
        "image_compression_error",
        {
          'error': e.toString(),
          'stack_trace': trace.toString(),
        },
      );
      if (mounted) {
        CustomNotification.show(
          context,
          "Could not compress image: ${e.toString()}",
          isSuccess: false,
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }
}
