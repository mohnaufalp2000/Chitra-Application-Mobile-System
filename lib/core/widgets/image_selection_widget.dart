import '../styles/text_manager.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class ImageSelection extends StatelessWidget {
  final Function(ImageSource) onImageSourceSelected;

  ImageSelection({required this.onImageSourceSelected});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 130,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: Icon(Icons.photo_library),
            title: Text(
              'Pilih Gambar dari Galeri',
              style: getBlackTextStyle(),
            ),
            onTap: () {
              onImageSourceSelected(ImageSource.gallery);
              Navigator.pop(context);
            },
          ),
          ListTile(
            leading: Icon(Icons.camera_alt),
            title: Text(
              'Ambil Gambar dari Kamera',
              style: getBlackTextStyle(),
            ),
            onTap: () {
              onImageSourceSelected(ImageSource.camera);
              Navigator.pop(context);
            },
          ),
        ],
      ),
    );
  }
}
