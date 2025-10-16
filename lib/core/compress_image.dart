import 'dart:io';
import 'dart:math' show Random;

import 'package:flutter/foundation.dart';
import 'package:image/image.dart' as img;
import 'package:path_provider/path_provider.dart';
import 'package:vies_projection_support/core/analytics.dart';
import 'dart:developer';

import 'package:vies_projection_support/core/enums/aspect_ratio_mode.dart';

/// Compresses an image file to be under the specified maximum size in bytes.
///
/// Compresses an image file to be under the specified maximum size in bytes.
///
/// If an [aspectRatioMode] is provided and is not
/// [AspectRatioMode.maintainDimensions], the image will first be processed
/// to fit a 16:9 aspect ratio. Otherwise, this step is skipped, and the
/// image is compressed with its original dimensions.
///
/// [imageFile] The original image file.
/// [maxSizeInBytes] The target maximum size for the compressed image.
/// [aspectRatioMode] The mode to handle the image's aspect ratio.
///   - `centerCrop`: Crops the image to 16:9.
///   - `stretch`: Stretches the image to 16:9.
///   - `maintainDimensions`: Skips aspect ratio changes and resizing.
Future<File?> compressImageToSize(
  File imageFile,
  int maxSizeInBytes, {
  AspectRatioMode? aspectRatioMode,
}) async {
  final stopwatch = Stopwatch()..start();
  File fileToProcess = imageFile;

  // --- Step 1 (Isolate): Enforce Aspect Ratio ---
  if (aspectRatioMode != null &&
      aspectRatioMode != AspectRatioMode.maintainDimensions) {
    log('Starting aspect ratio enforcement: ${aspectRatioMode.name}');
    final Map<String, dynamic> aspectRatioParams = {
      'filePath': imageFile.path,
      'mode': aspectRatioMode.index,
    };

    final Map<String, dynamic>? result =
        await compute(_enforceAspectRatio, aspectRatioParams);

    if (result != null && result['bytes'] != null) {
      final Directory tempDir = await getTemporaryDirectory();
      final String extension = result['extension'];
      final String newPath =
          '${tempDir.path}/${Random().nextInt(10000)}_aspect.$extension';
      fileToProcess = await File(newPath).writeAsBytes(result['bytes']);
      log('Saved aspect-ratio-enforced image to temp file: ${newPath}');
    }
  }

  // --- Step 2 (Isolate): Compress Image ---
  log('Starting compression for ${fileToProcess.path}');
  final Map<String, dynamic> compressionParams = {
    'filePath': fileToProcess.path,
    'maxSizeInBytes': maxSizeInBytes,
    'maintainDimensions': aspectRatioMode == AspectRatioMode.maintainDimensions,
  };
  final Map<String, dynamic>? result =
      await compute(_compressImage, compressionParams);

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

  log('Total time taken: ${stopwatch.elapsedMilliseconds} ms');
  Analytics.instance.trackEventWithProperties("image_compression_details", {
    ...analyticsData,
    'time_taken': '${stopwatch.elapsedMilliseconds} ms',
  });
  stopwatch.stop();

  return compressedFile;
}

/// Compresses an image by iteratively resizing it (unless dimensions are
/// maintained), then converting to JPG and reducing quality if necessary.
///
/// This function provides detailed logs to track the compression process.
/// It first attempts to meet the size constraints by resizing. If that
/// fails, or if resizing is skipped, it switches to a more aggressive
/// JPG quality reduction phase.
///
/// [params] A map containing:
/// - 'filePath': The path to the image file to compress.
/// - 'maxSizeInBytes': The target maximum file size in bytes.
/// - 'maintainDimensions': A boolean to prevent image resizing.
Future<Map<String, dynamic>?> _compressImage(
  Map<String, dynamic> params,
) async {
  final String filePath = params['filePath'];
  final int maxSizeInBytes = params['maxSizeInBytes'];
  final bool maintainDimensions = params['maintainDimensions'] ?? false;

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

  const int minWidth = 1920;
  const int minHeight = 1080;
  final bool isOriginalPng = filePath.toLowerCase().endsWith('.png');
  img.Image currentImage = originalImage;
  Uint8List? resultBytes;

  log('Starting compression for $filePath');
  log('Original dims: ${originalImage.width}x${originalImage.height}, '
      'size: ${imageBytes.length} bytes');

  // --- Phase 1: Iterative Resizing by 20% ---
  if (!maintainDimensions) {
    double resizeFactor = 1.0;
    while (true) {
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

      resizeFactor *= 0.9;

      final int nextWidth = (originalImage.width * resizeFactor).toInt();
      final int nextHeight =
          (originalImage.height * (nextWidth / originalImage.width)).toInt();

      if (nextWidth < minWidth || nextHeight < minHeight) {
        log('Next resize would go below minimums. Stopping resize loop.');
        break;
      }

      log('Resizing to ${nextWidth}x${nextHeight}...');
      currentImage = img.copyResize(
        originalImage,
        width: nextWidth,
        maintainAspect: true,
      );
    }
  }

  // --- Phase 2: Convert to JPG and Reduce Quality ---
  log(maintainDimensions
      ? 'Maintaining dimensions. Starting JPG quality reduction.'
      : 'Reached minimum size. Starting JPG quality reduction.');
  int quality = 98;
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
    'bytes': resultBytes,
    'extension': 'jpg',
  };
}

/// Processes an image to enforce a 16:9 aspect ratio.
///
/// Returns the path to a new, temporary file if modification was needed,
/// otherwise returns the original file path.
/// Processes an image to enforce a 16:9 aspect ratio in an isolate.
///
/// Returns a map with the modified image's bytes and extension, or null
/// if no modification was needed.
Future<Map<String, dynamic>?> _enforceAspectRatio(
  Map<String, dynamic> params,
) async {
  final String filePath = params['filePath'];
  final AspectRatioMode mode = AspectRatioMode.values[params['mode']];

  final imageBytes = await File(filePath).readAsBytes();
  final img.Image? image = img.decodeImage(imageBytes);

  if (image == null) return null;

  const double targetAspectRatio = 16.0 / 9.0;
  final double currentAspectRatio = image.width / image.height;

  if ((currentAspectRatio - targetAspectRatio).abs() < 0.01) {
    log('Image is already 16:9. No changes needed.');
    return null; // Return null to indicate no changes were made
  }

  log('Image is not 16:9. Applying mode: ${mode.name}');
  img.Image modifiedImage;

  if (mode == AspectRatioMode.centerCrop) {
    int cropWidth, cropHeight, x, y;
    if (currentAspectRatio > targetAspectRatio) {
      cropHeight = image.height;
      cropWidth = (cropHeight * targetAspectRatio).toInt();
      x = (image.width - cropWidth) ~/ 2;
      y = 0;
    } else {
      cropWidth = image.width;
      cropHeight = (cropWidth / targetAspectRatio).toInt();
      x = 0;
      y = (image.height - cropHeight) ~/ 2;
    }
    modifiedImage =
        img.copyCrop(image, x: x, y: y, width: cropWidth, height: cropHeight);
  } else {
    // AspectRatioMode.stretch
    modifiedImage = img.copyResize(
      image,
      width: image.width,
      height: (image.width / targetAspectRatio).toInt(),
      maintainAspect: false,
    );
  }

  final String extension = filePath.split('.').last.toLowerCase();
  final Uint8List outputBytes = extension == 'png'
      ? img.encodePng(modifiedImage)
      : img.encodeJpg(modifiedImage);

  return {'bytes': outputBytes, 'extension': extension};
}
