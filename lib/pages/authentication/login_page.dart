import 'package:camos/core/blocs/authentication/authentication_bloc.dart';
import 'package:camos/core/navigator/navigation_route.dart';
import 'package:camos/core/services/shared_preferences/shared_preferences.dart';
import 'package:camos/core/styles/asset_path.dart';
import 'package:camos/core/styles/color.dart';
import 'package:camos/core/styles/text_manager.dart';
import 'package:camos/core/utils/functions/functions.dart';
import 'package:camos/core/widgets/button_widget.dart';
import 'package:camos/core/widgets/input_form_widget.dart';
import 'package:camos/core/widgets/text_button_widget.dart';
import 'package:camos/pages/authentication/email_verification_page.dart';
import 'package:camos/pages/authentication/image_profile_page.dart';
import 'package:camos/pages/authentication/register_page.dart';
import 'package:camos/pages/home/home_page.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
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

  @override
  void initState() {
    requestGeolocatorPermission();

    context.read<AuthenticationBloc>().add(AuthenticationEventLogout());

    super.initState();
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
                            pushReplace(context, HomePage.routeName);
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
