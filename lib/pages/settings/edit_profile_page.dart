import 'dart:io';

import '../../core/blocs/authentication/authentication_bloc.dart';
import '../../core/styles/asset_path.dart';
import '../../core/styles/color.dart';
import '../../core/styles/text_manager.dart';
import '../../core/widgets/appbar_widget.dart';
import '../../core/widgets/button_widget.dart';
import '../../core/widgets/image_selection_widget.dart';
import '../../core/widgets/input_form_widget.dart';
import '../../core/widgets/upload_photo_widget.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'package:uuid/uuid.dart';

class EditProfilePage extends StatefulWidget {
  static const routeName = '/edit-profile-page';
  const EditProfilePage({super.key});

  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  UploadTask? uploadTask;
  late String urlDownload;
  String initialPhoto = '';

  File? imageFile;
  final ImagePicker _picker = ImagePicker();

  TextEditingController usernameCtrl = TextEditingController(text: '');
  TextEditingController positionCtrl = TextEditingController(text: '');
  TextEditingController ageCtrl = TextEditingController(text: '');

  FirebaseAuth auth = FirebaseAuth.instance;
  FirebaseFirestore firestore = FirebaseFirestore.instance;
  late CollectionReference users;

  void _pickImage(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return ImageSelection(
          onImageSourceSelected: (ImageSource source) async {
            final pickedImage = await _picker.getImage(source: source);

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

  Future<String?> uploadFile() async {
    final id = Uuid();
    final path = 'files/${id.v4()}';
    if (imageFile != null) {
      final file = imageFile!;

      final ref = FirebaseStorage.instance.ref().child(path);
      uploadTask = ref.putFile(file);

      final snapshot = await uploadTask!.whenComplete(() {});

      urlDownload = await snapshot.ref.getDownloadURL();

      return urlDownload;
    } else {
      return initialPhoto;
    }
  }

  defaultFillForm(Map<String, dynamic> user) {
    usernameCtrl.text = user['username'];
    positionCtrl.text = user['position'];
    ageCtrl.text = (user['age']).toString();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: appBarWidget('Edit Profile', context),
      body: SafeArea(
          child: SingleChildScrollView(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: FutureBuilder(
                future: firestore
                    .collection('users')
                    .where('email', isEqualTo: auth.currentUser!.email)
                    .get(),
                builder: (context, snapshot) {
                  final data = snapshot.data;
                  Map<String, dynamic> map = {};
                  data?.docs.forEach((e) {
                    map = e.data();
                  });
                  initialPhoto = map['image'] ?? '';
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return CircularProgressIndicator();
                  }
                  defaultFillForm(map);
                  return Column(
                    children: [
                      UploadPhotoWidget(
                          image: (imageFile != null)
                              ? Image(
                                  image: FileImage(imageFile!),
                                  fit: BoxFit.cover,
                                )
                              : (map['image'] == 'image' || map['image'] == '')
                                  ? Image(
                                      image: AssetImage(
                                          '$imagePath/default_user_image.png'))
                                  : Image(
                                      image: NetworkImage(map['image']),
                                      fit: BoxFit.cover,
                                    ),
                          function: () {
                            _pickImage(context);
                          }),
                      const SizedBox(
                        height: 32,
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Username', style: getBlackTextStyle()),
                          const SizedBox(
                            height: 12,
                          ),
                          SizedBox(
                              width: double.infinity,
                              child: InputFormWidget(
                                  controller: usernameCtrl, hint: 'Username')),
                        ],
                      ),
                      const SizedBox(
                        height: 24,
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Position', style: getBlackTextStyle()),
                          const SizedBox(
                            height: 12,
                          ),
                          SizedBox(
                              width: double.infinity,
                              child: InputFormWidget(
                                  controller: positionCtrl, hint: 'Position')),
                          const SizedBox(
                            height: 24,
                          ),
                        ],
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Age', style: getBlackTextStyle()),
                          const SizedBox(
                            height: 12,
                          ),
                          SizedBox(
                              width: double.infinity,
                              child: InputFormWidget(
                                  controller: ageCtrl, hint: 'Age')),
                          const SizedBox(
                            height: 24,
                          ),
                        ],
                      ),
                      SizedBox(
                        height: MediaQuery.of(context).size.height * 0.16,
                      ),
                      SizedBox(
                        width: double.infinity,
                        child: ButtonWidget(
                          function: () async {
                            final photo = await uploadFile();
                            context.read<AuthenticationBloc>().add(
                                AuthenticationEventUpdate(
                                    username: usernameCtrl.text,
                                    position: positionCtrl.text,
                                    age: int.parse(ageCtrl.text),
                                    image: photo ?? ''));
                          },
                          name: BlocConsumer<AuthenticationBloc,
                              AuthenticationState>(
                            listener: (context, state) {
                              if (state is AuthenticationErrorState) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                        content:
                                            Text('Cannot update profile')));
                              }
                              if (state is AuthenticationCompleteProfileState) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                        content:
                                            Text('Successful update profile')));
                              }
                            },
                            builder: (context, state) {
                              if (state is AuthenticatioLoadingState) {
                                return CircularProgressIndicator();
                              }

                              return Text(
                                'Update',
                                style: getWhiteTextStyle(),
                              );
                            },
                          ),
                        ),
                      )
                    ],
                  );
                }),
          ),
        ),
      )),
    );
  }
}
