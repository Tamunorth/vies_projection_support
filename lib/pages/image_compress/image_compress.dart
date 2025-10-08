import 'dart:io';

import 'package:desktop_drop/desktop_drop.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:untitled/core/analytics.dart';
import 'package:untitled/pages/home_page.dart';
import 'package:untitled/core/compress_image.dart';
import 'package:untitled/shared/snackbar.dart';

import '../../shared/button_widget.dart';

class ImageCompress extends StatefulWidget {
  const ImageCompress({super.key});

  static final pageId = 'image_compress_page';

  @override
  State<ImageCompress> createState() => _ImageCompressState();
}

class _ImageCompressState extends State<ImageCompress> {
  File? img;

  bool isLoading = false;

  @override
  Widget build(BuildContext context) {
    return DropTarget(
      onDragDone: (detail) async {
        final draggedFile = File(detail.files.first.path);

        await _compressImage(passedFile: draggedFile);
        setState(() {});
      },
      onDragEntered: (detail) {
        // setState(() {
        //   _dragging = true;
        // });
      },
      onDragExited: (detail) {
        // setState(() {
        //   _dragging = false;
        // });
      },
      child: Container(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Drop Image Here',
                  style: Theme.of(context)
                      .textTheme
                      .displayMedium
                      ?.copyWith(color: Colors.white),
                ),
              ],
            ),
            SizedBox(height: 24),
            Text(
              'Compress images to the right size for YouTube thumbnails',
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ?.copyWith(color: Colors.white),
            ),
            SizedBox(height: 24),
            if (img != null)
              Image.file(
                img!,
                width: 240,
                height: 144,
              )
            else
              SizedBox(
                width: 240,
                height: 200,
                child: Image(
                    fit: BoxFit.cover,
                    image: AssetImage('assets/image_placeholder.png')),
              ),
            SizedBox(height: 12),
            if (isLoading) ...[
              CircularProgressIndicator(
                strokeCap: StrokeCap.round,
                strokeWidth: 5,
                backgroundColor: accentColor,
                trackGap: 12,
                color: Colors.blue,
              ),
              SizedBox(height: 12),
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

  _compressImage({File? passedFile}) async {
    setState(() {
      isLoading = true;
    });
    try {
      File? fileImage;
      int maxSizeInBytes = 2 * 1024 * 1024;

      img = null;
      if (passedFile == null) {
        final file = await FilePicker.platform.pickFiles(type: FileType.image);

        if (file?.files.single.path != null) {
          fileImage = File(file!.files.single.path!);
        }

        if (fileImage != null) {
          img = await compressImageToSize(fileImage, maxSizeInBytes);
        }
      } else {
        img = await compressImageToSize(passedFile, maxSizeInBytes);
      }

      if (img != null) {
        String? outputFile = await FilePicker.platform.saveFile(
          dialogTitle: 'Please select an output file:',
          allowedExtensions: ['png'],
          fileName: 'compressed_${DateTime.now().millisecondsSinceEpoch}.png',
        );

        // Check if the user selected a location (didn't cancel)
        if (outputFile != null) {
          // FIX: Manually ensure the file path ends with the .png extension.
          if (!outputFile.toLowerCase().endsWith('.png')) {
            outputFile = '$outputFile.png';
          }

          // Now, `outputFile` is guaranteed to have the correct extension.
          await img?.copy(outputFile);
        }
      }

      Analytics.instance.trackEvent("image_compression_success");
    } catch (e, trace) {
      Analytics.instance.trackEventWithProperties(
        "image_compression_error",
        {
          'error': e.toString(),
          'stack_trace': trace.toString(),
        },
      );
      CustomNotification.show(
        context,
        "Could not compress image",
        isSuccess: false,
      );

      print(trace);
    } finally {
      Analytics.instance.trackEvent("image_compression_completed");
      setState(() {
        isLoading = false;
      });
    }
  }
}
