import 'dart:io';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:image/image.dart' as img;
import 'package:path_provider/path_provider.dart';
import 'package:untitled/core/analytics.dart';

Future<File?> compressImageToSize(File imageFile, int maxSizeInBytes) async {
  final String filePath = imageFile.path;

  // Pass the file path to the isolate, not the bytes
  final Map<String, dynamic> params = {
    'filePath': filePath,
    'maxSizeInBytes': maxSizeInBytes,
  };

  final stopwatch = Stopwatch()..start();

  // The isolate will now handle all heavy work, including file reading
  final Map<String, dynamic>? result = await compute(_compressImage, params);

  if (result == null || result['bytes'] == null) {
    throw 'Failed to resize';
  }

  final Directory tempDir = await getTemporaryDirectory();
  final String tempPath = tempDir.path;
  final String extension = result['extension'];

  final File compressedFile =
      File('$tempPath${Random().nextInt(1000)}.$extension');
  await compressedFile.writeAsBytes(result['bytes']);

  final analyticsData = {
    'original_size': await imageFile.length(),
    'compressed_size': await compressedFile.length(),
    'size_reduction_percent':
        ((1 - (await compressedFile.length()) / (await imageFile.length())) *
                100)
            .toStringAsFixed(2),
    'original_path': imageFile.path,
    'compressed_path': compressedFile.path,
  };

  // Fire the analytics event with all details
  Analytics.instance.trackEventWithProperties(
    "image_compression_details",
    {
      ...analyticsData,
      'time_taken': '${stopwatch.elapsedMilliseconds} ms',
    },
  );

  stopwatch.stop();

  return compressedFile;
}

Future<Map<String, dynamic>?> _compressImage(
    Map<String, dynamic> params) async {
  // Receive the file path and max size
  final String filePath = params['filePath'];
  final int maxSizeInBytes = params['maxSizeInBytes'];

  // Read the file inside the isolate to avoid blocking the UI thread
  final File imageFile = File(filePath);
  final Uint8List imageBytes = await imageFile.readAsBytes();

  final img.Image? image = img.decodeImage(imageBytes);
  if (image == null) {
    return null; // Could not decode image
  }

  // Define minimum dimensions for YouTube thumbnails
  const int minWidth = 1280;
  const int minHeight = 720;

  // Define initial quality and resize factor
  int quality = 100;
  double resizeFactor = 1.0;

  // Smaller steps for finer control and getting closer to target size
  const double resizeStep =
      0.1; // resizeStep reduction percentage per iteration
  const int qualityStep = 5; // qualityStep reduction

  Uint8List? result;
  int currentSize = imageBytes.length;

  // Detect the image format
  bool isPng = filePath.toLowerCase().endsWith('.png');
  bool convertedToJpg = false;

  // Check if the initial image size is already below the desired size
  if (imageBytes.length <= maxSizeInBytes) {
    return {
      'bytes': imageBytes,
      'extension': isPng ? 'png' : 'jpg',
    };
  }

  // Check if the image is already smaller than minimum dimensions
  if (image.width < minWidth || image.height < minHeight) {
    // Try to compress with quality reduction only
    if (!isPng) {
      while (currentSize > maxSizeInBytes && quality > 5) {
        quality -= qualityStep;
        result = img.encodeJpg(image, quality: quality);
        currentSize = result.length;
      }
      return {
        'bytes': result ?? imageBytes,
        'extension': 'jpg',
      };
    }
    // If PNG and can't compress further, convert to JPG
    while (currentSize > maxSizeInBytes && quality > 5) {
      quality -= qualityStep;
      result = img.encodeJpg(image, quality: quality);
      currentSize = result.length;
      convertedToJpg = true;
    }
    return {
      'bytes': result ?? imageBytes,
      'extension': convertedToJpg ? 'jpg' : 'png',
    };
  }

  // Compress the image until it meets the size requirement
  while (currentSize > maxSizeInBytes) {
    // Calculate the next resize dimensions
    int newWidth = (image.width * (resizeFactor - resizeStep)).toInt();
    int newHeight = (image.height * (resizeFactor - resizeStep)).toInt();

    // Check if resizing would make the image smaller than minimum dimensions
    bool canResize = newWidth >= minWidth && newHeight >= minHeight;

    // Adjust the resize factor and quality
    if (!isPng && quality > 5) {
      quality -= qualityStep;
    } else if (canResize) {
      resizeFactor -= resizeStep;
      quality = 100;
    } else {
      // Can't resize further
      if (!isPng && quality > 5) {
        quality -= qualityStep;
      } else if (isPng) {
        // PNG hit minimum dimensions - convert to JPG and continue compressing
        print(
            'PNG cannot be compressed further by resizing. Converting to JPG...');
        isPng = false;
        convertedToJpg = true;
        quality = 95; // Start with high quality for converted image
      } else {
        print(
            'Cannot compress further without going below minimum dimensions.');
        break;
      }
    }

    // Resize the image if allowed
    img.Image processedImage;
    if (resizeFactor < 1.0 && canResize) {
      processedImage = img.copyResize(image,
          width: (image.width * resizeFactor).toInt(),
          height: (image.height * resizeFactor).toInt(),
          maintainAspect: true);
    } else {
      processedImage = image;
    }

    // Encode the processed image
    if (isPng) {
      result = img.encodePng(processedImage);
    } else {
      result = img.encodeJpg(processedImage, quality: quality);
    }

    currentSize = result.length;

    // Prevent infinite loop - check if we've reached minimum thresholds
    if (resizeFactor <= resizeStep && quality <= 5) {
      break;
    }
  }

  return {
    'bytes': result,
    'extension': convertedToJpg || !isPng ? 'jpg' : 'png',
  };
}
