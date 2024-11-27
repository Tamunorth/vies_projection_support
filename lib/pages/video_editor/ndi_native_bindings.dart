// lib/ndi_native_bindings.dart

import 'dart:developer' as developer;
import 'dart:ffi' as ffi;
import 'dart:io' show Platform;

import 'package:ffi/ffi.dart';

// NDI SDK structs
base class NDIlib_find_create_t extends ffi.Struct {
  @ffi.Bool()
  external bool show_local_sources;
  external ffi.Pointer<Utf8> p_groups;
  external ffi.Pointer<Utf8> p_extra_ips;
}

base class NDIlib_source_t extends ffi.Struct {
  external ffi.Pointer<Utf8> p_ndi_name;
  external ffi.Pointer<Utf8> p_url_address;
}

base class NDIlib_send_create_t extends ffi.Struct {
  external ffi.Pointer<Utf8> p_ndi_name;
  external ffi.Pointer<Utf8> p_groups;
  @ffi.Bool()
  external bool clock_video;
  @ffi.Bool()
  external bool clock_audio;
}

base class NDIlib_video_frame_v2_t extends ffi.Struct {
  @ffi.Int32()
  external int xres;
  @ffi.Int32()
  external int yres;
  @ffi.Int32()
  external int FourCC;
  @ffi.Int32()
  external int frame_rate_N;
  @ffi.Int32()
  external int frame_rate_D;
  @ffi.Float()
  external double picture_aspect_ratio;
  @ffi.Int32()
  external int frame_format_type;
  @ffi.Int64()
  external int timecode;
  external ffi.Pointer<ffi.Uint8> p_data;
  @ffi.Int32()
  external int line_stride_in_bytes;
  external ffi.Pointer<Utf8> p_metadata;
  @ffi.Int64()
  external int timestamp;
}

// Native function types
typedef NDIlib_initialize_native = ffi.Bool Function();
typedef NDIlib_initialize_dart = bool Function();

typedef NDIlib_find_create_v2_native = ffi.Pointer Function(
    ffi.Pointer<NDIlib_find_create_t> p_create_settings);
typedef NDIlib_find_create_v2_dart = ffi.Pointer Function(
    ffi.Pointer<NDIlib_find_create_t> p_create_settings);

typedef NDIlib_find_get_sources_native = ffi.Pointer<NDIlib_source_t> Function(
    ffi.Pointer finder,
    ffi.Pointer<ffi.Uint32> numSources,
    ffi.Uint32 timeout_in_ms);
typedef NDIlib_find_get_sources_dart = ffi.Pointer<NDIlib_source_t> Function(
    ffi.Pointer finder, ffi.Pointer<ffi.Uint32> numSources, int timeout_in_ms);

typedef NDIlib_find_wait_for_sources_native = ffi.Bool Function(
    ffi.Pointer finder, ffi.Uint32 timeout_in_ms);
typedef NDIlib_find_wait_for_sources_dart = bool Function(
    ffi.Pointer finder, int timeout_in_ms);

typedef NDIlib_send_create_native = ffi.Pointer Function(
    ffi.Pointer<NDIlib_send_create_t> p_create_settings);
typedef NDIlib_send_create_dart = ffi.Pointer Function(
    ffi.Pointer<NDIlib_send_create_t> p_create_settings);

typedef NDIlib_send_destroy_native = ffi.Void Function(ffi.Pointer sender);
typedef NDIlib_send_destroy_dart = void Function(ffi.Pointer sender);

typedef NDIlib_send_send_video_v2_native = ffi.Void Function(
    ffi.Pointer sender, ffi.Pointer<NDIlib_video_frame_v2_t> p_video_data);
typedef NDIlib_send_send_video_v2_dart = void Function(
    ffi.Pointer sender, ffi.Pointer<NDIlib_video_frame_v2_t> p_video_data);

class NDIBindings {
  late final ffi.DynamicLibrary _ndiLib;

  late final NDIlib_initialize_dart initialize;
  late final NDIlib_find_create_v2_dart findCreate;
  late final NDIlib_find_get_sources_dart findGetSources;
  late final NDIlib_find_wait_for_sources_dart findWaitForSources;
  late final NDIlib_send_create_dart senderCreate;
  late final NDIlib_send_destroy_dart senderDestroy;
  late final NDIlib_send_send_video_v2_dart senderSendVideo;

  NDIBindings() {
    _ndiLib = _loadNDILibrary();
    _bindFunctions();
  }

