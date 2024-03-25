// ignore_for_file: public_member_api_docs, sort_constructors_first

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import 'package:camos/core/styles/asset_path.dart';
import 'package:camos/core/styles/color.dart';

class UploadPhotoWidget extends StatelessWidget {
  const UploadPhotoWidget({
    Key? key,
    required this.function,
    this.image,
  }) : super(key: key);

  final Image? image;
  final VoidCallback function;

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.bottomCenter,
      clipBehavior: Clip.none,
      children: [
        Container(
          width: 180,
          height: 180,
          decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: grey6A707C,
                width: 5.0,
                strokeAlign: BorderSide.strokeAlignOutside,
              )),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(100.0),
            child: (image != null)
                ? image
                : Icon(
                    Icons.person,
                    color: grey6A707C,
                    size: 128,
                  ),
          ),
        ),
        Positioned(
          bottom: -5,
          right: 5,
          child: InkWell(
            onTap: function,
            child: SizedBox(
              width: 50,
              height: 50,
              child: Image(
                image: AssetImage('${iconPath}/add_color_icon.png'),
              ),
            ),
          ),
        )
      ],
    );
  }
}
