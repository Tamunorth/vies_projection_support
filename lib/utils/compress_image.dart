import 'dart:io';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:image/image.dart' as img;
import 'package:path_provider/path_provider.dart';

Future<File?> compressImageToSize(File imageFile, int maxSizeInBytes) async {
  // Read the image from file
  Uint8List imageBytes = await imageFile.readAsBytes();
  String filePath = imageFile.path;

  // Run the compression in an isolate
  Map<String, dynamic> params = {
    'imageBytes': imageBytes,
    'maxSizeInBytes': maxSizeInBytes,
    'filePath': filePath,
  };
  Uint8List? result = await compute(_compressImage, params);

  if (result == null) {
    throw 'Failed to resize';
  }

  // Get the temporary directory
  Directory tempDir = await getTemporaryDirectory();
  String tempPath = tempDir.path;

  // Detect the image format
  bool isPng = filePath.toLowerCase().endsWith('.png');
  String extension = isPng ? 'png' : 'jpg';

  // Create a temporary file for the compressed image
  File compressedFile = File('$tempPath${Random().nextInt(1000)}.$extension');

  await compressedFile.writeAsBytes(result);

  // Return the compressed image file
  return compressedFile;
}

Future<Uint8List?> _compressImage(Map<String, dynamic> params) async {
  Uint8List imageBytes = params['imageBytes'];
  int maxSizeInBytes = params['maxSizeInBytes'];
  String filePath = params['filePath'];

  img.Image image = img.decodeImage(imageBytes)!;

  // Define initial quality and resize factor
  int quality = 100;
  double resizeFactor = 1.0;

  Uint8List? result;
  int currentSize = imageBytes.length;

  // Detect the image format
  bool isPng = filePath.toLowerCase().endsWith('.png');

  // Check if the initial image size is already below the desired size
  if (imageBytes.length <= maxSizeInBytes) {
    print('Image size is already below the desired maximum size.');
    return imageBytes;
  }

  // Compress the image until it meets the size requirement
  while (currentSize > maxSizeInBytes) {
    // Adjust the resize factor and quality
    if (!isPng && quality > 10) {
      quality -= 10;
    } else {
      resizeFactor -= 0.1;
      quality = 100;
    }

    // Resize the image
    img.Image resizedImage = img.copyResize(image,
        width: (image.width * resizeFactor).toInt(),
        height: (image.height * resizeFactor).toInt(),
        maintainAspect: true);

    // Encode the resized image
    if (isPng) {
      result = img.encodePng(resizedImage);
    } else {
      result = img.encodeJpg(resizedImage, quality: quality);
    }

    currentSize = result.length;

    // Prevent from infinite loop if the image cannot be resized any further
    if (resizeFactor <= 0.1) {
      break;
    }
  }

  return result;
}
