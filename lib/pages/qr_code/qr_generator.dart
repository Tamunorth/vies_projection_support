import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:screenshot/screenshot.dart';
import 'package:vies_projection_support/core/analytics.dart';
import 'package:vies_projection_support/pages/home_page.dart';
import 'package:vies_projection_support/shared/button_widget.dart';

class QrGenerator extends StatefulWidget {
  const QrGenerator({super.key});

  static final pageId = 'qr_generator_page';

  @override
  State<QrGenerator> createState() => _QrGeneratorState();
}

class _QrGeneratorState extends State<QrGenerator> {
  final _textCtrl = TextEditingController();

  ScreenshotController screenshotController = ScreenshotController();

  void captureQR() {
    screenshotController
        .captureFromWidget(
      delay: Duration(milliseconds: 400),
      CustomQR(
        textCtrl: _textCtrl,
        size: 1000,
      ),
      targetSize: Size(1000, 1000),
    )
        .then((capturedImage) async {
      if (capturedImage != null) {
        String? outputFile = await FilePicker.platform.saveFile(
          dialogTitle: 'Please select an output file:',
          fileName: 'qr_code_${DateTime.now().millisecondsSinceEpoch}',
        );
        final file = File('$outputFile.png');
        file.writeAsBytesSync(capturedImage);

        Analytics.instance.trackEventWithProperties(
          "qr_code_exported",
          {
            'file_path': outputFile.toString(),
          },
        );

        // final newImage = await file.copy('$outputFile.png');
      }
      // Handle captured image
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(20.0),
            child: TextField(
              autofocus: true,
              textAlignVertical: TextAlignVertical.center,
              textAlign: TextAlign.center,
              controller: _textCtrl,
              decoration: InputDecoration(
                hintText: 'Enter text here to generate QR code',
              ),
              onChanged: (val) async {
                setState(() {});
              },
            ),
          ),
          SizedBox(
            height: 20,
          ),
          CustomQR(
            textCtrl: _textCtrl,
            size: 200,
          ),
          ButtonWidget(
            title: 'Export',
            onTap: () async {
              captureQR();
            },
          ),
        ],
      ),
    );
  }
}

class CustomQR extends StatelessWidget {
  const CustomQR({
    super.key,
    required TextEditingController textCtrl,
    required this.size,
  }) : _textCtrl = textCtrl;

  final TextEditingController _textCtrl;
  final double size;

  @override
  Widget build(BuildContext context) {
    return QrImageView(
      data: _textCtrl.text,
      version: QrVersions.auto,
      foregroundColor: Colors.white,
      size: size,
      dataModuleStyle: const QrDataModuleStyle(
          dataModuleShape: QrDataModuleShape.circle, color: Colors.black),
      eyeStyle:
          const QrEyeStyle(eyeShape: QrEyeShape.square, color: Colors.black),
    );
  }
}
