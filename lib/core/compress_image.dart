import 'dart:io';
import 'dart:math' show Random;

import 'package:flutter/foundation.dart';
import 'package:image/image.dart' as img;
import 'package:path_provider/path_provider.dart';
import 'package:untitled/core/analytics.dart';
import 'dart:developer';

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

  log('time taken details: ${stopwatch.elapsedMilliseconds} ms');

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

/// Compresses an image by iteratively resizing it by 20% until it reaches
/// minimum dimensions, then converting to JPG and reducing quality.
///
/// This function provides detailed logs to track the compression process.
/// It first attempts to meet the size constraints by resizing alone. If that
/// fails, it switches to a more aggressive JPG quality reduction phase.
///
/// [params] A map containing:
/// - 'filePath': The path to the image file to compress.
/// - 'maxSizeInBytes': The target maximum file size in bytes.
Future<Map<String, dynamic>?> _compressImage(
  Map<String, dynamic> params,
) async {
  final String filePath = params['filePath'];
  final int maxSizeInBytes = params['maxSizeInBytes'];

  final File imageFile = File(filePath);
  final Uint8List imageBytes = await imageFile.readAsBytes();

  if (imageBytes.length <= maxSizeInBytes) {
    return {
      'bytes': imageBytes,
      'extension': filePath.toLowerCase().endsWith('.png') ? 'png' : 'jpg',
    };
  }

  final img.Image? originalImage = img.decodeImage(imageBytes);
  if (originalImage == null) {
    log('Failed to decode image.');
    return null;
  }

  const int minWidth = 1280;
  const int minHeight = 720;
  final bool isOriginalPng = filePath.toLowerCase().endsWith('.png');
  img.Image currentImage = originalImage;
  Uint8List? resultBytes;

  log('Starting compression for $filePath');
  log('Original dims: ${originalImage.width}x${originalImage.height}, '
      'size: ${imageBytes.length} bytes');

  // --- Phase 1: Iterative Resizing by 20% ---
  double resizeFactor = 1.0;
  while (true) {
    // Check size at the current dimension
    if (isOriginalPng) {
      resultBytes = img.encodePng(currentImage);
    } else {
      resultBytes = img.encodeJpg(currentImage, quality: 95);
    }

    log('Current dims: ${currentImage.width}x${currentImage.height}, '
        'size: ${resultBytes.length} bytes');

    if (resultBytes.length <= maxSizeInBytes) {
      log('Image is now under the size limit. Success!');
      return {
        'bytes': resultBytes,
        'extension': isOriginalPng ? 'png' : 'jpg',
      };
    }

    resizeFactor *= 0.70; // Reduce by 25% each iteration

    final int nextWidth = (originalImage.width * resizeFactor).toInt();
    final int nextHeight =
        (originalImage.height * (nextWidth / originalImage.width)).toInt();

    if (nextWidth < minWidth || nextHeight < minHeight) {
      log('Next resize would go below minimums. Stopping resize loop.');
      break;
    }

    log('Resizing to ${nextWidth}x${nextHeight}...');
    currentImage = img.copyResize(
      originalImage, // Always resize from original for best quality
      width: nextWidth,
      maintainAspect: true,
    );
  }

  // --- Phase 2: Convert to JPG and Reduce Quality ---
  log('Reached minimum size. Starting JPG quality reduction.');
  int quality = 95;
  const int qualityStep = 5;

  while (quality > 5) {
    resultBytes = img.encodeJpg(currentImage, quality: quality);
    log('Trying JPG quality $quality%. Size: ${resultBytes.length} bytes');

    if (resultBytes.length <= maxSizeInBytes) {
      log('Found suitable quality at $quality%. Success!');
      return {'bytes': resultBytes, 'extension': 'jpg'};
    }
    quality -= qualityStep;
  }

  log('Could not get under size limit. Returning best effort.');
  return {
    'bytes': resultBytes, // This will be the smallest version
    'extension': 'jpg',
  };
}
