// // lib/pages/video_editor_page.dart
//
// import 'package:flutter/material.dart';
// import 'package:untitled/pages/video_editor/ndi_output.dart';
// import 'package:untitled/pages/video_editor/video_editor_controller.dart';
//
// class VideoEditorPage extends StatefulWidget {
//   const VideoEditorPage({Key? key}) : super(key: key);
//
//   @override
//   State<VideoEditorPage> createState() => _VideoEditorPageState();
// }
//
// class _VideoEditorPageState extends State<VideoEditorPage> {
//   final VideoEditorController _controller = VideoEditorController();
//
//   @override
//   void dispose() {
//     _controller.dispose();
//     super.dispose();
//   }
//
//   void showExportDialog(BuildContext context) {
//     String preset = 'medium';
//     String crf = '23';
//     String? resolution;
//     String? bitrate;
//
//     showDialog(
//       context: context,
//       builder: (dialogContext) => AlertDialog(
//         title: const Text('Export Settings'),
//         content: Column(
//           mainAxisSize: MainAxisSize.min,
//           children: [
//             DropdownButtonFormField<String>(
//               value: preset,
//               decoration: const InputDecoration(labelText: 'Preset'),
//               items: [
//                 'ultrafast',
//                 'superfast',
//                 'veryfast',
//                 'faster',
//                 'fast',
//                 'medium',
//                 'slow',
//                 'slower',
//                 'veryslow'
//               ].map((String value) {
//                 return DropdownMenuItem<String>(
//                   value: value,
//                   child: Text(value),
//                 );
//               }).toList(),
//               onChanged: (value) => preset = value!,
//             ),
//             Slider(
//               value: double.parse(crf),
//               min: 0,
//               max: 51,
//               divisions: 51,
//               label: crf,
//               onChanged: (value) => crf = value.round().toString(),
//             ),
//             TextField(
//               decoration: const InputDecoration(
//                 labelText: 'Resolution (e.g., 1920x1080)',
//                 hintText: 'Optional',
//               ),
//               onChanged: (value) => resolution = value.isEmpty ? null : value,
//             ),
//             TextField(
//               decoration: const InputDecoration(
//                 labelText: 'Bitrate (e.g., 2M)',
//                 hintText: 'Optional',
//               ),
//               onChanged: (value) => bitrate = value.isEmpty ? null : value,
//             ),
//           ],
//         ),
//         actions: [
//           TextButton(
//             onPressed: () => Navigator.pop(dialogContext),
//             child: const Text('Cancel'),
//           ),
//           ElevatedButton(
//             onPressed: () async {
//               Navigator.pop(dialogContext);
//               try {
//                 // await _controller.exportVideoWithSettings(
//                 //   preset: preset,
//                 //   crf: crf,
//                 //   resolution: resolution,
//                 //   bitrate: bitrate,
//                 // );
//
//                 await _controller.exportVideo(context);
//                 ScaffoldMessenger.of(context).showSnackBar(
//                   const SnackBar(content: Text('Video exported successfully!')),
//                 );
//               } catch (e) {
//                 ScaffoldMessenger.of(context).showSnackBar(
//                   SnackBar(
//                     content: Text('Export failed: $e'),
//                     backgroundColor: Colors.red,
//                   ),
//                 );
//               }
//             },
//             child: const Text('Export'),
//           ),
//         ],
//       ),
//     );
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text('Video Editor'),
//         actions: [
//           ListenableBuilder(
//             listenable: _controller,
//             builder: (context, child) {
//               return IconButton(
//                 icon: Icon(_controller.isTrimming ? Icons.done : Icons.cut),
//                 onPressed:
//                     _controller.hasVideo ? _controller.toggleTrimming : null,
//               );
//             },
//           ),
//         ],
//       ),
//       body: SingleChildScrollView(
//         child: Column(
//           children: [
//             // Video Preview
//             ListenableBuilder(
//               listenable: _controller,
//               builder: (context, child) {
//                 return AspectRatio(
//                   aspectRatio: 16 / 9,
//                   child: _controller.hasVideo &&
//                           _controller.videoController != null
//                       ? NDIVideoPlayer(controller: _controller)
//                       // Video(controller: _controller.videoController)
//                       : Container(
//                           color: Colors.grey[300],
//                           child: const Center(
//                             child: Text('No video selected'),
//                           ),
//                         ),
//                 );
//               },
//             ),
//
//             // Trim Slider
//             ListenableBuilder(
//               listenable: _controller,
//               builder: (context, child) {
//                 if (!_controller.isTrimming || !_controller.hasVideo) {
//                   return const SizedBox.shrink();
//                 }
//
//                 return Container(
//                   height: 100,
//                   padding: const EdgeInsets.symmetric(horizontal: 16),
//                   child: Column(
//                     children: [
//                       const Text('Trim Video'),
//                       RangeSlider(
//                         values: RangeValues(
//                           _controller.startTrim.inMilliseconds.toDouble(),
//                           _controller.endTrim.inMilliseconds.toDouble(),
//                         ),
//                         min: 0,
//                         max: _controller.duration.inMilliseconds.toDouble(),
//                         onChanged: (RangeValues values) {
//                           _controller.updateTrimPoints(
//                             Duration(milliseconds: values.start.round()),
//                             Duration(milliseconds: values.end.round()),
//                           );
//                         },
//                       ),
//                       Row(
//                         mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                         children: [
//                           Text(_controller.startTrim
//                               .toString()
//                               .split('.')
//                               .first),
//                           Text(_controller.endTrim.toString().split('.').first),
//                         ],
//                       ),
//                     ],
//                   ),
//                 );
//               },
//             ),
//
//             // Playback Controls
//             ListenableBuilder(
//               listenable: _controller,
//               builder: (context, child) {
//                 return Row(
//                   mainAxisAlignment: MainAxisAlignment.spaceEvenly,
//                   children: [
//                     IconButton(
//                       icon: const Icon(Icons.play_arrow),
//                       onPressed: _controller.hasVideo
//                           ? _controller.togglePlayPause
//                           : null,
//                     ),
//                     IconButton(
//                       icon: const Icon(Icons.replay),
//                       onPressed:
//                           _controller.hasVideo ? _controller.replay : null,
//                     ),
//                   ],
//                 );
//               },
//             ),
//
//             // Speed Control
//             if (!_controller.isTrimming) ...[
//               Padding(
//                 padding: const EdgeInsets.symmetric(horizontal: 20),
//                 child: ListenableBuilder(
//                   listenable: _controller,
//                   builder: (context, child) {
//                     return Row(
//                       children: [
//                         const Text('Speed: '),
//                         Expanded(
//                           child: Slider(
//                             value: _controller.speedFactor,
//                             min: 0.25,
//                             max: 4.0,
//                             divisions: 15,
//                             label: '${_controller.speedFactor}x',
//                             onChanged: _controller.updateSpeedFactor,
//                           ),
//                         ),
//                         Text('${_controller.speedFactor}x'),
//                       ],
//                     );
//                   },
//                 ),
//               ),
//             ],
//
//             // Action Buttons
//             Padding(
//               padding: const EdgeInsets.all(16.0),
//               child: ListenableBuilder(
//                 listenable: _controller,
//                 builder: (context, child) {
//                   return Column(
//                     children: [
//                       ElevatedButton(
//                         onPressed: _controller.isProcessing
//                             ? null
//                             : _controller.pickVideo,
//                         child: const Text('Pick Video'),
//                       ),
//                       const SizedBox(height: 8),
//                       ElevatedButton(
//                         onPressed: _controller.isProcessing
//                             ? null
//                             : _controller.generateVideoFromImage,
//                         child: const Text('Generate from Image'),
//                       ),
//                       const SizedBox(height: 8),
//                       if (_controller.hasVideo)
//                         ElevatedButton(
//                           onPressed: _controller.isProcessing
//                               ? null
//                               : () => _controller.processVideo(
//                                     trimOnly: _controller.isTrimming,
//                                   ),
//                           child: _controller.isProcessing
//                               ? const CircularProgressIndicator()
//                               : Text(_controller.isTrimming
//                                   ? 'Trim Video'
//                                   : 'Process Video'),
//                         ),
//                     ],
//                   );
//                 },
//               ),
//             ),
//
//             NDIControls(controller: _controller),
//           ],
//         ),
//       ),
//       floatingActionButton: FloatingActionButton(
//           child: Icon(Icons.save),
//           onPressed: _controller.hasVideo && !_controller.isProcessing
//               ? () => showExportDialog(context)
//               : () {}),
//     );
//   }
// }
