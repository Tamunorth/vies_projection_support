import 'dart:io';

import 'package:desktop_drop/desktop_drop.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:untitled/utils/compress_image.dart';

import '../../utils/button_widget.dart';

class ImageCompress extends StatefulWidget {
  const ImageCompress({super.key});

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
                  'DRAG IMAGE HERE',
                  style: Theme.of(context)
                      .textTheme
                      .displayLarge
                      ?.copyWith(color: Colors.white),
                ),
              ],
            ),
            if (img != null)
              Image.file(
                img!,
                width: 240,
                height: 144,
              )
            else
              SizedBox(
                width: 240,
                height: 124,
                child: Placeholder(),
              ),
            if (isLoading) CircularProgressIndicator.adaptive(),
            ButtonWidget(
              title: "Pick Image",
              color: Colors.green,
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
      // XFile? file = /*await picker.pickImage(source: ImageSource.gallery);*/
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
    } catch (e, trace) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Colors.red,
          content: Text('Could not compress image'),
        ),
      );
      print(trace);
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }
}
