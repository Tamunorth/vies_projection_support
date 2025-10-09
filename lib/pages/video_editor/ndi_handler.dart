// lib/ndi_handler.dart

import 'dart:async';
import 'dart:developer' as dev;
import 'dart:ffi' as ffi;
import 'dart:typed_data';

import 'package:ffi/ffi.dart';
import 'package:vies_projection_support/pages/video_editor/ndi_native_bindings.dart';

class NDIHandler {
  final NDIBindings _ndiBindings;
  ffi.Pointer? _sender;
  bool _isInitialized = false;
  String _sourceName;
  Timer? _sourceDiscoveryTimer;
  List<NDISource> _currentSources = [];

  // Track previous frame dimensions
  int _lastWidth = 0;
  int _lastHeight = 0;
  bool _isFirstFrame = true;

  NDIHandler({
    required NDIBindings ndiBindings,
    String sourceName = 'Flutter NDI Source',
  })  : _ndiBindings = ndiBindings,
        _sourceName = sourceName;

  List<NDISource> get sources => List.unmodifiable(_currentSources);

  bool get isInitialized => _isInitialized;

  void handleVideoFrame(
    Uint8List frameData,
    int width,
    int height, {
    int frameRateN = 30000,
    int frameRateD = 1001,
  }) {
    if (!_isInitialized || _sender == null) {
      dev.log('NDI not initialized or sender is null');
      return;
    }

    try {
      if (frameData.length != width * height * 4) {
        dev.log(
            'Invalid frame data size: expected ${width * height * 4}, got ${frameData.length}');
        return;
      }

      // Log first frame dimensions
      if (_isFirstFrame) {
        dev.log('First frame size: ${width}x${height}');
        _isFirstFrame = false;
      }

      // Keep the RGBA data as is, since NDI can handle it
      final data = calloc<ffi.Uint8>(frameData.length);
      final buffer = data.asTypedList(frameData.length);
      buffer.setAll(0, frameData);

      // Create video frame structure
      final videoFrame = _ndiBindings.createVideoFrame(
        width: width,
        height: height,
        data: data,
        frameRateN: frameRateN,
        frameRateD: frameRateD,
      );

      // Update frame format to BGRA
      videoFrame.ref.FourCC = 0x42475241; // BGRA FourCC code
      videoFrame.ref.line_stride_in_bytes = width * 4;
      videoFrame.ref.frame_format_type = 1; // Progressive frame
      videoFrame.ref.picture_aspect_ratio = width / height;

      // Send frame
      _ndiBindings.senderSendVideo(_sender!, videoFrame);

      // Cleanup
      calloc.free(data);
      calloc.free(videoFrame);
    } catch (e, stackTrace) {
      dev.log('Error sending NDI frame', error: e, stackTrace: stackTrace);
    }
  }

  Future<void> startStream() async {
    if (_isInitialized) return;

    try {
      final success = _ndiBindings.initialize();
      if (!success) {
        throw Exception('Failed to initialize NDI');
      }

      // Create NDI sender with specific settings
      final settings = _ndiBindings.createSenderSettings(
        ndiName: _sourceName,
        groups: null,
        clockVideo: true,
        clockAudio: false,
      );

      _sender = _ndiBindings.senderCreate(settings);
      calloc.free(settings);

      if (_sender == ffi.nullptr) {
        throw Exception('Failed to create NDI sender');
      }

      _isInitialized = true;
      _isFirstFrame = true;
      // _startSourceDiscovery();
      dev.log('NDI stream started successfully');
    } catch (e) {
      dev.log('Error starting NDI stream: $e');
      await dispose();
      rethrow;
    }
  }

  void _convertRGBAtoUYVY(
      Uint8List rgba, Uint8List uyvy, int width, int height) {
    final int pixelCount = width * height;

    for (int i = 0; i < pixelCount - 1; i += 2) {
      final int rgbaIndex1 = i * 4;
      final int rgbaIndex2 = (i + 1) * 4;
      final int uyvyIndex = i * 2;

      if (rgbaIndex2 + 3 >= rgba.length || uyvyIndex + 3 >= uyvy.length) break;

      // First pixel
      final r1 = rgba[rgbaIndex1];
      final g1 = rgba[rgbaIndex1 + 1];
      final b1 = rgba[rgbaIndex1 + 2];

      // Second pixel
      final r2 = rgba[rgbaIndex2];
      final g2 = rgba[rgbaIndex2 + 1];
      final b2 = rgba[rgbaIndex2 + 2];

      // Calculate Y values (BT.601)
      final y1 = (0.299 * r1 + 0.587 * g1 + 0.114 * b1).round().clamp(0, 255);
      final y2 = (0.299 * r2 + 0.587 * g2 + 0.114 * b2).round().clamp(0, 255);

      // Calculate U and V values (BT.601)
      final u = (-0.14713 * r1 - 0.28886 * g1 + 0.436 * b1 + 128)
          .round()
          .clamp(0, 255);
      final v = (0.615 * r1 - 0.51499 * g1 - 0.10001 * b1 + 128)
          .round()
          .clamp(0, 255);

      // Pack as UYVY
      uyvy[uyvyIndex] = u;
      uyvy[uyvyIndex + 1] = y1;
      uyvy[uyvyIndex + 2] = v;
      uyvy[uyvyIndex + 3] = y2;
    }
  }

  Future<void> dispose() async {
    dev.log('Disposing NDI handler');
    _sourceDiscoveryTimer?.cancel();
    _currentSources.clear();

    if (_sender != null && _sender != ffi.nullptr) {
      try {
        _ndiBindings.senderDestroy(_sender!);
        dev.log('NDI sender destroyed successfully');
      } catch (e) {
        dev.log('Error destroying NDI sender: $e');
      }
      _sender = null;
    }

    _isInitialized = false;
    _isFirstFrame = true;
    _lastWidth = 0;
    _lastHeight = 0;
  }

  void _startSourceDiscovery() {
    _sourceDiscoveryTimer?.cancel();
    _sourceDiscoveryTimer = Timer.periodic(
      const Duration(seconds: 1),
      (_) => _findSources(),
    );
  }

  void _findSources() {
    dev.log('finding sources');
    if (!_isInitialized) return;

    final numSourcesPtr = calloc<ffi.Uint32>();

    dev.log('finding numSourcesPtr');

    try {
      final sourcesPtr = _ndiBindings.findGetSources(
        _sender!,
        numSourcesPtr,
        1000,
      );

      dev.log('finding sourcesPtr');

      if (sourcesPtr != ffi.nullptr) {
        final numSources = numSourcesPtr.value;
        _updateSources(sourcesPtr, numSources);
      }
    } finally {
      calloc.free(numSourcesPtr);
    }
  }

  void _updateSources(ffi.Pointer<NDIlib_source_t> sourcesPtr, int numSources) {
    _currentSources.clear();

    for (var i = 0; i < numSources; i++) {
      final source = sourcesPtr.elementAt(i).ref;
      _currentSources.add(
        NDISource(
          name: source.p_ndi_name.toDartString(),
          urlAddress: source.p_url_address.toDartString(),
          pointer: sourcesPtr.elementAt(i),
        ),
      );
    }
  }

  Future<List<NDISource>> refreshSources() async {
    _findSources();
    return sources;
  }
}

class NDISource {
  final String name;
  final String urlAddress;
  final ffi.Pointer<NDIlib_source_t> pointer;

  NDISource({
    required this.name,
    required this.urlAddress,
    required this.pointer,
  });

  @override
  String toString() => 'NDISource(name: $name, urlAddress: $urlAddress)';
}
