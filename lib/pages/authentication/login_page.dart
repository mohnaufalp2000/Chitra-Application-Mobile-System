import 'package:camos/core/blocs/authentication/authentication_bloc.dart';
import 'package:camos/core/navigator/navigation_route.dart';
import 'package:camos/core/services/shared_preferences/shared_preferences.dart';
import 'package:camos/core/styles/asset_path.dart';
import 'package:camos/core/styles/color.dart';
import 'package:camos/core/styles/text_manager.dart';
import 'package:camos/core/utils/functions/functions.dart';
import 'package:camos/core/widgets/button_widget.dart';
import 'package:camos/core/widgets/contact_developer_widget.dart';
import 'package:camos/core/widgets/input_form_widget.dart';
import 'package:camos/core/widgets/text_button_widget.dart';
import 'package:camos/pages/authentication/chat_bot_page.dart';
import 'package:camos/pages/authentication/email_verification_page.dart';
import 'package:camos/pages/authentication/image_profile_page.dart';
import 'package:camos/pages/authentication/register_page.dart';
import 'package:camos/pages/home/home_page.dart';
import 'package:camos/pages/home/trial/home_page_trial.dart';
import 'package:camos/pages/tpms/qr_tpms_page.dart';
import 'package:camos/pages/tpms/tpms_page.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:translator/translator.dart';

class LoginPage extends StatefulWidget {
  static const routeName = '/login_page';
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  GoogleTranslator translator = GoogleTranslator();
  FirebaseAuth auth = FirebaseAuth.instance;
  bool? isCompleted = false;
  FirebaseFirestore firestore = FirebaseFirestore.instance;

  PackageInfo _packageInfo = PackageInfo(
    appName: 'Unknown',
    packageName: 'Unknown',
    version: 'Unknown',
    buildNumber: 'Unknown',
    buildSignature: 'Unknown',
    installerStore: 'Unknown',
  );

  Future<void> _initPackageInfo() async {
    final info = await PackageInfo.fromPlatform();
    setState(() {
      _packageInfo = info;
    });
  }

  @override
  void initState() {
    _initPackageInfo();
    requestGeolocatorPermission();
    retrieveVersionNumber();
    context.read<AuthenticationBloc>().add(AuthenticationEventLogout());

    super.initState();
  }

  void retrieveVersionNumber() async {
    final versionCol = FirebaseFirestore.instance.collection('version');
    final versionDoc = await versionCol.doc('version').get();
    String versionNumber = versionDoc.data()?['number'];
    if (_packageInfo.version != versionNumber) {
      showUpdateDialog(context);
    }
  }

