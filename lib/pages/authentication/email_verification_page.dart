import 'dart:async';

import 'package:camos/core/blocs/authentication/authentication_bloc.dart';
import 'package:camos/core/navigator/navigation_route.dart';
import 'package:camos/core/styles/asset_path.dart';
import 'package:camos/core/styles/color.dart';
import 'package:camos/core/styles/text_manager.dart';
import 'package:camos/core/widgets/button_widget.dart';
import 'package:camos/pages/authentication/image_profile_page.dart';
import 'package:camos/pages/authentication/login_page.dart';
import 'package:camos/pages/home/home_page.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class EmailVerificationPage extends StatefulWidget {
  static const routeName = '/email-verification-page';
  const EmailVerificationPage({super.key});

  @override
  State<EmailVerificationPage> createState() => _EmailVerificationPageState();
}

class _EmailVerificationPageState extends State<EmailVerificationPage> {
  FirebaseAuth auth = FirebaseAuth.instance;
  bool _isEmailVerified = false;
  Timer? timer;

  emailVerifyInformation() {
    timer =
        Timer.periodic(const Duration(seconds: 3), (_) => checkEmailVerified());

    showDialog(
        context: context,
        builder: (context) {
          return StatefulBuilder(builder: (context, state) {
            return AlertDialog(
              content: BlocConsumer<AuthenticationBloc, AuthenticationState>(
                listener: (context, state) {},
                builder: (context, state) {
                  return Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Check Your Email',
                        style:
                            getBlackTextStyle(fontSize: 16, fontWeight: w600),
                      ),
                      const SizedBox(
                        height: 24,
                      ),
                      Text(
                        'We have emailed you at ${auth.currentUser!.email}',
                        textAlign: TextAlign.center,
                        style: getBlackTextStyle().copyWith(
                          height: 1.5,
                        ),
                      ),
                      const SizedBox(
                        height: 24,
                      ),
                      Column(
                        children: [
                          const CircularProgressIndicator(),
                          const SizedBox(
                            height: 12,
                          ),
                          Text(
                            'Verifying e-mail...',
                            style: getGreenTextStyle(),
                          )
                        ],
                      ),
                      const SizedBox(
                        height: 24,
                      ),
                      // Masih belum berfungsi (Resend Link)
                      // ButtonWidget(
                      //     name: (state is AuthenticatioLoadingState)
                      //         ? const CircularProgressIndicator()
                      //         : Text(
                      //             'Kirim Ulang',
                      //             style: getWhiteTextStyle(),
                      //           ),
                      //     function: () {
                      //       setState(() {});
                      //       context
                      //           .read<AuthenticationBloc>()
                      //           .add(AuthenticationEventVerifyEmail());
                      //     }),
                    ],
                  );
                },
              ),
            );
          });
        });
  }

  checkEmailVerified() async {
    await auth.currentUser?.reload();

    setState(() {
      _isEmailVerified = auth.currentUser!.emailVerified;
    });

    if (_isEmailVerified) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text("Email Successfully Verified")));
      timer?.cancel();

      if (context.mounted) {
        pushRemoveUntil(context, ImageProfilePage.routeName);
      }
    }
  }

  @override
  void dispose() {
    timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
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
                  back(context);
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
          child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.asset(
                '${imagePath}/email_verify_image.png',
                width: 150,
                height: 150,
              ),
              const SizedBox(
                height: 12,
              ),
              Text(
                'Verify your email address',
                style: getBlackTextStyle(fontSize: 18, fontWeight: w600),
              ),
              Container(
                  margin:
                      const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
                  child: const Divider(
                    thickness: 1.5,
                  )),
              Text(
                'To start using your account, you need to confirm your email address',
                textAlign: TextAlign.center,
                style: getBlackTextStyle().copyWith(height: 1.7),
              ),
              const SizedBox(
                height: 24,
              ),
              ButtonWidget(
                  name: Text('Email Verification'),
                  function: () {
                    context
                        .read<AuthenticationBloc>()
                        .add(AuthenticationEventVerifyEmail());
                    emailVerifyInformation();
                  }),
              Container(
                  margin:
                      const EdgeInsets.symmetric(vertical: 24, horizontal: 160),
                  child: const Divider(
                    thickness: 1.5,
                  )),
              Text(
                'If you did not register for this account, you can ignore this email and the account will be deleted',
                textAlign: TextAlign.center,
                style: getGreyTextStyle(Colors.grey)
                    .copyWith(height: 1.7)
                    .copyWith(fontStyle: FontStyle.italic),
              ),
            ],
          ),
        ),
      )),
    );
  }
}
