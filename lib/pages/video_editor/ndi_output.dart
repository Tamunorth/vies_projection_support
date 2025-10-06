// import 'package:flutter/material.dart';
// import 'package:media_kit_video/media_kit_video.dart';
// import 'package:untitled/pages/video_editor/video_editor_controller.dart';
//
// class NDIControls extends StatelessWidget {
//   final VideoEditorController controller;
//
//   const NDIControls({
//     Key? key,
//     required this.controller,
//   }) : super(key: key);
//
//   @override
//   Widget build(BuildContext context) {
//     return ListenableBuilder(
//       listenable: controller,
//       builder: (context, _) {
//         return Column(
//           mainAxisSize: MainAxisSize.min,
//           children: [
// // NDI Stream Control Button
//             ElevatedButton.icon(
//               onPressed: controller.hasVideo
//                   ? () async {
//                       try {
//                         if (controller.isStreamingNDI) {
//                           await controller.stopNDIStream();
//                           ScaffoldMessenger.of(context).showSnackBar(
//                             const SnackBar(content: Text('NDI stream stopped')),
//                           );
//                         } else {
//                           await controller.startNDIStream();
//                           ScaffoldMessenger.of(context).showSnackBar(
//                             const SnackBar(content: Text('NDI stream started')),
//                           );
//                         }
//                       } catch (e) {
//                         ScaffoldMessenger.of(context).showSnackBar(
//                           SnackBar(
//                             content: Text('NDI stream error: $e'),
//                             backgroundColor: Colors.red,
//                           ),
//                         );
//                       }
//                     }
//                   : null,
//               icon: Icon(
//                 controller.isStreamingNDI ? Icons.stop : Icons.play_arrow,
//               ),
//               label: Text(
//                 controller.isStreamingNDI ? 'Stop NDI' : 'Start NDI',
//               ),
//               style: ElevatedButton.styleFrom(
//                 backgroundColor: controller.isStreamingNDI
//                     ? Colors.red
//                     : Theme.of(context).primaryColor,
//               ),
//             ),
//
// // NDI Settings Button
//             Row(
//               children: [
//                 IconButton(
//                   icon: const Icon(Icons.settings),
//                   onPressed: () {
//                     showDialog(
//                       context: context,
//                       builder: (context) => NDISettingsDialog(
//                         controller: controller,
//                       ),
//                     );
//                   },
//                 ),
//                 IconButton(
//                   icon: const Icon(Icons.source),
//                   onPressed: () async {
//                     await controller.findNDISources();
//                   },
//                 ),
//               ],
//             ),
//           ],
//         );
//       },
//     );
//   }
// }
//
// class NDISettingsDialog extends StatefulWidget {
//   final VideoEditorController controller;
//
//   const NDISettingsDialog({
//     Key? key,
//     required this.controller,
//   }) : super(key: key);
//
//   @override
//   State<NDISettingsDialog> createState() => _NDISettingsDialogState();
// }
//
// class _NDISettingsDialogState extends State<NDISettingsDialog> {
//   late TextEditingController _nameController;
//
//   @override
//   void initState() {
//     super.initState();
//     _nameController = TextEditingController(text: 'VideoEditor');
//   }
//
//   @override
//   void dispose() {
//     _nameController.dispose();
//     super.dispose();
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return AlertDialog(
//       title: const Text('NDI Settings'),
//       content: Column(
//         mainAxisSize: MainAxisSize.min,
//         children: [
//           TextField(
//             controller: _nameController,
//             decoration: const InputDecoration(
//               labelText: 'NDI Output Name',
//               hintText: 'Enter NDI output name',
//             ),
//           ),
//         ],
//       ),
//       actions: [
//         TextButton(
//           onPressed: () => Navigator.pop(context),
//           child: const Text('Cancel'),
//         ),
//         ElevatedButton(
//           onPressed: () {
//             // widget.controller.setNDIOutputName(_nameController.text);
//             Navigator.pop(context);
//           },
//           child: const Text('Apply'),
//         ),
//       ],
//     );
//   }
// }
//
// class NDIVideoPlayer extends StatelessWidget {
//   final VideoEditorController controller;
//
//   const NDIVideoPlayer({
//     Key? key,
//     required this.controller,
//   }) : super(key: key);
//
//   @override
//   Widget build(BuildContext context) {
//     return RepaintBoundary(
//       key: controller.repaintBoundaryKey,
//       child: (controller.videoController != null)
//           ? Video(
//               controller: controller.videoController!,
//             )
//           : SizedBox(),
//     );
//   }
// }
