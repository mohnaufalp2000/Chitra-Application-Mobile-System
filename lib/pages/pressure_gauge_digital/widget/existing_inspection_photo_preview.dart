import 'package:flutter/material.dart';

/// Preview foto inspeksi yang sudah tersimpan di Firebase Storage.
/// Widget ini hanya menampilkan foto; penggantian foto tetap dilakukan
/// melalui tombol Take Picture yang sudah ada di form.
class ExistingInspectionPhotoPreview extends StatelessWidget {
  const ExistingInspectionPhotoPreview({
    super.key,
    required this.imageUrl,
  });

  final String imageUrl;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Padding(
          padding: EdgeInsets.only(bottom: 8),
          child: Text(
            'Foto sudah tersimpan',
            style: TextStyle(fontSize: 12, color: Colors.green),
          ),
        ),
        ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: SizedBox(
            height: 240,
            child: Image.network(
              imageUrl,
              fit: BoxFit.contain,
              loadingBuilder: (context, child, loadingProgress) {
                if (loadingProgress == null) return child;
                return const Center(child: CircularProgressIndicator());
              },
              errorBuilder: (context, error, stackTrace) => const Center(
                child: Tooltip(
                  message: 'Foto tersimpan di server',
                  child: Icon(
                    Icons.cloud_done,
                    size: 48,
                    color: Colors.green,
                  ),
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
