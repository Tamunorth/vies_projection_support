import 'dart:developer';
import 'dart:io';

import 'package:desktop_drop/desktop_drop.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:open_dir/open_dir.dart';
import 'package:vies_projection_support/core/analytics.dart';
import 'package:vies_projection_support/core/compress_image.dart';
import 'package:vies_projection_support/core/enums/aspect_ratio_mode.dart';
import 'package:vies_projection_support/core/local_storage.dart';
import 'package:vies_projection_support/pages/home_page.dart';
import 'package:vies_projection_support/shared/button_widget.dart';
import 'package:vies_projection_support/shared/snackbar.dart';
import 'package:path/path.dart' as p;
import 'package:vies_projection_support/pages/home_page.dart';

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
  final localAspectRatioMode = localStore.get('image_compress_aspect_ratio');
  late AspectRatioMode _selectedMode;
  @override
  initState() {
    super.initState();
    _selectedMode = AspectRatioMode.values.firstWhere(
      (mode) => mode.name == localAspectRatioMode,
      orElse: () => AspectRatioMode.maintainDimensions,
    );
  }

  @override
  Widget build(BuildContext context) {
    return DropTarget(
      onDragDone: (detail) async {
        final draggedFile = File(detail.files.first.path);
        await _compressImage(passedFile: draggedFile);
      },
      child: Container(
        padding: const EdgeInsets.all(24),
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(height: 24),
              Text(
                'Drop Image Here',
                style: Theme.of(context)
                    .textTheme
                    .displayMedium
                    ?.copyWith(color: Colors.white),
              ),
              Row(
                children: [
                  const SizedBox(height: 12),
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
              DropdownMenu<AspectRatioMode>(
                width: 240,
                initialSelection: _selectedMode,
                onSelected: (AspectRatioMode? mode) {
                  if (mode != null) {
                    localStore.setValue(
                        'image_compress_aspect_ratio', mode.name);
                    setState(() {
                      _selectedMode = mode;
                    });
                  }
                },
                dropdownMenuEntries: AspectRatioMode.values
                    .map<DropdownMenuEntry<AspectRatioMode>>(
                  (AspectRatioMode mode) {
                    return DropdownMenuEntry<AspectRatioMode>(
                      value: mode,
                      label: mode.displayName,
                      style: ButtonStyle(
                        foregroundColor:
                            WidgetStateProperty.all<Color>(Colors.white),
                      ),
                    );
                  },
                ).toList(),
                textStyle: const TextStyle(
                  fontSize: 14,
                ),
                menuStyle: MenuStyle(
                  backgroundColor: WidgetStateProperty.all<Color?>(accentColor),
                  fixedSize: WidgetStateProperty.all<Size>(
                    Size.fromWidth(240),
                  ),
                  padding: WidgetStateProperty.all<EdgeInsets>(
                    EdgeInsets.symmetric(vertical: 8.0),
                  ),
                ),
                inputDecorationTheme: InputDecorationTheme(
                  filled: true,
                  fillColor: accentColor,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12.0),
                  // Defines the border style when the dropdown is not focused.
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(4.0),
                    borderSide:
                        BorderSide(color: Colors.grey.shade600, width: 1.0),
                  ),
                  // Defines the border style when the dropdown is focused.
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(4.0),
                    borderSide:
                        const BorderSide(color: accentColor, width: 2.0),
                  ),
                ),
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
                  child: Image(
                    image: AssetImage('assets/image_placeholder.png'),
                    fit: BoxFit.contain,
                    width: 240,
                    height: 240,
                  ),
                ),
              // const SizedBox(height: 24),
              if (isLoading) ...[
                const SizedBox(height: 24),
                const CircularProgressIndicator(
                  strokeCap: StrokeCap.round,
                  strokeWidth: 5,
                  backgroundColor: accentColor,
                  trackGap: 12,
                  color: Colors.blue,
                ),
                // const SizedBox(height: 12),
              ],
              ButtonWidget(
                title: "Pick Image",
                onTap: isLoading ? null : _compressImage,
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Handles the image selection, compression, and saving process.
  _compressImage({File? passedFile}) async {
    setState(() {
      isLoading = true;
      savedImagePath = null;
    });

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
      final compressedFile = await compressImageToSize(
        fileImage,
        maxSizeInBytes,
        aspectRatioMode: _selectedMode,
      );
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
        if (p.extension(savePath).isEmpty) {
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
        log('Error during image compression: $e\n$trace');
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
