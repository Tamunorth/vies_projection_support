/// Defines how to enforce a 16:9 aspect ratio on an image.
enum AspectRatioMode {
  /// Stretches the image to fit 16:9, preserving the original width.
  stretch,

  /// Crops the image from the center to a 16:9 frame.
  centerCrop,

  /// Keeps the original aspect ratio of the image.
  maintainDimensions,
}

/// Provides user-friendly display names for the [AspectRatioMode] enum.
extension AspectRatioModeExtension on AspectRatioMode {
  String get displayName {
    switch (this) {
      case AspectRatioMode.maintainDimensions:
        return 'Maintain Dimensions';
      case AspectRatioMode.stretch:
        return 'Stretch to 16:9';
      case AspectRatioMode.centerCrop:
        return 'Center Crop to 16:9';
    }
  }
}
