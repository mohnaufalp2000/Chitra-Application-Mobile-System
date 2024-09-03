import 'dart:convert';
import 'dart:developer';
import 'dart:io';
import 'dart:typed_data';

import 'package:camos/core/services/local_database/tire_inspect_picture/tire_inspect_picture_entity.dart';
import 'package:camos/core/services/model/unit_tire.dart';
import 'package:camos/core/styles/asset_path.dart';
import 'package:camos/core/styles/color.dart';
import 'package:camos/core/styles/text_manager.dart';
import 'package:camos/core/utils/functions/functions.dart';
import 'package:camos/core/widgets/button_widget.dart';
import 'package:camos/core/widgets/input_form_widget.dart';
import 'package:camos/main.dart';
import 'package:camos/objectbox.g.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:lecle_downloads_path_provider/lecle_downloads_path_provider.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:uuid/uuid.dart';

class PgdTireCardWidget extends StatefulWidget {
  PgdTireCardWidget(
      {required this.onSelectedTireDamage,
      required this.onCategoryChecked,
      required this.onStringRemarks,
      required this.onStringRTD,
      required this.onImageTire,
      required this.dataTire,
      super.key});

  UnitTire dataTire;
  final Function(List<bool>) onCategoryChecked;
  final Function(String) onSelectedTireDamage;
  final Function(String) onStringRemarks;
  final Function(String) onStringRTD;
  final Function(List<String>) onImageTire;

  @override
  State<PgdTireCardWidget> createState() => _PgdTireCardWidgetState();
}

class _PgdTireCardWidgetState extends State<PgdTireCardWidget> {
  TextEditingController pressureCtrl = TextEditingController(text: '');
  TextEditingController remarksCtrl = TextEditingController(text: '');
  TextEditingController rtdCtrl = TextEditingController(text: '');
  final CarouselController _controller = CarouselController();

  int _current = 0;

  List<String> listImageString = [];
  List<File> listImg = [];

  void cameraPicture(BuildContext context) async {
    final ImagePicker picker = ImagePicker();
    final XFile? image =
        await picker.pickImage(imageQuality: 50, source: ImageSource.camera);

    if (image != null) {
      Uint8List bytes = await image.readAsBytes();
      // String imgString = base64Encode(bytes);

      // // untuk disimpan di excel
      // listImageString.add(imgString);
      // widget.onImageTire(listImageString)

      // untuk disimpan di excel
      if (Platform.isAndroid) {
        final id = Uuid();
        final file = await createFolderPath(id.v4(), 'outstanding-image');

        final saved = await file.writeAsBytes(bytes, flush: true);
        listImageString.add(saved.path);
        widget.onImageTire(listImageString);
      }

      if (Platform.isIOS) {
        Uint8List bytes = await image.readAsBytes();
        String imgString = base64Encode(bytes);

        listImageString.add(imgString);
        widget.onImageTire(listImageString);
      }
      // final id = Uuid().v4();
      // final file = await createFolderPath(id, 'outstanding-image');

      // final saved = await file.writeAsBytes(bytes, flush: true);
      // print('gambar tersimpan : $saved');

      // untuk preview
      listImg.add(File(image.path));
    }
  }

  List<String> categories = [
    'Reseal Oring',
    'Rim Condition',
    'Inflate Tire',
    'Lock Driver',
    'Slide Lock',
    'Valve Cap',
    'Valve Protector',
    'Stud and Nut',
  ];

  List<String> damageType = [
    'Good Condition',
    'Accident',
    'Bead Crack',
    'Boulder',
    'Bulging',
    'Bead Damage',
    'Chaffer Separation',
    'Dog Bound',
    'Foreign Object',
    'Heat Separation',
    'Inner Linner Separation',
    'Impact',
    'Repair Failure',
    'Radial Crack',
    'Run Flat',
    'Sidewall Crack',
    'Sidewall Cut',
    'Sidewall Cut 2',
    'Sidewall Cut 3',
    'Sidewall Separation',
    'Shoulder Cut',
    'Shoulder Separation',
    'Tread Chipping',
    'Tread Chungking',
    'Tread Lifting',
    'Tread Cut',
    'Tread Cut Separation',
    'Worn Out',
  ];

  String selectedTireDamage = '';

  List<bool> checkedListCategory = List<bool>.filled(8, false);

