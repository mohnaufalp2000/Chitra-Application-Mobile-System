import 'dart:io';

import 'package:camos/core/blocs/authentication/authentication_bloc.dart';
import 'package:camos/core/navigator/navigation_route.dart';
import 'package:camos/core/services/shared_preferences/shared_preferences.dart';
import 'package:camos/core/styles/color.dart';
import 'package:camos/core/styles/text_manager.dart';
import 'package:camos/core/utils/functions/functions.dart';
import 'package:camos/core/widgets/button_widget.dart';
import 'package:camos/core/widgets/image_selection_widget.dart';
import 'package:camos/core/widgets/input_form_widget.dart';
import 'package:camos/core/widgets/outlined_button_widget.dart';
import 'package:camos/core/widgets/upload_photo_widget.dart';
import 'package:camos/pages/authentication/login_page.dart';
import 'package:camos/pages/home/home_page.dart';
import 'package:camos/pages/home/trial/home_page_trial.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

class ImageProfilePage extends StatefulWidget {
  static const routeName = '/image-profile-page';
  const ImageProfilePage({super.key});

  @override
  State<ImageProfilePage> createState() => _ImageProfilePageState();
}

class _ImageProfilePageState extends State<ImageProfilePage> {
  UploadTask? uploadTask;
  String urlDownload = '';

  FirebaseAuth auth = FirebaseAuth.instance;
  FirebaseFirestore firestore = FirebaseFirestore.instance;

  File? imageFile;
  final ImagePicker _picker = ImagePicker();

  TextEditingController usernameCtrl = TextEditingController(text: '');
  TextEditingController positionCtrl = TextEditingController(text: '');
  TextEditingController ageCtrl = TextEditingController(text: '');