  ffi.DynamicLibrary _loadNDILibrary() {
    if (Platform.isMacOS) {
      const mainPath = '/Library/NDI SDK for Apple/lib/macOS/libndi.dylib';
      try {
        developer.log('Loading NDI library from: $mainPath');
        return ffi.DynamicLibrary.open(mainPath);
      } catch (e) {
        developer.log('Failed to load NDI library: $e');
        throw UnsupportedError('Failed to load NDI library from $mainPath: $e');
      }
    } else if (Platform.isWindows) {
      try {
        return ffi.DynamicLibrary.open('Processing.NDI.Lib.x64.dll');
      } catch (e) {
        throw UnsupportedError('NDI library not found: $e');
      }
    }
    throw UnsupportedError('Unsupported platform');
  }

  void _bindFunctions() {
    try {
      developer.log('Binding NDI functions...');

      initialize = _ndiLib
          .lookup<ffi.NativeFunction<NDIlib_initialize_native>>(
              'NDIlib_initialize')
          .asFunction();

      findCreate = _ndiLib
          .lookup<ffi.NativeFunction<NDIlib_find_create_v2_native>>(
              'NDIlib_find_create_v2')
          .asFunction();

      findGetSources = _ndiLib
          .lookup<ffi.NativeFunction<NDIlib_find_get_sources_native>>(
              'NDIlib_find_get_current_sources')
          .asFunction();

      findWaitForSources = _ndiLib
          .lookup<ffi.NativeFunction<NDIlib_find_wait_for_sources_native>>(
              'NDIlib_find_wait_for_sources')
          .asFunction();

      senderCreate = _ndiLib
          .lookup<ffi.NativeFunction<NDIlib_send_create_native>>(
              'NDIlib_send_create') // Changed from NDIlib_send_create_v2
          .asFunction();

      senderDestroy = _ndiLib
          .lookup<ffi.NativeFunction<NDIlib_send_destroy_native>>(
              'NDIlib_send_destroy')
          .asFunction();

      senderSendVideo = _ndiLib
          .lookup<ffi.NativeFunction<NDIlib_send_send_video_v2_native>>(
              'NDIlib_send_send_video_v2')
          .asFunction();

      developer.log('All NDI functions bound successfully');
    } catch (e, stack) {
      developer.log('Error binding NDI functions', error: e, stackTrace: stack);
      rethrow;
    }
  }

  ffi.Pointer<NDIlib_find_create_t> createFindSettings({
    bool showLocalSources = true,
    String? groups,
    String? extraIps,
  }) {
    final settings = calloc<NDIlib_find_create_t>();
    settings.ref.show_local_sources = showLocalSources;
    settings.ref.p_groups =
        groups != null ? groups.toNativeUtf8() : ffi.nullptr;
    settings.ref.p_extra_ips =
        extraIps != null ? extraIps.toNativeUtf8() : ffi.nullptr;
    return settings;
  }

  ffi.Pointer<NDIlib_send_create_t> createSenderSettings({
    required String ndiName,
    String? groups,
    bool clockVideo = false,
    bool clockAudio = false,
  }) {
    final settings = calloc<NDIlib_send_create_t>();
    settings.ref.p_ndi_name = ndiName.toNativeUtf8();
    // settings.ref.p_groups =nullptr;
    settings.ref.clock_video = clockVideo;
    settings.ref.clock_audio = clockAudio;
    return settings;
  }

  ffi.Pointer<NDIlib_video_frame_v2_t> createVideoFrame({
    required int width,
    required int height,
    required ffi.Pointer<ffi.Uint8> data,
    int frameRateN = 30000,
    int frameRateD = 1001,
    double aspectRatio = 16 / 9,
  }) {
    final frame = calloc<NDIlib_video_frame_v2_t>();
    frame.ref.xres = width;
    frame.ref.yres = height;
    frame.ref.FourCC = 0x42475241; // BGRA
    frame.ref.frame_rate_N = frameRateN;
    frame.ref.frame_rate_D = frameRateD;
    frame.ref.picture_aspect_ratio = width / height;
    frame.ref.frame_format_type = 1; // Progressive
    frame.ref.timecode = 0;
    frame.ref.p_data = data;
    frame.ref.line_stride_in_bytes = width * 4; // 4 bytes per pixel (BGRA)
    frame.ref.p_metadata = ffi.nullptr;
    frame.ref.timestamp = 0;
    return frame;
  }
}
