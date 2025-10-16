import '../../core/blocs/authentication/authentication_bloc.dart';
import '../../core/navigator/navigation_route.dart';
import '../../core/styles/asset_path.dart';
import '../../core/styles/color.dart';
import '../../core/styles/text_manager.dart';
import '../../core/widgets/appbar_widget.dart';
import '../../core/widgets/button_widget.dart';
import '../authentication/login_page.dart';
import 'edit_profile_page.dart';
import 'feedback_page.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:settings_ui/settings_ui.dart';

class SettingsPage extends StatefulWidget {
  static const routeName = '/settings-page';
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  FirebaseAuth auth = FirebaseAuth.instance;
  FirebaseFirestore firestore = FirebaseFirestore.instance;
  late CollectionReference users;

  changePasswordFunc() {
    showDialog(
        context: context,
        builder: (context) {
          return StatefulBuilder(builder: (context, setState) {
            return AlertDialog(
              title: Text(
                'Change Password',
                style: getBlackTextStyle(
                  fontSize: 16,
                  fontWeight: w700,
                ),
              ),
              content: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Are you want to change your password?',
                    style: getBlackTextStyle(),
                  )
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => back(context),
                  child: Text(
                    'No',
                    style: getGreyTextStyle(grey8391A1),
                  ),
                ),
                BlocConsumer<AuthenticationBloc, AuthenticationState>(
                  listener: (context, state) {
                    if (state is AuthenticationChangePasswordState) {
                      back(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                            content: Text(
                          'Please check your email inbox to change your password',
                          style: getWhiteTextStyle(),
                        )),
                      );
                    }

                    if (state is AuthenticationErrorState) {
                      back(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(state.errorMessage)),
                      );
                    }
                  },
                  builder: (context, state) {
                    return TextButton(
                      onPressed: () {
                        context.read<AuthenticationBloc>().add(
                            AuthenticationEventChangePassword(
                                email: auth.currentUser!.email ?? ''));
                      },
                      child: (state is AuthenticatioLoadingState)
                          ? const CircularProgressIndicator()
                          : Text('Yes'),
                    );
                  },
                ),
              ],
            );
          });
        });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: appBarWidget('Settings', context),
      body: SafeArea(
          child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24.0),
        child: SingleChildScrollView(
          child: Column(
            children: [
              const SizedBox(
                height: 24,
              ),
              StreamBuilder(
                  stream: firestore
                      .collection('users')
                      .where('email', isEqualTo: auth.currentUser!.email)
                      .snapshots(),
                  builder: (context, snapshot) {
                    final data = snapshot.data;
                    Map<String, dynamic> map = {};
                    data?.docs.forEach((e) {
                      map = e.data();
                    });
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return CircularProgressIndicator();
                    }
                    return Center(
                      child: Column(
                        children: [
                          CircleAvatar(
                            backgroundImage: (map['image'] == '' ||
                                    map['image'] == null ||
                                    map['image'] == 'image')
                                ? AssetImage(
                                        '$imagePath/default_user_image.png')
                                    as ImageProvider
                                : NetworkImage(map['image']),
                            backgroundColor: Colors.grey.withOpacity(0.4),
                            radius: 60,
                          ),
                          const SizedBox(
                            height: 12,
                          ),
                          Text(
                            map['username'],
                            style: getBlackTextStyle(
                                fontWeight: w700, fontSize: 20),
                          ),
                          const SizedBox(
                            height: 6,
                          ),
                          Text(
                            map['email'],
                            style: getGreyTextStyle(grey8391A1),
                          ),
                          const SizedBox(
                            height: 12,
                          ),
                          SizedBox(
                            width: 150,
                            child: ButtonWidget(
                                name: Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        'Edit Profile',
                                        style: getWhiteTextStyle(),
                                      ),
                                    ),
                                    Icon(
                                      Icons.arrow_forward_ios,
                                      size: 14,
                                    )
                                  ],
                                ),
                                function: () {
                                  Navigator.pushNamed(
                                      context, EditProfilePage.routeName);
                                }),
                          )
                        ],
                      ),
                    );
                  }),
              const SizedBox(
                height: 24,
              ),
              SettingsList(
                shrinkWrap: true,
                physics: NeverScrollableScrollPhysics(),
                sections: [
                  SettingsSection(
                    tiles: <SettingsTile>[
                      SettingsTile.navigation(
                        leading: Icon(Icons.lock),
                        onPressed: (context) {
                          changePasswordFunc();
                        },
                        title: Text(
                          'Change Password',
                          style:
                              getBlackTextStyle(fontSize: 18, fontWeight: w500),
                        ),
                        trailing: Icon(
                          Icons.arrow_forward_ios,
                          size: 16,
                        ),
                      ),
                      SettingsTile.navigation(
                        onPressed: (context) {
                          Navigator.pushNamed(context, FeedbackPage.routeName);
                        },
                        leading: Icon(Icons.feedback),
                        title: Text(
                          'Give Feedback',
                          style:
                              getBlackTextStyle(fontSize: 18, fontWeight: w500),
                        ),
                        trailing: Icon(
                          Icons.arrow_forward_ios,
                          size: 16,
                        ),
                      ),
                      SettingsTile.navigation(
                        leading: Icon(Icons.info),
                        title: Text(
                          'About Us',
                          style:
                              getBlackTextStyle(fontSize: 18, fontWeight: w500),
                        ),
                        trailing: Icon(
                          Icons.arrow_forward_ios,
                          size: 16,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(
                height: 24,
              ),
              ButtonWidget(
                  name: Text(
                    'Delete Account',
                    style: getWhiteTextStyle(),
                  ),
                  color: Colors.red,
                  function: () async {
                    showDialog(
                        context: context,
                        builder: (context) {
                          return AlertDialog(
                            content: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  'Delete Confirmation',
                                  style: getBlackTextStyle(
                                    fontSize: 16,
                                    fontWeight: w600,
                                  ),
                                ),
                                const SizedBox(
                                  height: 12,
                                ),
                                Text(
                                  'Are you sure you want to delete account?',
                                  style: getBlackTextStyle(),
                                ),
                              ],
                            ),
                            actions: [
                              TextButton(
                                  onPressed: () {
                                    back(context);
                                  },
                                  child: Text(
                                    'No',
                                    style: getGreyTextStyle(grey8391A1),
                                  )),
                              TextButton(
                                  onPressed: () async {
                                    context.read<AuthenticationBloc>().add(
                                        AuthenticationEventLogout(
                                            isDelete: true));
                                    pushRemoveUntil(
                                        context, LoginPage.routeName);
                                  },
                                  child: Text('Yes')),
                            ],
                          );
                        });
                  }),
              const SizedBox(
                height: 24,
              ),
            ],
          ),
        ),
      )),
    );
  }
}
