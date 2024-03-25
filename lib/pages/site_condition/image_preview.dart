import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class ImagePreview extends StatefulWidget {
  const ImagePreview({required this.file, super.key});

  final XFile file;

  @override
  State<ImagePreview> createState() => _ImagePreviewState();
}

class _ImagePreviewState extends State<ImagePreview> {
  @override
  Widget build(BuildContext context) {
    File picture = File(widget.file.path);

    return Scaffold(
      body: Center(
        child: Image.file(picture),
      ),
    );
  }
}
