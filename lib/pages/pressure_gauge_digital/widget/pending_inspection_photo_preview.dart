import 'dart:io';

import 'package:flutter/material.dart';

/// Preview lokal saja, bukan foto baru yang akan dimasukkan ke antrean upload.
class PendingInspectionPhotoPreview extends StatelessWidget {
  const PendingInspectionPhotoPreview({super.key, required this.filePath});

  final String filePath;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Padding(
          padding: EdgeInsets.only(bottom: 8),
          child: Text(
            'Foto tersimpan di perangkat • Menunggu upload',
            style: TextStyle(fontSize: 12, color: Colors.orange),
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
                child: Text(
                  'Foto lokal tidak tersedia. Silakan ambil foto ulang.',
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
      ],
    );
  }
}
