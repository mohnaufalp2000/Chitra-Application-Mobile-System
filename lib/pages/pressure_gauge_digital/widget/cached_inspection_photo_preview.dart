import 'dart:io';

import 'package:flutter/material.dart';

/// Preview foto lokal yang dipertahankan setelah upload berhasil.
class CachedInspectionPhotoPreview extends StatelessWidget {
  const CachedInspectionPhotoPreview({
    super.key,
    required this.filePath,
  });

  final String filePath;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Padding(
          padding: EdgeInsets.only(bottom: 8),
          child: Text(
            'Foto tersimpan di perangkat',
            style: TextStyle(fontSize: 12, color: Colors.green),
          ),
        ),
        ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: SizedBox(
            height: 240,
            child: Image(
              image: ResizeImage(
                FileImage(File(filePath)),
                width: 720,
                height: 720,
                policy: ResizeImagePolicy.fit,
              ),
              fit: BoxFit.contain,
              errorBuilder: (context, error, stackTrace) => const Center(
                child: Icon(Icons.cloud_done, size: 48, color: Colors.green),
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
      ],
    );
  }
}
