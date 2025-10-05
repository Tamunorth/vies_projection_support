// import 'dart:async';
// import 'dart:developer' as dev;
// import 'dart:io';
// import 'dart:math';
// import 'dart:typed_data';
// import 'dart:ui' as ui;
//
// import 'package:ffmpeg_helper/ffmpeg_helper.dart';
// import 'package:file_picker/file_picker.dart';
// import 'package:flutter/material.dart';
// import 'package:flutter/rendering.dart';
// import 'package:media_kit/media_kit.dart';
// import 'package:media_kit_video/media_kit_video.dart';
// import 'package:path/path.dart' as path;
// import 'package:path_provider/path_provider.dart';
// import 'package:process_run/process_run.dart';
// import 'package:vies_projection_support/pages/video_editor/ndi_handler.dart';
// import 'package:vies_projection_support/pages/video_editor/ndi_native_bindings.dart';
//
// class VideoEditorController extends ChangeNotifier {
//   Player player = Player();
//   VideoController? controller;
//
//   final ffmpeg = FFMpegHelper.instance;
//
//   File? _videoFile;
//   double _speedFactor = 1.0;
//   bool _isProcessing = false;
//   Duration _startTrim = Duration.zero;
//   Duration _endTrim = Duration.zero;
//   bool _isTrimming = false;
//   Duration _duration = Duration.zero;
//   String? _ffmpegPath;
//
//   ValueNotifier<FFMpegProgress> downloadProgress = ValueNotifier(
//     FFMpegProgress(
//       downloaded: 0,
//       fileSize: 0,
//       phase: FFMpegProgressPhase.inactive,
//     ),
//   );
//
// // Getters
//   VideoController? get videoController => controller;
//
//   File? get videoFile => _videoFile;
//
//   double get speedFactor => _speedFactor;
//
//   bool get isProcessing => _isProcessing;
//
//   Duration get startTrim => _startTrim;
//
//   Duration get endTrim => _endTrim;
//
//   bool get isTrimming => _isTrimming;
//
//   bool get hasVideo => _videoFile != null;
//
//   Duration get duration => _duration;
//
//   VideoEditorController() {
//     _initFFmpeg();
//     player.stream.duration.listen((duration) {
//       _duration = duration;
//       if (_endTrim == Duration.zero) {
//         _endTrim = duration;
//       }
//       notifyListeners();
//     });
//   }
//
//   Future<void> _initFFmpeg() async {
//     try {
// // Initialize FFmpeg helper
//       await FFMpegHelper.instance.initialize();
//
//       if (Platform.isWindows) {
// // Setup FFmpeg on Windows using ffmpeg_helper
//         bool success = await ffmpeg.setupFFMpegOnWindows(
//           onProgress: (FFMpegProgress progress) {
//             downloadProgress.value = progress;
//           },
//         );
//
//         if (success) {
// // Get the FFmpeg path from the helper package's installation
//           final appDocDir = await getApplicationDocumentsDirectory();
//           _ffmpegPath =
//               path.join(appDocDir.path, 'ffmpeg', 'bin', 'ffmpeg.exe');
//         } else {
//           throw Exception('Failed to setup FFmpeg on Windows');
//         }
//       } else {
// // For other platforms, use system FFmpeg
//         _ffmpegPath = 'ffmpeg';
//       }
//
// // Verify FFmpeg installation
//       final shell = Shell();
//       await shell.run('$_ffmpegPath -version');
//     } catch (e) {
//       dev.log('FFmpeg initialization error: $e');
//       rethrow;
//     }
//   }
//
//   @override
//   void dispose() {
//     stopNDIStream();
//
//     player.dispose();
//
//     super.dispose();
//   }
//
//   Process? _ffmPegProcess;
//   bool _isStreamingNDI = false;
//   String _ndiOutputName = 'Vies Projection support';
//
//   bool get isStreamingNDI => _isStreamingNDI;
//
//   static const int FRAME_WIDTH = 1920;
//   static const int FRAME_HEIGHT = 1080;
//   static const int AUDIO_BUFFER_SIZE = 1024;
//
//   Uint8List? _videoBuffer;
//   Float32List? _audioBuffer;
//   int _audioBufferPosition = 0;
//
//   NDIHandler? _ndiHandler;
//
//   Timer? _frameTimer;
//   StreamSubscription? _playerPositionSubscription;
//
//   String get ndiOutputName => _ndiOutputName;
//   GlobalKey repaintBoundaryKey = GlobalKey();
//   Timer? _captureTimer;
//   bool _isCapturing = false;
//
//   Future<void> startNDIStream() async {
//     if (_videoFile == null) {
//       throw Exception('No video to stream');
//     }
//
//     try {
//       if (_isStreamingNDI) {
//         await stopNDIStream();
//       }
//
//       // Initialize NDI
//       _ndiHandler ??= NDIHandler(
//         ndiBindings: NDIBindings(),
//         sourceName: _ndiOutputName,
//       );
//
//       await _ndiHandler!.startStream();
//
//       // Start frame capture using RepaintBoundary
//       _frameTimer = Timer.periodic(const Duration(milliseconds: 33), (_) async {
//         if (!_isStreamingNDI) return;
//
//         try {
//           final boundary = repaintBoundaryKey.currentContext?.findRenderObject()
//               as RenderRepaintBoundary?;
//           if (boundary == null) return;
//
//           // Capture at a specific scale for better quality
//           final image = await boundary.toImage();
//           // Use BGRA format as it's more compatible with NDI
//           final byteData =
//               await image.toByteData(format: ui.ImageByteFormat.rawRgba);
//
//           if (byteData != null) {
//             // Convert RGBA to BGRA
//             final rgbaData = byteData.buffer.asUint8List();
//             final bgraData = Uint8List(rgbaData.length);
//
//             for (var i = 0; i < rgbaData.length; i += 4) {
//               // RGBA to BGRA conversion
//               bgraData[i] = rgbaData[i + 2]; // B = R
//               bgraData[i + 1] = rgbaData[i + 1]; // G = G
//               bgraData[i + 2] = rgbaData[i]; // R = B
//               bgraData[i + 3] = rgbaData[i + 3]; // A = A
//             }
//
//             _ndiHandler?.handleVideoFrame(
//               bgraData,
//               image.width,
//               image.height,
//             );
//           }
//         } catch (e) {
//           dev.log('Error capturing frame: $e');
//         }
//       });
//
//       _isStreamingNDI = true;
//       notifyListeners();
//     } catch (e) {
//       await stopNDIStream();
//       dev.log('Error starting NDI stream: $e');
//       rethrow;
//     }
//   }
//
//   Future<void> stopNDIStream() async {
//     _frameTimer?.cancel();
//     _frameTimer = null;
//
//     await _ndiHandler?.dispose();
//     _ndiHandler = null;
//
//     _isStreamingNDI = false;
//     notifyListeners();
//   }
//
//   void _startFrameCapture() {
//     _captureTimer?.cancel();
//     _captureTimer = Timer.periodic(
//       const Duration(milliseconds: 33), // ~30fps
//       (_) => _captureFrame(),
//     );
//   }
//
//   Future<void> _captureFrame() async {
//     if (!_isCapturing || !_isStreamingNDI) return;
//
//     try {
//       final boundary = repaintBoundaryKey.currentContext?.findRenderObject()
//           as RenderRepaintBoundary?;
//       if (boundary == null) return;
//
//       final image = await boundary.toImage();
//       final byteData =
//           await image.toByteData(format: ui.ImageByteFormat.rawRgba);
//
//       if (byteData != null) {
//         final buffer = byteData.buffer.asUint8List();
//         _ndiHandler?.handleVideoFrame(
//           buffer,
//           image.width,
//           image.height,
//         );
//       }
//     } catch (e) {
//       dev.log('Error capturing frame: $e');
//     }
//   }
//
//   void setNDIOutputName(String name) {
//     _ndiOutputName = name;
//     if (_isStreamingNDI) {
//       stopNDIStream().then((_) => startNDIStream());
//     }
//     notifyListeners();
//   }
//
//   Future<List<NDISource>> findNDISources() async {
//     try {
//       _ndiHandler ??= NDIHandler(ndiBindings: NDIBindings());
//       await _ndiHandler!.startStream(); // Initialize NDI
//       return await _ndiHandler!.refreshSources();
//     } catch (e) {
//       dev.log('Error finding NDI sources: $e');
//       rethrow;
//     }
//   }
//
//   Future<bool> checkNDIAvailability() async {
//     try {
//       // Try to initialize NDI
//       _ndiHandler ??= NDIHandler(ndiBindings: NDIBindings());
//       await _ndiHandler!.startStream();
//       await _ndiHandler!.dispose();
//       _ndiHandler = null;
//       return true;
//     } catch (e) {
//       dev.log('Error checking NDI availability: $e');
//       return false;
//     }
//   }
//
//   Future<void> pickVideo() async {
//     try {
//       final result = await FilePicker.platform.pickFiles(
//         type: FileType.video,
//         allowMultiple: false,
//       );
//
//       if (result != null && result.files.isNotEmpty) {
//         final path = result.files.single.path;
//         if (path == null) {
//           throw Exception('Selected file path is null');
//         }
//
//         _videoFile = File(path);
//
//         // Stop any existing playback
//         await player.stop();
//
//         // Wait for player to fully stop
//         await Future.delayed(const Duration(milliseconds: 100));
//
//         // Initialize new video
//         await _initializeVideo();
//
//         notifyListeners();
//       }
//     } catch (e) {
//       dev.log('Error picking video: $e');
//       rethrow;
//     }
//   }
//
//   Future<void> _initializeVideo() async {
//     if (_videoFile == null) return;
//
//     try {
//       // // Dispose of any existing media
//       // await player.dispose();
//       //
//       // // Create a new player instance
//       // player = Player();
//       controller = VideoController(player);
//
//       // Set up duration listener
//       player.stream.duration.listen((duration) {
//         _duration = duration;
//         if (_endTrim == Duration.zero) {
//           _endTrim = duration;
//         }
//         notifyListeners();
//       });
//
//       // Open the media with explicit configuration
//       await player.open(Playlist([Media(_videoFile!.path)]));
//       await player.setPlaylistMode(PlaylistMode.loop);
//
//       // Wait for the media to be ready
//       await player.stream.width.first; // Wait for video dimensions
//       await player.stream.height.first;
//
//       // Set initial position
//       _startTrim = Duration.zero;
//       _endTrim = _duration;
//
//       // Initial seek to start
//       await player.seek(Duration.zero);
//
//       dev.log('Video initialized successfully: ${_videoFile!.path}');
//     } catch (e, stack) {
//       dev.log('Error initializing video', error: e, stackTrace: stack);
//       rethrow;
//     }
//   }
//
//   Future<void> generateVideoFromImage() async {
//     final image = await FilePicker.platform.pickFiles(
//       type: FileType.image,
//       allowMultiple: true,
//     );
//
//     if (image != null) {
//       _isProcessing = true;
//       notifyListeners();
//
//       try {
//         final directory = await getTemporaryDirectory();
//
//         final outputName =
//             'image_video_${DateTime.now().millisecondsSinceEpoch}.mp4';
//         final outputPath = path.join(directory.path, outputName);
//
//         // Format the FFmpeg command properly
//         final command = [
//           _ffmpegPath,
//           '-loop',
//           '1',
//           '-i',
//           '"${image.files.single.path}"',
//           '-c:v',
//           'libx264',
//           '-t',
//           '5',
//           '-pix_fmt',
//           'yuv420p',
//           '-vf',
//           'scale=1920:1080:force_original_aspect_ratio=decrease,pad=1920:1080:(ow-iw)/2:(oh-ih)/2',
//           '"$outputPath"'
//         ].join(' ');
//
//         final shell = Shell();
//         dev.log('Executing FFmpeg command: $command');
//
//         await shell.run(command);
//
//         // Verify the output file exists
//         if (!File(outputPath).existsSync()) {
//           throw Exception('Output file was not created');
//         }
//
//         _videoFile = File(outputPath);
//
//         final saveRoute = await FilePicker.platform
//             .saveFile(type: FileType.video, fileName: outputName);
//
//         if (saveRoute != null) _videoFile?.copy(saveRoute);
//
//         await _initializeVideo();
//       } catch (e, stack) {
//         dev.log('Error generating video: $e');
//         dev.log('Stack trace: $stack');
//         rethrow;
//       } finally {
//         _isProcessing = false;
//         notifyListeners();
//       }
//     }
//   }
//
//   String _escapePath(String path) {
//     if (Platform.isWindows) {
//       // For Windows, wrap in quotes and replace backslashes
//       return '"${path.replaceAll(r'\', '/')}"';
//     }
//     // For other platforms, just wrap in quotes
//     return '"$path"';
//   }
//
//   // Future<void> _initializeVideo() async {
//   //   if (_videoFile != null) {
//   //     await player.open(Playlist([Media(_videoFile!.path)]));
//   //     await player.setPlaylistMode(PlaylistMode.loop);
//   //     _startTrim = Duration.zero;
//   //     _endTrim = _duration;
//   //
//   //     notifyListeners();
//   //   }
//   // }
//
//   void updateSpeedFactor(double newSpeed) {
//     _speedFactor = newSpeed;
//     player.setRate(newSpeed);
//     notifyListeners();
//   }
//
//   void updateTrimPoints(Duration start, Duration end) {
//     _startTrim = start;
//     _endTrim = end;
//     player.seek(start);
//     notifyListeners();
//   }
//
//   void toggleTrimming() {
//     _isTrimming = !_isTrimming;
//     notifyListeners();
//   }
//
//   Future<void> processVideo({bool trimOnly = false}) async {
//     if (_videoFile == null) return;
//
//     _isProcessing = true;
//     notifyListeners();
//
//     try {
//       final directory = await getTemporaryDirectory();
//       final outputPath = path.join(directory.path,
//           'output_${DateTime.now().millisecondsSinceEpoch}.mp4');
//
// // Build FFmpeg command
//       var command = '$_ffmpegPath -i "${_videoFile!.path}"';
//
// // Add trim filter if trimming
//       if (_startTrim != Duration.zero || _endTrim != _duration) {
//         command +=
//             ' -ss ${_startTrim.inSeconds} -t ${(_endTrim - _startTrim).inSeconds}';
//       }
//
// // Add speed filter if not trim-only mode
//       if (!trimOnly && _speedFactor != 1.0) {
//         final setpts = _speedFactor > 1
//             ? '${1 / _speedFactor}*PTS'
//             : '${_speedFactor}*PTS';
//         command +=
//             ' -filter:v "setpts=$setpts" -filter:a "atempo=${_speedFactor}"';
//       }
//
//       command += ' -c:v libx264 -c:a aac "$outputPath"';
//
//       final shell = Shell();
//       await shell.run(command);
//
//       _videoFile = File(outputPath);
//       await _initializeVideo();
//     } catch (e) {
//       dev.log('Error processing video: $e');
//       rethrow;
//     } finally {
//       _isProcessing = false;
//       notifyListeners();
//     }
//   }
//
//   Future<void> extractAudio() async {
//     if (_videoFile == null) return;
//
//     _isProcessing = true;
//     notifyListeners();
//
//     try {
//       final directory = await getTemporaryDirectory();
//       final outputPath = path.join(
//           directory.path, 'audio_${DateTime.now().millisecondsSinceEpoch}.mp3');
//
//       final shell = Shell();
//       await shell.run(
//           '$_ffmpegPath -i "${_videoFile!.path}" -q:a 0 -map a "$outputPath"');
//
// // You can handle the extracted audio file here
//       dev.log('Audio extracted to: $outputPath');
//     } catch (e) {
//       dev.log('Error extracting audio: $e');
//       rethrow;
//     } finally {
//       _isProcessing = false;
//       notifyListeners();
//     }
//   }
//
//   Future<void> exportVideo(BuildContext? context) async {
//     if (_videoFile == null) {
//       throw Exception('No video to export');
//     }
//
//     try {
//       _isProcessing = true;
//       notifyListeners();
//
//       // Ask user to select save location
//       String? selectedPath = await FilePicker.platform.saveFile(
//         dialogTitle: 'Save Video As',
//         fileName: 'exported_video_${DateTime.now().millisecondsSinceEpoch}.mp4',
//         type: FileType.video,
//         allowedExtensions: ['mp4'],
//       );
//
//       if (selectedPath != null) {
//         if (!selectedPath.toLowerCase().endsWith('.mp4')) {
//           selectedPath = '$selectedPath.mp4';
//         }
//
//         final shell = Shell();
//         final command = '''
//         $_ffmpegPath -i "${_videoFile!.path}" -c:v libx264 -c:a aac -y "${selectedPath.replaceAll(r'\', '/')}"
//       ''';
//
//         dev.log('Executing command: $command'); // Debug log
//         await shell.run(command);
//
//         if (context != null && context.mounted) {
//           ScaffoldMessenger.of(context).showSnackBar(
//             const SnackBar(content: Text('Video exported successfully!')),
//           );
//         }
//       }
//     } catch (e) {
//       dev.log('Error exporting video: $e');
//       if (context != null && context.mounted) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(
//             content: Text('Export failed: $e'),
//             backgroundColor: Colors.red,
//           ),
//         );
//       }
//       rethrow;
//     } finally {
//       _isProcessing = false;
//       notifyListeners();
//     }
//   }
//
//   Future<void> exportVideoWithSettings({
//     BuildContext? context,
//     String preset = 'medium',
//     String crf = '23',
//     String? resolution,
//     String? bitrate,
//   }) async {
//     if (_videoFile == null) {
//       throw Exception('No video to export');
//     }
//
//     try {
//       _isProcessing = true;
//       notifyListeners();
//
//       String? selectedPath = await FilePicker.platform.saveFile(
//         dialogTitle: 'Save Video As',
//         fileName: 'exported_video_${DateTime.now().millisecondsSinceEpoch}.mp4',
//         type: FileType.video,
//         allowedExtensions: ['mp4'],
//       );
//
//       if (selectedPath != null) {
//         if (!selectedPath.toLowerCase().endsWith('.mp4')) {
//           selectedPath = '$selectedPath.mp4';
//         }
//
//         // Convert Windows path separators to forward slashes
//         selectedPath = selectedPath.replaceAll(r'\', '/');
//
//         final List<String> filters = [];
//         if (resolution != null) {
//           filters.add('scale=$resolution');
//         }
//
//         final filterString =
//             filters.isNotEmpty ? '-vf "${filters.join(',')}"' : '';
//         final bitrateString = bitrate != null ? '-b:v $bitrate' : '';
//
//         final shell = Shell();
//         final command = '''
//         $_ffmpegPath -i "${_videoFile!.path}"
//         -c:v libx264
//         -preset $preset
//         -crf $crf
//         $filterString
//         $bitrateString
//         -c:a aac
//         -y "$selectedPath"
//       ''';
//
//         dev.log('Executing command: $command'); // Debug log
//         await shell.run(command);
//
//         if (context != null && context.mounted) {
//           ScaffoldMessenger.of(context).showSnackBar(
//             const SnackBar(content: Text('Video exported successfully!')),
//           );
//         }
//       }
//     } catch (e) {
//       dev.log('Error exporting video: $e');
//       if (context != null && context.mounted) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(
//             content: Text('Export failed: $e'),
//             backgroundColor: Colors.red,
//           ),
//         );
//       }
//       rethrow;
//     } finally {
//       _isProcessing = false;
//       notifyListeners();
//     }
//   }
//
// // Optional: Add a convenience method for common export presets
//   Future<void> exportVideoPreset(String preset) async {
//     switch (preset.toLowerCase()) {
//       case 'web':
//         await exportVideoWithSettings(
//             preset: 'fast', crf: '23', resolution: '1280x720', bitrate: '2M');
//         break;
//       case 'hd':
//         await exportVideoWithSettings(
//             preset: 'medium',
//             crf: '20',
//             resolution: '1920x1080',
//             bitrate: '5M');
//         break;
//       case '4k':
//         await exportVideoWithSettings(
//             preset: 'slow', crf: '18', resolution: '3840x2160', bitrate: '20M');
//         break;
//       default:
//         await exportVideo(null);
//     }
//   }
//
// // Helper method to check if an export would overwrite an existing file
//   Future<bool> checkFileExists(String path) async {
//     return await File(path).exists();
//   }
//
// // Helper method to format file size
//   String formatFileSize(int bytes) {
//     if (bytes <= 0) return "0 B";
//     const suffixes = ["B", "KB", "MB", "GB", "TB"];
//     var i = (log(bytes) / log(1024)).floor();
//     return '${(bytes / pow(1024, i)).toStringAsFixed(2)} ${suffixes[i]}';
//   }
//
//   Future<void> addWatermark(String watermarkPath,
//       {String position =
//           'center' // 'center', 'topleft', 'topright', 'bottomleft', 'bottomright'
//       }) async {
//     if (_videoFile == null) return;
//
//     _isProcessing = true;
//     notifyListeners();
//
//     try {
//       final directory = await getTemporaryDirectory();
//       final outputPath = path.join(directory.path,
//           'watermarked_${DateTime.now().millisecondsSinceEpoch}.mp4');
//
// // Define overlay position
//       String overlayPos;
//       switch (position) {
//         case 'topleft':
//           overlayPos = '10:10';
//           break;
//         case 'topright':
//           overlayPos = 'main_w-overlay_w-10:10';
//           break;
//         case 'bottomleft':
//           overlayPos = '10:main_h-overlay_h-10';
//           break;
//         case 'bottomright':
//           overlayPos = 'main_w-overlay_w-10:main_h-overlay_h-10';
//           break;
//         default: // center
//           overlayPos = '(main_w-overlay_w)/2:(main_h-overlay_h)/2';
//       }
//
//       final shell = Shell();
//       await shell.run('''
//         $_ffmpegPath -i "${_videoFile!.path}" -i "$watermarkPath"
//         -filter_complex "overlay=$overlayPos"
//         -codec:a copy "$outputPath"
//       ''');
//
//       _videoFile = File(outputPath);
//       await _initializeVideo();
//     } catch (e) {
//       dev.log('Error adding watermark: $e');
//       rethrow;
//     } finally {
//       _isProcessing = false;
//       notifyListeners();
//     }
//   }
//
//   void togglePlayPause() {
//     if (player.state.playing) {
//       player.pause();
//     } else {
//       player.play();
//     }
//     notifyListeners();
//   }
//
//   void replay() {
//     player.seek(Duration.zero);
//     notifyListeners();
//   }
// }