  @override
  void initState() {
    super.initState();
    widget.onSelectedTireDamage(damageType[0]);
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      child: Container(
        width: MediaQuery.of(context).size.width,
        padding: EdgeInsets.all(12),
        child: Column(
          children: [
            SizedBox(
              width: 40,
              height: 58,
              child: Image.asset(
                '$imagePath/em_tire_image.png',
                fit: BoxFit.cover,
              ),
            ),
            const SizedBox(
              height: 12,
            ),
            Column(
              children: [
                Text(
                  'Position',
                  style: getBlackTextStyle(fontWeight: w700),
                ),
                const SizedBox(
                  height: 4,
                ),
                Text(
                  '#${widget.dataTire.posisi}',
                  style: getBlackTextStyle(),
                ),
              ],
            ),
            Padding(
              padding: EdgeInsets.symmetric(vertical: 6),
              child: Divider(
                thickness: 1.5,
              ),
            ),
            Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'SN',
                      style: getBlackTextStyle(fontWeight: w700),
                    ),
                    Text(
                      widget.dataTire.sn ?? '',
                      style: getBlackTextStyle(),
                    ),
                  ],
                ),
                const SizedBox(
                  height: 12,
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Brand',
                      style: getBlackTextStyle(fontWeight: w700),
                    ),
                    Text(
                      widget.dataTire.brand ?? '',
                      style: getBlackTextStyle(),
                    ),
                  ],
                ),
                const SizedBox(
                  height: 12,
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Unit Number',
                      style: getBlackTextStyle(fontWeight: w700),
                    ),
                    Text(
                      widget.dataTire.unitNumber ?? '',
                      style: getBlackTextStyle(),
                    ),
                  ],
                ),
                const SizedBox(
                  height: 12,
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Tire Lifetime',
                      style: getBlackTextStyle(fontWeight: w700),
                    ),
                    Text(
                      widget.dataTire.lifetime ?? '',
                      style: getBlackTextStyle(),
                    ),
                  ],
                ),
                // Row(
                //   mainAxisAlignment: MainAxisAlignment.spaceBetween,
                //   children: [
                //     Text(
                //       'Tyre Life Distance',
                //       style: getBlackTextStyle(fontWeight: w700),
                //     ),
                //     Text(
                //       '355550.0',
                //       style: getBlackTextStyle(),
                //     ),
                //   ],
                // ),
                const SizedBox(
                  height: 12,
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Component',
                      style: getBlackTextStyle(fontWeight: w700),
                    ),
                    Text(
                      'Tire',
                      style: getBlackTextStyle(),
                    ),
                  ],
                ),
                const SizedBox(
                  height: 12,
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Rating',
                      style: getBlackTextStyle(fontWeight: w700),
                    ),
                    Text(
                      widget.dataTire.rating ?? '',
                      style: getBlackTextStyle(),
                    ),
                  ],
                ),
              ],
            ),
            Padding(
              padding: EdgeInsets.symmetric(vertical: 6),
              child: Divider(
                thickness: 1.5,
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Tire Damage',
                  style: getBlackTextStyle(fontWeight: w700),
                ),
                const SizedBox(
                  height: 6,
                ),
                SizedBox(
                  width: double.infinity,
                  child: DropdownButtonFormField(
                    decoration: InputDecoration(
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(color: greyDADADA),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: black),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: black),
                      ),
                      contentPadding:
                          EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                    ),
                    isDense: true,
                    style: getBlackTextStyle(),
                    value: (selectedTireDamage == '')
                        ? damageType[0]
                        : selectedTireDamage,
                    items: damageType.map((damage) {
                      return DropdownMenuItem<String>(
                        child: Text(
                          damage,
                          style: getBlackTextStyle(fontSize: 10),
                        ),
                        value: damage,
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        selectedTireDamage = value ?? '';
                      });
                      widget.onSelectedTireDamage(selectedTireDamage);
                    },
                  ),
                ),
                const SizedBox(
                  height: 12,
                ),
                Text(
                  'RTD (Optional)',
                  style: getBlackTextStyle(fontWeight: w700),
                ),
                const SizedBox(
                  height: 6,
                ),
                SizedBox(
                  width: double.infinity,
                  child: InputFormWidget(
                      height: 45,
                      controller: rtdCtrl,
                      onChng: (value) {
                        widget.onStringRTD(value);
                      },
                      hint: ''),
                ),
                const SizedBox(
                  height: 12,
                ),
                Text(
                  'Remarks (Optional)',
                  style: getBlackTextStyle(fontWeight: w700),
                ),
                const SizedBox(
                  height: 6,
                ),
                SizedBox(
                  width: double.infinity,
                  child: InputFormWidget(
                      height: 45,
                      controller: remarksCtrl,
                      onChng: (value) {
                        print('remarks (pgdtirecard)');
                        widget.onStringRemarks(value);
                      },
                      hint: ''),
                ),
                const SizedBox(
                  height: 12,
                ),
                Column(
                  children: [
                    ButtonWidget(
                        name: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.image),
                            const SizedBox(
                              width: 12,
                            ),
                            Text(
                              'Show Image',
                              style: getWhiteTextStyle(),
                            )
                          ],
                        ),
                        function: () async {
                          showDialog(
                              context: context,
                              builder: (BuildContext context) {
                                return StatefulBuilder(
                                    builder: (context, setState) {
                                  return AlertDialog(
                                      content: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        'Ban Posisi #${widget.dataTire.posisi}',
                                        style: getBlackTextStyle(),
                                      ),
                                      (listImg.isNotEmpty)
                                          ? Container(
                                              width: 400,
                                              height: 400,
                                              child: CarouselSlider(
                                                carouselController: _controller,
                                                items: listImg.map((file) {
                                                  log('hasil foto $file');
                                                  return Image.file(file);
                                                }).toList(),
                                                options: CarouselOptions(
                                                  aspectRatio: 3.0,
                                                  height: 400,
                                                  enableInfiniteScroll: false,
                                                  enlargeCenterPage: true,
                                                ),
                                              ),
                                            )
                                          // ? Image.file(listImg[0])
                                          : Column(
                                              children: [
                                                const SizedBox(
                                                  height: 12,
                                                ),
                                                Icon(Icons.add_a_photo),
                                                const SizedBox(
                                                  height: 12,
                                                ),
                                                Text(
                                                  'No Picture',
                                                  style: getBlackTextStyle(
                                                    fontWeight: w700,
                                                  ),
                                                ),
                                              ],
                                            ),
                                      const SizedBox(
                                        height: 12,
                                      ),
                                    ],
                                  ));
                                });
                              });
                        }),
                    const SizedBox(
                      height: 12,
                    ),
                  ],
                ),
                ButtonWidget(
                    name: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.camera_alt),
                        const SizedBox(
                          width: 12,
                        ),
                        Text(
                          'Take a Picture',
                          style: getWhiteTextStyle(),
                        )
                      ],
                    ),
                    function: () async {
                      requestCameraPermission();
                      cameraPicture(context);
                      setState(() {});
                    }),
              ],
            ),
            Padding(
              padding: EdgeInsets.symmetric(vertical: 6),
              child: Divider(
                thickness: 1.5,
              ),
            ),
            Text(
              'Broken Component (Optional)',
              style: getBlackTextStyle(fontWeight: w700),
            ),
            const SizedBox(
              height: 12,
            ),
            SizedBox(
              // height: 160,
              child: GridView.builder(
                  physics: NeverScrollableScrollPhysics(),
                  shrinkWrap: true,
                  itemCount: categories.length,
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2, childAspectRatio: 3),
                  itemBuilder: (context, index) {
                    return InkWell(
                      onTap: () {
                        setState(() {
                          checkedListCategory[index] =
                              !checkedListCategory[index];
                          print('tercentang (inkwell) $checkedListCategory');
                        });
                        widget.onCategoryChecked(checkedListCategory);
                      },
                      child: Container(
                        padding: EdgeInsets.all(10),
                        child: Row(
                          children: [
                            Container(
                              width: 24,
                              height: 24,
                              decoration: BoxDecoration(
                                color: checkedListCategory[index]
                                    ? black
                                    : Colors.transparent,
                                border: Border.all(color: Colors.black),
                              ),
                              child: Icon(
                                Icons.check,
                                color: Colors.white,
                                size: 16,
                              ),
                            ),
                            SizedBox(width: 10),
                            LayoutBuilder(builder: (context, constraints) {
                              double fontSize = constraints.maxHeight * 0.35;
                              // log('ukuran' + fontSize.toString());
                              return Text(
                                categories[index],
                                style: getBlackTextStyle(fontSize: fontSize),
                              );
                            }),
                          ],
                        ),
                      ),
                    );
                  }),
            ),
          ],
        ),
      ),
    );
  }
}