  void _pickImage(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return ImageSelection(
          onImageSourceSelected: (ImageSource source) async {
            final pickedImage =
                await _picker.getImage(source: source, imageQuality: 30);

            if (pickedImage != null) {
              setState(() {
                imageFile = File(pickedImage.path);
              });
            }
          },
        );
      },
    );
  }

  Future<String?> updateProfile() async {
    final id = Uuid();
    final path = 'files/${id.v4()}';
    if (imageFile != null) {
      final file = imageFile!;

      final ref = FirebaseStorage.instance.ref().child(path);
      uploadTask = ref.putFile(file);

      final snapshot = await uploadTask!.whenComplete(() {});

      urlDownload = await snapshot.ref.getDownloadURL();

      context.read<AuthenticationBloc>().add(AuthenticationEventUpdate(
          username: (usernameCtrl.text == '') ? 'username' : usernameCtrl.text,
          position: (positionCtrl.text == '') ? 'position' : positionCtrl.text,
          age: (ageCtrl.text == '') ? 0 : int.parse(ageCtrl.text),
          image: (urlDownload == '') ? 'image' : urlDownload));

      return urlDownload;
    } else {
      print('ga pasang foto');
      context.read<AuthenticationBloc>().add(AuthenticationEventUpdate(
          username: (usernameCtrl.text == '') ? 'username' : usernameCtrl.text,
          position: (positionCtrl.text == '') ? 'position' : positionCtrl.text,
          age: (ageCtrl.text == '') ? 0 : int.parse(ageCtrl.text),
          image: (urlDownload == '') ? 'image' : urlDownload));
    }

    return '';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Padding(
          padding: const EdgeInsets.only(top: 18.0),
          child: Text(
            'Complete Profile Data',
            style: getBlackTextStyle(fontSize: 20, fontWeight: w700),
          ),
        ),
        centerTitle: true,
        leading: Padding(
          padding: const EdgeInsets.only(left: 16),
          child: Container(
            margin: const EdgeInsets.only(top: 14),
            padding: const EdgeInsets.symmetric(horizontal: 4),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: black),
            ),
            child: IconButton(
                onPressed: () {
                  ScaffoldMessenger.of(context).hideCurrentSnackBar();
                  pushRemoveUntil(context, LoginPage.routeName);
                },
                icon: const Icon(
                  Icons.arrow_back_ios,
                  color: black,
                  size: 24,
                )),
          ),
        ),
      ),
      body: SafeArea(
          child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Center(
            child: Column(
              children: [
                UploadPhotoWidget(
                    image: (imageFile != null)
                        ? Image(
                            image: FileImage(imageFile!),
                            fit: BoxFit.cover,
                          )
                        : null,
                    function: () {
                      _pickImage(context);
                    }),
                const SizedBox(
                  height: 24,
                ),
                Text(
                  'Upload a photo for us to easily identify you.',
                  style: getBlackTextStyle(fontSize: 16),
                ),
                const SizedBox(
                  height: 24,
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    InputFormWidget(
                      controller: usernameCtrl,
                      hint: 'Username',
                      type: TextInputType.emailAddress,
                    ),
                    const SizedBox(
                      height: 16,
                    ),
                    InputFormWidget(
                      controller: positionCtrl,
                      hint: 'Position',
                      type: TextInputType.emailAddress,
                    ),
                    const SizedBox(
                      height: 16,
                    ),
                    InputFormWidget(
                      controller: ageCtrl,
                      hint: 'Age',
                      type: TextInputType.emailAddress,
                    ),
                  ],
                ),
                const SizedBox(
                  height: 24,
                ),
                BlocConsumer<AuthenticationBloc, AuthenticationState>(
                  listener: (context, state) async {
                    if (state is AuthenticationCompleteProfileState) {
                      final user = await firestore
                          .collection('users')
                          .where('email', isEqualTo: auth.currentUser?.email)
                          .get();

                      final listCustPgDigital = await firestore
                          .collection('list_site_pgdigital')
                          .get();
                      final listCustPgDigitalData = listCustPgDigital.docs
                          .map((e) => e.data() as Map<String, dynamic>)
                          .toList();

                      // apakah user PAMA-TRIAL? Jika iya arahkan ke home page trial
                      if ((listCustPgDigitalData).any(
                          (e) => e['id_site'] == user.docs[0]['id_site'])) {
                        pushReplace(context, HomePageTrial.routeName);
                      } else {
                        pushReplace(context, HomePage.routeName);
                      }
                    }
                  },
                  builder: (context, state) {
                    return ButtonWidget(
                        name: (state is AuthenticatioLoadingState)
                            ? const CircularProgressIndicator()
                            : Text(
                                'Complete Profile',
                                style: getWhiteTextStyle(),
                              ),
                        function: () async {
                          final col = firestore.collection('users');
                          final query = await col
                              .where('email',
                                  isEqualTo: auth.currentUser?.email)
                              .get();
                          if (query.docs.isNotEmpty) {
                            DocumentSnapshot documentSnapshot = query.docs[0];
                            if (documentSnapshot.data()
                                is Map<String, dynamic>) {
                              Map<String, dynamic> data = documentSnapshot
                                  .data() as Map<String, dynamic>;

                              saveIdSitePreferences(data['id_site']);
                              saveManpowerShiftPreferences(shift: 'morning');
                            }
                          }
                          await updateProfile();
                        });
                  },
                ),
                const SizedBox(
                  height: 18,
                ),
                OutlinedButtonWidget(
                    name: Text(
                      'Skip for Now',
                      style: getBlackTextStyle(),
                    ),
                    function: () async {
                      final col = firestore.collection('users');
                      final query = await col
                          .where('email', isEqualTo: auth.currentUser?.email)
                          .get();
                      if (query.docs.isNotEmpty) {
                        DocumentSnapshot documentSnapshot = query.docs[0];
                        if (documentSnapshot.data() is Map<String, dynamic>) {
                          Map<String, dynamic> data =
                              documentSnapshot.data() as Map<String, dynamic>;

                          saveIdSitePreferences(data['id_site']);
                          saveManpowerShiftPreferences(shift: 'morning');
                        }
                      }
                      final user = await firestore
                          .collection('users')
                          .where('email', isEqualTo: auth.currentUser?.email)
                          .get();
                      final listCustPgDigital = await firestore
                          .collection('list_site_pgdigital')
                          .get();
                      final listCustPgDigitalData = listCustPgDigital.docs
                          .map((e) => e.data() as Map<String, dynamic>)
                          .toList();
                      // apakah user PAMA-TRIAL? Jika iya arahkan ke home page trial
                      if ((listCustPgDigitalData).any(
                          (e) => e['id_site'] == user.docs[0]['id_site'])) {
                        pushReplace(context, HomePageTrial.routeName);
                      } else {
                        pushReplace(context, HomePage.routeName);
                      }
                    }),
              ],
            ),
          ),
        ),
      )),
    );
  }
}