  Future<void> showUpdateDialog(BuildContext context) async {
    return showDialog<void>(
      context: context,
      barrierDismissible:
          false, // Dialog tidak dapat ditutup dengan mengetuk di luar dialog
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Update Available'),
          content: SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                Text('A new version is available.'),
                Text('Please update to the latest version.'),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: Text(
                'Close',
                style: getGreyTextStyle(grey6A707C),
              ),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: Text('Update Now'),
              onPressed: () {
                Navigator.of(context).pop();
                openPlayStore('camos');
              },
            ),
          ],
        );
      },
    );
  }

  // validation email and password
  String? validationInput() {
    if (emailController.text.isEmpty || passwordController.text.isEmpty) {
      return 'Email dan Password tidak boleh kosong';
    }

    if (!emailController.text.contains('@')) {
      return 'Email tidak valid';
    }
    return null;
  }

  inputEmailForm() {
    bool _isEmailValid = true;
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
                    'Please insert your email',
                    style: getBlackTextStyle(),
                  ),
                  const SizedBox(
                    height: 12,
                  ),
                  SizedBox(
                    width: double.infinity,
                    child: InputFormWidget(
                      controller: emailController,
                      hint: 'Enter email',
                      type: TextInputType.emailAddress,
                    ),
                  ),
                  (!_isEmailValid)
                      ? Column(
                          children: [
                            const SizedBox(
                              height: 12,
                            ),
                            Text('Email not valid', style: getRedTextStyle()),
                          ],
                        )
                      : Container()
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => back(context),
                  child: Text(
                    'Cancel',
                    style: getGreyTextStyle(grey8391A1),
                  ),
                ),
                BlocConsumer<AuthenticationBloc, AuthenticationState>(
                  listener: (context, state) {
                    if (state is AuthenticationChangePasswordState) {
                      back(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                            content:
                                Text('Check your email for change password')),
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
                        if (!emailController.text.contains('@')) {
                          setState(() {
                            _isEmailValid = false;
                          });
                          return;
                        }
                        context.read<AuthenticationBloc>().add(
                            AuthenticationEventChangePassword(
                                email: emailController.text));
                      },
                      child: (state is AuthenticatioLoadingState)
                          ? const CircularProgressIndicator()
                          : Text('Send'),
                    );
                  },
                ),
              ],
            );
          });
        });
  }

  @override
  void dispose() {
    emailController.clear();
    emailController.dispose();
    passwordController.clear();
    passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Center(
            child: SingleChildScrollView(
              child: Padding(
                padding: EdgeInsets.only(
                    bottom: MediaQuery.of(context).viewInsets.bottom),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Image.asset(
                      '${iconPath}/logo_camos_icon.png',
                      width: 120,
                      height: 120,
                    ),

                    const SizedBox(
                      height: 58,
                    ),
                    InputFormWidget(
                      controller: emailController,
                      hint: 'Enter Email',
                      type: TextInputType.emailAddress,
                    ),
                    const SizedBox(
                      height: 15,
                    ),
                    InputFormWidget(
                      controller: passwordController,
                      hint: 'Enter Password',
                      isObscure: true,
                      type: TextInputType.emailAddress,
                    ),
                    const SizedBox(
                      height: 16,
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        BlocConsumer<AuthenticationBloc, AuthenticationState>(
                          listener: (context, state) {},
                          builder: (context, state) {
                            return TextButtonWidget(
                              name: 'Forgot Password?',
                              style: getRedTextStyle(
                                fontSize: 16,
                              ),
                              function: () {
                                inputEmailForm();
                              },
                            );
                          },
                        ),
                      ],
                    ),
                    const SizedBox(
                      height: 24,
                    ),
                    BlocConsumer<AuthenticationBloc, AuthenticationState>(
                      listener: (context, state) async {
                        if (state is AuthenticatioLoginState) {
                          // check email is verify or not
                          if (auth.currentUser!.emailVerified) {
                            final col =
                                FirebaseFirestore.instance.collection('users');
                            final query = await col
                                .where('email',
                                    isEqualTo: auth.currentUser?.email)
                                .get();
                            if (query.docs.isNotEmpty) {
                              print('login dengan sharedprefrences');
                              DocumentSnapshot documentSnapshot = query.docs[0];
                              if (documentSnapshot.data()
                                  is Map<String, dynamic>) {
                                Map<String, dynamic> data = documentSnapshot
                                    .data() as Map<String, dynamic>;

                                saveIdSitePreferences(data['id_site']);
                                saveManpowerShiftPreferences(shift: 'morning');
                              }
                            }

                            final user = await firestore
                                .collection('users')
                                .where('email',
                                    isEqualTo: auth.currentUser?.email)
                                .get();

                            final listCustPgDigital = await firestore
                                .collection('list_site_pgdigital')
                                .get();
                            final listCustPgDigitalData = listCustPgDigital.docs
                                .map((e) => e.data() as Map<String, dynamic>)
                                .toList();

                            print('user docs : ${listCustPgDigitalData}');

                            saveListCustomer(listCustPgDigitalData);

                            // apakah user PAMA-TRIAL? Jika iya arahkan ke home page trial
                            if ((listCustPgDigitalData).any((e) =>
                                e['id_site'] == user.docs[0]['id_site'])) {
                              pushReplace(context, HomePageTrial.routeName);
                            } else {
                              pushReplace(context, HomePage.routeName);
                            }
                          } else {
                            push(context, EmailVerificationPage.routeName);
                          }
                        }

                        if (state is AuthenticationErrorState) {
                          ScaffoldMessenger.of(context).hideCurrentSnackBar();
                          FocusManager.instance.primaryFocus?.unfocus();
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text(state.errorMessage)),
                          );
                        }
                      },
                      builder: (context, state) {
                        return ButtonWidget(
                          function: () {
                            final message = validationInput();

                            // check if input is not valid
                            if (message != null) {
                              FocusManager.instance.primaryFocus?.unfocus();
                              ScaffoldMessenger.of(context)
                                  .hideCurrentSnackBar();
                              ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text(message)));
                              return;
                            }
                            context.read<AuthenticationBloc>().add(
                                AuthenticationEventLogin(
                                    email: emailController.text,
                                    password: passwordController.text));
                          },
                          name: (state is AuthenticatioLoadingState)
                              ? const CircularProgressIndicator()
                              : Text(
                                  'Login',
                                  style: getWhiteTextStyle(
                                    fontSize: 16,
                                    fontWeight: w600,
                                  ),
                                ),
                        );
                      },
                    ),
                    const SizedBox(
                      height: 12,
                    ),
                    // ButtonWidget(
                    //     name: Text('ChatBot'),
                    //     function: () {
                    //       Navigator.push(
                    //           context,
                    //           MaterialPageRoute(
                    //               builder: (context) => ChatMaximaWidget()));
                    //     }),
                    // const SizedBox(
                    //   height: 12,
                    // ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'Don\'t have account yet?',
                          style: getBlackTextStyle(
                            fontSize: 16,
                          ),
                        ),
                        TextButtonWidget(
                          name: 'Create Now',
                          style: getGreenTextStyle(fontSize: 16),
                          function: () {
                            push(context, RegisterPage.routeName);
                          },
                        ),
                      ],
                    ),
                    const SizedBox(
                      height: 48,
                    ),
                    ContactDeveloperWidget(),
                    const SizedBox(
                      height: 12,
                    ),
                    Center(
                      child: Text(
                        'App Version : ${_packageInfo.version}',
                        style: getBlackTextStyle(fontWeight: w700),
                      ),
                    ),
                    // Row(
                    //   mainAxisAlignment: MainAxisAlignment.center,
                    //   children: [
                    //     Image.asset(
                    //       '${iconPath}/heavy_tire_icon.png',
                    //       width: 30,
                    //       height: 30,
                    //     ),
                    //     TextButtonWidget(
                    //       name: 'Open Tire Inspection Page',
                    //       style: getGreenTextStyle(fontSize: 16),
                    //       function: () {
                    //         push(context, NonRunningInspectionPage.routeName);
                    //       },
                    //     ),
                    //   ],
                    // ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
