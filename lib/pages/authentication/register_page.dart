import 'package:camos/core/blocs/authentication/authentication_bloc.dart';
import 'package:camos/core/blocs/site/site_bloc.dart';
import 'package:camos/core/navigator/navigation_route.dart';
import 'package:camos/core/styles/asset_path.dart';
import 'package:camos/core/styles/color.dart';
import 'package:camos/core/styles/text_manager.dart';
import 'package:camos/core/widgets/button_widget.dart';
import 'package:camos/core/widgets/contact_developer_widget.dart';
import 'package:camos/core/widgets/input_form_widget.dart';
import 'package:camos/pages/authentication/email_verification_page.dart';
import 'package:camos/pages/authentication/login_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:translator/translator.dart';

class RegisterPage extends StatefulWidget {
  static const routeName = '/register_page';
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController snController = TextEditingController();
  GoogleTranslator translator = GoogleTranslator();
  int idSite = 0;

  @override
  void initState() {
    super.initState();
    context.read<SiteBloc>().add(GetAllSiteEvent());
  }

  @override
  void dispose() {
    emailController.clear();
    emailController.dispose();
    passwordController.clear();
    passwordController.dispose();
    super.dispose();
  }

  // validation email and password
  String? validationInput() {
    if (emailController.text.isEmpty || passwordController.text.isEmpty) {
      return 'Email dan Password tidak boleh kosong';
    }

    if (emailController.text.length < 6 || passwordController.text.length < 6) {
      return 'Terlalu pendek, minimal 6 karakter';
    }

    if (!emailController.text.contains('@')) {
      return 'Format email tidak valid';
    }

    if (idSite == 0) {
      return 'Select site first';
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
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
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: SingleChildScrollView(
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
                  hint: 'Enter Password (min. 6 character)',
                  isObscure: true,
                ),
                const SizedBox(
                  height: 15,
                ),
                InputFormWidget(
                  controller: snController,
                  hint: 'Enter SN',
                  type: TextInputType.number,
                ),
                const SizedBox(
                  height: 15,
                ),
                BlocBuilder<SiteBloc, SiteState>(
                  builder: (context, state) {
                    print('state (register) : $state');
                    if (state is SiteLoadingState) {
                      return SizedBox(
                          width: 50,
                          height: 50,
                          child: CircularProgressIndicator());
                    } else if (state is SiteLoadedState) {
                      // if (idSite == 0) {
                      //   idSite = int.parse(state.listSite[0].idSite ?? '');
                      //   print('id site register : $idSite');
                      // }
                      return Container(
                        padding: EdgeInsets.all(12),
                        decoration: BoxDecoration(
                            color: greyDADADA,
                            borderRadius: BorderRadius.circular(12)),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<int>(
                              isDense: true,
                              style: getBlackTextStyle(),
                              value: idSite,
                              // items: state.listSite.map((site) {
                              //   return DropdownMenuItem(
                              //     child: Text(site.site ?? ''),
                              //     value: int.parse(site.idSite ?? ''),
                              //   );
                              // }).toList(),
                              items: [
                                DropdownMenuItem(
                                  child: Text(
                                    'Please select site...',
                                    style: getBlackTextStyle(),
                                  ),
                                  value: 0,
                                ),
                                // Tambahkan item dari daftar situs yang dimuat
                                ...state.listSite.map((site) {
                                  return DropdownMenuItem(
                                    child: Text(site.site ?? ''),
                                    value: int.parse(site.idSite ?? ''),
                                  );
                                }).toList(),
                              ],
                              onChanged: (value) {
                                setState(() {
                                  idSite = value ?? 0;
                                });
                              }),
                        ),
                      );
                    } else {
                      return Container();
                    }
                  },
                ),
                const SizedBox(
                  height: 24,
                ),
                BlocConsumer<AuthenticationBloc, AuthenticationState>(
                  listener: (context, state) async {
                    if (state is AuthenticatioRegisterState) {
                      pushReplace(context, EmailVerificationPage.routeName);
                    }

                    if (state is AuthenticationErrorState) {
                      // final message = await translator
                      //     .translate(state.errorMessage, from: 'en', to: 'id');
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
                          ScaffoldMessenger.of(context).hideCurrentSnackBar();
                          ScaffoldMessenger.of(context)
                              .showSnackBar(SnackBar(content: Text(message)));
                          return;
                        }

                        context.read<AuthenticationBloc>().add(
                              AuthenticationEventRegister(
                                email: emailController.text,
                                password: passwordController.text,
                                sn: snController.text,
                                idSite: (idSite.toString()),
                              ),
                            );
                      },
                      name: (state is AuthenticatioLoadingState)
                          ? const CircularProgressIndicator()
                          : Text(
                              'Register',
                              style: getWhiteTextStyle(
                                fontSize: 16,
                                fontWeight: w600,
                              ),
                            ),
                    );
                  },
                ),
                const SizedBox(
                  height: 48,
                ),
                ContactDeveloperWidget()
              ],
            ),
          ),
        ),
      ),
    );
  }
}
